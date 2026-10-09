extends SceneTree

var capture_name := "startup"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		capture_name = args[0]
	root.size = Vector2i(1440, 900)
	call_deferred("_run_capture")

func _run_capture() -> void:
	match capture_name:
		"song_select", "gameplay", "countdown", "pause", "pause_retry", "result", "result_debug":
			await _capture_main_scene()
		"startup_result_debug":
			await _validate_startup_result_debug()
		"song_select_back":
			await _validate_song_select_back_to_menu()
		"loading_transition":
			await _validate_transition_layer_without_loading_ui()
		_:
			await _capture_startup_scene()
	for child in root.get_children():
		child.queue_free()
	await process_frame
	await process_frame
	quit()

func _capture_startup_scene() -> void:
	var scene := load("res://scenes/startup.tscn") as PackedScene
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	await process_frame
	if capture_name == "startup" and not (instance.get_node("Splash") as Control).visible:
		push_error("Cold startup must still show the splash screen")
	if capture_name in ["startup", "splash", "splash_auto"]:
		_validate_splash_screen(instance)
	if capture_name == "splash":
		await create_timer(0.42).timeout
		var reveal_window := instance.get_node("Splash/SplashLogoFrame/SplashLogoWindow") as Control
		var reveal_frame := instance.get_node("Splash/SplashLogoFrame") as Control
		if reveal_window.size.x <= 0.0 or reveal_window.size.x >= reveal_frame.size.x:
			push_error("Splash wordmark did not reveal progressively from left to right")
		_save_viewport(capture_name)
		return
	if capture_name == "splash_auto":
		await create_timer(3.15).timeout
		if (instance.get_node("Splash") as Control).visible or not (instance.get_node("MainMenu") as Control).visible:
			push_error("Splash animation did not enter the Main Menu automatically")
		return
	instance.call("_finish_splash")
	await create_timer(1.25).timeout
	if capture_name == "startup":
		await _validate_main_menu_layout(instance)
	if capture_name == "help":
		instance.call("_on_help_pressed")
	elif capture_name == "credits":
		instance.call("_on_credits_pressed")
	elif capture_name == "settings":
		instance.call("_show_settings")
	elif capture_name == "exit":
		instance.call("_on_exit_pressed")
		await create_timer(0.28).timeout
		_validate_exit_dialog(instance)
	elif capture_name == "calibration":
		instance.get_node("CalibrationScreen").call("open")
	elif capture_name == "main_calibration":
		instance.call("_on_quick_calibration_pressed")
		await process_frame
		if not instance.get_node("CalibrationScreen").visible or instance.get_node("MainMenu").visible:
			push_error("Direct Main Menu Calibration action did not open the calibration screen")
		instance.call("_on_calibration_back_requested")
		await create_timer(0.95).timeout
		if not instance.get_node("MainMenu").visible or instance.get_node("CalibrationScreen").visible:
			push_error("Calibration did not return to its Main Menu origin")
	await process_frame
	await process_frame
	if capture_name == "help":
		await _validate_how_to_play_layout(instance)
	elif capture_name == "settings":
		_validate_settings_system(instance)
	elif capture_name == "credits":
		_validate_credits_layout(instance)
	elif capture_name == "calibration":
		_validate_calibration_feedback(instance)
	_validate_interactive_layout(instance)
	_save_viewport(capture_name)

func _validate_startup_result_debug() -> void:
	var scene := load("res://scenes/startup.tscn") as PackedScene
	var startup := scene.instantiate()
	root.add_child(startup)
	current_scene = startup
	await process_frame
	await process_frame
	var debug_event := InputEventKey.new()
	debug_event.keycode = KEY_F4
	debug_event.pressed = true
	startup.call("_input", debug_event)
	await create_timer(0.90).timeout
	await process_frame
	await process_frame
	var main := current_scene as Control
	if main == null or main.name != "Main":
		push_error("F4 from startup did not transition to the main scene")
		return
	await create_timer(1.45).timeout
	_validate_result_debug(main)

func _validate_song_select_back_to_menu() -> void:
	var scene := load("res://main.tscn") as PackedScene
	var main := scene.instantiate() as Control
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame
	var selector := main.get_node("LevelSelect") as Control
	if not selector.visible:
		push_error("Song Select was not visible before testing Back")
	selector.call("_on_back_pressed")
	await create_timer(1.10).timeout
	await process_frame
	await process_frame
	var startup := current_scene as Control
	if startup == null or startup.name != "Startup":
		push_error("Song Select Back did not return to Startup")
		return
	var splash := startup.get_node("Splash") as Control
	var main_menu := startup.get_node("MainMenu") as Control
	if splash.visible:
		push_error("Song Select Back incorrectly displayed the splash screen")
	if not main_menu.visible:
		push_error("Song Select Back did not open the Main Menu directly")
	if has_meta("beat_up_return_to_main_menu"):
		push_error("Return-to-menu marker was not consumed by Startup")

func _validate_transition_layer_without_loading_ui() -> void:
	var transition := root.get_node_or_null("SceneTransition") as CanvasLayer
	if transition == null:
		push_error("Global SceneTransition autoload is missing")
		return
	if transition.get_node_or_null("TransitionRoot/Center") != null:
		push_error("Legacy loading Center must not exist")
	if transition.get_node_or_null("TransitionRoot/TransitionVisual") != null:
		push_error("Legacy LoadingTransitionVisual must not exist")
	var transition_root := transition.get_node("TransitionRoot") as Control
	if transition.layer < 100:
		push_error("Transition layer is not above scene UI")
	if not transition_root.get_global_rect().encloses(Rect2(Vector2.ZERO, root.size)):
		push_error("Transition layer does not cover the full viewport")
	if transition.get_node_or_null("TransitionRoot/SongLaunchVisual") == null:
		push_error("Seamless gameplay handoff visual is missing")

