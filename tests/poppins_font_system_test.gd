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

func _check_font(control: Control, expected_file: String, message: String) -> void:
	if control == null:
		_check(false, "%s (missing control)" % message)
		return
	var font := control.get_theme_font("font")
	_check(font != null and font.resource_path.ends_with(expected_file), "%s: %s" % [message, font.resource_path if font != null else "null"])

func _run() -> void:
	var startup_scene := load("res://scenes/startup.tscn") as PackedScene
	var startup := startup_scene.instantiate() as Control
	root.add_child(startup)
	await process_frame
	await process_frame
	_check_font(startup.get_node("MainMenu/MenuStack/PlayButton") as Control, "Poppins-Medium.ttf", "Main Menu action is not Poppins Medium")
	_check_font(startup.get_node("SettingsMenu/SettingsCenter/SettingsPanel/SettingsScroll/SettingsVBox/SettingsTitle") as Control, "Poppins-SemiBold.ttf", "Settings heading is not Poppins SemiBold")
	_check_font(startup.get_node("SettingsMenu/SettingsCenter/SettingsPanel/SettingsScroll/SettingsVBox/DisplaySettingsGroup/DisplayGrid/ResolutionOption") as Control, "Poppins-Medium.ttf", "Settings dropdown is not Poppins Medium")
	startup.queue_free()
	await process_frame

	var gameplay_scene := load("res://main.tscn") as PackedScene
	var gameplay := gameplay_scene.instantiate() as Control
	root.add_child(gameplay)
	await process_frame
	await process_frame
	await create_timer(0.08).timeout
	var selector := gameplay.get_node("LevelSelect") as Control
	_check_font(selector.get_node("MainMargin/RootVBox/HeaderRow/TitleBlock/TitleLabel") as Control, "Poppins-SemiBold.ttf", "Song Library title is not Poppins SemiBold")
	_check_font(selector.get_node("MainMargin/RootVBox/Body/WheelColumn/LibraryPanel/LibraryVBox/LibraryToolbar/SearchInput") as Control, "Poppins-Regular.ttf", "Search field is not Poppins Regular")
	_check_font(selector.get_node("MainMargin/RootVBox/Body/InfoPanel/InfoVBox/QuickStats/BpmCard/VBox/BpmValue") as Control, "IBMPlexMono-Regular.ttf", "BPM data no longer uses IBM Plex Mono")
	var song_buttons: Array = selector.get("song_buttons") as Array
	_check(not song_buttons.is_empty(), "Song Library produced no song rows")
	if not song_buttons.is_empty():
		_check_font(song_buttons[0] as Control, "Poppins-Medium.ttf", "Song row is not Poppins Medium")
	var difficulty_rows: Array = selector.get("song_difficulty_rows") as Array
	if not difficulty_rows.is_empty() and not (difficulty_rows[0] as Array).is_empty():
		var first_row := (difficulty_rows[0] as Array)[0] as Dictionary
		_check_font(first_row.get("button") as Control, "IBMPlexMono-Regular.ttf", "Difficulty data no longer uses IBM Plex Mono")
	else:
		_check(false, "Song Library produced no difficulty rows")

	gameplay.queue_free()
	await process_frame
	await process_frame
	if failures == 0:
		print("POPPINS_FONT_SYSTEM_TEST: PASS")
	else:
		print("POPPINS_FONT_SYSTEM_TEST: FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
