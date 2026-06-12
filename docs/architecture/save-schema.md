# Save Schema — セーブデータ設計ガイド

**タイミング:** 最初のゲームプレイシーンを実装する前に必ず設計する。
後からフィールドを追加する場合はバージョンを上げてマイグレーションを実装する。

---

## セーブフィールド定義テンプレート

ゲーム開始前にこの表を埋めること。空欄のままでは実装を始めない。

| section | key | 型 | デフォルト値 | 保存タイミング | 説明 |
|---------|-----|----|------------|-------------|------|
| `meta` | `save_version` | `int` | `1` | 常に | スキーマバージョン |
| `meta` | `saved_at` | `String` | `""` | 常に | 保存日時 |
| `meta` | `play_time` | `float` | `0.0` | 常に | 累積プレイ時間（秒） |
| `player` | `high_score` | `int` | `0` | ゲームオーバー時 | ハイスコア |
| *(追加)* | | | | | |

**ゲームジャンル別の追加フィールド例:**

| ジャンル | section | key | 型 | 説明 |
|---------|---------|-----|----|------|
| アクション | `player` | `stage_unlocked` | `int` | 解放済み最大ステージ番号 |
| RPG | `player` | `level` | `int` | プレイヤーレベル |
| RPG | `player` | `exp` | `int` | 現在経験値 |
| RPG | `inventory` | `items` | `String`（JSON） | アイテムリスト |
| パズル | `progress` | `stars_stage_{n}` | `int` | 各ステージの星評価（0〜3） |
| ノベル | `story` | `flags` | `String`（JSON） | 選択肢フラグ辞書 |
| ノベル | `story` | `chapter` | `int` | 進行済み章 |

---

## バージョン管理ルール

### SAVE_VERSION の increment 条件

| 変更の種類 | バージョン変更 | 理由 |
|-----------|-------------|------|
| 新しいフィールドを追加（デフォルト値で補完可能） | **マイナー扱い**（バージョン据え置きでも可） | get_value のデフォルト引数で対応 |
| フィールドの型を変更 | **必須 increment** | 古いデータが壊れる |
| フィールドを削除 | **必須 increment** | 古いセーブで余分なデータが残る |
| section の名前変更 | **必須 increment** | 古いデータを読めなくなる |

### マイグレーション実装パターン

```gdscript
# autoloads/save_manager.gd
const CURRENT_SAVE_VERSION: int = 2

func load_game() -> void:
    var err: Error = _save_config.load(SAVE_PATH)
    if err != OK:
        Logger.info("No save file found, using defaults")
        return
    _migrate_if_needed()
    GameManager.high_score = _save_config.get_value("player", "high_score", 0)

func _migrate_if_needed() -> void:
    var version: int = _save_config.get_value("meta", "save_version", 1)
    if version < CURRENT_SAVE_VERSION:
        Logger.info("Migrating save", {"from": version, "to": CURRENT_SAVE_VERSION})
        _migrate(version)

func _migrate(from_version: int) -> void:
    # バージョンごとに順番に適用する（スキップ不可）
    if from_version < 2:
        _migrate_v1_to_v2()
    # if from_version < 3:
    #     _migrate_v2_to_v3()
    _save_config.set_value("meta", "save_version", CURRENT_SAVE_VERSION)
    _save_config.save(SAVE_PATH)

func _migrate_v1_to_v2() -> void:
    # 例: v1 では "player/score" だったが v2 で "player/high_score" に rename
    var old_score: int = _save_config.get_value("player", "score", 0)
    _save_config.set_value("player", "high_score", old_score)
    _save_config.erase_section_key("player", "score")
    Logger.info("Migrated v1 → v2: score → high_score")
```

---

## GameSettings の型安全な定義

### 現状の問題点

```gdscript
# ❌ 現状: Dictionary は型安全でない
var settings: Dictionary = {
    "master_volume": 1.0,
    "bgm_volume": 0.8,
    "sfx_volume": 1.0,
    "fullscreen": false,
    "language": "ja",
}
# → "bgm_volum" のようなタイプミスが実行時エラーになる
```

### 推奨: class_name GameSettings extends Resource

```gdscript
# resources/data/game_settings.gd
class_name GameSettings
extends Resource

@export var master_volume: float = 1.0
@export var bgm_volume: float = 0.8
@export var sfx_volume: float = 1.0
@export var fullscreen: bool = false
@export var language: String = "ja"

func to_dict() -> Dictionary:
    return {
        "master_volume": master_volume,
        "bgm_volume": bgm_volume,
        "sfx_volume": sfx_volume,
        "fullscreen": fullscreen,
        "language": language,
    }

static func from_dict(data: Dictionary) -> GameSettings:
    var s: GameSettings = GameSettings.new()
    s.master_volume = data.get("master_volume", 1.0)
    s.bgm_volume = data.get("bgm_volume", 0.8)
    s.sfx_volume = data.get("sfx_volume", 1.0)
    s.fullscreen = data.get("fullscreen", false)
    s.language = data.get("language", "ja")
    return s
```

```gdscript
# autoloads/game_manager.gd（移行後）
var settings: GameSettings = GameSettings.new()

func update_setting_volume(bgm: float, sfx: float, master: float) -> void:
    settings.bgm_volume = bgm    # ✅ 型安全
    settings.sfx_volume = sfx
    settings.master_volume = master
    EventBus.settings_changed.emit("bgm_volume", bgm)
```

**移行タイミング:** ゲーム設定画面を実装する前（初期段階）に行う。
後から移行すると全 Autoload・シーンの settings 参照を修正する必要がある。

---

## セーブデータの分離方針

現状の SaveManager は `save_data.cfg`（ゲームデータ）と `settings.cfg`（設定）を分離している。
以下の方針で追加のセーブファイルを決定する。

| データ種別 | ファイル | 理由 |
|-----------|---------|------|
| ゲーム進行（スコア・レベル・インベントリ） | `user://save_data.cfg` | リセット可能・複数スロット候補 |
| アプリ設定（音量・言語・解像度） | `user://settings.cfg` | リセットしない・デバイス固有 |
| 機密データ（購入状態・ライセンス） | `user://secure_data.dat` | 暗号化必須（`docs/data/security.md` 参照） |

**複数セーブスロット対応が必要な場合:**
```gdscript
# SAVE_PATH を動的に変更する（SaveManager.SAVE_PATH は var なのでテスト同様に注入可能）
func load_slot(slot_number: int) -> void:
    SaveManager.SAVE_PATH = "user://save_slot_%d.cfg" % slot_number
    SaveManager.load_game()
```
