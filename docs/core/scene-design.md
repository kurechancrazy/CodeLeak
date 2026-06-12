# Scene Design — シーン設計・遷移パターン

## シーンの基本原則

Godot のシーンは「コンポーネント」でも「ページ」でもなく、**再利用可能な独立したツリー**。
1つのシーンは1つの責務を持つ。複数の責務をもつシーンは分割する。

---

## シーンの分類

| 種類 | 場所 | ノード型 | 役割 |
|------|------|---------|------|
| ゲームワールド | `scenes/game/` | Node2D / Node3D | ゲームプレイの舞台 |
| UIシーン | `scenes/ui/` | Control（CanvasLayer配下） | メニュー・HUD・ダイアログ |
| ゲームオブジェクト | `scenes/game/` | CharacterBody2D 等 | プレイヤー・敵・アイテム |
| エントリポイント | `scenes/main.tscn` | Node | アプリ起動点 |

---

## シーン遷移

SceneManager Autoload を必ず経由する。`get_tree().change_scene_to_file()` を直接呼ばない。

```gdscript
# ✅ SceneManager 経由
SceneManager.go_to("res://scenes/ui/main_menu.tscn")
SceneManager.go_to("res://scenes/game/game_world.tscn", SceneManager.TRANSITION_FADE)
SceneManager.go_back()  # 前の画面に戻る
SceneManager.go_to_root("res://scenes/ui/main_menu.tscn")  # 履歴をリセット

# ❌ 直接呼び出し（禁止）
get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
```

### EventBus 経由での遷移リクエスト（UIから）

```gdscript
# ✅ UIシーンからは EventBus でリクエスト（SceneManager への直接参照不要）
func _on_start_button_pressed() -> void:
    EventBus.scene_change_requested.emit("res://scenes/game/game_world.tscn", "fade")
```

---

## UIシーンのレイアウトパターン

### CanvasLayer で HUD を重ねる

```
main.tscn
├── GameWorld (Node2D/3D)  ← ゲームワールド
└── HUD (CanvasLayer, layer=1)  ← UIを常に前面に
    └── hud.tscn インスタンス
```

### フルスクリーンUIは別シーン

```gdscript
# ✅ メインメニューは独立シーンとして切り替え
SceneManager.go_to("res://scenes/ui/main_menu.tscn")

# ❌ メインシーンにメニューUIをネスト（禁止）
```

### ポップアップは addchild で重ねる

```gdscript
# ✅ ダイアログは addChild で追加（docs/ui/popups.md 参照）
var dialog: = preload("res://scenes/ui/confirm_dialog.tscn").instantiate()
add_child(dialog)
dialog.confirmed.connect(_on_dialog_confirmed)
```

---

## シーン間のデータ受け渡し

### 方法1: EventBus シグナル（推奨）

```gdscript
# 送信シーン
EventBus.level_selected.emit(level_id)

# 受信シーン（autoloadで管理）
GameManager.current_level_id = level_id
SceneManager.go_to("res://scenes/game/game_world.tscn")
```

### 方法2: Autoload を介したデータ共有

```gdscript
# 送信側（UIシーン）
GameManager.selected_character = character_id
SceneManager.go_to("res://scenes/game/game_world.tscn")

# 受信側（ゲームシーン）
func _ready() -> void:
    _setup_character(GameManager.selected_character)
```

### 方法3: @export でシーンインスタンス時に注入

```gdscript
# プレハブ使用時（Spawner → Spawned の関係）
@export var item_data: ItemData = null

func initialize(data: ItemData) -> void:
    item_data = data
    _update_display()
```

**禁止:** `get_tree().root.get_node("SceneName")` でシーンを検索

---

## シーンのライフサイクル

```gdscript
# 正しい初期化の順序
func _ready() -> void:
    # 1. @onready 変数は _ready() 開始時点で確定済み
    # 2. シグナル接続（EventBus は必ずここで）
    EventBus.game_started.connect(_on_game_started)
    # 3. 初期状態のセットアップ
    _setup_initial_state()

func _exit_tree() -> void:
    # 明示的に disconnect が必要なシグナルのみ（EventBus接続）
    EventBus.game_started.disconnect(_on_game_started)

# process_mode の制御
func pause() -> void:
    process_mode = Node.PROCESS_MODE_DISABLED  # 一時停止時に止まる
```

---

## ゲームオブジェクトの命名規則

| ノード型 | 用途 | 例 |
|---------|------|-----|
| `CharacterBody2D` | プレイヤー・敵（物理衝突あり） | `Player`, `Enemy` |
| `Area2D` | コレクタブル・トリガー | `Coin`, `Checkpoint` |
| `StaticBody2D` | 地形・壁 | `Ground`, `Wall` |
| `RigidBody2D` | 物理オブジェクト | `Barrel`, `Rock` |
| `Node2D` | ロジックのみ（表示なし）| `WaveSpawner`, `GameLogic` |
