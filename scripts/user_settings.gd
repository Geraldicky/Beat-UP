extends RefCounted
class_name UserSettings

const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_BACKUP_PATH := "user://settings.backup.cfg"
const SETTINGS_TEMP_PATH := "user://settings.tmp.cfg"
const SETTINGS_CORRUPT_PATH := "user://settings.corrupt.cfg"
const SETTINGS_SCHEMA_VERSION := 3

const DEFAULT_MASTER_VOLUME := 80.0
const DEFAULT_MENU_SFX_VOLUME := 68.0
const DEFAULT_MENU_SFX_ENABLED := true
const DEFAULT_BG_OPACITY := 62.0
const DEFAULT_INPUT_OFFSET_MS := 0.0
const DEFAULT_AUDIO_OFFSET_MS := 0.0
const MIN_TIMING_OFFSET_MS := -200.0
const MAX_TIMING_OFFSET_MS := 200.0

const DEFAULT_INPUT_STYLE := "8_direction"
const DEFAULT_NOTE_TRAVEL_TIME := 1.5
const MIN_NOTE_TRAVEL_TIME := 0.6
const MAX_NOTE_TRAVEL_TIME := 2.6
const VALID_INPUT_STYLES := ["8_direction", "4_arrow"]
const DEFAULT_EFFECT_INTENSITY := 75.0
const MIN_EFFECT_INTENSITY := 0.0
const MAX_EFFECT_INTENSITY := 100.0

const DEFAULT_GAMEPLAY_BINDINGS := {
	"8k_1": KEY_KP_1,
	"8k_2": KEY_KP_2,
	"8k_3": KEY_KP_3,
	"8k_4": KEY_KP_4,
	"8k_6": KEY_KP_6,
	"8k_7": KEY_KP_7,
	"8k_8": KEY_KP_8,
	"8k_9": KEY_KP_9,
	"4k_left": KEY_LEFT,
	"4k_up": KEY_UP,
	"4k_right": KEY_RIGHT,
	"4k_down": KEY_DOWN,
	"space": KEY_SPACE,
}
const FIRST_RUN_TUTORIAL_VERSION := "17.4.9"
const DEFAULT_LIBRARY_DIFFICULTY := "normal"
const VALID_LIBRARY_DIFFICULTIES := ["normal", "hard", "master"]

const DEFAULT_RESOLUTION := Vector2i(1280, 720)
const MIN_RESOLUTION := Vector2i(640, 360)
const MAX_RESOLUTION := Vector2i(7680, 4320)
const DEFAULT_WINDOW_MODE := "windowed"
const DEFAULT_VSYNC_ENABLED := true
const VALID_WINDOW_MODES := ["windowed", "borderless", "fullscreen"]


static func initialize_storage() -> bool:
	# Forces one health check at startup. Getters also self-heal, so callers that
	# bypass startup still receive safe values.
	var status := _load_config_with_status()
	var config: ConfigFile = status.get("config") as ConfigFile
	var changed := normalize_config(config)
	var needs_write: bool = changed or bool(status.get("recovered", false)) or bool(status.get("needs_rebuild", false))
	if needs_write:
		return _save_config(config, not bool(status.get("needs_rebuild", false)))
	return true


static func load_config() -> ConfigFile:
	var status := _load_config_with_status()
	var config: ConfigFile = status.get("config") as ConfigFile
	var changed := normalize_config(config)
	var needs_write: bool = changed or bool(status.get("recovered", false)) or bool(status.get("needs_rebuild", false))
	if needs_write:
		_save_config(config, not bool(status.get("needs_rebuild", false)))
	return config


