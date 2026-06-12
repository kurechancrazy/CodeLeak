extends GutTest

var _skill: SkillData

func before_each() -> void:
	_skill = SkillData.new()
	_skill.element = SkillData.Element.FIRE

func test_element_multiplier_weakness_returns_1_5() -> void:
	var result: float = _skill.element_multiplier(SkillData.Element.FIRE)
	assert_almost_eq(result, 1.5, 0.001)

func test_element_multiplier_no_weakness_returns_1_0() -> void:
	var result: float = _skill.element_multiplier(SkillData.Element.ICE)
	assert_almost_eq(result, 1.0, 0.001)

func test_element_multiplier_none_element_returns_1_0() -> void:
	_skill.element = SkillData.Element.NONE
	var result: float = _skill.element_multiplier(SkillData.Element.NONE)
	assert_almost_eq(result, 1.0, 0.001)

func test_default_mp_cost_is_zero() -> void:
	assert_eq(_skill.mp_cost, 0)

func test_default_target_type_is_single_enemy() -> void:
	assert_eq(_skill.target_type, SkillData.TargetType.SINGLE_ENEMY)
