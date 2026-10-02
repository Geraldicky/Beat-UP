extends SceneTree

const QA_ENVIRONMENT_VARIABLE := "BEAT_UP_QA_PHASE4_UI"
const QA_ENVIRONMENT_VALUE := "isolated"
const MinimalThemeScript = preload("res://scripts/ui/minimal_theme.gd")

const TARGET_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]

var failures := 0
var shell: Control
var navigation: Node

func _initialize() -> void:
	if OS.get_environment(QA_ENVIRONMENT_VARIABLE) != QA_ENVIRONMENT_VALUE:
		push_error("Refusing to run Phase 4 UI QA outside its isolated environment.")
		quit(2)
		return
	call_deferred("_run")

func _run() -> void:
	var baseline_orphans: Array[int] = Node.get_orphan_node_ids()
	root.get_node("AppSessionState").call("mark_splash_seen")
	navigation = root.get_node("NavigationController")
	shell = (load("res://scenes/app_shell.tscn") as PackedScene).instantiate() as Control
	root.add_child(shell)
	await _settle(4)

	var startup := shell.get("startup_screen") as Control
	for resolution in TARGET_RESOLUTIONS:
		await _resize_to(resolution)
		_check_main_menu(startup, resolution)

	var library_result: Dictionary = await navigation.call("request_song_library", "bad_apple", false)
	_check(str(library_result.get("outcome", "")) == "success", "Main Menu -> Song Library failed.")
	var library := shell.get("song_library_screen") as Control
	var selection := library.get("song_select") as Control
	await _settle(4)
	for resolution in TARGET_RESOLUTIONS:
		await _resize_to(resolution)
		_check_song_library(selection, resolution)

	# Mode and modifier controls must expose their state without changing launch
	# ownership. The test runs in isolated user data because these calls exercise
	# the same canonical settings consumer as the real screen.
	selection.call("_on_mode_4_selected")
	await _settle(2)
	_check(bool((selection.get("album_flow_mode_4_button") as Button).button_pressed), "4K selection is not visible.")
	_check(not bool((selection.get("album_flow_mode_8_button") as Button).button_pressed), "8K remained selected after choosing 4K.")
	selection.call("_on_mode_8_selected")
	await _settle(2)
	_check(bool((selection.get("album_flow_mode_8_button") as Button).button_pressed), "8K selection is not visible.")
	selection.call("set_random_mode", true)
	await _settle(2)
	_check(bool((selection.get("album_flow_random_button") as Button).button_pressed), "Random selection is not visible.")
	selection.call("set_random_mode", false)

	# The route assertions deliberately use NavigationController so this visual
	# suite cannot bypass the approved AppShell transaction boundary.
	var menu_result: Dictionary = await navigation.call("request_main_menu", 0)
	_check(str(menu_result.get("outcome", "")) == "success", "Song Library -> Main Menu failed.")
	_check(str(shell.call("get_active_route")) == "main_menu", "Main Menu was not active after returning from Song Library.")
	library_result = await navigation.call("request_song_library", "bad_apple", false)
	_check(str(library_result.get("outcome", "")) == "success", "Second Main Menu -> Song Library request failed.")

	var studio_result: Dictionary = await navigation.call("request_chart_studio")
	_check(str(studio_result.get("outcome", "")) == "success", "Chart Studio route failed after the UI redesign.")
	if str(studio_result.get("outcome", "")) == "success":
		var editor := shell.get("chart_studio_instance") as Control
		_check(is_instance_valid(editor), "Chart Studio route has no editor instance.")
		if is_instance_valid(editor):
			editor.call("return_to_game")
			await _wait_for_navigation()
			_check(str(shell.call("get_active_route")) == "song_library", "Chart Studio did not return to Song Library.")

	var launch_request := {"song_id": "bad_apple", "difficulty_id": "normal", "random_mode": false}
	var gameplay_result: Dictionary = await navigation.call("request_gameplay", launch_request, {})
	_check(str(gameplay_result.get("outcome", "")) == "success", "Song Library -> Gameplay failed.")
	var gameplay := shell.get("gameplay_screen") as Control
	await _settle(4)
	for resolution in TARGET_RESOLUTIONS:
		await _resize_to(resolution)
		gameplay.call("update_hud")
		_check_gameplay_hud(gameplay, resolution)
	_check_gameplay_identity(gameplay)

	library_result = await navigation.call("request_song_library", "bad_apple", false)
	_check(str(library_result.get("outcome", "")) == "success", "Gameplay -> Song Library failed.")
	_check(str(shell.call("get_active_route")) == "song_library", "Song Library was not restored after Gameplay.")

	print("PHASE4_UI_FOUNDATION_TEST: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	root.remove_child(shell)
	shell.free()
	await process_frame
	_cleanup_new_orphan_nodes(baseline_orphans)
	call_deferred("_finish", 1 if failures > 0 else 0)

func _check_main_menu(startup: Control, resolution: Vector2i) -> void:
	var play := startup.get("play_button") as Button
	var settings := startup.get("settings_button") as Button
	var title := startup.get("menu_title") as Control
	var now_playing := startup.get("now_playing_card") as Control
	var menu_stack := startup.get("menu_stack") as VBoxContainer
	var utility_row := startup.get("utility_row") as HBoxContainer
	var menu_visual := startup.get("menu_visual") as Control
	var menu_background := startup.get("menu_background") as TextureRect
	var now_playing_kicker := startup.get("now_playing_kicker") as Label
	var background_controller := startup.get("main_menu_background_controller") as RefCounted
	var brand_bounds: Rect2 = menu_visual.call("get_brand_panel_bounds") as Rect2
	_check(_inside_viewport(play, resolution), "Main Menu Play is clipped at %s." % resolution)
	_check(_inside_viewport(now_playing, resolution), "Main Menu Now Playing is clipped at %s." % resolution)
	_check(_inside_viewport(menu_stack, resolution), "Main Menu action column is clipped at %s." % resolution)
	_check(_inside_viewport(utility_row, resolution), "Main Menu utility links are clipped at %s." % resolution)
	_check(_rect_inside_viewport(brand_bounds, resolution), "Beat UP! brand diamond is clipped at %s." % resolution)
	_check(not title.get_global_rect().intersects(now_playing.get_global_rect()), "Main Menu wordmark overlaps Now Playing at %s." % resolution)
	_check(now_playing.get_global_rect().end.y < brand_bounds.position.y, "Now Playing is not a top rail at %s." % resolution)
	_check(menu_stack.get_global_rect().position.x > brand_bounds.end.x, "Main Menu actions are not right of the brand diamond at %s." % resolution)
	_check(not menu_stack.get_global_rect().intersects(brand_bounds), "Main Menu actions overlap the brand diamond at %s." % resolution)
	_check(utility_row.get_global_rect().position.y > menu_stack.get_global_rect().position.y, "Utility links do not sit below primary actions at %s." % resolution)
	_check(menu_stack.get_child_count() == 4, "Main Menu primary column must contain PLAY, CHART STUDIO, SETTINGS, and QUIT only.")
	_check(utility_row.get_child_count() == 3, "Main Menu utility row did not preserve Help, Calibration, and Credits.")
	_check(not bool(menu_visual.call("has_foreground_artwork_card")), "Main Menu restored a foreground cover-art card.")
	_check(menu_background.texture != null, "Main Menu current-song background is missing at %s." % resolution)
	var current_background_path := str(background_controller.call("get_current_background_path"))
	_check(not current_background_path.is_empty(), "Main Menu current-song background path is empty.")
	if not current_background_path.is_empty() and ResourceLoader.exists(current_background_path):
		_check(ResourceLoader.load(current_background_path) == menu_background.texture, "Main Menu full-screen background does not use the current song artwork.")
	_check(now_playing_kicker.visible and now_playing_kicker.text == "NOW PLAYING", "Now Playing rail lost its hierarchy label.")
	_check(play.size.y > settings.size.y, "Main Menu Play is not more prominent than secondary actions at %s." % resolution)
	_check(play.focus_mode == Control.FOCUS_ALL, "Main Menu Play lost keyboard focus support.")
	for property_name in ["prev_track_button", "play_pause_track_button", "next_track_button"]:
		var transport := startup.get(property_name) as Button
		_check(_inside_viewport(transport, resolution), "Now Playing control %s is clipped at %s: %s." % [property_name, resolution, transport.get_global_rect()])
		_check(transport.focus_mode == Control.FOCUS_ALL, "Now Playing control %s is not keyboard focusable." % property_name)

func _check_song_library(selection: Control, resolution: Vector2i) -> void:
	var play := selection.get("play_button") as Button
	var title := selection.get("detail_title") as Label
	var difficulty_row := selection.get("album_flow_difficulty_row") as Control
	var mode_row := selection.get("album_flow_mode_row") as Control
	var random_button := selection.get("album_flow_random_button") as Button
	var wheel_column := selection.get("wheel_column") as Control
	_check(_inside_viewport(play, resolution), "Song Library Play is clipped at %s: %s." % [resolution, play.get_global_rect()])
	_check(not play.disabled, "Song Library Play is unavailable for the bundled fixture at %s." % resolution)
	_check(_inside_viewport(title, resolution), "Selected song title is clipped at %s." % resolution)
	_check(_inside_viewport(difficulty_row, resolution), "Difficulty state is clipped at %s: %s." % [resolution, difficulty_row.get_global_rect()])
	_check(_inside_viewport(mode_row, resolution), "4K/8K state is clipped at %s." % resolution)
	_check(_inside_viewport(random_button, resolution), "Random state is clipped at %s." % resolution)
	_check(_inside_viewport(wheel_column, resolution), "Song list is clipped at %s: %s." % [resolution, wheel_column.get_global_rect()])
	_check(not title.get_global_rect().intersects(play.get_global_rect()), "Selected song title overlaps Play at %s." % resolution)
	var song_buttons: Array = selection.get("song_buttons") as Array
	var song_ids: Array = selection.get("filtered_song_ids") as Array
	var selected_index := song_ids.find(str(selection.get("selected_song_id")))
	_check(selected_index >= 0 and selected_index < song_buttons.size(), "Selected Song Library item is missing at %s." % resolution)
	if selected_index >= 0 and selected_index < song_buttons.size():
		var selected_button := song_buttons[selected_index] as Button
		var scroll := selection.get("song_scroll") as ScrollContainer
		_check(selected_button.button_pressed, "Selected song row has no visible selected state at %s." % resolution)
		_check(selected_button.get_global_rect().intersects(scroll.get_global_rect()), "Selected song row is outside the visible list at %s." % resolution)

func _check_gameplay_hud(gameplay: Control, resolution: Vector2i) -> void:
	var stats := gameplay.get_node("HUD/BattleStatsPanel") as Control
	var pause := gameplay.get_node("HUD/PauseButton") as Control
	var score := gameplay.get_node("HUD/ScoreDigits") as Control
	var accuracy := gameplay.get_node("HUD/AccuracyLabel") as Control
	var progress := gameplay.get_node("HUD/SongInfoPanel/DurationBar") as Control
	var judgment := gameplay.get_node("Feedback/JudgmentSprite") as Control
	var hit_zone := gameplay.get_node("Battle/Track/HitZone") as Control
	var combo_label := gameplay.get_node("HUD/ComboLabel") as Label
	judgment.visible = true
	for control in [stats, pause, score, accuracy, progress, judgment, hit_zone]:
		_check(_inside_viewport(control, resolution), "Gameplay control %s is clipped at %s." % [control.name, resolution])
	_check(not stats.get_global_rect().intersects(pause.get_global_rect()), "Score/accuracy overlaps Pause at %s." % resolution)
	_check(judgment.get_global_rect().end.y <= hit_zone.get_global_rect().position.y + 1.0, "Judgment is not above the hit zone at %s." % resolution)
	_check(not combo_label.visible, "Retired gameplay combo label became visible at %s." % resolution)

func _check_gameplay_identity(gameplay: Control) -> void:
	var palette: Resource = load("res://config/theme_config.tres")
	_check(palette.get("normal_note_color").is_equal_approx(MinimalThemeScript.NORMAL_BLUE), "Normal note is not Beat UP! blue.")
	_check(palette.get("diagonal_note_outline").is_equal_approx(MinimalThemeScript.DIAGONAL_ORANGE), "Diagonal note is not Beat UP! orange.")
	_check(palette.get("reverse_note_outline").is_equal_approx(MinimalThemeScript.REVERSE_RED), "Reverse note outline is not red.")
	_check(palette.get("space_accent").is_equal_approx(MinimalThemeScript.SPACE_GOLD), "Space timing color is not gold.")
	_check(palette.get("hit_zone_border").is_equal_approx(Color(1.0, 1.0, 1.0, 0.82)), "Hit-zone diamond is not white.")
	_check(gameplay.call("_judgment_color", "PERFECT").is_equal_approx(MinimalThemeScript.PERFECT_PINK), "PERFECT is not pink.")
	_check(gameplay.call("_judgment_color", "GREAT").is_equal_approx(MinimalThemeScript.GREAT_GREEN), "GREAT is not green.")
	_check(gameplay.call("_judgment_color", "GOOD").is_equal_approx(MinimalThemeScript.GOOD_CYAN), "GOOD is not cyan.")
	_check(gameplay.call("_judgment_color", "MISS").is_equal_approx(MinimalThemeScript.MISS_RED), "MISS is not red.")

	var note_scene := load("res://scenes/note.tscn") as PackedScene
	var normal := note_scene.instantiate() as Control
	var reverse := note_scene.instantiate() as Control
	var space := note_scene.instantiate() as Control
	for note in [normal, reverse, space]:
		note.set("theme_config", palette)
	normal.call("configure", {"type": "normal", "dx": 1.0, "dy": 0.0})
	reverse.call("configure", {"type": "reverse", "dx": 1.0, "dy": 0.0})
	space.call("configure", {"type": "space", "dx": 0.0, "dy": 0.0})
	_check(normal.size == reverse.size, "Reverse note no longer uses the normal note geometry.")
	_check(normal.call("get_outline_color").is_equal_approx(MinimalThemeScript.NORMAL_BLUE), "Normal note runtime outline is not blue.")
	_check(reverse.call("get_outline_color").is_equal_approx(MinimalThemeScript.REVERSE_RED), "Reverse note runtime outline is not red.")
	_check(space.call("get_outline_color").is_equal_approx(MinimalThemeScript.SPACE_GOLD), "Space target runtime outline is not gold.")
	normal.free()
	reverse.free()
	space.free()

func _inside_viewport(control: Control, resolution: Vector2i) -> bool:
	if control == null or not control.is_visible_in_tree():
		return false
	var rect := control.get_global_rect()
	var bounds := Rect2(Vector2.ZERO, Vector2(resolution))
	return rect.size.x > 0.0 and rect.size.y > 0.0 and bounds.encloses(rect.grow(-0.5))

func _rect_inside_viewport(rect: Rect2, resolution: Vector2i) -> bool:
	var bounds := Rect2(Vector2.ZERO, Vector2(resolution))
	return rect.size.x > 0.0 and rect.size.y > 0.0 and bounds.encloses(rect.grow(-0.5))

func _resize_to(resolution: Vector2i) -> void:
	root.size = resolution
	root.content_scale_size = resolution
	await _settle(4)

func _settle(frame_count: int) -> void:
	for _frame in range(frame_count):
		await process_frame

func _wait_for_navigation(max_frames: int = 600) -> void:
	for _frame in range(max_frames):
		if not bool(navigation.call("is_navigating")):
			await process_frame
			return
		await process_frame
	_check(false, "Navigation did not finish within the UI test deadline.")

func _cleanup_new_orphan_nodes(baseline_ids: Array[int]) -> void:
	for instance_id: int in Node.get_orphan_node_ids():
		if baseline_ids.has(instance_id):
			continue
		var orphan := instance_from_id(instance_id)
		if orphan is Node and is_instance_valid(orphan):
			(orphan as Node).free()

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)

func _finish(exit_code: int) -> void:
	quit(exit_code)
