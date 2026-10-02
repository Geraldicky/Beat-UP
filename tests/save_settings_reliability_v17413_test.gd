extends SceneTree

const UserSettingsScript = preload("res://scripts/user_settings.gd")
const ReliableJsonStoreScript = preload("res://scripts/reliable_json_store.gd")

const TEST_JSON_PATH := "user://v17413_reliable_store_test.json"

func _init() -> void:
	var failures: Array[String] = []
	_test_settings_normalization(failures)
	_test_atomic_json_recovery(failures)
	_cleanup_json_test_files()

	if failures.is_empty():
		print("v17.4.13 save/settings reliability checks: PASS")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)


func _test_settings_normalization(failures: Array[String]) -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", "broken")
	config.set_value("audio", "menu_sfx_enabled", "false")
	config.set_value("visual", "background_opacity", 140.0)
	config.set_value("timing", "input_offset_ms", -999.0)
	config.set_value("timing", "audio_offset_ms", "25.5")
	config.set_value("gameplay", "input_style", "invalid")
	config.set_value("display", "resolution_width", 100)
	config.set_value("display", "resolution_height", 99999)
	config.set_value("display", "window_mode", "exclusive")
	config.set_value("display", "vsync_enabled", "false")
	config.set_value("navigation", "last_difficulty", "impossible")
	config.set_value("future_section", "preserve_me", 42)

	UserSettingsScript.normalize_config(config)

	_expect_float(config.get_value("audio", "master_volume"), 80.0, "Malformed master volume did not fall back to default.", failures)
	_expect_bool(config.get_value("audio", "menu_sfx_enabled"), false, "String false was not normalized to bool false.", failures)
	_expect_float(config.get_value("visual", "background_opacity"), 100.0, "Background opacity was not clamped.", failures)
	_expect_float(config.get_value("timing", "input_offset_ms"), -200.0, "Input offset was not clamped.", failures)
	_expect_float(config.get_value("timing", "audio_offset_ms"), 25.5, "Numeric string audio offset was not preserved.", failures)
	_expect_string(config.get_value("gameplay", "input_style"), "8_direction", "Invalid input style was not repaired.", failures)
	_expect_int(config.get_value("display", "resolution_width"), 640, "Resolution width was not clamped.", failures)
	_expect_int(config.get_value("display", "resolution_height"), 4320, "Resolution height was not clamped.", failures)
	_expect_string(config.get_value("display", "window_mode"), "windowed", "Invalid window mode was not repaired.", failures)
	_expect_bool(config.get_value("display", "vsync_enabled"), false, "VSync string false was not normalized.", failures)
	_expect_string(config.get_value("navigation", "last_difficulty"), "normal", "Invalid saved difficulty was not repaired.", failures)
	_expect_int(config.get_value("future_section", "preserve_me"), 42, "Unknown/future settings were deleted.", failures)
	_expect_int(config.get_value("meta", "schema_version"), UserSettingsScript.SETTINGS_SCHEMA_VERSION, "Settings schema version missing.", failures)


func _test_atomic_json_recovery(failures: Array[String]) -> void:
	_cleanup_json_test_files()
	if not ReliableJsonStoreScript.save_dictionary_atomic(TEST_JSON_PATH, {"generation": 1, "score": 100}):
		failures.append("Could not create first atomic JSON test save.")
		return
	if not ReliableJsonStoreScript.save_dictionary_atomic(TEST_JSON_PATH, {"generation": 2, "score": 200}):
		failures.append("Could not create second atomic JSON test save.")
		return

	var file := FileAccess.open(TEST_JSON_PATH, FileAccess.WRITE)
	if file == null:
		failures.append("Could not corrupt primary JSON test file.")
		return
	file.store_string("{ this is deliberately invalid JSON")
	file.close()

	var result: Dictionary = ReliableJsonStoreScript.load_dictionary(TEST_JSON_PATH)
	if not bool(result.get("recovered", false)):
		failures.append("Reliable JSON store did not report backup recovery.")
	var data: Variant = result.get("data", {})
	if not (data is Dictionary):
		failures.append("Recovered JSON data is not a Dictionary.")
		return
	var recovered: Dictionary = data as Dictionary
	_expect_int(recovered.get("generation", -1), 1, "Recovery did not restore the previous known-good generation.", failures)
	_expect_int(recovered.get("score", -1), 100, "Recovered score did not match backup.", failures)

	var restored_parser := JSON.new()
	var restored_err := restored_parser.parse(FileAccess.get_file_as_string(TEST_JSON_PATH))
	if restored_err != OK or not (restored_parser.data is Dictionary):
		failures.append("Primary JSON file was not restored after backup recovery.")


func _cleanup_json_test_files() -> void:
	for suffix: String in ["", ".bak", ".tmp", ".corrupt"]:
		var path := TEST_JSON_PATH + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect_float(actual: Variant, expected: float, message: String, failures: Array[String]) -> void:
	if not (actual is int or actual is float) or absf(float(actual) - expected) > 0.001:
		failures.append(message)


func _expect_int(actual: Variant, expected: int, message: String, failures: Array[String]) -> void:
	if not (actual is int or actual is float) or int(actual) != expected:
		failures.append(message)


func _expect_bool(actual: Variant, expected: bool, message: String, failures: Array[String]) -> void:
	if not (actual is bool) or bool(actual) != expected:
		failures.append(message)


func _expect_string(actual: Variant, expected: String, message: String, failures: Array[String]) -> void:
	if not (actual is String) or str(actual) != expected:
		failures.append(message)
