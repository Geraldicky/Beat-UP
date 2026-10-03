extends RefCounted
# v18.2 release-facing Song Library composition.
# The controller continues to own catalog, selection, saves and navigation;
# this layer owns hierarchy, density and presentation only.

const VisualTheme = preload("res://scripts/ui/minimal_theme.gd")

var stats: Label
var detail_text: RichTextLabel
var filter_button: Button
var filter_row: HBoxContainer
var chips: HBoxContainer
var detail_scroll: ScrollContainer
var installed: bool = false

func button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	VisualTheme.style_compact(b)
	b.custom_minimum_size.y = 34
	return b

func install(s) -> void:
	# Album Flow is the release-facing composition. Keep the older details,
	# ranking and creator controls alive for their existing data/actions, but do
	# not let this helper reparent primary controls before Album Flow is built.
	stats = Label.new()
	stats.name = "SongStatsLine"
	stats.visible = false
	s.info_vbox.add_child(stats)

	detail_scroll = ScrollContainer.new()
	detail_scroll.name = "ChartDetailsScroll"
	detail_scroll.visible = false
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	s.details_panel.add_child(detail_scroll)
	detail_text = RichTextLabel.new()
	detail_text.name = "ChartDetailsText"
	detail_text.bbcode_enabled = true
	detail_text.fit_content = false
	detail_text.scroll_active = false
	detail_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.add_child(detail_text)

	# The minimal text tabs open these existing filters on demand. They stay
	# hidden until ARTIST or DIFFICULTY is requested; no second toolbar is built.
	var library_box := s.song_scroll.get_parent() as VBoxContainer
	filter_row = HBoxContainer.new()
	filter_row.name = "ExpandedFilters"
	filter_row.visible = false
	filter_row.add_theme_constant_override("separation", 8)
	library_box.add_child(filter_row)
	for control: Control in [s.artist_filter, s.difficulty_filter, s.progress_filter]:
		control.reparent(filter_row)

	chips = HBoxContainer.new()
	chips.name = "ActiveFilters"
	chips.visible = false
	chips.add_theme_constant_override("separation", 6)
	library_box.add_child(chips)
	filter_button = Button.new()
	filter_button.visible = false
	# Retained legacy presentation still needs the screen's lifetime owner.
	# Otherwise each resident/standalone library leaves an orphan Button behind.
	library_box.add_child(filter_button)
	installed = true
	# Single structural entry point: the controller supplies the live nodes and
	# state callbacks, while this composition layer owns installation order.
	s.call("_install_album_flow_song_library_layout")

