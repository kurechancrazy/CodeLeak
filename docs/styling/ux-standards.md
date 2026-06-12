# UX Standards — UI/UX標準

## タッチターゲット

```
最低サイズ: 44×44 ピクセル（iOS HIG 準拠）
推奨サイズ: 48×48 ピクセル以上（Material Design 推奨）
```

```gdscript
# ✅ Button の最低サイズを設定
button.custom_minimum_size = Vector2(48, 48)
```

---

## スペーシング（マージン・パディング）

| 用途 | 値 |
|------|-----|
| コンポーネント間の小さな余白 | 8px |
| セクション間の余白 | 16px |
| 画面端のマージン | 16px〜24px |
| カード・パネルのパディング | 12px〜16px |

---

## レスポンシブ対応

```gdscript
# ✅ ビューポートサイズに応じてUIを調整
func _on_viewport_size_changed() -> void:
    var viewport_size: Vector2 = get_viewport_rect().size
    if viewport_size.x < 768:
        _apply_mobile_layout()
    else:
        _apply_desktop_layout()

# ✅ AspectRatioContainer でアスペクト比を維持
```

---

## インタラクションフィードバック

ユーザーの操作には必ず視覚的・聴覚的フィードバックを返す。

```gdscript
# ✅ ボタンにホバー・押下アニメーション
func _on_button_mouse_entered() -> void:
    var tween: Tween = create_tween()
    tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)

func _on_button_pressed() -> void:
    EventBus.sfx_play_requested.emit("click")
    var tween: Tween = create_tween()
    tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.05)
    tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
```

---

## UI/UX チェックリスト（コミット前に確認）

### UIスクリーン全般（メニュー・設定・タイトル）

```
□ タッチターゲットが最低 44×44 ピクセルか
□ 破壊的操作（削除・リセット・タイトルへ戻る）に確認ダイアログがあるか
□ ボタン押下に視覚・音声フィードバックがあるか
□ キーボード・ゲームパッドでフォーカス移動できるか
□ フォント・アイコンが必要サイズで見やすいか（最低 20px）
□ カラーパレットが GameColors から使用されているか
```

### ゲームプレイ画面（HUD・ゲームオーバー・クリア）

```
□ HUD が画面の 10% 以内に収まっているか
□ 残り少ない値（HP・タイマー）に色変化・点滅などの警告があるか
□ 主要アクション（取得・ダメージ）に SFX フィードバックがあるか
□ ゲームオーバー → リトライが 1ボタンで即開始できるか
□ ポーズが常に Esc / Start で呼び出せるか
```

### 非同期・ローディング状態（メニューで非同期処理がある場合）

```
□ Loading / Error / Empty の3状態が実装されているか
□ フォームに入力バリデーションとエラー表示があるか（フォームがある場合のみ）
```

**ゲーム固有の詳細な UX パターン → `docs/gameplay/game-ux.md`**
