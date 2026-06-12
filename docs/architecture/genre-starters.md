# ジャンル別クイックスタートバンドル

**タイミング:** `_init.md` の初期化完了直後、最初のシーン実装前に実施する。
**目的:** Physics Layer・InputMap・GameState・Autoload を一括定義して「設定の迷い」をゼロにする。

各バンドルは `docs/architecture/initial-decisions.md` の詳細設計と合わせて使う。

---

## バンドルの使い方

1. 下記からゲームジャンルに合うバンドルを選ぶ
2. **Physics Layer** → `Project Settings > Layer Names > 3D/2D Physics` に貼り付ける
3. **InputMap** → `Project Settings > Input Map` に追加する（または `project.godot` に直接記述）
4. **GameState** → `autoloads/game_manager.gd` の enum を置き換える
5. **追加 Autoload** → `project.godot` の `[autoload]` セクションに追記し、ファイルを作成する

---

## バンドル 1: 2D アクション / プラットフォーマー

### Physics Layer（2D）

| Layer | 名前 | 用途 |
|-------|------|------|
| 1 | world | 地形・StaticBody2D（床・壁・天井） |
| 2 | player | プレイヤー本体 |
| 3 | enemy | 敵本体 |
| 4 | player_attack | プレイヤーの攻撃判定 |
| 5 | enemy_attack | 敵の攻撃判定 |
| 6 | item | コイン・回復・アイテム |
| 7 | trigger | ゴール・チェックポイント・イベントゾーン |

### InputMap

| アクション名 | PC デフォルト | ゲームパッド |
|------------|-------------|-----------|
| `move_left` | A / ←キー | 左スティック左 / D-Pad 左 |
| `move_right` | D / →キー | 左スティック右 / D-Pad 右 |
| `jump` | Space / W / ↑キー | A（Xbox）/ ✕（PS） |
| `attack` | Z / Jキー | X（Xbox）/ □（PS） |
| `interact` | Eキー | B（Xbox）/ ○（PS） |
| `dash` | Shift | RB / R1 |
| `pause` | Esc | Start |

### GameState

```gdscript
enum GameState {
    BOOT,
    MAIN_MENU,
    STAGE_SELECT,
    PLAYING,
    PAUSED,
    STAGE_CLEAR,
    GAME_OVER,
    GAME_CLEAR,
}
```

### 追加 Autoload（推奨）

| Autoload | ファイル | 役割 |
|---------|---------|------|
| StageManager | `autoloads/stage_manager.gd` | ステージ進行・クリア管理 |

---

## バンドル 2: パズルゲーム

### Physics Layer（2D）

| Layer | 名前 | 用途 |
|-------|------|------|
| 1 | world | 固定壁・床 |
| 2 | block | 動かせるブロック |
| 3 | player | プレイヤーキャラ |
| 4 | goal | ゴールゾーン |
| 5 | trigger | スイッチ・イベントゾーン |

### InputMap

| アクション名 | PC デフォルト | ゲームパッド |
|------------|-------------|-----------|
| `move_left` | A / ←キー | 左スティック左 / D-Pad 左 |
| `move_right` | D / →キー | 左スティック右 / D-Pad 右 |
| `move_up` | W / ↑キー | 左スティック上 / D-Pad 上 |
| `move_down` | S / ↓キー | 左スティック下 / D-Pad 下 |
| `confirm` | Enter / Z | A（Xbox）/ ✕（PS） |
| `cancel` | Esc / X | B（Xbox）/ ○（PS） |
| `undo` | Ctrl+Z / U | Y（Xbox）/ △（PS） |
| `reset_level` | R | Select |
| `pause` | Esc | Start |

### GameState

```gdscript
enum GameState {
    BOOT,
    MAIN_MENU,
    LEVEL_SELECT,
    PLAYING,
    ANIMATING,   # ブロック移動などのアニメーション再生中（入力無効）
    LEVEL_CLEAR,
    LEVEL_FAILED,
    PAUSED,
    GAME_CLEAR,
}
```

### 追加 Autoload（推奨）

| Autoload | ファイル | 役割 |
|---------|---------|------|
| LevelManager | `autoloads/level_manager.gd` | レベルデータ・進捗・星評価 |

---

## バンドル 3: 3D 探索 / アドベンチャー

### Physics Layer（3D）

| Layer | 名前 | 用途 |
|-------|------|------|
| 1 | world | 地形・StaticBody3D |
| 2 | player | プレイヤー本体 |
| 3 | npc | NPC・会話キャラ |
| 4 | enemy | 敵本体 |
| 5 | item | 拾えるアイテム |
| 6 | interact_zone | インタラクト可能ゾーン（扉・宝箱等） |
| 7 | trigger | イベントトリガー |
| 8 | damage_zone | 落下穴・ダメージゾーン |

### InputMap

