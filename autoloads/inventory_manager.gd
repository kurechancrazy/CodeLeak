extends Node
## アイテム所持・使用・装備変更を管理する Autoload。

# ── 公開プロパティ ────────────────────────────────────────

var items: Array[ItemData]:
	get:
		return _load_item_data_list()

# {item_id: int} 形式で所持数を管理
var _item_counts: Dictionary = {}
var _max_capacity: int = 20   # アイテム種類数の上限

# ── 公開 API ──────────────────────────────────────────────

func add_item(item_id: String, count: int = 1) -> bool:
	if count <= 0:
		return false
	if not _item_counts.has(item_id) and _item_counts.size() >= _max_capacity:
		EventBus.notification_requested.emit("アイテムがいっぱいです", "warn")
		return false
	_item_counts[item_id] = _item_counts.get(item_id, 0) + count
	EventBus.inventory_changed.emit()
	Logger.debug("Item added", {"id": item_id, "count": count})
	return true

func remove_item(item_id: String, count: int = 1) -> bool:
	if not has_item(item_id, count):
		return false
	_item_counts[item_id] -= count
	if _item_counts[item_id] <= 0:
		_item_counts.erase(item_id)
	EventBus.inventory_changed.emit()
	return true

func has_item(item_id: String, count: int = 1) -> bool:
	return _item_counts.get(item_id, 0) >= count

func get_count(item_id: String) -> int:
	return _item_counts.get(item_id, 0)

func get_item(item_id: String) -> ItemData:
	var path: String = "res://resources/data/items/%s.tres" % item_id
	if not ResourceLoader.exists(path):
		Logger.error("ItemData not found", {"id": item_id})
		return null
	return load(path) as ItemData

func use_item(item_id: String, target_id: String) -> bool:
	var item: ItemData = get_item(item_id)
	if item == null or not item.is_consumable():
		return false
	if not has_item(item_id):
		return false
	remove_item(item_id)
	EventBus.item_used.emit(item_id, target_id)
	return true

func reset() -> void:
	_item_counts.clear()
	EventBus.inventory_changed.emit()

# ── セーブ・ロード ────────────────────────────────────────

func _ready() -> void:
	EventBus.load_requested.connect(_on_load)
	EventBus.save_requested.connect(_on_save)
	EventBus.item_use_requested.connect(_on_item_use_requested)

func _exit_tree() -> void:
	EventBus.load_requested.disconnect(_on_load)
	EventBus.save_requested.disconnect(_on_save)
	EventBus.item_use_requested.disconnect(_on_item_use_requested)

func _on_save() -> void:
	SaveManager.set_value("inventory", "items", JSON.stringify(_item_counts))

func _on_load() -> void:
	var raw: Variant = SaveManager.get_value("inventory", "items", "{}")
	if not raw is String:
		return
	var parsed: Variant = JSON.parse_string(raw)
	if parsed is Dictionary:
		_item_counts = parsed

func _on_item_use_requested(item_id: String, target_id: String) -> void:
	use_item(item_id, target_id)

# ── プライベート ──────────────────────────────────────────

func _load_item_data_list() -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item_id: String in _item_counts.keys():
		var item: ItemData = get_item(item_id)
		if item != null:
			result.append(item)
	return result
