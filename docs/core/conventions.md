# Coding Conventions

## GDScript 型システム

### 全変数に型アノテーション必須

```gdscript
# ✅ 正しい書き方
var score: int = 0
var player_name: String = ""
var items: Array[ItemData] = []
var is_paused: bool = false

# ❌ 型アノテーションなし（禁止）
var score = 0
var items = []
```

### 関数シグネチャの完全型付け

```gdscript
# ✅ 引数・戻り値すべてに型を明示
func calculate_score(base: int, multiplier: float) -> int:
    return int(base * multiplier)

func get_items_by_type(type: String) -> Array[ItemData]:
    return items.filter(func(i: ItemData) -> bool: return i.type == type)

# ❌ 型なし（禁止）
func calculate_score(base, multiplier):
    return base * multiplier
```

### 強制キャストの禁止

```gdscript
# ✅ is チェックで型ガード
func handle_node(node: Node) -> void:
    if node is Player:
        var player: Player = node as Player
        # ここでは安全に使える
        player.take_damage(10)

# ❌ 確認なしの強制キャスト（禁止）
var player: Player = node as Player  # null の可能性がある
```

### Variant の過度な使用禁止

```gdscript
# ✅ 具体的な型を使う
var score: int = 0
var items: Array[ItemData] = []

# ❌ 全引数を Variant にする（禁止）
func process(data: Variant, callback: Variant) -> Variant:
    pass
```

#### Variant が許容されるケース（明示的な例外リスト）

以下の場合のみ `Variant` の使用を許可する。それ以外は具体的な型を使うこと。

| 状況 | 理由 | 例 |
|------|------|-----|
| `ConfigFile.get_value()` / `SaveManager.get_value()` の戻り値 | Godot API が Variant を返すため | `var v: Variant = config.get_value("s", "k", null)` |
| `EventBus.settings_changed(key, value)` のシグナルパラメータ | 設定値の型が string/float/bool と混在するため | `signal settings_changed(key: String, value: Variant)` |
| JSON パース結果 | JSON はスキーマなしで型が確定しないため | `var data: Variant = JSON.parse_string(text)` |
| `Node.get_meta()` / `Object.get()` など Godot 内部 API の戻り値 | APIが Variant を返す設計のため | `var meta: Variant = node.get_meta("key")` |

上記以外で Variant を使おうとしている場合は **実装を停止してユーザーに確認する**。

---

## ノード参照

### @onready を使う

```gdscript
# ✅ @onready で _ready() 前に参照を取得
@onready var health_bar: ProgressBar = $UI/HealthBar
@onready var player: CharacterBody2D = $Player

# ❌ get_node() のハードコードパス（禁止）
func _process(_delta: float) -> void:
    get_node("../UI/HealthBar").value = health  # 禁止
```

### @export で外部から設定可能にする

```gdscript
# ✅ インスペクターで設定可能・テスト時に注入可能
@export var speed: float = 200.0
@export var bullet_scene: PackedScene = null
@export var audio_manager: AudioManager = null
```

---

## シグナル

### 型付きシグナル

```gdscript
# ✅ パラメータに型を明示
signal player_died(final_score: int)
signal item_collected(item: ItemData)
signal health_changed(new_health: int, max_health: int)

# ❌ 型なしシグナル（禁止）
signal player_died
```

### 接続・切断のパターン

```gdscript
# ✅ _ready() で接続、_exit_tree() または Callable で切断
func _ready() -> void:
    EventBus.game_over.connect(_on_game_over)
    health_changed.connect(_update_health_bar)

func _exit_tree() -> void:
    EventBus.game_over.disconnect(_on_game_over)

# ✅ ラムダ接続（短い処理）
button.pressed.connect(func() -> void: SceneManager.go_to("res://scenes/ui/main_menu.tscn"))
```

---

## 定数・マジックナンバー

```gdscript
# ✅ 定数で名前をつける
const MAX_LIVES: int = 3
const GRAVITY: float = 980.0
const SAVE_VERSION: int = 1

# ❌ マジックナンバー直接記述（禁止）
if lives > 3:
    pass
velocity.y += 980.0 * delta
```

---

## ループ・コレクション

```gdscript
# ✅ 型付き配列 + ラムダ
var active_enemies: Array[Enemy] = enemies.filter(
    func(e: Enemy) -> bool: return e.is_alive()
)

var total_score: int = items.reduce(
    func(acc: int, item: ItemData) -> int: return acc + item.value,
    0
)

# ✅ for の型明示
for item: ItemData in inventory:
    process_item(item)

# ❌ 型なしループ変数（禁止）
for item in inventory:
    pass
```

---

## エラーハンドリング

```gdscript
# ✅ Error 型を確認する
var err: Error = config.load(path)
if err != OK:
    Logger.error("Load failed", {"path": path, "error": err})
    return false

# ✅ null チェック
var node: Node = get_node_or_null("PlayerNode")
if node == null:
    Logger.warn("Player node not found")
    return
```

---

## _process の使い方

```gdscript
# ✅ 軽量な更新のみ _process に書く
func _process(delta: float) -> void:
    _update_animation(delta)

# ✅ 重い処理はキャッシュまたはスレッド
func _ready() -> void:
    _cached_path = _calculate_path()  # 一度だけ計算

# ❌ _process 内でファイルI/O・複雑な検索（禁止）
func _process(_delta: float) -> void:
    config.load("user://save.cfg")  # 禁止：毎フレームI/O
```

---

## ログ規則

`print()` は本番コードで禁止。Logger Autoload を使う。

```gdscript
# ✅ Logger を使う
Logger.info("item_saved", {"id": item.id})
Logger.error("Save failed", {"error": err})
Logger.debug("raw_data", {"data": raw})  # デバッグビルドのみ出力

# ❌ 禁止
print("item saved")
```

---

## インポート順序（`class_name` と `extends` の位置）

```gdscript
# ✅ 正しい書き方
class_name PlayerController
extends CharacterBody2D

const SPEED: float = 200.0

@export var jump_force: float = 400.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

signal health_changed(new_health: int)

var health: int = 100
var _is_invincible: bool = false

func _ready() -> void:
    pass
```

**書き順（ファイル先頭から）:**
1. `class_name`（必要な場合）
2. `extends`
3. `const`（定数）
4. `@export var`（インスペクター変数）
5. `@onready var`（ノード参照）
6. `signal`（シグナル定義）
7. `var`（パブリック変数）
8. `var _`（プライベート変数）
9. `func _ready()`, `func _process()` 等のライフサイクル
10. パブリックメソッド
11. プライベートメソッド（`func _` プレフィックス）

---

## コメント規則

```gdscript
# ✅ WHY を書く（非自明な理由・制約）
const RETRY_LIMIT: int = 3  # App Store ガイドライン：無制限リトライは不可

# ❌ WHAT を書く（コードを読めば分かる）
# スコアを加算する
score += points
```

- `##` ドキュメンテーションコメントは公開APIのみ
- TODO はコードに残さず、タスク管理ツールに移す
