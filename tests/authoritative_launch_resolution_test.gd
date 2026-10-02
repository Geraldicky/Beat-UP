extends SceneTree

const LevelCatalogScript = preload("res://scripts/level_catalog.gd")

const BUNDLED_SONG_ID := "bad_apple"
const BUNDLED_NORMAL := "res://charts/bad_apple/normal.json"
const BUNDLED_HARD := "res://charts/bad_apple/hard.json"
const BUNDLED_MASTER := "res://charts/bad_apple/master.json"
const REAL_USER_SONG_PATH := "user://songs/bad_apple/normal.json"
const REAL_EXPORT_PATH := "user://chart_exports/bad_apple_normal.json"

var failures := 0
var qa_song_id := ""
var qa_lexical_song_id := ""
var qa_run_root := ""
var qa_bundled_dir := ""
var qa_bundled_chart := ""
var qa_user_song_dir := ""
var qa_user_chart := ""
var qa_export_chart := ""
var qa_unloadable_audio := ""
var owned_files: Dictionary = {}
var created_directories: Array[String] = []

class QaLevelCatalog:
	extends LevelCatalog
	var qa_bundled_prefix := ""

	func _source_kind(path: String) -> String:
		if not qa_bundled_prefix.is_empty() and path.begins_with(qa_bundled_prefix):
			return "bundled"
		return super(path)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_configure_unique_qa_paths()
	_check(qa_user_chart != REAL_USER_SONG_PATH and qa_export_chart != REAL_EXPORT_PATH, "QA paths overlap real Bad Apple user content.")
	var bundled_template: Dictionary = _read_chart(BUNDLED_NORMAL)
	_check(not bundled_template.is_empty(), "Bundled NORMAL fixture could not be read.")
	if bundled_template.is_empty():
		_finish()
		return

	# Real bundled content is read-only. Every writable fixture has a unique QA
	# identity and is registered before cleanup is allowed to remove it.
	var real_catalog: LevelCatalog = LevelCatalogScript.new()
	real_catalog.scan_roots = PackedStringArray()
	real_catalog.level_files = PackedStringArray([BUNDLED_NORMAL, BUNDLED_HARD, BUNDLED_MASTER])
	root.add_child(real_catalog)
	var real_bundled: Dictionary = real_catalog.resolve_playable(BUNDLED_SONG_ID, "normal", true)
	_check(bool(real_bundled.get("ok", false)), "Read-only bundled chart did not resolve.")
	_check(str(real_bundled.get("source_path", "")) == BUNDLED_NORMAL, "Read-only bundled fixture resolved from an unexpected source.")

	var base_chart: Dictionary = _qa_chart_from_template(bundled_template, qa_song_id, "QA BUNDLED BASE")
	_check(_write_owned_chart(qa_bundled_chart, base_chart), "Could not create QA bundled-source fixture.")
	var catalog := QaLevelCatalog.new()
	catalog.qa_bundled_prefix = qa_bundled_dir + "/"
	catalog.scan_roots = PackedStringArray()
	catalog.level_files = PackedStringArray([qa_bundled_chart, qa_export_chart, qa_user_chart])
	root.add_child(catalog)
	_assert_resolution(catalog.resolve_playable(qa_song_id, "normal", true), true, qa_bundled_chart, "bundled", "Synthetic bundled baseline")

	var export_chart: Dictionary = base_chart.duplicate(true)
	export_chart["title"] = "QA EXPORT OVERRIDE"
	export_chart["chart_offset_ms"] = 11.0
	_check(_write_owned_chart(qa_export_chart, export_chart), "Could not create QA Chart Studio export.")
	_assert_resolution(catalog.resolve_playable(qa_song_id, "normal", true), true, qa_export_chart, "user_exports", "Valid user export precedence")

	var user_chart: Dictionary = base_chart.duplicate(true)
	user_chart["title"] = "QA USER SONG OVERRIDE"
	user_chart["chart_offset_ms"] = 22.0
	_check(_write_owned_chart(qa_user_chart, user_chart), "Could not create QA user-song override.")
	_assert_resolution(catalog.resolve_playable(qa_song_id, "normal", true), true, qa_user_chart, "user_songs", "Valid user-song precedence")

	# Managed paths establish identity even when their contents cannot. Each
	# authoritative failure must name that source and never fall through.
	_check(_write_owned_text(qa_user_chart, "{ malformed json"), "Could not write malformed user-song fixture.")
	_assert_rejected_source(catalog.resolve_playable(qa_song_id, "normal", true), qa_user_chart, "user_songs", "Malformed authoritative user song")
	_delete_owned_file(qa_user_chart)
	_assert_resolution(catalog.resolve_playable(qa_song_id, "normal", true), true, qa_export_chart, "user_exports", "Removing broken user song reveals export")

	_check(_write_owned_text(qa_export_chart, "{ malformed json"), "Could not write malformed export fixture.")
	_assert_rejected_source(catalog.resolve_playable(qa_song_id, "normal", true), qa_export_chart, "user_exports", "Malformed authoritative export")
	_delete_owned_file(qa_export_chart)
	_assert_resolution(catalog.resolve_playable(qa_song_id, "normal", true), true, qa_bundled_chart, "bundled", "Removing broken export restores bundled")

	var missing_events: Dictionary = user_chart.duplicate(true)
	missing_events.erase("events")
	_check(_write_owned_chart(qa_user_chart, missing_events), "Could not write missing-events fixture.")
	_assert_rejected_source(catalog.resolve_playable(qa_song_id, "normal", true), qa_user_chart, "user_songs", "Missing events")

	var invalid_structure: Dictionary = user_chart.duplicate(true)
	invalid_structure["events"] = [{"time": "not-a-number", "type": "normal", "direction": 8}]
	_check(_write_owned_chart(qa_user_chart, invalid_structure), "Could not write structurally invalid fixture.")
	_assert_rejected_source(catalog.resolve_playable(qa_song_id, "normal", true), qa_user_chart, "user_songs", "Structural validation")

	var missing_audio: Dictionary = user_chart.duplicate(true)
	missing_audio["audio"] = "%s/missing_audio.ogg" % qa_run_root
	_check(_write_owned_chart(qa_user_chart, missing_audio), "Could not write missing-audio fixture.")
	_assert_rejected_source(catalog.resolve_playable(qa_song_id, "normal", true), qa_user_chart, "user_songs", "Missing audio")

	_check(_write_owned_text(qa_unloadable_audio, "this exists but is not a supported audio stream"), "Could not create unloadable-audio fixture.")
	var unloadable_audio: Dictionary = user_chart.duplicate(true)
	unloadable_audio["audio"] = qa_unloadable_audio
	_check(_write_owned_chart(qa_user_chart, unloadable_audio), "Could not write unloadable-audio chart fixture.")
	var unloadable_result: Dictionary = catalog.resolve_playable(qa_song_id, "normal", true)
	_assert_rejected_source(unloadable_result, qa_user_chart, "user_songs", "Unloadable audio")
	_check(str(unloadable_result.get("error", "")).contains("could not be loaded"), "Unloadable audio did not report a load failure.")

	# A malformed user file without a canonical managed-path identity is ignored.
	var unclaimed_path := "user://chart_exports/%s_unknown.json" % qa_song_id
	_check(_write_owned_text(unclaimed_path, "{ malformed json"), "Could not create unclaimed malformed fixture.")
	catalog.level_files.append(unclaimed_path)
	_delete_owned_file(qa_user_chart)
	_assert_resolution(catalog.resolve_playable(qa_song_id, "normal", true), true, qa_bundled_chart, "bundled", "Unclaimed malformed file remains ignored")

	# Same-priority arbitrary files use parsed identities; lexical path ordering
	# remains deterministic without inventing identities for malformed files.
	var lexical_a := "%s/other/a.json" % qa_run_root
	var lexical_z := "%s/other/z.json" % qa_run_root
	_check(_write_owned_chart(lexical_z, _qa_chart_from_template(bundled_template, qa_lexical_song_id, "LEXICAL Z")), "Could not create lexical Z fixture.")
	_check(_write_owned_chart(lexical_a, _qa_chart_from_template(bundled_template, qa_lexical_song_id, "LEXICAL A")), "Could not create lexical A fixture.")
	var lexical_catalog: LevelCatalog = LevelCatalogScript.new()
	lexical_catalog.scan_roots = PackedStringArray()
	lexical_catalog.level_files = PackedStringArray([lexical_z, lexical_a])
	root.add_child(lexical_catalog)
	_assert_resolution(lexical_catalog.resolve_playable(qa_lexical_song_id, "normal", true), true, lexical_a, "other", "Same-priority lexical ordering")

	# Retain launch identity and immutable-runtime regressions using only read-only
	# bundled charts.
	var gameplay_script := load("res://scripts/main.gd") as Script
	var main: Control = gameplay_script.new()
	main.set("level_catalog", real_catalog)
	var hard_preparation: Dictionary = main.call("prepare_launch_request", {"song_id": BUNDLED_SONG_ID, "difficulty_id": "hard"}, true)
	var master_preparation: Dictionary = main.call("prepare_launch_request", {"song_id": BUNDLED_SONG_ID, "difficulty_id": "master"}, true)
	_check(bool(hard_preparation.get("ok", false)) and bool(master_preparation.get("ok", false)), "Rapid bundled difficulty preparations failed.")
	var master_request: Dictionary = master_preparation.get("request", {}) as Dictionary
	var source_chart: Dictionary = master_request.get("_resolved_chart", {}) as Dictionary
	_check(str(source_chart.get("chart_difficulty", "")) == "master", "Rapid selection prepared a stale difficulty.")
	main.set("level_data", source_chart.duplicate(true))
	main.set("current_level_index", int(main.call("find_level_index", BUNDLED_SONG_ID, "hard")))
	var retry: Dictionary = main.call("prepare_retry_request", true)
	_check(str((retry.get("chart", {}) as Dictionary).get("chart_difficulty", "")) == "master", "Retry followed a stale index.")
	var authored_snapshot := JSON.stringify(source_chart)
	for style: String in ["8_direction", "4_arrow", "8_direction"]:
		var runtime_chart: Dictionary = source_chart.duplicate(true)
		var author: RefCounted = main.get("legacy_direction_author") as RefCounted
		runtime_chart = author.call("author_legacy_directions", runtime_chart) as Dictionary
		main.set("level_data", runtime_chart)
		main.set("input_style", style)
		main.call("_prepare_runtime_direction_layouts", runtime_chart.get("events", []) as Array)
		main.set("random_mode_enabled", true)
		for _sample in range(8):
			main.call("pick_runtime_direction")
		main.set("random_mode_enabled", false)
		_check(JSON.stringify(source_chart) == authored_snapshot, "%s runtime preparation mutated source data." % style)

	main.free()
	root.remove_child(lexical_catalog)
	lexical_catalog.free()
	root.remove_child(catalog)
	catalog.free()
	root.remove_child(real_catalog)
	real_catalog.free()
	_cleanup_owned_content()
	for _frame in range(3):
		await process_frame
	_finish()

