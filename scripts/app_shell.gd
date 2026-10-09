extends Control
class_name BeatUpAppShell

const SCREEN_TWEEN_DURATION := 0.20
const SCREEN_OFFSET := 24.0
const MENU_EXIT_DURATION := 0.14
const MENU_ENTER_DURATION := 0.26
const ROUTE_MAIN_MENU := "main_menu"
const ROUTE_SONG_LIBRARY := "song_library"
const ROUTE_GAMEPLAY := "gameplay"

@onready var startup_screen: Control = $ScreenHost/StartupScreen
@onready var song_library_screen: Control = $ScreenHost/SongLibraryScreen
@onready var gameplay_screen: Control = $ScreenHost/GameplayScreen

var active_screen: String = ROUTE_MAIN_MENU
var switching: bool = false
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
	startup_screen.position = Vector2.ZERO
	song_library_screen.position = Vector2.ZERO
	gameplay_screen.position = Vector2.ZERO

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
	if context.get("from_route", "") == ROUTE_GAMEPLAY:
		call_deferred("_cleanup_hidden_gameplay_after_return")
	return _navigation_result("success", previous_route, active_screen, "", transaction_id)

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
	if not gameplay_screen.has_method("prepare_launch_request_async"):
		_notify_gameplay_launch_failure("Gameplay could not prepare this chart.")
		return _navigation_result("failure", previous_route, previous_route, "Gameplay could not prepare this chart.", transaction_id)
	await transition.call("begin_gameplay_preparation", visual_payload)
	var preparation_value: Variant = await gameplay_screen.call("prepare_launch_request_async", request)
	var preparation: Dictionary = preparation_value as Dictionary if preparation_value is Dictionary else {}
	if not bool(preparation.get("ok", false)):
		transition.call("cancel_gameplay_preparation")
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
	payload["song_id"] = str(chart.get("song_id", request.get("song_id", "")))
	payload["title"] = str(chart.get("title", chart.get("song_id", "UNTITLED")))
	payload["artist"] = str(chart.get("artist", "Unknown Artist"))
	var difficulty_text: String = str(chart.get("difficulty", chart.get("chart_difficulty", "NORMAL"))).to_upper()
	if request.has("replay_data"):
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
	if screen != null and screen.has_method(method_name):
		screen.call(method_name, context)

func _active_control() -> Control:
	match active_screen:
		ROUTE_SONG_LIBRARY:
			return song_library_screen
		ROUTE_GAMEPLAY:
			return gameplay_screen
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
	# Keep one atmosphere under both foregrounds for the entire handoff. Texture
	# selection remains transactional metadata, but old pool art is not rendered.
	source.hide()
	destination.hide()
	preload("res://scripts/ui/procedural_background.gd").install(backdrop, "menu")
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
	background_tween.tween_property(source, "modulate:a", 0.0, MENU_EXIT_DURATION + MENU_ENTER_DURATION)
	background_tween.tween_property(destination, "modulate:a", 0.07, MENU_EXIT_DURATION + MENU_ENTER_DURATION)
	var exit_tween := create_tween()
	exit_tween.set_parallel(true)
	exit_tween.tween_property(outgoing, "modulate:a", 0.0, MENU_EXIT_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	exit_tween.tween_property(outgoing, "position:x", -18.0 if incoming == song_library_screen else 18.0, MENU_EXIT_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await exit_tween.finished
	outgoing.hide()
	session.call("commit_prepared_background", prepared)
	incoming.call("shell_apply_prepared_background")
	# Binding the prepared texture may update a detail wash's visibility. Keep
	# every screen-local background out of the foreground reveal until handoff.
	for item: CanvasItem in hidden_items:
		item.hide()
	incoming.show()
	incoming.position.x = 28.0 if incoming == song_library_screen else -28.0
	var enter_tween := create_tween()
	enter_tween.set_parallel(true)
	enter_tween.tween_property(incoming, "modulate:a", 1.0, MENU_ENTER_DURATION).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	enter_tween.tween_property(incoming, "position:x", 0.0, MENU_ENTER_DURATION).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
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
