# ジャンル一覧・除外マニフェスト

このファイルはテンプレートが対応する全ジャンルの索引と、
不要なジャンルコンポーネントを除外するための手順書です。

---

## 使い方（ゲーム開始時）

```
1. _init.md の初期化フロー実行
2. 下表からジャンルを選ぶ
3. docs/architecture/genre-starters.md の該当バンドルを project.godot に反映
4. docs/genres/{slug}.md を読んで実装開始
5. 使わないジャンルのファイルを「除外手順」に従って削除
```

---

## ジャンル一覧

### 2D ジャンル

| ジャンル | ドキュメント | バンドル # | 固有 Autoload | 固有データ |
|---------|------------|-----------|-------------|---------|
| 2D アクション / プラットフォーマー | `docs/genres/2d-action.md` | 1（既存） | — | — |
| メトロイドヴァニア | `docs/genres/metroidvania.md` | 6 | `map_state_manager` | — |
| 横スクロールシューティング / 弾幕 | `docs/genres/shmup.md` | 7 | `wave_manager` | `wave_data` |
| 見下ろし型アクション RPG | `docs/genres/arpg-topdown.md` | 8 | `quest_manager` | — |
| ターンベース JRPG | `docs/genres/jrpg.md` | 5（既存） | `battle_manager`, `party_manager`, `inventory_manager`, `dialog_manager`, `encounter_manager`, `flag_manager` | `character_data`, `enemy_data`, `item_data`, `skill_data` |
| ローグライク | `docs/genres/roguelike.md` | 9 | `run_manager` | `room_data` |
| タワーディフェンス | `docs/genres/tower-defense.md` | 10 | `wave_manager` | `wave_data`, `tower_data` |
| SRPG（シミュレーション RPG） | `docs/genres/srpg.md` | 11 | — | — |
| 農業 / 生活シム | `docs/genres/farming-sim.md` | 12 | `time_manager` | `crop_data` |
| カードゲーム / デッキビルダー | `docs/genres/card-game.md` | 13 | `deck_manager` | `card_data` |
| 格闘 | `docs/genres/fighting.md` | 14 | `input_buffer` | — |
| ホラー / サバイバル（2D） | `docs/genres/horror-2d.md` | 15 | — | — |
| パズル | `docs/genres/puzzle.md` | 2（既存） | — | — |
| ビジュアルノベル | `docs/genres/visual-novel.md` | 4（既存） | — | — |
| ベルトスクロールアクション | `docs/genres/belt-scroll-action.md` | 1（兼用） | — | — |
| ステルスゲーム | `docs/genres/stealth.md` | 1（兼用） | — | — |
| ポイント・アンド・クリック ADV | `docs/genres/point-and-click.md` | 4（兼用） | `flag_manager` | — |
| 落ち物パズル | `docs/genres/falling-puzzle.md` | 4（兼用） | — | — |
| マッチ3パズル | `docs/genres/match3.md` | 4（兼用） | — | — |
| スポーツゲーム | `docs/genres/sports.md` | 1（兼用） | — | — |
| 音楽 / リズム（音ゲー） | `docs/genres/rhythm.md` | 4（兼用） | — | — |
| サンドボックス / クラフト | `docs/genres/sandbox-craft.md` | 1（兼用） | — | — |
| パーティーゲーム | `docs/genres/party-game.md` | 4（兼用） | — | — |
| クイズゲーム | `docs/genres/quiz.md` | 4（兼用） | — | — |
| 放置 / クリッカーゲーム | `docs/genres/idle-clicker.md` | 4（兼用） | — | — |

### 3D ジャンル

| ジャンル | ドキュメント | バンドル # | 固有 Autoload | 固有データ |
|---------|------------|-----------|-------------|---------|
| 3D プラットフォーマー | `docs/genres/3d-platformer.md` | 16 | — | — |
| 3D 探索 / ウォーキングシム | `docs/genres/exploration-3d.md` | 16（兼用） | — | — |
| 3D アクション / アドベンチャー | `docs/genres/3d-action.md` | 17 | `input_buffer` | — |
| FPS / TPS | `docs/genres/fps-tps.md` | 18 | — | `weapon_data` |
| 3D RPG / オープンワールド | `docs/genres/3d-rpg.md` | 19 | `quest_manager`, `time_manager`, `dialog_manager` | — |
| 3D ストラテジー / RTS | `docs/genres/3d-strategy.md` | 20 | — | `unit_data` |
| 3D レース | `docs/genres/3d-race.md` | 21 | `race_manager` | — |
| 3D ホラー / サバイバル | `docs/genres/3d-horror.md` | 22 | `time_manager` | — |
| 3D パズル | `docs/genres/3d-puzzle.md` | 23 | — | — |

---

## 共通コンポーネント（複数ジャンルで共有）

削除する場合は、使用している全ジャンルを外してから行うこと。

| ファイル | 使用ジャンル |
|---------|------------|
| `scripts/utils/grid_utils.gd` | SRPG, タワーディフェンス, 農業シム, パズル |
| `scripts/utils/rng_utils.gd` | ローグライク, シューティング, 農業シム |
| `autoloads/wave_manager.gd` | シューティング, タワーディフェンス |
| `autoloads/time_manager.gd` | 農業シム, 3D RPG, 3D ホラー |
| `autoloads/input_buffer.gd` | 格闘, 3D アクション |
| `autoloads/progress_manager.gd` | 全ジャンル（実績・解放管理） |

---

## 一括除外手順

### 特定ジャンルを除外する場合

1. 該当ジャンルの `docs/genres/{slug}.md` の「除外手順」セクションを確認
2. 記載ファイルを削除（他ジャンルでも使用中のファイルは残す）
3. `project.godot` の `[autoload]` セクションから該当エントリを削除
4. `CLAUDE.md` のタスク別テーブルから該当行を削除（任意）

### 全ジャンル固有コンポーネントを除外して「ミニマル」構成にする場合

残すもの（コア）:
```
autoloads/game_manager.gd
autoloads/event_bus.gd
autoloads/audio_manager.gd
autoloads/save_manager.gd
autoloads/scene_manager.gd
autoloads/logger.gd
scripts/utils/math_utils.gd
scripts/utils/object_pool.gd
scripts/data/game_settings.gd
```

削除できるもの（ジャンル固有・共通コンポーネント全て）:
```
autoloads/battle_manager.gd
autoloads/party_manager.gd
autoloads/inventory_manager.gd
autoloads/dialog_manager.gd
autoloads/encounter_manager.gd
autoloads/flag_manager.gd
autoloads/wave_manager.gd
autoloads/time_manager.gd
autoloads/input_buffer.gd
autoloads/progress_manager.gd
scripts/data/character_data.gd
scripts/data/enemy_data.gd
scripts/data/item_data.gd
scripts/data/skill_data.gd
scripts/data/wave_data.gd
scripts/utils/grid_utils.gd
scripts/utils/rng_utils.gd
tests/unit/test_character_data.gd
tests/unit/test_enemy_data.gd
tests/unit/test_item_data.gd
tests/unit/test_skill_data.gd
tests/unit/test_wave_manager.gd
tests/unit/test_time_manager.gd
tests/unit/test_input_buffer.gd
tests/unit/test_progress_manager.gd
tests/unit/test_grid_utils.gd
tests/unit/test_rng_utils.gd
docs/genres/（フォルダごと）
docs/rpg/（フォルダごと）
```