static func normalize_config(config: ConfigFile) -> bool:
	# Canonicalize every setting that can affect a Beta playtest. Unknown keys
	# and future sections are deliberately preserved.
	var changed := false
	changed = _set_if_changed(config, "meta", "schema_version", SETTINGS_SCHEMA_VERSION) or changed

	changed = _set_if_changed(config, "audio", "master_volume", _read_float(config, "audio", "master_volume", DEFAULT_MASTER_VOLUME, 0.0, 100.0)) or changed
	changed = _set_if_changed(config, "audio", "menu_sfx_volume", _read_float(config, "audio", "menu_sfx_volume", DEFAULT_MENU_SFX_VOLUME, 0.0, 100.0)) or changed
	changed = _set_if_changed(config, "audio", "menu_sfx_enabled", _read_bool(config, "audio", "menu_sfx_enabled", DEFAULT_MENU_SFX_ENABLED)) or changed
	changed = _set_if_changed(config, "visual", "background_opacity", _read_float(config, "visual", "background_opacity", DEFAULT_BG_OPACITY, 0.0, 100.0)) or changed
	changed = _set_if_changed(config, "visual", "effect_intensity", _read_float(config, "visual", "effect_intensity", DEFAULT_EFFECT_INTENSITY, MIN_EFFECT_INTENSITY, MAX_EFFECT_INTENSITY)) or changed
	changed = _set_if_changed(config, "timing", "input_offset_ms", _read_float(config, "timing", "input_offset_ms", DEFAULT_INPUT_OFFSET_MS, MIN_TIMING_OFFSET_MS, MAX_TIMING_OFFSET_MS)) or changed
	changed = _set_if_changed(config, "timing", "audio_offset_ms", _read_float(config, "timing", "audio_offset_ms", DEFAULT_AUDIO_OFFSET_MS, MIN_TIMING_OFFSET_MS, MAX_TIMING_OFFSET_MS)) or changed

	var input_style := _read_string(config, "gameplay", "input_style", DEFAULT_INPUT_STYLE).to_lower()
	if not VALID_INPUT_STYLES.has(input_style):
		input_style = DEFAULT_INPUT_STYLE
	changed = _set_if_changed(config, "gameplay", "input_style", input_style) or changed
	changed = _set_if_changed(config, "gameplay", "note_travel_time", _read_float(config, "gameplay", "note_travel_time", DEFAULT_NOTE_TRAVEL_TIME, MIN_NOTE_TRAVEL_TIME, MAX_NOTE_TRAVEL_TIME)) or changed

	for action_value: Variant in DEFAULT_GAMEPLAY_BINDINGS.keys():
		var action: String = str(action_value)
		var fallback_key: int = int(DEFAULT_GAMEPLAY_BINDINGS[action])
		var binding_key: int = _read_int(config, "controls", action, fallback_key, 1, 0x7fffffff)
		changed = _set_if_changed(config, "controls", action, binding_key) or changed

	var width := _read_int(config, "display", "resolution_width", DEFAULT_RESOLUTION.x, MIN_RESOLUTION.x, MAX_RESOLUTION.x)
	var height := _read_int(config, "display", "resolution_height", DEFAULT_RESOLUTION.y, MIN_RESOLUTION.y, MAX_RESOLUTION.y)
	changed = _set_if_changed(config, "display", "resolution_width", width) or changed
	changed = _set_if_changed(config, "display", "resolution_height", height) or changed
	var window_mode := _read_string(config, "display", "window_mode", DEFAULT_WINDOW_MODE).to_lower()
	if not VALID_WINDOW_MODES.has(window_mode):
		window_mode = DEFAULT_WINDOW_MODE
	changed = _set_if_changed(config, "display", "window_mode", window_mode) or changed
	changed = _set_if_changed(config, "display", "vsync_enabled", _read_bool(config, "display", "vsync_enabled", DEFAULT_VSYNC_ENABLED)) or changed

	var tutorial_version := _read_string(config, "onboarding", "tutorial_version", "").strip_edges()
	changed = _set_if_changed(config, "onboarding", "tutorial_version", tutorial_version) or changed
	var song_id := _read_string(config, "navigation", "last_song_id", "").strip_edges()
	changed = _set_if_changed(config, "navigation", "last_song_id", song_id) or changed
	var difficulty := _read_string(config, "navigation", "last_difficulty", DEFAULT_LIBRARY_DIFFICULTY).to_lower()
	if not VALID_LIBRARY_DIFFICULTIES.has(difficulty):
		difficulty = DEFAULT_LIBRARY_DIFFICULTY
	changed = _set_if_changed(config, "navigation", "last_difficulty", difficulty) or changed
	return changed