| アクション名 | PC デフォルト | ゲームパッド |
|------------|-------------|-----------|
| `move_forward` | W / ↑キー | 左スティック上 |
| `move_back` | S / ↓キー | 左スティック下 |
| `move_left` | A / ←キー | 左スティック左 |
| `move_right` | D / →キー | 左スティック右 |
| `jump` | Space | A（Xbox）/ ✕（PS） |
| `interact` | Eキー | B（Xbox）/ ○（PS） |
| `sprint` | Shift | LS 押し込み |
| `camera_left` | ←キー | 右スティック左 |
| `camera_right` | →キー | 右スティック右 |
| `camera_up` | ↑キー | 右スティック上 |
| `camera_down` | ↓キー | 右スティック下 |
| `menu` | Tab / I | Y（Xbox）/ △（PS） |
| `pause` | Esc | Start |

### project.godot の追加設定（3D 向け）

```ini
[display]
window/size/viewport_width=1920
window/size/viewport_height=1080

[rendering]
renderer/rendering_method="forward_plus"
renderer/rendering_method.mobile="mobile"
```

### GameState

```gdscript
enum GameState {
    BOOT,
    MAIN_MENU,
    LOADING,     # フィールドロード中
    FIELD,       # フィールド探索中
    DIALOG,      # NPC 会話中（移動不可）
    INVENTORY,   # インベントリ画面
    PAUSED,
    GAME_OVER,
    ENDING,
}
```

### 追加 Autoload（推奨）

| Autoload | ファイル | 役割 |
|---------|---------|------|
| InventoryManager | `autoloads/inventory_manager.gd` | アイテム所持・使用管理 |
| DialogManager | `autoloads/dialog_manager.gd` | NPC 会話・テキスト表示 |
| QuestManager | `autoloads/quest_manager.gd` | クエスト進行・達成条件 |

---

## バンドル 4: ノベル / ビジュアルノベル / カードゲーム（UI 専用）

### Physics Layer

不要（Control ノード中心のため物理演算なし）。
UI 専用の場合は `Project Settings > General > 2D Physics` を無効化することを検討する。

### InputMap

| アクション名 | PC デフォルト | ゲームパッド |
|------------|-------------|-----------|
| `confirm` | Enter / Space / Zキー | A（Xbox）/ ✕（PS） |
| `cancel` | Esc / Xキー | B（Xbox）/ ○（PS） |
| `skip` | Ctrl | RB / R1 |
| `auto` | Aキー | Y（Xbox）/ △（PS） |
| `log` | Lキー | Select |
| `menu` | Escキー | Start |

### project.godot の追加設定（UI 専用・縦画面向け）

```ini
[display]
window/size/viewport_width=1080
window/size/viewport_height=1920
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
```

### GameState

```gdscript
enum GameState {
    BOOT,
    MAIN_MENU,
    STORY,         # テキスト表示・クリック待ち
    CHOICE_WAIT,   # 選択肢表示中
    AUTO_PLAY,     # 自動再生中
    SKIP,          # スキップ中
    LOG,           # バックログ表示中
    PAUSED,
    ENDING,
    GALLERY,       # CG ギャラリー等
}
```

### 追加 Autoload（推奨）

| Autoload | ファイル | 役割 |
|---------|---------|------|
| ScriptReader | `autoloads/script_reader.gd` | シナリオデータ読み込み・進行管理 |
| FlagManager | `autoloads/flag_manager.gd` | 選択フラグ・ルート管理 |

---

## バンドル 5: 2D JRPG（ターンベース / FF4・5・6 スタイル）

### Physics Layer（2D）

フィールドと戦闘で使用するレイヤーを統合定義する。
戦闘中は BattleManager がシーンを管理するため物理判定は主にフィールドで使用。

| Layer | 名前 | 用途 |
|-------|------|------|
| 1 | world | 地形・StaticBody2D（壁・障害物） |
| 2 | player | プレイヤーキャラ（CharacterBody2D） |
| 3 | npc | NPC・会話可能キャラ |
| 4 | enemy | フィールド上の敵シンボル（シンボルエンカウント用） |
| 5 | item | フィールド上の宝箱・拾えるアイテム |
| 6 | trigger | イベントトリガー・扉・エリア移動ゾーン |

```ini
[layer_names]
2d_physics/layer_1="world"
2d_physics/layer_2="player"
2d_physics/layer_3="npc"
2d_physics/layer_4="enemy"
2d_physics/layer_5="item"
2d_physics/layer_6="trigger"
```

### InputMap

| アクション名 | PC デフォルト | ゲームパッド |
|------------|-------------|-----------|
| `move_left` | A / ←キー | 左スティック左 / D-Pad 左 |
| `move_right` | D / →キー | 左スティック右 / D-Pad 右 |
| `move_up` | W / ↑キー | 左スティック上 / D-Pad 上 |
| `move_down` | S / ↓キー | 左スティック下 / D-Pad 下 |
| `confirm` | Enter / Z | A（Xbox）/ ✕（PS） |
| `cancel` | Esc / X | B（Xbox）/ ○（PS） |
| `menu` | Esc / I | Start / Options |
| `run` | Shift（長押し） | B（Xbox）/ ○（PS）長押し |
| `shortcut_1` | Q | LB / L1 |
| `shortcut_2` | E | RB / R1 |

