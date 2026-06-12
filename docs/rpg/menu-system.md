# Menu System — RPG メニューアーキテクチャ

**対象:** Godot 4.4+ / 2D JRPG メインメニュー・サブメニュー設計

---

## Claude Code 実装停止チェックリスト

```
□ メニュー遷移スタックを管理せずにサブメニューを追加しようとしている
□ メニューの開閉ロジックをシーンスクリプトに書こうとしている（GameManager.state で管理する）
□ 装備・アイテム変更のロジックをメニューシーンスクリプトに書こうとしている（Autoload に移す）
□ ゲームパッドとキーボードの両方でフォーカス移動ができるか確認していない
```

---

## 1. RPG メニューの全体構成

```
MainMenu（CanvasLayer, layer=5）
├── MenuRoot（Control）          ← トップメニュー
│   ├── ItemButton
│   ├── MagicButton
│   ├── StatusButton
│   ├── EquipButton
│   └── SystemButton
├── ItemPanel（Control）         ← アイテム一覧（MenuRoot の右）
│   ├── ItemList（ItemList）
│   └── ItemDescription（Label）
├── MagicPanel（Control）        ← 魔法/スキル一覧
├── StatusPanel（Control）       ← ステータス表示
├── EquipPanel（Control）        ← 装備変更
└── PartyStatusBar（Control）    ← 常時表示: パーティーHP/MP
```

---

## 2. メニュースタック管理

サブメニューへの遷移履歴をスタックで管理し、`cancel` で一段階戻れるようにする。

```gdscript
# scenes/ui/main_menu.gd
extends CanvasLayer

var _menu_stack: Array[Control] = []

func _ready() -> void:
    EventBus.menu_open_requested.connect(_on_open)
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = false

func _exit_tree() -> void:
    EventBus.menu_open_requested.disconnect(_on_open)

func _input(event: InputEvent) -> void:
    if not visible:
        return
    if event.is_action_just_pressed("cancel"):
        _go_back()
    if event.is_action_just_pressed("menu"):
        _close_menu()

func _on_open() -> void:
    if GameManager.state == GameManager.GameState.FIELD:
        GameManager.change_state(GameManager.GameState.MENU)
        visible = true
        _push_panel($MenuRoot)

func _push_panel(panel: Control) -> void:
    if not _menu_stack.is_empty():
        _menu_stack.back().visible = false
    _menu_stack.append(panel)
    panel.visible = true
    _focus_first(panel)

func _go_back() -> void:
    if _menu_stack.size() <= 1:
        _close_menu()
        return
    _menu_stack.pop_back().visible = false
    _menu_stack.back().visible = true
    _focus_first(_menu_stack.back())

func _close_menu() -> void:
    for panel: Control in _menu_stack:
        panel.visible = false
    _menu_stack.clear()
    visible = false
    GameManager.change_state(GameManager.GameState.FIELD)

func _focus_first(panel: Control) -> void:
    await get_tree().process_frame
    var first: Control = _find_first_focusable(panel)
    if first != null:
        first.grab_focus()

func _find_first_focusable(parent: Control) -> Control:
    for child: Node in parent.get_children():
        if child is Button or child is ItemList:
            return child
        if child is Control:
            var found: Control = _find_first_focusable(child)
            if found != null:
                return found
    return null
```

---

## 3. アイテムパネル

```gdscript
# scenes/ui/item_panel.gd
extends Control

@onready var item_list: ItemList = $ItemList
@onready var description: Label  = $ItemDescription
@onready var use_button: Button  = $UseButton

func _ready() -> void:
    EventBus.inventory_changed.connect(_refresh)
    item_list.item_selected.connect(_on_item_selected)
    use_button.pressed.connect(_on_use_pressed)
    _refresh()

func _exit_tree() -> void:
    EventBus.inventory_changed.disconnect(_refresh)

func _refresh() -> void:
    item_list.clear()
    for item: ItemData in InventoryManager.items:
        var count: int = InventoryManager.get_count(item.id)
        item_list.add_item("%s ×%d" % [item.display_name, count])
        item_list.set_item_metadata(item_list.item_count - 1, item.id)

func _on_item_selected(index: int) -> void:
    var item_id: String = item_list.get_item_metadata(index)
    var item: ItemData = InventoryManager.get_item(item_id)
    if item == null:
        return
    description.text = item.description
    use_button.disabled = not item.usable_in_field

func _on_use_pressed() -> void:
    var selected: int = item_list.get_selected_items()[0] if item_list.get_selected_items().size() > 0 else -1
    if selected == -1:
        return
    var item_id: String = item_list.get_item_metadata(selected)
    # アイテム使用対象選択（パーティーメンバー選択UIが必要な場合）
    EventBus.item_use_requested.emit(item_id, PartyManager.active_member_id)
```

---

## 4. ステータスパネル

```gdscript
# scenes/ui/status_panel.gd
extends Control

@export var character_index: int = 0   # 表示するパーティーメンバーインデックス

@onready var name_label: Label        = $NameLabel
@onready var level_label: Label       = $LevelLabel
@onready var hp_label: Label          = $HpLabel
@onready var mp_label: Label          = $MpLabel
@onready var str_label: Label         = $StrLabel
@onready var def_label: Label         = $DefLabel
@onready var agi_label: Label         = $AgiLabel
@onready var magic_label: Label       = $MagicLabel
@onready var equip_list: VBoxContainer = $EquipList

func _ready() -> void:
    EventBus.party_status_changed.connect(_refresh)
    _refresh()

func _exit_tree() -> void:
    EventBus.party_status_changed.disconnect(_refresh)

func _refresh() -> void:
    var members: Array[CharacterData] = PartyManager.party_members
    if character_index >= members.size():
        return
    var c: CharacterData = members[character_index]
    name_label.text  = c.display_name
    level_label.text = "Lv %d" % c.level
    hp_label.text    = "%d / %d" % [c.current_hp, c.max_hp]
    mp_label.text    = "%d / %d" % [c.current_mp, c.max_mp]
    str_label.text   = str(c.strength)
    def_label.text   = str(c.defense)
    agi_label.text   = str(c.agility)
    magic_label.text = str(c.magic)
```

---

## 5. EventBus シグナル設計（メニュー系）

```gdscript
signal menu_open_requested           # メニューを開く要求
signal menu_closed                   # メニューが閉じた
signal item_use_requested(item_id: String, target_id: String)
signal equip_change_requested(
    character_id: String,
    slot: String,
    item_id: String
)
```

---

## 6. メニューの開き方（フィールドからの呼び出し）

```gdscript
# scenes/characters/player_field.gd
func _input(event: InputEvent) -> void:
    if event.is_action_just_pressed("menu"):
        if GameManager.state == GameManager.GameState.FIELD:
            EventBus.menu_open_requested.emit()
```

---

## 7. ゲームパッド・キーボード対応チェックリスト

メニューを実装したら以下を必ず確認する:

```
□ D-Pad / 左スティックでリスト上下移動ができる
□ A（Xbox）/ ✕（PS）/ Enter で選択・決定できる
□ B（Xbox）/ ○（PS）/ Esc で1段階前のメニューに戻れる
□ Start でメニューを閉じてフィールドに戻れる
□ マウスクリックでも操作できる（PC プラットフォームの場合）
□ focus_neighbor_* が正しく設定されているか（Control ノード Inspector で確認）
```

**重要:** `Control` ノードの `focus_mode` が `FOCUS_ALL` になっていること。
デフォルト `FOCUS_NONE` だとゲームパッドで選択できない。