static func _load_config_with_status() -> Dictionary:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	if err == OK:
		return {"config": config, "recovered": false, "needs_rebuild": false}

	if err != ERR_FILE_NOT_FOUND:
		push_warning("Beat UP! settings: primary settings file is unreadable (error %d)." % err)
		_report_runtime("warning", "settings", "Primary settings file unreadable", {"error": err})
		_quarantine_corrupt_settings()

	var backup := ConfigFile.new()
	var backup_err := backup.load(SETTINGS_BACKUP_PATH)
	if backup_err == OK:
		push_warning("Beat UP! settings: recovered preferences from backup.")
		_report_runtime("warning", "settings", "Recovered preferences from backup")
		return {"config": backup, "recovered": true, "needs_rebuild": true}

	return {"config": ConfigFile.new(), "recovered": false, "needs_rebuild": true}


static func _save_config(config: ConfigFile, rotate_backup: bool = true) -> bool:
	normalize_config(config)
	_remove_file_if_exists(SETTINGS_TEMP_PATH)
	var temp_err := config.save(SETTINGS_TEMP_PATH)
	if temp_err != OK:
		push_error("Beat UP! settings: failed to write temporary settings (error %d)." % temp_err)
		_report_runtime("error", "settings", "Failed to write temporary settings", {"error": temp_err})
		return false

	var verify := ConfigFile.new()
	var verify_err := verify.load(SETTINGS_TEMP_PATH)
	if verify_err != OK:
		push_error("Beat UP! settings: temporary settings verification failed (error %d)." % verify_err)
		_remove_file_if_exists(SETTINGS_TEMP_PATH)
		return false

	var had_primary := FileAccess.file_exists(SETTINGS_PATH)
	if had_primary and rotate_backup:
		_remove_file_if_exists(SETTINGS_BACKUP_PATH)
		var rotate_err := DirAccess.rename_absolute(
			ProjectSettings.globalize_path(SETTINGS_PATH),
			ProjectSettings.globalize_path(SETTINGS_BACKUP_PATH)
		)
		if rotate_err != OK:
			push_error("Beat UP! settings: failed to rotate settings backup (error %d)." % rotate_err)
			_remove_file_if_exists(SETTINGS_TEMP_PATH)
			return false
	elif had_primary:
		# Recovery/rebuild writes must not replace a known-good backup with the
		# unreadable primary that triggered recovery.
		_remove_file_if_exists(SETTINGS_PATH)

	var promote_err := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(SETTINGS_TEMP_PATH),
		ProjectSettings.globalize_path(SETTINGS_PATH)
	)
	if promote_err == OK:
		return true

	push_error("Beat UP! settings: failed to promote temporary settings (error %d)." % promote_err)
	_remove_file_if_exists(SETTINGS_TEMP_PATH)
	if FileAccess.file_exists(SETTINGS_BACKUP_PATH) and not FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.rename_absolute(
			ProjectSettings.globalize_path(SETTINGS_BACKUP_PATH),
			ProjectSettings.globalize_path(SETTINGS_PATH)
		)
	return false


static func get_master_volume() -> float:
	var config := load_config()
	return _read_float(config, "audio", "master_volume", DEFAULT_MASTER_VOLUME, 0.0, 100.0)


static func get_menu_sfx_volume() -> float:
	var config := load_config()
	return _read_float(config, "audio", "menu_sfx_volume", DEFAULT_MENU_SFX_VOLUME, 0.0, 100.0)


