# 横スクロールシューティング / 弾幕 — ジャンルガイド

**次元:** 2D  
**genre-starters.md:** バンドル 7

---

## コアループ

自機を操作して敵弾を避けながら敵を撃破し、ステージ末尾のボスを倒す。
**毎秒 10 〜 100 発の弾を生成するため ObjectPool は必須**。

---

## シーン階層

```
Stage (Node2D)
├── Background (ParallaxBackground)
│   └── ParallaxLayer × n
├── BulletPool (Node2D)       — ObjectPool で管理
│   └── PlayerBullet (多数)
├── EnemyBulletPool (Node2D)  — ObjectPool で管理
│   └── EnemyBullet (多数)
├── EnemyGroup (Node2D)       — WaveManager がスポーン
├── Player (CharacterBody2D)
│   ├── AnimatedSprite2D      — 自機グラフィック（当たり判定より大きい）
│   ├── HurtBox (Area2D)      — 実際の当たり判定（小さめ）
│   ├── CollisionShape2D (CircleShape2D)
│   └── Shield (Area2D)       — 無敵時間中のみ active
├── WaveScript (Node)         — タイムライン形式でウェーブを制御
└── HUD (CanvasLayer)
    ├── ScoreLabel
    ├── LivesDisplay
    └── BossHPBar
```

---

## 必須 Autoload

| Autoload | ファイル | 役割 |
|---------|---------|------|
| WaveManager | `autoloads/wave_manager.gd` | ウェーブ番号・敵数カウント |
| ProgressManager | `autoloads/progress_manager.gd` | ハイスコア・実績 |

---

## 主要実装パターン

### ObjectPool で弾を管理（必須）

弾を毎フレーム `instantiate()` すると GC でフレームドロップが発生する。
`ObjectPool`（テンプレート付属）で事前確保する。

```gdscript
# BulletPool.gd（ObjectPool を継承）
func fire(origin: Vector2, direction: Vector2, speed: float) -> void:
    var bullet: Node2D = acquire()  # ObjectPool.acquire()
    if bullet == null:
        return
    bullet.global_position = origin
    bullet.setup(direction, speed)
```

### 自機の当たり判定をスプライトより小さくする

```gdscript
# Player の HurtBox は CircleShape2D で radius = 4px 程度
# AnimatedSprite2D はそれより大きい自機グラフィック
# → 「当たっていない感」がプレイヤーに有利な気持ちよさを生む
```

### ウェーブスクリプト（タイムライン型）

```gdscript
# WaveScript.gd — Stage 専用の演出スクリプト
func run_wave_1() -> void:
    await spawn_formation("v_formation", Vector2(200, 0), 5)
    await get_tree().create_timer(3.0).timeout
    await spawn_single("boss_01", Vector2(400, 100))
```

`WaveManager.start_wave(wave_data)` を呼んで敵数を登録した後、
各敵の撃破時に `WaveManager.on_enemy_killed()` を呼ぶ。

---

## よくある地雷

- ObjectPool なしで毎フレーム弾をインスタンス化 → 弾幕ゲームは必ずプーリングする
- 全弾が Area2D で衝突検出すると処理が重くなる → 弾のタイプごとに collision_layer を分ける
- 画面外の敵弾が永遠に飛び続けるとメモリリーク → 画面外判定で ObjectPool に返す
- 弾の `VisibilityNotifier2D.screen_exited` シグナルで自動返却するのが定番

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/shmup.md` | このファイル |
| Autoload | `autoloads/wave_manager.gd` | タワーディフェンスでも使用 |
| データ | `scripts/data/wave_data.gd` | タワーディフェンスでも使用 |
| 共通 | `autoloads/progress_manager.gd` | 他ジャンルでも使用 |

```ini
; タワーディフェンスも使わない場合のみ project.godot から削除
WaveManager="*res://autoloads/wave_manager.gd"
```
