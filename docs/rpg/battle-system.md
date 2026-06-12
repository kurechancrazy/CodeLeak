# Battle System — ターンベース戦闘アーキテクチャ

**対象:** Godot 4.4+ / 2D 横並びターンベース RPG（FF4/5/6 スタイル）

---

## Claude Code 実装停止チェックリスト

```
□ BattleManager なしに戦闘ロジックをシーンスクリプトに書こうとしている
□ ダメージ計算式を BattleManager または battle_calc.gd 以外に書こうとしている
□ 戦闘中のターン順序を Scene 側で管理しようとしている
□ 戦闘コマンド選択とコマンド実行を同一フェーズで処理しようとしている
□ GameState を BATTLE_COMMAND 等に遷移させずに入力制御しようとしている
```

---

## 1. 戦闘シーンの階層設計

```
BattleScene（Node2D）
├── Background（Sprite2D）            ← 戦闘背景（フィールド別に差し替え）
├── EnemyGroup（Node2D）              ← 敵スプライト配置コンテナ（画面左側）
│   ├── Enemy_0（AnimatedSprite2D）
│   ├── Enemy_1（AnimatedSprite2D）
│   └── Enemy_2（AnimatedSprite2D）
├── PartyGroup（Node2D）              ← パーティースプライト配置（画面右側）
│   ├── Char_0（AnimatedSprite2D）
│   ├── Char_1（AnimatedSprite2D）
│   └── Char_2（AnimatedSprite2D）
└── BattleUI（CanvasLayer, layer=1）
    ├── CommandWindow（Control）      ← コマンド選択 UI
    ├── PartyStatusPanel（Control）   ← HP/MP 表示
    ├── MessageWindow（Control）      ← 行動メッセージ表示
    └── TargetCursor（Control）       ← 対象選択カーソル
```

**原則:**
- 戦闘ロジック（ターン管理・ダメージ計算）は BattleManager Autoload
- 戦闘シーンは EventBus 経由でシグナルを受け取り表示のみを担当

---

## 2. BattleManager の責務

`autoloads/battle_manager.gd` が持つべき責務:

| 責務 | 具体的な内容 |
|------|------------|
| 戦闘開始 | 敵データ受け取り・戦闘シーン起動 |
| ターン順序管理 | 素早さ（AGI）順で行動キュー生成 |
| コマンド受付 | シーンからコマンド選択結果を受け取る |
| コマンド実行 | 攻撃・魔法・アイテム・逃げるの処理 |
| 戦闘終了判定 | 全敵撃破 → 勝利 / 全員戦闘不能 → 敗北 |
| 報酬計算 | EXP・ゴールド・アイテムドロップ → PartyManager に通知 |

```gdscript
# autoloads/battle_manager.gd
extends Node

# ── 公開シグナル ──────────────────────────────────────────
signal battle_started(enemies: Array[EnemyData])
signal turn_started(actor_id: String, is_player: bool)
signal command_execution_started(command: BattleCommand)
signal damage_dealt(target_id: String, amount: int, is_critical: bool)
signal status_applied(target_id: String, status: String)
signal actor_defeated(actor_id: String)
signal battle_ended(result: BattleResult)

# ── 戦闘状態 ─────────────────────────────────────────────
enum Phase {
    IDLE,
    START,      # 戦闘開始演出
    COMMAND,    # コマンド入力待ち（全パーティーメンバー分）
    EXECUTE,    # コマンド実行中（アニメーション・ダメージ処理）
    END,        # 戦闘終了演出
}

var _phase: Phase = Phase.IDLE
var _turn_queue: Array[String] = []      # 行動順IDリスト
var _pending_commands: Dictionary = {}   # actor_id → BattleCommand

# ── 公開API ──────────────────────────────────────────────
func start_battle(enemies: Array[EnemyData]) -> void:
    _phase = Phase.START
    GameManager.change_state(GameManager.GameState.BATTLE_START)
    # 敵データをセットしてシーン遷移
    _enemy_roster = enemies
    EventBus.battle_started.emit(enemies)

func submit_command(actor_id: String, command: BattleCommand) -> void:
    if _phase != Phase.COMMAND:
        Logger.warn("Command submitted outside COMMAND phase", {"actor": actor_id})
        return
    _pending_commands[actor_id] = command
    _check_all_commands_ready()

func _check_all_commands_ready() -> void:
    # 全パーティーメンバーのコマンドが揃ったら実行フェーズへ
    var all_ready: bool = PartyManager.alive_members().all(
        func(m: CharacterData) -> bool: return _pending_commands.has(m.id)
    )
    if all_ready:
        _start_execution_phase()
```

---

## 3. ダメージ計算の置き場所

ダメージ計算式は `scripts/utils/battle_calc.gd` に純粋関数として実装する。

```
理由: BattleManager はフェーズ管理に集中させる。
     ダメージ式はゲームバランス調整が頻繁なため、
     副作用のない純粋関数として分離し単体テストを容易にする。
```

