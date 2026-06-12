# 3D ストラテジー / RTS — ジャンルガイド

**次元:** 3D  
**genre-starters.md:** バンドル 20

---

## コアループ

資源を採集し → ユニットを生産 → 命令（移動・攻撃）して敵の拠点を破壊する。
**ユニット選択（ボックス選択）・経路探索（NavMesh）・俯瞰カメラ**が操作の核心。

---

## シーン階層

```
GameWorld (Node3D)
├── Terrain (StaticBody3D)
├── NavigationRegion3D
├── FactionGroup_Player (Node3D)
│   ├── Unit × n (CharacterBody3D)
│   │   ├── MeshInstance3D
│   │   └── NavigationAgent3D
│   └── Building × n (StaticBody3D)
├── FactionGroup_Enemy (Node3D)
├── ResourceNodes (Node3D)     — 採集可能な資源
├── RTSCamera (Camera3D)       — 俯瞰・パン・ズーム制御
├── SelectionRect (Node2D / CanvasLayer)  — ボックス選択の UI 矩形
└── HUD (CanvasLayer)
    ├── MiniMap
    ├── ResourceDisplay
    └── SelectionInfo
```

---

## 主要実装パターン

### 俯瞰カメラ（パン・ズーム）

```gdscript
# RTSCamera.gd
func _process(delta: float) -> void:
    var pan_dir: Vector3 = Vector3.ZERO
    if Input.is_action_pressed("camera_up"):    pan_dir.z -= 1.0
    if Input.is_action_pressed("camera_down"):  pan_dir.z += 1.0
    if Input.is_action_pressed("camera_left"):  pan_dir.x -= 1.0
    if Input.is_action_pressed("camera_right"): pan_dir.x += 1.0
    position += pan_dir * PAN_SPEED * delta

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            position.y = maxf(MIN_HEIGHT, position.y - ZOOM_STEP)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            position.y = minf(MAX_HEIGHT, position.y + ZOOM_STEP)
```

### ボックス選択（ドラッグ選択）

```gdscript
# SelectionManager.gd
var _drag_start: Vector2 = Vector2.ZERO
var selected_units: Array[Node3D] = []

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                _drag_start = event.position
            else:
                _finish_selection(event.position)

func _finish_selection(end_pos: Vector2) -> void:
    var rect: Rect2 = Rect2(_drag_start, end_pos - _drag_start).abs()
    selected_units = _get_units_in_screen_rect(rect)
```

`Camera3D.unproject_position()` でユニットのワールド座標をスクリーン座標に変換して矩形判定する。

### ユニット命令（NavigationAgent3D）

```gdscript
# Unit.gd
func move_to(target_pos: Vector3) -> void:
    _nav_agent.target_position = target_pos

func _physics_process(_delta: float) -> void:
    if _nav_agent.is_navigation_finished():
        return
    velocity = (_nav_agent.get_next_path_position() - global_position).normalized() * speed
    move_and_slide()
```

---

## よくある地雷

- 多数のユニットが同一フレームに NavigationAgent3D を更新すると負荷が高い → フレームを分散させるか群れ AI（Flocking）を使う
- ボックス選択のスクリーン座標判定に `Camera3D.project_ray_*` を使うと重い → `Camera3D.unproject_position()` の方が速い

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/3d-strategy.md` | このファイル |
| Autoload | なし（コアのみ使用） | — |
