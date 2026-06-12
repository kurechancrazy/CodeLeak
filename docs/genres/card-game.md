# カードゲーム / デッキビルダー — ジャンルガイド

**次元:** 2D（UI 中心）  
**genre-starters.md:** バンドル 13

---

## コアループ

デッキからカードを引き、手札からカードを使ってエネルギーを消費し、
敵を倒す → 報酬カードでデッキを強化 → 繰り返す。

---

## シーン階層

```
BattleScene (Control)
├── EnemyArea (HBoxContainer)
│   └── EnemyCard × n (PanelContainer)
├── PlayerArea (VBoxContainer)
│   ├── HandContainer (HBoxContainer)  — ドラッグ可能なカードを配置
│   ├── EnergyLabel
│   └── EndTurnButton
├── DeckPileBtn (Button)    — 山札枚数表示
├── DiscardPileBtn (Button) — 捨て山枚数表示
└── CardDetailPopup (PopupPanel)  — ホバー時の拡大表示
```

---

## 必須 Autoload

| Autoload | ファイル | 役割 |
|---------|---------|------|
| DeckManager | `autoloads/deck_manager.gd` | 山札・手札・捨て山の管理 |

---

## 主要実装パターン

### DeckManager の構造

```gdscript
# autoloads/deck_manager.gd（スタブ）
var deck: Array[CardData] = []     # 山札（シャッフル済み）
var hand: Array[CardData] = []     # 手札
var discard: Array[CardData] = []  # 捨て山

func draw(count: int = 1) -> void:
    for _i: int in count:
        if deck.is_empty():
            _reshuffle_discard()
        if deck.is_empty():
            return
        hand.append(deck.pop_back())
    EventBus.inventory_changed.emit()   # 手札変更通知

func play_card(index: int, target: Node) -> bool:
    if index >= hand.size():
        return false
    var card: CardData = hand[index]
    if not _has_enough_energy(card.cost):
        return false
    _spend_energy(card.cost)
    card.apply_effect(target)
    discard.append(hand.pop_at(index))
    EventBus.inventory_changed.emit()
    return true

func _reshuffle_discard() -> void:
    deck = RngUtils.shuffled(discard) as Array[CardData]
    discard.clear()
```

### カードのドラッグ & ドロップ

```gdscript
# CardUI.gd
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.pressed:
            _dragging = true
            _drag_offset = global_position - event.position
        else:
            _dragging = false
            _try_play_card()
    if _dragging and event is InputEventMouseMotion:
        global_position = event.position + _drag_offset
```

### カードエフェクト（データ駆動）

```gdscript
# CardData.gd (Resource)
@export var effect_type: String = ""  # "damage", "heal", "buff"
@export var effect_value: int = 0

func apply_effect(target: Node) -> void:
    match effect_type:
        "damage": target.take_damage(effect_value)
        "heal":   target.heal(effect_value)
```

---

## よくある地雷

- 山札シャッフルを `Array.shuffle()` で直接やると同期問題 → `RngUtils.shuffled()` でコピーを返す
- ドラッグ中に `z_index` を上げないと他のカードに隠れる
- デッキ構築画面と戦闘画面で `DeckManager` の状態が混在しないよう、戦闘開始時に山札をコピーする

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/card-game.md` | このファイル |
| Autoload | `autoloads/deck_manager.gd`（作成した場合） | — |
| ユーティリティ | `scripts/utils/rng_utils.gd` | ローグライクでも使用 |

```ini
; project.godot [autoload] から削除
DeckManager="*res://autoloads/deck_manager.gd"
```
