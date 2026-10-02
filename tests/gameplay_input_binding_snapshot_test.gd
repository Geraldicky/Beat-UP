extends SceneTree

const UserSettingsScript = preload("res://scripts/user_settings.gd")
const QA_ENVIRONMENT_VARIABLE := "BEAT_UP_QA_SETTINGS_FIXTURE"
const QA_ENVIRONMENT_VALUE := "gameplay-input-binding-snapshot"
const SETTINGS_FILES := [
	"user://settings.cfg",
	"user://settings.backup.cfg",
	"user://settings.tmp.cfg",
	"user://settings.corrupt.cfg",
]

var failures := 0
var original_settings: Dictionary = {}

func _initialize() -> void:
	if OS.get_environment(QA_ENVIRONMENT_VARIABLE) != QA_ENVIRONMENT_VALUE:
		push_error("Refusing to modify user:// settings without the isolated gameplay-input QA environment.")
		quit(2)
		return
	call_deferred("_run")

func _run() -> void:
	var baseline_orphan_ids: Array[int] = Node.get_orphan_node_ids()
	_backup_settings_files()
	_clear_settings_files()
	_check(UserSettingsScript.initialize_storage(), "Default settings could not be initialized.")

	var scene := load("res://main.tscn") as PackedScene
	var main := scene.instantiate() as Control
	root.add_child(main)
	await process_frame
	await process_frame

	var preparation: Dictionary = main.call("prepare_launch_request", {
		"song_id": "bad_apple",
		"difficulty_id": "normal",
		"random_mode": false,
	}, true)
	_check(bool(preparation.get("ok", false)), "Bundled chart could not be prepared for binding QA.")
	var request: Dictionary = preparation.get("request", {}) as Dictionary
	_check(bool(main.call("launch_from_app_shell", request)), "Default 8K run could not start.")
	_assert_default_8k(main)
	_check(bool(main.call("_event_matches_run_binding", _key_event(KEY_SPACE), "space")), "Default Space binding did not match.")

	# Persisted changes during a run must not mutate that run's captured bindings.
	_check(UserSettingsScript.set_gameplay_binding("8k_1", KEY_A), "Could not save custom 8K binding.")
	_check(UserSettingsScript.set_gameplay_binding("space", KEY_Z), "Could not save custom Space binding.")
	_check(int(main.call("get_pressed_gameplay_key", _key_event(KEY_KP_1))) == KEY_KP_1, "Active run lost its original 8K binding.")
	_check(int(main.call("get_pressed_gameplay_key", _key_event(KEY_A))) == KEY_NONE, "Active run adopted a mid-run 8K change.")
	_check(bool(main.call("_event_matches_run_binding", _key_event(KEY_SPACE), "space")), "Active run lost its original Space binding.")
	_check(not bool(main.call("_event_matches_run_binding", _key_event(KEY_Z), "space")), "Active run adopted a mid-run Space change.")

	var before_pause: Dictionary = main.call("get_run_input_binding_snapshot")
	main.call("show_pause_overlay")
	_check(main.call("get_run_input_binding_snapshot") == before_pause, "Pause recreated or mutated the run snapshot.")
	main.call("resume_gameplay")
	main.call("_finish_resume_countdown")
	_check(main.call("get_run_input_binding_snapshot") == before_pause, "Resume recreated or mutated the run snapshot.")

	# Retry uses _start_resolved_level(), the same run boundary as first launch.
	var retry: Dictionary = main.call("prepare_retry_request", true)
	_check(_start_prepared(main, retry), "Retry run could not start.")
	_check(int(main.call("get_pressed_gameplay_key", _key_event(KEY_A))) == KEY_KP_1, "Retry did not capture the latest custom 8K binding.")
	_check(bool(main.call("_event_matches_run_binding", _key_event(KEY_Z), "space")), "Retry did not capture the latest Space binding.")

	# Later 4K runs use the mode and bindings current at their own boundary.
	UserSettingsScript.reset_gameplay_bindings()
	UserSettingsScript.set_input_style("4_arrow")
	_check(_start_prepared(main, retry), "Default 4K run could not start.")
	_assert_default_4k(main)
	_check(UserSettingsScript.set_gameplay_binding("4k_left", KEY_Q), "Could not save custom 4K binding.")
	_check(int(main.call("get_pressed_gameplay_key", _key_event(KEY_LEFT))) == KEY_LEFT, "Active 4K run lost its original binding.")
	_check(int(main.call("get_pressed_gameplay_key", _key_event(KEY_Q))) == KEY_NONE, "Active 4K run adopted a mid-run binding change.")
	_check(_start_prepared(main, retry), "Custom 4K run could not start.")
	_check(int(main.call("get_pressed_gameplay_key", _key_event(KEY_Q))) == KEY_LEFT, "New 4K run did not capture the custom binding.")
	_check(int(main.call("get_pressed_gameplay_key", _physical_key_event(KEY_Q))) == KEY_LEFT, "Custom 4K physical-key matching changed.")

	# Switching back on a later run captures the independent 8K map.
	UserSettingsScript.set_input_style("8_direction")
	_check(UserSettingsScript.set_gameplay_binding("8k_1", KEY_A), "Could not restore custom 8K binding.")
	_check(_start_prepared(main, retry), "Later 8K run could not start.")
	_check(str((main.call("get_run_input_binding_snapshot") as Dictionary).get("input_style", "")) == "8_direction", "Later run retained stale 4K mode.")
	_check(int(main.call("get_pressed_gameplay_key", _key_event(KEY_A))) == KEY_KP_1, "Later 8K run used the wrong mode-specific snapshot.")
	main.call("_begin_gameplay_playback")

	# Make settings unreadable after the snapshot. The actual _input() path and
	# both lookup helpers must leave the malformed file byte-for-byte untouched.
	_write_text("user://settings.cfg", "[gameplay]\ninput_style=\"invalid_mode\"\n\n[controls]\n8k_1=0\n")
	var malformed_before := FileAccess.get_file_as_string("user://settings.cfg")
	main.call("_input", _key_event(KEY_A))
	main.call("_input", _key_event(KEY_Z))
	for _sample in range(16):
		main.call("get_pressed_gameplay_key", _key_event(KEY_A))
		main.call("_event_matches_run_binding", _key_event(KEY_Z), "space")
	_check(FileAccess.file_exists("user://settings.cfg"), "Gameplay input moved or deleted malformed settings.")
	_check(FileAccess.get_file_as_string("user://settings.cfg") == malformed_before, "Gameplay input loaded, normalized, or rewrote settings.")
	_check(_start_prepared(main, retry), "Normalized-settings run could not start.")
	var normalized_snapshot: Dictionary = main.call("get_run_input_binding_snapshot")
	_check(str(normalized_snapshot.get("input_style", "")) == "8_direction", "Invalid input style did not normalize to the existing default.")
	var normalized_bindings: Dictionary = normalized_snapshot.get("bindings", {}) as Dictionary
	_check(int(normalized_bindings.get("8k_1", KEY_NONE)) == 1, "Out-of-range binding did not retain the existing clamp-to-one behavior.")

	# Recovery at the next run boundary must retain the established canonical
	# normalization behavior.
	var recovery := ConfigFile.new()
	recovery.set_value("gameplay", "input_style", "4_arrow")
	recovery.set_value("controls", "4k_left", KEY_V)
	_check(recovery.save("user://settings.backup.cfg") == OK, "Could not create recovery fixture.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://settings.cfg"))
	_check(_start_prepared(main, retry), "Recovered-settings run could not start.")
	var recovered_snapshot: Dictionary = main.call("get_run_input_binding_snapshot")
	_check(str(recovered_snapshot.get("input_style", "")) == "4_arrow", "Recovered settings did not preserve canonical input style.")
	_check(int(main.call("get_pressed_gameplay_key", _key_event(KEY_V))) == KEY_LEFT, "Recovered settings did not preserve canonical custom binding.")
	_check(bool(main.call("_event_matches_run_binding", _key_event(KEY_SPACE), "space")), "Recovered settings did not restore the canonical default Space binding.")

	# Static reachability guard: the live input function and its binding lookup
	# helpers must not call UserSettings at all.
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var input_block := _source_block(source, "func _input(", "func _v18_replay_action_for_key")
	var direction_lookup_block := _source_block(source, "func get_pressed_gameplay_key", "func _capture_run_input_binding_snapshot")
	var match_lookup_block := _source_block(source, "func _event_matches_run_binding", "func is_numpad_key")
	_check(not input_block.contains("UserSettingsScript"), "Gameplay _input() still reaches live settings.")
	_check(not direction_lookup_block.contains("UserSettingsScript"), "Directional binding helpers still reach live settings.")
	_check(not match_lookup_block.contains("UserSettingsScript"), "Snapshot event matching still reaches live settings.")

	main.call("prepare_for_shell_exit", "binding_snapshot_test")
	root.remove_child(main)
	main.free()
	await process_frame
	_cleanup_new_orphan_nodes(baseline_orphan_ids)
	_restore_settings_files()
	if failures == 0:
		print("GAMEPLAY_INPUT_BINDING_SNAPSHOT_TEST: PASS")
	else:
		print("GAMEPLAY_INPUT_BINDING_SNAPSHOT_TEST: FAIL (%d)" % failures)
	# Quit after this coroutine returns so its scene/resource references are
	# released before Godot performs shutdown leak checks.
	call_deferred("_finish", 1 if failures > 0 else 0)