func _configure_unique_qa_paths() -> void:
	var run_id := "%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	qa_song_id = "qa_authoritative_launch_%s" % run_id
	qa_lexical_song_id = "%s_lexical" % qa_song_id
	qa_run_root = "user://qa_authoritative_launch_runs/%s" % run_id
	qa_bundled_dir = "%s/bundled" % qa_run_root
	qa_bundled_chart = "%s/normal.json" % qa_bundled_dir
	qa_user_song_dir = "user://songs/%s" % qa_song_id
	qa_user_chart = "%s/normal.json" % qa_user_song_dir
	qa_export_chart = "user://chart_exports/%s_normal.json" % qa_song_id
	qa_unloadable_audio = "%s/unloadable.qa" % qa_run_root

func _qa_chart_from_template(template: Dictionary, song_id: String, title: String) -> Dictionary:
	var chart: Dictionary = template.duplicate(true)
	chart["id"] = "%s_normal" % song_id
	chart["song_id"] = song_id
	chart["chart_difficulty"] = "normal"
	chart["difficulty"] = "NORMAL"
	chart["title"] = title
	return chart

func _assert_resolution(result: Dictionary, expected_ok: bool, expected_path: String, expected_kind: String, label: String) -> void:
	_check(bool(result.get("ok", false)) == expected_ok, "%s returned an unexpected status: %s" % [label, str(result.get("error", ""))])
	_check(str(result.get("source_path", "")) == expected_path, "%s selected the wrong source path." % label)
	_check(str(result.get("source_kind", "")) == expected_kind, "%s selected the wrong source kind." % label)

