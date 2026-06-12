# Asset Management — アセット管理ガイド

**対象:** Godot 4.4+ / GDScript 2.0

---

## ディレクトリ構造規則

```
res://assets/
├── audio/
│   ├── bgm/          # BGM（.ogg 推奨）
│   └── sfx/          # 効果音（.wav 推奨）
├── fonts/            # フォントファイル（.ttf / .otf）
├── icons/            # アイコン（.png / .svg）
├── sprites/          # 2D スプライト・スプライトシート（.png）
├── textures/         # 3D テクスチャ（.png / .webp）
├── models/           # 3D モデル（.glb / .gltf）
└── ui/               # UI 専用画像・テーマリソース（.png / .tres）
```

**禁止:** `res://` の直下にアセットを置く → `res://assets/` 以下に分類する

---

## ファイル命名規則

| 種類 | 命名規則 | 例 |
|------|---------|-----|
| スプライト（1枚絵） | `snake_case.png` | `player_idle.png` |
| スプライトシート | `{name}_sheet.png` | `player_sheet.png` |
| BGM | `{name}.ogg` | `main_theme.ogg` |
| SFX | `{name}.wav` | `jump.wav`, `coin_pickup.wav` |
| フォント | `{family}-{weight}.ttf` | `noto-sans-jp-regular.ttf` |
| 3D モデル | `{name}.glb` | `player_character.glb` |

---

## 画像フォーマット・圧縮設定

### 2D スプライト（`res://assets/sprites/`）

| 設定項目 | 推奨値 | 備考 |
|---------|--------|------|
| Compress Mode | Lossless（PNG） | ドット絵・アルファ付き透過 |
| Mipmaps | 無効 | 2D はカメラズームしない限り不要 |
| Filter | Nearest（ドット絵）/ Linear（イラスト） | ドット絵には Nearest を使う |

```
# Godot インポート設定（.import ファイルで自動生成）
# ドット絵スプライトのインポート設定（Inspector でも変更可）
compress/mode=0          ; Lossless
flags/filter=false       ; Nearest filter（ドット絵）
flags/mipmaps=false
```

### 3D テクスチャ（`res://assets/textures/`）

| 設定項目 | 推奨値 | 備考 |
|---------|--------|------|
| Compress Mode | VRAM Compressed | GPU メモリ削減 |
| Mipmaps | 有効 | 遠距離描画のノイズ低減 |
| Normal Map | 法線マップは `as Normal Map` を有効に | 正しい法線計算のため |

### WebP vs PNG の選択基準

| 用途 | 推奨フォーマット |
|------|----------------|
| アルファ付きスプライト（小） | PNG |
| 大きな背景・UI 画像 | WebP（PNG より 25-30% 小さい） |
| アニメーションフレーム多数 | WebP |

---

## 音声ファイルの設定

### BGM（`res://assets/audio/bgm/`）

| 設定 | 推奨値 |
|------|--------|
| フォーマット | .ogg（Vorbis） |
| Loop | 有効（`loop=true`） |
| Bitrate | 128–192 kbps |

```
# ループポイントを正確に設定する（Godot インポート設定）
loop/mode=1       ; Forward loop
loop/begin=0
loop/end=-1       ; ファイル末尾まで
```

### SFX（`res://assets/audio/sfx/`）

| 設定 | 推奨値 |
|------|--------|
| フォーマット | .wav（無圧縮 PCM） |
| Loop | 無効 |
| サンプリングレート | 44100 Hz |

**禁止:** SFX を .ogg にする → 再生開始に数ミリ秒のレイテンシが発生する

---

## スプライトシートの設計

```
スプライトシートの推奨サイズ: 2のべき乗（512×512, 1024×1024, 2048×2048）
1枚あたりのフレームサイズ: 全フレームで統一する
```

Godot での使い方：
- `AnimatedSprite2D` に直接設定（SpriteFrames リソース）
- `Sprite2D` + `AtlasTexture` でフレーム指定
- `TextureAtlas` リソースを使って UV 管理

```gdscript
# AtlasTexture でスプライトシートの特定フレームを参照
var atlas: AtlasTexture = AtlasTexture.new()
atlas.atlas = preload("res://assets/sprites/player_sheet.png")
atlas.region = Rect2(0, 0, 64, 64)  # x, y, width, height
sprite.texture = atlas
```

---

## リソースの preload / load キャッシュ戦略

### シーン起動時に確実に使うもの → preload（定数として定義）

```gdscript
# scenes/gameplay/game_world.gd
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/ui/hud.tscn")
```

### 実行時に条件で決まるもの → load（ResourceLoader で存在チェック付き）

```gdscript
func load_level(level_id: int) -> void:
    var path: String = "res://scenes/levels/level_%02d.tscn" % level_id
    if not ResourceLoader.exists(path):
        Logger.error("Level not found", {"id": level_id})
        return
    var packed: PackedScene = load(path)
    SceneManager.go_to(path)
```

### 大きなリソースの非同期ロード → load_threaded_request

```gdscript
# ロード開始（フレームをブロックしない）
func _start_loading(path: String) -> void:
    ResourceLoader.load_threaded_request(path)
    EventBus.loading_started.emit("Loading...")

# 毎フレームで進捗確認
func _process(_delta: float) -> void:
    if _loading_path.is_empty():
        return
    var progress: Array = []
    var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(_loading_path, progress)
    match status:
        ResourceLoader.THREAD_LOAD_LOADED:
            var resource: Resource = ResourceLoader.load_threaded_get(_loading_path)
            _loading_path = ""
            EventBus.loading_finished.emit()
            _on_resource_loaded(resource)
        ResourceLoader.THREAD_LOAD_FAILED:
            Logger.error("Async load failed", {"path": _loading_path})
            _loading_path = ""
```

---

## ファイルサイズガイドライン

| リソース種類 | 上限目安 |
|------------|---------|
| 1スプライトシート | 2048×2048px 以下 |
| BGM（1曲） | 5MB 以下（.ogg 圧縮後） |
| SFX（1ファイル） | 200KB 以下（.wav） |
| 3D モデル（1つ） | 5MB 以下（.glb テクスチャ込み） |
| 合計アセットサイズ | 500MB 以下（モバイル向け） |
