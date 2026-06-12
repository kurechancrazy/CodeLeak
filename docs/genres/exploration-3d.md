# 3D 探索 / ウォーキングシム — ジャンルガイド

**次元:** 3D  
**genre-starters.md:** バンドル 16（3D プラットフォーマーと同等。追加 Autoload なし）

---

## コアループ

フィールドや街を自由に歩き回り、建物に入ったり乗り物に乗ったり、
オブジェクトやNPCに話しかけたりして世界を探索する。
**戦闘・クエスト・バトルシステムは不要**。
「動かす気持ちよさ」と「インタラクト体験」が核心。

---

## このジャンルで使わない Autoload

| 使わない Autoload | 理由 |
|-----------------|------|
| BattleManager | 戦闘なし |
| PartyManager | パーティーなし |
| EncounterManager | エンカウントなし |
| FlagManager | 任意（単純な調査メモ程度なら SaveManager で代用可） |
| WaveManager | 敵ウェーブなし |

`project.godot` の `[autoload]` からこれらを削除してから実装を始めること。
→ `docs/genres/_index.md` の「全ジャンル固有コンポーネントを除外」手順を参照。

---

## シーン階層

```
World (Node3D)
├── DirectionalLight3D + WorldEnvironment   — 環境光・空
├── CityZone (Node3D)                       — 区画ごとに分割してストリーミングロード
│   ├── Buildings (Node3D)
│   │   ├── FireStation (StaticBody3D)      — 外観メッシュ + コリジョン
│   │   │   └── EntranceArea (Area3D)       — Interactable として機能
│   │   └── PoliceStation (StaticBody3D)
│   ├── Roads (StaticBody3D)
│   └── NavigationRegion3D                  — NPC の経路探索用
├── Vehicles (Node3D)
│   └── Train (Path3D)
│       └── TrainCar (PathFollow3D)         — 固定経路を走る
├── NPCGroup (Node3D)
│   └── NPC_01 (CharacterBody3D)
│       └── NavigationAgent3D
├── Player (CharacterBody3D)
│   ├── MeshInstance3D
│   ├── CollisionShape3D (CapsuleShape3D)
│   ├── CameraArm (SpringArm3D)
│   │   └── Camera3D
│   └── InteractZone (Area3D)               — 周囲の Interactable を検出
└── HUD (CanvasLayer)
    └── InteractPrompt (Label)              — "調べる [E]" などのプロンプト
```

---

## 主要実装パターン

### キャラクター移動・カメラ

`docs/genres/3d-platformer.md` の「CharacterBody3D の移動 + カメラ相対移動」パターンをそのまま使う。
ジャンプが不要な場合は `velocity.y` の重力処理だけ残し、ジャンプ入力を削除する。

---

### InteractZone（オブジェクト・NPC へのインタラクト）

**構造:** Player の子に `Area3D`（InteractZone）を置き、インタラクト可能なオブジェクト側にも `Area3D` を置く。

```gdscript
# interactable.gd — 建物入口・NPC・調べられるオブジェクトに attach
extends Area3D

@export var prompt_text: String = "調べる"

func interact(interactor: Node3D) -> void:
    pass  # 派生クラスでオーバーライド


# building_entrance.gd — 建物入口に attach
extends "res://scripts/interactable.gd"

@export var interior_scene: PackedScene = null

func interact(_interactor: Node3D) -> void:
    if interior_scene != null:
        SceneManager.go_to(interior_scene)
```

```gdscript
# player.gd（InteractZone の参照部分）
@onready var _interact_zone: Area3D = $InteractZone
@onready var _interact_prompt: Label = $"../HUD/InteractPrompt"

func _process(_delta: float) -> void:
    var nearest: Area3D = _find_nearest_interactable()
    _interact_prompt.visible = nearest != null
    if nearest != null:
        _interact_prompt.text = nearest.prompt_text + " [E]"

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("interact"):
        var target: Area3D = _find_nearest_interactable()
        if target != null:
            target.interact(self)

func _find_nearest_interactable() -> Area3D:
    var candidates: Array[Area3D] = _interact_zone.get_overlapping_areas()
    if candidates.is_empty():
        return null
    var nearest: Area3D = candidates[0]
    for area: Area3D in candidates:
        if area.global_position.distance_to(global_position) < nearest.global_position.distance_to(global_position):
            nearest = area
    return nearest
```

**Physics Layer 設定（必須）:**
```
Layer 3: interactable  ← Interactable の Area3D の collision_layer
Layer 3: interactable  ← InteractZone の collision_mask
```
`project.godot` の `[layer_names]` に追加する。

---

### 建物内外の遷移

**パターン A: シーン遷移（推奨・大きな屋内）**

```gdscript
# building_entrance.gd
func interact(_interactor: Node3D) -> void:
    SceneManager.go_to(interior_scene)
```

屋内シーンに「出口 Area3D」を置き、そこでも `SceneManager.go_to(exterior_scene)` で戻る。

**パターン B: 可視切り替え（シンプルな小屋など）**

```gdscript
# WorldManager.gd（Autoload or World スクリプト）
func enter_building(exterior: Node3D, interior: Node3D) -> void:
    exterior.visible = false
    interior.visible = true
    _player.global_position = interior.get_node("SpawnPoint").global_position
```

---

### PathFollow3D（電車・バス等の固定経路乗り物）

```gdscript
# train_car.gd
extends PathFollow3D

@export var speed: float = 8.0   # メートル/秒

func _process(delta: float) -> void:
    progress += speed * delta
    # Inspector で loop = true にすると路線を自動ループ
```

**セットアップ手順:**
1. `Path3D` ノードを置き、`Curve3D` で路線を描く
2. `Path3D` の子として `PathFollow3D` を追加
3. `PathFollow3D` の子として列車のメッシュ・コリジョンを追加
4. `PathFollow3D` に `train_car.gd` を attach し、`loop = true` に設定

乗客を乗せる場合はプレイヤーを `PathFollow3D` の子として `add_child` し、降りるときに `remove_child` してワールドに戻す。

---

### エリアストリーミング（大きな街）

`docs/genres/3d-rpg.md` の「エリア非同期ロード」パターンを使う。
街を複数の `Zone_*.tscn` に分割し、プレイヤーが近づいたときだけ `ResourceLoader.load_threaded_request()` でロードする。

---

## よくある地雷

- InteractZone の `collision_mask` を設定し忘れると何も検出されない → Layer 設定を必ず確認
- `PathFollow3D.loop` を `false` にすると路線の終端で止まる（意図しない場合は `true` に）
- 建物の外観と内装を同一シーンに置くと初期メモリが膨大になる → 内装は別シーンにしてストリーミングロード
- NPC が障害物を無視して突き抜ける → `NavigationRegion3D` に必ず NavigationMesh をベイクする
- `PathFollow3D` を持つ列車にプレイヤーを `add_child` すると座標系がずれる → `global_position` で補正するか `RemoteTransform3D` を使う

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル |
|------|---------|
| ドキュメント | `docs/genres/exploration-3d.md`（このファイル） |
| Autoload | なし（コアのみ使用） |

`project.godot` から追加で削除するエントリなし。
