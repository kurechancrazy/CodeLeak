class_name EnemyData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var sprite_frames: SpriteFrames = null

# 基礎ステータス
@export var max_hp: int = 50
@export var max_mp: int = 0
@export var strength: int = 8
@export var defense: int = 3
@export var agility: int = 8
@export var magic: int = 3
@export var magic_defense: int = 3
@export var luck: int = 5

# 属性弱点（SkillData.Element の値を使う）
@export var element_weakness: int = 0  # 0 = なし

# 報酬
@export var exp_reward: int = 10
@export var gold_reward: int = 5
@export var drop_items: Array[String] = []   # item_id リスト
@export var drop_rate: float = 0.1           # 0.0〜1.0

# 行動パターン（AI）
@export var action_pattern: String = "random"  # "random" / カスタム ID

# 現在値（戦闘中のみ使用）
var current_hp: int = 0
var current_mp: int = 0

func _init() -> void:
	current_hp = max_hp
	current_mp = max_mp

func is_alive() -> bool:
	return current_hp > 0

func apply_damage(amount: int) -> void:
	current_hp = maxi(0, current_hp - amount)

func apply_healing(amount: int) -> void:
	current_hp = mini(max_hp, current_hp + amount)

func roll_drop() -> String:
	if drop_items.is_empty():
		return ""
	if randf() > drop_rate:
		return ""
	return drop_items[randi() % drop_items.size()]
