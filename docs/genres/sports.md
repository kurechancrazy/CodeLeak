# スポーツゲーム — ジャンルガイド

**次元:** 2D（代表例: サッカー。バスケ・野球等への応用も記載）  
**genre-starters.md:** バンドル 1

---

## コアループ

チームで協力してボールを操作し、相手のゴールに入れて得点する。
ボール物理・プレイヤー切り替え・得点管理・試合タイマーが核心。
プレイヤーが「最もボールに近い味方」を自動操作することで
少人数でもチームプレー感を演出できる。

---

## シーン階層

```
MatchScene (Node2D)
├── Field (StaticBody2D)           — フィールド外周のコリジョン
│   └── CollisionPolygon2D
├── GoalLeft (Area2D)              — 左ゴール判定（右チームが得点）
│   └── CollisionShape2D
├── GoalRight (Area2D)             — 右ゴール判定（左チームが得点）
│   └── CollisionShape2D
├── Ball (RigidBody2D)
│   ├── Sprite2D
│   └── CollisionShape2D (CircleShape2D)
├── TeamLeft (Node2D)              — プレイヤー操作チーム
│   └── Player_0..N (CharacterBody2D)
│       ├── AnimatedSprite2D
│       ├── CollisionShape2D
│       └── KickZone (Area2D)     — ボールが範囲内に入ったら kick() 可能
├── TeamRight (Node2D)             — CPU または Player2
│   └── Player_0..N (CharacterBody2D)
│       ├── AnimatedSprite2D
│       ├── CollisionShape2D
│       └── KickZone (Area2D)
└── HUD (CanvasLayer)
    ├── ScoreLabel
    └── TimerLabel
```

---

## 必須 Autoload

| Autoload | 役割 |
|---------|------|
| AudioManager | ゴール SE・キック SFX・BGM 再生 |
| GameManager | PLAYING / PAUSED / HALFTIME / FINISHED 遷移 |

---

## 主要実装パターン

### ボールキック + 物理

`RigidBody2D` の速度は直接セットせず `apply_central_impulse()` で制御する。
スクリプト側で摩擦を補助適用することでフィールドレイアウト依存のチューニングを避ける。

```gdscript
# ball.gd
class_name Ball
extends RigidBody2D

const MAX_SPEED: float = 600.0
const FRICTION: float = 0.97  # 毎フレーム linear_velocity に乗算

func _physics_process(_delta: float) -> void:
    linear_velocity = linear_velocity * FRICTION
    linear_velocity = linear_velocity.limit_length(MAX_SPEED)

func kick(direction: Vector2, force: float) -> void:
    apply_central_impulse(direction.normalized() * force)
    Logger.info("Ball: kicked dir=(%s) force=%.1f" % [str(direction), force])
```

### 操作プレイヤー自動切り替え（ボール最近傍）

毎フレーム、ボールに最も近い味方を自動的に操作対象として切り替える。
切り替え閾値を設けることでカメラ・UI の過剰な追従を防ぐ。

```gdscript
# team_controller.gd
class_name TeamController
extends Node2D

@export var players: Array[CharacterBody2D] = []
@export var switch_threshold: float = 32.0  # 切り替えヒステリシス（px）

var _controlled: CharacterBody2D = null
var _ball: Ball = null

func _ready() -> void:
    _ball = get_tree().get_first_node_in_group("ball") as Ball
    if players.size() > 0:
        _controlled = players[0]

func _process(_delta: float) -> void:
    _update_controlled_player()
    if _controlled != null:
        _handle_input(_controlled)

func _update_controlled_player() -> void:
    if _ball == null or players.is_empty():
        return
    var nearest: CharacterBody2D = _controlled
    var nearest_dist: float = INF
    for p: CharacterBody2D in players:
        var d: float = p.global_position.distance_to(_ball.global_position)
        if d < nearest_dist:
            nearest_dist = d
            nearest = p
    # ヒステリシス: 現在の操作キャラとの距離差が閾値を超えた場合のみ切り替える
    if _controlled != null:
        var current_dist: float = _controlled.global_position.distance_to(_ball.global_position)
        if current_dist - nearest_dist < switch_threshold:
            return
    _controlled = nearest

func _handle_input(player: CharacterBody2D) -> void:
    var dir: Vector2 = Vector2(
        Input.get_axis("ui_left", "ui_right"),
        Input.get_axis("ui_up", "ui_down")
    )
    if dir != Vector2.ZERO:
        player.move_toward(dir)
    if Input.is_action_just_pressed("action_kick"):
        player.try_kick(_ball)
```

