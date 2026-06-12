# Pixel Art Setup — ドット絵プロジェクト設定

**対象:** Godot 4.4+ / ドット絵（ピクセルアート）スタイルのゲーム

---

## Claude Code 実装停止チェックリスト

```
□ project.godot のテクスチャフィルタ設定を行わずにスプライトを追加しようとしている
□ 論理解像度（仮想解像度）を決めずにレイアウトを実装しようとしている
□ スプライトのインポート設定（Nearest フィルタ）を確認せずに配置しようとしている
□ CanvasItem の texture_filter がドット絵の表示を壊していないか確認していない
```

---

## 1. project.godot の必須設定

ドット絵ゲームでは起動時に以下の設定を行うこと。設定漏れはスプライトぼけの原因になる。

```ini
[rendering]
; テクスチャフィルタをバイリニアからニアレスト（最近傍補間）に変更
; これがないとドット絵がぼやける
textures/canvas_textures/default_texture_filter=0

[display]
; 論理解像度（例: SNES相当のドット絵ゲーム）
window/size/viewport_width=320
window/size/viewport_height=240

; 起動時ウィンドウサイズ（論理解像度の3倍）
window/size/initial_screen=0
window/size/window_width_override=960
window/size/window_height_override=720

; ストレッチ設定: canvas_items でドット絵を整数倍スケールする
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"
```

### 論理解像度の選び方

| スタイル | 論理解像度 | 参考タイトル |
|---------|-----------|------------|
| FC / NES 風 | 256×240 | ロックマン |
| SFC / SNES 風 | 256×224 または 320×240 | FF4/5/6 |
| GBA 風 | 240×160 | ポケモン |
| HD ドット絵 | 480×270（1920×1080 の 1/4） | オクトパストラベラー風 |

> FF4/5/6 スタイルなら **256×224** または **320×240** を推奨。

---

## 2. スプライトのインポート設定

### 方法 A: `.import` ファイルで個別設定（非推奨）

インポート設定を変えると `.import` ファイルが生成されるが、
プロジェクト全体の `default_texture_filter=0` 設定が済んでいれば個別変更は不要。

### 方法 B: プロジェクト設定でグローバル適用（推奨）

上記 `project.godot` の設定（`default_texture_filter=0`）で全スプライトに自動適用される。

### 例外ケース: 特定テクスチャだけリニアフィルタを使う

```gdscript
# ✅ ノード単体でフィルタを上書き（UI グラデーションに使いたい場合など）
@onready var gradient_rect: TextureRect = $GradientRect

func _ready() -> void:
    gradient_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
```

---

## 3. AnimatedSprite2D のドット絵設定

```gdscript
# scenes/characters/player.gd
extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
    # SpriteFrames は Inspector で設定する
    # アニメーション名は定数で管理
    pass

const ANIM_IDLE: String   = "idle"
const ANIM_WALK: String   = "walk"
const ANIM_RUN: String    = "run"
const ANIM_ATTACK: String = "attack"
const ANIM_DAMAGE: String = "damage"
const ANIM_DEATH: String  = "death"
```

### SpriteFrames の設定（Inspector）

| 設定項目 | 推奨値 | 理由 |
|---------|--------|------|
| `Filter` | `Nearest` | ドット絵をくっきりさせる |
| FPS | 8〜12 | SFC 相当のアニメーション速度感 |
| Loop | アニメーション種別による | `idle`/`walk` は ON、`attack`/`death` は OFF |

---

## 4. TileMap のドット絵設定

```gdscript
# TileSet の tile_size をドット絵グリッドに合わせる
# Inspector で TileSet > Tile Size = Vector2i(16, 16) など
```

| タイルサイズ | 使う場面 |
|-----------|---------|
| 16×16 | FC / NES 風 |
| 16×16 または 32×32 | SFC / SNES 風（FF4/5/6 は 16×16） |
| 32×32 | GBA / 高解像度ドット絵 |

**禁止:** TileMap の `tile_size` を後から変更する（全マップの位置ずれが発生する）

---

## 5. カメラとスナップ（ピクセルパーフェクト）

ドット絵ゲームではカメラ位置を整数ピクセルにスナップしないとちらつく。

```gdscript
# scenes/world/field_camera.gd
extends Camera2D

func _process(_delta: float) -> void:
    # カメラを整数ピクセルにスナップ（サブピクセルぼけ防止）
    position = position.round()
```

または `project.godot` でスナップを強制:

```ini
[rendering]
2d/snap/snap_2d_vertices_to_pixel=true
2d/snap/snap_2d_transforms_to_pixel=true
```

> `snap_2d_transforms_to_pixel=true` にすると全ノードが自動スナップされる。
> ただし Tween や物理演算との相性を必ずテストすること。

---

## 6. ウィンドウスケールと解像度切り替え

```gdscript
# autoloads/game_manager.gd 内で解像度変更する場合の例
func set_window_scale(scale: int) -> void:
    var base_width: int = ProjectSettings.get_setting(
        "display/window/size/viewport_width"
    )
    var base_height: int = ProjectSettings.get_setting(
        "display/window/size/viewport_height"
    )
    DisplayServer.window_set_size(
        Vector2i(base_width * scale, base_height * scale)
    )
```

| scale 値 | 例（320×240 ベース） |
|---------|-------------------|
| 2 | 640×480 |
| 3 | 960×720（推奨デフォルト） |
| 4 | 1280×960 |

---

## 7. よくある問題と解決策

| 症状 | 原因 | 解決策 |
|------|------|--------|
| スプライトがぼやける | `default_texture_filter` が `LINEAR` のまま | `project.godot` で `0`（Nearest）に設定 |
| スクロール中にちらつく | サブピクセルずれ | `snap_2d_transforms_to_pixel=true` |
| 一部スプライトだけぼやける | ノード固有の `texture_filter` が上書き | Inspector で `texture_filter = Nearest` に変更 |
| 画面が引き伸びる | `stretch/aspect` 設定ミス | `"keep"` または `"keep_width"` に変更 |
| 全体的に暗い/明るい | CanvasModulate がある | 意図的なら OK、不要なら削除 |
