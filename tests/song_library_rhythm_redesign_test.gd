extends SceneTree

const ScoreIdentity = preload("res://scripts/score_identity.gd")
const UserSettings = preload("res://scripts/user_settings.gd")

var failures := 0

func check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)

func _initialize() -> void:
	root.content_scale_size = Vector2i(1920, 1080)
	root.size = Vector2i(1920, 1080)
	call_deferred("run")

func run() -> void:
	var scene := load("res://scenes/song_library.tscn") as PackedScene
	var library := scene.instantiate() as Control
	root.add_child(library)
	await process_frame
	await process_frame
	await create_timer(0.35).timeout
	var selector := library.song_select as Control

	var list_rect: Rect2 = selector.wheel_column.get_global_rect()
	var detail_rect: Rect2 = selector.info_panel.get_global_rect()
	check(list_rect.position.x < detail_rect.position.x, "Song list is not on the left.")
	var usable_width: float = list_rect.size.x + detail_rect.size.x
	check(list_rect.size.x / usable_width >= 0.33 and list_rect.size.x / usable_width <= 0.39, "Song list is not approximately 36% wide.")
	check(not list_rect.intersects(detail_rect), "Song list and detail panel overlap.")
	var center_rect: Rect2 = selector.album_flow_center_column.get_global_rect()
	var config_rect: Rect2 = selector.album_flow_sidebar.get_global_rect()
	check(center_rect.position.x >= detail_rect.position.x and config_rect.position.x > center_rect.position.x, "Inspect/configure columns are not ordered left-to-right.")
	check(not center_rect.intersects(config_rect), "Inspect and configuration columns overlap.")
	check(selector.search_input.is_visible_in_tree(), "Search is not visible.")
	check(selector.back_button.is_visible_in_tree(), "Back control is not visible.")
	check(selector.title_label.text == "S O N G   L I B R A R Y", "Tracked Song Library header title is missing.")
	check(selector.sort_filter.is_visible_in_tree() and selector.sort_filter.text == "BPM ASC", "Custom sort control or default BPM ascending mode is missing.")
	check(selector.artist_filter.is_visible_in_tree() and selector.difficulty_filter.is_visible_in_tree(), "Primary Artist/Difficulty header filters are missing.")
	check(selector.album_flow_filter_button != null and selector.album_flow_filter_button.visible and selector.album_flow_filter_button.text == "⋯", "Compact overflow filter control is missing.")
	check(selector.album_flow_difficulty_row.is_visible_in_tree(), "Difficulty selector is not permanently visible.")
	check(selector.album_flow_difficulty_row.get_child_count() == 3, "Normal, Hard, and Master selectors are not all represented.")
	check(selector.play_button.is_visible_in_tree() and not selector.play_button.disabled, "Play is not visibly available for the selected chart.")
	check(selector.album_flow_mode_4_button.is_visible_in_tree() and selector.album_flow_mode_8_button.is_visible_in_tree(), "Inline 4K/8K mode controls are missing.")
	check(selector.album_flow_random_button.is_visible_in_tree(), "Inline Random mod is missing.")
	check(selector.practice_button.is_visible_in_tree() and selector.practice_button.pressed.get_connections().size() > 0, "Practice action is missing or disconnected.")
	check(selector.album_flow_artwork.size.x >= 400.0 and selector.album_flow_artwork.size.y >= 400.0, "Selected jacket is not a large focal point at 1920×1080.")
	check(selector.album_flow_record_panel != null and selector.album_flow_record_panel.get_parent() == selector.album_flow_center_column, "Best Record is not in the center inspection column.")
	check(selector.album_flow_record_panel.get_theme_stylebox("panel") is StyleBoxEmpty, "Best Record still renders an opaque/dark panel background.")
	check(not selector.album_flow_record_panel.get_global_rect().intersects(selector.album_flow_artwork.get_global_rect()), "Best Record overlaps the selected artwork.")
	check(selector.album_flow_record_breakdown_row != null and selector.album_flow_record_breakdown_row.get_child_count() == 4, "Judgement breakdown is incomplete.")
	check(selector.album_flow_score_cluster != null and selector.album_flow_score_cluster.get_global_rect().position.y >= selector.album_flow_artwork.get_global_rect().end.y, "Best-score hierarchy is not positioned beneath the jacket.")
	check(selector.album_flow_difficulty_row.get_parent() == selector.album_flow_sidebar, "Difficulty selector is not in the configuration column.")
	check(selector.album_flow_mode_row.get_parent() == selector.album_flow_sidebar and selector.album_flow_modifier_row.get_parent() == selector.album_flow_sidebar, "Mode/mod controls are not in the configuration column.")
	check(selector.play_button.get_parent() == selector.album_flow_sidebar and selector.play_button.size.y >= 70.0, "Play is not the dominant bottom-right call to action.")
	check(selector.album_flow_bottom_panel != null and not selector.album_flow_bottom_panel.visible, "Legacy detached Difficulty/Play dock is still visible.")
	check(selector.album_flow_list_header != null and selector.album_flow_list_header.is_visible_in_tree(), "Dense song-list column header is missing.")
	check(selector.backdrop_visual.is_visible_in_tree() and selector.backdrop_visual.modulate.a <= 0.30, "Selected-song background atmosphere is missing or too strong.")
	check(selector.album_flow_ambient != null and not selector.album_flow_ambient.visible, "Abstract ambient geometry should be suppressed in the mockup-matched composition.")
	check(selector.album_flow_meta_line != null and selector.album_flow_meta_line.text.contains("BPM"), "Inline song metadata is missing.")
	check(selector.album_flow_prev_song_button != null and selector.album_flow_next_song_button != null, "Track previous/next controls are missing.")

	var selected_index: int = selector.filtered_song_ids.find(selector.selected_song_id)
	check(selected_index >= 0, "No initial song was selected.")
	if selected_index >= 0:
		var selected_button := selector.song_buttons[selected_index] as Button
		check(selected_button.custom_minimum_size.y >= 64.0 and selected_button.custom_minimum_size.y <= 76.0, "Selected song row is not dense enough for fast scanning.")
		var jacket := selected_button.find_child("SongJacket", true, false) as TextureRect
		check(jacket != null and jacket.custom_minimum_size.x >= 48.0 and jacket.custom_minimum_size.x <= 58.0, "Selected row jacket size does not match the dense-browser hierarchy.")

	selector.search_input.text = "blue zenith"
	selector._on_search_changed(selector.search_input.text)
	await process_frame
	check(selector.filtered_song_ids.size() == 1 and selector.filtered_song_ids[0] == "blue_zenith", "Title search did not filter immediately.")
	selector.search_input.text = "xi"
	selector._on_search_changed(selector.search_input.text)
	await process_frame
	check(not selector.filtered_song_ids.is_empty(), "Artist search returned no matches.")
	selector.search_input.text = "no_song_can_match_this_fixture"
	selector._on_search_changed(selector.search_input.text)
	await process_frame
	check(selector.filtered_song_ids.is_empty() and selector.play_button.disabled, "Empty search state did not disable Play.")
	check(selector.find_child("EmptyLibraryState", true, false) != null, "Empty search message is missing.")
	selector.search_input.clear()
	selector._on_search_changed("")
	await process_frame

	selector.selected_sort_mode = "BPM Desc"
	selector._apply_filters(false)
	check(_is_bpm_sorted(selector, false), "BPM descending sort was not preserved.")
	selector.selected_sort_mode = "BPM Asc"
	selector._apply_filters(false)
	check(_is_bpm_sorted(selector, true), "BPM ascending sort was not preserved.")
	selector.selected_difficulty_filter = "Master"
	selector._apply_filters(false)
	check(selector.filtered_song_ids.all(func(song_id: String) -> bool: return not selector._find_level(song_id, "master").is_empty()), "Difficulty filtering admitted a song without Master.")
	selector.selected_difficulty_filter = "All Difficulties"
	selector._apply_filters(false)

	var rapid_ids: Array[String] = []
	for song_id in selector.filtered_song_ids:
		rapid_ids.append(song_id)
		if rapid_ids.size() == 5:
			break
	for song_id in rapid_ids:
		selector._select_song(song_id)
	await create_timer(0.32).timeout
	check(selector.selected_song_id == rapid_ids.back(), "Rapid song selection did not settle on the final song.")
	check(not selector.preview_player.get_current_audio_path().is_empty(), "Song preview did not follow the final selection.")

	var available: Array[String] = selector._available_difficulties(selector.selected_song_id)
	if available.size() > 1:
		selector._select_difficulty(available.back())
		await create_timer(0.24).timeout
		check(selector.selected_difficulty == available.back(), "Difficulty switch did not update the chart ID.")
		check(selector._selected_v18_chart() == selector._find_level(selector.selected_song_id, selector.selected_difficulty), "Difficulty switch retained a stale chart.")

	selector._on_mode_4_selected()
	await process_frame
	check(UserSettings.get_input_style() == "4_arrow" and selector.notes_value.text == "4 KEY", "4K mode did not refresh metadata.")
	var chart_after_4k: Dictionary = selector._find_level(selector.selected_song_id, selector.selected_difficulty)
	selector._on_mode_8_selected()
	await process_frame
	check(UserSettings.get_input_style() == "8_direction" and selector.notes_value.text == "8 KEY", "8K mode did not refresh metadata.")
	check(selector._selected_v18_chart() == selector._find_level(selector.selected_song_id, selector.selected_difficulty), "8K mode retained a stale chart reference.")
	selector._on_mode_4_selected()
	await process_frame
	check(selector._selected_v18_chart() == chart_after_4k, "8K→4K did not resolve the selected chart cleanly.")
	selector._on_mode_8_selected()

	selector._on_random_mod_toggled(true)
	await process_frame
	check(selector.random_mode_enabled and selector.album_flow_random_button.button_pressed, "Random active state did not refresh.")
	selector._on_random_mod_toggled(false)

	var chart: Dictionary = selector._find_level(selector.selected_song_id, selector.selected_difficulty)
	var score_key: String = ScoreIdentity.key(chart, UserSettings.get_input_style(), false)
	selector.set_best_stats_store({score_key: {"score": 10680000, "best_accuracy": 98.42, "best_rank": "S", "best_max_combo": 512, "cleared": true}})
	await process_frame
	check(selector.album_flow_best_rank_value.text == "S", "Best rank did not refresh.")
	check(selector.album_flow_best_score_value.text == "10,680,000", "Best score did not refresh or format correctly.")
	check(selector.album_flow_best_accuracy_value.text == "98.42%", "Best accuracy did not refresh.")
	selector.set_best_stats_store({})
	await process_frame
	check(selector.album_flow_best_score_value.text == "NO RECORD" and selector.album_flow_best_rank_value.text.is_empty(), "No-record state still shows meaningless placeholders.")
	selector.set_best_stats_store({score_key: {"score": 10680000, "best_accuracy": 98.42, "best_rank": "S", "best_max_combo": 512, "cleared": true}})

	selector.song_scroll.scroll_vertical = 240
	await process_frame
	check(selector.song_scroll.scroll_vertical > 0, "Song list did not scroll independently.")
	check(selector._song_banner_texture("__missing_cover_fixture__", "") == null, "Missing-cover lookup did not return the safe fallback state.")
	check(selector.play_button.pressed.get_connections().size() > 0, "Play action is disconnected.")
	check(selector.back_button.pressed.get_connections().size() > 0, "Back action is disconnected.")

	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	await process_frame
	await process_frame
	check(selector.wheel_column.get_global_rect().end.y <= 721.0, "Song browser overflows a common 1280×720 viewport.")
	check(selector.info_panel.get_global_rect().end.y <= 721.0, "Song detail overflows a common 1280×720 viewport.")
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i(1920, 1080)
	await process_frame
	await process_frame

	if OS.get_cmdline_user_args().has("capture"):
		var image := root.get_texture().get_image()
		if image != null and not image.is_empty():
			image.save_png("res://tests/song_library_rhythm_redesign_1920x1080.png")
		else:
			check(false, "Could not capture the 1920×1080 Song Library viewport.")

	print("SONG_LIBRARY_RHYTHM_REDESIGN: ", "PASS" if failures == 0 else "FAIL", " ", failures)
	library.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures == 0 else 1)

func _is_bpm_sorted(selector: Control, ascending: bool) -> bool:
	for index in range(1, selector.filtered_song_ids.size()):
		var previous := float(selector._representative(selector.filtered_song_ids[index - 1]).get("bpm", 0.0))
		var current := float(selector._representative(selector.filtered_song_ids[index]).get("bpm", 0.0))
		if ascending and previous > current:
			return false
		if not ascending and previous < current:
			return false
	return true