### ゴール判定 + 試合タイマー

`Area2D` の `body_entered` でボールを検出し、得点・リセットを行う。
試合時間は `_process()` の `delta` 累積で管理し、終了時に `GameManager` へ通知する。

```gdscript
# match_scene.gd
class_name MatchScene
extends Node2D

const MATCH_DURATION: float = 90.0  # 秒

@onready var _goal_left: Area2D = $GoalLeft
@onready var _goal_right: Area2D = $GoalRight
@onready var _ball: Ball = $Ball

var _score_left: int = 0
var _score_right: int = 0
var _match_time: float = MATCH_DURATION

func _ready() -> void:
    _goal_left.body_entered.connect(_on_goal_left)
    _goal_right.body_entered.connect(_on_goal_right)

func _process(delta: float) -> void:
    if GameManager.current_state != GameManager.State.PLAYING:
        return
    _match_time -= delta
    EventBus.match_time_updated.emit(_match_time)
    if _match_time <= 0.0:
        _end_match()

func _on_goal_left(body: Node) -> void:
    if not (body is Ball):
        return
    _score_right += 1
    Logger.info("MatchScene: goal! score L=%d R=%d" % [_score_left, _score_right])
    _reset_positions()
    EventBus.score_changed.emit(_score_left, _score_right)

func _on_goal_right(body: Node) -> void:
    if not (body is Ball):
        return
    _score_left += 1
    Logger.info("MatchScene: goal! score L=%d R=%d" % [_score_left, _score_right])
    _reset_positions()
    EventBus.score_changed.emit(_score_left, _score_right)

func _reset_positions() -> void:
    _ball.linear_velocity = Vector2.ZERO
    _ball.angular_velocity = 0.0
    _ball.global_position = Vector2.ZERO  # フィールド中央に合わせて調整

func _end_match() -> void:
    Logger.info("MatchScene: match ended L=%d R=%d" % [_score_left, _score_right])
    EventBus.match_ended.emit(_score_left, _score_right)
    GameManager.change_state(GameManager.State.GAME_OVER)
```

### CPU 敵 AI（シンプルベクトル追従）

`NavigationAgent2D` は広いフィールドでは過剰。
ボールへの単純なベクトル追従で十分なゲームプレー感が得られる。

```gdscript
# cpu_team_controller.gd
class_name CpuTeamController
extends Node2D

@export var players: Array[CharacterBody2D] = []
@export var goal_target: Vector2 = Vector2(600.0, 0.0)  # 攻撃目標（相手ゴール中央）
@export var kick_range: float = 40.0
@export var kick_force: float = 500.0

var _ball: Ball = null

func _ready() -> void:
    _ball = get_tree().get_first_node_in_group("ball") as Ball

func _process(_delta: float) -> void:
    if _ball == null:
        return
    for player: CharacterBody2D in players:
        _update_player_ai(player)

func _update_player_ai(player: CharacterBody2D) -> void:
    var to_ball: Vector2 = _ball.global_position - player.global_position
    if to_ball.length() < kick_range:
        # ボールをゴール方向に蹴る
        var kick_dir: Vector2 = (goal_target - _ball.global_position).normalized()
        _ball.kick(kick_dir, kick_force)
    else:
        # ボールに向かって移動
        player.move_toward(to_ball.normalized())
```

---

## よくある地雷

- `RigidBody2D` の `linear_velocity` を直接代入すると物理エンジンとの整合性が崩れる → `apply_central_impulse()` または `apply_force()` を使う
- ゴール判定を `body_entered` で受けたとき、ボール以外のキャラクターも検出してしまう → `if not (body is Ball): return` で早期リターンする
- CPU AI のパス判断に `NavigationAgent2D` を使うとフィールドが広い場合に重い → シンプルなベクトル追従で実装し、障害物回避が必要になったら後から追加する
- プレイヤー切り替えを毎フレーム行うとカメラやUIが激しく揺れる → ヒステリシス（距離差の閾値）を設けて切り替え頻度を抑制する
- `_reset_positions()` でボールの `global_position` を直接変更すると、物理シミュレーション上での位置と描画位置がずれることがある → `_physics_process()` 内または `set_deferred("global_position", pos)` で設定する
- 試合タイマーをポーズ中も減算すると試合時間が不正になる → `GameManager.current_state` を確認してから `delta` を減算する

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/sports.md` | このファイル |
| Autoload | なし（コアのみ使用） | — |

project.godot から追加で削除するエントリなし（このジャンルはコア Autoload のみ使用する）。
