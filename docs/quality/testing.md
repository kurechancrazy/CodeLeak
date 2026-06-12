# Testing — GUT テスト規約・パターン

## GUT の基本

GUT（Godot Unit Testing）は Godot 4 のテストフレームワーク。
テストファイルは `tests/unit/` 以下に配置し、`test_` プレフィックスをつける。

---

## テストファイルの基本構造

```gdscript
# tests/unit/test_save_manager.gd
extends GutTest

var _save_manager: Node = null

func before_each() -> void:
    # 各テスト前に実行
    _save_manager = preload("res://autoloads/save_manager.gd").new()
    add_child_autofree(_save_manager)

func after_each() -> void:
    # テスト用ファイルを削除
    if FileAccess.file_exists("user://test_save.cfg"):
        DirAccess.remove_absolute("user://test_save.cfg")

# ✅ テスト名は test_ プレフィックス + 何をテストするか
func test_save_and_load_high_score() -> void:
    # Arrange
    _save_manager.set_value("player", "high_score", 1500)

    # Act
    _save_manager.save_game()
    _save_manager._save_config = ConfigFile.new()  # リセット
    _save_manager.load_game()

    # Assert
    var loaded_score: int = _save_manager.get_value("player", "high_score", 0)
    assert_eq(loaded_score, 1500, "高スコアが正しく保存・復元されること")

func test_default_value_when_no_save() -> void:
    var score: int = _save_manager.get_value("player", "high_score", 0)
    assert_eq(score, 0, "セーブデータがない場合はデフォルト値を返すこと")

func test_has_save_returns_false_initially() -> void:
    assert_false(_save_manager.has_save(), "初期状態でセーブデータが存在しないこと")
```

---

## GUT のアサーション

```gdscript
# ✅ 使用するアサーション一覧
assert_eq(actual, expected, "説明")          # 等値
assert_ne(actual, expected, "説明")          # 非等値
assert_true(condition, "説明")               # true
assert_false(condition, "説明")              # false
assert_null(value, "説明")                   # null
assert_not_null(value, "説明")               # non-null
assert_gt(actual, expected, "説明")          # greater than
assert_lt(actual, expected, "説明")          # less than
assert_has(collection, item, "説明")         # コレクションに含まれる
assert_does_not_have(collection, item, "説明")

# シグナルテスト
watch_signals(some_node)
some_node.some_signal.emit(42)
assert_signal_emitted(some_node, "some_signal")
assert_signal_emitted_with_parameters(some_node, "some_signal", [42])
```

---

## テストの3区分（全てのファイルに必須）

```gdscript
# 正常系
func test_add_item_successfully() -> void:
    var item: ItemData = ItemData.new()
    item.id = "sword_001"
    var result: bool = _inventory.add_item(item)
    assert_true(result)
    assert_eq(_inventory.items.size(), 1)

# 異常系
func test_add_item_when_full_returns_false() -> void:
    # 満杯にする
    for i: int in range(20):
        var item: ItemData = ItemData.new()
        item.id = "item_%d" % i
        _inventory.add_item(item)
    # 21個目
    var overflow_item: ItemData = ItemData.new()
    overflow_item.id = "overflow"
    var result: bool = _inventory.add_item(overflow_item)
    assert_false(result, "満杯の場合は false を返すこと")

# 境界値
func test_add_item_at_max_capacity() -> void:
    for i: int in range(19):
        var item: ItemData = ItemData.new()
        item.id = "item_%d" % i
        _inventory.add_item(item)
    # 20個目（最大容量）
    var last_item: ItemData = ItemData.new()
    last_item.id = "last"
    var result: bool = _inventory.add_item(last_item)
    assert_true(result, "最大容量ちょうどは成功すること")
    assert_eq(_inventory.items.size(), 20)
```

---

## テストの実行

```bash
# コマンドラインで全テストを実行
godot --headless -s addons/gut/gut_cmdln.gd -gdir=tests/unit -gexit

# 特定のテストファイルのみ
godot --headless -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_save_manager.gd -gexit
```

---

## テスト対象と不要なテスト

| 対象 | テスト | 理由 |
|------|--------|------|
| `scripts/utils/*.gd` | **必須** | 純粋関数は完全にテスト可能 |
| `autoloads/*.gd` のロジック | **必須** | ゲームロジックの核心 |
| スコア・HP・勝敗判定ロジック | **必須** | 純粋計算として切り出してテスト |
| EventBus シグナルの発火 | **必須** | `watch_signals()` で確認 |
| セーブ・ロード | **必須** | テスト用パスを使って確認 |
| `scenes/ui/*.gd` | 任意 | UIはGUT内での検証が複雑 |
| `scenes/game/*.gd` | 任意 | ゲームループは統合テストが適切 |
| 物理演算・Tween・アニメーション | **不要** | 手動確認で対応 |

**ゲーム固有のテストパターン詳細 → `docs/gameplay/testing-game.md`**

---

## Autoload のモック（テスト汚染の防止）

グローバルシングルトンをテスト内で直接使うとテスト間で状態が汚染される。
必ず独立したインスタンスを生成してテストする。

```gdscript
func before_each() -> void:
    # ✅ グローバル GameManager は使わず独立インスタンスを生成
    _game_manager = preload("res://autoloads/game_manager.gd").new()
    add_child_autofree(_game_manager)

# ❌ 禁止: グローバル Autoload を直接使う
# GameManager.score = 0  ← テスト間で状態が汚染される
```
