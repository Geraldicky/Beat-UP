extends RefCounted
class_name ReliableJsonStore

# Small atomic JSON persistence helper used by Beta save data. A successful
# write keeps the previous valid file as <path>.bak. If the primary file is
# unreadable on the next launch, it is quarantined and the backup is restored.

static func load_dictionary(path: String) -> Dictionary:
	var primary := _try_load_dictionary(path)
	if bool(primary.get("ok", false)):
		return {
			"data": primary.get("data", {}),
			"recovered": false,
			"source": "primary",
		}

	var primary_exists: bool = bool(primary.get("exists", false))
	if primary_exists:
		push_warning("Beat UP! save data: primary JSON is unreadable: %s" % path)
		_quarantine(path)

	var backup_path := _backup_path(path)
	var backup := _try_load_dictionary(backup_path)
	if bool(backup.get("ok", false)):
		var recovered_data: Dictionary = backup.get("data", {}) as Dictionary
		if not save_dictionary_atomic(path, recovered_data, false):
			push_warning("Beat UP! save data: backup loaded, but primary restore failed for %s" % path)
		return {
			"data": recovered_data,
			"recovered": true,
			"source": "backup",
		}

	return {
		"data": {},
		"recovered": false,
		"source": "default",
	}


static func save_dictionary_atomic(path: String, data: Dictionary, rotate_backup: bool = true) -> bool:
	var temp_path := _temp_path(path)
	_remove_if_exists(temp_path)

	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("Beat UP! save data: failed to open temporary save file: %s" % temp_path)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	file.close()

	var verification := _try_load_dictionary(temp_path)
	if not bool(verification.get("ok", false)):
		push_error("Beat UP! save data: temporary JSON verification failed: %s" % temp_path)
		_remove_if_exists(temp_path)
		return false

	var backup_path := _backup_path(path)
	var had_primary := FileAccess.file_exists(path)
	if had_primary and rotate_backup:
		_remove_if_exists(backup_path)
		var rotate_err := DirAccess.rename_absolute(
			ProjectSettings.globalize_path(path),
			ProjectSettings.globalize_path(backup_path)
		)
		if rotate_err != OK:
			push_error("Beat UP! save data: failed to rotate backup for %s (error %d)." % [path, rotate_err])
			_remove_if_exists(temp_path)
			return false
	elif had_primary:
		# Recovery writes replace the quarantined/invalid primary without
		# rotating the known-good backup that was used to recover it.
		_remove_if_exists(path)

	var promote_err := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temp_path),
		ProjectSettings.globalize_path(path)
	)
	if promote_err == OK:
		return true

	push_error("Beat UP! save data: failed to promote temporary save for %s (error %d)." % [path, promote_err])
	_remove_if_exists(temp_path)
	if rotate_backup and FileAccess.file_exists(backup_path) and not FileAccess.file_exists(path):
		DirAccess.rename_absolute(
			ProjectSettings.globalize_path(backup_path),
			ProjectSettings.globalize_path(path)
		)
	return false


static func _try_load_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "exists": false, "data": {}}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "exists": true, "data": {}}
	var contents := file.get_as_text()
	file.close()

	var parser := JSON.new()
	var parse_err := parser.parse(contents)
	if parse_err != OK or not (parser.data is Dictionary):
		return {"ok": false, "exists": true, "data": {}}

	return {"ok": true, "exists": true, "data": parser.data}


static func _backup_path(path: String) -> String:
	return "%s.bak" % path


static func _temp_path(path: String) -> String:
	return "%s.tmp" % path


static func _corrupt_path(path: String) -> String:
	return "%s.corrupt" % path


static func _quarantine(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var corrupt_path := _corrupt_path(path)
	_remove_if_exists(corrupt_path)
	var err := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(path),
		ProjectSettings.globalize_path(corrupt_path)
	)
	if err != OK:
		push_warning("Beat UP! save data: could not quarantine %s (error %d)." % [path, err])


static func _remove_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
