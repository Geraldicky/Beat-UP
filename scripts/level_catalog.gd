extends Node
class_name LevelCatalog
const ScoreIdentity = preload("res://scripts/score_identity.gd")

const ChartIntegrityScript = preload("res://scripts/chart_integrity.gd")
const LevelPackScript = preload("res://scripts/level_pack.gd")
const RuntimeResourceAccessScript = preload("res://scripts/runtime_resource_access.gd")
const MAX_CHART_FILE_BYTES := 8 * 1024 * 1024
const MAX_IMPORTED_AUDIO_BYTES := 384 * 1024 * 1024
const ALLOWED_DIFFICULTIES := ["normal", "hard", "master"]

# Higher values win when multiple files declare the same logical chart.
# Imported/custom songs are the primary writable source. Chart Studio exports
# override bundled charts when the project package is read-only.
const SOURCE_PRIORITY := {
	"user_songs": 300,
	"user_exports": 200,
	"bundled": 100,
	"other": 0,
}

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
	discovered_paths.sort()

	var canonical_by_identity: Dictionary = {}
	for path in discovered_paths:
		var level: Dictionary = load_level_file(path)
		if level.is_empty():
			continue
		level["_catalog_path"] = path
		level["_catalog_source"] = _source_kind(path)
		var identity: String = _logical_identity(level)
		if identity.is_empty():
			continue
		if not canonical_by_identity.has(identity) or _candidate_precedes(level, canonical_by_identity[identity] as Dictionary):
			canonical_by_identity[identity] = level

	for identity_value: Variant in canonical_by_identity.keys():
		_cache.append(canonical_by_identity[identity_value])
	_cache.sort_custom(_catalog_entry_less)
	return _cache

func refresh() -> Array:
	return load_all(true)

func get_level(index: int) -> Dictionary:
	var all_levels: Array = load_all()
	if index < 0 or index >= all_levels.size():
		return {}
	return all_levels[index]

func resolve_playable(song_id: String, difficulty_id: String, force_refresh: bool = false) -> Dictionary:
	var safe_song_id: String = _sanitize_id(song_id)
	var safe_difficulty_id: String = _sanitize_id(difficulty_id).to_lower()
	if safe_song_id.is_empty() or not ALLOWED_DIFFICULTIES.has(safe_difficulty_id):
		return {
			"ok": false,
			"error": "Invalid song or difficulty identity.",
			"song_id": safe_song_id,
			"difficulty_id": safe_difficulty_id,
		}

	var target_identity := "%s::%s" % [safe_song_id, safe_difficulty_id]
	for raw_level: Variant in load_all(force_refresh):
		if not (raw_level is Dictionary):
			continue
		var level: Dictionary = raw_level as Dictionary
		if _logical_identity(level) != target_identity:
			continue

		var validation: Dictionary = ChartIntegrityScript.validate_structure(level)
		if not bool(validation.get("ok", false)):
			return {
				"ok": false,
				"error": "; ".join(validation.get("errors", [])),
				"song_id": safe_song_id,
				"difficulty_id": safe_difficulty_id,
				"source_path": str(level.get("_catalog_path", "")),
			}
		var audio_path: String = str(level.get("audio", ""))
		if audio_path.is_empty() or not RuntimeResourceAccessScript.audio_exists(audio_path):
			return {
				"ok": false,
				"error": "Audio missing. Install or re-import the matching audio file.",
				"song_id": safe_song_id,
				"difficulty_id": safe_difficulty_id,
				"source_path": str(level.get("_catalog_path", "")),
			}

		var chart: Dictionary = level.duplicate(true)
		var source_hash: String = str(chart.get("_source_chart_hash", ""))
		if source_hash.is_empty():
			source_hash = ScoreIdentity.chart_hash(chart)
			chart["_source_chart_hash"] = source_hash
		return {
			"ok": true,
			"chart": chart,
			"song_id": safe_song_id,
			"difficulty_id": safe_difficulty_id,
			"source_path": str(chart.get("_catalog_path", "")),
			"source_kind": str(chart.get("_catalog_source", "other")),
			"source_hash": source_hash,
		}

	return {
		"ok": false,
		"error": "Chart not found for %s / %s." % [safe_song_id, safe_difficulty_id],
		"song_id": safe_song_id,
		"difficulty_id": safe_difficulty_id,
	}

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

func _logical_identity(chart: Dictionary) -> String:
	var song_id: String = _sanitize_id(str(chart.get("song_id", chart.get("id", ""))))
	var difficulty_id: String = _sanitize_id(str(chart.get("chart_difficulty", chart.get("difficulty", "")))).to_lower()
	if song_id.is_empty() or not ALLOWED_DIFFICULTIES.has(difficulty_id):
		return ""
	return "%s::%s" % [song_id, difficulty_id]

func _source_kind(path: String) -> String:
	if path.begins_with("user://songs/"):
		return "user_songs"
	if path.begins_with("user://chart_exports/"):
		return "user_exports"
	if path.begins_with("res://charts/"):
		return "bundled"
	return "other"

func _candidate_precedes(candidate: Dictionary, current: Dictionary) -> bool:
	var candidate_kind: String = str(candidate.get("_catalog_source", _source_kind(str(candidate.get("_catalog_path", "")))))
	var current_kind: String = str(current.get("_catalog_source", _source_kind(str(current.get("_catalog_path", "")))))
	var candidate_priority: int = int(SOURCE_PRIORITY.get(candidate_kind, 0))
	var current_priority: int = int(SOURCE_PRIORITY.get(current_kind, 0))
	if candidate_priority != current_priority:
		return candidate_priority > current_priority
	return str(candidate.get("_catalog_path", "")) < str(current.get("_catalog_path", ""))

func _catalog_entry_less(a: Dictionary, b: Dictionary) -> bool:
	var a_identity: String = _logical_identity(a)
	var b_identity: String = _logical_identity(b)
	if a_identity == b_identity:
		return str(a.get("_catalog_path", "")) < str(b.get("_catalog_path", ""))
	return a_identity < b_identity

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
