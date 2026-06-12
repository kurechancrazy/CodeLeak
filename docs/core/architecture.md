# Architecture — Layer Rules & Data Flow

**対象:** Godot 4.4+ / GDScript 2.0

---

## Claude Code 実装停止チェックリスト

以下のいずれかに該当する場合、**実装を停止してユーザーに確認する**。

```
□ シーンスクリプト（scenes/）にビジネスロジックを書こうとしている
□ Autoload が別 Autoload を直接 call() しようとしている（循環依存）
□ UIシーンがゲームロジックを直接制御しようとしている
□ scripts/utils/ に副作用（ファイルI/O・状態更新）を書こうとしている
□ _process() 内でファイルI/O・重いループを実行しようとしている
□ get_node("../../xxx") のようなハードコードパスを使おうとしている
□ 新しいレイヤー（res:// 第1階層ディレクトリ）を追加しようとしている
□ print() を Logger に変換せず残そうとしている
```

---

## レイヤー構成

```
┌─────────────────────────────────────────────┐
│  Presentation Layer                          │
│  scenes/  （.tscn + 付属スクリプト）          │
│  ・ノード配置・ビジュアル・ユーザー入力受付     │
│  ・シグナルを emit / connect するだけ          │
└────────────────┬────────────────────────────┘
                 │ シグナル経由
┌────────────────▼────────────────────────────┐
│  Application Layer                           │
│  autoloads/  （シングルトン）                 │
│  ・ゲームロジック・状態管理・サービス           │
│  ・GameManager / SceneManager / SaveManager  │
│  ・EventBus 経由でのみ Autoload 間通信        │
└────────────────┬────────────────────────────┘
                 │ 読み書きする
┌────────────────▼────────────────────────────┐
│  Domain Layer                                │
│  scripts/utils/  resources/data/             │
│  ・純粋関数（副作用なし・テスト可能）          │
│  ・カスタムリソース（ItemData等）              │
└─────────────────────────────────────────────┘
```

**依存方向の原則:** Presentation → Application → Domain

---

## レイヤー別 許可・禁止

| レイヤー | 参照可 | 参照禁 | 上限行数 |
|---------|------|------|---------|
| `scenes/` | autoloads（シグナル経由）, scripts/utils, resources | 他のシーンを直接参照 | 100行 |
| `autoloads/` | scripts/utils, resources, EventBus | 他のAutoloadを直接call | 150行 |
| `scripts/utils/` | resources のみ | autoloads, scenes | 80行 |
| `resources/data/` | — （データのみ） | スクリプトロジック | 制限なし |

---

## データフロー

```
ユーザー操作（タップ・キー入力）
  → シーンスクリプト（入力イベント受付）
    → EventBus.xxx.emit() または AutoloadのAPIを呼ぶ
      → Autoload が状態を更新
        → EventBus.yyy.emit() でシーンに通知
          → シーンが表示を更新
```

**禁止:** シーンが Autoload の状態を直接 `set()` する
**禁止:** Autoload が別 Autoload を直接 `call()` する
**禁止:** シーンが他のシーンを `get_node()` で直接参照する

---

## シグナルのエラーハンドリングパターン

Autoload はエラーを外部に throw しない。シグナルで状態として通知する。

```gdscript
# ✅ SaveManager: 成功・失敗をシグナルで通知
func save_game() -> void:
    var err: Error = _config.save(SAVE_PATH)
    var success: bool = err == OK
    if not success:
        Logger.error("Save failed", {"error": err})
    EventBus.save_completed.emit(success)

# ✅ シーン側: 結果シグナルで表示を更新
func _ready() -> void:
    EventBus.save_completed.connect(_on_save_completed)

func _on_save_completed(success: bool) -> void:
    if success:
        show_notification("保存しました")
    else:
        show_notification("保存に失敗しました", "error")
```

---

## バリデーション境界

入力バリデーションを実行する場所は **Autoload の API 入口のみ**。

```gdscript
# ✅ Autoload の API 入口でバリデーション
func set_player_name(name: String) -> bool:
    if name.length() < 1 or name.length() > 20:
        Logger.warn("Invalid player name", {"name": name, "length": name.length()})
        return false
    _player_name = name
    EventBus.settings_changed.emit("player_name", name)
    return true

# ❌ シーンスクリプト内でバリデーション（禁止）
func _on_name_confirmed() -> void:
    if name_input.text.length() < 1:  # ← シーン内バリデーション禁止
        show_error("名前を入力してください")
```

---

## カスタムリソースパターン

```gdscript
# resources/data/item_data.gd
class_name ItemData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var icon: Texture2D = null
@export var value: int = 0

# ✅ .tres ファイルとして保存し、インスペクターで編集可能
# ✅ load("res://resources/data/items/sword.tres") でロード可能
```

**禁止:** カスタムリソースにビジネスロジック（副作用・状態更新）を書く

---

## 2024-2026 Godot 4 モダンパターン

| パターン | 正しい方法 | ❌ 古いパターン |
|---------|---------|-----------|
| ノード間通信 | シグナル（型付き） | `get_parent().some_method()` |
| 型付き配列 | `Array[ItemData]` | `Array` のみ |
| ラムダ関数 | `func(x: int) -> String:` | `FuncRef` |
| 非同期処理 | `await signal` | ポーリング |
| ループ内の生成 | オブジェクトプール | `Node.new()` 毎回 |
| ノード参照 | `@onready var` または `@export` | `get_node("path")` |
| 定数 | `const MAX: int = 100` | マジックナンバー直接記述 |
