extends SceneTree

const ScoreIdentity = preload("res://scripts/score_identity.gd")
const UserSettings = preload("res://scripts/user_settings.gd")
const Palette = preload("res://scripts/ui/minimal_theme.gd")
const VectorIcon = preload("res://scripts/ui/library_vector_icon.gd")

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
	if OS.get_environment("BEAT_UP_QA_SONG_LIBRARY") != "isolated":
		push_error("Run with isolated APPDATA/XDG_DATA_HOME and BEAT_UP_QA_SONG_LIBRARY=isolated.")
		quit(2)
		return
	var scene := load("res://scenes/song_library.tscn") as PackedScene
	var library := scene.instantiate() as Control
	root.add_child(library)
	await process_frame
	await process_frame
	await create_timer(0.35).timeout
	var selector := library.song_select as Control
	# First interaction has no prior tween; successive input must retire the
	# previous animation, not print a missing-metadata error or stack tweens.
	var motion_probe := Button.new()
	library.add_child(motion_probe)
	var polish := preload("res://scripts/ui/interaction_polish.gd")
	polish.install_buttons([motion_probe])
	check(not motion_probe.has_meta(polish.TWEEN_META), "Motion probe unexpectedly has a prior tween.")
	motion_probe.focus_entered.emit()
	var first_motion := motion_probe.get_meta(polish.TWEEN_META) as Tween
	check(first_motion != null and first_motion.is_valid(), "First focus did not create a micro-tween.")
	motion_probe.button_down.emit()
	var pressed_motion := motion_probe.get_meta(polish.TWEEN_META) as Tween
	check(not first_motion.is_valid() and pressed_motion != first_motion and pressed_motion.is_valid(), "Press did not supersede the prior focus tween.")
	motion_probe.button_up.emit()
	check(not pressed_motion.is_valid(), "Release did not supersede the press tween.")
	motion_probe.queue_free()
	await process_frame

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
	var title_block := selector.title_label.get_parent() as Control
	var library_toolbar := selector.search_input.get_parent() as Control
	check(title_block != null and library_toolbar != null and title_block.get_index() < library_toolbar.get_index(), "Song Library title is not placed before the search/filter toolbar.")
	check(title_block.get_global_rect().end.x <= selector.search_input.get_global_rect().position.x, "Song Library title overlaps or trails the search field.")
	check(selector.header_row.size.y <= 50.0, "Song Library top rail is taller than the approved mockup.")
	for top_control: Control in [selector.back_button, selector.search_input, selector.artist_filter, selector.difficulty_filter, selector.sort_filter]:
		check(top_control.custom_minimum_size.y <= 40.0, "%s is taller than the approved top-bar control scale." % top_control.name)
	var search_normal := selector.search_input.get_theme_stylebox("normal") as StyleBoxFlat
	var search_focus := selector.search_input.get_theme_stylebox("focus") as StyleBoxFlat
	var filter_normal := selector.artist_filter.get_theme_stylebox("normal") as StyleBoxFlat
	var filter_hover := selector.artist_filter.get_theme_stylebox("hover") as StyleBoxFlat
	var filter_focus := selector.artist_filter.get_theme_stylebox("focus") as StyleBoxFlat
	check(search_normal != null and is_equal_approx(search_normal.bg_color.a, 0.56), "Search surface is not dark enough to separate from the artwork.")
	check(filter_normal != null and is_equal_approx(filter_normal.bg_color.a, 0.50), "Filter surface does not preserve the intended translucent contrast.")
	check(search_normal.bg_color.a > filter_normal.bg_color.a, "Search must remain slightly darker than the filter controls.")
	check(filter_normal.border_color.a >= 0.30 and filter_normal.border_color.a <= 0.38, "Filter border contrast is outside the approved range.")
	check(is_equal_approx(filter_hover.border_color.a, 0.65) or filter_hover.border_color.a > 0.65, "Filter hover does not expose the cyan edge clearly enough.")
	check(search_focus.border_width_left == 2 and filter_focus.border_width_left == 2, "Top controls do not expose a 2 px focus edge.")
	check(search_focus.shadow_size == 0 and filter_focus.shadow_size == 0, "Toolbar focus must use a crisp edge, not glow.")
	check(search_normal.corner_radius_top_left <= 2 and filter_normal.corner_radius_top_left <= 2, "Toolbar is too rounded.")
	var filter_text_alpha: float = selector.artist_filter.get_theme_color("font_color").a
	check(is_equal_approx(filter_text_alpha, 0.84) or filter_text_alpha > 0.84, "Filter text is too transparent against the artwork.")
	check(selector.back_button.get_theme_color("font_color").a >= 0.85, "Back text is too transparent against the artwork.")
	check(selector.sort_filter.is_visible_in_tree() and selector.sort_filter.text == "BPM ASC", "Custom sort control or default BPM ascending mode is missing.")
	check(selector.sort_filter.get_item_count() == 2 and selector.sort_filter.get_item_text(0) == "BPM Asc" and selector.sort_filter.get_item_text(1) == "BPM Desc", "Release-facing sort options drifted beyond BPM ascending/descending.")
	check(selector.artist_filter.is_visible_in_tree() and selector.difficulty_filter.is_visible_in_tree(), "Primary Artist/Difficulty header filters are missing.")
	var search_icon := selector.search_input.get_node_or_null("SearchIcon") as TextureRect
	check(search_icon != null and search_icon.texture != null, "Canonical SVG search icon is missing from the search field.")
	check(selector.find_child("LibraryFilterButton", true, false) == null, "Legacy overflow/ellipsis control leaked into the mockup-matched top bar.")
	check(selector.album_flow_difficulty_row.is_visible_in_tree(), "Difficulty selector is not permanently visible.")
	check(selector.album_flow_difficulty_row.get_child_count() == 3, "Normal, Hard, and Master selectors are not all represented.")
	check(selector.play_button.is_visible_in_tree() and not selector.play_button.disabled, "Play is not visibly available for the selected chart.")
	check(selector.album_flow_mode_4_button.is_visible_in_tree() and selector.album_flow_mode_8_button.is_visible_in_tree(), "Inline 4K/8K mode controls are missing.")
	check(selector.album_flow_random_button.is_visible_in_tree(), "Inline Random mod is missing.")
	var selected_difficulty_button := selector.album_flow_difficulty_row.get_node_or_null("%sDifficultyButton" % selector.selected_difficulty.capitalize()) as Button
	check(selected_difficulty_button != null and selected_difficulty_button.get_node_or_null("SelectionMarker") != null and selected_difficulty_button.get_node("SelectionMarker").visible, "Selected difficulty does not show the mockup-style top diamond marker.")
	var active_mode_button: Button = selector.album_flow_mode_4_button if UserSettings.get_input_style() == "4_arrow" else selector.album_flow_mode_8_button
	check(active_mode_button.get_node_or_null("SelectionMarker") != null and active_mode_button.get_node("SelectionMarker").visible, "Active input mode does not show the mockup-style top diamond marker.")
	check(selector.album_flow_random_button.find_child("StateLabel", true, false) != null, "Random button is missing its mockup-style state label.")
	check(selector.practice_button.find_child("StateLabel", true, false) != null, "Practice button is missing its mockup-style state label.")
	check(selector.play_button.find_child("PlayIcon", true, false) != null and selector.play_button.find_child("PlayDivider", true, false) != null and selector.play_button.find_child("PlayArrow", true, false) != null, "Play button is missing the mockup-style icon/divider/arrow composition.")
	check(selector.practice_button.is_visible_in_tree() and selector.practice_button.pressed.get_connections().size() > 0, "Practice action is missing or disconnected.")
	check(selector.album_flow_artwork.size.x >= 400.0 and selector.album_flow_artwork.size.y >= 400.0, "Selected jacket is not a large focal point at 1920×1080.")
	check(selector.album_flow_artwork.size.x >= 570.0 and selector.album_flow_artwork.size.y >= 570.0, "Selected jacket does not match the mockup's dominant 1920×1080 scale.")
	check(selector.album_flow_artwork_frame != null and selector.album_flow_artwork_frame.get_child_count() == 8, "Selected jacket is missing its luminous corner framing.")
	check(selector.album_flow_record_panel != null and selector.album_flow_record_panel.get_parent() == selector.album_flow_center_column, "Best Record is not in the center inspection column.")
	check(selector.album_flow_record_panel.get_theme_stylebox("panel") is StyleBoxEmpty, "Best Record still renders an opaque/dark panel background.")
	check(not selector.album_flow_record_panel.get_global_rect().intersects(selector.album_flow_artwork.get_global_rect()), "Best Record overlaps the selected artwork.")
	check(selector.album_flow_record_breakdown_row != null and selector.album_flow_record_breakdown_row.get_child_count() == 7, "Judgement breakdown is incomplete.")
	check(selector.album_flow_score_cluster != null and selector.album_flow_score_cluster.get_global_rect().position.y >= selector.album_flow_artwork.get_global_rect().end.y, "Best-score hierarchy is not positioned beneath the jacket.")
	check(selector.album_flow_difficulty_row.get_parent() == selector.album_flow_sidebar, "Difficulty selector is not in the configuration column.")
	check(selector.album_flow_mode_row.get_parent() == selector.album_flow_sidebar and selector.album_flow_modifier_row.get_parent() == selector.album_flow_sidebar, "Mode/mod controls are not in the configuration column.")
	check(selector.play_button.get_parent() == selector.album_flow_sidebar and selector.play_button.size.y >= 70.0, "Play is not the dominant bottom-right call to action.")
	check(selector.find_child("AlbumFlowBottomPanel", true, false) == null, "Legacy detached Difficulty/Play dock still exists.")
	check(selector.album_flow_list_header != null and selector.album_flow_list_header.is_visible_in_tree(), "Dense song-list column header is missing.")
	check(selector.backdrop_visual.is_visible_in_tree() and selector.backdrop_visual.modulate.a > 0.0 and selector.backdrop_visual.modulate.a <= 0.08, "Selected-song background atmosphere is missing or too strong.")
	check(selector.find_child("SongLibraryAmbient", true, false) == null, "Dead abstract ambient geometry still exists in the release composition.")
	check(selector.album_flow_meta_line != null and selector.album_flow_meta_line.text.contains("BPM"), "Inline song metadata is missing.")
	check(selector.album_flow_prev_song_button != null and selector.album_flow_next_song_button != null, "Track previous/next controls are missing.")

	# #19 data-binding contract: release-facing metadata must come from the selected catalog entry,
	# never from the design mockup or song-specific hardcoded presentation data.
	var initial_rep: Dictionary = selector._representative(selector.selected_song_id)
	var initial_chart: Dictionary = selector._find_level(selector.selected_song_id, selector.selected_difficulty)
	check(selector.detail_title.text == str(initial_rep.get("title", "SONG")), "Selected title is not bound to catalog metadata.")
	check(selector.detail_meta.text == selector._display_artist(initial_rep), "Selected artist is not bound to catalog metadata.")
	var expected_bpm := int(round(float(initial_rep.get("bpm", 0.0))))
	var expected_duration: String = selector._format_duration(float(initial_chart.get("duration", initial_rep.get("duration", 0.0))))
	check(selector.album_flow_meta_line.text.contains("%d BPM" % expected_bpm), "Selected BPM is not bound to catalog metadata.")
	check(selector.album_flow_meta_line.text.contains(expected_duration), "Selected duration is not bound to chart metadata.")
	var global_state: Dictionary = root.get_node("SongSelectionState").get_state()
	check(str(global_state.get("song_id", "")) == selector.selected_song_id and str(global_state.get("difficulty_id", "")) == selector.selected_difficulty, "Canonical SongSelectionState is out of sync with the visible selection.")

	var selected_index: int = selector.filtered_song_ids.find(selector.selected_song_id)
	check(selected_index >= 0, "No initial song was selected.")
	if selected_index >= 0:
		var selected_button := selector.song_buttons[selected_index] as Button
		check(selected_button.custom_minimum_size.y >= 68.0 and selected_button.custom_minimum_size.y <= 72.0, "Selected song row does not match the mockup's scanning rhythm.")
		var jacket := selected_button.find_child("SongJacket", true, false) as TextureRect
		check(jacket != null and jacket.custom_minimum_size.x >= 54.0 and jacket.custom_minimum_size.x <= 60.0, "Selected row jacket size does not match the mockup hierarchy.")
		var title := selected_button.find_child("SongTitle", true, false) as Label
		var artist := selected_button.find_child("SongArtist", true, false) as Label
		check(title != null and artist != null and title.get_parent() == artist.get_parent() and title.get_parent() is VBoxContainer, "Song title and artist are not stacked like the mockup.")
	check(selector.detail_title.get_theme_font_size("font_size") >= 38, "Selected-song title hierarchy is too small.")
	check(selector.play_button.custom_minimum_size.y >= 96.0 and selector.play_button.custom_minimum_size.y <= 108.0, "Play button is not dominant enough at 1920×1080.")
	var play_style := selector.play_button.get_theme_stylebox("normal") as StyleBoxFlat
	check(play_style != null and play_style.shadow_size == 0, "Play must use an outline, not neon bloom.")

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

	# #21 keyboard interaction contract: search shortcut and Escape own local focus before Back.
	var focus_search := InputEventKey.new()
	focus_search.pressed = true
	focus_search.keycode = KEY_F
	focus_search.ctrl_pressed = true
	selector._unhandled_key_input(focus_search)
	check(selector.search_input.has_focus(), "Ctrl+F no longer focuses Song Library search.")
	selector.search_input.text = "temporary"
	var escape_search := InputEventKey.new()
	escape_search.pressed = true
	escape_search.keycode = KEY_ESCAPE
	selector._unhandled_key_input(escape_search)
	await process_frame
	check(selector.search_input.text.is_empty() and not selector.search_input.has_focus(), "Escape did not clear/release search before navigation.")

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
	selector.selected_artist_filter = "Crywolf"
	selector._apply_filters(false)
	check(not selector.filtered_song_ids.is_empty() and selector.filtered_song_ids.all(func(song_id: String) -> bool: return selector._display_artist(selector._representative(song_id)) == "Crywolf"), "Artist filter no longer selects actual artist metadata.")
	selector.selected_artist_filter = "All Artists"
	selector._apply_filters(false)
	var before_next: String = selector.selected_song_id
	selector.album_flow_next_song_button.pressed.emit()
	check(selector.selected_song_id != before_next, "Next-song action did not change selection.")
	selector.album_flow_prev_song_button.pressed.emit()
	check(selector.selected_song_id == before_next, "Previous-song action did not restore selection.")

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

	var state_song_before_modes: String = selector.selected_song_id
	var state_diff_before_modes: String = selector.selected_difficulty
	var resident_row_before_modes: Button = selector.song_buttons[0] as Button
	var resident_row_id_before_modes := resident_row_before_modes.get_instance_id()
	selector._on_mode_4_selected()
	await process_frame
	check(UserSettings.get_input_style() == "4_arrow" and selector.notes_value.text == "4 KEY", "4K mode did not refresh metadata.")
	check(selector.selected_song_id == state_song_before_modes and selector.selected_difficulty == state_diff_before_modes, "4K switch changed logical song/difficulty selection.")
	check((selector.song_buttons[0] as Button).get_instance_id() == resident_row_id_before_modes, "4K switch rebuilt the entire resident song list unnecessarily.")
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
	check((selector.song_buttons[0] as Button).get_instance_id() == resident_row_id_before_modes, "Random toggle rebuilt the entire resident song list unnecessarily.")
	check(selector.selected_song_id == state_song_before_modes and selector.selected_difficulty == state_diff_before_modes, "Random toggle changed logical song/difficulty selection.")
	check(selector.album_flow_random_button.find_child("StateLabel", true, false).text == "ON", "Random text does not reflect actual state.")
	selector.album_flow_random_button.grab_focus()
	check(selector.album_flow_random_button.has_focus(), "Mod controls lost keyboard focus.")
	selector._on_random_mod_toggled(false)

	var chart: Dictionary = selector._find_level(selector.selected_song_id, selector.selected_difficulty)
	var score_key: String = ScoreIdentity.key(chart, UserSettings.get_input_style(), false)
	selector.set_best_stats_store({score_key: {"score": 10680000, "best_accuracy": 98.42, "best_rank": "S", "best_max_combo": 512, "cleared": true}})
	await process_frame
	check(selector.album_flow_best_rank_value.text == "S", "Best rank did not refresh.")
	check(selector.album_flow_best_score_value.text == "10,680,000", "Best score did not refresh or format correctly.")
	check(selector.album_flow_best_accuracy_value.text == "98.42%", "Best accuracy did not refresh.")
	check(selector.album_flow_best_combo_value.text.contains("512"), "MAX COMBO was lost.")
	check(selector.album_flow_score_cluster.find_child("RecordDate", true, false).text.is_empty(), "A timestamp was invented for a legacy record.")
	selector.set_best_stats_store({score_key: {"score": 10680000, "best_accuracy": 98.42, "best_rank": "S", "best_max_combo": 512, "completed_at": 1700000000, "perfect": 432, "great": 36, "good": 8, "miss": 1}})
	selector._apply_theme_config()
	await process_frame
	check(selector.album_flow_score_cluster.find_child("RecordDate", true, false).text == "2023-11-14 22:13", "Stored record timestamp was not displayed.")
	_check_presentation(selector)
	check(selector.album_flow_record_perfect_value.text == "432", "Judgement values were lost on restyling.")
	var diamond := selector.album_flow_best_card.get_node("RankDiamond") as TextureRect
	check(diamond.get_script() == VectorIcon and diamond.get("kind") == "rank" and diamond.texture != null, "Rank must use the canonical SVG-backed diamond asset.")
	check(selector.album_flow_best_card.get_theme_stylebox("panel") is StyleBoxEmpty, "A rectangle is still drawn behind the rank.")
	check(selector.practice_button.find_child("StateLabel", true, false).text == "SELECT", "Practice was misrepresented as an ON/OFF modifier.")
	check(not selector.practice_button.disabled, "Practice unexpectedly disabled for a playable chart.")
	selector.practice_button.pressed.emit()
	await process_frame
	check(is_instance_valid(selector.practice_popup._panel) and selector.practice_popup._panel.is_visible_in_tree(), "Practice no longer opens the section selector.")
	selector.practice_popup.close(true)
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

	# Nine-digit scores, tall titles and selected state must fit actual containers.
	selector.set_best_stats_store({score_key: {"score": 999999999, "best_accuracy": 100.0, "best_rank": "SS", "best_max_combo": 9999}})
	var responsive_song: String = selector.selected_song_id
	var responsive_difficulty: String = selector.selected_difficulty
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]:
		root.size = resolution
		root.content_scale_size = resolution
		await create_timer(0.4).timeout
		selector._center_selected_row(false)
		await process_frame
		await process_frame
		_check_layout(selector, resolution)
		check(selector.selected_song_id == responsive_song and selector.selected_difficulty == responsive_difficulty, "Responsive relayout changed logical selection at %s." % resolution)
		if OS.get_cmdline_user_args().has("capture"):
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("user://library_%dx%d.png" % [resolution.x, resolution.y])
	var original_audio: String = str(chart.audio)
	chart.audio = "res://music/qa_missing_visual_fixture.ogg"
	selector._update_detail(false)
	await process_frame
	check(selector.play_button.disabled and selector.practice_button.disabled, "Unavailable chart actions remain enabled.")
	check(not selector.play_button.find_child("PlayIcon", true, false).visible, "Unavailable Play retains the launch icon.")
	chart.audio = original_audio
	selector._update_detail(false)
	await process_frame
	check(not selector.play_button.disabled, "Play did not recover when valid audio returned.")
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i(1920, 1080)
	await process_frame
	await process_frame

	if OS.get_cmdline_user_args().has("capture"):
		var image := root.get_texture().get_image()
		if image != null and not image.is_empty():
			image.save_png("user://song_library_rhythm_redesign_1920x1080.png")
			print("CAPTURE: ", ProjectSettings.globalize_path("user://song_library_rhythm_redesign_1920x1080.png"))
		else:
			check(false, "Could not capture the 1920×1080 Song Library viewport.")

	print("SONG_LIBRARY_RHYTHM_REDESIGN: ", "PASS" if failures == 0 else "FAIL", " ", failures)
	library.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures == 0 else 1)

