extends SceneTree

const QA_ENVIRONMENT_VARIABLE := "BEAT_UP_QA_LOADING_PRESENTATION"
var failures := 0
var observed_loading_frames := 0
var observed_starts := 0
var observed_finishes := 0
var watch_launch := false
var shell: Control

func _initialize() -> void:
	if OS.get_environment(QA_ENVIRONMENT_VARIABLE) != "isolated":
		push_error("Refusing loading presentation QA outside isolated user data.")
		quit(2)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1600, 900)
	var boot := (load("res://scenes/boot.tscn") as PackedScene).instantiate() as Control
	root.add_child(boot)
	current_scene = boot
	# Validate the fixed wordmark with a moving clip, not scaled/sliding letters.
	boot.call("_set_reveal", 0.25)
	var mask := boot.get("logo_window") as Control
	var logo := boot.get("logo") as Control
	var fixed_size := logo.size
	var origin := mask.position
	_check(is_equal_approx(mask.size.x, fixed_size.x * 0.25), "Boot mask does not reveal left-to-right.")
	boot.call("_set_reveal", 0.75)
	_check(logo.size == fixed_size and logo.position == Vector2.ZERO and mask.position == origin, "Boot reveal moved/resized the wordmark.")
	boot.call("_set_reveal", 0.25)
	_check(mask.position == origin and is_equal_approx(mask.size.x, fixed_size.x * 0.25), "Boot retirement does not erase right-to-left.")
	boot.call("_set_reveal", 0.0)
	await create_timer(0.3).timeout
	await _capture("boot")
	var deadline := Time.get_ticks_msec() + 30000
	while (current_scene == boot or current_scene == null) and Time.get_ticks_msec() < deadline:
		await process_frame
	shell = current_scene as Control
	_check(shell != null and shell.has_method("get_active_route"), "Lightweight boot did not open AppShell.")
	if shell == null or not shell.has_method("get_active_route"):
		quit(1)
		return
	await process_frame
	var startup := shell.get("startup_screen") as Control
	_check(not (startup.get_node("Splash") as Control).visible, "AppShell ran a second launch splash.")
	_check(startup.get_node_or_null("MainMenu/MenuStack/ChartStudioButton") == null, "Retired Chart Studio action returned.")
	var navigation := root.get_node("NavigationController")
	await navigation.call("request_song_library", "bad_apple", false)
	var transition := root.get_node("SceneTransition")
	transition.connect("transition_started", _on_start)
	transition.connect("transition_finished", _on_finish)
	process_frame.connect(_observe_launch)
	var library := shell.get("song_library_screen") as Control
	watch_launch = true
	library.call("_on_play_requested", "qa_missing_chart", "normal", false)
	while bool(navigation.call("is_navigating")):
		await process_frame
	watch_launch = false
	_check(observed_loading_frames > 0, "Preparation failed before showing any loading frame.")
	_check(observed_starts == 1 and observed_finishes == 1, "Failed loading did not start/finish exactly once.")
	_check(str(shell.call("get_active_route")) == "song_library" and library.is_visible_in_tree(), "Invalid launch did not retain the origin.")
	_check(not bool(transition.call("is_transitioning")) and not bool(library.get("action_locked")), "Failed launch retained a loading/local action lock.")

	# Exercise a slow preparation independent of chart size / CPU speed. The
	# existing readiness boundary must hold the loading screen until ready.
	var probe := Control.new()
	probe.set_script(load("res://tests/loading_readiness_probe.gd"))
	root.add_child(probe)
	current_scene = probe
	await transition.call("begin_gameplay_preparation", {"title": "QA LOADING", "difficulty": "NORMAL"})
	transition.call("transition_action_to_gameplay", Callable(probe, "prepare"), {"title": "QA AUTHORITATIVE", "difficulty": "HARD"})
	await create_timer(0.4).timeout
	var visual := transition.get("song_launch_visual") as Control
	_check(bool(transition.call("is_transitioning")) and visual.is_visible_in_tree(), "Loading revealed gameplay before readiness.")
	_check((visual.get("title_label") as Label).text == "QA AUTHORITATIVE" and (visual.get("info_rail") as Control).modulate.a == 1.0, "Resolved identity disappeared while still loading.")
	visual.call("configure", {"song_id": "bad_apple", "title": "QA AUTHORITATIVE", "artist": "QA ARTIST"}, true)
	var jacket := visual.get("artwork") as TextureRect
	_check(jacket.texture != null and jacket.texture.resource_path == "res://assets/song_thumbnails/bad_apple.png", "Loading jacket is not selected-song artwork.")
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]:
		root.size = resolution
		await process_frame
		await process_frame
		var title := visual.get("title_label") as Label
		var artist := visual.get("artist_label") as Label
		var loading_rail: Rect2 = visual.get("rail")
		# Window pixels can differ from canvas coordinates under Godot stretch.
		var canvas_center := visual.get_global_rect().get_center().x
		_check(absf(jacket.size.x - jacket.size.y) < 1.0 and absf(jacket.get_global_rect().get_center().x - canvas_center) < 2.0, "Loading jacket is not a centered square.")
		_check(title.get_global_rect().position.y >= jacket.get_global_rect().end.y and artist.get_global_rect().position.y >= title.get_global_rect().end.y, "Loading identity overlaps or is ordered incorrectly.")
		_check(loading_rail.position.y > artist.get_global_rect().end.y and loading_rail.end.y < visual.size.y, "Loading rail is clipped or above artist.")
		_check(not (visual.get("detail_label") as Label).visible, "Minimal loading still exposes difficulty metadata.")
	root.size = Vector2i(1600, 900)
	await process_frame
	await _capture("gameplay_loading")
	probe.set("prepared", true)
	while bool(transition.call("is_transitioning")):
		await process_frame
	_check(not visual.visible, "Loading overlay remained after readiness.")
	_check(observed_starts == 2 and observed_finishes == 2, "Covered launch emitted duplicate transition signals.")
	current_scene = shell
	probe.free()
	_check((shell.get("gameplay_screen") as Control).get_node_or_null("Battle/Track/Lane/InputCompass") == null, "Gameplay key compass is still rendered.")
	await process_frame
	_check_tooltips(shell)
	var pause := (shell.get("gameplay_screen") as Control).get("pause_overlay") as Control
	_check((pause.get("resume_button") as Button).text == "Resume", "Removing tooltips erased the persistent pause action label.")
	_check((pause.get("action_hint") as Label).text == "ESC TO RESUME", "Pause keyboard guidance disappeared.")
	_check_tooltips(pause)
	# File picker paths formerly lived in tooltip_text. Clearing hover text must
	# not erase the import target. This synthetic path never touches the disk.
	var picker := load("res://scripts/ui/beat_file_picker.gd").new() as Control
	root.add_child(picker)
	picker.set("file_mode", 1)
	picker.set("_current_dir", "user://qa_loading_identity")
	var entry := picker.call("_make_entry_button", "qa_chart.json", false) as Button
	picker.add_child(entry)
	await process_frame
	entry.set_pressed_no_signal(true)
	entry.pressed.emit()
	_check((picker.get("_selected_paths") as PackedStringArray).has("user://qa_loading_identity/qa_chart.json"), "Tooltip removal broke file selection paths.")
	_check_tooltips(picker)
	picker.free()
	print("LOADING_PRESENTATION_TEST: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	root.remove_child(shell)
	shell.free()
	await process_frame
	quit(1 if failures else 0)

func _observe_launch() -> void:
	if not watch_launch:
		return
	var transition := root.get_node("SceneTransition")
	var visual := transition.get("song_launch_visual") as Control
	if visual.is_visible_in_tree() and visual.modulate.a > 0.9:
		observed_loading_frames += 1
		_check(str(shell.call("get_active_route")) == "song_library", "Loading activated gameplay before authoritative preparation.")
		_check((visual.get("info_rail") as Control).is_visible_in_tree(), "Loading identity is not visible.")

func _on_start(_status: String) -> void:
	observed_starts += 1

func _on_finish() -> void:
	observed_finishes += 1

func _check_tooltips(node: Node) -> void:
	if node is Control:
		_check((node as Control).tooltip_text.is_empty(), "Hover tooltip remains on %s." % node.name)
	for child: Node in node.get_children():
		_check_tooltips(child)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _capture(name_value: String) -> void:
	var directory := OS.get_environment("BEAT_UP_QA_CAPTURE_DIR")
	if directory.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var path := directory.path_join(name_value + ".png")
	if not FileAccess.file_exists(path):
		_check(root.get_texture().get_image().save_png(path) == OK, "Could not capture rendered QA frame.")
