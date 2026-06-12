# Game Responsiveness — 入力レスポンス・もっさり防止

「もっさり」の正体はほぼ **入力遅延** か **フレームドロップ** のどちらかだ。
このドキュメントに書かれていることを守れば、体感的にキビキビ動くゲームを維持できる。

---

## 【禁止】これをやると必ずもっさりになる

### 入力系

| 禁止パターン | なぜ悪いか | 代替 |
|------------|----------|------|
| `_process` の `Input.is_action_just_pressed()` だけで入力受付 | 最大1フレーム見落す。高速連打が消える | `_input()` でフラグを立て `_physics_process` で処理 |
| Tween / `await` 中に入力受付を止める | アニメーション終了まで何も反応しない | `_is_animating` フラグで「先行入力キュー」を保持する |
| ジャンプ・攻撃のバッファを実装しない | タイミングがシビアすぎて理不尽に感じる | コヨーテタイム・ジャンプバッファを必ず実装する |

### フレーム系

| 禁止パターン | なぜ悪いか | 代替 |
|------------|----------|------|
| `_process` 内で `load()` / `preload` を実行 | ロード中フレームが落ちる | `_ready()` または非同期ロード（`ResourceLoader.load_threaded_request()`） |
| `_process` 内で `instantiate()` / `queue_free()` を頻繁に呼ぶ | GC スパイクでフレームドロップ | `ObjectPool`（`scripts/utils/object_pool.gd`）を使う |
| `get_node("path")` / `find_child()` を `_process` で毎フレーム呼ぶ | ノードツリーを毎フレーム走査する | `@onready var _foo: Node = $Path` で起動時に固定する |
| 物理移動を `_process` に書く | フレームレート依存で挙動が変わる | 物理演算は必ず `_physics_process` に書く |
| 必要のないノードで `_process` を動かす | CPU サイクルの無駄 | 不要なら `set_process(false)` / `set_physics_process(false)` で止める |

---

## 入力レスポンスの実装パターン

### 基本：フラグ受付 → physics で処理

```gdscript
# ❌ 悪い例: _process でポーリングのみ
func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("jump"):
        _jump()

# ✅ 良い例: _input でフラグを立て _physics_process で処理
var _jump_requested: bool = false

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("jump"):
        _jump_requested = true

func _physics_process(_delta: float) -> void:
    if _jump_requested and _can_jump():
        _jump_requested = false
        _do_jump()
    elif _jump_requested:
        # ジャンプバッファとして一定フレーム保持（後述）
        pass
```

### ジャンプバッファ + コヨーテタイム（プラットフォーマー必須）

```gdscript
const COYOTE_TIME: float = 0.12      # 崖から離れた後もジャンプ受付
const JUMP_BUFFER_TIME: float = 0.10 # 着地前の先行入力を受け付ける

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("jump"):
        _jump_buffer_timer = JUMP_BUFFER_TIME

func _physics_process(delta: float) -> void:
    if is_on_floor():
        _coyote_timer = COYOTE_TIME
    else:
        _coyote_timer = maxf(_coyote_timer - delta, 0.0)

    _jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)

    if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
        _jump_buffer_timer = 0.0
        _coyote_timer = 0.0
        _do_jump()
```

### アニメーション中の先行入力キュー

```gdscript
# 攻撃アニメーション中に次の入力を「予約」して、終了直後に実行する
var _queued_action: String = ""
var _is_attacking: bool = false

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("attack"):
        if _is_attacking:
            _queued_action = "attack"   # 先行予約
        else:
            _start_attack()

func _on_attack_animation_finished() -> void:
    _is_attacking = false
    if _queued_action == "attack":
        _queued_action = ""
        _start_attack()
```

---

## フレームレートとタイミング設定

### Physics Ticks の設定（project.godot）

```ini
[physics]
common/physics_ticks_per_second=60   ; _physics_process の呼び出し頻度（デフォルト60）

[application]
config/use_custom_user_dir=false
```

60Hz 以外にする場合は **全ての物理ロジックを `delta` で正規化**していることを確認すること。

### 上限 FPS を設定する

```gdscript
# autoloads/game_manager.gd の _ready() に追加
func _ready() -> void:
    Engine.max_fps = 60   # モバイル向けや省電力モードが必要なければ 0（無制限）
    # ただし無制限はバッテリーを消耗するため、ターゲット FPS に合わせて設定する
```

---

## オーディオ遅延の削減

BGM・SE の発火タイミングが映像と合わないと「もっさり感」に直結する。

```ini
; project.godot — audio バッファを削減する
[audio]
driver/output_latency=15   ; デフォルト 50ms → 15ms（低スペック端末では増やす）
```

```gdscript
# ❌ 悪い例: await で再生完了を待ってから次の処理
await AudioManager.play_se("hit")

# ✅ 良い例: 再生は「発火して忘れる」形で行う。AudioManager は非同期
AudioManager.play_se("hit")
_continue_logic()
```

---

## ObjectPool でGCスパイクを防ぐ

弾・コイン・エフェクトなど大量に生成/破棄するオブジェクトは必ず ObjectPool を使う。

```gdscript
# ❌ 悪い例: 毎フレーム instantiate（GCスパイクの温床）
func _shoot() -> void:
    var bullet: Node2D = BulletScene.instantiate()
    add_child(bullet)

# ✅ 良い例: ObjectPool から取り出す
@onready var _bullet_pool: ObjectPool = $BulletPool

func _shoot() -> void:
    var bullet: Node2D = _bullet_pool.get_instance() as Node2D
    bullet.global_position = _muzzle.global_position
    bullet.set_direction(_aim_direction)
```

詳細 → `scripts/utils/object_pool.gd`

---

## 不要な更新処理を止める

```gdscript
# UIノードや非アクティブな敵は処理を止める
func deactivate() -> void:
    set_process(false)
    set_physics_process(false)
    set_process_input(false)

func activate() -> void:
    set_process(true)
    set_physics_process(true)
    set_process_input(true)

# 画面外の敵: VisibilityNotifier2D / 3D を使って自動停止
# VisibleOnScreenNotifier2D.screen_exited シグナルで deactivate() を呼ぶ
```

---

## 実装完了チェックリスト

機能を実装するたびにこのリストを確認すること。

```
□ 入力を _input() で受け付け、_physics_process で処理しているか
□ ジャンプ・攻撃にバッファ（コヨーテタイム・先行入力）を実装したか
□ _process / _physics_process 内に load() / instantiate() が混入していないか
□ get_node() / find_child() を @onready に置き換えたか
□ 大量生成オブジェクト（弾・コイン・エフェクト）に ObjectPool を使っているか
□ アニメーション中も入力を受け付け、先行予約キューを実装したか
□ 不要なノードの _process を set_process(false) で止めているか
□ AudioManager.play_se() を await せずに呼んでいるか
```
