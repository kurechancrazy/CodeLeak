# 2D ホラー / サバイバル — ジャンルガイド

**次元:** 2D（見下ろし型または横視点）  
**genre-starters.md:** バンドル 15

---

## コアループ

限られたリソースで脅威を回避・撃退しながら脱出ルートを探す。
**サニティ（精神力）ゲージ・限定的なセーブ・音響演出**がジャンルを支える。

---

## シーン階層

```
World (Node2D)
├── TileMapLayer (地形)
├── LightEnvironment (CanvasModulate)   — 暗闇の全体調光
│   └── PlayerLight (PointLight2D)     — プレイヤー周囲の灯り
├── EnemyGroup (Node2D)
│   └── Enemy (CharacterBody2D)
│       ├── NavigationAgent2D           — プレイヤーへの経路探索
│       └── HearingArea (Area2D)        — 音を検知するゾーン
├── ItemGroup (Node2D)                  — バッテリー・包帯・弾薬
├── InteractableGroup (Node2D)          — 扉・引き出し・セーブポイント
├── Player (CharacterBody2D)
│   ├── AnimatedSprite2D
│   ├── FlashlightCone (SpotLight2D / PointLight2D)
│   ├── SanityComponent (Node)
│   └── InventoryComponent (Node)
└── HUD (CanvasLayer)
    ├── SanityBar
    ├── HPBar
    └── ItemSlots
```

---

## 必須 Autoload

コアの Autoload のみ（追加固有 Autoload なし）。  
セーブポイント制限は `SaveManager` の呼び出し箇所を限定することで実現する。

---

## 主要実装パターン

### サニティ（精神力）ゲージ

```gdscript
# SanityComponent.gd（Player の子ノード）
const MAX_SANITY: float = 100.0

var sanity: float = MAX_SANITY

func _process(delta: float) -> void:
    # 暗闇・敵の近傍・特定イベントでジワジワ低下
    if _is_in_darkness():
        drain(5.0 * delta)

func drain(amount: float) -> void:
    sanity = maxf(0.0, sanity - amount)
    EventBus.notification_requested.emit("sanity_changed", "info")
    if sanity <= 0.0:
        EventBus.game_over.emit(0)

func restore(amount: float) -> void:
    sanity = minf(MAX_SANITY, sanity + amount)
```

### 敵の経路探索（NavigationAgent2D）

```gdscript
# Enemy.gd
@onready var _nav_agent: NavigationAgent2D = $NavigationAgent2D

func _physics_process(delta: float) -> void:
    if _state != State.CHASE:
        return
    _nav_agent.target_position = _player.global_position
    var next_pos: Vector2 = _nav_agent.get_next_path_position()
    velocity = (next_pos - global_position).normalized() * speed
    move_and_slide()
```

`NavigationAgent2D` を使うためにはシーンに `NavigationRegion2D` が必要。
TileMapLayer の Navigation レイヤーで通行可能領域を設定する。

### セーブポイント制限（セーブインク方式）

```gdscript
# SavePoint.gd
@export var uses_remaining: int = 2

func interact() -> void:
    if uses_remaining <= 0:
        EventBus.notification_requested.emit("インクがありません", "warn")
        return
    uses_remaining -= 1
    EventBus.save_requested.emit()
```

---

## よくある地雷

- イベントトリガーを「距離判定」でやると複数フレームにまたがって発火する → `Area2D` の `body_entered` シグナルで 1 回だけ発火させる
- `PointLight2D` を多用すると 2D の描画負荷が高い → ライトの texture サイズを小さくする
- 敵の NavigationAgent2D が壁をすり抜ける → NavigationRegion2D のポリゴンを手動で調整する

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/horror-2d.md` | このファイル |
| Autoload | なし（コアのみ使用） | — |
