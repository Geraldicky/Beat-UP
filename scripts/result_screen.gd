extends Control

const ThemeConfigScript = preload("res://config/theme_config.gd")
const LayoutConfigScript = preload("res://config/ui_layout_config.gd")
const ResultConfigScript = preload("res://config/result_config.gd")
const MinimalThemeScript = preload("res://scripts/ui/minimal_theme.gd")
const InteractionPolishScript = preload("res://scripts/ui/interaction_polish.gd")

signal back_requested
signal replay_requested

@export var theme_config: ThemeConfigScript
@export var layout_config: LayoutConfigScript
@export var result_config: ResultConfigScript

@onready var backdrop: Control = %Backdrop
@onready var top_accent: ColorRect = %TopAccent
@onready var main_margin: MarginContainer = %MainMargin
@onready var root_vbox: VBoxContainer = %RootVBox
@onready var header_bar: HBoxContainer = %HeaderBar
@onready var page_title: Label = %PageTitle
@onready var song_title: Label = %SongTitle
@onready var song_meta: Label = %SongMeta
@onready var best_plate: PanelContainer = %BestPlate
@onready var new_best: Label = %NewBest
@onready var content: HBoxContainer = %Content
@onready var rank_panel: PanelContainer = %RankPanel
@onready var rank_column: VBoxContainer = %RankColumn
@onready var rank_stack: Control = %RankStack
@onready var rank_meter: Control = %RankMeter
@onready var rank_value: Label = %RankValue
@onready var rank_sub: Label = %RankSub
@onready var stats_column: VBoxContainer = %StatsColumn
@onready var score_panel: PanelContainer = %ScorePanel
@onready var score_vbox: VBoxContainer = %ScoreVBox
@onready var score_status: Label = %ScoreStatus
@onready var score_value: Label = %ScoreValue
@onready var primary_stats: HBoxContainer = %PrimaryStats
@onready var accuracy_card: PanelContainer = %AccuracyCard
@onready var combo_card: PanelContainer = %ComboCard
@onready var perfect_rate_card: PanelContainer = %PerfectRateCard
@onready var accuracy_value: Label = %AccuracyValue
@onready var accuracy_bar: ProgressBar = %AccuracyBar
@onready var combo_value: Label = %ComboValue
@onready var perfect_rate_value: Label = %PerfectRateValue
@onready var breakdown_panel: PanelContainer = %BreakdownPanel
@onready var judgement_bar: Control = %JudgementBar
@onready var judged_value: Label = %JudgedValue
@onready var perfect_title: Label = %PerfectTitle
@onready var great_title: Label = %GreatTitle
@onready var good_title: Label = %GoodTitle
@onready var miss_title: Label = %MissTitle
@onready var perfect_value: Label = %PerfectValue
@onready var great_value: Label = %GreatValue
@onready var good_value: Label = %GoodValue
@onready var miss_value: Label = %MissValue
@onready var special_panel: PanelContainer = %SpecialPanel
@onready var special_row: HBoxContainer = %SpecialRow
@onready var space_value: Label = %SpaceValue
@onready var space_meta: Label = %SpaceMeta
@onready var reverse_value: Label = %ReverseValue
@onready var reverse_meta: Label = %ReverseMeta
@onready var bottom_bar: HBoxContainer = %BottomBar
@onready var back_button: Button = %BackButton
@onready var replay_button: Button = %ReplayButton

var _score_target := 0
var _accuracy_target := 0.0
var _combo_target := 0
var _perfect_rate_target := 0.0
var _perfect_target := 0
var _great_target := 0
var _good_target := 0
var _miss_target := 0
var _space_target := 0
var _space_total_target := 0
var _reverse_target := 0
var _reverse_total_target := 0
var _reverse_miss_target := 0
var _last_result_data: Dictionary = {}
var _rank_target := "D"
var _rank_sub_target := "CLEAR"
var _reveal_tween: Tween
var _actions_ready := false
var _result_generation: int = 0
var _rank_fill_finished: bool = false

func _ready() -> void:
	if theme_config == null:
		theme_config = ThemeConfigScript.new()
	if layout_config == null:
		layout_config = LayoutConfigScript.new()
	if result_config == null:
		result_config = ResultConfigScript.new()
	MinimalThemeScript.apply_root(self)
	back_button.pressed.connect(_on_back_button_pressed)
	replay_button.pressed.connect(_on_replay_button_pressed)
	_wire_action_focus()
	_set_actions_enabled(false)
	visibility_changed.connect(_on_visibility_changed)
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)
	_apply_layout_config()
	_apply_theme_config()
	_apply_scene_effects()
	InteractionPolishScript.install_buttons([back_button, replay_button])
	call_deferred("_update_animation_pivots")

