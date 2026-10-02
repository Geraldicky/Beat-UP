extends SceneTree

const LevelCatalogScript = preload("res://scripts/level_catalog.gd")
const ReliableJsonStoreScript = preload("res://scripts/reliable_json_store.gd")
const AppShellScript = preload("res://scripts/app_shell.gd")

const SONG_ID := "bad_apple"
const BUNDLED_NORMAL := "res://charts/bad_apple/normal.json"
const USER_SONG_DIR := "user://songs/bad_apple"
const USER_OVERRIDE := "user://songs/bad_apple/normal.json"
const EXPORT_DIR := "user://chart_exports"
const STUDIO_EXPORT := "user://chart_exports/bad_apple_normal.json"

var failures := 0

class RejectGameplayStub:
	extends Control
	signal best_stats_changed(store: Dictionary)

	func prepare_launch_request(_request: Dictionary, _force_refresh: bool = true) -> Dictionary:
		return {"ok": false, "error": "Audio missing. Install or re-import the matching audio file."}

class LibraryStub:
	extends Control
	var action_locked := true

	func receive_best_stats(_store: Dictionary) -> void:
		pass

	func handle_gameplay_launch_failure(_context: Dictionary) -> void:
		action_locked = false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_cleanup_fixtures()
	var bundled_chart: Dictionary = _read_chart(BUNDLED_NORMAL)
	_check(not bundled_chart.is_empty(), "Bundled NORMAL fixture could not be read.")
	if bundled_chart.is_empty():
		_finish()
		return

	var catalog: LevelCatalog = LevelCatalogScript.new()
	root.add_child(catalog)
	var bundled: Dictionary = catalog.resolve_playable(SONG_ID, "normal", true)
	_check(bool(bundled.get("ok", false)), "Bundled chart did not resolve.")
	_check(str(bundled.get("source_kind", "")) == "bundled", "Bundled chart reported the wrong source kind.")
	_check(str(bundled.get("source_path", "")) == BUNDLED_NORMAL, "Bundled chart reported the wrong source path.")

	# This is Chart Studio's packaged-build fallback path. A forced Play refresh
	# must observe edits made after the gameplay catalog was already cached.
	var studio_v1: Dictionary = bundled_chart.duplicate(true)
	studio_v1["title"] = "STUDIO REVISION ONE"
	studio_v1["chart_offset_ms"] = 11.0
	_check(_write_chart(STUDIO_EXPORT, studio_v1), "Could not write the first Chart Studio export fixture.")
	var first_export: Dictionary = catalog.resolve_playable(SONG_ID, "normal", true)
	_check(str(first_export.get("source_kind", "")) == "user_exports", "Chart Studio export did not override the bundled chart.")
	_check(str((first_export.get("chart", {}) as Dictionary).get("title", "")) == "STUDIO REVISION ONE", "First Chart Studio export was not resolved.")

	var studio_v2: Dictionary = bundled_chart.duplicate(true)
	studio_v2["title"] = "STUDIO REVISION TWO"
	studio_v2["chart_offset_ms"] = 22.0
	_check(_write_chart(STUDIO_EXPORT, studio_v2), "Could not write the second Chart Studio export fixture.")
	var stale_export: Dictionary = catalog.resolve_playable(SONG_ID, "normal", false)
	_check(str((stale_export.get("chart", {}) as Dictionary).get("title", "")) == "STUDIO REVISION ONE", "The test did not establish a cached pre-save catalog.")
	var latest_export: Dictionary = catalog.resolve_playable(SONG_ID, "normal", true)
	_check(str((latest_export.get("chart", {}) as Dictionary).get("title", "")) == "STUDIO REVISION TWO", "Forced Play refresh did not resolve the latest Chart Studio save.")

	var user_override: Dictionary = bundled_chart.duplicate(true)
	user_override["title"] = "USER SONG OVERRIDE"
	user_override["chart_offset_ms"] = 33.0
	_check(_write_chart(USER_OVERRIDE, user_override), "Could not write the user-song override fixture.")
	var override_result: Dictionary = catalog.resolve_playable(SONG_ID, "normal", true)
	_check(str(override_result.get("source_kind", "")) == "user_songs", "user://songs did not win duplicate identity precedence.")
	_check(str((override_result.get("chart", {}) as Dictionary).get("title", "")) == "USER SONG OVERRIDE", "Resolved chart was not the user-song override.")

	# A winning but invalid override must fail atomically; silently falling back to
	# a different source would make the visible selection lie about what launched.
	var invalid_override: Dictionary = user_override.duplicate(true)
	invalid_override["audio"] = "user://missing/authoritative_launch_audio.ogg"
	_check(_write_chart(USER_OVERRIDE, invalid_override), "Could not write the invalid override fixture.")
	var invalid_result: Dictionary = catalog.resolve_playable(SONG_ID, "normal", true)
	_check(not bool(invalid_result.get("ok", false)), "Missing audio was accepted for gameplay.")
	_check(str(invalid_result.get("source_path", "")) == USER_OVERRIDE, "Invalid winning source unexpectedly fell back to another chart.")

	var shell: Control = _make_rejecting_shell()
	root.add_child(shell)
	await process_frame
	shell.set("active_screen", "song_library")
	var library: Control = shell.get_node("ScreenHost/SongLibraryScreen") as Control
	var accepted: bool = bool(shell.call("launch_gameplay", {
		"song_id": SONG_ID,
		"difficulty_id": "normal",
		"random_mode": false,
	}, {"title": "STALE LIBRARY TITLE"}))
	_check(not accepted, "AppShell accepted a chart whose audio is missing.")
	_check(str(shell.call("get_active_route")) == "song_library", "Failed launch changed the resident route.")
	_check(not bool(library.get("action_locked")), "Failed launch left Song Library action-locked.")
	_check(not (shell.get_node("ScreenHost/GameplayScreen") as Control).visible, "Failed launch exposed gameplay.")

	_remove_file(USER_OVERRIDE)
	var gameplay_script := load("res://scripts/main.gd") as Script
	var main: Control = gameplay_script.new()
	main.set("level_catalog", catalog)

	var hard_preparation: Dictionary = main.call("prepare_launch_request", {
		"song_id": SONG_ID, "difficulty_id": "hard", "random_mode": false,
	}, true)
	var master_preparation: Dictionary = main.call("prepare_launch_request", {
		"song_id": SONG_ID, "difficulty_id": "master", "random_mode": false,
	}, true)
	_check(bool(hard_preparation.get("ok", false)) and bool(master_preparation.get("ok", false)), "Rapid difficulty preparations failed.")
	var master_request: Dictionary = master_preparation.get("request", {}) as Dictionary
	var visible_chart: Dictionary = master_request.get("_resolved_chart", {}) as Dictionary
	_check(str(visible_chart.get("chart_difficulty", "")) == "master", "Rapid selection prepared a stale difficulty instead of visible MASTER.")
	_check(str(visible_chart.get("_source_chart_hash", "")) == str(master_preparation.get("source_hash", "")), "Launch preparation did not preserve the resolved source hash.")
	var exact_visual: Dictionary = shell.call("_gameplay_visual_payload", visible_chart, master_request, {"title": "STALE"})
	_check(str(exact_visual.get("title", "")) == str(visible_chart.get("title", "")), "Transition metadata did not use the resolved chart.")
	_check(str(exact_visual.get("source_hash", "")) == str(master_preparation.get("source_hash", "")), "Transition metadata lost the resolved source hash.")

	# Retry identity comes from the active chart, never from a stale/reordered index.
	main.set("level_data", visible_chart.duplicate(true))
	main.set("current_level_index", int(main.call("find_level_index", SONG_ID, "hard")))
	var retry: Dictionary = main.call("prepare_retry_request", true)
	_check(bool(retry.get("ok", false)), "Retry chart could not be resolved.")
	var retry_chart: Dictionary = retry.get("chart", {}) as Dictionary
	_check(str(retry_chart.get("chart_difficulty", "")) == "master", "Retry followed the stale catalog index instead of active chart identity.")
	_check(str(retry.get("source_hash", "")) == str(master_preparation.get("source_hash", "")), "Retry changed the intended source identity.")

	# Exercise complete runtime preparation in 8K, 4K, then 8K again. The exact
	# resolved chart passed into gameplay must remain authored source data.
	var source_chart: Dictionary = master_request.get("_resolved_chart", {}) as Dictionary
	var authored_snapshot := JSON.stringify(source_chart)
	for style: String in ["8_direction", "4_arrow", "8_direction"]:
		main.set("input_style", style)
		var runtime_chart: Dictionary = source_chart.duplicate(true)
		var author: RefCounted = main.get("legacy_direction_author") as RefCounted
		runtime_chart = author.call("author_legacy_directions", runtime_chart) as Dictionary
		main.set("level_data", runtime_chart)
		main.call("_prepare_runtime_direction_layouts", runtime_chart.get("events", []) as Array)
		main.set("random_mode_enabled", true)
		for _sample in range(8):
			main.call("pick_runtime_direction")
		main.set("random_mode_enabled", false)
		_check(JSON.stringify(source_chart) == authored_snapshot, "%s runtime preparation mutated authored chart data." % style)
		_check(str(runtime_chart.get("_source_chart_hash", "")) == str(master_preparation.get("source_hash", "")), "%s runtime lost source identity." % style)

	main.free()
	root.remove_child(shell)
	shell.free()
	root.remove_child(catalog)
	catalog.free()
	for _frame in range(3):
		await process_frame
	_cleanup_fixtures()
	_finish()

