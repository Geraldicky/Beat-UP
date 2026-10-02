extends Control
const ScoreIdentity = preload("res://scripts/score_identity.gd")

const ReliableJsonStoreScript = preload("res://scripts/reliable_json_store.gd")
const BEST_STATS_SAVE_PATH := "user://best_level_stats.json"
const PENDING_LIBRARY_LAUNCH_META := "beat_up_pending_library_launch"
const RETURN_TO_MENU_META := "beat_up_return_to_main_menu"
const RETURN_TO_MENU_FOCUS_META := "beat_up_return_main_menu_focus"

@onready var level_catalog: Node = $LevelCatalog
@onready var song_select: Control = $SongSelect

var levels: Array = []
var best_stats_store: Dictionary = {}
var action_locked: bool = false
var _best_stats_dirty: bool = false

func _ready() -> void:
	_connect_library_signals()
	_reload_library()
	call_deferred("_focus_library")

func _connect_library_signals() -> void:
	_connect_signal("play_requested", Callable(self, "_on_play_requested"))
	_connect_signal("practice_requested", Callable(self, "_on_practice_requested"))
	_connect_signal("replay_requested", Callable(self, "_on_replay_requested"))
	_connect_signal("back_requested", Callable(self, "_on_back_requested"))
	_connect_signal("chart_editor_requested", Callable(self, "_on_chart_editor_requested"))
	_connect_signal("import_charts_requested", Callable(self, "_on_import_charts_requested"))
	_connect_signal("refresh_requested", Callable(self, "_on_refresh_requested"))

func _connect_signal(signal_name: StringName, callback: Callable) -> void:
	if not song_select.has_signal(signal_name):
		push_error("Song Library is missing signal: %s" % signal_name)
		return
	if not song_select.is_connected(signal_name, callback):
		song_select.connect(signal_name, callback)

func _reload_library() -> void:
	var loaded_levels: Variant = level_catalog.call("load_all", true)
	levels = loaded_levels as Array if loaded_levels is Array else []
	var load_result: Dictionary = ReliableJsonStoreScript.load_dictionary(BEST_STATS_SAVE_PATH)
	var loaded_data: Variant = load_result.get("data", {})
	best_stats_store = loaded_data as Dictionary if loaded_data is Dictionary else {}
	var migrated := ScoreIdentity.migrate_legacy(best_stats_store)
	migrated = ScoreIdentity.migrate_v185_score_scale(best_stats_store, levels) or migrated
	if migrated:
		ReliableJsonStoreScript.save_dictionary_atomic(BEST_STATS_SAVE_PATH, best_stats_store)
	song_select.call("set_catalog", levels)
	song_select.call("set_best_stats_store", best_stats_store)
	_best_stats_dirty = false

func receive_best_stats(store: Dictionary) -> void:
	# Snapshot committed results immediately; defer UI work while off screen.
	best_stats_store = store.duplicate(true)
	_best_stats_dirty = true
	if is_visible_in_tree() and process_mode != Node.PROCESS_MODE_DISABLED:
		_apply_pending_best_stats()

func handle_gameplay_launch_failure(context: Dictionary) -> void:
	action_locked = false
	var message: String = str(context.get("error", "CHART COULD NOT BE LOADED"))
	if song_select.has_method("show_playback_error"):
		song_select.call("show_playback_error", message)

func _apply_pending_best_stats() -> void:
	if not _best_stats_dirty:
		return
	_best_stats_dirty = false
	song_select.call("set_best_stats_store", best_stats_store)

func _focus_library() -> void:
	if song_select.has_method("focus_current_selection"):
		song_select.call("focus_current_selection")

func get_audio_handoff() -> Dictionary:
	if song_select == null or not song_select.has_method("get_audio_handoff"):
		return {}
	var handoff_value: Variant = song_select.call("get_audio_handoff")
	return (handoff_value as Dictionary).duplicate(true) if handoff_value is Dictionary else {}