func _capture_main_scene() -> void:
	var scene := load("res://main.tscn") as PackedScene
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	await process_frame
	_validate_gameplay_sfx(instance)
	_validate_gameplay_layout(instance)
	if capture_name == "song_select":
		var selector := instance.get_node("LevelSelect") as Control
		var song_id := str(selector.call("get_selected_song_id"))
		var difficulty_id := str(selector.call("get_selected_difficulty"))
		selector.call("set_best_stats_store", {
			"%s::%s" % [song_id, difficulty_id]: {
				"rank": "A", "score": 46940, "accuracy": 94.27,
				"max_combo": 158, "perfect": 205, "great": 83,
				"good": 65, "miss": 7, "plays": 4,
			},
		})
		await _validate_song_select_layout(selector)
	elif capture_name == "gameplay":
		instance.call("start_level", 0)
		await _validate_score_roll(instance)
		_validate_note_arrow_colors()
		_validate_reverse_note_direction(instance)
		await _validate_judgment_motion(instance)
	elif capture_name == "countdown":
		instance.call("start_level", 0)
		instance.call("show_pause_overlay")
		instance.call("resume_gameplay")
		await process_frame
		_validate_gameplay_countdown(instance, true)
		instance.call("_update_resume_countdown", 3.2)
		await process_frame
		_validate_gameplay_countdown(instance, false)
	elif capture_name == "pause":
		instance.call("start_level", 0)
		instance.call("show_pause_overlay")
		await process_frame
		_validate_pause_menu(instance)
	elif capture_name == "pause_retry":
		instance.call("start_level", 0)
		instance.call("show_pause_overlay")
		instance.call("retry_gameplay")
		await create_timer(0.82).timeout
		_validate_pause_retry(instance)
	elif capture_name == "result":
		instance.call("start_level", 0)
		instance.set("score", 128450)
		instance.set("total_hits", 118)
		instance.set("perfect_hits", 92)
		instance.set("great_hits", 20)
		instance.set("total_misses", 2)
		instance.set("max_combo", 83)
		instance.set("space_hits", 4)
		instance.set("space_misses", 1)
		instance.set("reverse_hits", 6)
		instance.call("end_fight")
	elif capture_name == "result_debug":
		var best_before := JSON.stringify(instance.get("best_stats_store"))
		var debug_event := InputEventKey.new()
		debug_event.keycode = KEY_F4
		debug_event.pressed = true
		instance.call("_input", debug_event)
		if JSON.stringify(instance.get("best_stats_store")) != best_before:
			push_error("Result debug shortcut must not mutate personal-best data")
	await process_frame
	await process_frame
	if capture_name == "result":
		await create_timer(0.55).timeout
		_validate_result_motion(instance)
		await create_timer(0.90).timeout
		_validate_result_layout(instance)
	elif capture_name == "result_debug":
		await create_timer(1.45).timeout
		_validate_result_debug(instance)
	match capture_name:
		"song_select", "result", "result_debug":
			_validate_gameplay_layer_visibility(instance, false)
		"gameplay", "countdown", "pause", "pause_retry":
			_validate_gameplay_layer_visibility(instance, true)
	_validate_interactive_layout(instance)
	_save_viewport(capture_name)

func _capture_scene(scene_path: String) -> void:
	var scene := load(scene_path) as PackedScene
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	await process_frame
	_validate_interactive_layout(instance)
	_save_viewport(capture_name)

func _validate_interactive_layout(node: Node) -> void:
	for candidate in node.find_children("*", "Button", true, false):
		var button := candidate as Button
		if button != null and button.is_visible_in_tree() and (button.size.x < 2.0 or button.size.y < 2.0):
			push_error("Visible button has invalid size: %s %s" % [button.get_path(), button.size])

func _validate_settings_system(instance: Control) -> void:
	var display_group := instance.get_node("SettingsMenu/SettingsCenter/SettingsPanel/SettingsScroll/SettingsVBox/DisplaySettingsGroup") as Control
	var audio_group := instance.get_node("SettingsMenu/SettingsCenter/SettingsPanel/SettingsScroll/SettingsVBox/AudioSettingsGroup") as Control
	var timing_group := instance.get_node("SettingsMenu/SettingsCenter/SettingsPanel/SettingsScroll/SettingsVBox/TimingSettingsGroup") as Control
	if not display_group.visible or audio_group.visible or timing_group.visible:
		push_error("Settings did not open on the Display tab")
	instance.call("_set_settings_tab", 1)
	if display_group.visible or not audio_group.visible or timing_group.visible:
		push_error("Audio settings tab did not switch sections")
	var sfx_toggle := instance.get_node("SettingsMenu/SettingsCenter/SettingsPanel/SettingsScroll/SettingsVBox/AudioSettingsGroup/MenuSFXToggle") as CheckButton
	var sfx_slider := instance.get_node("SettingsMenu/SettingsCenter/SettingsPanel/SettingsScroll/SettingsVBox/AudioSettingsGroup/MenuSFXRow/MenuSFXSlider") as HSlider
	if sfx_toggle == null or sfx_slider == null:
		push_error("Menu SFX settings are missing")
	var resolution_option := instance.get_node("SettingsMenu/SettingsCenter/SettingsPanel/SettingsScroll/SettingsVBox/DisplaySettingsGroup/DisplayGrid/ResolutionOption")
	var option_style := resolution_option.get_theme_stylebox("normal") as StyleBoxFlat
	if option_style == null or option_style.get_corner_radius(CORNER_TOP_LEFT) != 8 or resolution_option.get_theme_icon("arrow") == null:
		push_error("Settings dropdowns are still missing the Beat UP! custom treatment")
	var grabber := sfx_slider.get_theme_icon("grabber")
	var slider_fill := sfx_slider.get_theme_stylebox("grabber_area") as StyleBoxFlat
	var fill_matches_accent := slider_fill != null and absf(slider_fill.bg_color.r - MinimalTheme.CYAN.r) < 0.01 and absf(slider_fill.bg_color.g - MinimalTheme.CYAN.g) < 0.01 and absf(slider_fill.bg_color.b - MinimalTheme.CYAN.b) < 0.01
	if grabber == null or grabber.get_width() < 18 or not fill_matches_accent:
		push_error("Settings sliders are still using the default Godot visuals")
	var display_hint := instance.get_node("SettingsMenu/SettingsCenter/SettingsPanel/SettingsScroll/SettingsVBox/DisplaySettingsGroup/DisplayHint") as Label
	if display_hint.visible or not display_hint.text.is_empty():
		push_error("Display status copy should be hidden")
	var forbidden_settings_copy := ["KEEP THE PRESENTATION QUIET", "MENU FEEDBACK IS SYNTHESIZED", "APPLIED •"]
	for label_node in instance.get_node("SettingsMenu").find_children("*", "Label", true, false):
		var copy := (label_node as Label).text.to_upper()
		for forbidden in forbidden_settings_copy:
			if forbidden in copy:
				push_error("Settings still contain removed helper copy: %s" % forbidden)
	instance.call("_set_settings_tab", 2)
	if not timing_group.visible:
		push_error("Gameplay & Timing settings tab did not switch sections")
	var menu_sfx := root.get_node_or_null("MenuSFX")
	if menu_sfx == null or menu_sfx.get_child_count() < 4:
		push_error("Global procedural Menu SFX manager is not ready")