func _on_back_button_pressed() -> void:
	if not is_navigation_ready():
		return
	_set_actions_enabled(false)
	back_requested.emit()

func _on_replay_button_pressed() -> void:
	if not is_navigation_ready():
		return
	_set_actions_enabled(false)
	replay_requested.emit()

func _wire_action_focus() -> void:
	back_button.focus_neighbor_right = back_button.get_path_to(replay_button)
	back_button.focus_neighbor_left = back_button.get_path_to(replay_button)
	replay_button.focus_neighbor_left = replay_button.get_path_to(back_button)
	replay_button.focus_neighbor_right = replay_button.get_path_to(back_button)

func _set_actions_enabled(enabled: bool) -> void:
	_actions_ready = enabled
	back_button.disabled = not enabled
	replay_button.disabled = not enabled
	if not enabled and is_inside_tree():
		var focused_control: Control = get_viewport().gui_get_focus_owner()
		if focused_control == back_button or focused_control == replay_button:
			get_viewport().gui_release_focus()

func is_navigation_ready() -> bool:
	return _actions_ready and visible

func _apply_scene_effects() -> void:
	backdrop.set("background_color", MinimalThemeScript.BG)
	backdrop.set("grid_color", Color(MinimalThemeScript.BORDER, 0.10))
	backdrop.set("accent_color", Color(theme_config.accent_primary, 0.13))
	backdrop.queue_redraw()
	judgement_bar.call("set_palette", theme_config.perfect_color, theme_config.great_color, theme_config.good_color, theme_config.miss_color)
	rank_meter.call("set_thresholds",
		result_config.c_accuracy,
		result_config.b_accuracy,
		result_config.a_accuracy,
		result_config.s_accuracy
	)
	rank_meter.call("set_palette",
		theme_config.danger,
		theme_config.space_accent,
		theme_config.success,
		theme_config.accent_secondary,
		theme_config.accent_primary
	)

func _apply_layout_config() -> void:
	if layout_config == null:
		return
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		main_margin.add_theme_constant_override(side, layout_config.screen_margin)
	root_vbox.add_theme_constant_override("separation", layout_config.item_gap)
	header_bar.add_theme_constant_override("separation", layout_config.section_gap)
	content.add_theme_constant_override("separation", layout_config.section_gap)
	rank_column.add_theme_constant_override("separation", layout_config.compact_gap)
	stats_column.add_theme_constant_override("separation", layout_config.item_gap)
	score_vbox.add_theme_constant_override("separation", layout_config.compact_gap)
	primary_stats.add_theme_constant_override("separation", layout_config.item_gap)
	special_row.add_theme_constant_override("separation", layout_config.compact_gap)
	bottom_bar.add_theme_constant_override("separation", layout_config.item_gap)
	rank_panel.size_flags_stretch_ratio = layout_config.result_rank_ratio
	stats_column.size_flags_stretch_ratio = layout_config.result_left_ratio
	rank_panel.custom_minimum_size.x = layout_config.result_rank_min_width
	score_panel.custom_minimum_size.y = layout_config.result_score_panel_min_height
	breakdown_panel.custom_minimum_size.y = layout_config.result_breakdown_min_height
	special_panel.custom_minimum_size.y = layout_config.result_special_panel_min_height
	for card in [accuracy_card, combo_card, perfect_rate_card]:
		card.custom_minimum_size.y = layout_config.result_card_min_height
	for button in [back_button, replay_button]:
		button.custom_minimum_size = Vector2(
			layout_config.result_button_min_width,
			layout_config.result_button_min_height
		)