static func get_menu_sfx_enabled() -> bool:
	var config := load_config()
	return _read_bool(config, "audio", "menu_sfx_enabled", DEFAULT_MENU_SFX_ENABLED)


static func get_background_opacity() -> float:
	var config := load_config()
	return _read_float(config, "visual", "background_opacity", DEFAULT_BG_OPACITY, 0.0, 100.0)


static func get_effect_intensity() -> float:
	var config: ConfigFile = load_config()
	return _read_float(config, "visual", "effect_intensity", DEFAULT_EFFECT_INTENSITY, MIN_EFFECT_INTENSITY, MAX_EFFECT_INTENSITY)


static func set_effect_intensity(value: float) -> void:
	var config: ConfigFile = load_config()
	config.set_value("visual", "effect_intensity", clampf(value, MIN_EFFECT_INTENSITY, MAX_EFFECT_INTENSITY))
	_save_config(config)


static func get_gameplay_binding(action: String) -> int:
	if not DEFAULT_GAMEPLAY_BINDINGS.has(action):
		return KEY_NONE
	var config: ConfigFile = load_config()
	var fallback_key: int = int(DEFAULT_GAMEPLAY_BINDINGS[action])
	return _read_int(config, "controls", action, fallback_key, 1, 0x7fffffff)


static func create_gameplay_input_snapshot() -> Dictionary:
	# One normalized persistence read at the run boundary. Gameplay owns the
	# returned value and never consults ConfigFile again for this run.
	var config: ConfigFile = load_config()
	var style := _read_string(config, "gameplay", "input_style", DEFAULT_INPUT_STYLE).to_lower()
	if not VALID_INPUT_STYLES.has(style):
		style = DEFAULT_INPUT_STYLE
	var bindings: Dictionary = {}
	for action_value: Variant in DEFAULT_GAMEPLAY_BINDINGS.keys():
		var action: String = str(action_value)
		bindings[action] = _read_int(
			config,
			"controls",
			action,
			int(DEFAULT_GAMEPLAY_BINDINGS[action]),
			1,
			0x7fffffff
		)
	return {
		"input_style": style,
		"bindings": bindings,
		"note_travel_time": _read_float(config, "gameplay", "note_travel_time", DEFAULT_NOTE_TRAVEL_TIME, MIN_NOTE_TRAVEL_TIME, MAX_NOTE_TRAVEL_TIME),
	}

static func get_note_travel_time() -> float:
	return float(load_config().get_value("gameplay", "note_travel_time", DEFAULT_NOTE_TRAVEL_TIME))

static func set_note_travel_time(value: float) -> void:
	var config := load_config()
	config.set_value("gameplay", "note_travel_time", clampf(value, MIN_NOTE_TRAVEL_TIME, MAX_NOTE_TRAVEL_TIME) if is_finite(value) else DEFAULT_NOTE_TRAVEL_TIME)
	_save_config(config)


static func set_gameplay_binding(action: String, keycode: int) -> bool:
	if not DEFAULT_GAMEPLAY_BINDINGS.has(action) or keycode == KEY_NONE:
		return false
	if not can_assign_gameplay_binding(action, keycode):
		return false
	var config: ConfigFile = load_config()
	config.set_value("controls", action, keycode)
	return _save_config(config)


static func can_assign_gameplay_binding(action: String, keycode: int) -> bool:
	if keycode == KEY_NONE:
		return false
	for action_value: Variant in DEFAULT_GAMEPLAY_BINDINGS.keys():
		var other: String = str(action_value)
		if other == action:
			continue
		if get_gameplay_binding(other) == keycode:
			return false
	return true


static func reset_gameplay_bindings() -> void:
	var config: ConfigFile = load_config()
	for action_value: Variant in DEFAULT_GAMEPLAY_BINDINGS.keys():
		var action: String = str(action_value)
		config.set_value("controls", action, int(DEFAULT_GAMEPLAY_BINDINGS[action]))
	_save_config(config)


