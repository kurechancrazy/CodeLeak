class_name SkillData
extends Resource

enum Element {
	NONE,
	FIRE,
	ICE,
	THUNDER,
	WIND,
	EARTH,
	WATER,
	HOLY,
	DARK,
}

enum TargetType {
	SINGLE_ENEMY,
	ALL_ENEMIES,
	SINGLE_ALLY,
	ALL_ALLIES,
	SELF,
}

enum EffectType {
	DAMAGE,      # ダメージ（magic or physical）
	HEAL,        # 回復
	STATUS,      # ステータス異常付与
	BUFF,        # 強化
	DEBUFF,      # 弱体
	REVIVE,      # 戦闘不能回復
}

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D = null

@export var mp_cost: int = 0
@export var power: int = 0             # ダメージ・回復の基礎値
@export var element: Element = Element.NONE
@export var target_type: TargetType = TargetType.SINGLE_ENEMY
@export var effect_type: EffectType = EffectType.DAMAGE

# ステータス異常（STATUS エフェクト用）
@export var status_id: String = ""     # "poison" / "sleep" / "silence" 等
@export var status_rate: float = 0.5   # 付与確率 0.0〜1.0

# アニメーション
@export var animation_id: String = ""  # 演出用アニメーションID

# 習得条件
@export var learn_level: int = 1       # 習得レベル（0 = 最初から習得）

func element_multiplier(target_weakness: int) -> float:
	if target_weakness == element and element != Element.NONE:
		return 1.5  # 弱点属性は 1.5 倍
	return 1.0
