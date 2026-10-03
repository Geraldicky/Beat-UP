extends Control
class_name BeatUpAppShell

const SCREEN_TWEEN_DURATION := 0.20
const SCREEN_OFFSET := 24.0
const ROUTE_MAIN_MENU := "main_menu"
const ROUTE_SONG_LIBRARY := "song_library"
const ROUTE_GAMEPLAY := "gameplay"
const ROUTE_CHART_STUDIO := "chart_studio"
const CHART_STUDIO_SCENE_PATH := "res://scenes/chart_editor.tscn"
const CHART_STUDIO_LOAD_TIMEOUT_SECONDS := 8.0

@onready var startup_screen: Control = $ScreenHost/StartupScreen
@onready var song_library_screen: Control = $ScreenHost/SongLibraryScreen
@onready var gameplay_screen: Control = $ScreenHost/GameplayScreen
@onready var chart_studio_screen: Control = $ScreenHost/ChartStudioScreen

var active_screen: String = ROUTE_MAIN_MENU
var switching: bool = false
var chart_studio_instance: Control = null
var chart_studio_loading: bool = false
var chart_studio_load_failed: bool = false
var chart_studio_load_timed_out: bool = false
var chart_studio_load_generation: int = 0
var chart_studio_last_load_error: String = ""
var chart_studio_test_timeout_seconds: float = -1.0
var chart_studio_music_paused_by_shell: bool = false
var navigation_test_failures: Dictionary = {}
var gameplay_activation_result: Dictionary = {}

func _ready() -> void:
	add_to_group("beat_up_app_shell")
	# Gameplay and the resident library own distinct SongSelect instances.
	# Deliver committed records to the real library, including while hidden.
	gameplay_screen.connect("best_stats_changed", Callable(song_library_screen, "receive_best_stats"))
	var navigation: Node = get_node_or_null("/root/NavigationController")
	if navigation != null and navigation.has_method("register_shell"):
		navigation.call("register_shell", self)
	_set_screen_state(startup_screen, true)
	_set_screen_state(song_library_screen, false)
	_set_screen_state(gameplay_screen, false)
	_set_screen_state(chart_studio_screen, false)
	startup_screen.position = Vector2.ZERO
	song_library_screen.position = Vector2.ZERO
	gameplay_screen.position = Vector2.ZERO
	chart_studio_screen.position = Vector2.ZERO

func _exit_tree() -> void:
	var navigation: Node = get_node_or_null("/root/NavigationController")
	if navigation != null and navigation.has_method("unregister_shell"):
		navigation.call("unregister_shell", self)

func _input(event: InputEvent) -> void:
	if not switching:
		return
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
		get_viewport().set_input_as_handled()

func get_active_route() -> String:
	return active_screen

func is_switching() -> bool:
	return switching

func show_song_library(selected_song_id: String = "", refresh_data: bool = false, transaction_id: int = 0) -> Dictionary:
	var previous_route := active_screen
	if _navigation_blocked():
		return _navigation_result("cancelled", previous_route, previous_route, "Navigation is currently blocked.", transaction_id)
	if active_screen == ROUTE_CHART_STUDIO:
		# Chart creation may have published or discarded drafts while the resident
		# library was hidden; force a fresh catalog before rebuilding its cards.
		refresh_data = true
	if selected_song_id.is_empty():
		var selection_state: Node = get_node_or_null("/root/SongSelectionState")
		if selection_state != null and selection_state.has_method("get_song_id"):
			selected_song_id = str(selection_state.call("get_song_id"))
	var context: Dictionary = {
		"selected_song_id": selected_song_id,
		"refresh_data": refresh_data,
		"from_route": active_screen,
		"to_route": ROUTE_SONG_LIBRARY,
		"transaction_id": transaction_id,
	}
	if active_screen == ROUTE_SONG_LIBRARY:
		_notify_screen(song_library_screen, "shell_will_resume", context)
		_notify_screen(song_library_screen, "shell_did_resume", context)
		return _navigation_result("success", previous_route, active_screen, "", transaction_id)
	var outgoing := _active_control()
	_notify_screen(outgoing, "shell_will_suspend", context)
	if active_screen == ROUTE_GAMEPLAY:
		_prepare_gameplay_exit("song_library")
	await _commit_route(outgoing, song_library_screen, ROUTE_SONG_LIBRARY, 1.0 if active_screen == ROUTE_MAIN_MENU else -1.0, context)
	if str(context.get("from_route", "")) == ROUTE_CHART_STUDIO:
		_restore_music_after_chart_studio()
	if context.get("from_route", "") == ROUTE_GAMEPLAY:
		call_deferred("_cleanup_hidden_gameplay_after_return")
	return _navigation_result("success", previous_route, active_screen, "", transaction_id)

