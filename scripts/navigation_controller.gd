extends Node
class_name BeatUpNavigationController

signal route_changed(previous_route: String, current_route: String)
signal navigation_state_changed(navigating: bool)
signal navigation_completed(result: Dictionary)

const ROUTE_MAIN_MENU := "main_menu"
const ROUTE_SONG_LIBRARY := "song_library"
const ROUTE_GAMEPLAY := "gameplay"

var _shell: Node = null
var _navigating: bool = false
var _next_transaction_id: int = 1
var _active_transaction_id: int = 0

func register_shell(shell: Node) -> void:
	if shell == null:
		return
	_shell = shell

func unregister_shell(shell: Node) -> void:
	if _shell == shell:
		_shell = null

func has_registered_shell() -> bool:
	return _resolve_shell() != null

func get_active_route() -> String:
	var shell: Node = _resolve_shell()
	if shell != null and shell.has_method("get_active_route"):
		return str(shell.call("get_active_route"))
	return ""

func is_navigating() -> bool:
	if _navigating:
		return true
	var shell: Node = _resolve_shell()
	if shell != null and shell.has_method("is_switching") and bool(shell.call("is_switching")):
		return true
	var transition: Node = get_node_or_null("/root/SceneTransition")
	return transition != null and transition.has_method("is_transitioning") and bool(transition.call("is_transitioning"))

func request_main_menu(focus_index: int = 0) -> Dictionary:
	return await _request_shell_navigation("show_main_menu", [focus_index], ROUTE_MAIN_MENU)

func request_song_library(selected_song_id: String = "", refresh_data: bool = false) -> Dictionary:
	return await _request_shell_navigation("show_song_library", [selected_song_id, refresh_data], ROUTE_SONG_LIBRARY)

func request_gameplay(request: Dictionary, visual_payload: Dictionary) -> Dictionary:
	return await _request_shell_navigation("launch_gameplay", [request, visual_payload], ROUTE_GAMEPLAY)

func _request_shell_navigation(method_name: String, arguments: Array, requested_route: String) -> Dictionary:
	var transaction_id := _allocate_transaction_id()
	var previous := get_active_route()
	if is_navigating():
		var cancelled := _result("cancelled", previous, previous, "Navigation is already active.", transaction_id)
		_report_runtime("navigation", "Rejected duplicate navigation request", {
			"requested_route": requested_route,
			"active_route": previous,
			"transaction_id": transaction_id,
		})
		navigation_completed.emit(cancelled.duplicate(true))
		return cancelled

	var shell := _resolve_shell()
	if shell == null or not shell.has_method(method_name):
		var unavailable := _result("failure", previous, previous, "No registered AppShell can handle this route.", transaction_id)
		navigation_completed.emit(unavailable.duplicate(true))
		_fallback_to_shell_scene()
		return unavailable

	_begin_navigation(transaction_id)
	var call_arguments := arguments.duplicate()
	call_arguments.append(transaction_id)
	var raw_result: Variant = await shell.callv(method_name, call_arguments)
	var result := _normalize_shell_result(raw_result, previous, transaction_id)
	return _finish_navigation(transaction_id, result)

func _allocate_transaction_id() -> int:
	var transaction_id := _next_transaction_id
	_next_transaction_id += 1
	return transaction_id

func _begin_navigation(transaction_id: int) -> void:
	_navigating = true
	_active_transaction_id = transaction_id
	navigation_state_changed.emit(true)

func _finish_navigation(transaction_id: int, result: Dictionary) -> Dictionary:
	if not _navigating or transaction_id != _active_transaction_id:
		var stale := _result(
			"cancelled",
			str(result.get("previous_route", get_active_route())),
			get_active_route(),
			"Navigation completion was stale.",
			transaction_id
		)
		navigation_completed.emit(stale.duplicate(true))
		return stale

	_navigating = false
	_active_transaction_id = 0
	navigation_state_changed.emit(false)
	var previous := str(result.get("previous_route", ""))
	var current := str(result.get("resulting_route", previous))
	if str(result.get("outcome", "failure")) == "success" and previous != current and not current.is_empty():
		route_changed.emit(previous, current)
	navigation_completed.emit(result.duplicate(true))
	return result

func _normalize_shell_result(raw_result: Variant, previous: String, transaction_id: int) -> Dictionary:
	if not (raw_result is Dictionary):
		return _result("failure", previous, get_active_route(), "AppShell returned no navigation result.", transaction_id)
	var result := (raw_result as Dictionary).duplicate(true)
	result["transaction_id"] = transaction_id
	if not result.has("outcome"):
		result["outcome"] = "success" if bool(result.get("success", false)) else "failure"
	result["success"] = str(result.get("outcome", "failure")) == "success"
	result["previous_route"] = str(result.get("previous_route", previous))
	result["resulting_route"] = str(result.get("resulting_route", get_active_route()))
	result["reason"] = str(result.get("reason", ""))
	return result

func _result(outcome: String, previous: String, current: String, reason: String, transaction_id: int) -> Dictionary:
	return {
		"outcome": outcome,
		"success": outcome == "success",
		"previous_route": previous,
		"resulting_route": current,
		"reason": reason,
		"transaction_id": transaction_id,
	}

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

func _fallback_to_shell_scene() -> void:
	var transition: Node = get_node_or_null("/root/SceneTransition")
	if transition != null and transition.has_method("change_scene_quick"):
		transition.call("change_scene_quick", "res://scenes/app_shell.tscn")

func _report_runtime(category: String, message: String, context: Dictionary = {}) -> void:
	var guard: Node = get_node_or_null("/root/RuntimeGuard")
	if guard != null and guard.has_method("report"):
		guard.call("report", category, message, context)
