# Signals — シグナル設計・EventBus パターン

## シグナルの基本原則

- シグナルは「何が起きたか」を表す（過去形・名詞句）: `player_died`, `item_collected`
- シグナルは「何をしてほしいか」を表さない: `kill_player`, `collect_item` ← 禁止
- 受信側がどう反応するかはシグナルの関心事ではない

---

## シグナルの定義と接続

```gdscript
# ✅ 型付きシグナル定義
signal health_changed(new_health: int, max_health: int)
signal player_died(final_score: int)
signal item_collected(item: ItemData)

# ✅ _ready() で接続
func _ready() -> void:
    health_changed.connect(_on_health_changed)
    EventBus.game_over.connect(_on_game_over)

# ✅ ラムダ接続（短い処理のみ）
button.pressed.connect(func() -> void: EventBus.sfx_play_requested.emit("click"))

# ❌ 型なしシグナル（禁止）
signal player_died  # パラメータに型がない
```

---

## シグナルの命名規則

| パターン | 例 | 説明 |
|---------|-----|------|
| `[名詞]_[過去分詞]` | `player_died`, `item_collected` | 状態変化 |
| `[名詞]_changed` | `health_changed`, `score_updated` | 値の変化 |
| `[名詞]_[動詞]ed` | `door_opened`, `level_completed` | アクション完了 |
| `[動詞]_requested` | `save_requested`, `scene_change_requested` | リクエスト（EventBus用） |

---

## ローカルシグナル vs EventBus

### ローカルシグナル（シーン内・親子関係）

シーン内部・直接参照できる範囲で使う。

```gdscript
# player.gd（直接参照できる場合）
signal health_changed(hp: int, max_hp: int)

# game_world.gd
@onready var player: Player = $Player

func _ready() -> void:
    player.health_changed.connect(_on_player_health_changed)
```

### EventBus（Autoload 間・シーン跨ぎ）

直接参照できない場合・Autoload 間の通信に使う。

```gdscript
# どこからでも
EventBus.notification_requested.emit("アイテムを入手！", "success")

# HUD.gd
func _ready() -> void:
    EventBus.notification_requested.connect(_show_notification)
```

### 判断基準

```
同一シーン内の親子関係 → ローカルシグナル
異なるシーン・Autoload 間 → EventBus
UIが Autoload に通知 → EventBus
Autoload がUIに通知 → EventBus
```

---

## シグナルのメモリ管理

シーンが解放される前にシグナルを切断しないとエラーが発生する。

```gdscript
# ✅ EventBus 接続は _exit_tree() で切断
func _exit_tree() -> void:
    EventBus.game_over.disconnect(_on_game_over)

# ✅ 同一シーン内のシグナルは自動切断（シーン破棄時）
# → ローカルシグナルは _exit_tree() での切断不要

# ✅ 一度だけ受け取る場合は CONNECT_ONE_SHOT
some_signal.connect(_on_once, OBJECT_CONNECT_ONE_SHOT)
```

---

## シグナルチェーンの禁止

```gdscript
# ❌ 3段以上のシグナルチェーン（設計を見直す）
A.signal_x → B.do_something() → C.signal_y → D.do_something()

# ✅ EventBus を使って直接通信
A.signal_x → EventBus.event_happened → D.on_event_happened()
```
