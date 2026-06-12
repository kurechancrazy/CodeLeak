# 見下ろし型アクション RPG（ARPG）— ジャンルガイド

**次元:** 2D  
**genre-starters.md:** バンドル 8

---

## コアループ

フィールドをリアルタイムに移動し、アクション操作で敵を倒し、
装備・スキルを強化して次のエリアへ進む。

---

## シーン階層

```
World (Node2D)
├── TileMapLayer (地形・衝突)
├── TileMapLayer (装飾・手前)
├── EnemyGroup (Node2D)
├── NPCGroup (Node2D)
├── ItemDropGroup (Node2D)
├── Player (CharacterBody2D)
│   ├── AnimatedSprite2D
│   ├── CollisionShape2D
│   ├── SwordHitbox (Area2D)   — 攻撃判定（通常は disabled）
│   ├── HurtBox (Area2D)
│   └── InteractZone (Area2D)  — NPC・宝箱の検出
└── HUD (CanvasLayer)
    ├── HPBar
    ├── MPBar
    ├── Hotbar (スキル・アイテムショートカット)
    └── DamageNumbers (CanvasLayer)
```

---

## 必須 Autoload

| Autoload | ファイル | 役割 |
|---------|---------|------|
| QuestManager | `autoloads/quest_manager.gd` | クエスト進行・達成判定 |
| InventoryManager | `autoloads/inventory_manager.gd` | アイテム・装備管理 |
| ProgressManager | `autoloads/progress_manager.gd` | 実績・クリア率 |

---

## 主要実装パターン

### 8 方向移動と AnimatedSprite2D の向き管理

```gdscript
var _direction: Vector2 = Vector2.DOWN   # 最後の入力方向

func _update_animation() -> void:
    if _direction.y > 0:
        _sprite.play("walk_down")
    elif _direction.y < 0:
        _sprite.play("walk_up")
    elif _direction.x > 0:
        _sprite.play("walk_right")
    elif _direction.x < 0:
        _sprite.play("walk_left")
    elif velocity == Vector2.ZERO:
        _sprite.play("idle_" + _last_dir_name)
```

### 攻撃判定タイミング（AnimationPlayer 連携）

SwordHitbox（Area2D）は `monitoring = false` で待機。
AnimationPlayer のキーフレームで攻撃モーション中のみ有効化する。

```gdscript
# animation track: SwordHitbox:monitoring
# Frame 0.15: true   Frame 0.35: false
```

### ロックオン（ターゲット選択）

```gdscript
func _get_nearest_enemy() -> CharacterBody2D:
    var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
    var nearest: CharacterBody2D = null
    var min_dist: float = INF
    for enemy: Node in enemies:
        if enemy is CharacterBody2D:
            var dist: float = global_position.distance_to(enemy.global_position)
            if dist < min_dist:
                min_dist = dist
                nearest = enemy
    return nearest
```

---

## よくある地雷

- 攻撃後に SwordHitbox の `monitoring` を必ず `false` に戻す（戻し忘れると連続ヒット）
- ダメージ数字（DamageNumbers）は CanvasLayer に入れる。World 座標に追従させながら画面前面に表示
- InteractZone で複数の対象が重なった場合は最近傍を優先するか UI でリスト表示するか方針を決める

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/arpg-topdown.md` | このファイル |
| Autoload | `autoloads/quest_manager.gd`（作成した場合） | 3D RPG でも使用 |
| 共通 | `autoloads/inventory_manager.gd` | JRPG でも使用 |

```ini
; project.godot [autoload] から削除（3D RPG でも使わない場合のみ）
QuestManager="*res://autoloads/quest_manager.gd"
```
