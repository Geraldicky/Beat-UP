extends SceneTree

var failures := 0

func check(ok: bool, message: String) -> void:
	if ok:
		return
	failures += 1
	push_error(message)

func _initialize() -> void:
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = root.size
	call_deferred("run")

func run() -> void:
	preload("res://scripts/user_settings.gd").set_input_style("8_direction")
	root.get_node("AppSessionState").mark_splash_seen()
	var shell := load("res://scenes/app_shell.tscn").instantiate() as Control
	root.add_child(shell)
	await create_timer(0.6).timeout
	await shell.show_song_library("un_owen_was_her", false)
	var s: Control = shell.song_library_screen.song_select
	await create_timer(0.25).timeout

	check(s.detail_title.text == "U.N. Owen Was Her? & Flowering Night (Koa Remix)", "Long selected title no longer binds correctly.")
	check(s.detail_title.get_line_count() <= 2, "Long selected title exceeds the intended two-line hierarchy.")
	check(s.find_child("CarouselTopFade", true, false) == null, "Artificial carousel shadow overlay returned.")
	check(s.album_flow_record_panel != null and s.album_flow_record_panel.get_parent() == s.album_flow_center_column, "Reusable Best Record component is not installed.")
	check(s.album_flow_difficulty_row.get_child_count() == 3, "Reusable difficulty cards are incomplete.")
	check(s.album_flow_mode_4_button != null and s.album_flow_mode_8_button != null, "Reusable mode buttons are missing.")
	check(s.album_flow_random_button != null and s.practice_button != null, "Reusable mod buttons are missing.")
	check(s.play_button.find_child("PlayIcon", true, false) != null, "Reusable Play component is missing its canonical icon.")
	check(s.sort_filter.get_item_count() == 2, "Release Song Library sort contract is not BPM Asc/Desc only.")

	var selected_index: int = s.filtered_song_ids.find(s.selected_song_id)
	check(selected_index >= 0, "Selected song is absent from visible rows.")
	if selected_index >= 0:
		var selected_difficulties: Array = s.song_difficulty_rows[selected_index]
		check(not selected_difficulties.is_empty(), "Selected song has no reusable difficulty rows.")
		check((selected_difficulties[0].button as Button).find_children("*", "Label", true, false).any(func(label: Label): return label.text.contains("NOTES")), "Difficulty row lost its note-count binding.")

	s.search_input.text = "no_match_fixture"
	s._on_search_changed(s.search_input.text)
	await process_frame
	check(s.filtered_song_ids.is_empty() and s.play_button.disabled, "Empty search does not disable launch.")
	s.search_input.clear()
	s._on_search_changed("")
	await process_frame

	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1440)]:
		root.size = resolution
		root.content_scale_size = resolution
		await create_timer(0.2).timeout
		for control: Control in [s.header_row, s.wheel_column, s.info_panel, s.album_flow_record_panel, s.play_button]:
			var rect := control.get_global_rect()
			check(rect.position.x >= 0.0 and rect.end.x <= resolution.x + 1 and rect.end.y <= resolution.y + 1, "Album Flow overflow: %s at %s" % [control.name, resolution])

	print("SONG_LIBRARY_REDESIGN: ", "PASS" if failures == 0 else "FAIL", " ", failures)
	shell.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
