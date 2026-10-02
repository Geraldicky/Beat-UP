extends Control
class_name BeatUpAppShell

const SCREEN_TWEEN_DURATION := 0.20
const SCREEN_OFFSET := 24.0
const ROUTE_MAIN_MENU := "main_menu"
const ROUTE_SONG_LIBRARY := "song_library"
const ROUTE_GAMEPLAY := "gameplay"
const ROUTE_CHART_STUDIO := "chart_studio"
const CHART_STUDIO_SCENE_PATH := "res://scenes/chart_editor.tscn"

@onready var startup_screen: Control = $ScreenHost/StartupScreen
@onready var song_library_screen: Control = $ScreenHost/SongLibraryScreen
@onready var gameplay_screen: Control = $ScreenHost/GameplayScreen
@onready var chart_studio_screen: Control = $ScreenHost/ChartStudioScreen

var active_screen: String = ROUTE_MAIN_MENU
var switching: bool = false
var chart_studio_instance: Control = null
var chart_studio_loading: bool = false
var chart_studio_load_failed: bool = false
var chart_studio_music_paused_by_shell: bool = false

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

func show_song_library(selected_song_id: String = "", refresh_data: bool = false) -> void:
	if _navigation_blocked():
		return
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
	}
	if active_screen == ROUTE_SONG_LIBRARY:
		_notify_screen(song_library_screen, "shell_will_resume", context)
		_notify_screen(song_library_screen, "shell_did_resume", context)
		return
	if active_screen == ROUTE_GAMEPLAY:
		_prepare_gameplay_exit("song_library")
	await _switch_route(song_library_screen, ROUTE_SONG_LIBRARY, 1.0 if active_screen == ROUTE_MAIN_MENU else -1.0, context)
	if str(context.get("from_route", "")) == ROUTE_CHART_STUDIO:
		_restore_music_after_chart_studio()
	if context.get("from_route", "") == ROUTE_GAMEPLAY:
		call_deferred("_cleanup_hidden_gameplay_after_return")

func show_main_menu(focus_index: int = 0) -> void:
	if _navigation_blocked():
		return
	var context: Dictionary = {
		"focus_index": focus_index,
		"from_route": active_screen,
		"to_route": ROUTE_MAIN_MENU,
	}
	if active_screen == ROUTE_MAIN_MENU:
		_notify_screen(startup_screen, "shell_will_resume", context)
		_notify_screen(startup_screen, "shell_did_resume", context)
		return
	if active_screen == ROUTE_GAMEPLAY:
		_prepare_gameplay_exit("main_menu")
	await _switch_route(startup_screen, ROUTE_MAIN_MENU, -1.0, context)
	if str(context.get("from_route", "")) == ROUTE_CHART_STUDIO:
		_restore_music_after_chart_studio()
	if context.get("from_route", "") == ROUTE_GAMEPLAY:
		call_deferred("_cleanup_hidden_gameplay_after_return")

func show_chart_studio() -> void:
	if _navigation_blocked():
		return
	var context: Dictionary = {
		"from_route": active_screen,
		"to_route": ROUTE_CHART_STUDIO,
	}
	if active_screen == ROUTE_CHART_STUDIO:
		if chart_studio_instance != null:
			_notify_screen(chart_studio_screen, "shell_will_resume", context)
			_notify_screen(chart_studio_screen, "shell_did_resume", context)
		elif not chart_studio_loading:
			call_deferred("_load_chart_studio_after_route", context)
		return
	_pause_music_for_chart_studio()

	# Enter the lightweight resident shell first. The editor scene is requested only
	# after the route tween has finished so scene/resource construction never blocks
	# the Main Menu frame that starts navigation.
	await _switch_route(chart_studio_screen, ROUTE_CHART_STUDIO, 1.0, context)
	call_deferred("_load_chart_studio_after_route", context)

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

func _load_chart_studio_after_route(context: Dictionary) -> void:
	if active_screen != ROUTE_CHART_STUDIO:
		return
	var editor: Control = await _ensure_chart_studio_loaded()
	if editor == null or active_screen != ROUTE_CHART_STUDIO:
		return
	_notify_screen(chart_studio_screen, "shell_will_resume", context)
	_notify_screen(chart_studio_screen, "shell_did_resume", context)

