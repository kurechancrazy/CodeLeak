# Field System — フィールドマップ・エンカウント・エリア遷移

**対象:** Godot 4.4+ / 2D JRPG フィールド・ダンジョン実装

---

## Claude Code 実装停止チェックリスト

```
□ ランダムエンカウント判定をシーンスクリプトに書こうとしている
□ エリア遷移トリガーを手動で座標チェックして実装しようとしている（Area2D を使う）
□ イベントフラグを GameManager の汎用 Dictionary で管理しようとしている（FlagManager を使う）
□ NPC の会話テキストをシーンスクリプトに直書きしようとしている
```

---

## 1. フィールドシーンの階層設計

```
FieldScene（Node2D）
├── TileMap                          ← 地形（background / ground / foreground レイヤー）
├── Entities（Node2D）               ← 動的オブジェクトのコンテナ
│   ├── Player（CharacterBody2D）
│   ├── NPCs（Node2D）
│   │   └── NPC_001（Area2D）        ← 会話可能範囲を持つ NPC
│   └── Events（Node2D）
│       └── DoorTrigger（Area2D）    ← エリア遷移トリガー
├── Camera2D                         ← Player を追従
└── FieldUI（CanvasLayer, layer=1）
    └── MinimapPanel（Control）      ← 任意
```

---

## 2. プレイヤー移動（4方向・タイルベース or 自由移動）

### 自由移動（FF6 スタイル）

```gdscript
# scenes/characters/player_field.gd
class_name PlayerField
extends CharacterBody2D

const WALK_SPEED: float = 80.0
const RUN_SPEED: float  = 160.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
    if GameManager.state not in [GameManager.GameState.FIELD]:
        velocity = Vector2.ZERO
        return

    var direction: Vector2 = Input.get_vector(
        "move_left", "move_right", "move_up", "move_down"
    )
    var speed: float = RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED
    velocity = direction * speed
    move_and_slide()

    _update_animation(direction)

    if direction != Vector2.ZERO:
        EventBus.player_moved.emit()

func _update_animation(direction: Vector2) -> void:
    if direction == Vector2.ZERO:
        sprite.play("idle_" + _last_direction)
        return
    # 向きを記録してアイドル時に使う
    if direction.x > 0.0:
        _last_direction = "right"
    elif direction.x < 0.0:
        _last_direction = "left"
    elif direction.y > 0.0:
        _last_direction = "down"
    else:
        _last_direction = "up"
    sprite.play("walk_" + _last_direction)

var _last_direction: String = "down"
```

---

## 3. ランダムエンカウント実装

エンカウント判定は `EncounterManager` Autoload が担当する。
シーンは `EventBus.player_moved` を発行するだけでよい。

```gdscript
# autoloads/encounter_manager.gd
extends Node

const MIN_STEPS: int = 10   # エンカウントまでの最小歩数
const MAX_STEPS: int = 30   # エンカウントまでの最大歩数

var _step_counter: int = 0
var _encounter_threshold: int = 0
var _current_encounter_table: String = ""  # 現在のエリアのエンカウントテーブルID

func _ready() -> void:
    EventBus.player_moved.connect(_on_player_moved)
    EventBus.area_entered.connect(_on_area_entered)
    _roll_next_threshold()

func _exit_tree() -> void:
    EventBus.player_moved.disconnect(_on_player_moved)
    EventBus.area_entered.disconnect(_on_area_entered)

func set_encounter_table(table_id: String) -> void:
    _current_encounter_table = table_id
    _step_counter = 0
    _roll_next_threshold()

func _on_player_moved() -> void:
    if _current_encounter_table.is_empty():
        return  # エンカウントテーブルなし（町・ダンジョン外）
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
    # エンカウントテーブルから敵グループをランダム選択
    # テーブルは resources/data/encounters/{table_id}.tres で定義
    var path: String = "res://resources/data/encounters/%s.tres" % _current_encounter_table
    if not ResourceLoader.exists(path):
        Logger.error("Encounter table not found", {"id": _current_encounter_table})
        return []
    var table: Resource = load(path)
    return table.roll()

func _on_area_entered(area_id: String) -> void:
    # エリア移動時にエンカウントテーブルを切り替える
    set_encounter_table(area_id)
```

