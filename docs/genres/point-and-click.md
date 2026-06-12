# ポイント＆クリックアドベンチャー — ジャンルガイド

**次元:** 2D / UI 専用  
**genre-starters.md:** バンドル 4

---

## コアループ

画面内のオブジェクトをクリックして調べ・取得し、アイテムを組み合わせて謎を解く。
ホットスポット管理・カーソル状態・インベントリ操作が核心。
フラグ（FlagManager）で謎の解決済み状態を管理し、シーン遷移でロケーションを切り替える。

---

## シーン階層

```
GameScene (Node2D)
├── Background (Sprite2D)             — 背景画像
├── Hotspots (Node2D)
│   ├── Door (Area2D)                 — クリック判定ホットスポット
│   ├── Key (Area2D)
│   └── Painting (Area2D)
├── Characters (Node2D)
│   └── NPC (Node2D)
│       ├── Sprite2D
│       └── Hitbox (Area2D)           — NPC クリック判定
└── UI (CanvasLayer)
    ├── Cursor (TextureRect)          — ソフトウェアカーソル
    ├── VerbBar (HBoxContainer)       — 調べる / 使う / 話す
    ├── InventoryPanel (PanelContainer)  — 画面下部固定
    │   └── ItemSlots (HBoxContainer)
    └── DialogBox (PanelContainer)    — 説明テキスト・NPC 台詞
        ├── SpeakerLabel (Label)
        └── BodyLabel (RichTextLabel)
```

---

## 必須 Autoload

| Autoload | 役割 |
|---------|------|
| FlagManager | 謎の解決済みフラグ・ルート管理 |

---

## 主要実装パターン

### ホットスポット + 動詞アクション

ホットスポット（Area2D）は `available_actions` を持ち、
VerbBar で選択された動詞に応じた処理をシグナルで通知する。
`required_item` が設定されている場合のみ「使う」が成立する。

```gdscript
# Hotspot.gd
extends Area2D

enum Action { EXAMINE, TAKE, USE }

@export var label: String = ""
@export var available_actions: Array[int] = [Action.EXAMINE]
@export var item_id: String = ""        # TAKE 時にインベントリへ追加する ID
@export var required_item: String = ""  # USE 時に必要なアイテム ID
@export var flag_on_use: String = ""    # USE 成功時に立てるフラグ
@export var examine_text: String = ""   # EXAMINE 時の説明文

signal examined(text: String)
signal taken(item_id: String)
signal used(item_id: String)

func on_action(action: Action, used_item: String = "") -> void:
    match action:
        Action.EXAMINE:
            examined.emit(examine_text)
        Action.TAKE:
            taken.emit(item_id)
            queue_free()
        Action.USE:
            if required_item.is_empty() or used_item == required_item:
                if not flag_on_use.is_empty():
                    FlagManager.set_flag(flag_on_use, true)
                used.emit(item_id)
```

### インベントリ管理

インベントリは `Array[String]` でアイテム ID を管理する。
選択中アイテムを `_selected_item` で保持し、ホットスポットへ「使う」と消費する。

```gdscript
# InventoryManager.gd（Autoload または シーン内ノード）
extends Node

var _items: Array[String] = []
var _selected_item: String = ""

signal inventory_changed(items: Array[String])

func add_item(item_id: String) -> void:
    if _items.has(item_id):
        return
    _items.append(item_id)
    inventory_changed.emit(_items.duplicate())
    Logger.info("InventoryManager: add_item %s" % item_id)

func remove_item(item_id: String) -> void:
    var idx: int = _items.find(item_id)
    if idx < 0:
        Logger.error("InventoryManager: remove_item not found: %s" % item_id)
        return
    _items.remove_at(idx)
    inventory_changed.emit(_items.duplicate())

func select_item(item_id: String) -> void:
    _selected_item = item_id

func deselect_item() -> void:
    _selected_item = ""

func get_selected_item() -> String:
    return _selected_item

func has_item(item_id: String) -> bool:
    return _items.has(item_id)

func use_selected_on(hotspot: Node) -> void:
    if _selected_item.is_empty():
        return
    if hotspot.has_method("on_action"):
        hotspot.on_action(hotspot.Action.USE, _selected_item)
    _selected_item = ""
```

### ソフトウェアカーソル + クリック処理

OS カーソルを非表示にして TextureRect でカーソルを描画する。
マウスクリック時に `PhysicsDirectSpaceState2D` でホットスポットを取得する。

```gdscript
# GameScene.gd
extends Node2D

@onready var _cursor: TextureRect = $UI/Cursor
@onready var _inventory: Node = $UI/InventoryPanel
@onready var _dialog_box: PanelContainer = $UI/DialogBox
@onready var _verb_bar: HBoxContainer = $UI/VerbBar

var _current_verb: int = 0   # Hotspot.Action の値

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _process(_delta: float) -> void:
    _cursor.global_position = get_global_mouse_position() - _cursor.size / 2.0

func _unhandled_input(event: InputEvent) -> void:
    if not (event is InputEventMouseButton):
        return
    var mb: InputEventMouseButton = event as InputEventMouseButton
    if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
        _handle_click(mb.global_position)

func _handle_click(pos: Vector2) -> void:
    var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
    var params: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
    params.position = pos
    params.collision_mask = 0b0010  # Hotspot レイヤー
    var results: Array[Dictionary] = space.intersect_point(params, 8)
    if results.is_empty():
        return
    var collider: Object = results[0]["collider"]
    if collider is Node and collider.has_method("on_action"):
        collider.on_action(_current_verb, _get_selected_item())

func _get_selected_item() -> String:
    if _inventory.has_method("get_selected_item"):
        return _inventory.get_selected_item()
    return ""
```

### フラグによるシーン状態の切り替え

FlagManager を使い、謎解き済みのホットスポットを非表示・差し替えにする。

```gdscript
# GameScene.gd（フラグ連動）
func _apply_flags() -> void:
    # ドアを解錠済みなら「開いているドア」スプライトに差し替え
    if FlagManager.get_flag("door_unlocked"):
        $Hotspots/Door.get_node("Sprite2D").texture = preload("res://assets/door_open.png")
        $Hotspots/Door.examine_text = "扉が開いている。"
    # 鍵を入手済みなら鍵ホットスポットを非表示
    if FlagManager.get_flag("key_taken"):
        $Hotspots/Key.hide()
        $Hotspots/Key.monitoring = false
```

---

## よくある地雷

- `Input.MOUSE_MODE_HIDDEN` を設定しないと OS カーソルとソフトウェアカーソルが二重になる
- Area2D の `input_pickable = true` を忘れると `_input_event` シグナルが発火しない（PhysicsPointQueryParameters2D を使う場合は `monitoring = true` が必要）
- アイテムを「使う」でフラグを立てた後に同じホットスポットへ再作用できるバグ → `FlagManager` で消費済みチェックを先に行う
- インベントリの `_items` を直接外部参照して変更すると `inventory_changed` シグナルが飛ばない → 必ず `add_item()` / `remove_item()` を経由する
- ソフトウェアカーソルがシーン遷移後に消えるのは `CanvasLayer` のスコープ問題 → カーソルは最上位の常駐シーン（Autoload 的な CanvasLayer）に持たせる

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/point-and-click.md` | このファイル |
| Autoload | `autoloads/flag_manager.gd` | ビジュアルノベル・JRPG でも使用 |

```ini
; ビジュアルノベルでも JRPG でも使わない場合のみ project.godot から削除
FlagManager="*res://autoloads/flag_manager.gd"
```