func _read_chart(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}

func _write_chart(path: String, chart: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	return ReliableJsonStoreScript.save_dictionary_atomic(path, chart)

func _make_rejecting_shell() -> Control:
	var shell: Control = AppShellScript.new()
	var host := Control.new()
	host.name = "ScreenHost"
	shell.add_child(host)
	var startup := Control.new()
	startup.name = "StartupScreen"
	host.add_child(startup)
	var library := LibraryStub.new()
	library.name = "SongLibraryScreen"
	host.add_child(library)
	var gameplay := RejectGameplayStub.new()
	gameplay.name = "GameplayScreen"
	gameplay.visible = false
	host.add_child(gameplay)
	var studio := Control.new()
	studio.name = "ChartStudioScreen"
	host.add_child(studio)
	return shell

func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for suffix: String in [".tmp", ".bak"]:
		var sidecar := path + suffix
		if FileAccess.file_exists(sidecar):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(sidecar))

func _cleanup_fixtures() -> void:
	_remove_file(USER_OVERRIDE)
	_remove_file(STUDIO_EXPORT)
	_remove_empty_directory(USER_SONG_DIR)
	_remove_empty_directory(EXPORT_DIR)

func _remove_empty_directory(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	directory.list_dir_end()
	if entry.is_empty():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)

func _finish() -> void:
	if failures == 0:
		print("AUTHORITATIVE_LAUNCH_RESOLUTION_TEST: PASS")
	else:
		print("AUTHORITATIVE_LAUNCH_RESOLUTION_TEST: FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
