# Control Pitfalls — Control ノードの地雷パターン

## このドキュメントの使い方

UIレイアウトを実装する前に**必ず**読むこと。
以下のパターンは Godot 4 で頻繁に起きる問題。知らずに実装すると全面修正が必要になる。

---

## 地雷1: size vs minimum_size の混同

`size` は実際の表示サイズ（親コンテナが決定）。`minimum_size` はコンテナに「最低このサイズ以上にして」と伝えるヒント。

```gdscript
# ❌ size を直接セット（コンテナ内では無視される）
my_control.size = Vector2(200, 50)

# ✅ minimum_size を使う
my_control.custom_minimum_size = Vector2(200, 50)

# ✅ または SizeFlagsを使う
my_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
```

---

## 地雷2: アンカーとオフセットの混同

フリーレイアウト（Container外）では `anchors` と `offset` で位置を制御する。
`Container` 内では `anchors` を変更しても効かない（コンテナが上書きする）。

```gdscript
# ✅ フリーレイアウトでの中央配置
control.set_anchors_preset(Control.PRESET_CENTER)

# ✅ 画面いっぱいに広げる
control.set_anchors_preset(Control.PRESET_FULL_RECT)

# ❌ Container 内で anchor を変更（無意味）
# VBoxContainer の子で anchor を変えても VBoxContainer が上書きする
```

---

## 地雷3: CanvasLayer の z-ordering

`CanvasLayer` の `layer` プロパティで描画順を制御する。デフォルトは 0。

```
layer = -1  ← ゲームワールドの後ろ（背景）
layer = 0   ← デフォルト
layer = 1   ← HUD（ゲームワールドの前）
layer = 10  ← ローディング画面・ポップアップ
```

```gdscript
# ✅ HUD は layer=1
$HUD.layer = 1

# ✅ ローディング画面は最前面
$LoadingScreen.layer = 10
```

---

## 地雷4: SubViewport のパフォーマンストラップ

`SubViewport` は別の描画バッファを作成するため**重い**。不用意に使わない。

```
SubViewport が必要な場合:
✅ 3Dをコントロール内に表示（ミニマップ・キャラクタープレビュー）
✅ ポストプロセスエフェクトを一部UIにのみ適用
✅ テクスチャとして使いたい場合

SubViewport を使ってはいけない場合:
❌ 単純なUIのレイヤリング → CanvasLayer を使う
❌ シーン切り替えのトランジション → ColorRect + Tween を使う
```

---

## 地雷5: Label の自動サイズ

```gdscript
# ❌ Label がコンテナからはみ出す
label.autowrap_mode = TextServer.AUTOWRAP_OFF  # デフォルト

# ✅ 折り返しを有効にする
label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

# ✅ または Label のサイズフラグを設定
label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
```

---

## 地雷6: Button のタッチターゲットサイズ

モバイルでは最低 44×44 ピクセルのタッチターゲットが必要。

```gdscript
# ✅ minimum_size で最低サイズを保証
button.custom_minimum_size = Vector2(44, 44)

# ✅ または Theme でデフォルトサイズを設定
```

---

## 地雷7: Container の再計算タイミング

Container はノード追加後に自動的にレイアウトを再計算するが、
フレームをまたぐ処理では `size` がまだ確定していないことがある。

```gdscript
# ❌ _ready() で size を参照（まだ確定していない可能性）
func _ready() -> void:
    print(size)  # Vector2(0, 0) になることがある

# ✅ await でレイアウト確定を待つ
func _ready() -> void:
    await get_tree().process_frame
    print(size)  # 確定済み
```
