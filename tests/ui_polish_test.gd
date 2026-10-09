extends SceneTree

const Palette = preload("res://scripts/ui/minimal_theme.gd")
var failures := 0
var capture_dir := OS.get_environment("BEAT_UP_QA_POLISH_CAPTURE_DIR")

func _initialize() -> void:
	if OS.get_environment("BEAT_UP_QA_POLISH") != "isolated":
		push_error("UI polish QA requires isolated user data.")
		quit(2)
		return
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func settle() -> void:
	for index in range(6):
		await process_frame

func capture(label: String) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(capture_dir.path_join(label + ".png"))

func run() -> void:
	root.get_node("AppSessionState").call("mark_splash_seen")
	var menu := (load("res://scenes/startup.tscn") as PackedScene).instantiate() as Control
	root.add_child(menu)
	await settle()
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]:
		root.size = resolution
		await settle()
		var rail := menu.get("now_playing_card") as Control
		for property in ["now_playing_kicker", "now_playing_title", "now_playing_artist", "duration_value", "prev_track_button", "play_pause_track_button", "next_track_button"]:
			var control := menu.get(property) as Control
			check(rail.get_global_rect().encloses(control.get_global_rect()), "Now Playing clips %s at %s" % [property, resolution])
		await capture("menu_%d" % resolution.x)
		menu.call("_show_settings")
		await create_timer(0.35).timeout
		for tab in range(3):
			menu.call("_set_settings_tab", tab)
			await settle()
			var back := menu.get("back_button") as Button
			var reset := menu.get("reset_defaults_button") as Button
			var bounds := Rect2(Vector2.ZERO, Vector2(resolution))
			check(bounds.encloses(back.get_global_rect()) and bounds.encloses(reset.get_global_rect()), "Settings navigation clipped at %s / tab %d" % [resolution, tab])
			check(not back.get_parent().get_parent() is ScrollContainer, "Settings actions must remain outside scrolling body")
			await capture("settings_%d_%d" % [resolution.x, tab])
		await menu.call("_hide_settings")
	root.remove_child(menu)
	menu.free()
	await settle()

	var library := (load("res://scenes/song_library.tscn") as PackedScene).instantiate() as Control
	root.add_child(library)
	await create_timer(0.6).timeout
	var select := library.get("song_select") as Control
	select.call("_on_search_changed", "zzzz_no_song_matches_zzzz")
	await settle()
	check(str(select.get("selected_song_id")).is_empty(), "Empty search kept a selected song")
	for property in ["hero_panel", "album_flow_record_panel", "album_flow_identity", "album_flow_difficulty_row"]:
		check(not (select.get(property) as Control).is_visible_in_tree(), "Empty search retained stale " + property)
	check((select.get("play_button") as Button).disabled, "Empty search allowed Play")
	var recovery := (select.get("song_list") as Node).get_node_or_null("ClearLibraryFilters") as Button
	check(recovery != null, "Empty search has no recovery action")
	await capture("library_empty")
	recovery.pressed.emit()
	await settle()
	check(not str(select.get("selected_song_id")).is_empty(), "Clear filters failed to recover selection")
	check((select.get("album_flow_record_panel") as Control).is_visible_in_tree(), "Recovery did not restore record presentation")
	check((select.get("album_flow_difficulty_row") as Control).is_visible_in_tree(), "Recovery did not rebuild difficulty presentation")
	select.call("_on_search_changed", "immortal flame")
	await settle()
	var track_title := select.get("detail_title") as Label
	check(track_title.get_line_count() > 1 and track_title.max_lines_visible == 2, "Long selected title must use its reserved two-line area")
	check(track_title.get_visible_line_count() == 2, "Long selected title clips its second line")
	await capture("library_long_title")
	for grade in Palette.RANK_COLORS:
		check(select.call("_rank_display_color", grade) == Palette.RANK_COLORS[grade], "Library rank palette disagrees for " + grade)
	var trigger := select.get("note_speed_button") as Button
	trigger.grab_focus()
	select.call("_open_note_speed")
	await settle()
	var dialog := select.get("note_speed_dialog") as AcceptDialog
	await settle()
	check((dialog.get("_scrim") as Control).is_visible_in_tree(), "Note Speed modal has no scrim")
	check((dialog.get("value_label") as Label).text.contains("TRAVEL TIME"), "Note Speed units are ambiguous")
	await capture("note_speed")
	dialog.close_requested.emit()
	await settle()
	check(not (dialog.get("_scrim") as Control).is_visible_in_tree(), "Note Speed left a blocking scrim")
	check(trigger.has_focus(), "Note Speed did not return focus to trigger")
	root.remove_child(library)
	library.free()
	await settle()

	var pause := (load("res://scenes/pause_menu.tscn") as PackedScene).instantiate() as Control
	root.add_child(pause)
	pause.show()
	pause.call("show_settings")
	await settle()
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]:
		root.size = resolution
		await settle()
		check(Rect2(Vector2.ZERO, Vector2(resolution)).encloses((pause.get("settings_panel") as Control).get_global_rect()), "Quick Settings clipped at " + str(resolution))
		await capture("quick_settings_%d" % resolution.x)
	(pause.get("master_slider") as HSlider).value = 37
	(pause.get("background_slider") as HSlider).value = 28
	check((pause.get("master_value") as Label).text == "37%", "Master volume value did not update")
	check((pause.get("background_value") as Label).text == "28%", "Background value did not update")
	root.remove_child(pause)
	pause.free()

	var track := (load("res://scenes/track.tscn") as PackedScene).instantiate() as Control
	root.add_child(track)
	await settle()
	var note := track.call("spawn_note", {"type": "normal", "target": 101.0, "travel_time": 1.5, "dx": 1.0, "dy": 0.0}) as RhythmNote
	track.call("update_note_positions", 100.0, 1.5, note)
	var old_target := note.target_time
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]:
		root.size = resolution
		await settle()
		var hit := track.get("hit_point") as Marker2D
		check(is_equal_approx(note.position.y + note.judgement_anchor.position.y, hit.position.y), "Frozen note did not relayout on resize")
		check(note.target_time == old_target and not note.judged, "Visual resize changed note timing/judgement")
	root.remove_child(track)
	track.free()
	await settle()
	print("UI_POLISH_TEST: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(0 if failures == 0 else 1)
