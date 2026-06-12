# Initial Decisions — ゲーム開発前の設計決定チェックリスト

**タイミング:** `_init.md` の初期化完了直後、最初のシーン実装前に必ず実施すること。
ここで決定した内容を `project.godot` および `.kiro/steering/architecture.md` に反映する。

---

## Claude Code 実装停止チェックリスト

```
□ Physics Layer が project.godot に未定義のまま実装を始めようとしている
□ Input Map (project.godot の [input] セクション) が未定義のまま Input.is_action_pressed() を書こうとしている
□ GameState enum を拡張せずにゲームジャンル固有の状態（コマンド選択・ウェーブ遷移）を実装しようとしている
□ ゲーム固有の Autoload が必要だが初期化順序を決めずに追加しようとしている
```

---

## 1. Physics Layer 設計

### 決め方

`Project Settings > Layer Names > 2D Physics` (または 3D Physics) で名前を定義する。
**スクリプトから数字で参照する前に、必ず名前を設定すること。**

### ジャンル別サンプル

**2D アクション・プラットフォーマー:**

| Layer | 名前 | 用途 |
|-------|------|------|
| 1 | world | 地形・StaticBody（踏める床・壁） |
| 2 | player | プレイヤー本体 |
| 3 | enemy | 敵本体 |
| 4 | player_projectile | プレイヤーの攻撃 |
| 5 | enemy_projectile | 敵の攻撃 |
| 6 | item | コイン・アイテム |
| 7 | trigger | ゴール・イベントゾーン |

**パズルゲーム:**

| Layer | 名前 | 用途 |
|-------|------|------|
| 1 | world | 固定ブロック・床 |
| 2 | block | 動かせるブロック |
| 3 | player | プレイヤー |
| 4 | trigger | ゴール・スイッチ |

**RPG（見下ろし型）:**

| Layer | 名前 | 用途 |
|-------|------|------|
| 1 | world | 地形・障害物 |
| 2 | player | プレイヤー |
| 3 | npc | NPC・会話可能キャラ |
| 4 | enemy | 戦闘対象の敵 |
| 5 | item | 拾えるアイテム |
| 6 | damage_zone | ダメージエリア・トラップ |
| 7 | trigger | イベントトリガー・エリア切り替え |

### project.godot への反映

```ini
[layer_names]
2d_physics/layer_1="world"
2d_physics/layer_2="player"
2d_physics/layer_3="enemy"
; ... 以下同様
```

---

## 2. Input Map 定義

### 決め方

`Project Settings > Input Map` でアクションを定義してから、コードに書く。
ハードコードしたキー名（`"ui_accept"` 以外）を直接コードに書かない。

### ジャンル別 推奨アクション名

**2D アクション・プラットフォーマー:**

| アクション名 | 推奨キー（PC） | 推奨ボタン（ゲームパッド） |
|------------|-------------|------------------------|
| `move_left` | A / 左矢印 | 左スティック左 |
| `move_right` | D / 右矢印 | 左スティック右 |
| `jump` | Space / W / 上矢印 | A（Xbox）/ ✕（PS） |
| `attack` | Z / J | X（Xbox）/ □（PS） |
| `pause` | Esc | Start |
| `interact` | E / F | B（Xbox）/ ○（PS） |

**パズルゲーム:**

| アクション名 | 推奨キー（PC） | 説明 |
|------------|-------------|------|
| `move_left/right/up/down` | 矢印キー / WASD | カーソル移動 |
| `confirm` | Enter / Space | 決定・配置 |
| `cancel` | Esc / Z | 取り消し・戻る |
| `undo` | Ctrl+Z | 1手戻す |
| `pause` | Esc | ポーズ |

**RPG / アドベンチャー:**

| アクション名 | 推奨キー（PC） |
|------------|-------------|
| `move_left/right/up/down` | WASD / 矢印 |
| `interact` | E / Space | NPC会話・調べる |
| `menu` | Esc / I | メニュー開閉 |
| `confirm` | Enter / E | 選択決定 |
| `cancel` | Esc / X | キャンセル |
| `run` | Shift | 走る（長押し） |

### project.godot への反映

```ini
[input]
move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":65,"key_label":0,"unicode":97,"location":0,"echo":false,"script":null)]
}
; ... 各アクションを定義
```

---

## 3. GameState 拡張ガイド

### デフォルト状態

```gdscript
enum GameState { BOOT, MAIN_MENU, PLAYING, PAUSED, GAME_OVER }
```

### ジャンル別拡張例

