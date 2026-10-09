extends SceneTree

var failures := 0

func check(ok: bool, message: String) -> void:
	if ok:
		return
	failures += 1
	push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.get_node("AppSessionState").mark_splash_seen()
	var shell := load("res://scenes/app_shell.tscn").instantiate() as Control
	root.add_child(shell)
	await create_timer(0.6).timeout
	await shell.show_song_library("bad_apple", false)
	var selection: Control = shell.song_library_screen.song_select
	selection.set_selected_song("bad_apple")
	selection._select_difficulty("normal")
	await process_frame

	var chart: Dictionary = selection._find_level("bad_apple", "normal")
	var key: String = preload("res://scripts/score_identity.gd").key(chart, preload("res://scripts/user_settings.gd").get_input_style(), false)
	selection.set_best_stats_store({key: {"score": 999999999, "best_accuracy": 98.25, "best_max_combo": 9999, "best_rank": "S", "perfect": 9999, "great": 15, "good": 2, "miss": 1, "completed_at": 1700000000}})
	await process_frame

	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]:
		root.size = resolution
		root.content_scale_size = resolution
		await create_timer(0.25).timeout
		for control: Control in [selection.header_row, selection.wheel_column, selection.info_panel, selection.album_flow_record_panel, selection.play_button]:
			var rect := control.get_global_rect()
			check(rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= resolution.x + 1 and rect.end.y <= resolution.y + 1, "Viewport overflow: %s at %s: %s" % [control.name, resolution, rect])
		check(not selection.album_flow_artwork.get_global_rect().intersects(selection.album_flow_record_panel.get_global_rect()), "Best Record overlaps selected artwork at %s." % resolution)
		for song_id: String in ["space_invaders", "diana_boncheva_feat_banya_beethoven_virus_full_version", "bad_apple"]:
			selection.set_selected_song(song_id)
			check(selection.get_selected_song_id() == song_id, "Layout fixture selection is missing: %s." % song_id)
			await create_timer(0.15).timeout
			var top_inset: int = selection.main_margin.get_theme_constant("margin_top")
			for control: Control in [selection.back_button, selection.title_label, selection.search_input, selection.artist_filter, selection.difficulty_filter, selection.sort_filter]:
				var rect := control.get_global_rect()
				check(rect.position.y >= top_inset - 1 and rect.end.y <= resolution.y, "Header clipped above safe inset: %s at %s (%s)." % [control.name, resolution, song_id])
			check(selection.play_button.get_global_rect().end.y <= resolution.y, "Keeping header visible pushed Play offscreen at %s (%s)." % [resolution, song_id])

	var original_audio: String = str(chart.get("audio", ""))
	chart["audio"] = "res://music/qa_missing_visual_fixture.ogg"
	selection._update_detail(false)
	await process_frame
	var play_title := selection.play_button.find_child("PlayTitle", true, false) as Label
	check(selection.play_button.disabled and play_title != null and play_title.text == "AUDIO MISSING", "Missing audio is not visible and launch-safe.")
	chart["audio"] = original_audio
	selection._update_detail(false)
	await process_frame
	check(not selection.play_button.disabled, "Play did not recover after audio was restored.")

	selection.search_input.text = "nothing_matches_layout_fixture"
	selection._on_search_changed(selection.search_input.text)
	await process_frame
	check(selection.filtered_song_ids.is_empty() and selection.play_button.disabled, "Empty search state still exposes launch.")

	print("LIBRARY_LAYOUT: ", "PASS" if failures == 0 else "FAIL", " ", failures)
	shell.queue_free()
	await process_frame
	quit(1 if failures else 0)
