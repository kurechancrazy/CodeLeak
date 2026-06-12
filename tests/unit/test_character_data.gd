extends GutTest

var _char: CharacterData

func before_each() -> void:
	_char = CharacterData.new()
	_char.max_hp = 100
	_char.max_mp = 50
	_char.current_hp = 100
	_char.current_mp = 50

func test_apply_damage_reduces_hp() -> void:
	_char.apply_damage(30)
	assert_eq(_char.current_hp, 70)

func test_apply_damage_minimum_is_zero() -> void:
	_char.apply_damage(9999)
	assert_eq(_char.current_hp, 0)

func test_apply_healing_restores_hp() -> void:
	_char.current_hp = 50
	_char.apply_healing(30)
	assert_eq(_char.current_hp, 80)

func test_apply_healing_does_not_exceed_max() -> void:
	_char.current_hp = 90
	_char.apply_healing(50)
	assert_eq(_char.current_hp, 100)

func test_is_alive_true_when_hp_above_zero() -> void:
	_char.current_hp = 1
	assert_true(_char.is_alive())

func test_is_alive_false_when_hp_is_zero() -> void:
	_char.current_hp = 0
	assert_false(_char.is_alive())

func test_apply_mp_cost_reduces_mp() -> void:
	_char.apply_mp_cost(10)
	assert_eq(_char.current_mp, 40)

func test_apply_mp_cost_minimum_is_zero() -> void:
	_char.apply_mp_cost(9999)
	assert_eq(_char.current_mp, 0)

func test_apply_mp_restore_restores_mp() -> void:
	_char.current_mp = 20
	_char.apply_mp_restore(20)
	assert_eq(_char.current_mp, 40)

func test_apply_mp_restore_does_not_exceed_max() -> void:
	_char.current_mp = 45
	_char.apply_mp_restore(20)
	assert_eq(_char.current_mp, 50)

func test_to_dict_contains_required_keys() -> void:
	var data: Dictionary = _char.to_dict()
	assert_has(data, "id")
	assert_has(data, "level")
	assert_has(data, "current_hp")
	assert_has(data, "current_mp")

func test_from_dict_restores_values() -> void:
	var data: Dictionary = {"level": 5, "exp": 200, "current_hp": 60, "current_mp": 30}
	_char.from_dict(data)
	assert_eq(_char.level, 5)
	assert_eq(_char.exp, 200)
	assert_eq(_char.current_hp, 60)
	assert_eq(_char.current_mp, 30)
