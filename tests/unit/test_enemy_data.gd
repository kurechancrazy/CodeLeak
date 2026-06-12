extends GutTest

var _enemy: EnemyData

func before_each() -> void:
	_enemy = EnemyData.new()
	_enemy.max_hp = 100
	_enemy.current_hp = 100
	_enemy.drop_items = ["potion", "ether"]
	_enemy.drop_rate = 1.0   # 必ずドロップ

func test_apply_damage_reduces_hp() -> void:
	_enemy.apply_damage(40)
	assert_eq(_enemy.current_hp, 60)

func test_apply_damage_minimum_is_zero() -> void:
	_enemy.apply_damage(9999)
	assert_eq(_enemy.current_hp, 0)

func test_is_alive_true_when_hp_above_zero() -> void:
	_enemy.current_hp = 1
	assert_true(_enemy.is_alive())

func test_is_alive_false_when_hp_is_zero() -> void:
	_enemy.current_hp = 0
	assert_false(_enemy.is_alive())

func test_apply_healing_capped_at_max() -> void:
	_enemy.current_hp = 80
	_enemy.apply_healing(50)
	assert_eq(_enemy.current_hp, 100)

func test_roll_drop_returns_item_when_drop_rate_1() -> void:
	var drop: String = _enemy.roll_drop()
	assert_true(drop == "potion" or drop == "ether")

func test_roll_drop_returns_empty_when_no_items() -> void:
	_enemy.drop_items = []
	var drop: String = _enemy.roll_drop()
	assert_eq(drop, "")

func test_roll_drop_returns_empty_when_drop_rate_0() -> void:
	_enemy.drop_rate = 0.0
	var drop: String = _enemy.roll_drop()
	assert_eq(drop, "")