func show_main_menu(focus_index: int = 0, transaction_id: int = 0) -> Dictionary:
	var previous_route := active_screen
	if _navigation_blocked():
		return _navigation_result("cancelled", previous_route, previous_route, "Navigation is currently blocked.", transaction_id)
	var context: Dictionary = {
		"focus_index": focus_index,
		"from_route": active_screen,
		"to_route": ROUTE_MAIN_MENU,
		"transaction_id": transaction_id,
	}
	if active_screen == ROUTE_MAIN_MENU:
		_notify_screen(startup_screen, "shell_will_resume", context)
		_notify_screen(startup_screen, "shell_did_resume", context)
		return _navigation_result("success", previous_route, active_screen, "", transaction_id)
	var outgoing := _active_control()
	_notify_screen(outgoing, "shell_will_suspend", context)
	if active_screen == ROUTE_GAMEPLAY:
		_prepare_gameplay_exit("main_menu")
	await _commit_route(outgoing, startup_screen, ROUTE_MAIN_MENU, -1.0, context)
	if str(context.get("from_route", "")) == ROUTE_CHART_STUDIO:
		_restore_music_after_chart_studio()
	if context.get("from_route", "") == ROUTE_GAMEPLAY:
		call_deferred("_cleanup_hidden_gameplay_after_return")
	return _navigation_result("success", previous_route, active_screen, "", transaction_id)

func show_chart_studio(transaction_id: int = 0) -> Dictionary:
	var previous_route := active_screen
	if _navigation_blocked():
		return _navigation_result("cancelled", previous_route, previous_route, "Navigation is currently blocked.", transaction_id)
	var context: Dictionary = {
		"from_route": active_screen,
		"to_route": ROUTE_CHART_STUDIO,
		"transaction_id": transaction_id,
	}
	if active_screen == ROUTE_CHART_STUDIO:
		if is_instance_valid(chart_studio_instance):
			_notify_screen(chart_studio_screen, "shell_will_resume", context)
			_notify_screen(chart_studio_screen, "shell_did_resume", context)
			return _navigation_result("success", previous_route, active_screen, "", transaction_id)
		return _navigation_result("failure", previous_route, previous_route, "Chart Studio is not usable.", transaction_id)

	var outgoing := _active_control()
	_notify_screen(outgoing, "shell_will_suspend", context)
	_pause_music_for_chart_studio()
	var editor := await _ensure_chart_studio_loaded()
	if editor == null:
		var load_failure_reason := chart_studio_last_load_error if not chart_studio_last_load_error.is_empty() else "Chart Studio could not be loaded."
		_restore_music_after_chart_studio()
		# A failed Chart Studio attempt never transferred route ownership. Mark the
		# resume as a rollback so resident screens restore UI/focus without starting
		# new media that could override a user's pre-existing paused state.
		var rollback_context := context.duplicate(true)
		rollback_context["navigation_rollback"] = true
		rollback_context["preserve_music_state"] = true
		_rollback_to_origin(outgoing, chart_studio_screen, previous_route, rollback_context)
		_notify_screen(outgoing, "handle_navigation_failure", {
			"route": ROUTE_CHART_STUDIO,
			"error": load_failure_reason,
		})
		return _navigation_result("failure", previous_route, previous_route, load_failure_reason, transaction_id)

	if previous_route == ROUTE_GAMEPLAY:
		_prepare_gameplay_exit("chart_studio")
	await _commit_route(outgoing, chart_studio_screen, ROUTE_CHART_STUDIO, 1.0, context)
	if previous_route == ROUTE_GAMEPLAY:
		call_deferred("_cleanup_hidden_gameplay_after_return")
	return _navigation_result("success", previous_route, active_screen, "", transaction_id)

