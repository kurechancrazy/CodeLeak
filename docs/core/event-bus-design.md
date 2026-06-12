# EventBus 設計ガイド — シグナルの追加・整理・分割

**対象:** Godot 4.4+ / GDScript 2.0

---

## Claude Code 実装停止チェックリスト

```
□ EventBus に追加しようとしているシグナルが、既存シグナルと重複または類似している
□ シグナルのパラメータ型が Variant になっている（具体型を使えるはず）
□ シグナル名が命令形になっている（"play_sfx" ではなく "sfx_play_requested"）
□ 1つのシグナルに3つ以上のパラメータがある（Dictionary / Resource 化を検討）
□ EventBus のシグナル数が30本を超えている（分割を検討）
```

---

## シグナルを追加するタイミング

| 状況 | 追加するか | 理由 |
|------|----------|------|
| Autoload が別 Autoload に通知したい | **追加する** | 直接参照は循環依存になる |
| シーンが Autoload に通知したい | **追加する** | Autoload への直接呼び出しを避ける |
| 複数のシーンが同じイベントを購読する | **追加する** | 一対多の通知に最適 |
| 同一シーン内の親子間で通知したい | **追加しない** | ローカルシグナルで十分 |
| Autoload がシーンを直接操作したい | **追加しない** | シーンが Autoload を購読する設計に変える |

---

## 命名規則（厳守）

| パターン | 用途 | 例 |
|---------|------|-----|
| `[名詞]_[過去分詞]` | 何かが起きた通知 | `player_died`, `item_collected`, `stage_cleared` |
| `[名詞]_changed` | 状態が変わった通知 | `health_changed(new_value: int)`, `score_updated` |
| `[動詞]_requested` | 何かをしてほしい要求（EventBus専用） | `save_requested`, `scene_change_requested` |

**禁止:**
- 命令形 (`play_sfx`, `show_ui`) → `sfx_play_requested`, `ui_show_requested`
- 曖昧な名前 (`event_fired`, `update_happened`)
- 省略形 (`plr_died`, `scn_chgd`)

---

## パラメータ設計

### 少数パラメータ（3つ未満）→ 直接列挙

```gdscript
# ✅ 明確なパラメータ
signal health_changed(new_health: int, max_health: int)
signal enemy_defeated(enemy_id: String, position: Vector2)
```

### 多数パラメータ（3つ以上）→ Dictionary または Resource

```gdscript
# ❌ パラメータが多すぎる
signal item_picked_up(item_id: String, item_name: String, quantity: int, position: Vector2, rarity: int)

# ✅ Dictionary にまとめる
signal item_picked_up(item_data: Dictionary)
# → emit: EventBus.item_picked_up.emit({"id": "sword", "name": "剣", "qty": 1, ...})

# ✅ より型安全: Resource クラスを定義する
signal item_picked_up(item: ItemData)
```

---

## EventBus にシグナルを追加する手順

**1. カテゴリを確認する（コメントブロックで整理する）**

```gdscript
# event_bus.gd のカテゴリ構成
# --- ゲームライフサイクル ---    ← game_started, game_over 等
# --- シーン遷移 ---             ← scene_change_requested 等
# --- セーブ / ロード ---        ← save_requested 等
# --- UI ---                    ← notification_requested 等
# --- オーディオ ---             ← bgm_change_requested 等
# --- 設定 ---                  ← settings_changed
# --- [ゲーム固有] ---          ← 新規追加はここに
```

**2. シグナルを定義する**

```gdscript
# --- [ゲーム固有] ---
signal enemy_spawned(enemy_id: String, position: Vector2)
signal enemy_defeated(enemy_id: String)
signal player_level_up(new_level: int)
```

**3. 発行元と購読先を記録する（コメントで）**

```gdscript
## 発行: EnemySpawner / 購読: HUD, StageManager
signal enemy_spawned(enemy_id: String, position: Vector2)
```

**4. 購読側で必ず `_exit_tree()` に disconnect を追加する**

```gdscript
func _ready() -> void:
    EventBus.enemy_defeated.connect(_on_enemy_defeated)

func _exit_tree() -> void:
    EventBus.enemy_defeated.disconnect(_on_enemy_defeated)
```

---

## EventBus の分割タイミング

**以下の兆候が出たら分割を検討する:**

| 兆候 | 目安 |
|------|------|
| シグナル数が多い | 30本以上 |
| 特定のシグナル群が特定の Autoload にしか使われない | 5本以上の専用シグナル |
| チームが「どこに追加するか迷う」状態が続く | 即時検討 |

**分割パターン:**

```
EventBus（汎用ハブ）
├── CombatBus（戦闘専用）  → autoloads/combat_bus.gd
├── UiBus（UI専用）        → autoloads/ui_bus.gd
└── ShopBus（商店専用）    → autoloads/shop_bus.gd
```

**分割時の注意:**
- 分割先の Bus も Autoload として登録する
- Bus 間の通信は禁止（親 Bus を経由するか設計を見直す）
- 分割は「関心事の境界」で行う。ファイルサイズだけで分割しない

---

## よくある間違いパターン

```gdscript
# ❌ シグナルを購読したまま削除（メモリリーク・二重接続）
func _ready() -> void:
    EventBus.game_over.connect(_on_game_over)
# _exit_tree() なし → ホットリロード時に二重接続

# ❌ Autoload が直接 Autoload を呼ぶ（EventBus を使わない）
func _on_player_died() -> void:
    AudioManager.play_sfx("death")  # ← EventBus.sfx_play_requested.emit("death") が正しい

# ❌ ローカルシグナルで済む場面に EventBus を使う
# シーン内の Button.pressed → 同シーンの _on_button_pressed
# → ローカルシグナル接続で十分。EventBus 不要。
```
