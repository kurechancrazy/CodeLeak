# Game UX — ゲーム固有のUI/UX設計

**対象:** Godot 4.4+ / GDScript 2.0

汎用的なUI/UX規約（スペーシング・アクセシビリティ）は `docs/styling/ux-standards.md` を参照。
このドキュメントはゲーム特有の「手触り感・シーン遷移・HUD」を扱う。

---

## ゲームフィール（Juice）の基本原則

「ゲームが気持ちいい」と感じさせる演出。実装は任意だが、**アクション・パズル系では必須**。

### スクリーンシェイク

```gdscript
# autoloads/game_manager.gd またはシーンのカメラスクリプト
func shake_camera(intensity: float, duration: float) -> void:
    var tween: Tween = create_tween()
    var original_offset: Vector2 = camera.offset
    var elapsed: float = 0.0
    var steps: int = int(duration / 0.016)  # 60fps 換算

    for i: int in range(steps):
        var shake_offset: Vector2 = Vector2(
            randf_range(-intensity, intensity),
            randf_range(-intensity, intensity)
        )
        tween.tween_property(camera, "offset", shake_offset, 0.016)

    tween.tween_property(camera, "offset", original_offset, 0.05)
```

### ヒットストップ（一時停止）

ダメージを与えたとき・受けたときに数フレームだけ時間を止めると「重さ」が出る。

```gdscript
func hit_stop(frames: int = 3) -> void:
    Engine.time_scale = 0.0
    await get_tree().create_timer(frames / 60.0, true, false, true).timeout
    Engine.time_scale = 1.0
```

**注意:** `hit_stop` 中はゲームが止まるので UI（ポーズメニュー）は `PROCESS_MODE_ALWAYS` にしておく。

### スケールポップ（スコア取得・アイテム獲得）

```gdscript
func pop_scale(node: Node2D, scale_to: float = 1.3, duration: float = 0.1) -> void:
    var tween: Tween = create_tween()
    tween.tween_property(node, "scale", Vector2(scale_to, scale_to), duration)
    tween.tween_property(node, "scale", Vector2(1.0, 1.0), duration)
```

### フィードバックの最低基準

| アクション | 視覚 | 音 |
|-----------|------|-----|
| ボタン押下 | スケールアニメ or フラッシュ | click SFX |
| ダメージ受け | 赤フラッシュ + シェイク | hit SFX |
| アイテム取得 | スケールポップ + パーティクル | pickup SFX |
| レベルクリア | 画面フラッシュ | fanfare BGM |
| ゲームオーバー | フェードアウト | gameover SFX + stop BGM |

---

## 重要画面の UX パターン

### ポーズ画面

```
実装要件:
□ Esc / Start ボタンで即座に表示・非表示
□ ゲームが一時停止（get_tree().paused = true）
□ ポーズ画面自体は PROCESS_MODE_ALWAYS で動作
□ ゲームの画面が薄暗くなる（ColorRect で半透明オーバーレイ）
□ 「再開」「設定」「タイトルへ戻る」の選択肢
□ タイトルへ戻る前に確認ダイアログを表示
```

### ゲームオーバー画面

```
実装要件:
□ ゲームオーバーの理由が視覚的に明確（HP0 → キャラ倒れる演出）
□ スコアとベストスコアを並べて表示
□ 「リトライ」「タイトルへ戻る」の選択肢
□ リトライは 1ボタンで即座に開始できること（摩擦を最小化）
□ 自動でリトライへフォーカスを当てる
```

### レベルクリア / 勝利画面

```
実装要件:
□ 演出完了前に次へ進めないよう入力を一定時間ブロック（誤タップ防止）
□ 獲得スコア・星評価などを時間差で表示（達成感を演出）
□ 「次のステージ」「リプレイ」「タイトルへ戻る」の選択肢
```

### タイトル画面 / メインメニュー

```
実装要件:
□ 「続きから」と「最初から」を明確に分ける
□ セーブデータがない場合は「続きから」をグレーアウトまたは非表示
□ バージョン番号を画面端に表示（デバッグ確認用）
□ BGM はタイトル表示と同時に再生開始
```

---

## HUD の視認性ルール

### 情報の優先度と配置

```
最重要（常に目に入る位置）: HP・残機・タイマー
  → 画面四隅に配置。中央は避ける（ゲームプレイを邪魔する）

重要（プレイ中に参照する）: スコア・コンボ数・弾数
  → 画面上部または上隅

補助（必要なときだけ見る）: ミニマップ・アイテム一覧
  → 画面隅に小さく配置。デフォルトは半透明
```

### 解像度対応チェック

```gdscript
# HUD のフォントサイズは固定値ではなく viewport サイズから計算する
func _update_hud_scale() -> void:
    var viewport_height: float = get_viewport_rect().size.y
    var scale_factor: float = viewport_height / 1080.0  # 1080p 基準
    score_label.add_theme_font_size_override("font_size", int(32 * scale_factor))
```

### HUD視認性チェックリスト

```
□ 画面の 10% 以上を HUD が占有していないか
□ HUD の背景（半透明パネル）があり、ゲーム背景と分離されているか
□ 最小フォントサイズは 20px 以上か（モバイルは 24px 以上）
□ 重要な数値（HP・タイマー）が残り少ないとき色が変わるか（赤・点滅）
□ 縦持ち・横持ち両方でHUDが見切れないか（モバイル対象の場合）
```