func _ensure_chart_studio_loaded() -> Control:
	if is_instance_valid(chart_studio_instance):
		return chart_studio_instance
	if chart_studio_load_failed:
		_update_chart_studio_loading_label("CHART STUDIO\nCOULD NOT LOAD")
		return null
	if chart_studio_loading:
		while chart_studio_loading:
			await get_tree().process_frame
		return chart_studio_instance

	chart_studio_loading = true
	_update_chart_studio_loading_label("CHART STUDIO")
	var load_error: Error = ResourceLoader.load_threaded_request(CHART_STUDIO_SCENE_PATH, "PackedScene", false)
	if load_error != OK:
		chart_studio_loading = false
		chart_studio_load_failed = true
		_update_chart_studio_loading_label("CHART STUDIO\nCOULD NOT LOAD")
		_report_runtime("chart_studio", "Threaded scene request failed", {"error": int(load_error)})
		return null

	while true:
		var load_status: int = ResourceLoader.load_threaded_get_status(CHART_STUDIO_SCENE_PATH)
		if load_status == ResourceLoader.THREAD_LOAD_LOADED:
			break
		if load_status == ResourceLoader.THREAD_LOAD_FAILED or load_status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			chart_studio_loading = false
			chart_studio_load_failed = true
			_update_chart_studio_loading_label("CHART STUDIO\nCOULD NOT LOAD")
			_report_runtime("chart_studio", "Threaded scene load failed", {"status": load_status})
			return null
		await get_tree().process_frame

	var loaded_resource: Resource = ResourceLoader.load_threaded_get(CHART_STUDIO_SCENE_PATH)
	var packed_scene: PackedScene = loaded_resource as PackedScene
	if packed_scene == null:
		chart_studio_loading = false
		chart_studio_load_failed = true
		_update_chart_studio_loading_label("CHART STUDIO\nCOULD NOT LOAD")
		_report_runtime("chart_studio", "Loaded resource was not a PackedScene")
		return null

	# Scene instantiation itself must happen on the main thread, but by this point all
	# dependencies are loaded and the route is already visible. Yield once before
	# instantiation to protect the transition completion frame.
	await get_tree().process_frame
	var instance_node: Node = packed_scene.instantiate()
	if not (instance_node is Control):
		if instance_node != null:
			instance_node.queue_free()
		chart_studio_loading = false
		chart_studio_load_failed = true
		_update_chart_studio_loading_label("CHART STUDIO\nCOULD NOT LOAD")
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
	return chart_studio_instance

func _update_chart_studio_loading_label(value: String) -> void:
	var loading_label: Label = chart_studio_screen.get_node_or_null("LoadingLabel") as Label
	if loading_label != null:
		loading_label.text = value
		loading_label.visible = true

func _report_runtime(category: String, message: String, context: Dictionary = {}) -> void:
	var guard: Node = get_node_or_null("/root/RuntimeGuard")
	if guard != null and guard.has_method("report"):
		guard.call("report", category, message, context)

func launch_gameplay(request: Dictionary, visual_payload: Dictionary) -> void:
	if _navigation_blocked():
		return
	var transition: Node = get_node_or_null("/root/SceneTransition")
	if transition == null or not transition.has_method("transition_action_to_gameplay"):
		return
	var context: Dictionary = {
		"request": request.duplicate(true),
		"from_route": active_screen,
		"to_route": ROUTE_GAMEPLAY,
	}
	_notify_screen(_active_control(), "shell_will_suspend", context)
	transition.call(
		"transition_action_to_gameplay",
		Callable(self, "_activate_gameplay_request").bind(request, context),
		visual_payload
	)

func _activate_gameplay_request(request: Dictionary, context: Dictionary) -> void:
	var outgoing: Control = _active_control()
	_set_screen_state(outgoing, false)
	_set_screen_state(gameplay_screen, true)
	active_screen = ROUTE_GAMEPLAY
	_notify_screen(outgoing, "shell_did_suspend", context)
	_notify_screen(gameplay_screen, "shell_will_resume", context)
	if gameplay_screen.has_method("launch_from_app_shell"):
		gameplay_screen.call("launch_from_app_shell", request)
	_notify_screen(gameplay_screen, "shell_did_resume", context)

func is_gameplay_transition_ready() -> bool:
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

func _switch_route(incoming: Control, route: String, direction: float, context: Dictionary) -> void:
	var outgoing: Control = _active_control()
	if outgoing == incoming:
		_set_screen_state(incoming, true)
		active_screen = route
		return
	_notify_screen(outgoing, "shell_will_suspend", context)

	# v17.4.49: Song Library is a resident screen. Do not run selection, record
	# refresh, artwork loading, or preview work before its route tween has had a
	# chance to render. This mirrors osu!'s separation between immediate screen
	# navigation and deferred beatmap/media work.
	var defer_library_resume: bool = route == ROUTE_SONG_LIBRARY
	if defer_library_resume:
		_notify_screen(incoming, "shell_prepare_resume", context)
	else:
		_notify_screen(incoming, "shell_will_resume", context)

	await _animate_switch(outgoing, incoming, direction)
	active_screen = route
	_notify_screen(outgoing, "shell_did_suspend", context)
	if defer_library_resume:
		_notify_screen(incoming, "shell_will_resume", context)
	_notify_screen(incoming, "shell_did_resume", context)

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

func _set_screen_state(screen: Control, enabled: bool) -> void:
	screen.visible = enabled
	screen.modulate = Color.WHITE
	screen.position = Vector2.ZERO
	screen.process_mode = (Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED) as Node.ProcessMode
