# Asset Workflow — アセット追加ワークフロー

**対象:** Godot 4.4+ / GDScript 2.0

アセット追加は Quick Fix パスで処理する（既存コードを修正するだけなので新規設計不要）。
ただし以下のチェックリストを必ず実施すること。

---

## Quick Fix / Full Spec 判断

| ケース | パス |
|-------|------|
| 既存の AudioManager / scene に音声・画像を差し替える | Quick Fix |
| 新しい AudioManager の BGM/SFX ファイルを追加する | Quick Fix |
| 新しいスプライト・テクスチャを既存シーンに追加する | Quick Fix |
| 新しいシーン（.tscn）を追加する | **Full Spec** |
| 新しい 3D モデルを追加してシーン設計が変わる | **Full Spec** |

---

## 画像追加チェックリスト

### 配置先

```
スプライト（2D）    → res://assets/sprites/{category}/{name}.png
UIパーツ           → res://assets/ui/{name}.png
テクスチャ（3D）   → res://assets/textures/{name}.png / .webp
アイコン           → res://assets/icons/{name}.png / .svg
```

### インポート設定（Godot エディタ > Inspector > Import タブ）

**ドット絵スプライト:**
```
Compress > Mode: Lossless
Flags > Filter: OFF（Nearest filter）
Flags > Mipmaps: OFF
```

**イラスト・UI 画像:**
```
Compress > Mode: Lossless（透過あり）または VRAM Compressed（透過なし）
Flags > Filter: ON（Linear filter）
Flags > Mipmaps: OFF（2D は不要）
```

**3D テクスチャ:**
```
Compress > Mode: VRAM Compressed
Flags > Filter: ON
Flags > Mipmaps: ON
Normal Map の場合: Detect 3D > As Normal Map をチェック
```

### 確認チェック

```
□ ファイル名が snake_case か（例: player_idle.png）
□ res://assets/ 以下の正しいディレクトリに配置したか
□ インポート設定を変更した場合、.import ファイルをコミットに含めたか
□ ファイルサイズが ux-standards.md のガイドライン内か（スプライトシート: 2048×2048以下）
□ アルファ付き PNG を使っている場合、背景色が意図通りか
```

---

## 音声追加チェックリスト

### 配置先

```
BGM（ループ楽曲）  → res://assets/audio/bgm/{name}.ogg
SFX（効果音）     → res://assets/audio/sfx/{name}.wav
```

### インポート設定

**BGM（.ogg）:**
```
Loop > Mode: Forward（ループ有効）
Loop > Begin: 0
Loop > End: -1（ファイル末尾）
```

**SFX（.wav）:**
```
Loop > Mode: Disabled（ループ無効）
```

### AudioManager での動作確認

```gdscript
# デバッグビルドで一時的に再生確認（コミット前に削除）
func _ready() -> void:
    if OS.is_debug_build():
        AudioManager.play_sfx("new_sound_name")   # 追加したSFX名
        # AudioManager.play_bgm("new_bgm_name")   # 追加したBGM名
```

### 確認チェック

```
□ BGM: .ogg 形式か
□ SFX: .wav 形式か
□ BGM: インポート設定でループが有効か
□ SFX: インポート設定でループが無効か
□ AudioManager.play_sfx("name") / play_bgm("name") でエラーなく再生できるか
□ ファイル名が AudioManager の命名規則に沿っているか（スペースなし・snake_case）
□ BGM のループポイントが自然なつながりになっているか（実際に再生して確認）
```

---

## 3D モデル追加チェックリスト

### 配置先

```
3D モデル → res://assets/models/{category}/{name}.glb
```

### インポート設定（.glb ファイル選択後の Import タブ）

```
Meshes > Generate LODs: ON
Meshes > Create Shadow Meshes: ON（主要キャラのみ）
Skins > Use Named Skins: ON（アニメーション付きの場合）
Animation > Storage: Files（アニメーションを別ファイルに分離する場合）
```

### スケール確認

```gdscript
# Blender → Godot のスケール変換（通常は 1ユニット = 1メートル）
# インポート後にシーン上でサイズを確認する
# 想定外のスケールの場合: Import > Scale Factor を調整
```

### コリジョン設定

```
複雑な形状を必要としない場合（プレイヤー・敵）
  → MeshInstance3D の親に CollisionShape3D を手動追加
  → CollisionShape3D の Shape: CapsuleShape3D または BoxShape3D

精密な形状が必要な場合（地形・建物）
  → Import > Physics > Trimesh Collision Shape: ON
  → ただしパフォーマンスコストが高い（StaticBody 専用）
```

### 確認チェック

```
□ ゲームシーンに配置したとき、サイズが他のオブジェクトと比較して適切か
□ コリジョン形状が設定されているか（CharacterBody3D・RigidBody3D・StaticBody3D）
□ アニメーションが含まれる場合、AnimationPlayer または AnimationTree で再生できるか
□ テクスチャが正しく表示されているか（法線マップがある場合は As Normal Map 設定）
□ LOD が設定されているか（遠景でポリゴンが削減されるか）
```

---

## アセット追加後の共通確認

```
□ git status で .import ファイルが含まれているか確認
□ gdlint → エラー 0 件（アセット参照コードがある場合）
□ GUT → 全テスト PASS（アセット名を使ったテストがある場合）
□ Godot エディタで実行して視覚的に確認
```