func apply(s) -> void:
	if not installed:
		return
	# Album Flow owns the release-facing three-column composition. Keep this
	# legacy composition helper from re-applying the old 42/58 split after every
	# selection refresh or window resize.
	if s.has_method("is_album_flow_library_layout_active") and bool(s.call("is_album_flow_library_layout_active")):
		s.call("_apply_album_flow_song_library_layout")
		return
	var compact: bool = s.size.x < 1450.0 or s.size.y < 780.0
	var base_margin: int = 16 if compact else 22
	var now_playing_height: int = roundi(s.now_playing_card.size.y) if s.now_playing_card != null else 40

	s.main_margin.add_theme_constant_override("margin_left", base_margin)
	s.main_margin.add_theme_constant_override("margin_right", base_margin)
	s.main_margin.add_theme_constant_override("margin_bottom", base_margin)
	s.main_margin.add_theme_constant_override("margin_top", base_margin + now_playing_height + 8)
	s.root_vbox.add_theme_constant_override("separation", 10)
	s.body.add_theme_constant_override("separation", 18 if compact else 24)
	s.info_vbox.add_theme_constant_override("separation", 8)

	# Balanced 42/58 split: selected chart context is substantial without starving
	# the browser. Both columns remain responsive instead of locking a fixed width.
	s.info_panel.custom_minimum_size.x = 430 if compact else 500
	s.info_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.info_panel.size_flags_stretch_ratio = 0.42
	s.wheel_column.custom_minimum_size.x = 560 if compact else 660
	s.wheel_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.wheel_column.size_flags_stretch_ratio = 0.58

	for c: Control in [s.info_tabs, s.details_panel, s.best_card]:
		c.custom_minimum_size.x = 0
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.info_tabs.custom_minimum_size.y = 34
	s.details_panel.custom_minimum_size.y = 230 if compact else 270
	s.details_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.best_card.custom_minimum_size.y = 230 if compact else 270
	s.best_card.size_flags_vertical = Control.SIZE_EXPAND_FILL

	s.best_card.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var detail_card := VisualTheme.surface_s1(0.46)
	s.details_panel.add_theme_stylebox_override("panel", detail_card)
	var best_margin := s.best_card.get_node("BestCardMargin") as MarginContainer
	best_margin.add_theme_constant_override("margin_left", 0)
	best_margin.add_theme_constant_override("margin_right", 0)
	s.ranking_scroll.custom_minimum_size = Vector2.ZERO
	s.ranking_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.ranking_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if s.ranking_tab_tools != null:
		s.ranking_tab_tools.custom_minimum_size = Vector2.ZERO
		s.ranking_tab_tools.add_theme_constant_override("separation", 6)
	if s.ranking_mods_filter != null:
		s.ranking_mods_filter.custom_minimum_size = Vector2(118, 28)
		VisualTheme.style_compact(s.ranking_mods_filter)
	if s.rank_sort_button != null:
		s.rank_sort_button.visible = false

	for b: Button in [s.details_tab_button, s.ranking_tab_button]:
		b.custom_minimum_size = Vector2(90, 34)
		b.add_theme_font_size_override("font_size", 12)
		for state: String in ["normal", "hover", "pressed", "focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0, 0, 0, 0)
			style.border_width_bottom = 2 if (b == s.ranking_tab_button) == (s.selected_info_tab == "ranking") else 0
			style.border_color = VisualTheme.ACCENT
			b.add_theme_stylebox_override(state, style)

	# Selected title is the primary hierarchy anchor. It must never be replaced by
	# Now Playing or artist copy.
	s.detail_title.visible = true
	VisualTheme.apply_heading(s.detail_title, 27 if compact else 32, VisualTheme.TEXT)
	s.detail_title.custom_minimum_size.y = 38 if compact else 44
	s.detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	s.detail_title.max_lines_visible = 2
	s.detail_title.clip_text = true
	s.detail_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	VisualTheme.apply_body(s.detail_meta, 14, Color(VisualTheme.TEXT, 0.72))
	VisualTheme.apply_body(s.detail_description, 12, VisualTheme.ACCENT_LIGHT)
	VisualTheme.apply_mono(stats, 11, Color(VisualTheme.TEXT, 0.74))

	detail_text.add_theme_font_override("normal_font", VisualTheme.body_font())
	detail_text.add_theme_font_override("bold_font", VisualTheme.medium_font())
	detail_text.add_theme_font_size_override("normal_font_size", 12 if compact else 13)
	detail_text.add_theme_color_override("default_color", VisualTheme.TEXT)
	s.quick_stats.visible = false

	s.search_input.custom_minimum_size = Vector2(180, 40)
	s.search_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.sort_filter.custom_minimum_size = Vector2(124, 40)
	for c: Control in [s.artist_filter, s.difficulty_filter, s.progress_filter]:
		c.custom_minimum_size = Vector2(132, 36)
		c.clip_text = true
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	s.action_row.custom_minimum_size.y = 46
	s.action_row.add_theme_constant_override("separation", 8)
	s.back_button.custom_minimum_size = Vector2(82, 38)
	s.mods_button.custom_minimum_size = Vector2(126, 38)
	s.practice_button.custom_minimum_size = Vector2(104, 38)
	s.replay_button.custom_minimum_size = Vector2(96, 38)
	s.play_button.custom_minimum_size = Vector2(210, 46)
	s.play_button.size_flags_horizontal = Control.SIZE_FILL
	VisualTheme.style_tertiary(s.back_button, VisualTheme.ACCENT)
	VisualTheme.style_secondary(s.mods_button, VisualTheme.ACCENT)
	VisualTheme.style_tertiary(s.practice_button, VisualTheme.GOLD)
	VisualTheme.style_tertiary(s.replay_button, VisualTheme.ACCENT_LIGHT)
	VisualTheme.style_primary(s.play_button)

	# v18.7 promotes local song import/export to a supported player feature.
	s.footer_panel.visible = bool(ProjectSettings.get_setting("beat_up/player_creator_enabled", true))
	s.song_list.add_theme_constant_override("separation", 4)

func refresh(s) -> void:
	if not installed:
		return
	stats.text = "" if s.selected_song_id.is_empty() else "%s BPM   ·   %s   ·   %s NOTES" % [s.bpm_value.text, s.duration_value.text, s.notes_value.text]
	var chart: Dictionary = s._selected_v18_chart()
	if chart.is_empty():
		detail_text.text = "[color=#8B96A8]No chart selected.[/color]"
	else:
		var reverse: int = 0
		for event_value: Variant in chart.get("events", []):
			if event_value is Dictionary and str((event_value as Dictionary).get("type", "")) == "reverse":
				reverse += 1
		var space_count: int = (chart.get("space_events", []) as Array).size() if chart.get("space_events", []) is Array else 0
		var sections_count: int = (chart.get("sections", []) as Array).size() if chart.get("sections", []) is Array else 0
		var import_meta: Dictionary = chart.get("import_meta", {}) as Dictionary
		var generator_meta: Dictionary = chart.get("generator_meta", {}) as Dictionary
		var creator: String = str(generator_meta.get("generated_by", "Beat UP!")).replace("Beat UP! ", "").replace(" generator", "")
		if creator.is_empty():
			creator = "Beat UP!"
		var source: String = str(import_meta.get("analysis_master_name", import_meta.get("source_name", "Local audio"))).get_file()
		if source.length() > 44:
			source = source.substr(0, 41) + "..."
		var mode: String = "4K" if s.ranking_input_style == "4_arrow" else "8K"
		if s.random_mode_enabled:
			mode += " + RANDOM"
		var progress: String = s._progress_long_label(s._progress_entry(s.selected_song_id, s.selected_difficulty))
		detail_text.text = "[color=#8B96A8][font_size=11]CHART DETAILS[/font_size][/color]\n\n[b]CREATOR[/b]  %s\n[b]SOURCE[/b]  %s\n[b]INPUT[/b]  %s\n[b]SPECIALS[/b]  %d REVERSE  ·  %d SPACE\n[b]STRUCTURE[/b]  %d MUSICAL SECTIONS\n\n[color=#A9B8FF]%s[/color]" % [creator, source, mode, reverse, space_count, sections_count, progress]

	for child: Node in chips.get_children():
		chips.remove_child(child)
		child.queue_free()
	for c in [s.artist_filter, s.difficulty_filter, s.progress_filter]:
		if c.selected <= 0:
			continue
		var chip := button(c.text + "  ×")
		chip.add_theme_font_size_override("font_size", 10)
		chip.custom_minimum_size = Vector2(96, 26)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.clip_text = true
		chip.tooltip_text = c.text + " — remove filter"
		chip.pressed.connect(func() -> void: c.select(0); c.item_selected.emit(0))
		chips.add_child(chip)
	chips.visible = chips.get_child_count() > 0
	filter_button.text = "FILTERS" if not chips.visible else "FILTERS · %d" % chips.get_child_count()
	s.detail_title.tooltip_text = s.detail_title.text
	apply(s)

func render_ranking(s) -> void:
	if not installed or s.ranking_list == null:
		return
	s._clear_children(s.ranking_list)
	if s.record_rows.is_empty():
		var empty := VBoxContainer.new()
		empty.custom_minimum_size.y = 92
		empty.alignment = BoxContainer.ALIGNMENT_CENTER
		var empty_title := Label.new()
		empty_title.text = "NO LOCAL RUNS"
		VisualTheme.apply_heading(empty_title, 16, VisualTheme.TEXT)
		empty.add_child(empty_title)
		var empty_hint := Label.new()
		empty_hint.text = "Finish a play with these mods to create the first score."
		empty_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		VisualTheme.apply_body(empty_hint, 12, VisualTheme.MUTED)
		empty.add_child(empty_hint)
		s.ranking_list.add_child(empty)
		return

	for index in range(s.record_rows.size()):
		var run_value: Variant = s.record_rows[index]
		if not (run_value is Dictionary):
			continue
		var run: Dictionary = run_value as Dictionary
		var row_button := Button.new()
		row_button.name = "Run_%d" % index
		row_button.text = ""
		row_button.custom_minimum_size.y = 68
		row_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_button.focus_mode = Control.FOCUS_ALL
		row_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		VisualTheme.style_compact(row_button)
		row_button.pressed.connect(func() -> void: show_record(s, run))
		s.ranking_list.add_child(row_button)

		var margin := MarginContainer.new()
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_top", 7)
		margin.add_theme_constant_override("margin_bottom", 7)
		row_button.add_child(margin)

		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 12)
		margin.add_child(row)

		var place := Label.new()
		place.text = "#%d" % (index + 1)
		place.custom_minimum_size.x = 38
		VisualTheme.apply_numeric(place, 15, VisualTheme.TEXT)
		row.add_child(place)

		var run_meta := VBoxContainer.new()
		run_meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		run_meta.add_theme_constant_override("separation", 2)
		row.add_child(run_meta)

		var score_line := HBoxContainer.new()
		score_line.add_theme_constant_override("separation", 8)
		run_meta.add_child(score_line)
		var score := Label.new()
		score.text = s._format_number(int(run.get("score", 0)))
		VisualTheme.apply_numeric(score, 19, VisualTheme.TEXT)
		score_line.add_child(score)
		var grade := Label.new()
		grade.text = str(run.get("rank", "—"))
		VisualTheme.apply_heading(grade, 17, s._rank_display_color(grade.text))
		score_line.add_child(grade)
		if bool(run.get("run_full_combo", false)):
			var fc := Label.new()
			fc.text = "FC"
			VisualTheme.apply_mono(fc, 10, VisualTheme.SUCCESS)
			score_line.add_child(fc)

		var stat_line := Label.new()
		stat_line.text = "%.2f%%  ·  %dx" % [float(run.get("accuracy", 0.0)), int(run.get("max_combo", 0))]
		VisualTheme.apply_mono(stat_line, 11, Color(VisualTheme.TEXT, 0.72))
		run_meta.add_child(stat_line)

		var right := VBoxContainer.new()
		right.custom_minimum_size.x = 132
		right.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(right)
		var mode_tag := Label.new()
		var mode_text: String = "4K" if s.ranking_input_style == "4_arrow" else "8K"
		if s.ranking_random_mode:
			mode_text += " · RND"
		mode_tag.text = mode_text
		mode_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		VisualTheme.apply_mono(mode_tag, 10, VisualTheme.ACCENT)
		right.add_child(mode_tag)
		var timestamp: int = int(run.get("completed_at", 0))
		var date := Label.new()
		date.text = Time.get_datetime_string_from_unix_time(timestamp).replace("T", " ") if timestamp > 0 else "—"
		date.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		VisualTheme.apply_mono(date, 9, Color(VisualTheme.MUTED, 0.82))
		right.add_child(date)

