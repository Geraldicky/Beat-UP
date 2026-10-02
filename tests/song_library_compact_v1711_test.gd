extends SceneTree

var failures := 0

func _initialize() -> void:
	root.size = Vector2i(1440, 900)
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)

func _run() -> void:
	var scene := load("res://main.tscn") as PackedScene
	var instance := scene.instantiate() as Control
	root.add_child(instance)
	await process_frame
	await process_frame

	var selector := instance.get_node("LevelSelect") as Control
	var backdrop := selector.get_node("BackdropVisual") as Control
	var hero := selector.get_node("MainMargin/RootVBox/Body/InfoPanel/InfoVBox/HeroPanel") as Control
	var import_button := selector.get_node("MainMargin/RootVBox/FooterPanel/Footer/ImportButton") as Button
	var refresh_button := selector.get_node("MainMargin/RootVBox/FooterPanel/Footer/RefreshButton") as Button
	var editor_button := selector.get_node("MainMargin/RootVBox/FooterPanel/Footer/EditorButton") as Button
	var search_input := selector.get_node("MainMargin/RootVBox/Body/WheelColumn/LibraryPanel/LibraryVBox/LibraryToolbar/SearchInput") as LineEdit

	_check(backdrop.visible, "v17.1.1 selected-song backdrop is not visible.")
	_check(not hero.visible, "Legacy selected-song hero card should be hidden in compact mode.")
	_check(not import_button.visible and not refresh_button.visible and not editor_button.visible, "Developer controls leaked into the player-facing library footer.")
	_check(search_input.custom_minimum_size.y <= 40.0, "Search control is still too tall for compact mode.")

	var rows: Array = selector.get("song_buttons")
	_check(not rows.is_empty(), "Compact library generated no song rows.")
	if not rows.is_empty():
		var first := rows[0] as Button
		_check(first.custom_minimum_size.y <= 60.0, "Collapsed/selected song row is still oversized.")

	selector.call("set_selected_song", "2_starting_over")
	await process_frame
	var filtered: Array = selector.get("filtered_song_ids")
	var index := filtered.find("2_starting_over")
	var difficulty_rows: Array = selector.get("song_difficulty_rows")
	if index >= 0 and index < difficulty_rows.size():
		for row_value in difficulty_rows[index]:
			var row := row_value as Dictionary
			_check((row["button"] as Button).custom_minimum_size.y <= 32.0, "Difficulty strip is not compact.")

	instance.queue_free()
	await process_frame
	if failures == 0:
		print("SONG_LIBRARY_COMPACT_V1711_TEST: PASS")
	else:
		print("SONG_LIBRARY_COMPACT_V1711_TEST: FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