func _validate_splash_screen(instance: Control) -> void:
	var splash := instance.get_node("Splash") as Control
	var black := splash.get_node("SplashBlack") as ColorRect
	var frame := splash.get_node("SplashLogoFrame") as Control
	var logo := splash.get_node("SplashLogoFrame/SplashLogoWindow/SplashLogo") as Control
	var wipe := splash.get_node("SplashLogoFrame/SplashWipe") as ColorRect
	if black == null or black.color != Color.BLACK:
		push_error("Splash background is not pure black")
	if frame == null or logo == null or wipe == null or logo.get_script() == null:
		push_error("Splash BEAT UP! wordmark reveal structure is incomplete")
	for removed_node in ["SplashEyebrow", "SplashTagline", "SplashOrbit", "SplashHint"]:
		if splash.has_node(removed_node):
			push_error("Splash still contains removed element: %s" % removed_node)
	for label_node in splash.find_children("*", "Label", true, false):
		var copy := (label_node as Label).text.to_upper()
		if "NUMPAD BLADE" in copy or "PRESS ANY KEY" in copy or "A MINIMAL RHYTHM GAME" in copy or "EIGHT DIRECTIONS" in copy:
			push_error("Splash still exposes legacy copy")

func _validate_credits_layout(instance: Control) -> void:
	var credits := instance.get_node("CreditsScreen") as Control
	var mark := instance.get_node("CreditsScreen/CreditsMargin/CreditsVBox/CreditsBody/CreditsVisualPanel/CreditsVisual/CreditsMark") as Label
	var info_panel := instance.get_node("CreditsScreen/CreditsMargin/CreditsVBox/CreditsBody/CreditsInfoPanel") as PanelContainer
	var visual_panel := instance.get_node("CreditsScreen/CreditsMargin/CreditsVBox/CreditsBody/CreditsVisualPanel") as PanelContainer
	if not credits.visible or "BEAT UP" not in mark.text.to_upper():
		push_error("Credits screen is not branded for Beat UP!")
	if info_panel.get_global_rect().intersects(visual_panel.get_global_rect()):
		push_error("Credits panels overlap")
	for label_node in credits.find_children("*", "Label", true, false):
		if "NUMPAD BLADE" in (label_node as Label).text.to_upper():
			push_error("Credits still expose the old working title")

func _validate_calibration_feedback(instance: Control) -> void:
	var calibration := instance.get_node("CalibrationScreen") as Control
	var graph := calibration.get_node("Center/Panel/VBox/TimingGraphPanel/TimingGraph") as CalibrationTimingGraph
	var quality := calibration.get_node("Center/Panel/VBox/QualityLabel") as Label
	if graph == null or quality == null:
		push_error("Calibration timing feedback graph is missing")
		return
	graph.add_sample(-24.0)
	graph.add_sample(18.0)
	graph.set_result(4.0, 10.0)
	if graph.samples_ms.size() != 2 or not graph.has_result:
		push_error("Calibration graph did not accept timing samples")
	if "TIMING QUALITY" not in quality.text:
		push_error("Calibration quality readout is missing")

func _validate_exit_dialog(instance: Control) -> void:
	var dialog := instance.get_node("ExitDialog") as Control
	var panel := instance.get_node("ExitDialog/Center/Panel") as PanelContainer
	var title := instance.get_node("ExitDialog/Center/Panel/VBox/Title") as Label
	var power_icon := instance.get_node("ExitDialog/Center/Panel/VBox/IconArea/PowerIcon") as BeatUpActionIcon
	var stay_button := instance.get_node("ExitDialog/Center/Panel/VBox/Actions/ExitCancelButton") as Button
	var exit_button := instance.get_node("ExitDialog/Center/Panel/VBox/Actions/ExitConfirmButton") as Button
	if not dialog.visible:
		push_error("Exit confirmation did not open")
	if panel.size.x < 540.0 or panel.size.y < 310.0:
		push_error("Exit confirmation lost its compact visual hierarchy")
	if title.text != "Exit Beat UP?":
		push_error("Exit confirmation title is not branded")
	if power_icon.icon_type != "power":
		push_error("Exit confirmation is missing its code-native power icon")
	if stay_button.text != "Stay" or exit_button.text != "Exit":
		push_error("Exit confirmation actions are not explicit")
	for removed_node in ["Eyebrow", "Copy", "Divider", "ShortcutHint"]:
		if instance.get_node_or_null("ExitDialog/Center/Panel/VBox/%s" % removed_node) != null:
			push_error("Exit confirmation still contains noisy element: %s" % removed_node)
	if panel.find_children("*", "Label", true, false).size() != 1:
		push_error("Exit confirmation should contain only one text label")
	var panel_style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	if panel_style == null or panel_style.border_color != Color(MinimalTheme.BORDER, 0.92):
		push_error("Exit confirmation panel should use a quiet neutral border")

func _validate_pause_menu(instance: Control) -> void:
	var pause := instance.get_node("PauseOverlay") as Control
	var panel := pause.get_node("Center/MainPanel") as PanelContainer
	var notes := instance.get_node("Battle/Track/Notes") as Control
	var actions := pause.get_node("Center/MainPanel/MainVBox/PauseButtons") as VBoxContainer
	if not pause.visible or not bool(instance.get("game_paused")):
		push_error("Pause menu did not freeze gameplay")
	if pause.z_index <= notes.z_index:
		push_error("Pause menu must render above every gameplay note")
	if not Rect2(Vector2.ZERO, instance.size).encloses(panel.get_global_rect()):
		push_error("Pause action panel is clipped")
	var previous: Button
	for node in actions.get_children():
		var button := node as Button
		if button.text.is_empty() or button.icon == null:
			push_error("Pause action is missing its persistent label or SVG icon")
		if not panel.get_global_rect().encloses(button.get_global_rect()):
			push_error("Pause action falls outside its panel")
		if previous != null and previous.get_global_rect().intersects(button.get_global_rect()):
			push_error("Pause actions overlap")
		previous = button
	if actions.get_child(0).name != "ResumeButton":
		push_error("Resume must be the primary pause action")
	if not pause.has_signal("song_list_requested"):
		push_error("Pause menu is missing its Song Library action")
	if not pause.has_signal("retry_requested") or pause.get_signal_connection_list("retry_requested").is_empty():
		push_error("Pause menu retry action is not connected to gameplay")

func _validate_gameplay_countdown(instance: Control, expected_preparing: bool) -> void:
	var overlay := instance.get_node("CountdownOverlay") as Control
	var music := instance.get_node("Audio/Music") as AudioStreamPlayer
	var number := instance.get_node("CountdownOverlay/Center/Stack/Number") as TextureRect
	if bool(instance.get("resume_countdown_active")) != expected_preparing:
		push_error("Gameplay resume state did not match the countdown")
	if expected_preparing:
		if not overlay.visible or number.texture == null or int(instance.get("countdown_displayed_second")) != 3:
			push_error("Three-second resume countdown did not appear")
		if not music.stream_paused or not bool(instance.get("game_paused")):
			push_error("Song audio/gameplay resumed before the countdown ended")
	else:
		if not music.playing or music.stream_paused or bool(instance.get("game_paused")):
			push_error("Song audio did not resume after the countdown")
		if int(instance.get("countdown_displayed_second")) != 1:
			push_error("Countdown should release directly from 1 without a GO state")