func _pause_music_for_chart_studio() -> void:
	var session: Node = get_node_or_null("/root/MusicSession")
	if session == null or not session.has_method("get_state"):
		return
	var state_value: Variant = session.call("get_state")
	if not (state_value is Dictionary):
		return
	var state: Dictionary = state_value as Dictionary
	chart_studio_music_paused_by_shell = bool(state.get("playing", false)) and not bool(state.get("paused", false))
	if chart_studio_music_paused_by_shell and session.has_method("set_paused"):
		session.call("set_paused", true)

func _restore_music_after_chart_studio() -> void:
	if not chart_studio_music_paused_by_shell:
		return
	chart_studio_music_paused_by_shell = false
	var session: Node = get_node_or_null("/root/MusicSession")
	if session != null and session.has_method("set_paused"):
		session.call("set_paused", false)

func _ensure_chart_studio_loaded() -> Control:
	if is_instance_valid(chart_studio_instance):
		return chart_studio_instance
	if bool(navigation_test_failures.get(ROUTE_CHART_STUDIO, false)):
		chart_studio_last_load_error = "Chart Studio could not be loaded."
		_report_runtime("chart_studio", "Injected Chart Studio load failure")
		return null
	if chart_studio_load_failed and not chart_studio_load_timed_out:
		_update_chart_studio_loading_label("CHART STUDIO\nCOULD NOT LOAD")
		return null
	if chart_studio_load_timed_out:
		# A timed-out ResourceLoader request may still finish in the background.
		# A later transaction may adopt that resource, but the stale generation
		# that timed out can never instantiate or commit it.
		chart_studio_load_failed = false
		chart_studio_load_timed_out = false
	if chart_studio_loading:
		var observed_generation := chart_studio_load_generation
		var wait_deadline := _chart_studio_load_deadline()
		while chart_studio_loading and observed_generation == chart_studio_load_generation:
			if _monotonic_seconds() >= wait_deadline:
				_fail_chart_studio_load(observed_generation, "Chart Studio loading timed out.", true)
				return null
			await get_tree().process_frame
		return chart_studio_instance

	chart_studio_load_generation += 1
	var load_generation := chart_studio_load_generation
	chart_studio_loading = true
	chart_studio_last_load_error = ""
	_update_chart_studio_loading_label("CHART STUDIO")
	var injected_stall := bool(navigation_test_failures.get("chart_studio_stall", false))
	var initial_status: int = ResourceLoader.load_threaded_get_status(CHART_STUDIO_SCENE_PATH)
	if not injected_stall and initial_status != ResourceLoader.THREAD_LOAD_IN_PROGRESS and initial_status != ResourceLoader.THREAD_LOAD_LOADED:
		var load_error: Error = ResourceLoader.load_threaded_request(CHART_STUDIO_SCENE_PATH, "PackedScene", false)
		if load_error != OK:
			_fail_chart_studio_load(load_generation, "Chart Studio resource request failed.", false)
			_report_runtime("chart_studio", "Threaded scene request failed", {"error": int(load_error)})
			return null

	var load_deadline := _chart_studio_load_deadline()
	while true:
		if load_generation != chart_studio_load_generation:
			return null
		if _monotonic_seconds() >= load_deadline:
			_fail_chart_studio_load(load_generation, "Chart Studio loading timed out.", true)
			_report_runtime("chart_studio", "Threaded scene load timed out", {"deadline_seconds": _chart_studio_load_timeout_seconds()})
			return null
		if injected_stall:
			await get_tree().process_frame
			continue
		var load_status: int = ResourceLoader.load_threaded_get_status(CHART_STUDIO_SCENE_PATH)
		if load_status == ResourceLoader.THREAD_LOAD_LOADED:
			break
		if load_status == ResourceLoader.THREAD_LOAD_FAILED or load_status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_fail_chart_studio_load(load_generation, "Chart Studio could not be loaded.", false)
			_report_runtime("chart_studio", "Threaded scene load failed", {"status": load_status})
			return null
		await get_tree().process_frame

	if load_generation != chart_studio_load_generation:
		return null
	var loaded_resource: Resource = ResourceLoader.load_threaded_get(CHART_STUDIO_SCENE_PATH)
	var packed_scene: PackedScene = loaded_resource as PackedScene
	if packed_scene == null:
		_fail_chart_studio_load(load_generation, "Chart Studio resource was invalid.", false)
		_report_runtime("chart_studio", "Loaded resource was not a PackedScene")
		return null

	# Scene instantiation itself must happen on the main thread, but by this point all
	# dependencies are loaded and the route is already visible. Yield once before
	# instantiation to protect the transition completion frame.
	await get_tree().process_frame
	if load_generation != chart_studio_load_generation:
		return null
	var instance_node: Node = packed_scene.instantiate()
	if not (instance_node is Control):
		if instance_node != null:
			instance_node.queue_free()
		_fail_chart_studio_load(load_generation, "Chart Studio root was invalid.", false)
		_report_runtime("chart_studio", "Chart Studio root is not a Control")
		return null

	chart_studio_instance = instance_node as Control
	chart_studio_instance.name = "ChartEditor"
	chart_studio_instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chart_studio_screen.add_child(chart_studio_instance)
	chart_studio_screen.move_child(chart_studio_instance, chart_studio_screen.get_child_count() - 1)
	var loading_label: Label = chart_studio_screen.get_node_or_null("LoadingLabel") as Label
	if loading_label != null:
		loading_label.visible = false
	chart_studio_loading = false
	chart_studio_load_failed = false
	chart_studio_load_timed_out = false
	chart_studio_last_load_error = ""
	return chart_studio_instance

