# ステルス — ジャンルガイド

**次元:** 2D（3D への応用は `docs/genres/3d-horror.md` の RayCast3D 視線パターンを参照）  
**genre-starters.md:** バンドル 1

---

## コアループ

視野・音・明暗を利用して敵の警戒を回避しながら目的を達成する。
視野円錐の実装・警戒ステートマシン・隠れ場所システムが核心。
発見されると警戒度が上昇し、一定値を超えると即座に追跡状態へ遷移する。

---

## シーン階層

```
Level (Node2D)
├── TileMapLayer              — 壁・床（RayCast2D の遮蔽物として機能）
├── LightLayer (Node2D)       — PointLight2D など（明暗判定用）
├── HidingSpots (Node2D)
│   ├── Locker (Area2D)       — 接触で hide 可能
│   └── Bush (Area2D)         — 草むら・低速移動で隠れられる
├── Guards (Node2D)
│   └── Guard (CharacterBody2D)
│       ├── AnimatedSprite2D
│       ├── CollisionShape2D
│       ├── SightCone (Area2D)    — 扇形 CollisionPolygon2D
│       ├── SightRay (RayCast2D)  — 遮蔽物チェック用
│       ├── NavigationAgent2D
│       └── PatrolPath (Path2D)   — 巡回経路
├── Player (CharacterBody2D)
│   ├── AnimatedSprite2D
│   ├── CollisionShape2D
│   └── NoiseEmitter (Node)       — 足音半径のデバッグ可視化
└── HUD (CanvasLayer)
    ├── AlertIndicator (TextureProgressBar)  — 警戒度ゲージ
    └── StealthIndicator (TextureRect)       — 隠れ中アイコン
```

---

## 必須 Autoload

コアのみ使用（GameManager / EventBus / Logger）。

---

## 主要実装パターン

### 視野円錐 + 遮蔽物チェック

`SightCone`（Area2D）は敵の向きに追従する扇形コリジョン。
Area2D に入っているだけでは「見えている」ではなく、
RayCast2D で壁などの遮蔽物がないかを追加チェックする。

```gdscript
# Guard.gd
extends CharacterBody2D

const SIGHT_RANGE: float = 200.0
const SIGHT_ANGLE: float = PI / 3.0   # 60 度（片側 30 度）

@onready var _sight_ray: RayCast2D = $SightRay

var _player: Node2D = null

func _ready() -> void:
    _player = get_tree().get_first_node_in_group("player")

func _can_see_player() -> bool:
    if _player == null or _player.get("is_hidden"):
        return false
    var to_player: Vector2 = _player.global_position - global_position
    if to_player.length() > SIGHT_RANGE:
        return false
    # 前方角度内かチェック（ガードの向き = global_rotation）
    var angle_to: float = to_player.angle()
    var diff: float = angle_difference(angle_to, global_rotation)
    if absf(diff) > SIGHT_ANGLE / 2.0:
        return false
    # 遮蔽物チェック
    _sight_ray.target_position = to_player
    _sight_ray.force_raycast_update()
    return not _sight_ray.is_colliding()
```

### 警戒ステートマシン

`_suspicion_meter`（0.0 〜 1.0）を時間経過で増減し、閾値に応じて AlertLevel を遷移させる。
AlertLevel.ALERTED になると EventBus でゲーム全体に通知する。

```gdscript
# Guard.gd（続き）
enum AlertLevel { UNAWARE, SUSPICIOUS, ALERTED }

const SUSPICION_RISE: float = 0.5    # 視野内: 上昇速度 / 秒
const SUSPICION_DECAY: float = 0.3   # 視野外: 減少速度 / 秒
const THRESHOLD_SUSPICIOUS: float = 0.4
const THRESHOLD_ALERTED: float = 1.0

var _alert_level: AlertLevel = AlertLevel.UNAWARE
var _suspicion_meter: float = 0.0

func _process(delta: float) -> void:
    if _can_see_player():
        _suspicion_meter = minf(_suspicion_meter + SUSPICION_RISE * delta, 1.0)
    else:
        _suspicion_meter = maxf(_suspicion_meter - SUSPICION_DECAY * delta, 0.0)
    _update_alert_level()
    EventBus.guard_suspicion_changed.emit(self, _suspicion_meter)

func _update_alert_level() -> void:
    match _alert_level:
        AlertLevel.UNAWARE:
            if _suspicion_meter >= THRESHOLD_SUSPICIOUS:
                _alert_level = AlertLevel.SUSPICIOUS
        AlertLevel.SUSPICIOUS:
            if _suspicion_meter >= THRESHOLD_ALERTED:
                _alert_level = AlertLevel.ALERTED
                EventBus.alert_raised.emit(global_position)
            elif _suspicion_meter <= 0.0:
                _alert_level = AlertLevel.UNAWARE
        AlertLevel.ALERTED:
            if _suspicion_meter <= THRESHOLD_SUSPICIOUS:
                _alert_level = AlertLevel.SUSPICIOUS
```

