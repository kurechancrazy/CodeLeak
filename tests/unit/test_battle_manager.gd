extends GutTest

var _bm: Node = null


func before_each() -> void:
	_bm = load("res://autoloads/battle_manager.gd").new()
	# _ready() を呼ばず Autoload 依存を回避して純粋ロジックのみテスト


func after_each() -> void:
	_bm.free()


# --- 初期状態 ---

func test_initial_phase_is_idle() -> void:
	assert_eq(_bm._phase, _bm.Phase.IDLE)


func test_get_enemies_returns_empty_initially() -> void:
	assert_eq(_bm.get_enemies().size(), 0)


# --- start_battle ガード ---

func test_start_battle_guard_does_not_add_enemies_when_active() -> void:
	_bm._phase = _bm.Phase.COMMAND  # アクティブ状態にする
	var enemy: EnemyData = EnemyData.new()
	_bm.start_battle([enemy])
	assert_eq(_bm.get_enemies().size(), 0, "アクティブ中は start_battle を無視すること")


# --- submit_command ガード ---

func test_submit_command_ignored_outside_command_phase() -> void:
	_bm._phase = _bm.Phase.IDLE
	_bm.submit_command("hero", {"type": "attack"})
	assert_eq(_bm._pending_commands.size(), 0, "COMMAND フェーズ外ではコマンドを無視すること")


# --- _is_all_enemies_defeated ---

func test_all_enemies_defeated_when_empty_roster() -> void:
	assert_true(_bm._is_all_enemies_defeated(), "敵なしは全滅扱い")


func test_all_enemies_defeated_false_when_alive_enemy() -> void:
	var enemy: EnemyData = EnemyData.new()
	enemy.max_hp = 100
	enemy.current_hp = 50
	_bm._enemy_roster = [enemy]
	assert_false(_bm._is_all_enemies_defeated())


func test_all_enemies_defeated_true_when_all_ko() -> void:
	var enemy: EnemyData = EnemyData.new()
	enemy.max_hp = 100
	enemy.current_hp = 0
	_bm._enemy_roster = [enemy]
	assert_true(_bm._is_all_enemies_defeated())


# --- リセット (_on_battle_ended) ---

func test_on_battle_ended_resets_phase_to_idle() -> void:
	_bm._phase = _bm.Phase.END
	_bm._on_battle_ended(true)
	assert_eq(_bm._phase, _bm.Phase.IDLE)


func test_on_battle_ended_clears_enemy_roster() -> void:
	var enemy: EnemyData = EnemyData.new()
	_bm._enemy_roster = [enemy]
	_bm._on_battle_ended(false)
	assert_eq(_bm._enemy_roster.size(), 0)


func test_on_battle_ended_clears_pending_commands() -> void:
	_bm._pending_commands["hero"] = {"type": "attack"}
	_bm._on_battle_ended(true)
	assert_eq(_bm._pending_commands.size(), 0)