### GameState

```gdscript
enum GameState {
    BOOT,
    MAIN_MENU,
    LOADING,         # フィールドマップのロード中
    FIELD,           # フィールド探索中（プレイヤー操作可）
    DIALOG,          # NPC 会話中（移動不可、テキスト送り可）
    MENU,            # RPG メニュー表示中（アイテム・装備・ステータス等）
    BATTLE_START,    # 戦闘開始演出（フラッシュ・BGM切り替え）
    BATTLE_COMMAND,  # コマンド入力待ち（全パーティーメンバー分）
    BATTLE_EXECUTE,  # コマンド実行中（アニメーション・ダメージ処理）
    BATTLE_END,      # 戦闘終了演出（EXP・ゴールド表示）
    GAME_OVER,
    ENDING,
    PAUSED,
}
```

### project.godot の追加設定（ドット絵 JRPG）

```ini
[display]
window/size/viewport_width=320
window/size/viewport_height=240
window/size/window_width_override=960
window/size/window_height_override=720
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"

[rendering]
textures/canvas_textures/default_texture_filter=0
2d/snap/snap_2d_transforms_to_pixel=true
```

詳細は `docs/rpg/pixel-art-setup.md` を参照。

### 追加 Autoload（推奨）

初期化順序の後ろから追加すること（`docs/architecture/initial-decisions.md` セクション 4 参照）。

| Autoload | ファイル | 役割 |
|---------|---------|------|
| PartyManager | `autoloads/party_manager.gd` | パーティー編成・ステータス管理 |
| InventoryManager | `autoloads/inventory_manager.gd` | アイテム所持・使用・装備管理 |
| BattleManager | `autoloads/battle_manager.gd` | 戦闘フェーズ管理・ターン制御 |
| EncounterManager | `autoloads/encounter_manager.gd` | ランダムエンカウント判定 |
| DialogManager | `autoloads/dialog_manager.gd` | NPC 会話・テキスト制御 |
| FlagManager | `autoloads/flag_manager.gd` | ゲーム進行フラグ（イベントスイッチ） |

初期化順序（推奨）:
```
Logger → EventBus → GameManager → PartyManager → InventoryManager
       → BattleManager → EncounterManager → DialogManager → FlagManager
       → SceneManager → SaveManager → AudioManager
```

### 必読ドキュメント（実装開始前）

| 実装内容 | 読むドキュメント |
|---------|----------------|
| ドット絵プロジェクト設定 | `docs/rpg/pixel-art-setup.md` |
| ターンベース戦闘を実装 | `docs/rpg/battle-system.md` |
| フィールドマップ・エンカウント | `docs/rpg/field-system.md` |
| ダイアログ・NPC 会話 | `docs/rpg/dialog-system.md` |
| RPG メニュー（アイテム・装備等） | `docs/rpg/menu-system.md` |

---

## バンドル 6: メトロイドヴァニア

詳細: `docs/genres/metroidvania.md`

### Physics Layer（2D）

| Layer | 名前 | 用途 |
|-------|------|------|
| 1 | world | 地形・StaticBody2D |
| 2 | player | プレイヤー |
| 3 | enemy | 敵 |
| 4 | player_attack | 攻撃判定 |
| 5 | enemy_attack | 敵攻撃判定 |
| 6 | item | 能力アイテム・拾得物 |
| 7 | breakable | 破壊可能な壁・床 |

### InputMap

| アクション名 | PC デフォルト | ゲームパッド |
|------------|-------------|-----------|
| `move_left` | A / ←キー | D-Pad 左 |
| `move_right` | D / →キー | D-Pad 右 |
| `jump` | Space / W | A / ✕ |
| `attack` | Z | X / □ |
| `dash` | Shift | RB / R1 |
| `interact` | Eキー | B / ○ |
| `use_ability` | Q | LB / L1 |
| `map` | Mキー | Select |
| `pause` | Esc | Start |

### GameState

```gdscript
enum GameState {
    BOOT,
    MAIN_MENU,
    LOADING,
    EXPLORING,   # 通常探索
    DIALOG,
    MAP_VIEW,    # マップ画面表示中
    PAUSED,
    GAME_OVER,
    ENDING,
}
```

### 追加 Autoload（推奨）

| Autoload | ファイル | 役割 |
|---------|---------|------|
| MapStateManager | `autoloads/map_state_manager.gd` | 部屋状態・破壊壁・扉の永続化 |
| ProgressManager | `autoloads/progress_manager.gd` | アビリティ解放・収集率 |

---

## バンドル 7: 横スクロールシューティング / 弾幕

