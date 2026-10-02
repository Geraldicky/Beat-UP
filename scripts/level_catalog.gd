extends Node
class_name LevelCatalog
const ScoreIdentity = preload("res://scripts/score_identity.gd")

const ChartIntegrityScript = preload("res://scripts/chart_integrity.gd")
const LevelPackScript = preload("res://scripts/level_pack.gd")
const MAX_CHART_FILE_BYTES := 8 * 1024 * 1024
const MAX_IMPORTED_AUDIO_BYTES := 384 * 1024 * 1024
const ALLOWED_DIFFICULTIES := ["normal", "hard", "master"]

@export var level_files: PackedStringArray = PackedStringArray()
@export var scan_roots: PackedStringArray = PackedStringArray([
	"res://charts",
	"user://songs",
	"user://chart_exports",
])

var _cache: Array = []

func load_all(force_refresh: bool = false) -> Array:
	if not force_refresh and not _cache.is_empty():
		return _cache
	_cache.clear()
	var discovered_paths: Array[String] = []
	for path in level_files:
		if not discovered_paths.has(path):
			discovered_paths.append(path)
	for root in scan_roots:
		_scan_json_recursive(root, discovered_paths)

	for path in discovered_paths:
		var level: Dictionary = load_level_file(path)
		if not level.is_empty():
			level["_catalog_path"] = path
			_cache.append(level)
	return _cache

func refresh() -> Array:
	return load_all(true)

func get_level(index: int) -> Dictionary:
	var all_levels: Array = load_all()
	if index < 0 or index >= all_levels.size():
		return {}
	return all_levels[index]

func load_level_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		return {}
	var data: Dictionary = parsed
	if not data.has("events"):
		return {}
	data["_source_chart_hash"] = ScoreIdentity.chart_hash(data)
	return ChartIntegrityScript.decorate_chart(data)

func import_chart_files(source_paths: PackedStringArray) -> Dictionary:
	var imported: int = 0
	var failed: Array[String] = []
	var imported_song_ids: Array[String] = []
	for source_path in source_paths:
		var result: Dictionary = import_chart_file(source_path)
		if bool(result.get("ok", false)):
			imported += 1
			var song_id: String = str(result.get("song_id", ""))
			if not song_id.is_empty() and not imported_song_ids.has(song_id):
				imported_song_ids.append(song_id)
		else:
			failed.append("%s: %s" % [source_path.get_file(), str(result.get("error", "Import failed"))])
	refresh()
	return {
		"ok": imported > 0,
		"imported": imported,
		"failed": failed,
		"song_ids": imported_song_ids,
	}

func import_chart_file(source_path: String) -> Dictionary:
	if source_path.is_empty() or not FileAccess.file_exists(source_path):
		return {"ok": false, "error": "Chart file not found."}
	if source_path.get_extension().to_lower() == "beatup-pack":
		return LevelPackScript.import_pack(source_path)
	if _file_size(source_path) > MAX_CHART_FILE_BYTES:
		return {"ok": false, "error": "Chart JSON exceeds the 8 MB safety limit."}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(source_path))
	if not (parsed is Dictionary):
		return {"ok": false, "error": "Invalid JSON."}
	var data: Dictionary = parsed
	if not data.has("events"):
		return {"ok": false, "error": "JSON does not contain an events array."}

	var report: Dictionary = ChartIntegrityScript.validate_structure(data)
	if not bool(report.get("ok", false)):
		return {"ok": false, "error": "; ".join(report.get("errors", []))}
	var import_audio: String = str(data.get("audio", ""))
	var resolved_audio: String = import_audio if import_audio.is_absolute_path() or import_audio.begins_with("res://") or import_audio.begins_with("user://") else source_path.get_base_dir().path_join(import_audio)
	if import_audio.is_empty() or not FileAccess.file_exists(resolved_audio):
		return {"ok": false, "error": "Audio missing. Keep audio beside the chart or install its Audio Pack."}
	var fallback_id: String = source_path.get_file().get_basename().to_snake_case()
	var song_id: String = _sanitize_id(str(data.get("song_id", data.get("id", fallback_id))))
	if song_id.is_empty():
		song_id = fallback_id
	var difficulty_id: String = _sanitize_id(str(data.get("chart_difficulty", data.get("difficulty", "normal"))).to_lower())
	if not ALLOWED_DIFFICULTIES.has(difficulty_id):
		return {"ok": false, "error": "Difficulty must be normal, hard, or master."}
	data["song_id"] = song_id
	data["chart_difficulty"] = difficulty_id
	if not data.has("title"):
		data["title"] = song_id.replace("_", " ").to_upper()
	if not data.has("artist"):
		data["artist"] = "Unknown Artist"

	var destination_dir: String = "user://songs/%s" % song_id
	if FileAccess.file_exists(destination_dir.path_join(difficulty_id + ".json")):
		return {"ok": false, "error": "Chart already exists. Use a different song ID to import another revision."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination_dir))
	var audio_path: String = str(data.get("audio", ""))
	if not audio_path.is_empty():
		var normalized_audio: String = _import_audio_reference(source_path, audio_path, destination_dir)
		if normalized_audio.is_empty():
			return {"ok": false, "error": "Audio copy failed or a different audio file already exists for this song."}
		data["audio"] = normalized_audio

	var destination_path: String = "%s/%s.json" % [destination_dir, difficulty_id]
	if not preload("res://scripts/reliable_json_store.gd").save_dictionary_atomic(destination_path, data):
		return {"ok": false, "error": "Could not save chart."}
	return {"ok": true, "song_id": song_id, "difficulty": difficulty_id, "path": destination_path}