static func event_matches_gameplay_binding(event: InputEventKey, action: String) -> bool:
	var expected: int = get_gameplay_binding(action)
	return expected != KEY_NONE and (event.keycode == expected or event.physical_keycode == expected)


static func gameplay_binding_label(action: String) -> String:
	var keycode: int = get_gameplay_binding(action)
	var label: String = OS.get_keycode_string(keycode)
	return label if not label.is_empty() else str(keycode)


static func get_input_offset_ms() -> float:
	var config := load_config()
	return _read_float(config, "timing", "input_offset_ms", DEFAULT_INPUT_OFFSET_MS, MIN_TIMING_OFFSET_MS, MAX_TIMING_OFFSET_MS)


static func get_audio_offset_ms() -> float:
	var config := load_config()
	return _read_float(config, "timing", "audio_offset_ms", DEFAULT_AUDIO_OFFSET_MS, MIN_TIMING_OFFSET_MS, MAX_TIMING_OFFSET_MS)


static func get_input_style() -> String:
	var config := load_config()
	var style := _read_string(config, "gameplay", "input_style", DEFAULT_INPUT_STYLE).to_lower()
	return style if VALID_INPUT_STYLES.has(style) else DEFAULT_INPUT_STYLE


static func has_seen_first_run_tutorial() -> bool:
	var config := load_config()
	return _read_string(config, "onboarding", "tutorial_version", "") == FIRST_RUN_TUTORIAL_VERSION


static func mark_first_run_tutorial_seen() -> void:
	var config := load_config()
	config.set_value("onboarding", "tutorial_version", FIRST_RUN_TUTORIAL_VERSION)
	_save_config(config)


static func get_last_library_song_id() -> String:
	var config := load_config()
	return _read_string(config, "navigation", "last_song_id", "").strip_edges()


static func get_last_library_difficulty() -> String:
	var config := load_config()
	var difficulty := _read_string(config, "navigation", "last_difficulty", DEFAULT_LIBRARY_DIFFICULTY).to_lower()
	return difficulty if VALID_LIBRARY_DIFFICULTIES.has(difficulty) else DEFAULT_LIBRARY_DIFFICULTY


static func remember_library_selection(song_id: String, difficulty_id: String) -> void:
	var safe_song_id := song_id.strip_edges()
	if safe_song_id.is_empty():
		return
	var safe_difficulty := difficulty_id.to_lower()
	if not VALID_LIBRARY_DIFFICULTIES.has(safe_difficulty):
		safe_difficulty = DEFAULT_LIBRARY_DIFFICULTY
	var config := load_config()
	config.set_value("navigation", "last_song_id", safe_song_id)
	config.set_value("navigation", "last_difficulty", safe_difficulty)
	_save_config(config)


static func get_resolution() -> Vector2i:
	var config := load_config()
	return Vector2i(
		_read_int(config, "display", "resolution_width", DEFAULT_RESOLUTION.x, MIN_RESOLUTION.x, MAX_RESOLUTION.x),
		_read_int(config, "display", "resolution_height", DEFAULT_RESOLUTION.y, MIN_RESOLUTION.y, MAX_RESOLUTION.y)
	)


static func get_window_mode() -> String:
	var config := load_config()
	var mode := _read_string(config, "display", "window_mode", DEFAULT_WINDOW_MODE).to_lower()
	return mode if VALID_WINDOW_MODES.has(mode) else DEFAULT_WINDOW_MODE


static func get_vsync_enabled() -> bool:
	var config := load_config()
	return _read_bool(config, "display", "vsync_enabled", DEFAULT_VSYNC_ENABLED)


static func set_master_volume(value: float) -> void:
	var config := load_config()
	var safe_value := clampf(value, 0.0, 100.0)
	config.set_value("audio", "master_volume", safe_value)
	_save_config(config)
	apply_master_volume(safe_value)