func _check_presentation(selector: Control) -> void:
	var values: Array = [selector.album_flow_record_perfect_value, selector.album_flow_record_great_value, selector.album_flow_record_good_value, selector.album_flow_record_miss_value]
	var colors: Array[Color] = [Palette.PERFECT_PINK, Palette.GREAT_GREEN, Palette.GOOD_CYAN, Palette.MISS_RED]
	for index in range(values.size()):
		var value: Label = values[index]
		check(value.get_theme_color("font_color").is_equal_approx(colors[index]), "Theme pass erased a semantic judgement color.")
		check(value.get_theme_font_size("font_size") >= 21, "Judgement numeric hierarchy was erased.")
		var caption := value.get_parent().get_child(0) as Label
		check(caption.get_theme_color("font_color").is_equal_approx(Color(colors[index], 0.9)), "Judgement caption lost its semantic color.")
	for button: Button in [selector.album_flow_mode_8_button, selector.album_flow_random_button, selector.practice_button]:
		check((button.get_theme_stylebox("normal") as StyleBoxFlat).shadow_size == 0, "Configuration controls regained glow.")
	for icon_name in ["PlayIcon", "PlayArrow"]:
		var icon := selector.play_button.find_child(icon_name, true, false) as TextureRect
		check(icon != null and icon.get_script() == VectorIcon and icon.texture != null, "Play must use the canonical SVG-backed icon library.")
	for button: Button in selector.album_flow_difficulty_row.get_children():
		var marker := button.get_node("SelectionMarker") as TextureRect
		check(marker.get_script() == VectorIcon and marker.texture != null, "Difficulty selection must use the canonical SVG-backed diamond asset.")
		check(marker.visible == (button.name == "%sDifficultyButton" % selector.selected_difficulty.capitalize()), "Rebuilt difficulty selection marker is stale.")

