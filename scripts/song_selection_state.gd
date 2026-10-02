extends Node
class_name BeatUpSongSelectionState

signal selection_changed(state: Dictionary)

const CANONICAL_KEYS := [
	"song_id",
	"difficulty_id",
	"title",
	"artist",
	"background",
	"audio",
	"duration",
	"bpm",
	"difficulty",
	"star_rating",
	"source",
]

var state: Dictionary = {}

func set_selection(song_id: String, difficulty_id: String, metadata: Dictionary = {}) -> void:
	var same_song: bool = not song_id.is_empty() and song_id == get_song_id()
	var next_state: Dictionary = {}
	if same_song:
		next_state = state.duplicate(true)
	for key_value in metadata.keys():
		var key: Variant = key_value
		next_state[key] = metadata[key]
	next_state["song_id"] = song_id
	next_state["difficulty_id"] = difficulty_id
	_normalize_state(next_state)
	_commit(next_state)

func update_metadata(metadata: Dictionary) -> void:
	if state.is_empty():
		return
	var next_state: Dictionary = state.duplicate(true)
	for key_value in metadata.keys():
		var key: Variant = key_value
		next_state[key] = metadata[key]
	_normalize_state(next_state)
	_commit(next_state)

func set_difficulty(difficulty_id: String, difficulty_metadata: Dictionary = {}) -> void:
	if state.is_empty():
		return
	var next_state: Dictionary = state.duplicate(true)
	next_state["difficulty_id"] = difficulty_id
	for key_value in difficulty_metadata.keys():
		var key: Variant = key_value
		next_state[key] = difficulty_metadata[key]
	_normalize_state(next_state)
	_commit(next_state)

func clear() -> void:
	if state.is_empty():
		return
	state.clear()
	selection_changed.emit({})

func has_selection() -> bool:
	return not get_song_id().is_empty()

func get_state() -> Dictionary:
	return state.duplicate(true)

func get_song_id() -> String:
	return str(state.get("song_id", ""))

func get_difficulty_id() -> String:
	return str(state.get("difficulty_id", ""))

func get_background_path() -> String:
	return str(state.get("background", ""))

func get_audio_path() -> String:
	return str(state.get("audio", ""))

func _normalize_state(target: Dictionary) -> void:
	for canonical_key_value in CANONICAL_KEYS:
		var canonical_key: String = str(canonical_key_value)
		if not target.has(canonical_key):
			if canonical_key in ["song_id", "difficulty_id", "title", "artist", "background", "audio", "difficulty", "source"]:
				target[canonical_key] = ""
			else:
				target[canonical_key] = 0.0
	if str(target.get("difficulty", "")).is_empty() and not str(target.get("difficulty_id", "")).is_empty():
		target["difficulty"] = str(target.get("difficulty_id", "")).to_upper()

func _commit(next_state: Dictionary) -> void:
	if next_state == state:
		return
	state = next_state
	selection_changed.emit(get_state())
