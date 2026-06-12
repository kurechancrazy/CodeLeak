# Accessibility — アクセシビリティ対応

## Godot のアクセシビリティ機能

Godot 4 は `AccessibilityServer` を通じてスクリーンリーダー連携を提供している（実験的）。
基本的なアクセシビリティは以下で対応する。

---

## フォーカス管理

全てのインタラクティブ要素がキーボード・ゲームパッドでフォーカス可能であること。

```gdscript
# ✅ フォーカスを明示的に設定
func _ready() -> void:
    # 最初の要素にフォーカス
    start_button.grab_focus()

# ✅ フォーカスの移動順序を設定（インスペクターで設定するか）
func _setup_focus_chain() -> void:
    start_button.focus_next = settings_button.get_path()
    settings_button.focus_next = quit_button.get_path()
    quit_button.focus_previous = settings_button.get_path()

# ✅ フォーカス時のビジュアルフィードバック
# テーマで Button の Focus スタイルボックスを設定する
```

---

## タッチターゲットサイズ

```gdscript
# ✅ 最低 44×44 ピクセル（iOS HIG / Material Design 準拠）
button.custom_minimum_size = Vector2(44, 44)
```

---

## テキストのコントラスト

| 背景色 | テキスト色 | コントラスト比 |
|--------|----------|------------|
| 暗い背景 | 白または明るいグレー | 4.5:1 以上（WCAG AA） |
| 明るい背景 | 黒または暗いグレー | 4.5:1 以上 |
| 重要なテキスト | より高いコントラスト | 7:1 以上（WCAG AAA） |

---

## モーション軽減

```gdscript
# ✅ OS のモーション軽減設定を確認
func _apply_reduced_motion() -> void:
    # DisplayServer は直接的なmotion reduction APIを持たないため
    # 設定から読み取る
    var reduce_motion: bool = GameManager.settings.get("reduce_motion", false)
    if reduce_motion:
        _disable_decorative_animations()

func _disable_decorative_animations() -> void:
    # 装飾的なアニメーション（浮遊・パーティクル等）を停止
    $ParticleEffects.emitting = false
```

---

## アクセシビリティチェックリスト

```
□ 全インタラクティブ要素がキーボード・ゲームパッドで操作可能か
□ フォーカスの移動順序が論理的か（上→下・左→右）
□ フォーカス時のビジュアルフィードバックがあるか
□ タッチターゲットが最低 44×44 ピクセルか
□ テキストのコントラスト比が 4.5:1 以上か
□ 色だけで情報を伝えていないか（アイコン・ラベルを併用）
□ アニメーションを無効化できる設定があるか
□ フォントサイズを調整できる設定があるか
```