func _validate_pause_retry(instance: Control) -> void:
	var pause := instance.get_node("PauseOverlay") as Control
	var countdown := instance.get_node("CountdownOverlay") as Control
	var music := instance.get_node("Audio/Music") as AudioStreamPlayer
	if pause.visible or bool(instance.get("game_paused")):
		push_error("Retry did not close the pause menu")
	if not countdown.visible or not bool(instance.get("gameplay_preparing")):
		push_error("Retry did not restart the chart with a fresh countdown")
	if music.playing or float(instance.get("fight_time")) != 0.0:
		push_error("Retry started audio or chart time before its countdown")

func _validate_main_menu_layout(instance: Control) -> void:
	var main_menu := instance.get_node("MainMenu") as Control
	var menu_stack := instance.get_node("MainMenu/MenuStack") as VBoxContainer
	var orb_cluster := instance.get_node("MainMenu/OrbCluster") as Control
	var menu_visual := instance.get_node("MainMenu/MenuVisual") as Control
	var menu_bgm := instance.get_node("MenuBGM") as MenuBGMController
	var menu_title := instance.get_node("MainMenu/MenuTitle") as Control
	var main_footer := instance.get_node("MainMenu/MainFooter") as Label
	var play_button := instance.get_node("MainMenu/MenuStack/PlayButton") as Button
	var settings_button := instance.get_node("MainMenu/MenuStack/SettingsButton") as Button
	var quick_calibration := instance.get_node("MainMenu/MenuStack/QuickCalibrationButton") as Button
	var selection_title := instance.get_node("MainMenu/OrbCluster/MainLogo") as Label
	var selection_index := instance.get_node("MainMenu/OrbCluster/SelectionIndex") as Label
	var selection_description := instance.get_node("MainMenu/SelectionDescription") as Label
	if not main_menu.visible:
		push_error("Main Menu did not appear after the splash transition")
	if menu_stack.get_child_count() != 6:
		push_error("Main Menu must expose six primary actions")
	if menu_stack.get_global_rect().intersects(orb_cluster.get_global_rect()):
		push_error("Main Menu action stack overlaps the selection visual")
	if not main_menu.get_global_rect().encloses(menu_visual.get_global_rect()):
		push_error("Main Menu visual backdrop is outside the viewport")
	if not menu_bgm.is_music_playing():
		push_error("Main Menu BGM did not start")
	var menu_stream: AudioStream = menu_bgm.get_current_stream()
	if not (menu_stream is AudioStreamOggVorbis) or not (menu_stream as AudioStreamOggVorbis).loop:
		push_error("Main Menu BGM must use the selected looping OGG stream")
	if not menu_bgm.is_spectrum_configured():
		push_error("Central MusicSession spectrum analyzer is not configured")
	var first_frequency_range: Vector2 = menu_bgm.get_band_frequency_range(0)
	var middle_frequency_range: Vector2 = menu_bgm.get_band_frequency_range(9)
	var last_frequency_range: Vector2 = menu_bgm.get_band_frequency_range(17)
	if first_frequency_range.x < 40.0 or first_frequency_range.y >= middle_frequency_range.x or middle_frequency_range.y >= last_frequency_range.x:
		push_error("Main Menu spectrum bands are not ordered from low to high")
	if last_frequency_range.y > 5400.0:
		push_error("Main Menu spectrum ceiling exceeds the centralized analyzer range")
	var test_levels := PackedFloat32Array()
	test_levels.resize(18)
	for level_index in range(test_levels.size()):
		test_levels[level_index] = float(level_index + 1) / float(test_levels.size())
	menu_bgm.set_process(false)
	menu_visual.call("set_audio_levels", test_levels)
	await create_timer(0.08).timeout
	var rendered_levels := menu_visual.call("get_audio_levels") as PackedFloat32Array
	menu_bgm.set_process(true)
	var strongest_rendered_level := 0.0
	for level in rendered_levels:
		strongest_rendered_level = maxf(strongest_rendered_level, level)
	if rendered_levels.size() != 18 or strongest_rendered_level <= 0.10:
		push_error("Main Menu sound bar did not react to spectrum level input")
	if rendered_levels[17] <= rendered_levels[0]:
		push_error("Main Menu sound bar collapsed into mirrored or center-weighted output")
	if not main_menu.get_global_rect().encloses(main_footer.get_global_rect()):
		push_error("Main Menu footer content is outside the viewport")
	for removed_path in ["MainMenu/TopStatus", "MainMenu/SystemStatus", "MainMenu/MenuEyebrow", "MainMenu/MenuSubtitle", "MainMenu/FooterStatus", "MainMenu/OrbCluster/OrbCaption"]:
		if instance.get_node_or_null(removed_path) != null:
			push_error("Removed Main Menu utility copy still exists: %s" % removed_path)
	var title_script := menu_title.get_script() as Script
	if menu_title is Label or title_script == null or not title_script.resource_path.ends_with("main_menu_logo.gd"):
		push_error("Beat UP! must use the custom code-native vector wordmark")
	if not play_button.has_focus():
		push_error("Main Menu did not focus Play after its entrance animation")
	if play_button.focus_neighbor_top.is_empty() or play_button.focus_neighbor_bottom.is_empty():
		push_error("Main Menu keyboard focus does not wrap vertically")
	if quick_calibration.get_signal_connection_list("pressed").is_empty():
		push_error("Main Menu direct Calibration action is not connected")
	if selection_title.text != "PLAY" or selection_index.text != "01 / 06" or selection_description.text != "Pick a song. Hit the beat.":
		push_error("Main Menu selection panel did not initialize from Play")
	var circle_bottom := orb_cluster.global_position.y + orb_cluster.size.y * 0.89
	if selection_description.get_global_rect().position.y <= circle_bottom:
		push_error("Main Menu action description must sit below the signal ring")
	instance.call("_on_menu_button_highlight", settings_button)
	await create_timer(0.08).timeout
	if selection_title.text != "SETTINGS" or selection_index.text != "04 / 06" or selection_description.text != "Adjust display, audio, and timing.":
		push_error("Main Menu hover/focus did not update the selection panel")
	if settings_button.scale.x <= 1.0 or play_button.modulate.a >= 0.9:
		push_error("Main Menu hover motion did not emphasize the active action")
	instance.call("_on_menu_button_highlight", play_button)
	await create_timer(0.16).timeout
	var original_viewport_size := root.size
	root.size = Vector2i(960, 540)
	await process_frame
	await process_frame
	instance.call("_apply_layout_config")
	await process_frame
	if menu_stack.get_global_rect().intersects(orb_cluster.get_global_rect()):
		push_error("Compact Main Menu layout overlaps at 960 × 540")
	if not main_menu.get_global_rect().encloses(menu_stack.get_global_rect()) or not main_menu.get_global_rect().encloses(main_footer.get_global_rect()) or not main_menu.get_global_rect().encloses(selection_description.get_global_rect()):
		push_error("Compact Main Menu layout falls outside the viewport")
	var compact_circle_bottom := orb_cluster.global_position.y + orb_cluster.size.y * 0.89
	if selection_description.get_global_rect().position.y <= compact_circle_bottom:
		push_error("Compact Main Menu description overlaps the signal ring")
	root.size = original_viewport_size
	await process_frame
	await process_frame
	instance.call("_apply_layout_config")

