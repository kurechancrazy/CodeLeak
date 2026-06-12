# 2D Patterns — 2D ゲーム固有の実装パターン

**対象:** Godot 4.4+ / GDScript 2.0 / 2Dゲーム（Node2D ベース）

---

## Claude Code 実装停止チェックリスト

```
□ CanvasLayer を使わずに HUD を World ノードの子に配置しようとしている
□ TileMap のコリジョンレイヤーを設計せずに実装を始めようとしている
□ Camera2D を複数配置しようとしている（同時に有効にできるのは1台）
□ AnimatedSprite2D と AnimationPlayer を同じキャラクターに混在させようとしている
```

---

## シーン階層の設計ルール

```
World（Node2D）          ← ゲームワールドのルート
├── TileMap              ← 地形レイヤー（必要ならサブレイヤーに分割）
├── Entities（Node2D）   ← 動的オブジェクトのコンテナ
│   ├── Player
│   └── Enemies（Node2D）
├── Camera2D             ← World の子に置く（HUD ではない）
└── HUD（CanvasLayer）   ← layer=1。UI は必ずここに入れる
    ├── ScoreLabel
    └── HealthBar
```

**HUD は必ず CanvasLayer の子にする。** Node2D の子にすると World のカメラに追従して画面外に消える。

---

## TileMap の設計

### レイヤー構成（推奨）

| レイヤー | 用途 | collision |
|---------|------|-----------|
| 0: Background | 装飾タイル（空・山） | なし |
| 1: Ground | 地形（踏める床・壁） | あり |
| 2: Foreground | キャラクターの前に来るタイル | なし |

```gdscript
# TileMap のコリジョンを確認する（デバッグ用）
# Project Settings > Debug > Visible Collision Shapes = true
```

### TileMap でのコリジョンレイヤー設定

`TileSet` の Physics Layer で設定する。スクリプトからは変更しない。
collision_layer / collision_mask は Inspector の TileSet > Physics Layer で定義。

### TileMap の位置合わせ

```gdscript
# タイルの中心座標をワールド座標に変換
var world_pos: Vector2 = tile_map.map_to_local(Vector2i(x, y))

# ワールド座標からタイル座標に変換
var tile_pos: Vector2i = tile_map.local_to_map(world_position)
```

---

## Camera2D の設定

### 基本設定（Inspector で行う）

| プロパティ | 推奨値 | 説明 |
|-----------|--------|------|
| `position_smoothing_enabled` | true | カメラ追従を滑らかにする |
| `position_smoothing_speed` | 5.0 | 追従速度（大きいほど追従が速い） |
| `limit_left/right/top/bottom` | ステージサイズ | カメラの移動範囲を制限 |

### カメラの limit をコードで設定する

```gdscript
# TileMap のサイズからカメラ範囲を動的に設定
func _setup_camera_limits() -> void:
    var map_rect: Rect2i = tile_map.get_used_rect()
    var tile_size: Vector2i = tile_map.tile_set.tile_size
    camera.limit_left = map_rect.position.x * tile_size.x
    camera.limit_top = map_rect.position.y * tile_size.y
    camera.limit_right = map_rect.end.x * tile_size.x
    camera.limit_bottom = map_rect.end.y * tile_size.y
```

**禁止:** 複数の Camera2D を `current = true` に同時設定する → 動作が不定になる

---

## Sprite2D vs AnimatedSprite2D の使い分け

| ノード | 使う場面 |
|--------|---------|
| `Sprite2D` | 静止画・1枚絵・状態を AnimationPlayer で管理する場合 |
| `AnimatedSprite2D` | 単純なスプライトシートアニメーション（walk/idle/jump）|
| `Sprite2D + AnimationPlayer` | 複雑なアニメーション（パーツ組み合わせ・ブレンド）|

```gdscript
# AnimatedSprite2D の切り替え
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func update_animation(velocity: Vector2) -> void:
    if velocity.x != 0.0:
        sprite.play("walk")
        sprite.flip_h = velocity.x < 0.0
    elif not is_on_floor():
        sprite.play("jump")
    else:
        sprite.play("idle")
```

**禁止:** `AnimatedSprite2D` と `AnimationPlayer` を同じノードに両方つけてアニメーションを競合させる

---

## HUD の実装パターン

```gdscript
# scenes/ui/hud.gd
extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
    EventBus.score_changed.connect(_on_score_changed)
    EventBus.health_changed.connect(_on_health_changed)

func _on_score_changed(new_score: int) -> void:
    score_label.text = str(new_score)

func _on_health_changed(new_health: int, max_health: int) -> void:
    health_bar.max_value = max_health
    health_bar.value = new_health
```

HUD はゲームロジックを知らない。EventBus のシグナルだけを購読して表示を更新する。

---

## ポーズメニューの実装パターン

```gdscript
# scenes/ui/pause_menu.gd
extends CanvasLayer

func _ready() -> void:
    visible = false
    process_mode = Node.PROCESS_MODE_ALWAYS  # ポーズ中も動作させる

func _input(event: InputEvent) -> void:
    if event.is_action_just_pressed("pause"):
        toggle_pause()

func toggle_pause() -> void:
    var is_paused: bool = not get_tree().paused
    get_tree().paused = is_paused
    visible = is_paused
    EventBus.game_paused.emit(is_paused)
```

**重要:** ポーズメニュー自身は `PROCESS_MODE_ALWAYS` に設定する（ポーズ中も入力を受け付けるため）。

---

## 2D ライティング注意事項

- 2D ライティングを使う場合は `CanvasModulate` ノードで環境光を設定する
- `Light2D` を大量に配置するとパフォーマンスが低下する → 必要最小限に
- モバイルターゲットでは 2D ライティングを無効にすることを検討する