func _fail_chart_studio_load(load_generation: int, reason: String, timed_out: bool) -> void:
	if load_generation != chart_studio_load_generation:
		return
	# Invalidate every continuation belonging to this attempt before releasing
	# its waiter. ResourceLoader itself may continue, but this generation cannot.
	chart_studio_load_generation += 1
	chart_studio_loading = false
	chart_studio_load_failed = true
	chart_studio_load_timed_out = timed_out
	chart_studio_last_load_error = reason
	_update_chart_studio_loading_label("CHART STUDIO\nCOULD NOT LOAD")

func _chart_studio_load_timeout_seconds() -> float:
	return chart_studio_test_timeout_seconds if chart_studio_test_timeout_seconds > 0.0 else CHART_STUDIO_LOAD_TIMEOUT_SECONDS

func _chart_studio_load_deadline() -> float:
	return _monotonic_seconds() + _chart_studio_load_timeout_seconds()

func _monotonic_seconds() -> float:
	return float(Time.get_ticks_usec()) / 1000000.0

func _update_chart_studio_loading_label(value: String) -> void:
	var loading_label: Label = chart_studio_screen.get_node_or_null("LoadingLabel") as Label
	if loading_label != null:
		loading_label.text = value
		loading_label.visible = true

func _report_runtime(category: String, message: String, context: Dictionary = {}) -> void:
	var guard: Node = get_node_or_null("/root/RuntimeGuard")
	if guard != null and guard.has_method("report"):
		guard.call("report", category, message, context)

func launch_gameplay(request: Dictionary, visual_payload: Dictionary, transaction_id: int = 0) -> Dictionary:
	var previous_route := active_screen
	if _navigation_blocked():
		return _navigation_result("cancelled", previous_route, previous_route, "Navigation is currently blocked.", transaction_id)
	var transition: Node = get_node_or_null("/root/SceneTransition")
	if transition == null or not transition.has_method("transition_action_to_gameplay"):
		return _navigation_result("failure", previous_route, previous_route, "Gameplay transition is unavailable.", transaction_id)
	if not gameplay_screen.has_method("prepare_launch_request"):
		_notify_gameplay_launch_failure("Gameplay could not prepare this chart.")
		return _navigation_result("failure", previous_route, previous_route, "Gameplay could not prepare this chart.", transaction_id)
	var preparation_value: Variant = gameplay_screen.call("prepare_launch_request", request, true)
	var preparation: Dictionary = preparation_value as Dictionary if preparation_value is Dictionary else {}
	if not bool(preparation.get("ok", false)):
		var preparation_error := str(preparation.get("error", "Chart could not be loaded."))
		_notify_gameplay_launch_failure(preparation_error)
		return _navigation_result("failure", previous_route, previous_route, preparation_error, transaction_id)
	var prepared_request: Dictionary = preparation.get("request", {}) as Dictionary
	# Build the handoff from the exact chart object gameplay will consume, not a
	# second catalog lookup or the Song Library's pre-click snapshot.
	var resolved_chart: Dictionary = prepared_request.get("_resolved_chart", {}) as Dictionary
	var resolved_visual_payload: Dictionary = _gameplay_visual_payload(resolved_chart, prepared_request, visual_payload)
	var context: Dictionary = {
		"request": prepared_request.duplicate(true),
		"from_route": active_screen,
		"to_route": ROUTE_GAMEPLAY,
		"transaction_id": transaction_id,
	}
	var outgoing := _active_control()
	_notify_screen(outgoing, "shell_will_suspend", context)
	gameplay_activation_result = {}
	var finished_signal := Signal(transition, "transition_finished")
	transition.call(
		"transition_action_to_gameplay",
		Callable(self, "_activate_gameplay_request").bind(prepared_request, context),
		resolved_visual_payload
	)
	await finished_signal
	if str(gameplay_activation_result.get("outcome", "failure")) != "success":
		var activation_error := str(gameplay_activation_result.get("reason", "Gameplay activation failed."))
		_rollback_to_origin(outgoing, gameplay_screen, previous_route, context)
		return _navigation_result("failure", previous_route, previous_route, activation_error, transaction_id)
	return _navigation_result("success", previous_route, active_screen, "", transaction_id)

