## EventBus — Autoload間・シーン間のシグナルハブ
## Autoload同士が直接参照し合うと循環依存が生じるため、このバスを経由する。
## 使い方: EventBus.case_started.emit(case) / EventBus.case_started.connect(_on_case_started)
extends Node

# --- ゲームライフサイクル ---
signal game_paused(is_paused: bool)

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

# --- ゲーム状態遷移 ---
signal game_state_change_requested(new_state: int)

# --- ナラティブ調査 ---
signal case_started(case_data: CaseData)
signal evidence_selected(evidence_id: String)
signal evidence_read(evidence_id: String)
signal countdown_updated(remaining: float)
signal case_resolved(case_id: String, outcome_key: String, read_count: int)

# --- 連鎖推理チェーン ---
signal step_arrived(step_id: String)
signal step_answered(step_id: String, choice_key: String)
signal issue_resolved(issue_id: String)
signal evidence_unlocked(evidence_id: String)
signal investigation_chain_complete(resolved_issue_ids: Array)
signal evidence_cited_correctly(step_id: String, evidence_id: String)
signal evidence_cited_wrongly(step_id: String, evidence_id: String)
