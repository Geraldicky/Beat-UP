extends SceneTree

const QA_ENVIRONMENT_VARIABLE := "BEAT_UP_QA_NAVIGATION_LIFECYCLE"
const QA_ENVIRONMENT_VALUE := "isolated"

var failures := 0
var navigation_states: Array[bool] = []
var route_changes: Array[Dictionary] = []
var completions: Array[Dictionary] = []
var navigation: Node
var shell: Control

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
	var chart_host: Control = shell.get("chart_studio_screen") as Control
	var song_select: Control = library.get("song_select") as Control
	var play_connection_count := song_select.get_signal_connection_list("play_requested").size()

	# A stalled lazy load is bounded locally and restores every Main Menu owner.
	_configure_music(false)
	shell.call("set_chart_studio_load_timeout_for_test", 0.05)
	shell.call("set_navigation_test_failure", "chart_studio_stall", true)
	var states_before := navigation_states.size()
	var route_count_before := route_changes.size()
	var completions_before := completions.size()
	startup.call("_on_chart_studio_pressed")
	await _wait_for_navigation()
	_check(str(shell.call("get_active_route")) == "main_menu", "Chart Studio timeout did not restore Main Menu.")
	_check(startup.visible and startup.process_mode == Node.PROCESS_MODE_INHERIT, "Chart Studio timeout did not restore Main Menu visibility/process state.")
	_check(not chart_host.visible and chart_host.process_mode == Node.PROCESS_MODE_DISABLED, "Chart Studio timeout left the attempted route active.")
	_check(not bool(startup.get("in_transition")), "Main Menu remained locally locked after Chart Studio timeout.")
	_check(_all_menu_buttons_enabled(startup), "Main Menu controls remained disabled after Chart Studio timeout.")
	_check(navigation_states.slice(states_before) == [true, false], "Chart Studio timeout broke navigation-state signal pairing.")
	_check(completions.size() == completions_before + 1, "Chart Studio timeout did not complete exactly once.")
	var main_timeout_result: Dictionary = completions.back()
	_check(str(main_timeout_result.get("outcome", "")) == "failure", "Chart Studio timeout did not report failure.")
	_check(str(main_timeout_result.get("reason", "")).contains("timed out"), "Chart Studio timeout did not report its bounded-load reason.")
	_check(route_changes.size() == route_count_before, "Timed-out Chart Studio entry emitted a false route change.")
	_check(not bool(root.get_node("MusicSession").call("is_paused")), "Shell did not restore music that it paused for timed-out Chart Studio entry.")
	_check(not bool(navigation.call("is_navigating")), "Chart Studio timeout left NavigationController locked.")
	_check(bool(startup.get("splash_finished")), "Suspending Main Menu did not retire its pending boot reveal.")
	await process_frame
	_check(_focus_is_within(startup), "Main Menu focus was not restored after Chart Studio failure.")
	# Releasing the injected stall cannot let the expired generation commit later.
	shell.call("set_navigation_test_failure", "chart_studio_stall", false)
	for _frame in range(6):
		await process_frame
	_check(str(shell.call("get_active_route")) == "main_menu", "A stale Chart Studio completion committed after timeout.")
	_check(route_changes.size() == route_count_before, "A stale Chart Studio completion emitted a route change.")
	# Main Menu rollback restores presentation, not a new music activation.
	_configure_music(true)
	var paused_stream: AudioStream = (root.get_node("MusicSession").get("player") as AudioStreamPlayer).stream
	shell.call("set_navigation_test_failure", "chart_studio_stall", true)
	startup.call("_on_chart_studio_pressed")
	await _wait_for_navigation()
	_check(bool(root.get_node("MusicSession").call("is_paused")), "Main Menu rollback resumed user-paused music.")
	_check((root.get_node("MusicSession").get("player") as AudioStreamPlayer).stream == paused_stream, "Main Menu rollback replaced the user's paused stream.")
	shell.call("set_navigation_test_failure", "chart_studio_stall", false)
	root.get_node("MusicSession").call("set_paused", false)

	# Main Menu <-> Song Library is repeatable and each transaction completes once.
	for _cycle in range(2):
		await _expect_success("request_song_library", [], "song_library")
		await _expect_success("request_main_menu", [0], "main_menu")

	await _expect_success("request_song_library", [], "song_library")
	# A user-paused MusicSession must remain paused after a timed-out entry, and
	# Song Library's caller-local action lock must be released.
	_configure_music(true)
	shell.call("set_navigation_test_failure", "chart_studio_stall", true)
	states_before = navigation_states.size()
	route_count_before = route_changes.size()
	completions_before = completions.size()
	library.call("_on_chart_editor_requested")
	await _wait_for_navigation()
	_check(str(shell.call("get_active_route")) == "song_library", "Chart Studio timeout did not restore Song Library.")
	_check(library.visible and library.process_mode == Node.PROCESS_MODE_INHERIT, "Chart Studio timeout did not restore Song Library visibility/process state.")
	_check(not bool(library.get("action_locked")), "Song Library action lock survived timed-out Chart Studio entry.")
	_check(bool(root.get_node("MusicSession").call("is_paused")), "Chart Studio timeout resumed music that was already user-paused.")
	_check(not bool(shell.get("chart_studio_music_paused_by_shell")), "Shell retained temporary Chart Studio music ownership after rollback.")
	_check(navigation_states.slice(states_before) == [true, false], "Song Library Chart Studio timeout broke navigation-state signal pairing.")
	_check(completions.size() == completions_before + 1, "Song Library Chart Studio timeout did not complete exactly once.")
	var library_timeout_result: Dictionary = completions.back()
	_check(str(library_timeout_result.get("outcome", "")) == "failure", "Song Library Chart Studio timeout did not report failure.")
	_check(route_changes.size() == route_count_before, "Timed-out Chart Studio entry committed a route.")
	# Wait past the old boot callback deadline: a hidden Main Menu must not
	# resume playback or reclaim focus after this transaction has finished.
	await create_timer(1.7).timeout
	_check(bool(root.get_node("MusicSession").call("is_paused")), "A stale Main Menu reveal resumed user-paused music after rollback.")
	await process_frame
	_check(_focus_matches_route("song_library"), "Song Library focus policy was not restored after Chart Studio failure.")
	shell.call("set_navigation_test_failure", "chart_studio_stall", false)
	shell.call("set_chart_studio_load_timeout_for_test", -1.0)
	root.get_node("MusicSession").call("set_paused", false)

	# Song Library <-> lazily-instantiated Chart Studio is repeatable.
	for _cycle in range(2):
		await _expect_success("request_chart_studio", [], "chart_studio")
		_check(is_instance_valid(shell.get("chart_studio_instance")), "Successful Chart Studio route has no usable editor instance.")
		await _expect_chart_studio_return("song_library")

	# Failed gameplay preparation never suspends or commits the resident player.
	route_count_before = route_changes.size()
	library.call("_on_play_requested", "qa_missing_song", "normal", false)
	await _wait_for_navigation()
	_check(str(shell.call("get_active_route")) == "song_library", "Failed gameplay preparation left Song Library.")
	_check(not bool(library.get("action_locked")), "Failed gameplay preparation left Song Library locked.")
	_check(not gameplay.visible, "Failed gameplay preparation exposed GameplayScreen.")
	_check(route_changes.size() == route_count_before, "Failed gameplay preparation emitted a route change.")

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
	var duplicate_value: Variant = await navigation.call("request_chart_studio")
	var duplicate: Dictionary = duplicate_value as Dictionary if duplicate_value is Dictionary else {}
	_check(str(duplicate.get("outcome", "")) == "cancelled", "Concurrent navigation was not explicitly cancelled.")
	await _wait_for_navigation()
	_check(str(shell.call("get_active_route")) == "song_library", "Concurrent request changed the winning destination.")
	_check(navigation_states.slice(states_before) == [true, false], "Concurrent request broke navigation-state signal pairing.")
	_check(route_changes.size() == routes_before + 1, "Concurrent request created a duplicate or missing route commit.")
	_check(completions.size() == completions_before + 2, "Concurrent requests did not each complete exactly once.")

	_check(shell.get_node("ScreenHost").get_child_count() == resident_count, "Repeated navigation duplicated a resident screen.")
	_check(chart_host.get_child_count() == 3, "Repeated Chart Studio entry duplicated its lazy editor instance.")
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

func _expect_success(method_name: String, arguments: Array, expected_route: String, max_frames: int = 600) -> void:
	var previous_route := str(shell.call("get_active_route"))
	var states_before := navigation_states.size()
	var routes_before := route_changes.size()
	var completions_before := completions.size()
	var result_value: Variant = await navigation.callv(method_name, arguments)
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

func _expect_chart_studio_return(expected_route: String) -> void:
	var states_before := navigation_states.size()
	var routes_before := route_changes.size()
	var completions_before := completions.size()
	var editor: Control = shell.get("chart_studio_instance") as Control
	editor.call("return_to_game")
	await _wait_for_navigation()
	_check(str(shell.call("get_active_route")) == expected_route, "Chart Studio Back did not restore its originating route.")
	_check(navigation_states.slice(states_before) == [true, false], "Chart Studio Back broke navigation-state pairing.")
	_check(route_changes.size() == routes_before + 1, "Chart Studio Back did not commit exactly one route change.")
	_check(completions.size() == completions_before + 1, "Chart Studio Back did not complete exactly once.")
	_check(_focus_matches_route(expected_route), "Chart Studio Back did not restore origin focus policy.")

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