詳細: `docs/genres/shmup.md`

### Physics Layer（2D）

| Layer | 名前 | 用途 |
|-------|------|------|
| 1 | world | 地形・障害物 |
| 2 | player | プレイヤー機（実際の当たり判定） |
| 3 | enemy | 敵機 |
| 4 | player_bullet | 自機弾 |
| 5 | enemy_bullet | 敵弾 |
| 6 | pickup | パワーアップ |

### InputMap

| アクション名 | PC デフォルト | ゲームパッド |
|------------|-------------|-----------|
| `move_left` | ←キー / A | D-Pad 左 / 左スティック左 |
| `move_right` | →キー / D | D-Pad 右 / 左スティック右 |
| `move_up` | ↑キー / W | D-Pad 上 / 左スティック上 |
| `move_down` | ↓キー / S | D-Pad 下 / 左スティック下 |
| `fire` | Z / Space | A / ✕（長押し） |
| `bomb` | X | B / ○ |
| `pause` | Esc | Start |

### GameState

```gdscript
enum GameState {
    BOOT,
    MAIN_MENU,
    STAGE_INTRO,
    PLAYING,
    BOSS_FIGHT,
    STAGE_CLEAR,
    GAME_OVER,
    HIGH_SCORE,
    PAUSED,
}
```

### 追加 Autoload（推奨）

| Autoload | ファイル | 役割 |
|---------|---------|------|
| WaveManager | `autoloads/wave_manager.gd` | ウェーブ番号・残敵カウント |
| ProgressManager | `autoloads/progress_manager.gd` | ハイスコア・実績 |

---

## バンドル 8: 見下ろし型アクション RPG

詳細: `docs/genres/arpg-topdown.md`

### Physics Layer（2D）

| Layer | 名前 | 用途 |
|-------|------|------|
| 1 | world | 地形・壁 |
| 2 | player | プレイヤー |
| 3 | enemy | 敵 |
| 4 | player_attack | 武器判定 |
| 5 | enemy_attack | 敵攻撃判定 |
| 6 | item | ドロップアイテム |
| 7 | npc | NPC・会話キャラ |
| 8 | interact | インタラクト可能オブジェクト |

### InputMap

| アクション名 | PC デフォルト | ゲームパッド |
|------------|-------------|-----------|
| `move_left` | A / ←キー | 左スティック左 |
| `move_right` | D / →キー | 左スティック右 |
| `move_up` | W / ↑キー | 左スティック上 |
| `move_down` | S / ↓キー | 左スティック下 |
| `attack` | Zキー / LMB | X / □ |
| `dodge` | Shift / RMB | B / ○ |
| `interact` | Eキー | A / ✕ |
| `use_skill_1` | Q | LB / L1 |
| `use_skill_2` | E | RB / R1 |
| `menu` | Tab / I | Y / △ |
| `pause` | Esc | Start |

### GameState

```gdscript
enum GameState {
    BOOT,
    MAIN_MENU,
    LOADING,
    FIELD,
    DIALOG,
    INVENTORY,
    QUEST_LOG,
    PAUSED,
    GAME_OVER,
    ENDING,
}
```

### 追加 Autoload（推奨）

| Autoload | ファイル | 役割 |
|---------|---------|------|
| QuestManager | `autoloads/quest_manager.gd` | クエスト進行・達成判定 |
| InventoryManager | `autoloads/inventory_manager.gd` | アイテム・装備管理 |
| ProgressManager | `autoloads/progress_manager.gd` | 実績・クリア率 |

---

## バンドル 9: ローグライク / ローグライト

詳細: `docs/genres/roguelike.md`

### Physics Layer（2D）

| Layer | 名前 | 用途 |
|-------|------|------|
| 1 | world | 地形・StaticBody2D |
| 2 | player | プレイヤー |
| 3 | enemy | 敵 |
| 4 | player_attack | 攻撃判定 |
| 5 | enemy_attack | 敵攻撃判定 |
| 6 | pickup | ランアイテム・金貨 |

### InputMap

バンドル 1（2D アクション）の InputMap と同じ構成で可。

### GameState

```gdscript
enum GameState {
    BOOT,
    MAIN_MENU,
    RUN_START,     # ラン開始（キャラ・開始ボーナス選択）
    DUNGEON,       # ダンジョン探索中
    REWARD,        # 報酬選択中
    SHOP,          # ショップ
    BOSS_FIGHT,
    RUN_END,       # クリア または デス
    PAUSED,
    META_MENU,     # アンロック・統計
}
```

### 追加 Autoload（推奨）

| Autoload | ファイル | 役割 |
|---------|---------|------|
| RunManager | `autoloads/run_manager.gd` | ランの進行状態・ランスコア |
| ProgressManager | `autoloads/progress_manager.gd` | アンロック・メタ進行 |

---

## バンドル 10: タワーディフェンス

詳細: `docs/genres/tower-defense.md`

