class_name CharacterData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var portrait: Texture2D = null
@export var sprite_frames: SpriteFrames = null

# レベル・経験値
@export var level: int = 1
@export var exp: int = 0
@export var exp_to_next: int = 100

# 基礎ステータス
@export var max_hp: int = 100
@export var max_mp: int = 50
@export var strength: int = 10
@export var defense: int = 5
@export var agility: int = 10
@export var magic: int = 5
@export var magic_defense: int = 5
@export var luck: int = 5

# 属性弱点（SkillData.Element の値を使う）
@export var element_weakness: int = 0  # 0 = なし

# 現在値（戦闘中・セーブデータで変動）
var current_hp: int = 0
var current_mp: int = 0

# 装備スロット（item_id を保持）
var equip_weapon: String = ""
var equip_armor: String = ""
var equip_accessory: String = ""

func _init() -> void:
	current_hp = max_hp
	current_mp = max_mp

func is_alive() -> bool:
	return current_hp > 0

func is_hp_full() -> bool:
	return current_hp >= max_hp

func is_mp_full() -> bool:
	return current_mp >= max_mp

func apply_damage(amount: int) -> void:
	current_hp = maxi(0, current_hp - amount)

func apply_healing(amount: int) -> void:
	current_hp = mini(max_hp, current_hp + amount)

func apply_mp_cost(amount: int) -> void:
	current_mp = maxi(0, current_mp - amount)

func apply_mp_restore(amount: int) -> void:
	current_mp = mini(max_mp, current_mp + amount)

func to_dict() -> Dictionary:
	return {
		"id": id,
		"level": level,
		"exp": exp,
		"current_hp": current_hp,
		"current_mp": current_mp,
		"equip_weapon": equip_weapon,
		"equip_armor": equip_armor,
		"equip_accessory": equip_accessory,
	}

func from_dict(data: Dictionary) -> void:
	level = data.get("level", 1)
	exp = data.get("exp", 0)
	current_hp = data.get("current_hp", max_hp)
	current_mp = data.get("current_mp", max_mp)
	equip_weapon = data.get("equip_weapon", "")
	equip_armor = data.get("equip_armor", "")
	equip_accessory = data.get("equip_accessory", "")