func _assert_rejected_source(result: Dictionary, expected_path: String, expected_kind: String, label: String) -> void:
	_assert_resolution(result, false, expected_path, expected_kind, label)
	_check(not str(result.get("error", "")).is_empty(), "%s did not report a failure reason." % label)

func _read_chart(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}

func _write_owned_chart(path: String, chart: Dictionary) -> bool:
	return _write_owned_text(path, JSON.stringify(chart, "\t", false))

func _write_owned_text(path: String, content: String) -> bool:
	if not owned_files.has(path) and FileAccess.file_exists(path):
		_check(false, "Refusing to overwrite pre-existing file: %s" % path)
		return false
	_ensure_owned_directory(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(content)
	file.close()
	owned_files[path] = true
	return true

func _delete_owned_file(path: String) -> void:
	if owned_files.has(path) and FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _ensure_owned_directory(path: String) -> void:
	if path == "user://" or DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)):
		return
	_ensure_owned_directory(path.get_base_dir())
	if DirAccess.make_dir_absolute(ProjectSettings.globalize_path(path)) == OK:
		created_directories.append(path)

func _cleanup_owned_content() -> void:
	for path_value: Variant in owned_files.keys():
		var path := str(path_value)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	created_directories.reverse()
	for path: String in created_directories:
		var directory := DirAccess.open(path)
		if directory == null:
			continue
		directory.list_dir_begin()
		var entry := directory.get_next()
		directory.list_dir_end()
		if entry.is_empty():
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	created_directories.clear()

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)

func _finish() -> void:
	_cleanup_owned_content()
	if failures == 0:
		print("AUTHORITATIVE_LAUNCH_RESOLUTION_TEST: PASS")
	else:
		print("AUTHORITATIVE_LAUNCH_RESOLUTION_TEST: FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
