# ターンベース JRPG — ジャンルガイド

**次元:** 2D（ドット絵）  
**genre-starters.md:** バンドル 5

---

## 詳細ドキュメント

JRPG は他ジャンルに比べてサブシステムが多いため、以下に専用ドキュメントを用意している。  
実装前に必ず読むこと。

| 実装内容 | 読むドキュメント |
|---------|----------------|
| ドット絵プロジェクト設定 | `docs/rpg/pixel-art-setup.md` |
| ターンベース戦闘の設計・実装 | `docs/rpg/battle-system.md` |
| フィールドマップ・ランダムエンカウント | `docs/rpg/field-system.md` |
| NPC 会話・テキストボックス | `docs/rpg/dialog-system.md` |
| RPG メニュー（アイテム・装備・ステータス） | `docs/rpg/menu-system.md` |

---

## コアループ

フィールドを歩いてエンカウント → ターン制コマンド戦闘 →
経験値・ゴールドを得て成長 → 新エリアへ進む。

---

## 必須 Autoload（JRPG 固有）

| Autoload | ファイル | 役割 |
|---------|---------|------|
| PartyManager | `autoloads/party_manager.gd` | パーティー編成・HP/MP 管理 |
| InventoryManager | `autoloads/inventory_manager.gd` | アイテム・装備管理 |
| BattleManager | `autoloads/battle_manager.gd` | 戦闘フェーズ管理 |
| EncounterManager | `autoloads/encounter_manager.gd` | ランダムエンカウント判定 |
| DialogManager | `autoloads/dialog_manager.gd` | NPC 会話 |
| FlagManager | `autoloads/flag_manager.gd` | 進行フラグ |

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル |
|------|---------|
| ドキュメント | `docs/genres/jrpg.md`, `docs/rpg/`（フォルダごと） |
| Autoload | `autoloads/battle_manager.gd`, `autoloads/party_manager.gd`, `autoloads/inventory_manager.gd`, `autoloads/dialog_manager.gd`, `autoloads/encounter_manager.gd`, `autoloads/flag_manager.gd` |
| データ | `scripts/data/character_data.gd`, `scripts/data/enemy_data.gd`, `scripts/data/item_data.gd`, `scripts/data/skill_data.gd` |
| テスト | `tests/unit/test_character_data.gd`, `tests/unit/test_enemy_data.gd`, `tests/unit/test_item_data.gd`, `tests/unit/test_skill_data.gd` |

```ini
; project.godot [autoload] から削除
PartyManager="*res://autoloads/party_manager.gd"
InventoryManager="*res://autoloads/inventory_manager.gd"
BattleManager="*res://autoloads/battle_manager.gd"
EncounterManager="*res://autoloads/encounter_manager.gd"
DialogManager="*res://autoloads/dialog_manager.gd"
FlagManager="*res://autoloads/flag_manager.gd"
```