func _apply_theme_config() -> void:
	if theme_config == null:
		return
	for node in find_children("*", "Label", true, false):
		if not is_instance_valid(node) or node.owner == null:
			continue
		var label := node as Label
		if label == null:
			continue
		label.add_theme_color_override("font_color", theme_config.text_primary)
		label.add_theme_font_size_override("font_size", theme_config.body_size)
		if label.name in ["Title", "Meta", "RankCaption", "RankHint", "ScoreCaption", "ScoreStatus", "JudgedValue", "FooterHint"]:
			label.add_theme_color_override("font_color", theme_config.text_secondary)
			label.add_theme_font_size_override("font_size", theme_config.caption_size)

	page_title.add_theme_color_override("font_color", theme_config.accent_primary)
	page_title.add_theme_font_size_override("font_size", theme_config.caption_size)
	song_title.add_theme_font_size_override("font_size", theme_config.title_size)
	song_title.add_theme_font_override("font", MinimalThemeScript.semibold_font())
	song_meta.add_theme_color_override("font_color", theme_config.text_secondary)
	new_best.add_theme_color_override("font_color", theme_config.accent_primary)
	rank_value.add_theme_font_size_override("font_size", maxi(110, theme_config.rank_size - 14))
	rank_value.add_theme_font_override("font", MinimalThemeScript.semibold_font())
	rank_sub.add_theme_font_size_override("font_size", theme_config.meta_size)
	score_value.add_theme_font_size_override("font_size", maxi(58, theme_config.score_size - 4))
	for label in [accuracy_value, combo_value, perfect_rate_value]:
		label.add_theme_font_size_override("font_size", theme_config.card_value_size)
	for label in [perfect_value, great_value, good_value, miss_value]:
		label.add_theme_font_size_override("font_size", maxi(20, theme_config.card_value_size - 4))

	MinimalThemeScript.apply_mono(song_meta, 13, MinimalThemeScript.MUTED)
	MinimalThemeScript.apply_mono(score_value, maxi(58, theme_config.score_size - 4), MinimalThemeScript.TEXT)
	MinimalThemeScript.apply_mono(rank_sub, 16, MinimalThemeScript.PINK)
	MinimalThemeScript.apply_mono(score_status, 12, MinimalThemeScript.MUTED)
	MinimalThemeScript.apply_mono(judged_value, 12, MinimalThemeScript.MUTED)
	for label in [accuracy_value, combo_value, perfect_rate_value, perfect_value, great_value, good_value, miss_value]:
		MinimalThemeScript.apply_mono(label, label.get_theme_font_size("font_size"), label.get_theme_color("font_color"))
	for label in [space_value, reverse_value]:
		MinimalThemeScript.apply_mono(label, 18, MinimalThemeScript.TEXT)
	for meta_label in [space_meta, reverse_meta]:
		meta_label.add_theme_color_override("font_color", theme_config.text_secondary)
		MinimalThemeScript.apply_mono(meta_label, 10, MinimalThemeScript.MUTED)

	perfect_title.add_theme_color_override("font_color", theme_config.perfect_color)
	perfect_value.add_theme_color_override("font_color", theme_config.perfect_color)
	great_title.add_theme_color_override("font_color", theme_config.great_color)
	great_value.add_theme_color_override("font_color", theme_config.great_color)
	good_title.add_theme_color_override("font_color", theme_config.good_color)
	good_value.add_theme_color_override("font_color", theme_config.good_color)
	miss_title.add_theme_color_override("font_color", theme_config.miss_color)
	miss_value.add_theme_color_override("font_color", theme_config.miss_color)
	for label in _rolling_labels():
		label.call("refresh_style")

	# Album Flow keeps the result hierarchy typographic. Containment appears only
	# where it improves scanning instead of turning every metric into a card.
	rank_panel.add_theme_stylebox_override("panel", MinimalThemeScript.surface_s0(12.0))
	score_panel.add_theme_stylebox_override("panel", MinimalThemeScript.surface_s1(16.0, theme_config.accent_primary))
	for panel in [accuracy_card, combo_card, perfect_rate_card]:
		panel.add_theme_stylebox_override("panel", MinimalThemeScript.surface_s0(10.0))
	breakdown_panel.add_theme_stylebox_override("panel", MinimalThemeScript.surface_s1(14.0))
	special_panel.add_theme_stylebox_override("panel", MinimalThemeScript.surface_s0(10.0))
	best_plate.add_theme_stylebox_override("panel", MinimalThemeScript.panel_style(Color(theme_config.accent_primary, 0.08), MinimalThemeScript.RADIUS_SM, Color(theme_config.accent_primary, 0.42), 1, 12.0))
	MinimalThemeScript.style_tertiary(back_button, MinimalThemeScript.ACCENT)
	MinimalThemeScript.style_primary(replay_button)