static func set_menu_sfx_volume(value: float) -> void:
	var config := load_config()
	config.set_value("audio", "menu_sfx_volume", clampf(value, 0.0, 100.0))
	_save_config(config)


static func set_menu_sfx_enabled(enabled: bool) -> void:
	var config := load_config()
	config.set_value("audio", "menu_sfx_enabled", enabled)
	_save_config(config)


static func set_background_opacity(value: float) -> void:
	var config := load_config()
	config.set_value("visual", "background_opacity", clampf(value, 0.0, 100.0))
	_save_config(config)


static func set_input_offset_ms(value: float) -> void:
	var config := load_config()
	config.set_value("timing", "input_offset_ms", clampf(value, MIN_TIMING_OFFSET_MS, MAX_TIMING_OFFSET_MS))
	_save_config(config)


static func set_audio_offset_ms(value: float) -> void:
	var config := load_config()
	config.set_value("timing", "audio_offset_ms", clampf(value, MIN_TIMING_OFFSET_MS, MAX_TIMING_OFFSET_MS))
	_save_config(config)


static func set_timing_offsets(input_offset_ms: float, audio_offset_ms: float) -> void:
	var config := load_config()
	config.set_value("timing", "input_offset_ms", clampf(input_offset_ms, MIN_TIMING_OFFSET_MS, MAX_TIMING_OFFSET_MS))
	config.set_value("timing", "audio_offset_ms", clampf(audio_offset_ms, MIN_TIMING_OFFSET_MS, MAX_TIMING_OFFSET_MS))
	_save_config(config)


static func reset_timing_offsets() -> void:
	set_timing_offsets(DEFAULT_INPUT_OFFSET_MS, DEFAULT_AUDIO_OFFSET_MS)


static func reset_all() -> void:
	# Reset user-adjustable preferences only. Onboarding completion and Song
	# Library continuity are state, not visual/audio/timing defaults, so they are
	# preserved instead of being silently deleted.
	var config := load_config()
	config.set_value("audio", "master_volume", DEFAULT_MASTER_VOLUME)
	config.set_value("audio", "menu_sfx_volume", DEFAULT_MENU_SFX_VOLUME)
	config.set_value("audio", "menu_sfx_enabled", DEFAULT_MENU_SFX_ENABLED)
	config.set_value("visual", "background_opacity", DEFAULT_BG_OPACITY)
	config.set_value("visual", "effect_intensity", DEFAULT_EFFECT_INTENSITY)
	for action_value: Variant in DEFAULT_GAMEPLAY_BINDINGS.keys():
		var action: String = str(action_value)
		config.set_value("controls", action, int(DEFAULT_GAMEPLAY_BINDINGS[action]))
	config.set_value("timing", "input_offset_ms", DEFAULT_INPUT_OFFSET_MS)
	config.set_value("timing", "audio_offset_ms", DEFAULT_AUDIO_OFFSET_MS)
	config.set_value("display", "resolution_width", DEFAULT_RESOLUTION.x)
	config.set_value("display", "resolution_height", DEFAULT_RESOLUTION.y)
	config.set_value("display", "window_mode", DEFAULT_WINDOW_MODE)
	config.set_value("display", "vsync_enabled", DEFAULT_VSYNC_ENABLED)
	config.set_value("gameplay", "input_style", DEFAULT_INPUT_STYLE)
	config.set_value("gameplay", "note_travel_time", DEFAULT_NOTE_TRAVEL_TIME)
	_save_config(config)
	apply_master_volume(DEFAULT_MASTER_VOLUME)
	apply_display_settings(DEFAULT_RESOLUTION, DEFAULT_WINDOW_MODE, DEFAULT_VSYNC_ENABLED)


static func set_input_style(style: String) -> void:
	var safe_style := style.to_lower()
	if not VALID_INPUT_STYLES.has(safe_style):
		safe_style = DEFAULT_INPUT_STYLE
	var config := load_config()
	config.set_value("gameplay", "input_style", safe_style)
	_save_config(config)


