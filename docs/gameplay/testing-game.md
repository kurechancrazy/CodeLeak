# Testing Game Logic — ゲーム固有のテストパターン

**対象:** Godot 4.4+ / GDScript 2.0 / GUT 4.x

基本的なテスト規約（GUT の使い方・アサーション・3区分）は `docs/quality/testing.md` を参照。
このドキュメントはゲーム特有の「何をどうテストするか」を扱う。

---

## テスト可能領域とテスト不可領域

```
テスト可能（単体テスト推奨）:
  ✅ スコア・HP・残機 などの数値計算
  ✅ 勝敗判定ロジック（is_game_over, check_win_condition）
  ✅ インベントリ・アイテム管理
  ✅ セーブ・ロードデータの検証
  ✅ EventBus シグナルの発火確認
  ✅ 設定値のバリデーション

テスト不可（単体テスト不向き）:
  ⚠️ _physics_process / _process の毎フレーム挙動
  ⚠️ Tween / AnimationPlayer の再生確認
  ⚠️ ノードの描画・レイアウト確認
  ⚠️ 物理衝突の発生タイミング

テスト不可領域の代替戦略:
  → ゲームロジックを Autoload に切り出し、そこを単体テストする
  → シーンスクリプトには「EventBus に emit するだけ」の薄いコードのみ残す
  → 物理演算は手動テストで確認し、tasks.md に「手動確認済み」を記録する
```

---

## Autoload のモックパターン

テスト中に本物の Autoload を使うと、テスト間で状態が汚染される。
GUT の `add_child_autofree()` を使って独立したインスタンスを生成する。

```gdscript
# tests/unit/test_game_manager.gd
extends GutTest

var _game_manager: Node = null
var _event_bus: Node = null

func before_each() -> void:
    # 本物の Autoload は使わず、独立したインスタンスを生成
    _event_bus = preload("res://autoloads/event_bus.gd").new()
    add_child_autofree(_event_bus)

    _game_manager = preload("res://autoloads/game_manager.gd").new()
    add_child_autofree(_game_manager)

func test_score_increases_on_item_collected() -> void:
    _game_manager.score = 0
    _event_bus.item_collected.emit(100)
    assert_eq(_game_manager.score, 100, "アイテム取得でスコアが増加すること")
```

**ポイント:** グローバルの `GameManager` シングルトンは使わない。
テスト用に独立したインスタンスを生成してテスト間の汚染を防ぐ。

---

## ゲーム状態のテストパターン

### スコア計算

```gdscript
func test_score_with_combo_multiplier() -> void:
    _game_manager.combo = 3
    _game_manager.add_score(100)
    # コンボ3倍 + ベーススコア100
    assert_eq(_game_manager.score, 300, "コンボ倍率が正しく適用されること")

func test_score_does_not_go_negative() -> void:
    _game_manager.score = 50
    _game_manager.add_score(-100)
    assert_gte(_game_manager.score, 0, "スコアは0以下にならないこと")
```

### 勝敗判定

```gdscript
func test_game_over_when_hp_reaches_zero() -> void:
    watch_signals(_event_bus)
    _game_manager.hp = 1
    _game_manager.take_damage(1)
    assert_eq(_game_manager.hp, 0)
    assert_signal_emitted(_event_bus, "game_over", "HP0でgame_overシグナルが発火すること")

func test_game_over_not_triggered_above_zero() -> void:
    watch_signals(_event_bus)
    _game_manager.hp = 10
    _game_manager.take_damage(5)
    assert_signal_not_emitted(_event_bus, "game_over")
```

### レベル進行

```gdscript
func test_level_unlocks_after_score_threshold() -> void:
    _game_manager.score = 0
    _game_manager.add_score(LEVEL_2_THRESHOLD)
    assert_true(_game_manager.is_level_unlocked(2), "閾値スコア到達でレベル2が解放されること")

func test_level_not_unlocked_below_threshold() -> void:
    _game_manager.score = LEVEL_2_THRESHOLD - 1
    assert_false(_game_manager.is_level_unlocked(2))
```

