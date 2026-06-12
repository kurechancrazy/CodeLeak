# Error Handling — エラー処理パターン

**対象:** Godot 4.4+ / GDScript 2.0

---

## Claude Code 実装停止チェックリスト

```
□ エラーを握り潰している（if err != OK: pass / return）
□ エラーメッセージをユーザーに見せずに無視している
□ セーブデータ読み込みエラーを処理せずにゲームを続行させようとしている
□ load() / preload() の失敗を考慮していない（存在しないパスを渡している）
□ エラー処理を後回しにして「とりあえず動く」状態で実装を進めている
```

---

## エラー処理の原則

| 原則 | 内容 |
|------|------|
| **Fail loud, recover gracefully** | エラーは必ずログに記録し、可能な限り回復策を実行する |
| **ユーザーには適切なフィードバック** | 技術的詳細は隠し、次のアクションを案内する |
| **握り潰し禁止** | `if err != OK: pass` は絶対禁止。必ず Logger.error() を呼ぶ |
| **境界でのみ検証** | 外部データ（ファイル・ネットワーク・ユーザー入力）の境界でのみ検証する |

---

## Godot の Error 型

```gdscript
# OK = 0（成功）
# ERR_FILE_NOT_FOUND = 7
# ERR_FILE_CANT_READ = 12
# ERR_FILE_CORRUPT = 26
# ERR_PARSE_ERROR = 43

var err: Error = config.load(path)
if err != OK:
    Logger.error("ファイル読み込み失敗", {"path": path, "error": err})
```

---

## セーブデータのエラー処理

セーブデータはユーザーが直接操作できるファイルのため、必ず破損を想定した処理を書く。

```gdscript
# autoloads/save_manager.gd

const SAVE_PATH: String = "user://save_data.cfg"
const BACKUP_PATH: String = "user://save_data.cfg.bak"

func load_game() -> void:
    # バックアップからリストアを先に試みる関数を呼ぶ
    if not FileAccess.file_exists(SAVE_PATH):
        Logger.info("セーブデータなし。デフォルト値で開始", {})
        _apply_defaults()
        return

    var err: Error = _save_config.load(SAVE_PATH)
    if err != OK:
        Logger.error("セーブデータ読み込み失敗", {"error": err})
        _try_restore_backup()
        return

    _migrate_if_needed()
    _apply_loaded_values()

func save_game() -> void:
    # 保存前に既存ファイルをバックアップ
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH)

    var err: Error = _save_config.save(SAVE_PATH)
    if err != OK:
        Logger.error("セーブデータ保存失敗", {"error": err})
        EventBus.notification_requested.emit("保存に失敗しました", "error")
        EventBus.save_completed.emit(false)
        return

    EventBus.save_completed.emit(true)

func _try_restore_backup() -> void:
    if not FileAccess.file_exists(BACKUP_PATH):
        Logger.warn("バックアップなし。デフォルト値で開始", {})
        _apply_defaults()
        EventBus.notification_requested.emit("セーブデータを読み込めませんでした", "warning")
        return

    var err: Error = _save_config.load(BACKUP_PATH)
    if err != OK:
        Logger.error("バックアップも読み込めません。データをリセット", {"error": err})
        _apply_defaults()
        EventBus.notification_requested.emit("セーブデータが破損しています。初期化しました", "error")
        return

    Logger.warn("バックアップから復元しました", {})
    EventBus.notification_requested.emit("バックアップから復元しました", "warning")
    _apply_loaded_values()
```

---

## リソース読み込みのエラー処理

```gdscript
# ✅ 存在確認してから load する
func _load_enemy_scene(type: String) -> PackedScene:
    var path: String = "res://scenes/enemies/%s.tscn" % type
    if not ResourceLoader.exists(path):
        Logger.error("敵シーンが存在しません", {"type": type, "path": path})
        return null
    return load(path) as PackedScene

# ✅ load 結果が null のケースも処理する
func _spawn_enemy(type: String) -> void:
    var scene: PackedScene = _load_enemy_scene(type)
    if scene == null:
        return  # すでに Logger.error が呼ばれている
    var enemy: Node = scene.instantiate()
    add_child(enemy)

# ❌ 禁止: 存在確認なし
func _spawn_enemy_wrong(type: String) -> void:
    var enemy: Node = load("res://scenes/enemies/%s.tscn" % type).instantiate()
    # → type が不正なら null.instantiate() でクラッシュ
```

---

## シーン遷移のエラー処理

```gdscript
# autoloads/scene_manager.gd

func go_to(path: String, transition: String = "fade") -> void:
    if _is_transitioning:
        Logger.warn("遷移中に go_to が呼ばれました", {"path": path})
        return

    if not ResourceLoader.exists(path):
        Logger.error("遷移先シーンが存在しません", {"path": path})
        EventBus.notification_requested.emit("画面の読み込みに失敗しました", "error")
        return

    _is_transitioning = true
    # 遷移処理...
```

---

## ユーザー向けエラー通知の分類

| エラー種別 | ユーザーへの表示 | Logger レベル |
|-----------|--------------|-------------|
| セーブ失敗 | 「保存に失敗しました。ストレージ容量を確認してください」 | error |
| セーブ破損 | 「セーブデータが破損しています。初期化しました」 | error |
| バックアップ復元 | 「前回のデータから復元しました」 | warn |
| アセット不存在（開発中） | HUD には表示しない（開発者向けログのみ） | error |
| 設定値異常 | 「設定をリセットしました」 | warn |

```gdscript
# EventBus.notification_requested の type 別表示方針
# "info"    → 青いトースト通知（自動消去）
# "warning" → 黄色いトースト通知（自動消去）
# "error"   → 赤いモーダルダイアログ（ユーザーの確認が必要）
```

---

## GDScript の型チェックエラー防止

```gdscript
# ✅ as でキャストする前に is でチェック
func _on_body_entered(body: Node) -> void:
    if body is Player:
        var player: Player = body as Player
        player.take_damage(10)

# ❌ 禁止: チェックなしの強制キャスト
func _on_body_entered_wrong(body: Node) -> void:
    var player: Player = body as Player  # Player でなければ null になる（クラッシュしないが意図しない動作）
    player.take_damage(10)  # null.take_damage() でクラッシュ

# ✅ null になりうる変数は必ずチェック
func update_target(target: Node) -> void:
    if target == null or not is_instance_valid(target):
        Logger.warn("update_target: 無効なターゲット", {})
        return
    # 処理
```

---

## エラー処理のアンチパターン

```gdscript
# ❌ 握り潰し
var err: Error = config.load(path)
if err != OK:
    pass  # 絶対禁止

# ❌ エラーを無視して処理続行
var data: Dictionary = JSON.parse_string(raw)
# → parse_string は失敗時に null を返す。チェック必須

# ❌ ユーザーに技術的エラーをそのまま表示
EventBus.notification_requested.emit(str(err), "error")
# → "ERR_FILE_NOT_FOUND" ではなく「ファイルが見つかりません」と表示する

# ❌ エラー後のリカバリーなしに処理続行
func load_config() -> void:
    if _save_config.load(SAVE_PATH) != OK:
        Logger.error("Failed", {})
        return  # ← defaults を適用せずに return している
```
