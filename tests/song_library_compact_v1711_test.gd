extends SceneTree

var failures := 0

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)

func _run() -> void:
	var library := load("res://scenes/song_library.tscn").instantiate() as Control
	root.add_child(library)
	await process_frame
	await process_frame
	await create_timer(0.25).timeout
	var selector: Control = library.song_select

	_check(selector.backdrop_visual.visible, "Selected-song backdrop is not visible in compact Album Flow.")
	_check(selector.hero_panel.visible and selector.album_flow_artwork.is_visible_in_tree(), "Selected artwork should remain the compact layout focal point.")
	_check(selector.search_input.custom_minimum_size.y <= 36.0, "Search control is too tall at 1280×720.")
	_check(selector.play_button.custom_minimum_size.y <= 72.0, "Play CTA did not compact at 1280×720.")
	_check(selector.album_flow_mode_4_button.custom_minimum_size.y <= 46.0 and selector.album_flow_mode_8_button.custom_minimum_size.y <= 46.0, "Mode controls did not compact.")
	_check(selector.album_flow_random_button.custom_minimum_size.y <= 60.0 and selector.note_speed_button.custom_minimum_size.y <= 60.0, "Secondary controls did not compact.")

	var rows: Array = selector.song_buttons
	_check(not rows.is_empty(), "Compact library generated no song rows.")
	if not rows.is_empty():
		var first := rows[0] as Button
		_check(first.custom_minimum_size.y <= 60.0, "Compact song row is oversized.")

	var selected_index: int = selector.filtered_song_ids.find(selector.selected_song_id)
	if selected_index >= 0:
		var difficulty_rows: Array = selector.song_difficulty_rows[selected_index]
		for row_value in difficulty_rows:
			var row := row_value as Dictionary
			_check((row["button"] as Button).custom_minimum_size.y <= 36.0, "Expanded difficulty strip is oversized in compact mode.")

	for control: Control in [selector.header_row, selector.wheel_column, selector.info_panel, selector.album_flow_record_panel, selector.play_button]:
		var rect := control.get_global_rect()
		_check(rect.position.x >= 0.0 and rect.end.x <= 1281.0 and rect.end.y <= 721.0, "Compact viewport overflow: %s" % control.name)

	library.queue_free()
	await process_frame
	print("SONG_LIBRARY_COMPACT_V1711_TEST: ", "PASS" if failures == 0 else "FAIL", " ", failures)
	quit(1 if failures > 0 else 0)