func _gameplay_visual_payload(chart: Dictionary, request: Dictionary, fallback: Dictionary) -> Dictionary:
	var payload: Dictionary = fallback.duplicate(true)
	payload["title"] = str(chart.get("title", chart.get("song_id", "UNTITLED")))
	payload["artist"] = str(chart.get("artist", "Unknown Artist"))
	var difficulty_text: String = str(chart.get("difficulty", chart.get("chart_difficulty", "NORMAL"))).to_upper()
	if request.has("practice_section_index"):
		difficulty_text = "PRACTICE"
	elif request.has("replay_data"):
		difficulty_text = "REPLAY"
	payload["difficulty"] = difficulty_text
	payload["bpm"] = float(chart.get("bpm", 0.0))
	payload["star_rating"] = int(chart.get("star_rating", 0))
	var background_session: Node = get_node_or_null("/root/BackgroundSession")
	payload["background"] = str(background_session.call("get_background_path")) if background_session != null and background_session.has_method("get_background_path") else str(fallback.get("background", ""))
	payload["random_mode"] = bool(request.get("random_mode", false))
	payload["source_path"] = str(request.get("_resolved_source_path", ""))
	payload["source_hash"] = str(request.get("_resolved_source_hash", ""))
	return payload

func _notify_gameplay_launch_failure(message: String) -> void:
	_report_runtime("gameplay_launch", message, {"route": active_screen})
	_notify_screen(_active_control(), "handle_gameplay_launch_failure", {"error": message})

func _activate_gameplay_request(request: Dictionary, context: Dictionary) -> void:
	if bool(navigation_test_failures.get(ROUTE_GAMEPLAY, false)):
		gameplay_activation_result = {"outcome": "failure", "reason": "Injected gameplay activation failure."}
		_notify_gameplay_launch_failure(str(gameplay_activation_result.get("reason", "")))
		return
	if not gameplay_screen.has_method("launch_from_app_shell") or not bool(gameplay_screen.call("launch_from_app_shell", request)):
		var activation_error := "Gameplay rejected the prepared chart."
		gameplay_activation_result = {"outcome": "failure", "reason": activation_error}
		_notify_gameplay_launch_failure(activation_error)
		return
	var outgoing: Control = _active_control()
	_set_screen_state(outgoing, false)
	_set_screen_state(gameplay_screen, true)
	active_screen = ROUTE_GAMEPLAY
	_notify_screen(outgoing, "shell_did_suspend", context)
	_notify_screen(gameplay_screen, "shell_will_resume", context)
	_notify_screen(gameplay_screen, "shell_did_resume", context)
	gameplay_activation_result = {"outcome": "success"}

func is_gameplay_transition_ready() -> bool:
	if str(gameplay_activation_result.get("outcome", "")) == "failure":
		return true
	if active_screen != ROUTE_GAMEPLAY:
		return false
	if gameplay_screen.has_method("is_gameplay_transition_ready"):
		return bool(gameplay_screen.call("is_gameplay_transition_ready"))
	return true

# Compatibility aliases retained for older callbacks. Route ownership now lives
# in show_song_library()/show_main_menu(), including gameplay cleanup.
func show_song_library_from_gameplay(selected_song_id: String = "") -> void:
	await show_song_library(selected_song_id, false)