func set_result(data: Dictionary) -> void:
	_last_result_data = data.duplicate(true)
	_cancel_reveal()
	_result_generation += 1
	_rank_fill_finished = false
	_set_actions_enabled(false)
	song_title.text = str(data.get("title", "SONG"))
	song_meta.text = str(data.get("meta", ""))
	_score_target = maxi(0, int(data.get("score", _parse_result_number(str(data.get("score_text", "0"))))))
	_combo_target = maxi(0, int(data.get("max_combo", _parse_first_integer(str(data.get("combo_text", "0"))))))
	_perfect_target = maxi(0, int(data.get("perfect", 0)))
	_great_target = maxi(0, int(data.get("great", 0)))
	_good_target = maxi(0, int(data.get("good", 0)))
	_miss_target = maxi(0, int(data.get("miss", 0)))

	# Judgement counts are the authoritative result model. Recompute derived
	# metrics here so stale display strings or a mismatched caller cannot make
	# Accuracy / Perfect Rate / Rank disagree with the breakdown panel.
	var judged: int = _perfect_target + _great_target + _good_target + _miss_target
	var supplied_accuracy: float = clampf(float(data.get("accuracy", _parse_percentage(str(data.get("accuracy_text", "0.00%"))))), 0.0, 100.0)
	_accuracy_target = _calculate_accuracy_from_targets() if judged > 0 else supplied_accuracy
	_perfect_rate_target = (float(_perfect_target) / float(judged) * 100.0) if judged > 0 else 0.0

	_space_target = maxi(0, int(data.get("space_hits", _parse_first_integer(str(data.get("space_text", "0"))))))
	var supplied_space_misses: int = maxi(0, int(data.get("space_misses", 0)))
	_space_total_target = maxi(0, int(data.get("space_total", _space_target + supplied_space_misses)))
	_space_total_target = maxi(_space_total_target, _space_target + supplied_space_misses)
	_space_target = mini(_space_target, _space_total_target)
	var space_misses: int = maxi(0, _space_total_target - _space_target)

	_reverse_target = maxi(0, int(data.get("reverse_hits", _parse_first_integer(str(data.get("reverse_text", "0"))))))
	_reverse_total_target = maxi(0, int(data.get("reverse_total", _reverse_target)))
	_reverse_total_target = maxi(_reverse_total_target, _reverse_target)
	_reverse_target = mini(_reverse_target, _reverse_total_target)
	_reverse_miss_target = maxi(0, _reverse_total_target - _reverse_target)

	var is_new_best: bool = bool(data.get("new_best", false))
	best_plate.visible = is_new_best
	var previous: Dictionary = data.get("previous_best", {})
	score_status.text = ""
	if is_new_best and not previous.is_empty():
		score_status.text = "SCORE %+d  ·  ACC %+.2f pp" % [int(data.get("score", 0)) - int(previous.get("score", 0)), supplied_accuracy - float(previous.get("accuracy", 0.0))]
	if bool(data.get("record_save_failed", false)):
		score_status.text = "RECORD SAVE FAILED · CHECK DISK SPACE / PERMISSIONS"
	score_status.visible = not score_status.text.is_empty()
	judged_value.text = "%d NOTES" % judged
	space_meta.text = "%d TOTAL  ·  %d MISS" % [_space_total_target, space_misses]
	reverse_meta.text = "%d TOTAL  ·  %d MISS" % [_reverse_total_target, _reverse_miss_target]
	special_panel.visible = _space_total_target > 0 or _reverse_total_target > 0
	judgement_bar.call("set_counts", _perfect_target, _great_target, _good_target, _miss_target)
	judgement_bar.call("set_reveal", 0.0)

	# Rank is derived from the exact same accuracy value shown on this screen.
	_rank_target = _rank_for_accuracy(_accuracy_target)
	_rank_sub_target = str(data.get("rank_sub", "CLEAR"))
	var difficulty_id: String = str(data.get("difficulty_id", "normal")).to_lower()
	var accent: Color = _difficulty_accent(difficulty_id)
	top_accent.color = accent
	backdrop.call("set_song_background", str(data.get("background", "")), accent)
	for label in _rolling_labels():
		label.call("reset_numeric_value", 0.0)
	rank_value.text = "D"
	rank_sub.text = "CALCULATING"
	rank_meter.set("value", 0.0)
	accuracy_bar.value = 0.0
	_apply_rank_color("D")
	call_deferred("_play_reveal", _result_generation)

func _calculate_accuracy_from_targets() -> float:
	return preload("res://scripts/score_processor.gd").accuracy(_perfect_target, _great_target, _good_target, _miss_target, result_config)

