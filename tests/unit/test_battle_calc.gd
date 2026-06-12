extends GutTest


func _make_attacker(strength: int = 20, magic: int = 10, luck: int = 10) -> CharacterData:
	var c: CharacterData = CharacterData.new()
	c.strength = strength
	c.magic = magic
	c.luck = luck
	c.defense = 5
	c.magic_defense = 5
	return c


func _make_target(defense: int = 5, magic_defense: int = 5) -> CharacterData:
	var c: CharacterData = CharacterData.new()
	c.defense = defense
	c.magic_defense = magic_defense
	c.luck = 5
	c.element_weakness = 0
	return c


func _make_skill(power: int = 50, element: int = SkillData.Element.FIRE) -> SkillData:
	var s: SkillData = SkillData.new()
	s.power = power
	s.element = element
	return s


# --- physical_damage ---

func test_physical_damage_minimum_is_1() -> void:
	var attacker: CharacterData = _make_attacker(1, 0, 0)
	var target: CharacterData = _make_target(9999)
	var result: int = BattleCalc.physical_damage(attacker, target, 0.0)
	assert_gte(result, 1, "最低ダメージは 1 以上")


func test_physical_damage_zero_variance_is_deterministic() -> void:
	var attacker: CharacterData = _make_attacker(20)
	var target: CharacterData = _make_target(5)
	var result1: int = BattleCalc.physical_damage(attacker, target, 0.0)
	var result2: int = BattleCalc.physical_damage(attacker, target, 0.0)
	assert_eq(result1, result2, "分散 0 のとき決定論的なダメージ")


func test_physical_damage_positive_when_attacker_stronger() -> void:
	var attacker: CharacterData = _make_attacker(100)
	var target: CharacterData = _make_target(10)
	var result: int = BattleCalc.physical_damage(attacker, target, 0.0)
	assert_gt(result, 0)


# --- magic_damage ---

func test_magic_damage_minimum_is_1() -> void:
	var attacker: CharacterData = _make_attacker(0, 0)
	var target: CharacterData = _make_target(9999, 9999)
	var skill: SkillData = _make_skill(0)
	var result: int = BattleCalc.magic_damage(attacker, target, skill)
	assert_gte(result, 1, "最低魔法ダメージは 1 以上")


func test_magic_damage_weakness_multiplier_increases_damage() -> void:
	var attacker: CharacterData = _make_attacker(0, 20)
	var target: CharacterData = _make_target(5, 5)
	target.element_weakness = SkillData.Element.FIRE

	var skill_normal: SkillData = _make_skill(100, SkillData.Element.ICE)
	var skill_weakness: SkillData = _make_skill(100, SkillData.Element.FIRE)

	var normal: int = BattleCalc.magic_damage(attacker, target, skill_normal)
	var weakness: int = BattleCalc.magic_damage(attacker, target, skill_weakness)
	assert_gt(weakness, normal, "弱点属性はダメージが増加する")


# --- is_critical ---

func test_is_critical_returns_bool() -> void:
	var attacker: CharacterData = _make_attacker()
	var result: bool = BattleCalc.is_critical(attacker)
	assert_true(result is bool)


func test_is_critical_never_crits_with_zero_luck() -> void:
	var attacker: CharacterData = _make_attacker()
	attacker.luck = 0
	# luck = 0 のとき randf() < 0.0 は常に false
	assert_false(BattleCalc.is_critical(attacker))


# --- status_hit ---

func test_status_hit_returns_false_at_zero_rate() -> void:
	var attacker: CharacterData = _make_attacker()
	var target: CharacterData = _make_target()
	assert_false(BattleCalc.status_hit(attacker, target, 0.0))


func test_status_hit_returns_true_at_full_rate() -> void:
	var attacker: CharacterData = _make_attacker()
	var target: CharacterData = _make_target()
	assert_true(BattleCalc.status_hit(attacker, target, 1.0))
