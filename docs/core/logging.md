# Logging — Logger Autoload の使い方

**実装:** `autoloads/logger.gd`

`print()` は本番コードで禁止。全てのログ出力は Logger を使う。

---

## API リファレンス

```gdscript
Logger.debug(message: String, context: Dictionary = {}) -> void
Logger.info(message: String, context: Dictionary = {})  -> void
Logger.warn(message: String, context: Dictionary = {})  -> void
Logger.error(message: String, context: Dictionary = {}) -> void
```

**`context`** は任意の補足情報を Dictionary で渡す。ログ行に `| {key: value}` として追記される。

---

## ログレベルの使い分け

| レベル | メソッド | 使う状況 | 出力先 |
|-------|---------|---------|--------|
| DEBUG | `Logger.debug()` | 開発中の詳細トレース。本番には不要な情報 | デバッグビルドのみ `print()` |
| INFO | `Logger.info()` | 正常な処理フローの記録（シーン遷移・セーブ完了） | デバッグビルドのみ `print()` |
| WARN | `Logger.warn()` | 異常ではないが注意が必要な状態（未知の設定キー・SFXプール不足） | `push_warning()` |
| ERROR | `Logger.error()` | 処理の失敗・回復できない異常（ファイルI/O失敗・シーンが見つからない） | `push_error()` |

```
迷ったら:
  処理が続行できる → warn
  処理が失敗した → error
  正常完了の記録 → info
  開発中だけ見たい → debug
```

---

## 使用例

```gdscript
# ✅ INFO: 正常フローの記録
func go_to(scene_path: String, transition: String = TRANSITION_FADE) -> void:
    Logger.info("SceneManager.go_to", {"to": scene_path, "transition": transition})

# ✅ WARN: 処理は続くが注意が必要
func update_setting(key: String, value: Variant) -> void:
    if not settings.has(key):
        Logger.warn("Unknown setting key", {"key": key})
        return

# ✅ ERROR: 処理が失敗した
func save_game() -> void:
    var err: Error = _save_config.save(SAVE_PATH)
    if err != OK:
        Logger.error("Save failed", {"error": err, "path": SAVE_PATH})

# ✅ DEBUG: 開発中のみ必要な詳細情報
func _on_physics_update(delta: float) -> void:
    Logger.debug("physics", {"velocity": velocity, "delta": delta})

# ❌ 禁止
print("scene changed")
print_debug("velocity: ", velocity)
```

---

## ログ出力の条件

| ビルド種別 | DEBUG | INFO | WARN | ERROR |
|-----------|-------|------|------|-------|
| デバッグビルド（エディタ） | ✅ print | ✅ print | ✅ push_warning | ✅ push_error |
| リリースビルド（エクスポート） | ❌ 出力なし | ❌ 出力なし | ✅ push_warning | ✅ push_error |

リリースビルドでは DEBUG / INFO は出力されない。パフォーマンスに影響するログは DEBUG レベルで書くこと。

---

## ファイルへのログ出力（任意）

`Logger._log_to_file = true` に設定するとファイルにも書き出す（デフォルトは無効）。
出力先: `user://logs/game.log`

テスト時はファイルへの書き出しを有効にしないこと（テスト実行速度が低下する）。