func _finish(exit_code: int) -> void:
	quit(exit_code)

func _start_prepared(main: Control, preparation: Dictionary) -> bool:
	if not bool(preparation.get("ok", false)):
		return false
	var prepared_request: Dictionary = preparation.get("request", {}) as Dictionary
	return bool(main.call(
		"_start_resolved_level",
		prepared_request.get("_resolved_chart", {}) as Dictionary,
		prepared_request.get("_resolved_audio_stream") as AudioStream
	))

func _assert_default_8k(main: Control) -> void:
	var cases := {
		KEY_KP_1: KEY_KP_1, KEY_KP_2: KEY_KP_2, KEY_KP_3: KEY_KP_3, KEY_KP_4: KEY_KP_4,
		KEY_KP_6: KEY_KP_6, KEY_KP_7: KEY_KP_7, KEY_KP_8: KEY_KP_8, KEY_KP_9: KEY_KP_9,
	}
	for input_value: Variant in cases.keys():
		var input_key := int(input_value)
		_check(int(main.call("get_pressed_gameplay_key", _key_event(input_key))) == int(cases[input_value]), "Default 8K binding failed for %d." % input_key)

func _assert_default_4k(main: Control) -> void:
	for key: int in [KEY_LEFT, KEY_UP, KEY_RIGHT, KEY_DOWN]:
		_check(int(main.call("get_pressed_gameplay_key", _key_event(key))) == key, "Default 4K binding failed for %d." % key)

