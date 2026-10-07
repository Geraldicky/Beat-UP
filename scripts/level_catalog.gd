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
var _authoritative_claims: Dictionary = {}
var _launch_thread: Thread
var _launch_worker: Node

# The worker owns an off-tree catalog, never the live scene/catalog state.
# Publish its result only after joining; UI remains on the main thread.
func resolve_playable_async(song_id: String, difficulty_id: String) -> Dictionary:
	if _launch_thread != null:
		return {"ok": false, "error": "Chart preparation is already active."}
	_launch_worker = get_script().new() as Node
	_launch_worker.set("level_files", level_files.duplicate())
	_launch_worker.set("scan_roots", scan_roots.duplicate())
	_launch_thread = Thread.new()
	var error := _launch_thread.start(Callable(_launch_worker, "resolve_playable").bind(song_id, difficulty_id, true))
	if error != OK:
		_release_launch_worker()
		return {"ok": false, "error": "Could not start chart preparation."}
	while _launch_thread.is_alive():
		await get_tree().process_frame
	var resolution: Dictionary = _launch_thread.wait_to_finish() as Dictionary
	_cache = _launch_worker.get("_cache") as Array
	_authoritative_claims = _launch_worker.get("_authoritative_claims") as Dictionary
	_release_launch_worker()
	return resolution

func _release_launch_worker() -> void:
	if _launch_thread != null and _launch_thread.is_started():
		_launch_thread.wait_to_finish()
	_launch_thread = null
	if is_instance_valid(_launch_worker):
		_launch_worker.free()
	_launch_worker = null

func _exit_tree() -> void:
	_release_launch_worker()

func load_all(force_refresh: bool = false) -> Array:
	if not force_refresh and not _cache.is_empty():
		return _cache
	_cache.clear()
	_authoritative_claims.clear()
	var discovered_paths: Array[String] = []
	for path in level_files:
		if not discovered_paths.has(path):
			discovered_paths.append(path)
	for root in scan_roots:
		_scan_json_recursive(root, discovered_paths)
	discovered_paths.sort()

	var canonical_by_identity: Dictionary = {}
	for path in discovered_paths:
		var source_kind: String = _source_kind(path)
		var path_identity: String = _managed_path_identity(path, source_kind)
		var load_result: Dictionary = _load_level_file_result(path)
		if not bool(load_result.get("ok", false)):
			# A malformed file may claim authority only through a canonical managed
			# user path. Arbitrary files never receive guessed identities.
			if not path_identity.is_empty() and FileAccess.file_exists(path):
				_register_authoritative_claim(path_identity, {
					"_catalog_path": path,
					"_catalog_source": source_kind,
					"_catalog_identity": path_identity,
					"_catalog_error": str(load_result.get("error", "Chart could not be read.")),
				})
			continue
		var level: Dictionary = load_result.get("chart", {}) as Dictionary
		level["_catalog_path"] = path
		level["_catalog_source"] = source_kind
		var identity: String = _logical_identity(level)
		if not path_identity.is_empty() and identity != path_identity:
			_register_authoritative_claim(path_identity, {
				"_catalog_path": path,
				"_catalog_source": source_kind,
				"_catalog_identity": path_identity,
				"_catalog_error": "Chart identity does not match its managed user path.",
			})
			continue
		if identity.is_empty():
			continue
		level["_catalog_identity"] = identity
		_register_authoritative_claim(identity, level)
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
	load_all(force_refresh)
	var claim_value: Variant = _authoritative_claims.get(target_identity, {})
	if claim_value is Dictionary and not (claim_value as Dictionary).is_empty():
		var level: Dictionary = claim_value as Dictionary
		var source_path: String = str(level.get("_catalog_path", ""))
		var source_kind: String = str(level.get("_catalog_source", "other"))
		var catalog_error: String = str(level.get("_catalog_error", ""))
		if not catalog_error.is_empty():
			return _resolution_failure(catalog_error, safe_song_id, safe_difficulty_id, source_path, source_kind)

		var validation: Dictionary = ChartIntegrityScript.validate_structure(level)
		if not bool(validation.get("ok", false)):
			return _resolution_failure("; ".join(validation.get("errors", [])), safe_song_id, safe_difficulty_id, source_path, source_kind)
		var audio_path: String = str(level.get("audio", ""))
		if audio_path.is_empty() or not RuntimeResourceAccessScript.audio_exists(audio_path):
			return _resolution_failure("Audio missing. Install or re-import the matching audio file.", safe_song_id, safe_difficulty_id, source_path, source_kind)
		var audio_stream: AudioStream = _load_audio_stream(audio_path)
		if audio_stream == null:
			return _resolution_failure("Audio exists but could not be loaded.", safe_song_id, safe_difficulty_id, source_path, source_kind)

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
			"audio_stream": audio_stream,
		}

	return {
		"ok": false,
		"error": "Chart not found for %s / %s." % [safe_song_id, safe_difficulty_id],
		"song_id": safe_song_id,
		"difficulty_id": safe_difficulty_id,
	}

