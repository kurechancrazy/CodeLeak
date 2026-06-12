extends GutTest


func test_default_type_is_attack() -> void:
	var cmd: BattleCommand = BattleCommand.new()
	assert_eq(cmd.type, BattleCommand.Type.ATTACK)


func test_default_actor_id_is_empty() -> void:
	var cmd: BattleCommand = BattleCommand.new()
	assert_eq(cmd.actor_id, "")


func test_default_target_ids_is_empty() -> void:
	var cmd: BattleCommand = BattleCommand.new()
	assert_eq(cmd.target_ids.size(), 0)


func test_default_skill_is_null() -> void:
	var cmd: BattleCommand = BattleCommand.new()
	assert_null(cmd.skill)


func test_default_item_is_null() -> void:
	var cmd: BattleCommand = BattleCommand.new()
	assert_null(cmd.item)


func test_set_type_magic() -> void:
	var cmd: BattleCommand = BattleCommand.new()
	cmd.type = BattleCommand.Type.MAGIC
	assert_eq(cmd.type, BattleCommand.Type.MAGIC)


func test_all_types_accessible() -> void:
	assert_eq(BattleCommand.Type.ATTACK, 0)
	assert_eq(BattleCommand.Type.MAGIC, 1)
	assert_eq(BattleCommand.Type.ITEM, 2)
	assert_eq(BattleCommand.Type.DEFEND, 3)
	assert_eq(BattleCommand.Type.RUN, 4)
