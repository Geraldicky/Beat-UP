extends Node
class_name BeatUpNavigationController

signal route_changed(previous_route: String, current_route: String)
signal navigation_state_changed(navigating: bool)

const ROUTE_MAIN_MENU := "main_menu"
const ROUTE_SONG_LIBRARY := "song_library"
const ROUTE_GAMEPLAY := "gameplay"
const ROUTE_CHART_STUDIO := "chart_studio"

var _shell: Node = null
var _navigating: bool = false

func register_shell(shell: Node) -> void:
	if shell == null:
		return
	_shell = shell

func unregister_shell(shell: Node) -> void:
	if _shell == shell:
		_shell = null

func get_active_route() -> String:
	var shell: Node = _resolve_shell()
	if shell != null and shell.has_method("get_active_route"):
		return str(shell.call("get_active_route"))
	return ""

func is_navigating() -> bool:
	if _navigating:
		return true
	var shell: Node = _resolve_shell()
	if shell != null and shell.has_method("is_switching"):
		return bool(shell.call("is_switching"))
	var transition: Node = get_node_or_null("/root/SceneTransition")
	return transition != null and transition.has_method("is_transitioning") and bool(transition.call("is_transitioning"))

func request_main_menu(focus_index: int = 0) -> void:
	if is_navigating():
		_report_runtime("navigation", "Ignored duplicate Main Menu navigation request", {"route": get_active_route()})
		return
	var shell: Node = _resolve_shell()
	if shell != null and shell.has_method("show_main_menu"):
		var previous: String = get_active_route()
		_begin_navigation()
		shell.call("show_main_menu", focus_index)
		call_deferred("_finish_navigation_when_route", previous, ROUTE_MAIN_MENU)
		return
	_fallback_to_shell_scene()

func request_song_library(selected_song_id: String = "", refresh_data: bool = false) -> void:
	if is_navigating():
		_report_runtime("navigation", "Ignored duplicate Song Library navigation request", {"route": get_active_route()})
		return
	var shell: Node = _resolve_shell()
	if shell != null and shell.has_method("show_song_library"):
		var previous: String = get_active_route()
		_begin_navigation()
		shell.call("show_song_library", selected_song_id, refresh_data)
		call_deferred("_finish_navigation_when_route", previous, ROUTE_SONG_LIBRARY)
		return
	_fallback_to_shell_scene()

func request_chart_studio() -> void:
	if is_navigating():
		_report_runtime("navigation", "Ignored duplicate Chart Studio navigation request", {"route": get_active_route()})
		return
	var shell: Node = _resolve_shell()
	if shell != null and shell.has_method("show_chart_studio"):
		var previous: String = get_active_route()
		_begin_navigation()
		shell.call("show_chart_studio")
		call_deferred("_finish_navigation_when_route", previous, ROUTE_CHART_STUDIO)
		return
	_fallback_to_shell_scene()

func request_gameplay(request: Dictionary, visual_payload: Dictionary) -> void:
	if is_navigating():
		_report_runtime("navigation", "Ignored duplicate Gameplay navigation request", {"route": get_active_route()})
		return
	var shell: Node = _resolve_shell()
	if shell != null and shell.has_method("launch_gameplay"):
		var previous: String = get_active_route()
		_begin_navigation()
		var accepted_value: Variant = shell.call("launch_gameplay", request, visual_payload)
		if accepted_value is bool and not bool(accepted_value):
			_end_navigation(previous, previous)
			return
		# Gameplay uses SceneTransition's artwork handoff. AppShell will report the
		# new active route once the transition action activates the resident player.
		call_deferred("_finish_gameplay_navigation_when_ready", previous)
		return
	var transition: Node = get_node_or_null("/root/SceneTransition")
	if transition != null and transition.has_method("change_scene_to_gameplay"):
		get_tree().set_meta("beat_up_pending_library_launch", request)
		transition.call("change_scene_to_gameplay", "res://main.tscn", visual_payload)

func _finish_gameplay_navigation_when_ready(previous: String) -> void:
	await _finish_navigation_when_route(previous, ROUTE_GAMEPLAY)

func _finish_navigation_when_route(previous: String, expected_route: String) -> void:
	for _frame in range(180):
		await get_tree().process_frame
		if get_active_route() == expected_route:
			_end_navigation(previous, expected_route)
			return
	_report_runtime("navigation", "Navigation watchdog reached timeout", {"expected": expected_route, "actual": get_active_route()})
	_end_navigation(previous, get_active_route())

func _resolve_shell() -> Node:
	if is_instance_valid(_shell) and _shell.is_inside_tree():
		return _shell
	_shell = null
	var current_scene: Node = get_tree().current_scene
	if current_scene != null and current_scene.is_in_group("beat_up_app_shell"):
		_shell = current_scene
		return _shell
	var shells: Array = get_tree().get_nodes_in_group("beat_up_app_shell")
	if not shells.is_empty():
		_shell = shells[0] as Node
	return _shell

func _begin_navigation() -> void:
	if _navigating:
		return
	_navigating = true
	navigation_state_changed.emit(true)

func _end_navigation(previous: String, current: String) -> void:
	if _navigating:
		_navigating = false
		navigation_state_changed.emit(false)
	if previous != current and not current.is_empty():
		route_changed.emit(previous, current)

func _fallback_to_shell_scene() -> void:
	var transition: Node = get_node_or_null("/root/SceneTransition")
	if transition != null and transition.has_method("change_scene_quick"):
		transition.call("change_scene_quick", "res://scenes/app_shell.tscn")

func _report_runtime(category: String, message: String, context: Dictionary = {}) -> void:
	var guard: Node = get_node_or_null("/root/RuntimeGuard")
	if guard != null and guard.has_method("report"):
		guard.call("report", category, message, context)