**2D アクション:**
```gdscript
enum GameState {
    BOOT, MAIN_MENU, STAGE_SELECT,
    PLAYING, PAUSED, GAME_OVER,
    STAGE_CLEAR, GAME_CLEAR
}
```

**RPG（ターンベース戦闘）:**
```gdscript
enum GameState {
    BOOT, MAIN_MENU,
    FIELD,          # フィールド探索
    BATTLE_START,   # 戦闘開始演出
    BATTLE_COMMAND, # コマンド選択待ち
    BATTLE_EXECUTE, # コマンド実行中
    BATTLE_END,     # 戦闘終了演出
    PAUSED, GAME_OVER
}
```

**パズルゲーム:**
```gdscript
enum GameState {
    BOOT, MAIN_MENU, LEVEL_SELECT,
    PLAYING,        # 操作待ち
    ANIMATING,      # 落下・消去アニメーション中（操作受け付けない）
    LEVEL_CLEAR, LEVEL_FAILED,
    PAUSED, GAME_OVER
}
```

**ノベル・アドベンチャー:**
```gdscript
enum GameState {
    BOOT, MAIN_MENU,
    STORY,          # テキスト表示中
    CHOICE_WAIT,    # 選択肢待ち
    PAUSED, ENDING
}
```

### EventBus への追加

GameState を拡張したら、`event_bus.gd` に対応するシグナルを追加する:

```gdscript
# ジャンル固有シグナルの追加例（RPGの場合）
signal battle_started(enemy_ids: Array[String])
signal battle_command_selected(command: String)
signal battle_ended(victory: bool)
```

---

## 4. Autoload 追加判断基準

### 追加が必要になるケース

| ケース | 追加する Autoload | 初期化順序への挿入位置 |
|-------|-----------------|----------------------|
| インベントリ・アイテム管理が必要 | `InventoryManager` | GameManager の後 |
| ダイアログ・会話システムが必要 | `DialogManager` | GameManager の後 |
| ウェーブ・ステージ進行管理が必要 | `StageManager` | GameManager の後 |
| ランキング・実績管理が必要 | `ProgressManager` | SaveManager の後 |
| 入力バッファ・コンボ判定が必要 | `InputBuffer` | EventBus の後 |

### 初期化順序ルール

```
Logger → EventBus → [ゲームロジック系: GameManager → StageManager → InventoryManager...]
       → SceneManager → SaveManager → [永続化系: ProgressManager...]
       → AudioManager
```

**原則:**
- 他の Autoload に依存する Autoload は、依存先の後に配置する
- 同一レイヤーの Autoload は EventBus 経由でのみ通信する
- 追加した Autoload は必ず `_exit_tree()` でシグナル切断を実装する

---

## 5. ポーズ時に止まるもの・止まらないもの

### Process Mode 設定表

`get_tree().paused = true` を実行したとき、各ノードの `process_mode` によって動作が変わる。

| Process Mode | ポーズ中の動作 | 使用先の例 |
|-------------|--------------|----------|
| `PROCESS_MODE_INHERIT`（デフォルト） | 親に従う | 一般的なゲームオブジェクト |
| `PROCESS_MODE_PAUSABLE` | **停止** | 敵・プレイヤー・ゲームオブジェクト |
| `PROCESS_MODE_WHEN_PAUSED` | **動作継続** | ポーズメニュー・UI |
| `PROCESS_MODE_ALWAYS` | 常に動作 | Logger・デバッグUI |
| `PROCESS_MODE_DISABLED` | 常に停止 | 無効化したいノード |

### 設定が必要なノード一覧

| ノード | 推奨 Process Mode |
|-------|-----------------|
| ゲームワールド（World ルート） | PROCESS_MODE_PAUSABLE |
| ポーズメニュー（CanvasLayer） | PROCESS_MODE_WHEN_PAUSED |
| HUD（CanvasLayer） | PROCESS_MODE_WHEN_PAUSED（残像表示のため） |
| BGM（AudioStreamPlayer） | PROCESS_MODE_ALWAYS（ポーズ中も継続 or 別途制御） |
| ゲームオーバー画面 | PROCESS_MODE_ALWAYS |

```gdscript
# ポーズ実装のテンプレート
func toggle_pause() -> void:
    var is_paused: bool = not get_tree().paused
    get_tree().paused = is_paused
    pause_menu.visible = is_paused
    if is_paused:
        AudioManager.set_bgm_volume(0.3)  # BGMを下げる
    else:
        AudioManager.set_bgm_volume(GameManager.settings.get("bgm_volume", 0.8))
    EventBus.game_paused.emit(is_paused)
```