func focus_default() -> void:
	if not is_navigation_ready():
		return
	if replay_button.visible and not replay_button.disabled:
		replay_button.grab_focus()
	elif back_button.visible and not back_button.disabled:
		back_button.grab_focus()

func _play_reveal(generation: int) -> void:
	if generation != _result_generation or not is_inside_tree() or not visible:
		return
	if _reveal_tween != null:
		_reveal_tween.kill()
		_reveal_tween = null
	MenuSFX.cancel_rank_fill()
	_update_animation_pivots()
	header_bar.modulate = Color(1.0, 1.0, 1.0, 0.0)
	rank_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	stats_column.modulate = Color(1.0, 1.0, 1.0, 0.0)
	bottom_bar.modulate = Color(1.0, 1.0, 1.0, 0.0)
	rank_stack.scale = Vector2.ONE * result_config.rank_pop_start_scale
	score_value.text = "0"
	accuracy_bar.value = 0.0
	judgement_bar.call("set_reveal", 0.0)
	rank_meter.set("value", 0.0)
	rank_value.text = "D"
	rank_sub.text = "CALCULATING"

	_reveal_tween = create_tween()
	_reveal_tween.set_parallel(true)
	_reveal_tween.tween_property(header_bar, "modulate:a", 1.0, result_config.header_reveal_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_reveal_tween.tween_property(rank_panel, "modulate:a", 1.0, result_config.rank_reveal_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_reveal_tween.tween_property(rank_stack, "scale", Vector2.ONE, result_config.rank_reveal_duration).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	_reveal_tween.chain().tween_callback(Callable(self, "_start_metric_rolls"))
	_reveal_tween.parallel().tween_property(stats_column, "modulate:a", 1.0, result_config.stats_reveal_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_reveal_tween.parallel().tween_method(Callable(self, "_set_animated_score"), 0.0, float(_score_target), result_config.score_count_duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_reveal_tween.parallel().tween_property(accuracy_bar, "value", _accuracy_target, result_config.score_count_duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_reveal_tween.parallel().tween_method(Callable(self, "_set_rank_progress"), 0.0, _accuracy_target, result_config.score_count_duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_reveal_tween.parallel().tween_method(Callable(self, "_set_judgement_reveal"), 0.0, 1.0, maxf(0.30, result_config.score_count_duration * 0.72)).set_delay(0.06).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_reveal_tween.chain().tween_callback(Callable(self, "_finish_rank_fill_audio").bind(generation))
	_reveal_tween.chain().tween_property(bottom_bar, "modulate:a", 1.0, result_config.actions_reveal_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if result_config.action_unlock_delay > 0.0:
		_reveal_tween.chain().tween_interval(result_config.action_unlock_delay)
	_reveal_tween.chain().tween_callback(Callable(self, "_finish_reveal").bind(generation))

func _start_metric_rolls() -> void:
	var duration := result_config.score_count_duration
	MenuSFX.begin_rank_fill(_accuracy_target, duration)
	accuracy_value.call("animate_to", _accuracy_target, duration, 0.0)
	combo_value.call("animate_to", float(_combo_target), maxf(0.20, duration - 0.03), 0.03)
	perfect_rate_value.call("animate_to", _perfect_rate_target, maxf(0.20, duration - 0.03), 0.03)
	perfect_value.call("animate_to", float(_perfect_target), maxf(0.20, duration - 0.08), 0.08)
	great_value.call("animate_to", float(_great_target), maxf(0.20, duration - 0.08), 0.08)
	good_value.call("animate_to", float(_good_target), maxf(0.20, duration - 0.08), 0.08)
	miss_value.call("animate_to", float(_miss_target), maxf(0.20, duration - 0.08), 0.08)
	space_value.call("animate_to", float(_space_target), maxf(0.20, duration - 0.14), 0.14)
	reverse_value.call("animate_to", float(_reverse_target), maxf(0.20, duration - 0.14), 0.14)

func _finish_reveal(generation: int) -> void:
	if generation != _result_generation or not visible:
		return
	_reveal_tween = null
	_force_final_values()
	_set_actions_enabled(true)
	call_deferred("focus_default")

func _force_final_values() -> void:
	_set_animated_score(float(_score_target))
	accuracy_bar.value = _accuracy_target
	judgement_bar.call("set_reveal", 1.0)
	rank_meter.set("value", _accuracy_target)
	rank_value.text = _rank_target
	rank_sub.text = _rank_sub_target
	_apply_rank_color(_rank_target)
	accuracy_value.call("set_numeric_value", _accuracy_target, false)
	combo_value.call("set_numeric_value", float(_combo_target), false)
	perfect_rate_value.call("set_numeric_value", _perfect_rate_target, false)
	perfect_value.call("set_numeric_value", float(_perfect_target), false)
	great_value.call("set_numeric_value", float(_great_target), false)
	good_value.call("set_numeric_value", float(_good_target), false)
	miss_value.call("set_numeric_value", float(_miss_target), false)
	space_value.call("set_numeric_value", float(_space_target), false)
	reverse_value.call("set_numeric_value", float(_reverse_target), false)

func _set_judgement_reveal(value: float) -> void:
	judgement_bar.call("set_reveal", value)

func _set_rank_progress(value: float) -> void:
	rank_meter.set("value", value)
	MenuSFX.update_rank_fill(value)
	var live_rank := _rank_for_accuracy(value)
	if rank_value.text != live_rank:
		rank_value.text = live_rank
		_apply_rank_color(live_rank)

func _finish_rank_fill_audio(generation: int) -> void:
	if generation != _result_generation or _rank_fill_finished:
		return
	_rank_fill_finished = true
	MenuSFX.update_rank_fill(_accuracy_target)
	MenuSFX.finish_rank_fill(_rank_target)

func _cancel_reveal() -> void:
	if _reveal_tween != null:
		_reveal_tween.kill()
		_reveal_tween = null
	MenuSFX.cancel_rank_fill()

func _on_visibility_changed() -> void:
	if not visible:
		_result_generation += 1
		_cancel_reveal()
		_set_actions_enabled(false)

func _set_animated_score(value: float) -> void:
	score_value.text = _format_number(int(round(value)))

func _format_number(value: int) -> String:
	var digits := str(maxi(0, value))
	var grouped := ""
	var count := 0
	for index in range(digits.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			grouped = "," + grouped
		grouped = digits.substr(index, 1) + grouped
		count += 1
	return grouped

func _parse_result_number(value: String) -> int:
	return int(value.replace(",", "").replace(" ", ""))

func _parse_percentage(value: String) -> float:
	return float(value.replace("%", "").strip_edges())

func _parse_first_integer(value: String) -> int:
	var digits := ""
	for index in range(value.length()):
		var character := value.substr(index, 1)
		if character.is_valid_int():
			digits += character
		elif not digits.is_empty():
			break
	return int(digits) if not digits.is_empty() else 0

func _apply_rank_color(rank: String) -> void:
	var color := _rank_color(rank)
	rank_value.add_theme_color_override("font_color", color)
	rank_sub.add_theme_color_override("font_color", color)
	rank_panel.add_theme_stylebox_override("panel", MinimalThemeScript.panel_style(Color(MinimalThemeScript.SURFACE, 0.70), 8, Color(color, 0.52), 1, 20.0))

func _rank_for_accuracy(accuracy: float) -> String:
	if accuracy >= result_config.ss_accuracy:
		return "SS"
	if accuracy >= result_config.s_accuracy:
		return "S"
	if accuracy >= result_config.a_accuracy:
		return "A"
	if accuracy >= result_config.b_accuracy:
		return "B"
	if accuracy >= result_config.c_accuracy:
		return "C"
	return "D"

func _rank_color(rank: String) -> Color:
	match rank:
		"SS", "S": return theme_config.accent_primary
		"A": return theme_config.accent_secondary
		"B": return theme_config.success
		"C": return theme_config.space_accent
		_: return theme_config.danger

func _difficulty_accent(difficulty_id: String) -> Color:
	match difficulty_id:
		"master": return MinimalThemeScript.PINK
		"hard": return MinimalThemeScript.GOLD
		_: return MinimalThemeScript.CYAN

func _rolling_labels() -> Array:
	return [
		accuracy_value,
		combo_value,
		perfect_rate_value,
		perfect_value,
		great_value,
		good_value,
		miss_value,
		space_value,
		reverse_value,
	]

func _update_animation_pivots() -> void:
	rank_stack.pivot_offset = rank_stack.size * 0.5

func _on_resized() -> void:
	_apply_layout_config()
	call_deferred("_update_animation_pivots")

func get_last_result_data() -> Dictionary:
	return _last_result_data.duplicate(true)
