# メトロイドヴァニア — ジャンルガイド

**次元:** 2D  
**genre-starters.md:** バンドル 6

---

## コアループ

探索 → 強化アビリティ入手 → 以前行けなかったエリアへ引き返す → 繰り返す。
**マップ状態（扉・破壊壁・入手済みアイテム）の永続化**がジャンルの核心。

---

## シーン階層

```
World (Node2D)
├── MapStateManager (Node) — 現セッションの部屋状態を管理
├── RoomGroup (Node2D)     — 現在ロード中の部屋
│   ├── Room_A01 (Node2D)
│   │   ├── TileMapLayer
│   │   ├── Breakable_Wall_01 (Area2D)
│   │   ├── Door_East (Area2D)   — 次の部屋へのトランジション
│   │   └── EnemyGroup
│   └── Room_A02 (Node2D)        — 隣接部屋（プリロード推奨）
├── Player (CharacterBody2D)
└── HUD (CanvasLayer)
    ├── MiniMap
    ├── HPBar
    └── AbilityIcons
```

---

## 必須 Autoload

| Autoload | ファイル | 役割 |
|---------|---------|------|
| MapStateManager | `autoloads/map_state_manager.gd` | 部屋の解放・壁の破壊・扉状態の永続化 |
| ProgressManager | `autoloads/progress_manager.gd` | アビリティ解放・収集率管理 |
| SaveManager | コア | セーブポイント経由の全体セーブ |

---

## 主要実装パターン

### 部屋状態の永続化（MapStateManager）

```gdscript
# MapStateManager がセーブデータに保存する構造
# {room_id: {breakable_ids_destroyed: [...], doors_opened: [...]}}

func mark_breakable_destroyed(room_id: String, obj_id: String) -> void:
    var room: Dictionary = _room_states.get(room_id, {})
    var destroyed: Array = room.get("breakable_ids_destroyed", [])
    if not destroyed.has(obj_id):
        destroyed.append(obj_id)
    room["breakable_ids_destroyed"] = destroyed
    _room_states[room_id] = room
```

部屋ロード時に `MapStateManager.get_destroyed_ids(room_id)` を参照して
破壊済みの `Breakable` を `queue_free()` する。

### アビリティゲート

扉・破壊壁は Autoload 側ではなくシーン側が条件チェックを持つ。

```gdscript
# BreakableWall.gd
@export var required_ability: String = "dash"

func _ready() -> void:
    if ProgressManager.is_unlocked(required_ability):
        queue_free()   # すでに取得済みならスポーン時に消す
```

### ルーム遷移（シームレス風）

プレイヤーが `Door_East`（Area2D）に触れたら `SceneManager` でなく
現在 World 内の部屋ノードを差し替える（部屋単位ロード）。
World シーンは維持したままにすることでミニマップ・HUD をリセットしない。

---

## よくある地雷

- 部屋状態をシーンノードに持たせると遷移時に消える → MapStateManager（Autoload）に持たせる
- アビリティ取得後の「引き返し導線」を未設計のまま実装すると詰む → 設計段階でマップグラフを引く
- `queue_free()` した部屋の参照が残るとメモリリーク → 遷移後に `prev_room.queue_free()` を確実に呼ぶ
- ミニマップの未探索・探索済みの状態は部屋状態と同じ仕組みで管理できる

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/metroidvania.md` | このファイル |
| Autoload | `autoloads/map_state_manager.gd` | — |
| テスト | `tests/unit/test_map_state_manager.gd`（作成した場合） | — |
| 共通 | `autoloads/progress_manager.gd` | 他ジャンルでも使用 |

```ini
; project.godot [autoload] から削除
MapStateManager="*res://autoloads/map_state_manager.gd"
```