### Physics Layer（2D）

| Layer | 名前 | 用途 |
|-------|------|------|
| 1 | world | 地形・パス外エリア |
| 2 | enemy | 敵（パスを移動） |
| 3 | tower_range | タワーの射程判定（Area2D） |
| 4 | bullet | タワー弾 |

### InputMap

| アクション名 | PC デフォルト | ゲームパッド |
|------------|-------------|-----------|
| `click` | LMB | A / ✕ |
| `cancel` | RMB / Esc | B / ○ |
| `speed_up` | Spaceキー | Y / △ |
| `pause` | Esc | Start |

### GameState

```gdscript
enum GameState {
    BOOT,
    MAIN_MENU,
    LEVEL_SELECT,
    PREP_PHASE,    # ウェーブ開始前のタワー配置時間
    WAVE,          # ウェーブ進行中
    BETWEEN_WAVES, # ウェーブ間（配置・強化）
    STAGE_CLEAR,
    GAME_OVER,
    PAUSED,
}
```

### 追加 Autoload（推奨）

| Autoload | ファイル | 役割 |
|---------|---------|------|
| WaveManager | `autoloads/wave_manager.gd` | ウェーブ番号・残敵カウント |

---

## バンドル 11: SRPG（シミュレーション RPG）

詳細: `docs/genres/srpg.md`

### Physics Layer（2D）

SRPG ではリアルタイム物理演算が不要なため、Physics Layer は最小限に留める。

| Layer | 名前 | 用途 |
|-------|------|------|
| 1 | world | 地形タイル（障害物判定） |
| 2 | unit | ユニット（クリック検出用） |
| 3 | cursor | カーソルレイヤー |

### InputMap

| アクション名 | PC デフォルト | ゲームパッド |
|------------|-------------|-----------|
| `cursor_left` | ←キー / A | D-Pad 左 |
| `cursor_right` | →キー / D | D-Pad 右 |
| `cursor_up` | ↑キー / W | D-Pad 上 |
| `cursor_down` | ↓キー / S | D-Pad 下 |
| `confirm` | Enter / Z | A / ✕ |
| `cancel` | Esc / X | B / ○ |
| `end_turn` | Eキー | Y / △ |
| `pause` | Esc | Start |

### GameState

```gdscript
enum GameState {
    BOOT,
    MAIN_MENU,
    LOADING,
    PLAYER_SELECT,    # ユニット選択待ち
    PLAYER_MOVE,      # 移動先選択中
    PLAYER_ACTION,    # 行動選択（攻撃・アイテム・待機）
    ANIMATING,        # 移動・攻撃アニメーション再生中（入力無効）
    ENEMY_TURN,       # 敵ターン AI 実行中
    RESULT,           # 勝利・敗北判定
    PAUSED,
}
```

### 追加 Autoload（推奨）

なし（GridUtils ユーティリティのみ使用）。

---

## バンドル 12: 農業 / 生活シム

詳細: `docs/genres/farming-sim.md`

### Physics Layer（2D）

| Layer | 名前 | 用途 |
|-------|------|------|
| 1 | world | 地形・StaticBody2D |
| 2 | player | プレイヤー |
| 3 | npc | NPC |
| 4 | crop_zone | 農地判定（Area2D） |
| 5 | interact | インタラクト可能オブジェクト |

### InputMap

| アクション名 | PC デフォルト | ゲームパッド |
|------------|-------------|-----------|
| `move_left` | A / ←キー | 左スティック左 |
| `move_right` | D / →キー | 左スティック右 |
| `move_up` | W / ↑キー | 左スティック上 |
| `move_down` | S / ↓キー | 左スティック下 |
| `use_tool` | Zキー / LMB | X / □ |
| `switch_tool_prev` | Qキー | LB / L1 |
| `switch_tool_next` | Eキー | RB / R1 |
| `interact` | Fキー | A / ✕ |
| `menu` | Escキー / Iキー | Start |

### GameState

```gdscript
enum GameState {
    BOOT,
    MAIN_MENU,
    FIELD,           # フィールド操作中
    DIALOG,          # NPC 会話中
    SHOP,            # 店内
    INVENTORY,       # リュック・箱管理
    SLEEP_CONFIRM,   # 就寝確認ダイアログ
    SLEEPING,        # 日付遷移アニメーション
    PAUSED,
}
```

### 追加 Autoload（推奨）

| Autoload | ファイル | 役割 |
|---------|---------|------|
| TimeManager | `autoloads/time_manager.gd` | ゲーム内時計・日付・季節 |

---

## バンドル 13: カードゲーム / デッキビルダー

詳細: `docs/genres/card-game.md`

### Physics Layer

不要（Control ノード中心）。

### InputMap

| アクション名 | PC デフォルト | ゲームパッド |
|------------|-------------|-----------|
| `confirm` | Enter / Z | A / ✕ |
| `cancel` | Esc / X | B / ○ |
| `end_turn` | Eキー | Y / △ |
| `pause` | Esc | Start |