func show_main_menu_from_gameplay(focus_index: int = 0) -> void:
	await show_main_menu(focus_index)

func _commit_route(outgoing: Control, incoming: Control, route: String, direction: float, context: Dictionary) -> void:
	if outgoing == incoming:
		_set_screen_state(incoming, true)
		active_screen = route
		return

	# Prepare only route ambience here. Catalog/records/preview remain deferred;
	# a route reveal must never wait for, or be followed by, a second image swap.
	var continuity := (outgoing == startup_screen and incoming == song_library_screen) or (outgoing == song_library_screen and incoming == startup_screen)
	var prepared: Dictionary = {}
	if continuity:
		switching = true
		prepared = await get_node("/root/BackgroundSession").call("prepare_random_background", route)
		# If ambience cannot load, retain the current cached background rather than
		# leave a late resource completion capable of altering this transaction.
		context["background_prepared"] = true
	_notify_screen(incoming, "shell_prepare_resume", context)

	if continuity:
		await _animate_menu_library_switch(outgoing, incoming, prepared)
	else:
		await _animate_switch(outgoing, incoming, direction)
	active_screen = route
	_notify_screen(outgoing, "shell_did_suspend", context)
	_notify_screen(incoming, "shell_will_resume", context)
	_notify_screen(incoming, "shell_did_resume", context)

func _rollback_to_origin(origin: Control, attempted: Control, previous_route: String, context: Dictionary) -> void:
	_set_screen_state(attempted, false)
	_set_screen_state(origin, true)
	active_screen = previous_route
	_notify_screen(origin, "shell_will_resume", context)
	_notify_screen(origin, "shell_did_resume", context)

func _navigation_result(outcome: String, previous_route: String, resulting_route: String, reason: String, transaction_id: int) -> Dictionary:
	return {
		"outcome": outcome,
		"success": outcome == "success",
		"previous_route": previous_route,
		"resulting_route": resulting_route,
		"reason": reason,
		"transaction_id": transaction_id,
	}

func set_navigation_test_failure(route: String, enabled: bool) -> void:
	if enabled:
		navigation_test_failures[route] = true
	else:
		navigation_test_failures.erase(route)

func set_chart_studio_load_timeout_for_test(seconds: float) -> void:
	chart_studio_test_timeout_seconds = seconds

func _prepare_gameplay_exit(reason: String) -> void:
	if gameplay_screen.has_method("prepare_for_shell_exit"):
		gameplay_screen.call("prepare_for_shell_exit", reason)

func _cleanup_hidden_gameplay_after_return() -> void:
	await get_tree().process_frame
	if gameplay_screen.has_method("reset_after_shell_exit_async"):
		await gameplay_screen.call("reset_after_shell_exit_async")
	elif gameplay_screen.has_method("reset_after_shell_exit"):
		gameplay_screen.call("reset_after_shell_exit")

func _notify_screen(screen: Control, method_name: String, context: Dictionary) -> void:
	if screen == chart_studio_screen and is_instance_valid(chart_studio_instance):
		if chart_studio_instance.has_method(method_name):
			chart_studio_instance.call(method_name, context)
		return
	if screen != null and screen.has_method(method_name):
		screen.call(method_name, context)

func _active_control() -> Control:
	match active_screen:
		ROUTE_SONG_LIBRARY:
			return song_library_screen
		ROUTE_GAMEPLAY:
			return gameplay_screen
		ROUTE_CHART_STUDIO:
			return chart_studio_screen
		_:
			return startup_screen

func _navigation_blocked() -> bool:
	if switching:
		return true
	var transition: Node = get_node_or_null("/root/SceneTransition")
	return transition != null and transition.has_method("is_transitioning") and bool(transition.call("is_transitioning"))

