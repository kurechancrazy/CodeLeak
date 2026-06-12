extends GutTest

var _inv: Node = null


func before_each() -> void:
	_inv = load("res://autoloads/inventory_manager.gd").new()
	# _ready() を呼ばず EventBus 依存を回避して純粋ロジックのみテスト


func after_each() -> void:
	_inv.free()


# --- add_item ---

func test_add_item_returns_true_on_success() -> void:
	assert_true(_inv.add_item("potion"))


func test_add_item_increases_count() -> void:
	_inv.add_item("potion", 3)
	assert_eq(_inv.get_count("potion"), 3)


func test_add_item_accumulates() -> void:
	_inv.add_item("potion", 2)
	_inv.add_item("potion", 1)
	assert_eq(_inv.get_count("potion"), 3)


func test_add_item_with_zero_count_returns_false() -> void:
	assert_false(_inv.add_item("potion", 0))


func test_add_item_with_negative_count_returns_false() -> void:
	assert_false(_inv.add_item("potion", -1))


# --- has_item ---

func test_has_item_true_when_sufficient() -> void:
	_inv.add_item("ether", 2)
	assert_true(_inv.has_item("ether", 2))


func test_has_item_false_when_not_enough() -> void:
	_inv.add_item("ether", 1)
	assert_false(_inv.has_item("ether", 2))


func test_has_item_false_when_not_added() -> void:
	assert_false(_inv.has_item("unknown_item"))


# --- get_count ---

func test_get_count_returns_zero_for_unknown_item() -> void:
	assert_eq(_inv.get_count("unknown"), 0)


# --- remove_item ---

func test_remove_item_decreases_count() -> void:
	_inv.add_item("potion", 3)
	_inv.remove_item("potion", 1)
	assert_eq(_inv.get_count("potion"), 2)


func test_remove_item_returns_false_when_not_enough() -> void:
	_inv.add_item("potion", 1)
	assert_false(_inv.remove_item("potion", 5))


func test_remove_item_removes_entry_when_depleted() -> void:
	_inv.add_item("potion", 1)
	_inv.remove_item("potion", 1)
	assert_false(_inv.has_item("potion"))


# --- capacity ---

func test_add_item_fails_when_capacity_exceeded() -> void:
	_inv._max_capacity = 2
	_inv.add_item("item_a")
	_inv.add_item("item_b")
	var result: bool = _inv.add_item("item_c")
	assert_false(result, "容量超過時は false を返すこと")


func test_add_item_same_id_does_not_consume_capacity() -> void:
	_inv._max_capacity = 1
	_inv.add_item("potion", 1)
	var result: bool = _inv.add_item("potion", 1)
	assert_true(result, "同じアイテムの追加は容量を消費しない")


# --- reset ---

func test_reset_clears_inventory() -> void:
	_inv.add_item("potion", 5)
	_inv.add_item("ether", 2)
	_inv.reset()
	assert_false(_inv.has_item("potion"))
	assert_false(_inv.has_item("ether"))
