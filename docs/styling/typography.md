# Typography — タイポグラフィ・フォントスケール

## フォントスケール

| 用途 | サイズ | ウェイト |
|------|--------|---------|
| 大見出し（タイトル画面） | 48〜72px | Bold/Black |
| 見出し（画面タイトル） | 28〜36px | Bold |
| サブ見出し | 20〜24px | SemiBold |
| 本文 | 16〜18px | Regular |
| キャプション（補足・ラベル） | 12〜14px | Regular |
| ボタンテキスト | 16〜18px | SemiBold |
| スコア・数値表示 | 24〜48px | Bold/Mono |

---

## フォントの使い方

```gdscript
# ✅ テーマ経由（推奨）
# インスペクターの Theme Override で設定する

# ✅ スクリプトからサイズを変更する場合
label.add_theme_font_size_override("font_size", 24)

# ✅ モノスペースが必要な場合（スコア・タイマー等）
var mono_font: FontFile = load("res://assets/fonts/RobotoMono-Bold.ttf")
score_label.add_theme_font_override("font", mono_font)
```

---

## 多言語対応のフォント

日本語テキストには必ず日本語フォントを設定する。
システムフォントは環境依存になるため使わない。

```
推奨フォント:
- Noto Sans JP（SIL OFL、商用無料）
- M PLUS Rounded 1c（SIL OFL）
- コーポレート・ロゴ（ラウンドを使ったゲームUI向け）
```

---

## テキストの折り返し

```gdscript
# ✅ 長いテキストは折り返しを有効にする
label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

# ✅ 固定幅のラベルはサイズフラグで伸縮
label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

# ❌ テキストが切れるまま放置（禁止）
```

---

## アクセシビリティのフォントサイズ

最小フォントサイズは **14px**（それ以下は読めない可能性がある）。
設定画面でフォントサイズを変更できるようにすることを推奨する。
