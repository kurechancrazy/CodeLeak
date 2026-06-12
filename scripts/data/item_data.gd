class_name ItemData
extends Resource

enum Category {
	CONSUMABLE,   # ポーション・エーテル等
	EQUIPMENT,    # 武器・防具・アクセサリ
	KEY_ITEM,     # イベントアイテム（売れない・捨てられない）
}

enum EquipSlot {
	NONE,
	WEAPON,
	ARMOR,
	ACCESSORY,
}

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D = null
@export var category: Category = Category.CONSUMABLE
@export var equip_slot: EquipSlot = EquipSlot.NONE
@export var price: int = 0          # 0 = 売れない
@export var max_stack: int = 99     # 最大所持数（KEY_ITEM は 1）

# 使用効果（CONSUMABLE）
@export var hp_restore: int = 0
@export var mp_restore: int = 0
@export var usable_in_field: bool = true    # フィールドで使用可能か
@export var usable_in_battle: bool = true   # 戦闘中で使用可能か

# 装備効果（EQUIPMENT）
@export var equip_str_bonus: int = 0
@export var equip_def_bonus: int = 0
@export var equip_agi_bonus: int = 0
@export var equip_magic_bonus: int = 0
@export var equip_mdef_bonus: int = 0

func is_consumable() -> bool:
	return category == Category.CONSUMABLE

func is_equipment() -> bool:
	return category == Category.EQUIPMENT

func is_key_item() -> bool:
	return category == Category.KEY_ITEM