static func set_display_settings(resolution: Vector2i, window_mode: String, vsync_enabled: bool) -> bool:
	var safe_mode := window_mode.to_lower()
	if not VALID_WINDOW_MODES.has(safe_mode):
		safe_mode = DEFAULT_WINDOW_MODE
	var safe_resolution := Vector2i(
		clampi(resolution.x, MIN_RESOLUTION.x, MAX_RESOLUTION.x),
		clampi(resolution.y, MIN_RESOLUTION.y, MAX_RESOLUTION.y)
	)
	var config := load_config()
	config.set_value("display", "resolution_width", safe_resolution.x)
	config.set_value("display", "resolution_height", safe_resolution.y)
	config.set_value("display", "window_mode", safe_mode)
	config.set_value("display", "vsync_enabled", vsync_enabled)
	_save_config(config)
	return apply_display_settings(safe_resolution, safe_mode, vsync_enabled)


static func apply_display_preferences() -> bool:
	return apply_display_settings(get_resolution(), get_window_mode(), get_vsync_enabled())


static func is_game_embedded() -> bool:
	# Godot 4.7 game embedding deliberately blocks window mode / window flag
	# changes. Settings are still saved so the exported/standalone build can
	# apply them on the next launch.
	return Engine.is_embedded_in_editor()


static func apply_display_settings(resolution: Vector2i, window_mode: String, vsync_enabled: bool) -> bool:
	DisplayServer.window_set_vsync_mode((DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED) as DisplayServer.VSyncMode)

	var safe_mode := window_mode.to_lower()
	if not VALID_WINDOW_MODES.has(safe_mode):
		safe_mode = DEFAULT_WINDOW_MODE
	var safe_resolution := Vector2i(
		clampi(resolution.x, MIN_RESOLUTION.x, MAX_RESOLUTION.x),
		clampi(resolution.y, MIN_RESOLUTION.y, MAX_RESOLUTION.y)
	)

	if is_game_embedded():
		return false

	var screen_index: int = DisplayServer.window_get_current_screen()
	var screen_size: Vector2i = DisplayServer.screen_get_size(screen_index)
	var screen_position: Vector2i = DisplayServer.screen_get_position(screen_index)

	match safe_mode:
		"borderless":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			if screen_size.x > 0 and screen_size.y > 0:
				DisplayServer.window_set_size(screen_size)
				DisplayServer.window_set_position(screen_position)
		"fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"windowed":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_size(safe_resolution)
			_center_window(safe_resolution)
		_:
			return false
	return true


static func get_runtime_display_summary() -> String:
	if is_game_embedded():
		return "EDITOR EMBEDDED PREVIEW"
	var mode: int = DisplayServer.window_get_mode()
	var mode_label := "WINDOWED"
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		mode_label = "FULLSCREEN"
	elif mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		mode_label = "EXCLUSIVE FULLSCREEN"
	elif DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS):
		mode_label = "BORDERLESS"
	var actual_size: Vector2i = DisplayServer.window_get_size()
	return "%s • %d × %d" % [mode_label, actual_size.x, actual_size.y]


static func _center_window(window_size: Vector2i) -> void:
	var screen_index: int = DisplayServer.window_get_current_screen()
	var screen_position: Vector2i = DisplayServer.screen_get_position(screen_index)
	var screen_size: Vector2i = DisplayServer.screen_get_size(screen_index)
	if screen_size.x <= 0 or screen_size.y <= 0:
		return
	var centered_position: Vector2i = screen_position + Vector2i(
		floori(float(screen_size.x - window_size.x) / 2.0),
		floori(float(screen_size.y - window_size.y) / 2.0)
	)
	DisplayServer.window_set_position(centered_position)