func _on_play_requested(song_id: String, difficulty_id: String, random_mode: bool) -> void:
	if action_locked or _navigation_busy():
		return
	action_locked = true
	var launch_request: Dictionary = {
		"song_id": song_id,
		"difficulty_id": difficulty_id,
		"random_mode": random_mode,
	}
	var level: Dictionary = _find_level(song_id, difficulty_id)
	var representative: Dictionary = _representative(song_id)
	var canonical: Dictionary = _get_global_song_state()
	var canonical_matches: bool = str(canonical.get("song_id", "")) == song_id
	var visual_payload: Dictionary = {
		"title": str(canonical.get("title", level.get("title", representative.get("title", song_id.replace("_", " "))))) if canonical_matches else str(level.get("title", representative.get("title", song_id.replace("_", " ")))),
		"artist": str(canonical.get("artist", level.get("artist", representative.get("artist", "Unknown Artist")))) if canonical_matches else str(level.get("artist", representative.get("artist", "Unknown Artist"))),
		"difficulty": str(level.get("difficulty", difficulty_id)).to_upper(),
		"bpm": float(canonical.get("bpm", level.get("bpm", representative.get("bpm", 0.0)))) if canonical_matches else float(level.get("bpm", representative.get("bpm", 0.0))),
		"star_rating": int(level.get("star_rating", 0)),
		"background": _get_global_background_path(str(level.get("background", representative.get("background", "")))) if canonical_matches else str(level.get("background", representative.get("background", ""))),
		"random_mode": random_mode,
	}
	# v17.4.24: gameplay is pre-instantiated inside AppShell. The selected artwork
	# still owns the handoff, but no PackedScene swap occurs when PLAY is pressed.
	var navigation: Node = get_node_or_null("/root/NavigationController")
	if navigation != null and navigation.has_method("request_gameplay"):
		_report_runtime("song_library", "Launching gameplay", launch_request)
		navigation.call("request_gameplay", launch_request, visual_payload)
		return
	# Compatibility fallback for running SongLibrary as a standalone scene.
	get_tree().set_meta(PENDING_LIBRARY_LAUNCH_META, launch_request)
	SceneTransition.change_scene_to_gameplay("res://main.tscn", visual_payload)

func _on_practice_requested(song_id: String, difficulty_id: String, random_mode: bool, section_index: int) -> void:
	_launch_v18_request(song_id, difficulty_id, random_mode, {"practice_section_index": section_index})

func _on_replay_requested(song_id: String, difficulty_id: String, random_mode: bool, replay_data: Dictionary) -> void:
	_launch_v18_request(song_id, difficulty_id, random_mode, {"replay_data": replay_data.duplicate(true)})

func _launch_v18_request(song_id: String, difficulty_id: String, random_mode: bool, extra: Dictionary) -> void:
	if action_locked or _navigation_busy():
		return
	action_locked = true
	var launch_request: Dictionary = {
		"song_id": song_id,
		"difficulty_id": difficulty_id,
		"random_mode": random_mode,
	}
	for key: Variant in extra.keys():
		launch_request[key] = extra[key]
	var level: Dictionary = _find_level(song_id, difficulty_id)
	var representative: Dictionary = _representative(song_id)
	var canonical: Dictionary = _get_global_song_state()
	var canonical_matches: bool = str(canonical.get("song_id", "")) == song_id
	var mode_suffix: String = "PRACTICE" if extra.has("practice_section_index") else ("REPLAY" if extra.has("replay_data") else str(level.get("difficulty", difficulty_id)).to_upper())
	var visual_payload: Dictionary = {
		"title": str(canonical.get("title", level.get("title", representative.get("title", song_id.replace("_", " "))))) if canonical_matches else str(level.get("title", representative.get("title", song_id.replace("_", " ")))),
		"artist": str(canonical.get("artist", level.get("artist", representative.get("artist", "Unknown Artist")))) if canonical_matches else str(level.get("artist", representative.get("artist", "Unknown Artist"))),
		"difficulty": mode_suffix,
		"bpm": float(canonical.get("bpm", level.get("bpm", representative.get("bpm", 0.0)))) if canonical_matches else float(level.get("bpm", representative.get("bpm", 0.0))),
		"star_rating": int(level.get("star_rating", 0)),
		"background": _get_global_background_path(str(level.get("background", representative.get("background", "")))) if canonical_matches else str(level.get("background", representative.get("background", ""))),
		"random_mode": random_mode,
	}
	var navigation: Node = get_node_or_null("/root/NavigationController")
	if navigation != null and navigation.has_method("request_gameplay"):
		_report_runtime("song_library", "Launching v18 gameplay mode", launch_request)
		navigation.call("request_gameplay", launch_request, visual_payload)
		return
	get_tree().set_meta(PENDING_LIBRARY_LAUNCH_META, launch_request)
	SceneTransition.change_scene_to_gameplay("res://main.tscn", visual_payload)

func _get_global_song_state() -> Dictionary:
	var selection_state: Node = get_node_or_null("/root/SongSelectionState")
	if selection_state != null and selection_state.has_method("get_state"):
		var value: Variant = selection_state.call("get_state")
		if value is Dictionary:
			return (value as Dictionary).duplicate(true)
	return {}

func _get_global_background_path(fallback: String = "") -> String:
	var background_session: Node = get_node_or_null("/root/BackgroundSession")
	if background_session != null and background_session.has_method("get_background_path"):
		var path: String = str(background_session.call("get_background_path"))
		if not path.is_empty():
			return path
	return fallback