---

## EventBus シグナルのテスト

```gdscript
func test_item_pickup_emits_score_changed() -> void:
    watch_signals(_event_bus)

    # アクション実行
    _game_manager.collect_item("coin_gold")

    # シグナル確認
    assert_signal_emitted(_event_bus, "score_changed")
    assert_signal_emitted_with_parameters(_event_bus, "score_changed", [100])
```

---

## セーブデータのテスト

セーブ・ロードテストは `user://` ではなく専用のテストパスを使う。

```gdscript
const TEST_SAVE_PATH: String = "user://test_save_game.cfg"

var _save_manager: Node = null

func before_each() -> void:
    _save_manager = preload("res://autoloads/save_manager.gd").new()
    # テスト用パスを注入できるよう SaveManager に SAVE_PATH を変数にしておく
    _save_manager.SAVE_PATH = TEST_SAVE_PATH
    add_child_autofree(_save_manager)

func after_each() -> void:
    if FileAccess.file_exists(TEST_SAVE_PATH):
        DirAccess.remove_absolute(TEST_SAVE_PATH)

func test_game_state_persists_across_save_load() -> void:
    _save_manager.set_value("player", "level", 5)
    _save_manager.set_value("player", "score", 8500)
    _save_manager.save_game()

    # 別インスタンスでロード（再起動をシミュレート）
    var new_save: Node = preload("res://autoloads/save_manager.gd").new()
    new_save.SAVE_PATH = TEST_SAVE_PATH
    add_child_autofree(new_save)
    new_save.load_game()

    assert_eq(new_save.get_value("player", "level", 0), 5)
    assert_eq(new_save.get_value("player", "score", 0), 8500)
```

---

## 物理演算・プロセスロジックのテスト戦略

`_physics_process` / `_process` に書いたロジックは直接テストできない。
**解決策: 計算ロジックを純粋関数に切り出す。**

```gdscript
# autoloads/game_manager.gd
# ❌ テストしにくい: _physics_process 内にロジック
func _physics_process(delta: float) -> void:
    velocity.y += gravity * delta
    if velocity.y > max_fall_speed:
        velocity.y = max_fall_speed

# ✅ テスト可能: ロジックを純粋関数に切り出す
func calculate_gravity_velocity(current_vy: float, gravity: float, max_fall: float, delta: float) -> float:
    return minf(current_vy + gravity * delta, max_fall)

func _physics_process(delta: float) -> void:
    velocity.y = calculate_gravity_velocity(velocity.y, GRAVITY, MAX_FALL_SPEED, delta)
```

```gdscript
# tests/unit/test_gravity_calculation.gd
func test_gravity_accelerates_downward() -> void:
    var result: float = GameLogic.calculate_gravity_velocity(0.0, 980.0, 600.0, 0.016)
    assert_gt(result, 0.0, "重力で下向きに加速すること")

func test_gravity_capped_at_max_fall_speed() -> void:
    var result: float = GameLogic.calculate_gravity_velocity(590.0, 980.0, 600.0, 0.016)
    assert_lte(result, 600.0, "最大落下速度を超えないこと")
```

---

## テスト対象早見表（ゲーム開発版）

| 対象 | テスト方針 |
|------|----------|
| スコア・HP・残機計算 | **必須** — 単体テスト |
| 勝敗・レベル進行判定 | **必須** — 単体テスト |
| アイテム・インベントリ管理 | **必須** — 単体テスト |
| セーブ・ロード | **必須** — 単体テスト（テスト用パスを使用） |
| EventBus シグナル発火 | **必須** — watch_signals で確認 |
| 移動・物理演算 | **推奨** — 計算関数に切り出して単体テスト |
| UI の表示切り替え | **任意** — ロジックを Autoload に切り出し、そこをテスト |
| アニメーション・Tween | **不要** — 手動確認で対応 |
| 物理衝突の発生タイミング | **不要** — 手動確認で対応 |
