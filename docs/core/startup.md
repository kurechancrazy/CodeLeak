# Startup — 起動シーケンス・Autoload 初期化順序

## Autoload の初期化順序

Godot は `project.godot` の `[autoload]` セクションに記述された順序で Autoload を初期化する。
**この順序は依存関係を考慮して定義されており、変更する場合はユーザーに確認する。**

```
[autoload]
Logger        ← 最初。全 Autoload がログを使う
EventBus      ← 2番目。全 Autoload がシグナルを使う
GameManager   ← ゲーム状態管理
SceneManager  ← シーン遷移（GameManager に依存しない）
SaveManager   ← 永続化（GameManager に依存）
AudioManager  ← オーディオ（GameManager の設定値を読む）
```

**禁止:** Autoload のコンストラクタ（`_init()`）で他の Autoload を参照する。
`_ready()` でのみ他 Autoload・EventBus を参照すること。

---

## main.tscn の役割

```
main.tscn
└── Main (Node)
    └── main.gd
```

`main.gd` は以下のみを担当する：
1. 初期ロード完了後の最初のシーンへの遷移
2. ロード画面の表示

```gdscript
# scenes/main.gd
extends Node

func _ready() -> void:
    SaveManager.load_game()
    AudioManager.set_master_volume(GameManager.settings.get("master_volume", 1.0))
    await get_tree().process_frame  # Autoload の _ready() 完了を待つ
    SceneManager.go_to("res://scenes/ui/main_menu.tscn", SceneManager.TRANSITION_NONE)
```

---

## 初期化チェックリスト

新しい Autoload を追加する場合：

```
□ project.godot の [autoload] セクションに正しい順序で追加した
□ _ready() でのみ他 Autoload・EventBus を参照している（_init() では参照しない）
□ EventBus に必要なシグナルを追加した
□ docs/core/state-management.md のパターンに従っている
□ Autoload 名が PascalCase になっている（GameManager, SaveManager 等）
□ テストを書いた（tests/unit/test_{name}.gd）
```

---

## デバッグビルドでの起動

```gdscript
# ✅ デバッグビルド時のみ追加処理
func _ready() -> void:
    if OS.is_debug_build():
        Logger.debug("Main._ready: debug mode active")
        _setup_debug_overlay()
```