func _on_back_requested() -> void:
	if action_locked or _navigation_busy():
		return
	action_locked = true
	get_tree().set_meta(RETURN_TO_MENU_META, true)
	get_tree().set_meta(RETURN_TO_MENU_FOCUS_META, 0)
	var navigation: Node = get_node_or_null("/root/NavigationController")
	if navigation != null and navigation.has_method("request_main_menu"):
		navigation.call("request_main_menu", 0)
		return
	SceneTransition.change_scene_quick("res://scenes/app_shell.tscn")

func _on_chart_editor_requested() -> void:
	SceneTransition.change_scene_quick("res://scenes/chart_editor.tscn")

func _on_refresh_requested() -> void:
	_reload_library()

func _on_import_charts_requested(paths: PackedStringArray) -> void:
	var raw_report: Variant = level_catalog.call("import_chart_files", paths)
	var report: Dictionary = raw_report as Dictionary if raw_report is Dictionary else {}
	_reload_library()
	var imported_ids: Array = report.get("song_ids", [])
	if not imported_ids.is_empty():
		song_select.call("set_selected_song", str(imported_ids[0]))
	var imported_count: int = int(report.get("imported", 0))
	var failures: Array = report.get("failed", []) as Array
	var summary := "IMPORTED %d/%d CHARTS OR PACKS" % [imported_count, paths.size()]
	if not failures.is_empty():
		summary += " · %s" % "; ".join(failures)
	if song_select.has_method("show_creator_status"):
		song_select.call("show_creator_status", summary, imported_count <= 0)

func _find_level(song_id: String, difficulty_id: String) -> Dictionary:
	for raw_level in levels:
		if not (raw_level is Dictionary):
			continue
		var data: Dictionary = raw_level
		if str(data.get("song_id", data.get("id", ""))) == song_id and str(data.get("chart_difficulty", data.get("difficulty", ""))).to_lower() == difficulty_id.to_lower():
			return data
	return {}

func _representative(song_id: String) -> Dictionary:
	for raw_level in levels:
		if not (raw_level is Dictionary):
			continue
		var data: Dictionary = raw_level
		if str(data.get("song_id", data.get("id", ""))) == song_id:
			return data
	return {}

func activate_from_shell(selected_song_id: String = "", refresh_data: bool = false) -> void:
	# v17.4.24.1: do not force _apply_filters()/row reconstruction when returning
	# to the same selection. The persistent Song Library should simply reveal its
	# already-built UI.
	if not selected_song_id.is_empty() and song_select.has_method("set_selected_song"):
		var current_song_id: String = ""
		if song_select.has_method("get_selected_song_id"):
			current_song_id = str(song_select.call("get_selected_song_id"))
		if current_song_id != selected_song_id:
			song_select.call("set_selected_song", selected_song_id)
	if refresh_data:
		call_deferred("refresh_from_shell_deferred")
	call_deferred("_focus_library")

func refresh_from_shell_deferred() -> void:
	_reload_library()
	call_deferred("_focus_library")



# v17.4.49 resident-screen lifecycle. `shell_prepare_resume` is intentionally
# constant-time and is the only hook allowed before the route tween starts.
func shell_prepare_resume(_context: Dictionary) -> void:
	action_locked = false

func shell_will_resume(context: Dictionary) -> void:
	action_locked = false
	var selected_song_id: String = str(context.get("selected_song_id", ""))
	activate_from_shell(selected_song_id, false)
	# Progress/record refresh is safe now because AppShell invokes this hook after
	# the route animation for Song Library has completed.
	_apply_pending_best_stats()

func shell_did_resume(context: Dictionary) -> void:
	if song_select != null and song_select.has_method("shell_did_resume"):
		song_select.call("shell_did_resume", context)
	if bool(context.get("refresh_data", false)):
		call_deferred("refresh_from_shell_deferred")
	else:
		call_deferred("_focus_library")

func shell_will_suspend(context: Dictionary) -> void:
	if song_select != null and song_select.has_method("shell_will_suspend"):
		song_select.call("shell_will_suspend", context)
	if song_select != null and song_select.has_method("remember_current_selection"):
		song_select.call("remember_current_selection")

func shell_did_suspend(_context: Dictionary) -> void:
	pass

func _navigation_busy() -> bool:
	var navigation: Node = get_node_or_null("/root/NavigationController")
	return navigation != null and navigation.has_method("is_navigating") and bool(navigation.call("is_navigating"))

func _report_runtime(category: String, message: String, context: Dictionary = {}) -> void:
	var guard: Node = get_node_or_null("/root/RuntimeGuard")
	if guard != null and guard.has_method("report"):
		guard.call("report", category, message, context)
