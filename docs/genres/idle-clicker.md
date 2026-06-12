# アイドル / クリッカー — ジャンルガイド

**次元:** UI 専用  
**genre-starters.md:** バンドル 4

---

## コアループ

クリック/タップで通貨を獲得し、自動生産設備をアップグレードして収入を増やす。
通貨蓄積ループ・オフライン収益・プレステージ（リセット）が核心。

---

## シーン階層

```
IdleGame (Node2D)
└── UI (CanvasLayer)
    ├── CurrencyPanel (HBoxContainer)
    │   ├── CurrencyIcon (TextureRect)
    │   └── CurrencyLabel (Label)            — "1,234,567 コイン"
    ├── ClickButton (TextureButton)           — 中央の大きなクリック対象
    ├── ClickParticle (GPUParticles2D)        — クリック時のエフェクト
    ├── ProducerList (ScrollContainer)
    │   └── VBoxContainer
    │       └── ProducerItem × n (HBoxContainer)
    │           ├── NameLabel (Label)
    │           ├── CountLabel (Label)        — 所持数
    │           ├── CostLabel (Label)
    │           └── BuyButton (Button)
    └── PrestigePanel (PanelContainer)        — プレステージ条件満了時に表示
```

---

## 必須 Autoload

| Autoload | 役割 |
|---------|------|
| SaveManager | セーブ・ロード・オフライン収益計算 |

---

## 主要実装パターン

### 通貨 + 自動生産ループ（Timer 使用）

```gdscript
# idle_manager.gd（Node として IdleGame の子に置く）
class_name IdleManager
extends Node

var currency: float = 0.0
var currency_per_second: float = 0.0
var click_power: float = 1.0

var _producers: Array[ProducerData] = []

@onready var _income_timer: Timer = $IncomeTimer   # wait_time = 1.0, autostart = true

func _ready() -> void:
    _income_timer.timeout.connect(_on_income_timer_timeout)

func _on_income_timer_timeout() -> void:
    if currency_per_second > 0.0:
        add_currency(currency_per_second)

func add_currency(amount: float) -> void:
    currency += amount
    EventBus.currency_changed.emit(currency)

func on_click() -> void:
    add_currency(click_power)
    EventBus.click_happened.emit()

func recalculate_cps() -> void:
    var total: float = 0.0
    for producer: ProducerData in _producers:
        total += producer.cps_per_unit * float(producer.owned_count)
    currency_per_second = total
    EventBus.cps_changed.emit(currency_per_second)
```

### 生産者データ + アップグレード購入

```gdscript
# producer_data.gd
class_name ProducerData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var base_cost: float = 10.0
@export var cps_per_unit: float = 0.1
@export var cost_multiplier: float = 1.15   # 購入ごとに 1.15 倍

var owned_count: int = 0

func get_current_cost() -> float:
    return base_cost * pow(cost_multiplier, float(owned_count))

func buy_one(manager: IdleManager) -> bool:
    var cost: float = get_current_cost()
    if manager.currency < cost:
        return false
    manager.currency -= cost
    owned_count += 1
    manager.recalculate_cps()
    EventBus.currency_changed.emit(manager.currency)
    return true
```

### オフライン収益 + SaveManager 統合

```gdscript
# idle_manager.gd（続き）
const OFFLINE_EFFICIENCY: float = 0.5       # オフライン中は通常収益の 50%
const MAX_OFFLINE_SECONDS: float = 86400.0  # 最大 24 時間

func save_state() -> Dictionary:
    var producer_states: Array[Dictionary] = []
    for p: ProducerData in _producers:
        producer_states.append({"id": p.id, "count": p.owned_count})
    return {
        "currency": currency,
        "cps": currency_per_second,
        "click_power": click_power,
        "last_save_unix": Time.get_unix_time_from_system(),
        "producers": producer_states,
    }

func load_state(data: Dictionary) -> void:
    currency = data.get("currency", 0.0)
    currency_per_second = data.get("cps", 0.0)
    click_power = data.get("click_power", 1.0)
    # オフライン収益を計算
    var last_save: float = data.get("last_save_unix", Time.get_unix_time_from_system())
    var elapsed: float = Time.get_unix_time_from_system() - last_save
    elapsed = clampf(elapsed, 0.0, MAX_OFFLINE_SECONDS)
    var offline_gain: float = currency_per_second * elapsed * OFFLINE_EFFICIENCY
    if offline_gain > 0.0:
        add_currency(offline_gain)
        EventBus.offline_income_applied.emit(offline_gain)
```

### 通貨の指数表記フォーマット

```gdscript
# currency_formatter.gd（静的ユーティリティ）
class_name CurrencyFormatter
extends RefCounted

static func format(value: float) -> String:
    if value < 1_000.0:
        return str(int(value))
    elif value < 1_000_000.0:
        return "%.1fK" % (value / 1_000.0)
    elif value < 1_000_000_000.0:
        return "%.1fM" % (value / 1_000_000.0)
    else:
        return "%.2e" % value   # 精度が失われる領域では指数表記
```

---

## よくある地雷

- `_process()` で毎フレーム通貨を加算すると `delta` 累積の誤差でフレームレート依存の収益ブレが起きる → `Timer`（wait_time = 1.0）で 1 秒ごとに加算する
- `pow(cost_multiplier, owned_count)` は `owned_count` が大きくなると `float` の精度が失われ購入コストがズレる → 表示は `CurrencyFormatter.format()` で指数表記にする
- オフライン時間に上限を設けないとゲームバランスが壊れる → `clampf(elapsed, 0.0, MAX_OFFLINE_SECONDS)` で必ず上限を設定する
- `add_currency()` の呼び出しごとに `EventBus.currency_changed` が飛び、大量の UI 更新が走る → フレームをまとめて `_process` 末尾で一括 emit する設計にするとパフォーマンスが改善する
- プレステージ後に `_producers` の `owned_count` をリセットし忘れると CPS が誤った値のまま残る → `recalculate_cps()` を必ずリセット後に呼ぶ

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/idle-clicker.md` | このファイル |
| Autoload | なし（コアのみ使用） | — |

project.godot から追加で削除するエントリなし（このジャンルは追加 Autoload を持たない）。
