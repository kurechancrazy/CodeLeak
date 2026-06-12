# Performance — パフォーマンス基準・プロファイリング

## パフォーマンス基準

| 指標 | 基準 |
|------|------|
| フレームレート（PC） | 60fps 維持 |
| フレームレート（モバイル） | 30fps 以上 |
| 起動時間 | 3秒以内 |
| シーン遷移 | 500ms以内 |
| メモリ使用量（モバイル） | 256MB以下 |

---

## プロファイリング

```bash
# Godot のプロファイラーを使う（デバッグ実行時に利用可能）
# エディタ → デバッガー → プロファイラー → 記録開始

# コマンドラインでのパフォーマンス計測
godot --debug
```

```gdscript
# ✅ スクリプトからパフォーマンスを計測
func _process(_delta: float) -> void:
    if OS.is_debug_build():
        var fps: float = Engine.get_frames_per_second()
        var static_mem: int = OS.get_static_memory_usage() / 1024 / 1024
        if fps < 30.0:
            Logger.warn("Low FPS", {"fps": fps, "memory_mb": static_mem})
```

---

## オブジェクトプール

大量の同種オブジェクト（弾・コイン・パーティクル）は毎回生成・破棄せずプールを使う。

```gdscript
# scripts/utils/object_pool.gd
class_name ObjectPool
extends Node

@export var scene: PackedScene = null
@export var initial_size: int = 20

var _pool: Array[Node] = []

func _ready() -> void:
    for i: int in range(initial_size):
        _create_object()

func get_object() -> Node:
    for obj: Node in _pool:
        if not obj.visible:
            obj.visible = true
            return obj
    # プールが枯渇した場合は新規作成
    Logger.warn("ObjectPool exhausted, expanding", {"scene": scene.resource_path})
    return _create_object()

func return_object(obj: Node) -> void:
    obj.visible = false

func _create_object() -> Node:
    var obj: Node = scene.instantiate()
    obj.visible = false
    add_child(obj)
    _pool.append(obj)
    return obj
```

---

## _process の最適化

```gdscript
# ❌ _process 内で毎フレーム重い処理（禁止）
func _process(_delta: float) -> void:
    _cache = items.filter(func(i: ItemData) -> bool: return i.is_active())  # 毎フレーム計算

# ✅ 変化時のみ更新
var _active_items_cache: Array[ItemData] = []

func _on_items_changed() -> void:
    _active_items_cache = items.filter(func(i: ItemData) -> bool: return i.is_active())
```

---

## テクスチャ最適化

```
□ スプライトは 2の累乗サイズ（512×512, 1024×1024 等）
□ モバイル向けは ASTC 圧縮を使う
□ スプライトシート（テクスチャアトラス）を使う
□ mipmap を有効化する（3D の場合）
```

---

## メモリリークの防止

```gdscript
# ✅ 動的に追加したノードは必ず queue_free() する
var _popup: Control = null

func _show_popup() -> void:
    _popup = preload("res://scenes/ui/popup.tscn").instantiate()
    add_child(_popup)
    _popup.closed.connect(_on_popup_closed)

func _on_popup_closed() -> void:
    _popup.queue_free()
    _popup = null

# ✅ シグナル接続の切断（EventBus は必須）
func _exit_tree() -> void:
    EventBus.game_over.disconnect(_on_game_over)
```