func _import_audio_reference(chart_source_path: String, audio_path: String, destination_dir: String) -> String:
	if audio_path.begins_with("res://") or audio_path.begins_with("user://"):
		return audio_path
	var resolved: String = audio_path
	if not audio_path.is_absolute_path():
		resolved = chart_source_path.get_base_dir().path_join(audio_path)
	if not FileAccess.file_exists(resolved):
		return ""
	if _file_size(resolved) > MAX_IMPORTED_AUDIO_BYTES:
		return ""
	var extension: String = resolved.get_extension().to_lower()
	if not ["ogg", "mp3", "wav"].has(extension):
		return ""
	var destination_path: String = "%s/%s" % [destination_dir, resolved.get_file()]
	if FileAccess.file_exists(destination_path):
		return destination_path if FileAccess.get_sha256(destination_path) == FileAccess.get_sha256(resolved) else ""
	if resolved != ProjectSettings.globalize_path(destination_path):
		var input: FileAccess = FileAccess.open(resolved, FileAccess.READ)
		if input == null:
			return ""
		var bytes: PackedByteArray = input.get_buffer(input.get_length())
		input.close()
		if bytes.is_empty():
			return ""
		var output: FileAccess = FileAccess.open(destination_path, FileAccess.WRITE)
		if output == null:
			return ""
		output.store_buffer(bytes)
		output.close()
	return destination_path

func export_song_pack(song_id: String, include_audio: bool = true) -> Dictionary:
	var safe_id: String = _sanitize_id(song_id)
	if safe_id.is_empty():
		return {"ok": false, "error": "Invalid song ID."}
	var export_root := "user://level_packs"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(export_root))
	return LevelPackScript.export_song(safe_id, export_root.path_join(safe_id + ".beatup-pack"), include_audio)

func _file_size(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return -1
	var length: int = file.get_length()
	file.close()
	return length

func _scan_json_recursive(root: String, output: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(root)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var entry_name: String = dir.get_next()
		if entry_name.is_empty():
			break
		if entry_name.begins_with("."):
			continue
		var full_path: String = root.path_join(entry_name)
		if dir.current_is_dir():
			_scan_json_recursive(full_path, output)
		elif entry_name.get_extension().to_lower() == "json" and not output.has(full_path):
			output.append(full_path)
	dir.list_dir_end()

func _sanitize_id(value: String) -> String:
	var result: String = ""
	var allowed: String = "abcdefghijklmnopqrstuvwxyz0123456789_"
	for character in value.to_lower():
		if allowed.contains(character):
			result += character
		elif character == "-" or character == " " or character == ".":
			result += "_"
	while "__" in result:
		result = result.replace("__", "_")
	return result.trim_prefix("_").trim_suffix("_")
