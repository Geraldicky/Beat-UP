extends SceneTree

const UserSettings = preload("res://scripts/user_settings.gd")

var failures := 0
var qa_song_id := ""
var qa_song_dir := ""
var qa_chart_path := ""

func _initialize() -> void:
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i(1920, 1080)
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)

func _run() -> void:
	UserSettings.set_input_style("8_direction")
	root.get_node("AppSessionState").mark_splash_seen()

	var shell := load("res://scenes/app_shell.tscn").instantiate() as Control
	root.add_child(shell)
	await create_timer(0.6).timeout
	var navigation: Node = root.get_node("NavigationController")
	var open_result: Variant = await navigation.call("request_song_library", "blue_zenith", false)
	_check(open_result is Dictionary and str((open_result as Dictionary).get("outcome", "")) == "success", "Could not enter resident Song Library.")
	var library: Control = shell.song_library_screen
	var selector: Control = library.song_select
	var gameplay: Control = shell.gameplay_screen

	# osu! invariant: rapid provisional selection followed by Play must launch the
	# final visible logical identity, not a previous/debounced chart.
	selector._select_song("blue_zenith")
	selector._select_song("bad_apple")
	selector._select_difficulty("master")
	_check(selector.selected_song_id == "bad_apple" and selector.selected_difficulty == "master", "Rapid selection did not settle synchronously on the visible identity.")
	selector._play_selected_chart()
	_check(await _wait_for_route_and_idle(shell, navigation, "gameplay", 5.0), "Immediate Play did not reach gameplay.")
	if shell.get_active_route() == "gameplay":
		_check(str(gameplay.level_data.get("song_id", gameplay.level_data.get("id", ""))) == "bad_apple", "Immediate Play launched the previous song.")
		_check(str(gameplay.level_data.get("chart_difficulty", gameplay.level_data.get("difficulty", ""))).to_lower() == "master", "Immediate Play launched the previous difficulty.")
		var input_snapshot: Dictionary = gameplay.get_run_input_binding_snapshot()
		_check(str(input_snapshot.get("input_style", "")) == "8_direction", "Gameplay did not snapshot the launch-time input mode.")

	if shell.get_active_route() == "gameplay":
		var return_result: Variant = await navigation.call("request_song_library", "bad_apple", false)
		_check(return_result is Dictionary and str((return_result as Dictionary).get("outcome", "")) == "success", "Could not return to Song Library after launch regression.")
		await create_timer(0.25).timeout

	# Editor/import invalidation contract: the visible library may still hold its
	# old catalog snapshot, but the Play boundary must force-resolve current disk data.
	_prepare_qa_paths()
	var template := _read_chart("res://charts/bad_apple/normal.json")
	_check(not template.is_empty(), "QA chart template could not be read.")
	if not template.is_empty():
		var before := _qa_chart(template, "QA BEFORE EDIT", 111.0)
		_check(_write_chart(qa_chart_path, before), "Could not create QA user chart.")
		library._reload_library()
		await process_frame
		await process_frame
		selector.set_selected_song(qa_song_id)
		selector._select_difficulty("normal")
		selector._update_detail(false)
		await process_frame
		_check(selector.detail_title.text == "QA BEFORE EDIT", "QA chart did not enter the library before invalidation.")

		var after := _qa_chart(template, "QA AFTER EDIT", 222.0)
		_check(_write_chart(qa_chart_path, after), "Could not mutate QA chart on disk.")
		# Intentionally DO NOT refresh Song Library before Play.
		_check(selector.detail_title.text == "QA BEFORE EDIT", "Library unexpectedly refreshed before the launch-boundary check.")
		selector._play_selected_chart()
		_check(await _wait_for_route_and_idle(shell, navigation, "gameplay", 5.0), "Edited chart did not launch.")
		if shell.get_active_route() == "gameplay":
			_check(str(gameplay.level_data.get("song_id", gameplay.level_data.get("id", ""))) == qa_song_id, "Edited QA launch resolved the wrong song.")
			_check(str(gameplay.level_data.get("title", "")) == "QA AFTER EDIT", "Play boundary reused stale pre-edit chart metadata.")
			_check(is_equal_approx(float(gameplay.level_data.get("bpm", 0.0)), 222.0), "Play boundary reused stale pre-edit BPM.")

		if shell.get_active_route() == "gameplay":
			var refresh_return: Variant = await navigation.call("request_song_library", qa_song_id, true)
			_check(refresh_return is Dictionary and str((refresh_return as Dictionary).get("outcome", "")) == "success", "Could not return to Song Library with refresh_data.")
			await create_timer(0.45).timeout
			var refreshed_rep: Dictionary = selector._representative(qa_song_id)
			_check(str(refreshed_rep.get("title", "")) == "QA AFTER EDIT", "Resident Song Library did not refresh edited metadata on resume.")
			_check(is_equal_approx(float(refreshed_rep.get("bpm", 0.0)), 222.0), "Resident Song Library did not refresh edited BPM on resume.")

	_cleanup_qa()
	shell.queue_free()
	await process_frame
	await process_frame
	print("SONG_LIBRARY_OSU_REFERENCE_CONTRACT: ", "PASS" if failures == 0 else "FAIL", " ", failures)
	quit(0 if failures == 0 else 1)

func _wait_for_route_and_idle(shell: Control, navigation: Node, target: String, timeout_seconds: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if shell.get_active_route() == target and not bool(navigation.call("is_navigating")):
			return true
		await create_timer(0.05).timeout
	return false

func _prepare_qa_paths() -> void:
	qa_song_id = "qa_song_library_contract_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	qa_song_dir = "user://songs/%s" % qa_song_id
	qa_chart_path = "%s/normal.json" % qa_song_dir
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(qa_song_dir))

func _read_chart(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}

func _qa_chart(template: Dictionary, title: String, bpm: float) -> Dictionary:
	var chart: Dictionary = template.duplicate(true)
	chart["id"] = "%s_normal" % qa_song_id
	chart["song_id"] = qa_song_id
	chart["chart_difficulty"] = "normal"
	chart["difficulty"] = "NORMAL"
	chart["title"] = title
	chart["artist"] = "Beat UP! QA"
	chart["bpm"] = bpm
	return chart

func _write_chart(path: String, chart: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(chart, "\t", false))
	file.close()
	return true

func _cleanup_qa() -> void:
	if not qa_chart_path.is_empty() and FileAccess.file_exists(qa_chart_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(qa_chart_path))
	if not qa_song_dir.is_empty():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(qa_song_dir))