func _validate_how_to_play_layout(instance: Control) -> void:
	var help_screen := instance.get_node("HelpScreen") as Control
	var help_body := instance.get_node("HelpScreen/HelpMargin/HelpVBox/HelpBody") as HBoxContainer
	var copy_panel := instance.get_node("HelpScreen/HelpMargin/HelpVBox/HelpBody/TutorialCopyPanel") as PanelContainer
	var visual_panel := instance.get_node("HelpScreen/HelpMargin/HelpVBox/HelpBody/TutorialVisualPanel") as PanelContainer
	var tutorial_visual := instance.get_node("HelpScreen/HelpMargin/HelpVBox/HelpBody/TutorialVisualPanel/TutorialVisual") as HowToPlayVisual
	var heading := instance.get_node("HelpScreen/HelpMargin/HelpVBox/HelpBody/TutorialCopyPanel/TutorialCopy/TutorialHeading") as Label
	var tabs := instance.get_node("HelpScreen/HelpMargin/HelpVBox/TutorialTabs") as HBoxContainer
	var previous_button := instance.get_node("HelpScreen/HelpMargin/HelpVBox/HelpActions/TutorialPreviousButton") as Button
	var next_button := instance.get_node("HelpScreen/HelpMargin/HelpVBox/HelpActions/TutorialButton") as Button
	var step_counter := instance.get_node("HelpScreen/HelpMargin/HelpVBox/HelpActions/TutorialStepDots") as Label
	if not help_screen.visible:
		push_error("How To Play screen did not open")
	if tabs.get_child_count() != 3:
		push_error("How To Play must expose three tutorial steps")
	if help_body.get_global_rect().intersects(Rect2()):
		push_error("How To Play body produced an invalid rectangle")
	if copy_panel.get_global_rect().intersects(visual_panel.get_global_rect()):
		push_error("How To Play copy and visual panels overlap")
	if not help_screen.get_global_rect().encloses(copy_panel.get_global_rect()) or not help_screen.get_global_rect().encloses(visual_panel.get_global_rect()):
		push_error("How To Play panels extend outside the viewport")
	if heading.text != "Match the direction.":
		push_error("How To Play did not initialize on the Controls step")
	if not previous_button.disabled or not next_button.has_focus():
		push_error("How To Play initial navigation state is incorrect")
	for removed_name in ["NumpadGrid", "Mechanics", "TutorialCard"]:
		if help_screen.find_child(removed_name, true, false) != null:
			push_error("Legacy tutorial node still exists: %s" % removed_name)
	instance.call("_set_tutorial_step", 1, false)
	if tutorial_visual.get_step() != 1 or step_counter.text != "○  ●  ○" or heading.text != "Hit the diamond on beat.":
		push_error("Timing tutorial step did not synchronize its copy and visual")
	instance.call("_set_tutorial_step", 2, false)
	if tutorial_visual.get_step() != 2 or heading.text != "Read color before shape.":
		push_error("Note Types tutorial step did not synchronize its copy and visual")
	if next_button.text != "Play a song →" or tutorial_visual.has_method("reset_practice"):
		push_error("Final tutorial page must launch a full song, not Practice")
	var original_viewport_size := root.size
	root.size = Vector2i(960, 540)
	await process_frame
	await process_frame
	instance.call("_apply_layout_config")
	await process_frame
	if copy_panel.get_global_rect().intersects(visual_panel.get_global_rect()):
		push_error("Compact How To Play layout overlaps at 960 × 540")
	if not help_screen.get_global_rect().encloses(help_body.get_global_rect()) or not help_screen.get_global_rect().encloses(previous_button.get_global_rect()) or not help_screen.get_global_rect().encloses(next_button.get_global_rect()):
		push_error("Compact How To Play layout falls outside the viewport")
	root.size = original_viewport_size
	await process_frame
	await process_frame
	instance.call("_apply_layout_config")
	instance.call("_set_tutorial_step", 0, false)

func _validate_gameplay_layout(instance: Control) -> void:
	var lane := instance.get_node("Battle/Track/Lane") as Control
	var hit_zone := instance.get_node("Battle/Track/HitZone") as Control
	var judgment := instance.get_node("Feedback/JudgmentSprite") as Control
	var song_panel := instance.get_node("HUD/SongInfoPanel") as Control
	var stats_panel := instance.get_node("HUD/BattleStatsPanel") as Control
	if lane.size.x < instance.size.x * 0.80:
		push_error("Gameplay lane must span at least 80% of the viewport")
	var lane_rect := lane.get_global_rect()
	var hit_center := hit_zone.global_position + hit_zone.size * 0.5
	if not lane_rect.has_point(hit_center):
		push_error("Hit receptor is outside the gameplay lane")
	if judgment.get_global_rect().end.y > hit_zone.get_global_rect().position.y:
		push_error("Judgment popup must remain above the hit receptor")
	if song_panel.get_global_rect().intersects(stats_panel.get_global_rect()):
		push_error("Song and performance HUD panels overlap")

func _validate_gameplay_sfx(instance: Control) -> void:
	var hit_player := instance.get_node("Audio/HitSFX") as AudioStreamPlayer
	var miss_player := instance.get_node("Audio/MissSFX") as AudioStreamPlayer
	if hit_player.stream == null or miss_player.stream == null:
		push_error("Gameplay hit or miss SFX is missing")
		return
	if FileAccess.get_sha256("res://audio/Beat.wav") != "3d9e86003f8ebd1a3f6f3d8af65b6b682562a46d532ccd204dcba21305b950ff":
		push_error("Gameplay hit SFX is not the selected Kenney select_001 sound")
	if FileAccess.get_sha256("res://audio/fail.wav") != "9d326005be0cdef35ef7fc52a81eed4b77a0dcbf0346503fd5d5da76743cdb1f":
		push_error("Gameplay miss SFX is not the selected Kenney error_007 sound")
	if miss_player.volume_db > -5.0:
		push_error("Gameplay miss SFX is louder than its balanced target")
	if not FileAccess.file_exists("res://audio/KENNEY-CC0-LICENSE.txt") or not FileAccess.file_exists("res://audio/SFX-SOURCES.md"):
		push_error("Gameplay SFX source or CC0 license note is missing")