### GameState

```gdscript
enum GameState {
    BOOT,
    MAIN_MENU,
    DECK_BUILD,       # デッキ構築画面
    BATTLE_START,
    PLAYER_TURN,      # プレイヤーターン（カード選択・使用）
    ENEMY_TURN,
    REWARD_SELECT,    # 報酬カード選択
    RUN_CLEAR,
    RUN_FAILED,
    PAUSED,
}
```

### 追加 Autoload（推奨）

| Autoload | ファイル | 役割 |
|---------|---------|------|
| DeckManager | `autoloads/deck_manager.gd` | 山札・手札・捨て山の管理 |
| RunManager | `autoloads/run_manager.gd` | ランの進行状態（デッキビルダーの場合） |

---

## バンドル 14: 格闘ゲーム

詳細: `docs/genres/fighting.md`

### Physics Layer（2D）

| Layer | 名前 | 用途 |
|-------|------|------|
| 1 | world | ステージ地形 |
| 2 | fighter_1 | P1 本体 |
| 3 | fighter_2 | P2 本体 |
| 4 | hit_1 | P1 攻撃判定 |
| 5 | hit_2 | P2 攻撃判定 |
| 6 | hurt_1 | P1 くらい判定 |
| 7 | hurt_2 | P2 くらい判定 |

### InputMap

| アクション名 | PC デフォルト | ゲームパッド |
|------------|-------------|-----------|
| `p1_left` | ←キー | D-Pad 左 |
| `p1_right` | →キー | D-Pad 右 |
| `p1_up` | ↑キー | D-Pad 上（ジャンプ） |
| `p1_down` | ↓キー | D-Pad 下（しゃがみ） |
| `p1_light` | Zキー | X / □ |
| `p1_heavy` | Xキー | Y / △ |
| `p1_special` | Cキー | A / ✕ |
| `p1_guard` | Aキー | RB / R1 |
| `pause` | Enter | Start |

### GameState

```gdscript
enum GameState {
    BOOT,
    MAIN_MENU,
    CHARACTER_SELECT,
    ROUND_INTRO,    # "ROUND 1 FIGHT!" 演出
    FIGHTING,
    ROUND_RESULT,   # KO / 時間切れ
    MATCH_RESULT,   # 試合終了
    PAUSED,
}
```

### 追加 Autoload（推奨）

| Autoload | ファイル | 役割 |
|---------|---------|------|
| InputBuffer | `autoloads/input_buffer.gd` | コンボ入力の時間窓判定 |

---

## バンドル 15: 2D ホラー / サバイバル

詳細: `docs/genres/horror-2d.md`

### Physics Layer（2D）

| Layer | 名前 | 用途 |
|-------|------|------|
| 1 | world | 地形・壁 |
| 2 | player | プレイヤー |
| 3 | enemy | 敵 |
| 4 | interact | インタラクト可能オブジェクト |
| 5 | light_blocker | 光を遮るオブジェクト（2D ライト用） |

### InputMap

| アクション名 | PC デフォルト | ゲームパッド |
|------------|-------------|-----------|
| `move_left` | A / ←キー | 左スティック左 |
| `move_right` | D / →キー | 左スティック右 |
| `move_up` | W / ↑キー | 左スティック上 |
| `move_down` | S / ↓キー | 左スティック下 |
| `interact` | Eキー | A / ✕ |
| `run` | Shift | LS 押し込み |
| `inventory` | Tab / Iキー | Y / △ |
| `pause` | Esc | Start |

### GameState

```gdscript
enum GameState {
    BOOT,
    MAIN_MENU,
    LOADING,
    EXPLORING,
    DIALOG,
    INVENTORY,
    SCARE_EVENT,  # 恐怖イベント演出中（入力制限）
    PAUSED,
    GAME_OVER,
    ENDING,
}
```

---

## バンドル 16: 3D プラットフォーマー

詳細: `docs/genres/3d-platformer.md`

### Physics Layer（3D）

| Layer | 名前 | 用途 |
|-------|------|------|
| 1 | world | 地形・StaticBody3D |
| 2 | player | プレイヤー |
| 3 | enemy | 敵 |
| 4 | collectible | コイン・アイテム |
| 5 | trigger | ゴール・チェックポイント |

### InputMap

バンドル 3（3D 探索）の InputMap と同じ構成で可。

### GameState

```gdscript
enum GameState {
    BOOT,
    MAIN_MENU,
    LOADING,
    PLAYING,
    STAGE_CLEAR,
    GAME_OVER,
    GAME_CLEAR,
    PAUSED,
}
```

### project.godot の追加設定（3D）

```ini
[rendering]
renderer/rendering_method="forward_plus"
renderer/rendering_method.mobile="mobile"
```

---

## バンドル 17: 3D アクション / アドベンチャー

詳細: `docs/genres/3d-action.md`