func _animate_switch(outgoing: Control, incoming: Control, direction: float) -> void:
	var perf: Node = get_node_or_null("/root/PerformanceMonitor")
	var perf_span: String = "route_%s_to_%s" % [outgoing.name, incoming.name]
	if perf != null:
		perf.call("begin_span", perf_span)
	if outgoing == incoming:
		_set_screen_state(incoming, true)
		if perf != null:
			perf.call("end_span", perf_span, {"skipped": true})
		return
	switching = true
	_set_screen_state(incoming, true)
	outgoing.process_mode = Node.PROCESS_MODE_DISABLED
	incoming.process_mode = Node.PROCESS_MODE_INHERIT
	incoming.visible = true
	incoming.modulate = Color(1.0, 1.0, 1.0, 0.0)
	incoming.position = Vector2(SCREEN_OFFSET * direction, 0.0)
	outgoing.modulate = Color.WHITE
	outgoing.position = Vector2.ZERO
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(outgoing, "modulate:a", 0.0, SCREEN_TWEEN_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(outgoing, "position:x", -SCREEN_OFFSET * direction, SCREEN_TWEEN_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(incoming, "modulate:a", 1.0, SCREEN_TWEEN_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(incoming, "position:x", 0.0, SCREEN_TWEEN_DURATION).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	await tween.finished
	outgoing.visible = false
	outgoing.modulate = Color.WHITE
	outgoing.position = Vector2.ZERO
	incoming.modulate = Color.WHITE
	incoming.position = Vector2.ZERO
	incoming.process_mode = Node.PROCESS_MODE_INHERIT
	switching = false
	if perf != null:
		perf.call("end_span", perf_span, {"duration_target_s": SCREEN_TWEEN_DURATION})

func _animate_menu_library_switch(outgoing: Control, incoming: Control, prepared: Dictionary) -> void:
	switching = true
	var perf: Node = get_node_or_null("/root/PerformanceMonitor")
	var perf_span := "route_%s_to_%s" % [outgoing.name, incoming.name]
	if perf != null:
		perf.call("begin_span", perf_span)
	var session := get_node("/root/BackgroundSession")
	var source_texture := session.call("get_texture") as Texture2D
	var destination_texture := session.call("get_texture_for_path", str(prepared.get("background", session.call("get_background_path")))) as Texture2D
	# Presentation-only layer, below both resident foregrounds. It never owns
	# background selection or route state and is freed when the tween completes.
	var backdrop := ColorRect.new()
	backdrop.name = "RouteBackdrop"
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.color = Color(0.0431373, 0.0509804, 0.0666667)
	add_child(backdrop)
	move_child(backdrop, $ScreenHost.get_index())
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var source := _transition_background_texture(backdrop, source_texture, 0.07)
	var destination := _transition_background_texture(backdrop, destination_texture, 0.0)
	var hidden_items: Dictionary = {}
	for screen: Control in [outgoing, incoming]:
		for item: CanvasItem in screen.call("shell_background_items"):
			if item != null:
				hidden_items[item] = item.visible
				item.hide()
	outgoing.process_mode = Node.PROCESS_MODE_DISABLED
	incoming.process_mode = Node.PROCESS_MODE_DISABLED
	incoming.modulate.a = 0.0
	incoming.hide()
	var background_tween := create_tween().set_parallel(true)
	background_tween.tween_property(source, "modulate:a", 0.0, SCREEN_TWEEN_DURATION)
	background_tween.tween_property(destination, "modulate:a", 0.07, SCREEN_TWEEN_DURATION)
	var exit_tween := create_tween()
	exit_tween.tween_property(outgoing, "modulate:a", 0.0, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await exit_tween.finished
	outgoing.hide()
	session.call("commit_prepared_background", prepared)
	incoming.call("shell_apply_prepared_background")
	# Binding the prepared texture may update a detail wash's visibility. Keep
	# every screen-local background out of the foreground reveal until handoff.
	for item: CanvasItem in hidden_items:
		item.hide()
	incoming.show()
	var enter_tween := create_tween()
	enter_tween.tween_property(incoming, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await enter_tween.finished
	for item: CanvasItem in hidden_items:
		item.visible = bool(hidden_items[item])
	_set_screen_state(outgoing, false)
	_set_screen_state(incoming, true)
	background_tween.kill()
	backdrop.free()
	switching = false
	if perf != null:
		perf.call("end_span", perf_span, {"duration_target_s": SCREEN_TWEEN_DURATION})

func _transition_background_texture(parent: Control, texture: Texture2D, opacity: float) -> TextureRect:
	var view := TextureRect.new()
	view.texture = texture
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	view.modulate.a = opacity
	parent.add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return view

func _set_screen_state(screen: Control, enabled: bool) -> void:
	screen.visible = enabled
	screen.modulate = Color.WHITE
	screen.position = Vector2.ZERO
	screen.process_mode = (Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED) as Node.ProcessMode
