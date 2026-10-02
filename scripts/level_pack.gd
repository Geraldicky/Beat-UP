extends RefCounted

# Portable, local-first Beat UP! level packs. Packs are ordinary ZIP archives
# with a different extension so players can share a complete custom song without
# exposing arbitrary archive extraction to the game.
const FORMAT_ID := "beatup-level-pack"
const FORMAT_VERSION := 1
const MAX_ARCHIVE_BYTES := 512 * 1024 * 1024
const MAX_AUDIO_BYTES := 384 * 1024 * 1024
const MAX_IMAGE_BYTES := 24 * 1024 * 1024
const MAX_CHART_BYTES := 8 * 1024 * 1024
const MAX_ENTRIES := 16
const ALLOWED_DIFFICULTIES := ["normal", "hard", "master"]
const ChartIntegrityScript = preload("res://scripts/chart_integrity.gd")
const ReliableJsonStoreScript = preload("res://scripts/reliable_json_store.gd")

static func import_pack(pack_path: String, overwrite: bool = false) -> Dictionary:
	if pack_path.is_empty() or not FileAccess.file_exists(pack_path):
		return {"ok": false, "error": "Level pack was not found."}
	if _file_size(pack_path) > MAX_ARCHIVE_BYTES:
		return {"ok": false, "error": "Level pack exceeds the 512 MB safety limit."}

	var reader := ZIPReader.new()
	var open_error: Error = reader.open(pack_path)
	if open_error != OK:
		return {"ok": false, "error": "Level pack is not a readable ZIP archive."}
	var entries: PackedStringArray = reader.get_files()
	if entries.size() > MAX_ENTRIES:
		reader.close()
		return {"ok": false, "error": "Level pack contains too many files."}
	var unique_entries: Dictionary = {}
	for entry: String in entries:
		if not _is_safe_entry(entry):
			reader.close()
			return {"ok": false, "error": "Unsafe archive path: %s" % entry}
		if unique_entries.has(entry):
			reader.close()
			return {"ok": false, "error": "Duplicate archive entry: %s" % entry}
		unique_entries[entry] = true
	if not entries.has("manifest.json"):
		reader.close()
		return {"ok": false, "error": "Level pack has no manifest.json."}

	var manifest_bytes: PackedByteArray = reader.read_file("manifest.json")
	if manifest_bytes.size() <= 0 or manifest_bytes.size() > MAX_CHART_BYTES:
		reader.close()
		return {"ok": false, "error": "Level pack manifest is empty or too large."}
	var manifest_value: Variant = JSON.parse_string(manifest_bytes.get_string_from_utf8())
	if not (manifest_value is Dictionary):
		reader.close()
		return {"ok": false, "error": "Level pack manifest is invalid JSON."}
	var manifest: Dictionary = manifest_value as Dictionary
	if str(manifest.get("format", "")) != FORMAT_ID or int(manifest.get("format_version", 0)) != FORMAT_VERSION:
		reader.close()
		return {"ok": false, "error": "Unsupported level-pack format version."}

	var song_value: Variant = manifest.get("song", {})
	if not (song_value is Dictionary):
		reader.close()
		return {"ok": false, "error": "Level pack song metadata is missing."}
	var song_meta: Dictionary = song_value as Dictionary
	var song_id: String = sanitize_id(str(song_meta.get("id", "")))
	if song_id.is_empty():
		reader.close()
		return {"ok": false, "error": "Level pack song ID is invalid."}

	var audio_entry: String = str(manifest.get("audio", ""))
	var audio_bytes := PackedByteArray()
	if not audio_entry.is_empty():
		if not entries.has(audio_entry) or not _allowed_audio_extension(audio_entry.get_extension()):
			reader.close()
			return {"ok": false, "error": "Level pack audio is missing or unsupported."}
		audio_bytes = reader.read_file(audio_entry)
		if audio_bytes.is_empty() or audio_bytes.size() > MAX_AUDIO_BYTES:
			reader.close()
			return {"ok": false, "error": "Level pack audio is empty or exceeds 384 MB."}

	var background_entry: String = str(manifest.get("background", ""))
	var background_bytes := PackedByteArray()
	if not background_entry.is_empty():
		if not entries.has(background_entry) or not _allowed_image_extension(background_entry.get_extension()):
			reader.close()
			return {"ok": false, "error": "Level pack artwork is missing or unsupported."}
		background_bytes = reader.read_file(background_entry)
		if background_bytes.is_empty() or background_bytes.size() > MAX_IMAGE_BYTES:
			reader.close()
			return {"ok": false, "error": "Level pack artwork is empty or exceeds 24 MB."}

	var chart_entries_value: Variant = manifest.get("charts", [])
	if not (chart_entries_value is Array):
		reader.close()
		return {"ok": false, "error": "Level pack chart list is invalid."}
	var prepared_charts: Array[Dictionary] = []
	var seen_difficulties: Array[String] = []
	for raw_entry: Variant in (chart_entries_value as Array):
		var chart_entry: String = str(raw_entry)
		if not chart_entry.begins_with("charts/") or not chart_entry.ends_with(".json") or not entries.has(chart_entry):
			reader.close()
			return {"ok": false, "error": "Invalid chart entry: %s" % chart_entry}
		var chart_bytes: PackedByteArray = reader.read_file(chart_entry)
		if chart_bytes.is_empty() or chart_bytes.size() > MAX_CHART_BYTES:
			reader.close()
			return {"ok": false, "error": "A chart is empty or exceeds 8 MB."}
		var chart_value: Variant = JSON.parse_string(chart_bytes.get_string_from_utf8())
		if not (chart_value is Dictionary):
			reader.close()
			return {"ok": false, "error": "Invalid chart JSON: %s" % chart_entry}
		var chart: Dictionary = (chart_value as Dictionary).duplicate(true)
		var difficulty: String = sanitize_id(str(chart.get("chart_difficulty", chart.get("difficulty", chart_entry.get_file().get_basename())))).to_lower()
		if not ALLOWED_DIFFICULTIES.has(difficulty) or seen_difficulties.has(difficulty):
			reader.close()
			return {"ok": false, "error": "Invalid or duplicate chart difficulty: %s" % difficulty}
		chart["song_id"] = song_id
		chart["chart_difficulty"] = difficulty
		if not audio_entry.is_empty():
			chart["audio"] = "user://songs/%s/%s" % [song_id, audio_entry.get_file()]
		if not background_entry.is_empty():
			chart["background"] = "user://songs/%s/%s" % [song_id, background_entry.get_file()]
		if not chart.has("title"):
			chart["title"] = str(song_meta.get("title", song_id.replace("_", " ")))
		if not chart.has("artist"):
			chart["artist"] = str(song_meta.get("artist", "Unknown Artist"))
		var report: Dictionary = ChartIntegrityScript.validate_structure(chart)
		if not bool(report.get("ok", false)):
			reader.close()
			return {"ok": false, "error": "%s: %s" % [difficulty.to_upper(), "; ".join(report.get("errors", []))]}
		seen_difficulties.append(difficulty)
		prepared_charts.append({"difficulty": difficulty, "chart": chart})
	reader.close()
	if prepared_charts.is_empty():
		return {"ok": false, "error": "Level pack contains no playable charts."}

	var destination_dir: String = "user://songs/%s" % song_id
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(destination_dir)) and not overwrite:
		return {"ok": false, "error": "%s is already installed. Remove it before importing another revision." % song_id}
	for prepared: Dictionary in prepared_charts:
		var chart_path: String = destination_dir.path_join(str(prepared.get("difficulty", "")) + ".json")
		if FileAccess.file_exists(chart_path) and not overwrite:
			return {"ok": false, "error": "%s already exists. Remove it or explicitly overwrite it." % chart_path}
	var install_dir: String = destination_dir
	if not overwrite:
		install_dir = "user://songs/.install_%s_%d" % [song_id, Time.get_ticks_msec()]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(install_dir))
	if not audio_entry.is_empty() and not _write_bytes_atomic(install_dir.path_join(audio_entry.get_file()), audio_bytes):
		_remove_tree(install_dir)
		return {"ok": false, "error": "Could not install level-pack audio."}
	if not background_entry.is_empty() and not _write_bytes_atomic(install_dir.path_join(background_entry.get_file()), background_bytes):
		_remove_tree(install_dir)
		return {"ok": false, "error": "Could not install level-pack artwork."}
	for prepared: Dictionary in prepared_charts:
		var difficulty: String = str(prepared.get("difficulty", ""))
		if not ReliableJsonStoreScript.save_dictionary_atomic(install_dir.path_join(difficulty + ".json"), prepared.get("chart", {}) as Dictionary):
			_remove_tree(install_dir)
			return {"ok": false, "error": "Could not install %s chart." % difficulty.to_upper()}
	if not ReliableJsonStoreScript.save_dictionary_atomic(install_dir.path_join("pack_manifest.json"), manifest):
		_remove_tree(install_dir)
		return {"ok": false, "error": "Could not install the level-pack manifest."}
	if not overwrite:
		var rename_error: Error = DirAccess.rename_absolute(ProjectSettings.globalize_path(install_dir), ProjectSettings.globalize_path(destination_dir))
		if rename_error != OK:
			_remove_tree(install_dir)
			return {"ok": false, "error": "Could not finalize the level-pack installation."}
	return {"ok": true, "song_id": song_id, "difficulties": seen_difficulties, "path": destination_dir}

