extends Node
class_name BeatUpRuntimeGuard

const LOG_DIR := "user://logs"
const LOG_PATH := "user://logs/beta_runtime.log"
const MAX_LOG_BYTES := 1024 * 1024

func _ready() -> void:
	_ensure_log_dir()
	_rotate_if_needed()
	report("boot", "Beat UP! runtime guard initialized", {"version": str(ProjectSettings.get_setting("application/config/version", "unknown"))})

func report(category: String, message: String, context: Dictionary = {}) -> void:
	_write_line("INFO", category, message, context)

func warning(category: String, message: String, context: Dictionary = {}) -> void:
	push_warning("Beat UP! %s: %s" % [category, message])
	_write_line("WARN", category, message, context)

func error(category: String, message: String, context: Dictionary = {}) -> void:
	push_error("Beat UP! %s: %s" % [category, message])
	_write_line("ERROR", category, message, context)

func _write_line(level: String, category: String, message: String, context: Dictionary) -> void:
	_ensure_log_dir()
	_rotate_if_needed()
	var file := FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.seek_end()
	var payload := {
		"time_unix": int(Time.get_unix_time_from_system()),
		"level": level,
		"category": category,
		"message": message,
		"context": context,
	}
	file.store_line(JSON.stringify(payload))
	file.flush()
	file.close()

func _ensure_log_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(LOG_DIR))

func _rotate_if_needed() -> void:
	if not FileAccess.file_exists(LOG_PATH):
		return
	var file := FileAccess.open(LOG_PATH, FileAccess.READ)
	if file == null:
		return
	var length: int = file.get_length()
	file.close()
	if length <= MAX_LOG_BYTES:
		return
	var backup_path := "user://logs/beta_runtime.previous.log"
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))
	DirAccess.rename_absolute(ProjectSettings.globalize_path(LOG_PATH), ProjectSettings.globalize_path(backup_path))