### 音の伝播 + 隠れ場所

プレイヤーが走ると半径の大きいノイズを発生させ、
範囲内のガードに `hear_noise()` を送る。
HidingSpot（Area2D）に入ると `is_hidden` フラグで視認不可にする。

```gdscript
# Player.gd
extends CharacterBody2D

const WALK_NOISE_RADIUS: float = 60.0
const RUN_NOISE_RADIUS: float = 150.0
const CROUCH_NOISE_RADIUS: float = 20.0

var is_hidden: bool = false
var _is_running: bool = false
var _is_crouching: bool = false

func _physics_process(delta: float) -> void:
    _handle_input()
    move_and_slide()
    if is_on_floor():
        _emit_footstep_noise()

func _emit_footstep_noise() -> void:
    if velocity.length() < 5.0:
        return
    var radius: float = CROUCH_NOISE_RADIUS if _is_crouching else (
        RUN_NOISE_RADIUS if _is_running else WALK_NOISE_RADIUS
    )
    for guard: Node in get_tree().get_nodes_in_group("guard"):
        if guard is Node2D:
            var g: Node2D = guard as Node2D
            if g.global_position.distance_to(global_position) <= radius:
                g.hear_noise(global_position)

func _handle_input() -> void:
    _is_running = Input.is_action_pressed("run")
    _is_crouching = Input.is_action_pressed("crouch")
```

```gdscript
# HidingSpot.gd
extends Area2D

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        body.set("is_hidden", true)

func _on_body_exited(body: Node2D) -> void:
    if body.is_in_group("player"):
        body.set("is_hidden", false)
```

### 巡回 AI（NavigationAgent2D）

ガードはウェイポイントを順番に歩き、ALERTED 時はプレイヤー最終目撃地点へ向かう。

```gdscript
# Guard.gd（巡回・追跡）
@onready var _nav_agent: NavigationAgent2D = $NavigationAgent2D

var _waypoints: Array[Vector2] = []
var _waypoint_index: int = 0
var _last_known_player_pos: Vector2 = Vector2.ZERO

func hear_noise(noise_pos: Vector2) -> void:
    if _alert_level == AlertLevel.UNAWARE:
        _alert_level = AlertLevel.SUSPICIOUS
    _last_known_player_pos = noise_pos

func _navigate(delta: float) -> void:
    var target: Vector2
    match _alert_level:
        AlertLevel.ALERTED:
            target = _last_known_player_pos
        _:
            if _waypoints.is_empty():
                return
            target = _waypoints[_waypoint_index]
    _nav_agent.target_position = target
    if _nav_agent.is_navigation_finished():
        _waypoint_index = (_waypoint_index + 1) % _waypoints.size()
        return
    var next_pos: Vector2 = _nav_agent.get_next_path_position()
    velocity = (next_pos - global_position).normalized() * _get_speed()
    move_and_slide()

func _get_speed() -> float:
    match _alert_level:
        AlertLevel.ALERTED:
            return 120.0
        AlertLevel.SUSPICIOUS:
            return 80.0
        _:
            return 50.0
```

---

## よくある地雷

- `RayCast2D.force_raycast_update()` を呼ばないと前フレームの結果が返る → 視野判定ごとに必ず呼ぶ
- `SightCone`（Area2D）の `collision_mask` を player レイヤーのみに設定しないと壁に反応して誤判定する
- 隠れ中に `collision_layer = 0` にするとガードの NavigationAgent2D がパス計算できなくなる → 視認チェック用レイヤーのみ切る
- `get_nodes_in_group()` を `_physics_process` で毎フレーム呼ぶとコストが高い → `_ready()` でリストをキャッシュする
- ALERTED 後にガードが扉を開けるギミックがある場合、TileMapLayer のコリジョン変更は NavigationServer2D の再ベイクが必要

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/stealth.md` | このファイル |
| Autoload | なし（コアのみ使用） | — |

project.godot から追加で削除するエントリなし（このジャンルは追加 Autoload を持たない）。