func load_level_file(path: String) -> Dictionary:
	var result: Dictionary = _load_level_file_result(path)
	return result.get("chart", {}) as Dictionary if bool(result.get("ok", false)) else {}

func _load_level_file_result(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "Chart file does not exist."}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Chart file could not be read."}
	var text: String = file.get_as_text()
	file.close()
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return {"ok": false, "error": "Malformed chart JSON: %s" % parser.get_error_message()}
	var parsed: Variant = parser.data
	if not (parsed is Dictionary):
		return {"ok": false, "error": "Chart JSON root must be an object."}
	var data: Dictionary = parsed
	if not data.has("events"):
		return {"ok": false, "error": "Chart JSON does not contain events."}
	data["_source_chart_hash"] = ScoreIdentity.chart_hash(data)
	return {"ok": true, "chart": ChartIntegrityScript.decorate_chart(data)}

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

func _managed_path_identity(path: String, source_kind: String) -> String:
	if source_kind == "user_songs":
		var relative: String = path.trim_prefix("user://songs/")
		var parts: PackedStringArray = relative.split("/", false)
		if parts.size() != 2 or parts[1].get_extension().to_lower() != "json":
			return ""
		var raw_song_id: String = parts[0]
		var raw_difficulty_id: String = parts[1].get_basename()
		var song_id: String = _sanitize_id(raw_song_id)
		var difficulty_id: String = _sanitize_id(raw_difficulty_id).to_lower()
		if song_id != raw_song_id.to_lower() or difficulty_id != raw_difficulty_id.to_lower():
			return ""
		if song_id.is_empty() or not ALLOWED_DIFFICULTIES.has(difficulty_id):
			return ""
		return "%s::%s" % [song_id, difficulty_id]
	if source_kind == "user_exports":
		var relative: String = path.trim_prefix("user://chart_exports/")
		if relative.contains("/") or relative.get_extension().to_lower() != "json":
			return ""
		var basename: String = relative.get_basename()
		for difficulty_id: String in ALLOWED_DIFFICULTIES:
			var suffix := "_%s" % difficulty_id
			if not basename.to_lower().ends_with(suffix):
				continue
			var raw_song_id: String = basename.left(basename.length() - suffix.length())
			var song_id: String = _sanitize_id(raw_song_id)
			if not song_id.is_empty() and song_id == raw_song_id.to_lower():
				return "%s::%s" % [song_id, difficulty_id]
	return ""

func _register_authoritative_claim(identity: String, candidate: Dictionary) -> void:
	if identity.is_empty():
		return
	if not _authoritative_claims.has(identity) or _candidate_precedes(candidate, _authoritative_claims[identity] as Dictionary):
		_authoritative_claims[identity] = candidate

func _resolution_failure(error: String, song_id: String, difficulty_id: String, source_path: String, source_kind: String) -> Dictionary:
	return {
		"ok": false,
		"error": error,
		"song_id": song_id,
		"difficulty_id": difficulty_id,
		"source_path": source_path,
		"source_kind": source_kind,
	}

func _load_audio_stream(path: String) -> AudioStream:
	if path.is_empty():
		return null
	if path.begins_with("res://"):
		var imported_stream: AudioStream = load(path) as AudioStream
		if imported_stream != null:
			return imported_stream
	var filesystem_path: String = ProjectSettings.globalize_path(path) if path.begins_with("user://") or path.begins_with("res://") else path
	match filesystem_path.get_extension().to_lower():
		"ogg": return AudioStreamOggVorbis.load_from_file(filesystem_path)
		"mp3": return AudioStreamMP3.load_from_file(filesystem_path)
		"wav": return AudioStreamWAV.load_from_file(filesystem_path)
	return null

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