func show_record(s, run: Dictionary) -> void:
	var dialog := preload("res://scripts/ui/beat_message_dialog.gd").new()
	s.add_child(dialog)
	var message := "Score %s · %s · %.2f%%\nCombo %dx\n\nPERFECT %d · GREAT %d · GOOD %d · MISS %d\nSPACE %d HIT · %d MISS" % [s._format_number(int(run.get("score", 0))), str(run.get("rank", "")), float(run.get("accuracy", 0)), int(run.get("max_combo", 0)), int(run.get("perfect", 0)), int(run.get("great", 0)), int(run.get("good", 0)), int(run.get("miss", 0)), int(run.get("space_hits", 0)), int(run.get("space_misses", 0))]
	var manager: Node = s.get_node_or_null("/root/ReplayManager")
	var replay_available := false
	if manager != null:
		var replay: Dictionary = manager.load_latest(s._selected_v18_chart(), s.ranking_input_style, s.ranking_random_mode)
		if not str(run.get("run_id", "")).is_empty() and str(replay.get("result", {}).get("run_id", "")) == str(run.get("run_id", "")):
			replay_available = true
			dialog.action_requested.connect(Callable(s, "_play_v18_latest_replay"))
	dialog.show_message("Run details", message, "WATCH REPLAY" if replay_available else "")