### Physics Layer（3D）

バンドル 3（3D 探索）と同じ構成に、攻撃判定レイヤーを追加する。

| Layer | 名前 | 用途 |
|-------|------|------|
| 1 | world | 地形 |
| 2 | player | プレイヤー |
| 3 | enemy | 敵本体 |
| 4 | player_attack | 武器判定 |
| 5 | enemy_attack | 敵攻撃判定 |
| 6 | item | ドロップアイテム |

### InputMap

| アクション名 | PC デフォルト | ゲームパッド |
|------------|-------------|-----------|
| `move_forward` | W | 左スティック上 |
| `move_back` | S | 左スティック下 |
| `move_left` | A | 左スティック左 |
| `move_right` | D | 左スティック右 |
| `jump` | Space | A / ✕ |
| `attack` | LMBキー | X / □ |
| `dodge` | Shift | B / ○ |
| `lock_on` | Tabキー | LS 押し込み |
| `use_skill` | Qキー | LB / L1 |
| `camera_*` | マウス | 右スティック |
| `pause` | Esc | Start |

### GameState

バンドル 3（3D 探索）の GameState と同じで可。

### 追加 Autoload（推奨）

| Autoload | ファイル | 役割 |
|---------|---------|------|
| InputBuffer | `autoloads/input_buffer.gd` | コンボ入力判定 |

---

## バンドル 18: FPS / TPS

詳細: `docs/genres/fps-tps.md`

### Physics Layer（3D）

| Layer | 名前 | 用途 |
|-------|------|------|
| 1 | world | 地形・壁 |
| 2 | player | プレイヤー |
| 3 | enemy | 敵 |
| 4 | hitscan | レイキャスト用（マスク設定） |
| 5 | interact | インタラクト可能オブジェクト |

### InputMap

| アクション名 | PC デフォルト | ゲームパッド |
|------------|-------------|-----------|
| `move_forward` | W | 左スティック上 |
| `move_back` | S | 左スティック下 |
| `move_left` | A | 左スティック左 |
| `move_right` | D | 左スティック右 |
| `jump` | Space | A / ✕ |
| `fire` | LMB | RT / R2 |
| `aim` | RMB | LT / L2 |
| `reload` | Rキー | X / □ |
| `crouch` | Ctrl | LS 押し込み |
| `sprint` | Shift | RS 押し込み |
| `interact` | Eキー | A / ✕ |
| `weapon_next` | Qキー | Y / △ |
| `pause` | Esc | Start |

### GameState

```gdscript
enum GameState {
    BOOT,
    MAIN_MENU,
    LOADING,
    PLAYING,
    CUTSCENE,
    PAUSED,
    GAME_OVER,
    MISSION_CLEAR,
}
```

---

## バンドル 19: 3D RPG / オープンワールド

詳細: `docs/genres/3d-rpg.md`

### Physics Layer（3D）

バンドル 3（3D 探索）と同じ構成に、攻撃判定レイヤーを追加する。

### InputMap

バンドル 3（3D 探索）の InputMap を使用する。

### GameState

```gdscript
enum GameState {
    BOOT,
    MAIN_MENU,
    LOADING,
    FIELD,
    DIALOG,
    INVENTORY,
    QUEST_LOG,
    WORLD_MAP,
    FAST_TRAVEL,
    PAUSED,
    GAME_OVER,
    ENDING,
}
```

### 追加 Autoload（推奨）

| Autoload | ファイル | 役割 |
|---------|---------|------|
| QuestManager | `autoloads/quest_manager.gd` | クエスト進行・達成判定 |
| TimeManager | `autoloads/time_manager.gd` | 昼夜・日付・季節 |
| DialogManager | `autoloads/dialog_manager.gd` | NPC 会話 |
| InventoryManager | `autoloads/inventory_manager.gd` | アイテム・装備 |

---

## バンドル 20: 3D ストラテジー / RTS

詳細: `docs/genres/3d-strategy.md`

### Physics Layer（3D）

| Layer | 名前 | 用途 |
|-------|------|------|
| 1 | world | 地形 |
| 2 | unit_player | 自軍ユニット |
| 3 | unit_enemy | 敵軍ユニット |
| 4 | building_player | 自軍建物 |
| 5 | resource | 資源ノード |
| 6 | select_plane | 選択判定用透明平面 |

### InputMap

| アクション名 | PC デフォルト | ゲームパッド |
|------------|-------------|-----------|
| `select` | LMB | A / ✕ |
| `command` | RMB | B / ○ |
| `camera_up` | ↑キー / W | 右スティック上 |
| `camera_down` | ↓キー / S | 右スティック下 |
| `camera_left` | ←キー / A | 右スティック左 |
| `camera_right` | →キー / D | 右スティック右 |
| `zoom_in` | マウスホイール上 | RT / R2 |
| `zoom_out` | マウスホイール下 | LT / L2 |
| `pause` | Esc | Start |