static func apply_master_volume(value: float) -> void:
	var master_index := AudioServer.get_bus_index("Master")
	if master_index < 0:
		return
	if value <= 0.0:
		AudioServer.set_bus_mute(master_index, true)
	else:
		AudioServer.set_bus_mute(master_index, false)
		AudioServer.set_bus_volume_db(master_index, linear_to_db(clampf(value, 0.0, 100.0) / 100.0))


static func save_all(master_volume: float, background_opacity: float, menu_sfx_volume: float = DEFAULT_MENU_SFX_VOLUME, menu_sfx_enabled: bool = DEFAULT_MENU_SFX_ENABLED) -> void:
	var config := load_config()
	config.set_value("audio", "master_volume", clampf(master_volume, 0.0, 100.0))
	config.set_value("audio", "menu_sfx_volume", clampf(menu_sfx_volume, 0.0, 100.0))
	config.set_value("audio", "menu_sfx_enabled", menu_sfx_enabled)
	config.set_value("visual", "background_opacity", clampf(background_opacity, 0.0, 100.0))
	_save_config(config)
	apply_master_volume(master_volume)


static func _read_float(config: ConfigFile, section: String, key: String, default_value: float, minimum: float, maximum: float) -> float:
	var raw: Variant = config.get_value(section, key, default_value)
	var value := default_value
	if raw is int or raw is float:
		value = float(raw)
	elif raw is String:
		var text := str(raw).strip_edges()
		if text.is_valid_float():
			value = text.to_float()
	if not is_finite(value):
		value = default_value
	return clampf(value, minimum, maximum)


static func _read_int(config: ConfigFile, section: String, key: String, default_value: int, minimum: int, maximum: int) -> int:
	var raw: Variant = config.get_value(section, key, default_value)
	var value := default_value
	if raw is int or raw is float:
		value = int(raw)
	elif raw is String:
		var text := str(raw).strip_edges()
		if text.is_valid_int():
			value = text.to_int()
	return clampi(value, minimum, maximum)


static func _read_bool(config: ConfigFile, section: String, key: String, default_value: bool) -> bool:
	var raw: Variant = config.get_value(section, key, default_value)
	if raw is bool:
		return bool(raw)
	if raw is int or raw is float:
		return float(raw) != 0.0
	if raw is String:
		var text := str(raw).strip_edges().to_lower()
		if ["true", "1", "yes", "on"].has(text):
			return true
		if ["false", "0", "no", "off"].has(text):
			return false
	return default_value


static func _read_string(config: ConfigFile, section: String, key: String, default_value: String) -> String:
	var raw: Variant = config.get_value(section, key, default_value)
	return str(raw) if raw is String else default_value


static func _set_if_changed(config: ConfigFile, section: String, key: String, value: Variant) -> bool:
	if config.has_section_key(section, key):
		var previous: Variant = config.get_value(section, key)
		# Comparing incompatible Variants (e.g. malformed String vs float) throws.
		if typeof(previous) == typeof(value) and previous == value:
			return false
	config.set_value(section, key, value)
	return true


static func _quarantine_corrupt_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	_remove_file_if_exists(SETTINGS_CORRUPT_PATH)
	var err := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(SETTINGS_PATH),
		ProjectSettings.globalize_path(SETTINGS_CORRUPT_PATH)
	)
	if err != OK:
		push_warning("Beat UP! settings: could not quarantine corrupted settings (error %d)." % err)


static func _remove_file_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

static func _report_runtime(level: String, category: String, message: String, context: Dictionary = {}) -> void:
	var loop: MainLoop = Engine.get_main_loop()
	if not (loop is SceneTree):
		return
	var tree: SceneTree = loop as SceneTree
	var guard: Node = tree.root.get_node_or_null("RuntimeGuard")
	if guard == null:
		return
	if level == "error" and guard.has_method("error"):
		guard.call("error", category, message, context)
	elif level == "warning" and guard.has_method("warning"):
		guard.call("warning", category, message, context)
	elif guard.has_method("report"):
		guard.call("report", category, message, context)
