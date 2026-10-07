extends SceneTree

const QA_ENVIRONMENT_VARIABLE := "BEAT_UP_QA_NAVIGATION_LIFECYCLE"
const QA_ENVIRONMENT_VALUE := "isolated"

var failures := 0
var navigation_states: Array[bool] = []
var route_changes: Array[Dictionary] = []
var completions: Array[Dictionary] = []
var navigation: Node
var shell: Control
var monitor_continuity := false
var continuity_frames := 0
var continuity_background_changes := 0
var continuity_origin_path := ""
var continuity_song_id := ""

func _initialize() -> void:
	if OS.get_environment(QA_ENVIRONMENT_VARIABLE) != QA_ENVIRONMENT_VALUE:
		push_error("Refusing to run AppShell lifecycle QA outside its isolated environment.")
		quit(2)
		return
	call_deferred("_run")

func _run() -> void:
	var baseline_orphans: Array[int] = Node.get_orphan_node_ids()
	root.size = Vector2i(1600, 900)
	navigation = root.get_node("NavigationController")
	navigation.connect("navigation_state_changed", Callable(self, "_on_navigation_state_changed"))
	navigation.connect("route_changed", Callable(self, "_on_route_changed"))
	navigation.connect("navigation_completed", Callable(self, "_on_navigation_completed"))

	var scene := load("res://scenes/app_shell.tscn") as PackedScene
	shell = scene.instantiate() as Control
	root.add_child(shell)
	await process_frame
	await process_frame
	_check(str(shell.call("get_active_route")) == "main_menu", "AppShell did not begin on Main Menu.")
	var resident_count := shell.get_node("ScreenHost").get_child_count()
	var library: Control = shell.get("song_library_screen") as Control
	var startup: Control = shell.get("startup_screen") as Control
	var gameplay: Control = shell.get("gameplay_screen") as Control
	var song_select: Control = library.get("song_select") as Control
	process_frame.connect(_observe_continuity)
	root.get_node("BackgroundSession").connect("background_changed", _on_background_changed)
	var play_connection_count := song_select.get_signal_connection_list("play_requested").size()

	_check(not navigation.has_method("request_chart_studio"), "Retired Chart Studio route is still callable.")
	_check(shell.get_node("ScreenHost").get_child_count() == 3, "Unexpected resident route.")
	var states_before := navigation_states.size()
	var route_count_before := route_changes.size()
	var completions_before := completions.size()

	# Main Menu <-> Song Library is repeatable and each transaction completes once.
	for _cycle in range(2):
		continuity_song_id = "bad_apple" if _cycle == 0 else "crab_rave"
		# Force a different resident presentation, including an unfinished detail tween.
		song_select.call("_select_song", "night_of_nights")
		monitor_continuity = true
		continuity_frames = 0
		continuity_background_changes = 0
		continuity_origin_path = str(root.get_node("BackgroundSession").call("get_background_path"))
		await _expect_success("request_song_library", [continuity_song_id, false], "song_library")
		_check(continuity_frames > 0, "No continuity tween frames were exercised.")
		_check(continuity_background_changes == 1, "Library visit did not publish exactly one prepared background.")
		var visual: Control = song_select.get("backdrop_visual") as Control
		var session: Node = root.get_node("BackgroundSession")
		var revealed_path := str(session.call("get_background_path"))
		_check(str(visual.get("current_background_path")) == revealed_path, "Library revealed before its background was applied.")
		_check(str(visual.get("pending_background_path")).is_empty() and float(visual.get("background_fade")) == 1.0, "Library revealed a pending/unfinished background swap.")
		await create_timer(0.5).timeout
		_check(str(session.call("get_background_path")) == revealed_path and continuity_background_changes == 1, "Library background changed again after reveal.")
		_check(str(song_select.call("get_selected_song_id")) == continuity_song_id, "Late detail completion changed destination selection.")
		var background: TextureRect = startup.get("menu_background") as TextureRect
		var controller: RefCounted = startup.get("main_menu_background_controller") as RefCounted
		controller.call("animate_visit")
		_check(background.scale == Vector2.ONE and background.modulate == Color.WHITE, "Hidden Main Menu animated based on child visibility.")
		continuity_background_changes = 0
		continuity_origin_path = str(session.call("get_background_path"))
		await _expect_success("request_main_menu", [0], "main_menu")
		_check(continuity_background_changes == 1, "Main Menu visit published more than one background.")
		revealed_path = str(session.call("get_background_path"))
		_check(background.texture == session.call("get_texture"), "Main Menu revealed a stale texture.")
		_check(background.scale == Vector2.ONE and background.modulate == Color.WHITE, "Main Menu added a visit fade/zoom.")
		await create_timer(0.8).timeout
		_check(str(session.call("get_background_path")) == revealed_path and continuity_background_changes == 1, "Main Menu background changed again after reveal.")
		_check(background.scale == Vector2.ONE and background.modulate == Color.WHITE, "Late Main Menu animation altered the final destination.")
		_check((startup.get("menu_dim") as ColorRect).visible, "Main Menu lost its continuity scrim.")
		monitor_continuity = false

	await _expect_success("request_song_library", [], "song_library")
	# Failed gameplay preparation never suspends or commits the resident player.
	_configure_music(true)
	var paused_stream: AudioStream = (root.get_node("MusicSession").get("player") as AudioStreamPlayer).stream
	states_before = navigation_states.size()
	completions_before = completions.size()
	route_count_before = route_changes.size()
	library.call("_on_play_requested", "qa_missing_song", "normal", false)
	await _wait_for_navigation()
	_check(str(shell.call("get_active_route")) == "song_library", "Failed gameplay preparation left Song Library.")
	_check(not bool(library.get("action_locked")), "Failed gameplay preparation left Song Library locked.")
	_check(not gameplay.visible, "Failed gameplay preparation exposed GameplayScreen.")
	_check(route_changes.size() == route_count_before, "Failed gameplay preparation emitted a route change.")

	_check(bool(root.get_node("MusicSession").call("is_paused")), "Failed launch resumed user-paused music.")
	_check((root.get_node("MusicSession").get("player") as AudioStreamPlayer).stream == paused_stream, "Failed launch replaced the user-paused stream.")
	_check(navigation_states.slice(states_before) == [true, false], "Failed launch broke state signal pairing.")
	_check(completions.size() == completions_before + 1, "Failed launch did not finish exactly once.")
	_check(not bool(root.get_node("SceneTransition").call("is_transitioning")), "Failed launch retained its loading overlay lock.")
	root.get_node("MusicSession").call("set_paused", false)

	# A post-preparation activation failure rolls lifecycle back atomically.
	shell.call("set_navigation_test_failure", "gameplay", true)
	route_count_before = route_changes.size()
	library.call("_on_play_requested", "bad_apple", "normal", false)
	await _wait_for_navigation(900)
	_check(str(shell.call("get_active_route")) == "song_library", "Gameplay activation failure did not restore Song Library.")
	_check(not bool(library.get("action_locked")), "Gameplay activation failure left Song Library locked.")
	_check(not gameplay.visible, "Gameplay activation failure exposed the resident gameplay route.")
	_check(route_changes.size() == route_count_before, "Gameplay activation failure emitted a route change.")
	_check(not bool(navigation.call("is_navigating")), "Gameplay activation failure left NavigationController locked.")
	shell.call("set_navigation_test_failure", "gameplay", false)

	# Song Library <-> Gameplay remains deterministic across repeated cycles.
	var launch_request := {"song_id": "bad_apple", "difficulty_id": "normal", "random_mode": false}
	for _cycle in range(2):
		await _expect_success("request_gameplay", [launch_request, {}], "gameplay", 900)
		await _expect_success("request_song_library", ["bad_apple", false], "song_library")

	# Result is route-owned gameplay state; returning still commits one shell route.
	await _expect_success("request_gameplay", [launch_request, {}], "gameplay", 900)
	gameplay.call("show_result_debug_screen")
	await process_frame
	_check(bool((gameplay.get("result_overlay") as Control).visible), "Result overlay did not become active inside the gameplay route.")
	_check(str(shell.call("get_active_route")) == "gameplay", "Result incorrectly changed the shell route.")
	await _expect_success("request_song_library", ["bad_apple", false], "song_library")

	# A concurrent request is cancelled explicitly and cannot duplicate a commit.
	await _expect_success("request_main_menu", [0], "main_menu")
	states_before = navigation_states.size()
	var routes_before := route_changes.size()
	completions_before = completions.size()
	navigation.call("request_song_library")
	var duplicate_value: Variant = await navigation.call("request_main_menu")
	var duplicate: Dictionary = duplicate_value as Dictionary if duplicate_value is Dictionary else {}
	_check(str(duplicate.get("outcome", "")) == "cancelled", "Concurrent navigation was not explicitly cancelled.")
	await _wait_for_navigation()
	_check(str(shell.call("get_active_route")) == "song_library", "Concurrent request changed the winning destination.")
	_check(navigation_states.slice(states_before) == [true, false], "Concurrent request broke navigation-state signal pairing.")
	_check(route_changes.size() == routes_before + 1, "Concurrent request created a duplicate or missing route commit.")
	_check(completions.size() == completions_before + 2, "Concurrent requests did not each complete exactly once.")

	_check(shell.get_node("ScreenHost").get_child_count() == resident_count, "Repeated navigation duplicated a resident screen.")
	_check(song_select.get_signal_connection_list("play_requested").size() == play_connection_count, "Repeated navigation duplicated Song Library signal connections.")
	var navigation_source := FileAccess.get_file_as_string("res://scripts/navigation_controller.gd")
	_check(not navigation_source.contains("range(180)"), "Navigation still depends on the 180-frame polling watchdog.")
	_check(not navigation_source.contains("_finish_navigation_when_route"), "Legacy route-polling completion remains reachable.")

	print("APP_SHELL_NAVIGATION_LIFECYCLE_TEST: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	root.remove_child(shell)
	shell.free()
	await process_frame
	_cleanup_new_orphan_nodes(baseline_orphans)
	call_deferred("_finish", 1 if failures > 0 else 0)

func _on_background_changed(_state: Dictionary) -> void:
	if monitor_continuity:
		continuity_background_changes += 1

func _observe_continuity() -> void:
	if not monitor_continuity or not is_instance_valid(shell) or not bool(shell.get("switching")):
		return
	continuity_frames += 1
	var startup: Control = shell.get("startup_screen") as Control
	var library: Control = shell.get("song_library_screen") as Control
	_check(not (startup.is_visible_in_tree() and startup.modulate.a > 0.001 and library.is_visible_in_tree() and library.modulate.a > 0.001), "Resident foregrounds overlap during transition.")
	if shell.get_node_or_null("RouteBackdrop") == null:
		# Preload holds the origin fully visible; foreground animation has not
		# started yet. No global background publication is permitted here.
		var origin: Control = startup if str(shell.call("get_active_route")) == "main_menu" else library
		_check(origin.is_visible_in_tree() and origin.modulate.a == 1.0, "Preload altered the outgoing foreground before preparation finished.")
		_check(str(root.get_node("BackgroundSession").call("get_background_path")) == continuity_origin_path, "Preload published the background before the foreground handoff.")
		return
	for screen: Control in [startup, library]:
		for item: CanvasItem in screen.call("shell_background_items"):
			_check(not item.visible, "Screen-local background participated in the foreground fade.")
	if library.is_visible_in_tree() and library.modulate.a > 0.001:
		var select: Control = library.get("song_select") as Control
		_check(str(select.call("get_selected_song_id")) == continuity_song_id, "Incoming Library revealed the previous selection.")
		var row_index: int = select.filtered_song_ids.find(continuity_song_id)
		_check(row_index >= 0 and (select.song_buttons[row_index] as Button).button_pressed, "Incoming Library row selection is stale.")
		if row_index >= 0:
			_check((select.song_scroll as Control).get_global_rect().intersects((select.song_groups[row_index] as Control).get_global_rect()), "Destination selection is offscreen during reveal.")
		var rep: Dictionary = select.call("_representative", continuity_song_id)
		_check((select.get("detail_title") as Label).text.to_upper() == str(rep.get("title", "")).to_upper(), "Incoming Library title changed after reveal.")
		var expected_art: Texture2D = select.call("_song_banner_texture", continuity_song_id, str(rep.get("background", "")))
		_check((select.get("album_flow_artwork") as TextureRect).texture == expected_art, "Incoming Library revealed stale artwork.")
		var visual: Control = select.get("backdrop_visual") as Control
		_check(str(visual.get("current_background_path")) == str(root.get_node("BackgroundSession").call("get_background_path")) and float(visual.get("background_fade")) == 1.0, "Incoming Library frame used an unfinished background.")
	if startup.is_visible_in_tree() and startup.modulate.a > 0.001:
		_check((startup.get("menu_visual") as Control).modulate.a == 1.0, "Main Menu brand has an independent reveal after route preparation.")

func _expect_success(method_name: String, arguments: Array, expected_route: String, max_frames: int = 600) -> void:
	var previous_route := str(shell.call("get_active_route"))
	var states_before := navigation_states.size()
	var routes_before := route_changes.size()
	var completions_before := completions.size()
	var started_at := Time.get_ticks_msec()
	var result_value: Variant = await navigation.callv(method_name, arguments)
	if previous_route != expected_route and previous_route in ["main_menu", "song_library"] and expected_route in ["main_menu", "song_library"]:
		var minimum_motion := (BeatUpAppShell.MENU_EXIT_DURATION + BeatUpAppShell.MENU_ENTER_DURATION) * 0.8
		_check(float(Time.get_ticks_msec() - started_at) / 1000.0 >= minimum_motion, "Menu transition skipped its fluid foreground motion.")
	var result: Dictionary = result_value as Dictionary if result_value is Dictionary else {}
	_check(str(result.get("outcome", "")) == "success", "%s did not complete successfully: %s" % [method_name, str(result.get("reason", "missing result"))])
	_check(str(result.get("previous_route", "")) == previous_route, "%s reported the wrong previous route." % method_name)
	_check(str(result.get("resulting_route", "")) == expected_route, "%s reported the wrong resulting route." % method_name)
	_check(str(shell.call("get_active_route")) == expected_route, "%s did not commit the expected AppShell route." % method_name)
	_check(navigation_states.slice(states_before) == [true, false], "%s did not pair navigation state signals." % method_name)
	_check(completions.size() == completions_before + 1, "%s did not complete exactly once." % method_name)
	var expected_route_changes := 0 if previous_route == expected_route else 1
	_check(route_changes.size() == routes_before + expected_route_changes, "%s emitted an incorrect number of route changes." % method_name)
	if previous_route == "song_library" and expected_route != previous_route:
		_check(not bool((shell.get("song_library_screen") as Control).get("action_locked")), "%s did not release the outgoing Song Library action lock." % method_name)
	await process_frame
	await process_frame
	_check(_focus_matches_route(expected_route), "%s did not restore the destination focus policy." % method_name)
	_check(not bool(navigation.call("is_navigating")), "%s left navigation active." % method_name)
	# Keep the argument meaningful for slower CI machines without production polling.
	_check(max_frames >= 1, "Invalid test wait budget.")

func _wait_for_navigation(max_frames: int = 600) -> void:
	for _frame in range(max_frames):
		if not bool(navigation.call("is_navigating")):
			await process_frame
			return
		await process_frame
	_check(false, "Navigation did not complete within the test deadline.")

func _configure_music(paused: bool) -> void:
	var session: Node = root.get_node("MusicSession")
	var player: AudioStreamPlayer = session.get("player") as AudioStreamPlayer
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 44100.0
	stream.buffer_length = 2.0
	player.stream = stream
	player.play()
	session.call("set_paused", paused)

func _all_menu_buttons_enabled(startup: Control) -> bool:
	for value: Variant in startup.get("menu_buttons") as Array:
		if value is BaseButton and (value as BaseButton).disabled:
			return false
	return true

func _focus_is_within(control: Control) -> bool:
	if control == null:
		return false
	var focused := root.gui_get_focus_owner()
	return focused != null and (focused == control or control.is_ancestor_of(focused))

func _focus_matches_route(route: String) -> bool:
	var active := shell.call("_active_control") as Control
	var focused := root.gui_get_focus_owner()
	if route == "song_library" or route == "gameplay":
		# These routes intentionally use global gameplay/library input and release
		# stale GUI focus instead of assigning a focused button.
		return focused == null or _focus_is_within(active)
	return _focus_is_within(active)

func _cleanup_new_orphan_nodes(baseline_ids: Array[int]) -> void:
	for instance_id: int in Node.get_orphan_node_ids():
		if baseline_ids.has(instance_id):
			continue
		var orphan := instance_from_id(instance_id)
		if orphan is Node and is_instance_valid(orphan):
			(orphan as Node).free()

func _on_navigation_state_changed(navigating: bool) -> void:
	navigation_states.append(navigating)

func _on_route_changed(previous_route: String, current_route: String) -> void:
	route_changes.append({"previous": previous_route, "current": current_route})

func _on_navigation_completed(result: Dictionary) -> void:
	completions.append(result.duplicate(true))

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)

func _finish(exit_code: int) -> void:
	quit(exit_code)
