## EventBus — Autoload間・シーン間のシグナルハブ
## Autoload同士が直接参照し合うと循環依存が生じるため、このバスを経由する。
## 使い方: EventBus.player_died.emit() / EventBus.player_died.connect(_on_player_died)
extends Node

# --- ゲームライフサイクル ---
signal game_started
signal game_paused(is_paused: bool)
signal game_over(score: int)

# --- シーン遷移 ---
signal scene_change_requested(scene_path: String, transition: String)
signal scene_loaded(scene_path: String)

# --- セーブ / ロード ---
signal save_requested
signal load_requested
signal save_completed(success: bool)

# --- UI ---
signal notification_requested(message: String, type: String)
signal loading_started(label: String)
signal loading_finished

# --- オーディオ ---
signal bgm_change_requested(track_name: String)
signal sfx_play_requested(sound_name: String)

# --- 設定 ---
signal settings_changed(key: String, value: Variant)

# --- RPG: パーティー・インベントリ ---
signal party_status_changed
signal inventory_changed
signal item_used(item_id: String, target_id: String)
signal item_use_requested(item_id: String, target_id: String)

# --- RPG: 戦闘 ---
signal battle_started(enemies: Array)
signal battle_execution_started
signal turn_started(actor_id: String)
signal battle_ended(victory: bool)
signal item_dropped(item_id: String)
signal exp_gained(amount: int)
signal gold_gained(amount: int)

# --- RPG: フィールド ---
signal player_moved
signal area_entered(area_id: String)

# --- RPG: ダイアログ ---
signal dialog_requested(dialog_id: String)
signal dialog_ended(dialog_id: String)
signal dialog_page_shown(speaker: String, portrait: String, text: String, choices: Variant)

# --- ウェーブ管理（シューティング・タワーディフェンス） ---
signal wave_started(wave_num: int)
signal wave_completed(wave_num: int)
signal all_waves_completed

# --- 実績・進捗（全ジャンル共通） ---
signal achievement_unlocked(achievement_id: String)
signal progress_updated(key: String)

# --- ゲーム状態遷移（Autoload間の直接メソッド呼び出しを避けるためのブリッジ） ---
signal game_state_change_requested(new_state: int)

# --- パズル ---
signal puzzle_loaded(puzzle: PuzzleData)
signal line_selected(line_index: int)
signal answer_submitted(correct: bool, explanation: String)
signal hint_requested
signal hint_applied(line_index: int)
signal puzzle_completed(score: int, miss_count: int, elapsed_time: float)
signal level_cleared
signal level_restarted
