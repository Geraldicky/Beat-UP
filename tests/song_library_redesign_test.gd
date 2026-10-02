extends SceneTree
var failures: int = 0
func check(ok: bool, text: String) -> void:
	if not ok:
		failures += 1
		push_error(text)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	preload("res://scripts/user_settings.gd").set_input_style("8_direction")
	root.get_node("AppSessionState").mark_splash_seen()
	var shell: Control = load("res://scenes/app_shell.tscn").instantiate()
	root.add_child(shell)
	await create_timer(1).timeout
	await shell.show_song_library("big_daddy", false)
	var s: Control = shell.song_library_screen.song_select
	s.set_selected_song("un_owen_was_her")
	await create_timer(0.4).timeout
	check(s.detail_title.text == "U.N. Owen Was Her? & Flowering Night (Koa Remix)", "Long title remains complete")
	check(s.detail_title.get_line_count() == 2, "Long title wraps to exactly two lines")
	check(s.detail_meta.get_global_rect().position.y - s.detail_title.get_global_rect().end.y <= 14.0, "Artist stays grouped with song title")
	check(s.composition.detail_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "Overview does not show a false scrollbar")
	check(s.composition.detail_text.get_parsed_text().contains("NORMAL") and not s.composition.detail_text.get_parsed_text().contains("[font_size"), "Overview renders formatted metrics instead of raw BBCode")
	check(s.find_child("CarouselTopFade", true, false) == null, "Carousel edge has no artificial shadow overlay")
	var selected_index: int = s.filtered_song_ids.find(s.selected_song_id)
	var width_margin: float = float(s._carousel_width_margin())
	check(absf(float(s.song_header_wrappers[selected_index].get("animated_margin_left")) - width_margin) <= 1.0, "Selected row anchors to the shortened carousel edge")
	var far_index: int = 0 if selected_index > 4 else s.song_header_wrappers.size() - 1
	check(float(s.song_header_wrappers[far_index].get("animated_margin_left")) >= width_margin + 40.0, "Unselected rows create a visible carousel curve")
	var selected_difficulties: Array = s.song_difficulty_rows[selected_index]
	check(not selected_difficulties.is_empty() and (selected_difficulties[0].button as Button).find_children("*", "Label", true, false).any(func(label: Label): return label.text.contains("NOTES")), "Difficulty rows label their note count")
	var manual_scrollbar: VScrollBar = s.song_scroll.get_v_scroll_bar()
	s.scroll_target = 100.0
	manual_scrollbar.value = 0.0 if manual_scrollbar.value > 0.0 else minf(1.0, manual_scrollbar.max_value - manual_scrollbar.page)
	check(s.scroll_target < 0.0, "Manual scrollbar input cancels automatic centering")
	s.set_selected_song("blue_zenith")
	await create_timer(0.4).timeout
	check(s.detail_title.text == "Blue Zenith" and s.detail_title.size.y >= 39.0, "Single-line song title remains visible")
	check(s.detail_meta.get_global_rect().position.y - s.detail_title.get_global_rect().end.y <= 14.0, "Single-line title remains grouped with artist")
	var chart: Dictionary = s._selected_v18_chart()
	var key: String = preload("res://scripts/score_identity.gd").key(chart, preload("res://scripts/user_settings.gd").get_input_style(), false)
	var records: Dictionary = {}
	for i in range(20):
		var run_data: Dictionary = {"run_id": str(i), "score": 999999999-i, "accuracy": 98.5, "rank": "S", "max_combo": 9999, "completed_at": 1700000000+i, "run_full_combo": false}
		records = preload("res://scripts/run_records.gd").merge(records, run_data).entry
	s.set_best_stats_store({key: records})
	for resolution: Vector2i in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
		root.size = resolution
		root.content_scale_size = resolution
		for tab: String in ["ranking", "details"]:
			s._set_info_tab(tab, false)
			await create_timer(0.4).timeout
			for control: Control in [s.play_button,s.action_row,s.info_panel,s.wheel_column,s.info_tabs]:
				check(control.get_global_rect().end.x <= resolution.x+1, "Horizontal overflow: "+str(control.name))
				check(control.get_global_rect().end.y <= resolution.y+1, "Vertical overflow: "+str(control.name))
			for b: Button in s.song_buttons:
				check(b.size.x <= 942.0, "Song banner remains short enough to preserve artwork")
				for label: Label in b.find_children("*", "Label", true, false):
					check(label.get_global_rect().end.y <= b.get_global_rect().end.y+1, "Clipped song subtitle: "+label.text)
			print("GEOMETRY ", resolution," ",tab," LEFT ",s.info_panel.get_global_rect()," RIGHT ",s.wheel_column.get_global_rect())
	check(s.ranking_list.get_child_count() == 20, "All runs available")
	s._toggle_v18_rank_sort()
	check(str(s.rank_sort_button.text).contains("NEWEST"), "Sort mode is visible")
	s._on_mode_4_selected()
	check(s.record_rows.is_empty(), "Ranking follows active 4K mode")
	s._on_mode_8_selected()
	check(s.record_rows.size() == 20, "8K records preserved")
	s.composition.filter_button.pressed.emit()
	check(s.composition.filter_row.visible,"Filter opens")
	s.composition.options_button.pressed.emit()
	check(s.composition.options_row.visible,"Options opens")
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	s.artist_filter.add_item("A very long artist name used to verify compact filter width")
	s.artist_filter.select(s.artist_filter.item_count - 1)
	s.composition.refresh(s)
	await create_timer(0.4).timeout
	for control: Control in [s.composition.filter_row, s.composition.chips, s.composition.options_row, s.action_row, s.wheel_column]:
		check(control.get_global_rect().end.x <= 1281, "Expanded toolbar overflow: " + str(control.name))
		check(control.get_global_rect().end.y <= 721, "Expanded toolbar vertical overflow: " + str(control.name))
	s.composition.chips.get_child(0).pressed.emit()
	check(s.artist_filter.selected == 0, "Filter chip clears filter")
	s.search_input.text = "no_match_fixture"
	s.search_input.text_changed.emit(s.search_input.text)
	await create_timer(0.3).timeout
	check(s.play_button.disabled,"Empty search prevents launch")
	print("SONG_LIBRARY_REDESIGN: ","PASS" if failures == 0 else "FAIL", " ", failures)
	shell.queue_free()
	await create_timer(0.3).timeout
	quit(0 if failures == 0 else 1)
