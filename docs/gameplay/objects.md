# Objects — ノード動的生成・破棄パターン

**対象:** Godot 4.4+ / GDScript 2.0

---

## Claude Code 実装停止チェックリスト

```
□ _process ループ内で Node.new() や instantiate() を毎フレーム呼ぼうとしている
□ queue_free() を Tween 実行中のノードに即座に呼ぼうとしている
□ 10体以上の同種オブジェクトを毎秒以上のペースで生成・破棄しようとしている
□ シーン外のノードに対して queue_free() を呼ぼうとしている
```

---

## preload vs load の選択基準

```
起動時に確実に使うリソース（プレイヤー・UI）→ preload
ゲーム中に条件次第で使うリソース（敵の種類・ステージ）→ load
サイズが大きく起動を遅らせたくないリソース → load + ResourceLoader.load_threaded_request()
```

```gdscript
# ✅ preload: コンパイル時に解決される。起動時ロード。
const BULLET_SCENE: PackedScene = preload("res://scenes/gameplay/bullet.tscn")

# ✅ load: ランタイムで解決される。初回呼び出し時にロード。
func _spawn_enemy(type: String) -> void:
    var path: String = "res://scenes/enemies/%s.tscn" % type
    if not ResourceLoader.exists(path):
        Logger.error("Enemy scene not found", {"type": type})
        return
    var scene: PackedScene = load(path)
    var enemy: Node = scene.instantiate()
    add_child(enemy)
```

**禁止:** `preload` を条件分岐内や関数内で使う → 常にコンパイル時評価されるためファイルが存在しないとエラーになる

---

## instantiate + add_child の正しい手順

```gdscript
# ✅ 正しい手順
func spawn_bullet(spawn_pos: Vector2, direction: Vector2) -> void:
    var bullet: Bullet = BULLET_SCENE.instantiate()
    # 1. add_child する前にプロパティをセット
    bullet.direction = direction
    bullet.global_position = spawn_pos
    # 2. add_child でシーンツリーに追加（_ready() が呼ばれる）
    add_child(bullet)

# ❌ 禁止: add_child 後にプロパティをセットする（_ready() が先に動く）
func spawn_bullet_wrong(spawn_pos: Vector2) -> void:
    var bullet: Bullet = BULLET_SCENE.instantiate()
    add_child(bullet)
    bullet.global_position = spawn_pos  # _ready() 内の初期化と競合する可能性
```

---

## queue_free の安全な使い方

### 基本ルール

```gdscript
# ✅ queue_free(): 現フレームの処理が終わった後に削除される（安全）
func die() -> void:
    queue_free()

# ❌ 禁止: free(): 即時削除。シグナルが接続中だとエラーになる
func die_wrong() -> void:
    free()  # 他のノードがシグナルを待っている場合にクラッシュ
```

### Tween 実行中の削除

```gdscript
# ✅ Tween 完了後に queue_free する
func fade_out_and_die() -> void:
    var tween: Tween = create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.3)
    tween.tween_callback(queue_free)  # Tween 完了後に queue_free

# ❌ 禁止: Tween 実行中に外部から queue_free を呼ぶ
# → Tween がすでに削除されたノードを操作してエラーになる
```

### シグナル接続中の削除

**切断が必要かどうかの判断基準:**

```
接続先が Autoload（EventBus 等）→ _exit_tree() で明示的に disconnect() する
接続先が同一シーン内のノード → 切断不要（ノード破棄時に自動切断される）
```

Godot 4 では同一シーン内のノード間の接続は、接続先ノードの `queue_free` 時に自動切断される。
ただし **EventBus は Autoload（シーン外のシングルトン）なので自動切断されない**。
`_exit_tree()` で手動切断しないとテスト時・ホットリロード時にシグナルが二重接続される。

```gdscript
# ✅ EventBus（Autoload）のシグナルは必ず _exit_tree() で切断
func _ready() -> void:
    EventBus.game_over.connect(_on_game_over)

func _exit_tree() -> void:
    EventBus.game_over.disconnect(_on_game_over)

# ✅ 同じシーン内のノードは切断不要（ノード破棄で自動切断）
func _ready() -> void:
    button.pressed.connect(_on_button_pressed)
    # button はこのシーンの子 → queue_free 時に自動切断

# ❌ 判断の誤り例: Autoload シグナルを切断し忘れる
func _exit_tree() -> void:
    pass  # EventBus.game_over が接続したままになる
```

---

## ObjectPool パターン（大量生成が必要な場合）

**目安: 毎秒 10 個以上を生成・破棄する場合にプール化を検討する。**

```gdscript
# scripts/utils/object_pool.gd
class_name ObjectPool
extends RefCounted

var _scene: PackedScene
var _pool: Array[Node] = []
var _parent: Node

func _init(scene: PackedScene, size: int, parent: Node) -> void:
    _scene = scene
    _parent = parent
    for i: int in range(size):
        var obj: Node = scene.instantiate()
        obj.visible = false
        parent.add_child(obj)
        _pool.append(obj)

func acquire() -> Node:
    for obj: Node in _pool:
        if not obj.visible:
            obj.visible = true
            return obj
    # プール不足: 警告を出して新規生成（プールサイズを見直す）
    Logger.warn("ObjectPool exhausted", {"scene": _scene.resource_path})
    var new_obj: Node = _scene.instantiate()
    _parent.add_child(new_obj)
    _pool.append(new_obj)
    return new_obj

func release(obj: Node) -> void:
    obj.visible = false
    # 位置・状態をリセット
    if obj.has_method("reset"):
        obj.reset()
```

**プールを管理する場所:** 生成元のシーンか、それを管理する Autoload（GameManager など）。
「どのシーンでも使う」ならオブジェクト専用の Manager Autoload を作ることを検討する。

---

## ノード生成先の判断基準

```
生成物がシーンローカルで管理される（弾・エフェクト）→ 現在のシーンの子として add_child
シーン遷移後も存続する必要がある → Autoload の子として add_child
シーン遷移時に破棄したい（地形・敵）→ WorldRoot シーンの子として add_child
```

```gdscript
# ✅ 弾: 現在のシーンに追加（シーン遷移時に一緒に消える）
func _fire() -> void:
    var bullet: Bullet = BULLET_SCENE.instantiate()
    get_tree().current_scene.add_child(bullet)

# ❌ 禁止: get_parent() を3段以上辿って生成先を探す
func _fire_wrong() -> void:
    var bullet: Bullet = BULLET_SCENE.instantiate()
    get_parent().get_parent().get_parent().add_child(bullet)
```
