extends Node
## ターンベース戦闘のフェーズ管理・ターン制御を担う Autoload。
## ダメージ計算は scripts/utils/battle_calc.gd に委譲する。
## 詳細設計: docs/rpg/battle-system.md

enum Phase {
	IDLE,
	START,
	COMMAND,
	EXECUTE,
	END,
}

var _phase: Phase = Phase.IDLE
var _enemy_roster: Array[EnemyData] = []
var _turn_queue: Array[String] = []
var _pending_commands: Dictionary = {}   # {actor_id: Dictionary}

# ── 公開 API ──────────────────────────────────────────────

func start_battle(enemies: Array[EnemyData]) -> void:
	if _phase != Phase.IDLE:
		Logger.warn("Battle already in progress")
		return
	_enemy_roster = enemies.map(
		func(e: EnemyData) -> EnemyData:
			var copy: EnemyData = e.duplicate()
			copy.current_hp = copy.max_hp
			copy.current_mp = copy.max_mp
			return copy
	)
	_phase = Phase.START
	GameManager.change_state(GameManager.GameState.BATTLE_START)
	EventBus.battle_started.emit(_enemy_roster)
	Logger.info("Battle started", {"enemy_count": enemies.size()})

func submit_command(actor_id: String, command: Dictionary) -> void:
	if _phase != Phase.COMMAND:
		Logger.warn("Command submitted outside COMMAND phase", {"actor": actor_id})
		return
	_pending_commands[actor_id] = command
	_check_all_commands_ready()

func get_enemies() -> Array[EnemyData]:
	return _enemy_roster

# ── フェーズ遷移 ──────────────────────────────────────────

func begin_command_phase() -> void:
	_phase = Phase.COMMAND
	_pending_commands.clear()
	_turn_queue = _build_turn_queue()
	GameManager.change_state(GameManager.GameState.BATTLE_COMMAND)
	EventBus.battle_execution_started.emit()

func _check_all_commands_ready() -> void:
	var alive: Array[CharacterData] = PartyManager.alive_members()
	var all_ready: bool = alive.all(
		func(m: CharacterData) -> bool: return _pending_commands.has(m.id)
	)
	if all_ready:
		_start_execution_phase()

func _start_execution_phase() -> void:
	_phase = Phase.EXECUTE
	GameManager.change_state(GameManager.GameState.BATTLE_EXECUTE)
	_process_next_turn()

func _process_next_turn() -> void:
	if _turn_queue.is_empty():
		_check_battle_end()
		return
	var actor_id: String = _turn_queue.pop_front()
	EventBus.turn_started.emit(actor_id)

func _check_battle_end() -> void:
	if _is_all_enemies_defeated():
		_end_battle(true)
	elif PartyManager.is_all_defeated():
		_end_battle(false)
	else:
		begin_command_phase()

func _end_battle(victory: bool) -> void:
	_phase = Phase.END
	GameManager.change_state(GameManager.GameState.BATTLE_END)
	if victory:
		_distribute_rewards()
	EventBus.battle_ended.emit(victory)
	Logger.info("Battle ended", {"victory": victory})

func _distribute_rewards() -> void:
	var total_exp: int = 0
	var total_gold: int = 0
	for enemy: EnemyData in _enemy_roster:
		total_exp += enemy.exp_reward
		total_gold += enemy.gold_reward
		var drop: String = enemy.roll_drop()
		if not drop.is_empty():
			InventoryManager.add_item(drop)
			EventBus.item_dropped.emit(drop)
	EventBus.exp_gained.emit(total_exp)
	EventBus.gold_gained.emit(total_gold)

# ── ユーティリティ ────────────────────────────────────────

func _build_turn_queue() -> Array[String]:
	var actors: Array[Dictionary] = []
	for member: CharacterData in PartyManager.alive_members():
		actors.append({"id": member.id, "agility": member.agility})
	for enemy: EnemyData in _enemy_roster:
		if enemy.is_alive():
			actors.append({"id": enemy.id, "agility": enemy.agility})
	actors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.agility != b.agility:
			return a.agility > b.agility
		return randf() > 0.5
	)
	var result: Array[String] = []
	for a: Dictionary in actors:
		result.append(a.id)
	return result

func _is_all_enemies_defeated() -> bool:
	return _enemy_roster.all(func(e: EnemyData) -> bool: return not e.is_alive())

# ── ライフサイクル ────────────────────────────────────────

func _ready() -> void:
	EventBus.battle_ended.connect(_on_battle_ended)

func _exit_tree() -> void:
	EventBus.battle_ended.disconnect(_on_battle_ended)

func _on_battle_ended(_victory: bool) -> void:
	_phase = Phase.IDLE
	_enemy_roster.clear()
	_turn_queue.clear()
	_pending_commands.clear()
