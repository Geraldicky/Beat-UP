extends SceneTree

const UserSettingsScript = preload("res://scripts/user_settings.gd")

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
	var original_song_id: String = UserSettingsScript.get_last_library_song_id()
	var original_difficulty: String = UserSettingsScript.get_last_library_difficulty()

	# Navigation state persistence should be explicit and sanitized.
	UserSettingsScript.remember_library_selection("big_daddy", "hard")
	_check(UserSettingsScript.get_last_library_song_id() == "big_daddy", "Song Library selection was not persisted.")
	_check(UserSettingsScript.get_last_library_difficulty() == "hard", "Song Library difficulty was not persisted.")

	UserSettingsScript.remember_library_selection("big_daddy", "invalid")
	_check(UserSettingsScript.get_last_library_difficulty() == "normal", "Invalid remembered difficulty was not sanitized.")

	# Restore user's pre-test navigation values.
	if not original_song_id.is_empty():
		UserSettingsScript.remember_library_selection(original_song_id, original_difficulty)
	else:
		var restore_config := UserSettingsScript.load_config()
		if restore_config.has_section("navigation"):
			restore_config.erase_section("navigation")
			restore_config.save(UserSettingsScript.SETTINGS_PATH)

	var pause_scene := load("res://scenes/pause_menu.tscn") as PackedScene
	var pause_menu := pause_scene.instantiate() as Control
	root.add_child(pause_menu)
	await process_frame
	var song_list_button := pause_menu.get_node("Center/MainPanel/MainVBox/PauseButtons/SongListButton") as Button
	var retry_button := pause_menu.get_node("Center/MainPanel/MainVBox/PauseButtons/RetryButton") as Button
	var settings_button := pause_menu.get_node("Center/MainPanel/MainVBox/PauseButtons/SettingsButton") as Button
	var resume_button := pause_menu.get_node("Center/MainPanel/MainVBox/PauseButtons/ResumeButton") as Button
	_check(resume_button.focus_neighbor_bottom == resume_button.get_path_to(retry_button), "Pause Resume → Retry focus neighbor missing.")
	_check(retry_button.focus_neighbor_bottom == retry_button.get_path_to(settings_button), "Pause Retry → Settings focus neighbor missing.")
	_check(settings_button.focus_neighbor_bottom == settings_button.get_path_to(song_list_button), "Pause Settings → Song Library focus neighbor missing.")
	_check(song_list_button.focus_neighbor_bottom == song_list_button.get_path_to(resume_button), "Pause Song Library → Resume circular focus neighbor missing.")
	pause_menu.queue_free()
	await process_frame

	var result_scene := load("res://scenes/result_screen.tscn") as PackedScene
	var result := result_scene.instantiate() as Control
	root.add_child(result)
	await process_frame
	_check(not bool(result.call("is_navigation_ready")), "Result actions must start locked before reveal completion.")
	result.call("_set_actions_enabled", true)
	_check(bool(result.call("is_navigation_ready")), "Result navigation-ready state did not unlock.")
	var result_back := result.get_node("MainMargin/RootVBox/BottomBar/BackButton") as Button
	var result_retry := result.get_node("MainMargin/RootVBox/BottomBar/ReplayButton") as Button
	_check(result_back.focus_neighbor_right == result_back.get_path_to(result_retry), "Result Back → Retry focus neighbor missing.")
	_check(result_retry.focus_neighbor_left == result_retry.get_path_to(result_back), "Result Retry → Back focus neighbor missing.")
	result.queue_free()
	await process_frame

	if failures == 0:
		print("MENU_NAVIGATION_V17410_TEST: PASS")
	else:
		print("MENU_NAVIGATION_V17410_TEST: FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