```gdscript
# scripts/utils/battle_calc.gd
class_name BattleCalc

# FF4 ベースの物理ダメージ計算
static func physical_damage(
    attacker: CharacterData,
    target: CharacterData,
    variance: float = 0.1
) -> int:
    var base: float = float(attacker.strength) * 2.0 - float(target.defense)
    base = maxf(base, 1.0)
    var rand_factor: float = 1.0 + randf_range(-variance, variance)
    return int(base * rand_factor)

# 魔法ダメージ計算
static func magic_damage(
    attacker: CharacterData,
    target: CharacterData,
    skill: SkillData
) -> int:
    var base: float = float(skill.power) + float(attacker.magic) - float(target.magic_defense)
    base = maxf(base, 1.0)
    return int(base * skill.element_multiplier(target.element_weakness))

# クリティカル判定
static func is_critical(attacker: CharacterData) -> bool:
    return randf() < float(attacker.luck) / 100.0

# ステータス効果の命中判定
static func status_hit(attacker: CharacterData, target: CharacterData, base_rate: float) -> bool:
    var adjusted: float = base_rate * (1.0 + float(attacker.luck - target.luck) / 100.0)
    return randf() < clampf(adjusted, 0.0, 1.0)
```

---

## 4. ターン順序管理

```gdscript
# BattleManager 内のターンキュー生成
func _build_turn_queue(
    party: Array[CharacterData],
    enemies: Array[EnemyData]
) -> Array[String]:
    var actors: Array[Dictionary] = []
    for member: CharacterData in party:
        if member.current_hp > 0:
            actors.append({"id": member.id, "agility": member.agility, "is_player": true})
    for enemy: EnemyData in enemies:
        if enemy.current_hp > 0:
            actors.append({"id": enemy.id, "agility": enemy.agility, "is_player": false})
    # 素早さ降順でソート（同値は乱数で決定）
    actors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        if a.agility != b.agility:
            return a.agility > b.agility
        return randf() > 0.5
    )
    return actors.map(func(a: Dictionary) -> String: return a.id)
```

---

## 5. GameState と戦闘フェーズの対応

```
FIELD          ← フィールド歩行中
  ↓ ランダムエンカウントまたはイベントバトル
BATTLE_START   ← 戦闘開始演出（フラッシュ・BGM切り替え）
  ↓
BATTLE_COMMAND ← パーティー全員のコマンド入力待ち（シーンが入力を受け付ける）
  ↓ 全員入力完了
BATTLE_EXECUTE ← BattleManager がターン順で処理実行（入力受け付けない）
  ↓ ターン終了 → 勝利/敗北でなければ BATTLE_COMMAND へ戻る
BATTLE_END     ← 勝利/敗北演出・EXP 計算
  ↓
FIELD          ← フィールドへ復帰
```

---

## 6. EventBus シグナル設計（戦闘系）

`autoloads/event_bus.gd` に追加するシグナル:

```gdscript
# 戦闘開始・終了
signal battle_started(enemies: Array[EnemyData])
signal battle_command_requested(actor_id: String)    # コマンド入力要求
signal battle_command_submitted(actor_id: String, command: BattleCommand)
signal battle_execution_started                      # 実行フェーズ開始
signal battle_ended(result: BattleResult)

# ダメージ・ステータス
signal damage_dealt(target_id: String, amount: int, is_critical: bool)
signal healing_received(target_id: String, amount: int)
signal status_applied(target_id: String, status: String)
signal actor_defeated(actor_id: String)

# 報酬（BattleManager → PartyManager 経由でなく EventBus 経由）
signal exp_gained(amounts: Dictionary)   # {actor_id: int}
signal gold_gained(amount: int)
signal item_dropped(item_id: String)
```

---

## 7. フィールド → バトル遷移パターン

```gdscript
# autoloads/encounter_manager.gd
func _on_player_moved(steps: int) -> void:
    _step_counter += 1
    if _step_counter >= _encounter_threshold:
        _step_counter = 0
        _encounter_threshold = _roll_next_threshold()
        var enemies: Array[EnemyData] = _roll_encounter()
        BattleManager.start_battle(enemies)

# SceneManager はバトルシーンへ遷移させる
# (BattleManager.start_battle → EventBus.battle_started → SceneManager が購読して遷移)
```

---

## 8. BattleCommand データ定義

```gdscript
# scripts/data/battle_command.gd
class_name BattleCommand
extends RefCounted

enum Type {
    ATTACK,
    MAGIC,
    ITEM,
    DEFEND,
    RUN,
}

var type: Type = Type.ATTACK
var actor_id: String = ""
var target_ids: Array[String] = []   # 全体攻撃なら複数
var skill: SkillData = null          # MAGIC の場合
var item: ItemData = null            # ITEM の場合
```

---

## 9. テスト設計の指針

`scripts/utils/battle_calc.gd` のダメージ計算はシーン不要なので単体テスト必須:

```gdscript
# tests/unit/test_battle_calc.gd
extends GutTest

func test_physical_damage_minimum_is_1() -> void:
    var attacker: CharacterData = CharacterData.new()
    attacker.strength = 1
    var target: CharacterData = CharacterData.new()
    target.defense = 9999
    var result: int = BattleCalc.physical_damage(attacker, target)
    assert_true(result >= 1, "最低ダメージは1以上")

func test_magic_weakness_multiplier() -> void:
    var skill: SkillData = SkillData.new()
    skill.power = 100
    skill.element = SkillData.Element.FIRE
    var target: CharacterData = CharacterData.new()
    target.element_weakness = SkillData.Element.FIRE
    var attacker: CharacterData = CharacterData.new()
    var normal: int = BattleCalc.magic_damage(attacker, target, skill)
    # 弱点属性は 1.5〜2.0 倍期待
    assert_true(normal > 100, "弱点属性はダメージが増加する")
```