static func export_song(song_id_value: String, output_path: String, include_audio: bool = true) -> Dictionary:
	var song_id: String = sanitize_id(song_id_value)
	if song_id.is_empty():
		return {"ok": false, "error": "Invalid song ID."}
	var source_dir: String = "user://songs/%s" % song_id
	var directory := DirAccess.open(source_dir)
	if directory == null:
		return {"ok": false, "error": "Only locally installed custom songs can be exported."}
	var charts: Array[Dictionary] = []
	var title: String = song_id.replace("_", " ")
	var artist := "Unknown Artist"
	var audio_path := ""
	var background_path := ""
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while not entry.is_empty():
		if not directory.current_is_dir() and entry.get_extension().to_lower() == "json" and entry != "pack_manifest.json":
			var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(source_dir.path_join(entry)))
			if value is Dictionary:
				var chart: Dictionary = value as Dictionary
				var report: Dictionary = ChartIntegrityScript.validate_structure(chart)
				if bool(report.get("ok", false)):
					charts.append({"name": entry, "data": chart})
					title = str(chart.get("title", title))
					artist = str(chart.get("artist", artist))
					audio_path = str(chart.get("audio", audio_path))
					background_path = str(chart.get("background", background_path))
		entry = directory.get_next()
	directory.list_dir_end()
	if charts.is_empty():
		return {"ok": false, "error": "Custom song has no valid charts."}
	if include_audio and (audio_path.is_empty() or not FileAccess.file_exists(audio_path)):
		return {"ok": false, "error": "Custom song audio is missing."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_path.get_base_dir()))
	var packer := ZIPPacker.new()
	var open_error: Error = packer.open(ProjectSettings.globalize_path(output_path))
	if open_error != OK:
		return {"ok": false, "error": "Could not create the level pack."}
	var chart_entries: Array[String] = []
	for prepared: Dictionary in charts:
		var packed_name: String = "charts/%s" % str(prepared.get("name", "chart.json"))
		chart_entries.append(packed_name)
		if not _pack_bytes(packer, packed_name, JSON.stringify(prepared.get("data", {}), "\t").to_utf8_buffer()):
			packer.close()
			return {"ok": false, "error": "Could not add a chart to the level pack."}
	var packed_audio := ""
	if include_audio:
		packed_audio = "audio.%s" % audio_path.get_extension().to_lower()
		if not _pack_bytes(packer, packed_audio, FileAccess.get_file_as_bytes(audio_path)):
			packer.close()
			return {"ok": false, "error": "Could not add audio to the level pack."}
	var packed_background := ""
	if not background_path.is_empty() and FileAccess.file_exists(background_path):
		packed_background = "background.%s" % background_path.get_extension().to_lower()
		if not _pack_bytes(packer, packed_background, FileAccess.get_file_as_bytes(background_path)):
			packer.close()
			return {"ok": false, "error": "Could not add artwork to the level pack."}
	var manifest: Dictionary = {
		"format": FORMAT_ID,
		"format_version": FORMAT_VERSION,
		"created_with": str(ProjectSettings.get_setting("application/config/version", "unknown")),
		"song": {"id": song_id, "title": title, "artist": artist},
		"charts": chart_entries,
		"audio": packed_audio,
		"background": packed_background,
		"includes_audio": include_audio,
		"distribution_notice": "The exporter is responsible for having permission to share included audio and artwork.",
	}
	if not _pack_bytes(packer, "manifest.json", JSON.stringify(manifest, "\t").to_utf8_buffer()):
		packer.close()
		return {"ok": false, "error": "Could not add the level-pack manifest."}
	packer.close()
	return {"ok": true, "path": output_path, "song_id": song_id, "charts": charts.size(), "includes_audio": include_audio}