func _validate_gameplay_layer_visibility(instance: Control, expected_visible: bool) -> void:
	var battle := instance.get_node("Battle") as Control
	var hud := instance.get_node("HUD") as Control
	var feedback := instance.get_node("Feedback") as Control
	var hit_zone := instance.get_node("Battle/Track/HitZone") as Control
	var level_select := instance.get_node("LevelSelect") as Control
	var preview_player := level_select.get_node("PreviewPlayer") as SongPreviewController
	if battle.visible != expected_visible:
		push_error("Battle layer visibility did not match the active screen")
	if hud.visible != expected_visible:
		push_error("HUD layer visibility did not match the active screen")
	if feedback.visible != expected_visible:
		push_error("Feedback layer visibility did not match the active screen")
	if not expected_visible and hit_zone.is_visible_in_tree():
		push_error("Gameplay hit zone leaked into a non-gameplay screen")
	if not level_select.visible and preview_player.playing:
		push_error("Song preview audio continued outside Song Select")

func _validate_judgment_motion(instance: Control) -> void:
	var judgment := instance.get_node("Feedback/JudgmentSprite") as Label
	instance.set("combo", 12)
	instance.call("show_judgment_popup", "PERFECT")
	await create_timer(0.05).timeout
	if not judgment.visible or judgment.modulate.a <= 0.0:
		push_error("Judgment popup did not animate in")
	await create_timer(0.52).timeout
	if judgment.visible:
		push_error("Judgment popup did not animate out")

func _validate_song_select_layout(selector: Control) -> void:
	var info_panel := selector.get_node("MainMargin/RootVBox/Body/InfoPanel") as Control
	var library_panel := selector.get_node("MainMargin/RootVBox/Body/WheelColumn/LibraryPanel") as Control
	var hero := selector.get_node("MainMargin/RootVBox/Body/InfoPanel/InfoVBox/HeroPanel") as Control
	var best_grid := selector.get_node("MainMargin/RootVBox/Body/InfoPanel/InfoVBox/BestGrid") as GridContainer
	var play_button := selector.get_node("MainMargin/RootVBox/Body/InfoPanel/InfoVBox/ActionRow/PlayButton") as Button
	var best_score := selector.get_node("MainMargin/RootVBox/Body/InfoPanel/InfoVBox/BestGrid/BestScoreCard/VBox/BestScoreValue") as Label
	var song_list := selector.get_node("MainMargin/RootVBox/Body/WheelColumn/LibraryPanel/LibraryVBox/SongScroll/SongList") as VBoxContainer
	var preview_player := selector.get_node("PreviewPlayer") as SongPreviewController
	var song_visual := selector.get_node("MainMargin/RootVBox/Body/InfoPanel/InfoVBox/HeroPanel/HeroContent/SongVisual") as SongSelectVisual
	if info_panel.get_global_rect().intersects(library_panel.get_global_rect()):
		push_error("Song detail panel overlaps the track library")
	if hero.size.y < 140.0:
		push_error("Song identity visual is too small")
	if best_grid.columns != 4 or best_grid.get_child_count() != 4:
		push_error("Personal-best summary must remain a four-card row")
	if play_button.disabled:
		push_error("Selected playable chart did not enable the Play action")
	if best_score.text != "46,940":
		push_error("Song Select personal-best score was not formatted correctly")
	if song_list.get_child_count() < 1:
		push_error("Song library did not create any track rows")
	if selector.find_child("ChartList", true, false) != null:
		push_error("Song detail panel still contains duplicate difficulty controls")
	if selector.find_child("SongCodeLabel", true, false) != null:
		push_error("Song preview still contains its NB-00x identifier")
	if selector.find_child("DifficultyStamp", true, false) != null:
		push_error("Song preview still contains its duplicate difficulty stamp")
	if preview_player.get_current_audio_path().is_empty():
		push_error("Selected song did not start its audio preview")
	var preview_range := preview_player.get_preview_range()
	if preview_range.x <= 1.0 or preview_range.y - preview_range.x < 10.0:
		push_error("Song preview did not select a representative reference segment")
	if not preview_player.is_spectrum_configured():
		push_error("Central MusicSession spectrum analyzer is not configured for song preview")
	var first_preview_band: Vector2 = preview_player.get_band_frequency_range(0)
	var last_preview_band: Vector2 = preview_player.get_band_frequency_range(17)
	if first_preview_band.x < 40.0 or first_preview_band.y >= last_preview_band.x or last_preview_band.y > 5400.0:
		push_error("Song preview spectrum bands are not ordered across the useful music range")
	var test_preview_levels := PackedFloat32Array()
	test_preview_levels.resize(18)
	for level_index in range(test_preview_levels.size()):
		test_preview_levels[level_index] = float(level_index + 1) / float(test_preview_levels.size())
	preview_player.set_process(false)
	song_visual.set_audio_levels(test_preview_levels)
	await create_timer(0.10).timeout
	var rendered_preview_levels := song_visual.get_audio_levels()
	preview_player.set_process(true)
	if rendered_preview_levels.size() != 18 or rendered_preview_levels[17] <= rendered_preview_levels[0] or rendered_preview_levels[17] <= 0.10:
		push_error("Song preview sound bar did not react across all spectrum bands")
	if not selector.get_global_rect().encloses(play_button.get_global_rect()):
		push_error("Song Select Play action is outside the viewport")
	var available: Array[String] = selector.call("_available_difficulties", selector.call("get_selected_song_id"))
	if available.size() > 1:
		var before := str(selector.call("get_selected_difficulty"))
		var next_chart := InputEventKey.new()
		next_chart.keycode = KEY_RIGHT
		next_chart.pressed = true
		selector.call("_unhandled_key_input", next_chart)
		if str(selector.call("get_selected_difficulty")) == before:
			push_error("Left/right chart navigation did not change difficulty")

	var song_buttons: Array = selector.get("song_buttons")
	var wrappers: Array = selector.get("song_header_wrappers")
	var clips: Array = selector.get("song_difficulty_clips")
	var difficulty_rows: Array = selector.get("song_difficulty_rows")
	var filtered_ids: Array = selector.get("filtered_song_ids")
	if song_buttons.size() >= 2 and wrappers.size() == song_buttons.size():
		var original_song := str(selector.call("get_selected_song_id"))
		var original_audio_path := preview_player.get_current_audio_path()
		var original_index := filtered_ids.find(original_song)
		var hover_index := 1 if original_index == 0 else 0
		var hover_wrapper := wrappers[hover_index] as MarginContainer
		var hover_button := song_buttons[hover_index] as Button
		if hover_button.get_signal_connection_list("mouse_entered").is_empty():
			push_error("Song row is missing its mouse-hover connection")
		var resting_margin := hover_wrapper.get_theme_constant("margin_left")
		selector.call("_on_song_row_hover", hover_index, true)
		await create_timer(0.08).timeout
		var hovered_margin := hover_wrapper.get_theme_constant("margin_left")
		if hovered_margin >= resting_margin:
			push_error("Song-row hover did not extend the card toward the left (%d -> %d; property %.1f)" % [resting_margin, hovered_margin, float(hover_wrapper.get("animated_margin_left"))])
		selector.call("_on_song_row_hover", hover_index, false)
		await create_timer(0.16).timeout

		var next_song := str(filtered_ids[hover_index])
		selector.call("_select_song", next_song)
		await create_timer(0.08).timeout
		var next_clip := clips[hover_index] as Control
		if next_clip.custom_minimum_size.y <= 0.0:
			push_error("Selected song difficulty cascade did not animate open")
		await create_timer(0.30).timeout
		if preview_player.get_current_audio_path() == original_audio_path:
			push_error("Changing the selected song did not switch the audio preview")
		if hover_wrapper.get_theme_constant("margin_left") != 0:
			push_error("Selected song row did not expand to full width")
		if not next_clip.visible or next_clip.custom_minimum_size.y <= 80.0:
			push_error("Selected song did not keep its difficulty rows expanded")
		if (difficulty_rows[hover_index] as Array).is_empty():
			push_error("Selected song is missing its inline difficulty rows")
		else:
			var first_diff := (difficulty_rows[hover_index] as Array)[0] as Dictionary
			var diff_wrapper := first_diff["wrapper"] as MarginContainer
			var diff_button := first_diff["button"] as Button
			if diff_button.get_signal_connection_list("mouse_entered").is_empty():
				push_error("Inline difficulty row is missing its hover connection")
			var diff_resting_margin := diff_wrapper.get_theme_constant("margin_left")
			selector.call("_on_difficulty_row_hover", hover_index, 0, true)
			await create_timer(0.08).timeout
			if diff_wrapper.get_theme_constant("margin_left") >= diff_resting_margin:
				push_error("Difficulty-row hover did not extend the card toward the left")
			selector.call("_on_difficulty_row_hover", hover_index, 0, false)

		selector.call("_select_song", original_song)
		await create_timer(0.36).timeout