### GameState

```gdscript
enum GameState {
    BOOT,
    MAIN_MENU,
    LOADING,
    PLAYING,     # 通常プレイ中
    PAUSED,
    VICTORY,
    DEFEAT,
}
```

---

## バンドル 21: 3D レース

詳細: `docs/genres/3d-race.md`

### Physics Layer（3D）

| Layer | 名前 | 用途 |
|-------|------|------|
| 1 | world | コース地形 |
| 2 | car | 車両本体 |
| 3 | checkpoint | チェックポイント判定 |
| 4 | item | アイテムボックス |

### InputMap

| アクション名 | PC デフォルト | ゲームパッド |
|------------|-------------|-----------|
| `accelerate` | W / ↑キー | RT / R2 |
| `brake` | S / ↓キー | LT / L2 |
| `steer_left` | A / ←キー | 左スティック左 |
| `steer_right` | D / →キー | 左スティック右 |
| `handbrake` | Space | A / ✕ |
| `use_item` | Xキー | B / ○ |
| `camera_toggle` | Cキー | Y / △ |
| `pause` | Esc | Start |

### GameState

```gdscript
enum GameState {
    BOOT,
    MAIN_MENU,
    TRACK_SELECT,
    COUNTDOWN,     # 3…2…1 カウントダウン
    RACING,
    FINISHED,      # ゴール後のリザルト
    PAUSED,
    RESULTS,
}
```

### 追加 Autoload（推奨）

| Autoload | ファイル | 役割 |
|---------|---------|------|
| RaceManager | `autoloads/race_manager.gd` | ラップ・タイム・順位管理 |
| ProgressManager | `autoloads/progress_manager.gd` | ベストタイム・アンロック |

---

## バンドル 22: 3D ホラー / サバイバル

詳細: `docs/genres/3d-horror.md`

### Physics Layer（3D）

| Layer | 名前 | 用途 |
|-------|------|------|
| 1 | world | 地形 |
| 2 | player | プレイヤー |
| 3 | enemy | 敵 |
| 4 | interact | インタラクト可能オブジェクト |
| 5 | trigger | イベントトリガー |

### InputMap

バンドル 18（FPS）の InputMap と同じ構成（`fire` → `attack` に変更）で可。

### GameState

```gdscript
enum GameState {
    BOOT,
    MAIN_MENU,
    LOADING,
    EXPLORING,
    DIALOG,
    INVENTORY,
    SCARE_EVENT,  # 恐怖演出中（入力制限）
    PAUSED,
    GAME_OVER,
    ENDING,
}
```

### 追加 Autoload（推奨）

| Autoload | ファイル | 役割 |
|---------|---------|------|
| TimeManager | `autoloads/time_manager.gd` | 時刻ベースのイベントトリガー（任意） |

---

## バンドル 23: 3D パズル / 脱出

詳細: `docs/genres/3d-puzzle.md`

### Physics Layer（3D）

| Layer | 名前 | 用途 |
|-------|------|------|
| 1 | world | 壁・床・天井 |
| 2 | player | プレイヤー |
| 3 | physics_object | RigidBody3D（押せる箱など） |
| 4 | interact | ギミック・スイッチ |
| 5 | trigger | ゴール判定 |

### InputMap

| アクション名 | PC デフォルト | ゲームパッド |
|------------|-------------|-----------|
| `move_forward` | W | 左スティック上 |
| `move_back` | S | 左スティック下 |
| `move_left` | A | 左スティック左 |
| `move_right` | D | 左スティック右 |
| `jump` | Space | A / ✕ |
| `interact` | Eキー | X / □ |
| `grab` | LMB / F | RT / R2 |
| `camera_*` | マウス | 右スティック |
| `pause` | Esc | Start |

### GameState

```gdscript
enum GameState {
    BOOT,
    MAIN_MENU,
    LOADING,
    PLAYING,
    CUTSCENE,    # ヒント演出・物語シーン
    LEVEL_CLEAR,
    PAUSED,
    CREDITS,
}
```

---

## ポーズ時の停止設定（全ジャンル共通）

`get_tree().paused = true` 発行後のノード別推奨設定:

| ノード | Process Mode | 理由 |
|-------|-------------|------|
| World / Level（ゲームワールド全体） | PROCESS_MODE_PAUSABLE | ポーズ中に停止 |
| Player / Enemy | PROCESS_MODE_INHERIT（Worldに従う） | ポーズで自動停止 |
| ポーズメニュー（CanvasLayer） | PROCESS_MODE_WHEN_PAUSED | ポーズ中も操作可能 |
| HUD（CanvasLayer） | PROCESS_MODE_WHEN_PAUSED | スコア等は見える状態に |
| BGM（AudioStreamPlayer） | PROCESS_MODE_ALWAYS | BGMはポーズ中も継続 |
| Logger | PROCESS_MODE_ALWAYS | ログは常に出力 |