func _check_layout(selector: Control, resolution: Vector2i) -> void:
	for control: Control in [selector.header_row, selector.wheel_column, selector.info_panel, selector.album_flow_center_column, selector.album_flow_sidebar, selector.album_flow_record_panel, selector.play_button]:
		var rect := control.get_global_rect()
		check(rect.position.x >= 0 and rect.end.x <= resolution.x + 1 and rect.end.y <= resolution.y + 1, "Viewport overflow: %s at %s" % [control.name, resolution])
	var previous_end := 0.0
	for control: Control in [selector.back_button, selector.title_label, selector.search_input, selector.artist_filter, selector.difficulty_filter, selector.sort_filter]:
		check(control.get_global_rect().position.x >= previous_end, "Header controls overlap.")
		previous_end = control.get_global_rect().end.x
	var accuracy_rect: Rect2 = selector.album_flow_best_accuracy_value.get_global_rect()
	var score_rect: Rect2 = selector.album_flow_best_score_value.get_global_rect()
	check(not accuracy_rect.intersects(score_rect), "Record values overlap.")
	check(score_rect.end.x <= selector.album_flow_best_card.get_global_rect().position.x, "Score overlaps diamond rank.")
	check(not selector.album_flow_artwork.get_global_rect().intersects(selector.album_flow_record_panel.get_global_rect()), "Record overlaps jacket.")
	check(not selector.album_flow_center_column.get_global_rect().intersects(selector.album_flow_sidebar.get_global_rect()), "Center inspection column overlaps right configuration column.")
	check(selector.play_button.get_global_rect().position.y >= selector.album_flow_modifier_row.get_global_rect().end.y, "Play CTA is not anchored below Mode/Mods controls.")
	var row: Control = selector.song_buttons[selector.filtered_song_ids.find(selector.selected_song_id)]
	check(selector.song_scroll.get_global_rect().intersects(row.get_global_rect()), "Selected song is offscreen.")
	check(selector.album_flow_mode_8_button.button_pressed and not selector.album_flow_mode_4_button.button_pressed, "Layout refresh changed input-mode state.")
	_check_presentation(selector)

func _is_bpm_sorted(selector: Control, ascending: bool) -> bool:
	for index in range(1, selector.filtered_song_ids.size()):
		var previous := float(selector._representative(selector.filtered_song_ids[index - 1]).get("bpm", 0.0))
		var current := float(selector._representative(selector.filtered_song_ids[index]).get("bpm", 0.0))
		if ascending and previous > current:
			return false
		if not ascending and previous < current:
			return false
	return true