func _validate_score_roll(instance: Control) -> void:
	var score_display := instance.get_node("HUD/ScoreDigits") as ScoreDigits
	instance.set("score", 100)
	score_display.reset_value(100)
	instance.set("score", 250)
	instance.call("update_hud")
	await create_timer(0.05).timeout
	if not score_display.is_rolling():
		push_error("Score digits did not start their odometer animation")
	await create_timer(0.45).timeout
	if score_display.is_rolling() or score_display.get_value() != 250:
		push_error("Score digits did not finish on the target value")
	instance.set("score", 0)
	score_display.reset_value(0)

func _validate_note_arrow_colors() -> void:
	var note_scene := load("res://scenes/note.tscn") as PackedScene
	var note := note_scene.instantiate() as RhythmNote
	var palette := load("res://config/theme_config.tres") as Resource
	note.theme_config = palette
	note.configure({"type": "normal", "dx": 1.0, "dy": 0.0})
	if not note.get_arrow_color().is_equal_approx(palette.base_dark):
		push_error("Straight normal arrow must remain dark over the white note fill")
	if not note.get_outline_color().is_equal_approx(palette.normal_note_color):
		push_error("Straight normal-note outline must remain blue")
	note.configure({"type": "normal", "dx": 1.0, "dy": -1.0})
	if not note.get_arrow_color().is_equal_approx(palette.base_dark):
		push_error("Diagonal normal arrow must remain dark over the white note fill")
	if not note.get_outline_color().is_equal_approx(palette.diagonal_note_outline):
		push_error("Diagonal normal-note outline must be orange")
	note.configure({"type": "reverse", "dx": 1.0, "dy": -1.0})
	if not note.get_arrow_color().is_equal_approx(palette.base_dark):
		push_error("Reverse arrow must remain dark over the white note fill")
	if not note.get_outline_color().is_equal_approx(palette.reverse_note_outline):
		push_error("Every reverse-note outline must be red")
	note.free()

func _validate_reverse_note_direction(instance: Control) -> void:
	instance.set("random_mode_enabled", false)
	var opposite_numbers := {1: 9, 2: 8, 3: 7, 4: 6, 6: 4, 7: 3, 8: 2, 9: 1}
	for direction_number in opposite_numbers:
		var note_data: Dictionary = instance.call("build_note_data", {
			"type": "reverse",
			"direction": direction_number,
			"time": 1.0,
		})
		var expected_direction: Dictionary = instance.call("get_direction_by_number", direction_number)
		var display_direction: Dictionary = instance.call("get_direction_by_number", opposite_numbers[direction_number])
		if int(note_data["key"]) != int(expected_direction["key"]):
			push_error("Reverse input must preserve authored direction %s" % direction_number)
		if int(note_data["display_key"]) != int(display_direction["key"]):
			push_error("Reverse note visual must flip authored direction %s" % direction_number)
		var visual_vector := Vector2(float(note_data["dx"]), float(note_data["dy"])).normalized()
		var display_vector := Vector2(float(display_direction["dx"]), float(display_direction["dy"])).normalized()
		var input_vector := Vector2(float(expected_direction["dx"]), float(expected_direction["dy"])).normalized()
		if not visual_vector.is_equal_approx(display_vector):
			push_error("Reverse arrow did not use flipped visual direction %s" % direction_number)
		if visual_vector.dot(input_vector) > -0.99:
			push_error("Reverse visual and unchanged input are not opposite for direction %s" % direction_number)