static func sanitize_id(value: String) -> String:
	var result := ""
	var allowed := "abcdefghijklmnopqrstuvwxyz0123456789_"
	for character: String in value.to_lower():
		if allowed.contains(character):
			result += character
		elif character in ["-", " ", "."]:
			result += "_"
	while "__" in result:
		result = result.replace("__", "_")
	return result.trim_prefix("_").trim_suffix("_").left(80)

static func _is_safe_entry(entry: String) -> bool:
	var normalized: String = entry.replace("\\", "/")
	return not normalized.is_empty() and not normalized.begins_with("/") and not normalized.contains(":") and not normalized.split("/").has("..")

static func _allowed_audio_extension(extension: String) -> bool:
	return extension.to_lower() in ["ogg", "mp3", "wav"]

static func _allowed_image_extension(extension: String) -> bool:
	return extension.to_lower() in ["png", "jpg", "jpeg", "webp"]

static func _file_size(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return -1
	var length: int = file.get_length()
	file.close()
	return length

static func _write_bytes_atomic(path: String, bytes: PackedByteArray) -> bool:
	var temporary_path := path + ".tmp"
	if FileAccess.file_exists(temporary_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_path))
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_buffer(bytes)
	file.flush()
	file.close()
	if _file_size(temporary_path) != bytes.size():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_path))
		return false
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary_path), ProjectSettings.globalize_path(path)) == OK

static func _pack_bytes(packer: ZIPPacker, path: String, bytes: PackedByteArray) -> bool:
	if bytes.is_empty() or packer.start_file(path) != OK:
		return false
	var write_error: Error = packer.write_file(bytes)
	var close_error: Error = packer.close_file()
	return write_error == OK and close_error == OK

static func _remove_tree(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while not entry.is_empty():
		var child: String = path.path_join(entry)
		if directory.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(child))
		entry = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
