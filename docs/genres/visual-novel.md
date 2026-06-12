# ビジュアルノベル — ジャンルガイド

**次元:** 2D（UI 中心）  
**genre-starters.md:** バンドル 4

---

## コアループ

テキストを読み進め、選択肢でルート分岐し、エンディングへ到達する。
**テキスト表示速度・オート再生・バックログ・選択フラグ管理**が品質の核心。

---

## シーン階層

```
NovelScene (Control)
├── Background (TextureRect)           — 背景画像
├── CharacterLayer (HBoxContainer)     — 立ち絵を中央・左・右に配置
│   └── CharaSprite_Center (TextureRect)
├── TextBox (PanelContainer)
│   ├── SpeakerLabel (Label)
│   └── BodyLabel (RichTextLabel)      — wait_for_meta + bbcode_enabled
├── ChoiceContainer (VBoxContainer)    — 選択肢が出るときのみ visible
│   └── ChoiceButton × n (Button)
├── BacklogPanel (ScrollContainer)     — Log ボタンで表示
│   └── BacklogContent (VBoxContainer)
└── ControlBar (HBoxContainer)
    ├── AutoButton (CheckButton)
    └── SkipButton (Button)
```

---

## 必須 Autoload

| Autoload | ファイル | 役割 |
|---------|---------|------|
| ScriptReader | （作成する場合）`autoloads/script_reader.gd` | シナリオファイル解析・ページ進行 |
| FlagManager | `autoloads/flag_manager.gd` | 選択フラグ・ルート管理 |

---

## 主要実装パターン

### シナリオデータ形式（JSON）

```json
{
  "id": "scene_01",
  "pages": [
    { "speaker": "主人公", "text": "ここは…どこだ？" },
    { "speaker": "謎の少女", "text": "目が覚めましたか？",
      "portrait": "girl_surprised" },
    { "speaker": "", "text": "少女はこちらを見つめている。",
      "choices": [
        { "text": "話しかける", "flag": "talked_to_girl", "next_id": "scene_02" },
        { "text": "無視する",   "next_id": "scene_03" }
      ]
    }
  ]
}
```

`docs/rpg/dialog-system.md` も参照（ダイアログ JSON 設計の詳細）。

### テキストタイプライター効果（RichTextLabel）

```gdscript
# TextBox.gd
func show_text(text: String) -> void:
    _body_label.text = text
    _body_label.visible_characters = 0
    _tween = create_tween()
    _tween.tween_property(_body_label, "visible_characters", text.length(), text.length() * 0.03)
    await _tween.finished
    _tween = null
```

### オート再生

```gdscript
# NovelScene.gd
func _process(delta: float) -> void:
    if GameManager.state != GameManager.GameState.AUTO_PLAY:
        return
    _auto_timer += delta
    if _auto_timer >= AUTO_DELAY and not _is_animating():
        _auto_timer = 0.0
        _advance()
```

---

## よくある地雷

- `RichTextLabel.visible_characters` と `text` の長さが合わなくなるのは `bbcode_enabled` の挿入タグが含まれるから → `get_total_character_count()` を使う
- バックログの全文を `Array` で持ち続けるとメモリが増える → 最大 100 行で上限管理
- `FlagManager` の状態をオートセーブしていないと、エラー後に分岐が変わる

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/visual-novel.md` | このファイル |
| Autoload | `autoloads/flag_manager.gd` | JRPG でも使用 |

```ini
; JRPG でも使わない場合のみ project.godot から削除
FlagManager="*res://autoloads/flag_manager.gd"
```
