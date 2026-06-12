extends Node
## ランダムエンカウント判定を担う Autoload。
## 詳細: docs/rpg/field-system.md

const MIN_STEPS: int = 10
const MAX_STEPS: int = 30

var _step_counter: int = 0
var _encounter_threshold: int = 0
var _current_table_id: String = ""   # 空文字 = エンカウントなし

func _ready() -> void:
	EventBus.player_moved.connect(_on_player_moved)
	EventBus.area_entered.connect(_on_area_entered)
	EventBus.battle_started.connect(_on_battle_started)
	_roll_next_threshold()

func _exit_tree() -> void:
	EventBus.player_moved.disconnect(_on_player_moved)
	EventBus.area_entered.disconnect(_on_area_entered)
	EventBus.battle_started.disconnect(_on_battle_started)

# ── 公開 API ──────────────────────────────────────────────

func set_encounter_table(table_id: String) -> void:
	_current_table_id = table_id
	_step_counter = 0
	_roll_next_threshold()

func disable_encounters() -> void:
	_current_table_id = ""

# ── プライベート ──────────────────────────────────────────

func _on_player_moved() -> void:
	if _current_table_id.is_empty():
		return
	if GameManager.state != GameManager.GameState.FIELD:
		return
	_step_counter += 1
	if _step_counter >= _encounter_threshold:
		_trigger_encounter()

func _trigger_encounter() -> void:
	_step_counter = 0
	_roll_next_threshold()
	var enemies: Array[EnemyData] = _roll_enemy_group()
	if enemies.is_empty():
		return
	BattleManager.start_battle(enemies)

func _roll_next_threshold() -> void:
	_encounter_threshold = randi_range(MIN_STEPS, MAX_STEPS)

func _roll_enemy_group() -> Array[EnemyData]:
	var path: String = "res://resources/data/encounters/%s.tres" % _current_table_id
	if not ResourceLoader.exists(path):
		Logger.error("Encounter table not found", {"id": _current_table_id})
		return []
	var table: Resource = load(path)
	if not table.has_method("roll"):
		Logger.error("Encounter table missing roll() method", {"id": _current_table_id})
		return []
	return table.roll()

func _on_area_entered(area_id: String) -> void:
	set_encounter_table(area_id)

func _on_battle_started(_enemies: Array[EnemyData]) -> void:
	_step_counter = 0
	_roll_next_threshold()
