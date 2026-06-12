extends GutTest

var _item: ItemData

func before_each() -> void:
	_item = ItemData.new()

func test_is_consumable_true_for_consumable_category() -> void:
	_item.category = ItemData.Category.CONSUMABLE
	assert_true(_item.is_consumable())
	assert_false(_item.is_equipment())
	assert_false(_item.is_key_item())

func test_is_equipment_true_for_equipment_category() -> void:
	_item.category = ItemData.Category.EQUIPMENT
	assert_false(_item.is_consumable())
	assert_true(_item.is_equipment())
	assert_false(_item.is_key_item())

func test_is_key_item_true_for_key_item_category() -> void:
	_item.category = ItemData.Category.KEY_ITEM
	assert_false(_item.is_consumable())
	assert_false(_item.is_equipment())
	assert_true(_item.is_key_item())

func test_default_category_is_consumable() -> void:
	assert_eq(_item.category, ItemData.Category.CONSUMABLE)

func test_default_equip_slot_is_none() -> void:
	assert_eq(_item.equip_slot, ItemData.EquipSlot.NONE)
