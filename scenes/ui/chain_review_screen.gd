## ChainReviewScreen — 連鎖推理チェーン完了後のレビュー画面
## 全ステップの選択と課題解決数を一括表示し、最終判定へ進む。
extends MarginContainer

var _COLOR_TEXT: Color = Color.html("#00ff41")
var _COLOR_BG: Color = Color.html("#0d0d0d")
var _COLOR_DIM: Color = Color.html("#555555")
var _COLOR_RESOLVED: Color = Color.html("#00ff41")
var _COLOR_UNRESOLVED: Color = Color.html("#555555")
var _COLOR_TIMEOUT: Color = Color.html("#ff4444")

var _input_locked: bool = true
var _verdict_btn: Button


func _ready() -> void:
	if CaseManager.current_case == null:
		EventBus.scene_change_requested.emit("res://scenes/ui/case_select_screen.tscn", "fade")
		return
	GameManager.transition_to(GameManager.GameState.CHAIN_REVIEW)
	_build_layout()
	_input_locked = true
	get_tree().create_timer(0.4).timeout.connect(
		func() -> void:
			_input_locked = false
			if _verdict_btn != null:
				_verdict_btn.grab_focus()
	)


func _build_layout() -> void:
	var case_data: CaseData = CaseManager.current_case
	var summary: Array[Dictionary] = CaseManager.get_chain_summary()
	var resolved_count: int = CaseManager.resolved_issue_ids.size()
	var total_issues: int = case_data.resolvable_issues.size()

	var bg: ColorRect = ColorRect.new()
	bg.color = _COLOR_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)

	var outer_vbox: VBoxContainer = VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 16)
	margin.add_child(outer_vbox)

	# ヘッダー: INVESTIGATION COMPLETE
	var title: Label = Label.new()
	title.text = tr("CHAIN_REVIEW_TITLE")
	title.add_theme_color_override("font_color", _COLOR_TEXT)
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer_vbox.add_child(title)

	# 課題解決数
	var issues_label: Label = Label.new()
	issues_label.text = tr("CHAIN_REVIEW_ISSUES_IDENTIFIED") % [resolved_count, total_issues]
	issues_label.add_theme_color_override("font_color", _COLOR_TEXT)
	issues_label.add_theme_font_size_override("font_size", 26)
	issues_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer_vbox.add_child(issues_label)

	# 獲得ポイント
	var score_label: Label = Label.new()
	score_label.text = tr("CHAIN_REVIEW_SCORE") % CaseManager.total_points
	score_label.add_theme_color_override("font_color", _COLOR_TEXT)
	score_label.add_theme_font_size_override("font_size", 22)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer_vbox.add_child(score_label)

	var sep: HSeparator = HSeparator.new()
	outer_vbox.add_child(sep)

	# スクロール可能なステップ履歴リスト
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_vbox.add_child(scroll)

	var list_vbox: VBoxContainer = VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 10)
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_vbox)

	var step_num: int = 1
	for entry: Dictionary in summary:
		var step_id: String = entry.get("step_id", "")
		var choice_key: String = entry.get("choice_key", "")
		var resolved_issue_id: String = entry.get("resolved_issue_id", "")
		var points_earned: int = entry.get("points_earned", 0)
		var timed_out: bool = entry.get("timed_out", false)
		var cited_evidence_id: String = entry.get("cited_evidence_id", "")

		var step: InvestigationStep = case_data.get_step_by_id(step_id)

		var row_vbox: VBoxContainer = VBoxContainer.new()
		row_vbox.add_theme_constant_override("separation", 3)
		list_vbox.add_child(row_vbox)

		# ステップ番号 + 質問概要
		var question_text: String = ""
		if step != null:
			question_text = step.get_question()
			if question_text.length() > 60:
				question_text = question_text.substr(0, 57) + "..."

		var q_label: Label = Label.new()
		q_label.text = "[%d] %s" % [step_num, question_text]
		q_label.add_theme_color_override("font_color", _COLOR_DIM)
		q_label.add_theme_font_size_override("font_size", 14)
		q_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row_vbox.add_child(q_label)

		# 選択肢と解決状態
		var choice_label_text: String = ""
		var row_color: Color = _COLOR_UNRESOLVED

		if timed_out:
			choice_label_text = "  -> " + tr("CHAIN_REVIEW_STEP_TIMEOUT")
			row_color = _COLOR_TIMEOUT
		else:
			# 選択肢ラベルを取得
			var chosen_label: String = choice_key
			if step != null:
				var sc: StepChoice = step.get_choice_by_key(choice_key)
				if sc != null:
					chosen_label = sc.get_label()

			var pts_tag: String = " [+%dpt]" % points_earned if points_earned > 0 else ""
			if not resolved_issue_id.is_empty():
				var issue: CaseIssue = case_data.get_issue_by_id(resolved_issue_id)
				var issue_desc: String = resolved_issue_id
				if issue != null:
					issue_desc = issue.get_description()
				choice_label_text = "  -> %s%s  [+] %s" % [chosen_label, pts_tag, issue_desc]
				row_color = _COLOR_RESOLVED
			else:
				choice_label_text = "  -> %s%s" % [chosen_label, pts_tag]
				row_color = _COLOR_UNRESOLVED if points_earned == 0 else _COLOR_TEXT

		var c_label: Label = Label.new()
		c_label.text = choice_label_text
		c_label.add_theme_color_override("font_color", row_color)
		c_label.add_theme_font_size_override("font_size", 15)
		c_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row_vbox.add_child(c_label)

		var cite_label: Label = Label.new()
		if cited_evidence_id.is_empty():
			cite_label.text = "  —"
			cite_label.add_theme_color_override("font_color", _COLOR_DIM)
		else:
			var ev_title: String = cited_evidence_id
			if case_data.evidence != null:
				for ev: EvidenceItem in case_data.evidence:
					if ev.evidence_id == cited_evidence_id:
						ev_title = ev.get_title()
						break
			cite_label.text = "  " + tr("CHAIN_REVIEW_CITATION") % ev_title
			cite_label.add_theme_color_override("font_color", _COLOR_RESOLVED)
		cite_label.add_theme_font_size_override("font_size", 13)
		row_vbox.add_child(cite_label)

		step_num += 1

	# セパレーター
	var sep2: HSeparator = HSeparator.new()
	outer_vbox.add_child(sep2)

	# VERDICTボタン
	_verdict_btn = Button.new()
	_verdict_btn.text = tr("CHAIN_REVIEW_VERDICT_BTN")
	_verdict_btn.flat = true
	_verdict_btn.custom_minimum_size = Vector2(300, 52)
	_verdict_btn.add_theme_color_override("font_color", _COLOR_TEXT)
	_verdict_btn.add_theme_font_size_override("font_size", 22)
	_verdict_btn.pressed.connect(_on_verdict_pressed)
	outer_vbox.add_child(_verdict_btn)


func _on_verdict_pressed() -> void:
	if _input_locked:
		return
	_input_locked = true
	CaseManager.selected_verdict = CaseManager.determine_outcome()
	EventBus.scene_change_requested.emit("res://scenes/ui/outcome_screen.tscn", "fade")


func _input(event: InputEvent) -> void:
	# 判定確定後は戻れない
	if event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		return
	if _input_locked:
		return
	if event.is_action_pressed("confirm"):
		_on_verdict_pressed()
		get_viewport().set_input_as_handled()
