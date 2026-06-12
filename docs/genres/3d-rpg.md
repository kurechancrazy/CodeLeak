# 3D RPG / オープンワールド — ジャンルガイド

**次元:** 3D  
**genre-starters.md:** バンドル 19

---

## コアループ

広大なフィールドを探索し → NPC からクエストを受注 →
ダンジョン・ボスをクリア → 装備・レベルアップで強化 → 繰り返す。
**クエスト管理・日時システム・フィールドの非同期ロード**が技術的核心。

---

## シーン階層

```
GameWorld (Node3D)
├── WorldStream (Node)         — エリアの非同期ロード・アンロード制御
├── ActiveZone (Node3D)        — 現在ロード中のエリア群
│   └── Zone_Forest (Node3D)  — SubScene として個別ロード
│       ├── NavigationRegion3D
│       ├── EnemyGroup
│       └── NPCGroup
├── Player (CharacterBody3D)
│   ├── CameraArm (SpringArm3D)
│   │   └── Camera3D
│   ├── InteractZone (Area3D)
│   └── AnimationTree
├── WorldEnvironment
├── DirectionalLight3D (太陽)   — TimeManager.hour_changed で角度変更
└── HUD (CanvasLayer)
    ├── QuestTracker
    ├── MiniMap
    └── StatusBars
```

---

## 必須 Autoload

| Autoload | ファイル | 役割 |
|---------|---------|------|
| QuestManager | `autoloads/quest_manager.gd` | クエスト進行・達成条件・報酬配布 |
| TimeManager | `autoloads/time_manager.gd` | 日時・昼夜・季節 |
| DialogManager | `autoloads/dialog_manager.gd` | NPC 会話（2D JRPG と共通実装） |

---

## 主要実装パターン

### 昼夜サイクル（TimeManager 連動）

```gdscript
# WorldLighting.gd（DirectionalLight3D の制御）
func _ready() -> void:
    TimeManager.hour_changed.connect(_on_hour_changed)

func _on_hour_changed(hour: int) -> void:
    # 1 日 24 時間 → 太陽の回転角
    var sun_angle: float = (float(hour) / 24.0) * 360.0 - 90.0
    _sun_light.rotation_degrees.x = sun_angle
    _sun_light.visible = TimeManager.is_daytime()
```

### エリア非同期ロード

```gdscript
# WorldStream.gd
func load_zone(zone_path: String) -> void:
    if _loaded_zones.has(zone_path):
        return
    ResourceLoader.load_threaded_request(zone_path)
    _pending_zones.append(zone_path)

func _process(_delta: float) -> void:
    for zone_path: String in _pending_zones:
        if ResourceLoader.load_threaded_get_status(zone_path) == ResourceLoader.THREAD_LOAD_LOADED:
            var scene: PackedScene = ResourceLoader.load_threaded_get(zone_path)
            var zone: Node3D = scene.instantiate()
            active_zone.add_child(zone)
            _loaded_zones[zone_path] = zone
            _pending_zones.erase(zone_path)
```

### クエストシステム（データ駆動）

```gdscript
# QuestData.gd (Resource)
@export var id: String = ""
@export var title: String = ""
@export var objectives: Array[String] = []   # 達成条件の flag_id 一覧

# QuestManager.gd: FlagManager.get_flag() で達成条件をチェック
func check_completion(quest: QuestData) -> bool:
    return quest.objectives.all(func(obj: String) -> bool: return FlagManager.get_flag(obj))
```

---

## よくある地雷

- フィールド全体を 1 シーンにすると起動・編集が遅くなる → エリアを独立したシーンに分割してストリーミングロード
- NPC のスケジュール（昼は広場・夜は宿）を `_process` で毎フレームチェックすると重い → `TimeManager.hour_changed` シグナルで更新
- 非同期ロード中にロードしたシーンを `add_child` するとメインスレッド衝突 → `call_deferred("add_child", zone)`

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/3d-rpg.md` | このファイル |
| Autoload | `autoloads/quest_manager.gd`（作成した場合） | — |
| Autoload | `autoloads/time_manager.gd` | 農業シム・3D ホラーでも使用 |
| Autoload | `autoloads/dialog_manager.gd` | JRPG でも使用 |

```ini
; 農業シム・3D ホラーも使わない場合のみ削除
TimeManager="*res://autoloads/time_manager.gd"
; JRPG も使わない場合のみ削除
DialogManager="*res://autoloads/dialog_manager.gd"
```