func _validate_result_layout(instance: Control) -> void:
	var result := instance.get_node("ResultOverlay") as Control
	var rank_panel := result.get_node("MainMargin/RootVBox/Content/RankPanel") as Control
	var stats_column := result.get_node("MainMargin/RootVBox/Content/StatsColumn") as Control
	var score_value := result.get_node("MainMargin/RootVBox/Content/StatsColumn/ScorePanel/ScoreVBox/ScoreValue") as Label
	var rank_value := result.get_node("MainMargin/RootVBox/Content/RankPanel/RankColumn/RankArea/RankStack/RankCenter/VBox/RankValue") as Label
	var rank_meter := result.get_node("MainMargin/RootVBox/Content/RankPanel/RankColumn/RankArea/RankStack/RankMeter") as Control
	var accuracy_bar := result.get_node("MainMargin/RootVBox/Content/StatsColumn/PrimaryStats/AccuracyCard/VBox/AccuracyBar") as ProgressBar
	var accuracy_value := result.get_node("MainMargin/RootVBox/Content/StatsColumn/PrimaryStats/AccuracyCard/VBox/AccuracyValue") as Label
	var combo_value := result.get_node("%ComboValue") as Label
	var perfect_rate_value := result.get_node("MainMargin/RootVBox/Content/StatsColumn/PrimaryStats/PerfectRateCard/VBox/PerfectRateValue") as Label
	var bottom_bar := result.get_node("MainMargin/RootVBox/BottomBar") as Control
	if not result.visible:
		push_error("Result screen must be visible after the fight ends")
	if rank_panel.get_global_rect().intersects(stats_column.get_global_rect()):
		push_error("Result rank and score overlap")
	var rank_area := result.get_node("%RankArea") as Control
	if rank_area.get_global_rect().intersects(stats_column.get_global_rect()):
		push_error("Result glyph and score/accuracy overlap")
	if not result.get_global_rect().encloses(bottom_bar.get_global_rect()):
		push_error("Result action bar is outside the viewport")
	if score_value.text != "128,450":
		push_error("Result score reveal did not settle on the final formatted value")
	if rank_value.text != "S":
		push_error("Representative result data should produce an S rank")
	if absf(float(accuracy_bar.value) - (118.0 / 120.0 * 100.0)) > 0.05:
		push_error("Result accuracy bar does not match the calculated accuracy")
	if absf(float(rank_meter.get("value")) - float(accuracy_bar.value)) > 0.05:
		push_error("Final rank meter must fill alongside final score and accuracy")
	if absf(float(accuracy_value.call("get_numeric_value")) - float(accuracy_bar.value)) > 0.05:
		push_error("Animated accuracy percentage does not match its bar")
	if float(combo_value.call("get_numeric_value")) != 83.0:
		push_error("Animated max combo did not settle on the target")
	if absf(float(perfect_rate_value.call("get_numeric_value")) - (92.0 / 120.0 * 100.0)) > 0.05:
		push_error("Animated perfect rate did not settle on the target")
	var rolling_labels: Array = result.call("_rolling_labels")
	var expected_values := [118.0 / 120.0 * 100.0, 83.0, 92.0 / 120.0 * 100.0, 92.0, 20.0, 6.0, 2.0, 4.0, 6.0, 3.0, 1.0]
	for index in range(rolling_labels.size()):
		var rolling_label := rolling_labels[index] as Label
		if absf(float(rolling_label.call("get_numeric_value")) - expected_values[index]) > 0.05:
			push_error("Result rolling metric %d did not settle on its target" % index)
		if bool(rolling_label.call("is_rolling")):
			push_error("A result rolling value was still animating after the reveal completed")
	if result.has_signal("next_requested") or result.has_node("MainMargin/RootVBox/BottomBar/NextButton"):
		push_error("Result screen still exposes the removed NEXT action")
	var back_button := result.get_node("MainMargin/RootVBox/BottomBar/BackButton") as Button
	var replay_button := result.get_node("MainMargin/RootVBox/BottomBar/ReplayButton") as Button
	if not back_button.visible or not replay_button.visible:
		push_error("Result screen must keep Song Select and Retry available")
	var rank_sfx_state: Dictionary = root.get_node("MenuSFX").call("get_rank_fill_debug_state")
	if bool(rank_sfx_state.get("active", true)):
		push_error("Final-rank SFX must stop when the meter settles")
	if int(rank_sfx_state.get("ticks", 0)) < 2 or int(rank_sfx_state.get("locks", 0)) != 1:
		push_error("Final-rank fill must play charge ticks and one lock cue")

func _validate_result_motion(instance: Control) -> void:
	var result := instance.get_node("ResultOverlay") as Control
	var score_value := result.get_node("MainMargin/RootVBox/Content/StatsColumn/ScorePanel/ScoreVBox/ScoreValue") as Label
	var rank_meter := result.get_node("MainMargin/RootVBox/Content/RankPanel/RankColumn/RankArea/RankStack/RankMeter") as Control
	var accuracy_bar := result.get_node("MainMargin/RootVBox/Content/StatsColumn/PrimaryStats/AccuracyCard/VBox/AccuracyBar") as ProgressBar
	var displayed_score := int(score_value.text.replace(",", ""))
	var rank_progress := float(rank_meter.get("value"))
	if displayed_score <= 0 or displayed_score >= 128450:
		push_error("Final score was not actively counting at the motion checkpoint")
	if rank_progress <= 0.0 or rank_progress >= 118.0 / 120.0 * 100.0:
		push_error("Final rank meter was not actively filling with the score")
	if accuracy_bar.value <= 0.0 or accuracy_bar.value >= 118.0 / 120.0 * 100.0:
		push_error("Accuracy bar was not actively filling")
	var rank_sfx_state: Dictionary = root.get_node("MenuSFX").call("get_rank_fill_debug_state")
	if not bool(rank_sfx_state.get("active", false)) or int(rank_sfx_state.get("ticks", 0)) < 1:
		push_error("Final-rank charge SFX was not active during the meter fill")
	var rolling_count := 0
	for rolling_label in result.call("_rolling_labels"):
		if bool((rolling_label as Label).call("is_rolling")):
			rolling_count += 1
	if rolling_count < 8:
		push_error("Result metrics did not start their casino-style rolling animation together")

func _validate_result_debug(instance: Control) -> void:
	var result := instance.get_node("ResultOverlay") as Control
	var score_value := result.get_node("MainMargin/RootVBox/Content/StatsColumn/ScorePanel/ScoreVBox/ScoreValue") as Label
	var rank_value := result.get_node("MainMargin/RootVBox/Content/RankPanel/RankColumn/RankArea/RankStack/RankCenter/VBox/RankValue") as Label
	var rank_meter := result.get_node("MainMargin/RootVBox/Content/RankPanel/RankColumn/RankArea/RankStack/RankMeter") as Control
	var accuracy_bar := result.get_node("MainMargin/RootVBox/Content/StatsColumn/PrimaryStats/AccuracyCard/VBox/AccuracyBar") as ProgressBar
	var expected_accuracy := 353.0 / 460.0 * 100.0
	if not result.visible:
		push_error("F4 result debug shortcut did not open the result screen")
	if score_value.text != "46,940":
		push_error("Debug result score did not settle on 46,940")
	if rank_value.text != "C":
		push_error("Debug result data should produce a C rank")
	if absf(float(accuracy_bar.value) - expected_accuracy) > 0.05:
		push_error("Debug result accuracy did not settle on 76.74 percent")
	if absf(float(rank_meter.get("value")) - expected_accuracy) > 0.05:
		push_error("Debug result rank meter did not match the sample accuracy")
	var expected_values := [expected_accuracy, 58.0, 205.0 / 460.0 * 100.0, 205.0, 83.0, 65.0, 107.0, 7.0, 25.0, 7.0, 0.0]
	var rolling_labels: Array = result.call("_rolling_labels")
	for index in range(rolling_labels.size()):
		var rolling_label := rolling_labels[index] as Label
		if absf(float(rolling_label.call("get_numeric_value")) - expected_values[index]) > 0.05:
			push_error("Debug result rolling metric %d missed its sample target" % index)
		if bool(rolling_label.call("is_rolling")):
			push_error("Debug result metric %d was still rolling after reveal" % index)

func _save_viewport(file_name: String) -> void:
	if DisplayServer.get_name() == "headless" and OS.get_environment("FORCE_HEADLESS_CAPTURE") != "1":
		return
	var image := root.get_texture().get_image()
	if image != null and not image.is_empty():
		image.save_png("res://tests/%s.png" % file_name)