---

## 4. エリア遷移トリガー（扉・階段・エリア境界）

```gdscript
# scenes/triggers/area_transition.gd
class_name AreaTransition
extends Area2D

@export var target_scene: String = ""          # 遷移先シーンパス
@export var target_spawn_id: String = "default" # 遷移先のスポーン地点ID
@export var encounter_table: String = ""        # 遷移後のエンカウントテーブル

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
    if not body is PlayerField:
        return
    if target_scene.is_empty():
        Logger.warn("AreaTransition: target_scene not set")
        return
    EventBus.area_transition_requested.emit(target_scene, target_spawn_id, encounter_table)
```

SceneManager が `EventBus.area_transition_requested` を購読してシーン遷移を実行する。

---

## 5. NPC インタラクション

```gdscript
# scenes/npc/npc_base.gd
class_name NpcBase
extends Area2D

@export var npc_id: String = ""          # FlagManager・DialogManager で参照するID
@export var dialog_id: String = ""       # DialogManager に渡すダイアログID
@export var interaction_range: float = 32.0

func _ready() -> void:
    # コリジョン形状は Inspector で設定
    pass

func _input(event: InputEvent) -> void:
    if not event.is_action_just_pressed("confirm"):
        return
    # プレイヤーが近くにいるか確認
    var player: PlayerField = _find_nearby_player()
    if player == null:
        return
    _start_dialog()

func _start_dialog() -> void:
    if dialog_id.is_empty():
        return
    # フラグで会話内容を切り替える場合は FlagManager を参照
    var actual_dialog: String = FlagManager.resolve_dialog(npc_id, dialog_id)
    EventBus.dialog_requested.emit(actual_dialog)

func _find_nearby_player() -> PlayerField:
    for body: Node2D in get_overlapping_bodies():
        if body is PlayerField:
            return body
    return null
```

---

## 6. EventBus シグナル設計（フィールド系）

`autoloads/event_bus.gd` に追加するシグナル:

```gdscript
signal player_moved                                              # 1歩移動のたびに発行
signal area_entered(area_id: String)                            # エリア進入
signal area_transition_requested(
    scene_path: String,
    spawn_id: String,
    encounter_table: String
)
signal dialog_requested(dialog_id: String)                      # 会話開始要求
signal chest_opened(chest_id: String, item_id: String)          # 宝箱開封
signal event_triggered(event_id: String)                        # 汎用イベントトリガー
```

---

## 7. フラグ管理（イベントスイッチ）

```gdscript
# autoloads/flag_manager.gd
extends Node

# フラグは SaveManager 経由でセーブデータに永続化する
var _flags: Dictionary = {}   # {flag_id: bool}

func _ready() -> void:
    EventBus.load_requested.connect(_on_load)

func set_flag(flag_id: String) -> void:
    _flags[flag_id] = true
    Logger.debug("Flag set", {"id": flag_id})

func clear_flag(flag_id: String) -> void:
    _flags[flag_id] = false

func get_flag(flag_id: String) -> bool:
    return _flags.get(flag_id, false)

func resolve_dialog(npc_id: String, default_dialog_id: String) -> String:
    # フラグによって会話IDを切り替える（各NPCのロジックはリソースで定義）
    return default_dialog_id  # 基本実装：上書きして切り替えを追加

func _on_load() -> void:
    var raw: Variant = SaveManager.get_value("flags", "switches", {})
    if raw is Dictionary:
        _flags = raw
```

---

## 8. セーブデータ追加フィールド（フィールド系）

`docs/architecture/save-schema.md` の表に追加するフィールド:

| section | key | 型 | 説明 |
|---------|-----|----|------|
| `field` | `current_map` | `String` | 現在のマップシーンパス |
| `field` | `spawn_id` | `String` | 復帰スポーン地点 ID |
| `flags` | `switches` | `String`（JSON） | イベントフラグ辞書 |
| `field` | `step_counter` | `int` | 総歩数（図鑑・実績用） |
