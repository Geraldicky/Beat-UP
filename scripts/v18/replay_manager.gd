extends Node
class_name BeatUpReplayManager

const ReliableJsonStoreScript = preload("res://scripts/reliable_json_store.gd")
const ScoreIdentity = preload("res://scripts/score_identity.gd")
const STORAGE_ROOT := "user://replays"
const SCHEMA_VERSION := 1

var _recording: bool = false
var _recording_data: Dictionary = {}
var _playback: bool = false
var _playback_data: Dictionary = {}
var _playback_cursor: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(STORAGE_ROOT))

func begin_recording(level_data: Dictionary, input_style: String, random_mode: bool, random_seed: int) -> void:
	stop_playback()
	_recording = true
	_recording_data = {
		"schema_version": SCHEMA_VERSION,
		"app_version": ScoreIdentity.app_version(),
		"score_identity": ScoreIdentity.identity(level_data, input_style, random_mode),
		"song_id": str(level_data.get("song_id", level_data.get("id", ""))),
		"title": str(level_data.get("title", "")),
		"difficulty": str(level_data.get("chart_difficulty", level_data.get("difficulty", "normal"))).to_lower(),
		"input_style": input_style,
		"random_mode": random_mode,
		"random_seed": random_seed,
		"created_unix_ms": int(round(Time.get_unix_time_from_system() * 1000.0)),
		"inputs": [],
		"result": {},
	}

func record_action(song_time_s: float, action: String, keycode: int) -> void:
	if not _recording or _playback or action.is_empty():
		return
	var inputs: Array = _recording_data.get("inputs", []) as Array
	inputs.append({
		"time_ms": int(round(maxf(0.0, song_time_s) * 1000.0)),
		"action": action,
		"keycode": keycode,
	})
	_recording_data["inputs"] = inputs

func finish_recording(result_snapshot: Dictionary) -> bool:
	if not _recording:
		return false
	_recording = false
	_recording_data["result"] = result_snapshot.duplicate(true)
	_recording_data["completed_unix_ms"] = int(round(Time.get_unix_time_from_system() * 1000.0))
	var path: String = _path_for_identity(_recording_data.get("score_identity", {}) as Dictionary)
	var saved: bool = ReliableJsonStoreScript.save_dictionary_atomic(path, _recording_data)
	_recording_data.clear()
	return saved

func abort_recording() -> void:
	_recording = false
	_recording_data.clear()

func has_latest(level_data: Dictionary, input_style: String, random_mode: bool) -> bool:
	return not load_latest(level_data, input_style, random_mode).is_empty()

func load_latest(level_data: Dictionary, input_style: String, random_mode: bool) -> Dictionary:
	var identity: Dictionary = ScoreIdentity.identity(level_data, input_style, random_mode)
	var result: Dictionary = ReliableJsonStoreScript.load_dictionary(_path_for_identity(identity))
	var raw: Variant = result.get("data", {})
	if not (raw is Dictionary):
		return {}
	var replay: Dictionary = (raw as Dictionary).duplicate(true)
	if not _identity_matches(identity, replay.get("score_identity", {}) as Dictionary):
		return {}
	return replay

func begin_playback(replay: Dictionary, level_data: Dictionary, input_style: String, random_mode: bool) -> bool:
	abort_recording()
	var expected: Dictionary = ScoreIdentity.identity(level_data, input_style, random_mode)
	var recorded: Dictionary = replay.get("score_identity", {}) as Dictionary
	if not _identity_matches(expected, recorded):
		return false
	var inputs_value: Variant = replay.get("inputs", [])
	if not (inputs_value is Array):
		return false
	_playback_data = replay.duplicate(true)
	_playback_cursor = 0
	_playback = true
	return true

func pop_due_actions(song_time_s: float) -> Array:
	var due: Array = []
	if not _playback:
		return due
	var inputs: Array = _playback_data.get("inputs", []) as Array
	var now_ms: int = int(round(maxf(0.0, song_time_s) * 1000.0)) + 2
	while _playback_cursor < inputs.size():
		var raw: Variant = inputs[_playback_cursor]
		if not (raw is Dictionary):
			_playback_cursor += 1
			continue
		var item: Dictionary = raw as Dictionary
		if int(item.get("time_ms", 0)) > now_ms:
			break
		due.append(item.duplicate(true))
		_playback_cursor += 1
	return due

func is_playing() -> bool:
	return _playback

func playback_finished() -> bool:
	if not _playback:
		return true
	var inputs: Array = _playback_data.get("inputs", []) as Array
	return _playback_cursor >= inputs.size()

func stop_playback() -> void:
	_playback = false
	_playback_data.clear()
	_playback_cursor = 0

func get_playback_seed() -> int:
	return int(_playback_data.get("random_seed", 0)) if _playback else 0

func get_playback_summary() -> Dictionary:
	return _playback_data.duplicate(true) if _playback else {}

func _path_for_identity(identity: Dictionary) -> String:
	var token: String = JSON.stringify(identity).sha256_text().substr(0, 32)
	return "%s/%s.json" % [STORAGE_ROOT, token]

func _identity_matches(a: Dictionary, b: Dictionary) -> bool:
	for key: String in ["song_id", "difficulty", "input_style", "random_mode", "chart_hash", "rules_hash"]:
		if a.get(key, null) != b.get(key, null):
			return false
	return true
