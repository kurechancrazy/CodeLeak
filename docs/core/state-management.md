# State Management — Autoload パターン・EventBus

## 状態の分類と置き場所

```
UIの一時状態（アニメーション中・入力中の値）
  → シーンスクリプトの var

シーンをまたいで共有するゲーム状態
  → GameManager Autoload

デバイス再起動後も保持する状態
  → SaveManager 経由で ConfigFile に保存

Autoload 間のイベント通知
  → EventBus シグナル
```

---

## Autoload のパターン

### 状態 + アクションの分離

```gdscript
# autoloads/inventory_manager.gd（新規 Autoload を追加する場合の参考）
extends Node

# State（パブリック読み取り）
var items: Array[ItemData] = []
var _max_capacity: int = 20  # プライベート（変更は内部のみ）

# Actions（パブリックAPI・動詞始まり）
func add_item(item: ItemData) -> bool:
    if items.size() >= _max_capacity:
        EventBus.notification_requested.emit("インベントリが満杯です", "warn")
        return false
    items.append(item)
    EventBus.item_added.emit(item)
    return true

func remove_item(item_id: String) -> void:
    var idx: int = _find_index(item_id)
    if idx == -1:
        Logger.warn("Item not found", {"id": item_id})
        return
    items.remove_at(idx)
    EventBus.item_removed.emit(item_id)

func reset() -> void:
    items.clear()

# Private
func _find_index(item_id: String) -> int:
    for i: int in range(items.size()):
        if items[i].id == item_id:
            return i
    return -1
```

### EventBus 接続の定型パターン

```gdscript
func _ready() -> void:
    EventBus.save_requested.connect(_on_save_requested)
    EventBus.load_requested.connect(_on_load_requested)

func _exit_tree() -> void:
    # EventBus への接続は _exit_tree() で明示的に切断
    EventBus.save_requested.disconnect(_on_save_requested)
    EventBus.load_requested.disconnect(_on_load_requested)
```

---

## EventBus への新しいシグナル追加

新しいシグナルが必要になった場合は `autoloads/event_bus.gd` に追加する。

```gdscript
# event_bus.gd に追加
signal inventory_changed(item_count: int)
signal item_added(item: ItemData)
signal item_removed(item_id: String)
```

**ルール:**
- シグナル名は `snake_case`（`item_added`, `game_over` 等）
- パラメータには型を必ず明示する
- 追加したシグナルは `docs/core/state-management.md` のシグナル一覧を更新する

#### シグナル命名パターン（`docs/ui/signals.md` より）

| パターン | 例 | 使う状況 |
|---------|-----|---------|
| `[名詞]_[過去分詞]` | `player_died`, `item_collected` | 状態変化・完了 |
| `[名詞]_changed` | `health_changed`, `score_updated` | 値の変化通知 |
| `[名詞]_[動詞]ed` | `door_opened`, `level_completed` | アクション完了 |
| `[動詞]_requested` | `save_requested`, `bgm_change_requested` | 処理依頼（EventBus 専用） |

シグナルは「何が起きたか」を表す過去形・名詞句にする。「何をしてほしいか」（`kill_player`, `do_save`）は禁止。

---

## EventBus シグナル一覧

（テンプレートの初期シグナル。機能追加時はここに追記する）

| シグナル | パラメータ | 発行者 | 購読者 |
|---------|----------|--------|--------|
| `game_started` | なし | ゲームシーン | GameManager |
| `game_paused(is_paused)` | `bool` | UIシーン | GameManager |
| `game_over(score)` | `int` | ゲームシーン | GameManager |
| `scene_change_requested(path, transition)` | `String, String` | UIシーン | SceneManager |
| `scene_loaded(path)` | `String` | SceneManager | UIシーン |
| `save_requested` | なし | GameManager | SaveManager |
| `load_requested` | なし | main.gd | SaveManager |
| `save_completed(success)` | `bool` | SaveManager | UIシーン |
| `notification_requested(message, type)` | `String, String` | 各Autoload | UIシーン（HUD） |
| `bgm_change_requested(track)` | `String` | GameManager | AudioManager |
| `sfx_play_requested(sound)` | `String` | 各シーン | AudioManager |
| `settings_changed(key, value)` | `String, Variant` | GameManager | AudioManager 等 |

---

## 禁止パターン

```gdscript
# ❌ Autoload が別 Autoload を直接 call()（循環依存）
class_name SaveManager
func save_game() -> void:
    AudioManager.play_sfx("save_jingle")  # 禁止！

# ✅ EventBus 経由で通知（依存なし）
func save_game() -> void:
    EventBus.save_completed.emit(true)
    EventBus.sfx_play_requested.emit("save_jingle")  # AudioManager が受け取る
```
