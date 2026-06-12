# Physics — 物理演算・コリジョン実装ガイド

**対象:** Godot 4.4+ / GDScript 2.0（2D物理。3Dは docs/3d/patterns.md も参照）

---

## Claude Code 実装停止チェックリスト

```
□ RigidBody2D の position を _physics_process 内で直接セットしようとしている
□ CollisionLayer/CollisionMask を設計せずにデフォルトのまま実装しようとしている
□ Area2D のシグナルを _process 内でポーリングしようとしている
□ CharacterBody2D に gravity を _process 内で加算しようとしている
```

---

## Body 型の選択基準

```
動かすのは自分（プレイヤー・敵）で移動制御が必要？
  → CharacterBody2D（move_and_slide + 独自ロジック）

物理エンジンに動きを任せたい（岩・ドラム缶）？
  → RigidBody2D（impulse / force で操作）

動かさない障害物・地形？
  → StaticBody2D

「触れたかどうか」だけ検知したい（アイテム・ゴールゾーン）？
  → Area2D（シグナルで通知）
```

| ノード型 | 使用例 | _physics_process で行うこと |
|---------|--------|---------------------------|
| CharacterBody2D | プレイヤー・敵 | velocity 設定 + move_and_slide() |
| RigidBody2D | 物理オブジェクト | apply_impulse() / apply_force() のみ |
| StaticBody2D | 地形・壁 | 何もしない（動かさない） |
| Area2D | アイテム・ゾーン | シグナル接続のみ |

---

## CollisionLayer / CollisionMask の設計

プロジェクト開始時に `Project Settings > Layer Names > 2D Physics` でレイヤー名を定義する。
デフォルトの Layer 1（unnamed）のまま実装しない。

### 推奨レイヤー設計（2Dアクション例）

| レイヤー番号 | 名前 | 用途 |
|------------|------|------|
| 1 | world | 地形・StaticBody |
| 2 | player | プレイヤー |
| 3 | enemy | 敵 |
| 4 | player_projectile | プレイヤーの弾 |
| 5 | enemy_projectile | 敵の弾 |
| 6 | item | アイテム・コレクタブル |
| 7 | trigger | ゴールゾーン・イベントトリガー |

### 設定の読み方

```
collision_layer: 自分がどのレイヤーに「存在するか」
collision_mask:  自分が「何と衝突を検知するか」
```

```gdscript
# 例: 敵（Layer 3）が world（1）と player（2）と衝突する設定
# Inspector で設定するのが原則。スクリプトからの変更は原則禁止。
# （テスト目的の場合のみスクリプトから変更可）
```

**禁止:** `collision_layer = 0` にして「全て無効化」するデバッグ設定を本番に残す

---

## CharacterBody2D の move_and_slide パターン

```gdscript
extends CharacterBody2D

const SPEED: float = 200.0
const GRAVITY: float = 980.0
const JUMP_VELOCITY: float = -400.0

func _physics_process(delta: float) -> void:
    # 1. 重力（is_on_floor() チェック後に加算）
    if not is_on_floor():
        velocity.y += GRAVITY * delta

    # 2. 水平入力
    var dir: float = Input.get_axis("move_left", "move_right")
    if dir != 0.0:
        velocity.x = dir * SPEED
    else:
        velocity.x = move_toward(velocity.x, 0.0, SPEED)  # 減速

    # 3. ジャンプ
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    # 4. 最後に必ず move_and_slide()
    move_and_slide()
```

**`move_toward()` を使う理由:** `velocity.x = 0.0` で即停止すると滑りがなく不自然。慣性は `move_toward` で表現する。

---

## Area2D シグナルの接続パターン

```gdscript
extends Area2D

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

# ✅ 型付きパラメータを明示する
func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        EventBus.sfx_play_requested.emit("item_pickup")
        queue_free()

func _on_body_exited(body: Node2D) -> void:
    pass
```

### ローカルシグナル vs EventBus の使い分け

| 状況 | 使うもの |
|------|---------|
| Area2D の判定結果を同じシーン内の親に伝える | ローカルシグナル（`signal picked_up`） |
| 判定結果をゲームロジック（Autoload）に伝える | EventBus |
| 複数のシーンが同じイベントを購読する | EventBus |

```gdscript
# ✅ ローカルシグナル（アイテムシーン内で完結）
class_name CollectibleItem
extends Area2D

signal picked_up(item_id: String)

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        picked_up.emit(item_id)
        queue_free()
```

---

## RigidBody2D の操作パターン

RigidBody2D の `position` を直接変えると物理エンジンとの同期が崩れる。

```gdscript
extends RigidBody2D

# ✅ impulse で一瞬の力を与える（ジャンプ・爆発）
func launch(direction: Vector2, force: float) -> void:
    apply_impulse(direction.normalized() * force)

# ✅ force で継続的な力を与える（推進力）
func _physics_process(_delta: float) -> void:
    if is_thrusting:
        apply_force(Vector2.UP * thrust_power)

# ❌ 禁止: position を直接変更
func teleport(pos: Vector2) -> void:
    position = pos  # 物理エンジンとの状態が壊れる
    # 正しくは: global_position = pos を _integrate_forces 内で使う
```

---

## 物理演算のパフォーマンス

```
□ 静的な地形には StaticBody2D を使う（RigidBody より軽い）
□ 画面外のオブジェクトは set_physics_process(false) で止める
□ コリジョンシェイプは単純な形状を優先（Rectangle > Capsule > ConvexPolygon > ConcavePolygon）
□ 精密な地形には CollisionPolygon2D ではなく TileMap のコリジョンを使う
```