---

## チュートリアル / 操作説明のパターン

```
ルール:
□ ゲーム開始時に操作方法をテキストで説明しない（実際にやらせる）
□ 「〇ボタンでジャンプ」は実際に押すまで消えないよう表示し続ける
□ プラットフォームに応じてボタン表記を変える（PC: Space / ゲームパッド: A ボタン）
□ チュートリアルはスキップできるようにする
```

```gdscript
# プラットフォーム別ボタン表記
func get_jump_label() -> String:
    if Input.get_connected_joypads().size() > 0:
        return "Aボタン でジャンプ"
    else:
        return "Space でジャンプ"
```

---

## アニメーション・演出のルール

| 演出の種類 | 所要時間の目安 | 理由 |
|-----------|-------------|------|
| ボタン押下フィードバック | 0.05〜0.1秒 | 即時感 |
| シーン遷移フェード | 0.3〜0.5秒 | 自然な切り替わり |
| スコア加算アニメ | 0.5〜1.0秒 | 達成感を味わわせる |
| ゲームオーバー演出 | 1.0〜2.0秒 | 結果を受け入れる時間 |
| ローディング最低表示時間 | 0.3秒以上 | 一瞬の表示でちらつきを防ぐ |

**禁止:** 演出が終わるまで操作を完全にブロックする（ローディング除く）
→ 演出中でもポーズは常に受け付ける

---

## ゲームUX チェックリスト（実装後に確認）

```
--- ゲームフィール ---
□ 主要アクション（攻撃・取得・ダメージ）にSFXがあるか
□ ボタン押下に視覚フィードバックがあるか（スケール・フラッシュ）

--- 画面遷移 ---
□ シーン遷移にフェードがあるか（即切り替えはしていないか）
□ ゲームオーバー → リトライが1ボタンで即開始できるか
□ タイトルへ戻る前に確認ダイアログがあるか

--- HUD ---
□ HUD が画面の 10% 以内か
□ 残り少ない値（HP・タイマー）に視覚的警告があるか
□ 最小フォントサイズは 20px 以上か

--- アクセシビリティ ---
□ ポーズが常に Esc / Start で呼び出せるか
□ 全メニューがゲームパッドで操作できるか
□ BGM・SFX の音量を設定で変更できるか
```

---

## ジャンル別 UX 最低要件

### アクション系

```
□ 入力からキャラ動作までの遅延が 1〜2 フレーム以内か
□ ダメージ時に点滅・赤フラッシュなど無敵時間の視覚フィードバックがあるか
□ 攻撃のヒット確認（ヒットストップ または SE + エフェクト）があるか
□ 死亡アニメーション中に次の操作を受け付けないよう入力をブロックしているか
```

### パズル系

```
□ 操作の結果（ブロック移動・消去）が明確なアニメーションで示されるか
□ 「詰み」の状態でリセットボタンが常に表示されているか
□ undo がある場合、操作可能な状態と不可能な状態がボタンの見た目で区別できるか
□ タイムアタック要素がある場合、残り時間に警告演出があるか（30秒切りで色変化等）
```

### RPG 系

```
□ バトル開始・終了の演出時間が 2 秒以内か（冗長なアニメーションで離脱しないよう）
□ コマンド選択中はキャンセル（戻る）が必ず機能するか
□ ステータス変化（バフ・デバフ）が視覚的アイコンで表示されるか
□ セーブ中はインジケーター（ぐるぐる等）を表示しているか
```

### ノベル系

```
□ テキスト表示中にスキップ（すべて即表示）ができるか
□ 選択肢の選択後、選んだ内容が一瞬でも確認できるか
□ バックログ（読み返し）から戻るボタンがあるか
□ オート進行中にタップで停止できるか
```

---

## プログレッション・達成感のフィードバックパターン

### スコア加算演出

```gdscript
# スコアが加算される時のカウントアップ演出
func animate_score(from: int, to: int) -> void:
    var tween: Tween = create_tween()
    tween.tween_method(
        func(value: float) -> void: score_label.text = str(int(value)),
        float(from),
        float(to),
        0.5
    )
```

### 星評価・ランク表示

クリア画面での評価表示は時間差で順番に表示する（達成感を演出）。

```gdscript
func show_results(stars: int, score: int, time: float) -> void:
    # 1. スコアをカウントアップ表示
    animate_score(0, score)
    await get_tree().create_timer(0.8).timeout
    # 2. タイム表示
    time_label.visible = true
    await get_tree().create_timer(0.4).timeout
    # 3. 星を1つずつ点灯
    for i: int in range(stars):
        star_icons[i].modulate = Color.YELLOW
        AudioManager.play_sfx("star_earn")
        await get_tree().create_timer(0.3).timeout
```

### ハイスコア更新の演出

```gdscript
func _on_game_over(final_score: int) -> void:
    if final_score > GameManager.high_score:
        # ハイスコア更新
        new_record_label.visible = true
        var tween: Tween = create_tween()
        tween.tween_property(new_record_label, "scale", Vector2(1.3, 1.3), 0.1)
        tween.tween_property(new_record_label, "scale", Vector2(1.0, 1.0), 0.1)
        AudioManager.play_sfx("new_record")
```