func _key_event(keycode: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = keycode
	return event

func _physical_key_event(keycode: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.pressed = true
	event.physical_keycode = keycode
	return event

func _source_block(source: String, start_marker: String, end_marker: String) -> String:
	var start := source.find(start_marker)
	var end := source.find(end_marker, start + start_marker.length())
	if start < 0 or end < 0:
		return source
	return source.substr(start, end - start)

func _backup_settings_files() -> void:
	for path: String in SETTINGS_FILES:
		if not FileAccess.file_exists(path):
			original_settings[path] = {"exists": false}
			continue
		var file := FileAccess.open(path, FileAccess.READ)
		original_settings[path] = {
			"exists": true,
			"bytes": file.get_buffer(file.get_length()) if file != null else PackedByteArray(),
		}
		if file != null:
			file.close()

func _clear_settings_files() -> void:
	for path: String in SETTINGS_FILES:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _restore_settings_files() -> void:
	_clear_settings_files()
	for path: String in SETTINGS_FILES:
		var original: Dictionary = original_settings.get(path, {}) as Dictionary
		if not bool(original.get("exists", false)):
			continue
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_buffer(original.get("bytes", PackedByteArray()) as PackedByteArray)
			file.close()

func _write_text(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(value)
		file.close()

func _cleanup_new_orphan_nodes(baseline_ids: Array[int]) -> void:
	for instance_id: int in Node.get_orphan_node_ids():
		if baseline_ids.has(instance_id):
			continue
		var orphan: Object = instance_from_id(instance_id)
		if orphan is Node and is_instance_valid(orphan):
			(orphan as Node).free()

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
