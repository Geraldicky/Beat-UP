extends AudioStreamPlayer
class_name SongPreviewController

const BAR_COUNT := 18
const DEFAULT_PREVIEW_LENGTH := 20.0

@export var visual_path: NodePath
@export_range(-40.0, 0.0, 0.5) var target_volume_db := -9.0
@export_range(8.0, 30.0, 1.0) var preview_length := DEFAULT_PREVIEW_LENGTH
@export_range(0.02, 1.0, 0.01) var switch_fade_duration := 0.20

var visual: Control
var current_audio_path: String = ""
var preview_start_seconds: float = 0.0
var preview_end_seconds: float = 0.0
var pending_chart: Dictionary = {}
var pending_delay_seconds: float = 0.0
var pending_preview: bool = false
var pending_wait_seconds: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visual = get_node_or_null(visual_path) as Control

func _process(delta: float) -> void:
	if pending_preview:
		pending_delay_seconds -= delta
		pending_wait_seconds += delta
		if pending_delay_seconds <= 0.0:
			var audio_path := str(pending_chart.get("audio", ""))
			var session := _session()
			var track_ready := true
			var failed := false
			if session != null and session.has_method("is_track_ready"):
				track_ready = bool(session.call("is_track_ready", audio_path))
				if session.has_method("is_track_preload_failed"):
					failed = bool(session.call("is_track_preload_failed", audio_path))
			if track_ready or failed:
				var chart_to_play := pending_chart.duplicate(true)
				pending_chart.clear()
				pending_preview = false
				play_chart_preview(chart_to_play)
			else:
				# Keep UI highlight/background responsive while decode finishes.
				pending_delay_seconds = 0.02
	var levels: PackedFloat32Array = get_latest_levels()
	if visual != null and visual.has_method("set_audio_levels"):
		visual.call("set_audio_levels", levels)

func queue_chart_preview(chart: Dictionary, delay_seconds: float = 0.12) -> void:
	pending_chart = chart.duplicate(true)
	pending_delay_seconds = maxf(0.0, delay_seconds)
	pending_wait_seconds = 0.0
	pending_preview = true
	var session := _session()
	var audio_path := str(chart.get("audio", ""))
	var perf: Node = get_node_or_null("/root/PerformanceMonitor")
	if perf != null and not audio_path.is_empty():
		perf.call("mark_preview_requested", audio_path)
	if session != null and session.has_method("preload_track") and not audio_path.is_empty():
		session.call("preload_track", audio_path)

func cancel_pending_preview() -> void:
	pending_preview = false
	pending_delay_seconds = 0.0
	pending_wait_seconds = 0.0
	pending_chart.clear()

func _session() -> Node:
	return get_node_or_null("/root/MusicSession")

func play_chart_preview(chart: Dictionary) -> void:
	cancel_pending_preview()
	var audio_path: String = str(chart.get("audio", ""))
	if audio_path.is_empty():
		stop_immediately()
		return
	var duration: float = float(chart.get("duration", 0.0))
	var start_time: float = _choose_preview_start(chart, duration)
	var metadata: Dictionary = {
		"source": "song_library",
		"song_id": str(chart.get("song_id", chart.get("id", ""))),
		"difficulty_id": str(chart.get("chart_difficulty", chart.get("difficulty", ""))),
		"title": str(chart.get("title", "")),
		"artist": str(chart.get("artist", "")),
		"background": str(chart.get("background", "")),
	}
	var selection_state: Node = get_node_or_null("/root/SongSelectionState")
	if selection_state != null and selection_state.has_method("get_state"):
		var selection_value: Variant = selection_state.call("get_state")
		if selection_value is Dictionary:
			var canonical: Dictionary = selection_value as Dictionary
			if str(canonical.get("song_id", "")) == str(metadata.get("song_id", "")):
				for key_value in canonical.keys():
					var key: Variant = key_value
					metadata[key] = canonical[key]
	play_preview(audio_path, start_time, duration, metadata)

func play_preview(audio_path: String, start_time: float, song_duration: float, metadata: Dictionary = {}) -> void:
	if audio_path.is_empty():
		stop_immediately()
		return
	var safe_duration: float = maxf(song_duration, 0.0)
	var safe_start: float = _clamp_preview_start(start_time, safe_duration)
	var safe_end: float = minf(safe_duration, safe_start + preview_length) if safe_duration > 0.0 else safe_start + preview_length
	preview_start_seconds = safe_start
	preview_end_seconds = maxf(safe_start + 1.0, safe_end)
	var session: Node = _session()
	if session == null or not session.has_method("play_track"):
		return
	var session_state: Dictionary = {}
	if session.has_method("get_state"):
		var state_value: Variant = session.call("get_state")
		if state_value is Dictionary:
			session_state = state_value as Dictionary
	var same_track: bool = str(session_state.get("audio", "")) == audio_path and (bool(session_state.get("playing", false)) or bool(session_state.get("paused", false)))
	current_audio_path = audio_path
	var perf: Node = get_node_or_null("/root/PerformanceMonitor")
	if perf != null:
		perf.call("mark_preview_started", audio_path)
	if same_track:
		if session.has_method("update_metadata"):
			session.call("update_metadata", metadata)
		if session.has_method("set_target_volume"):
			session.call("set_target_volume", target_volume_db, switch_fade_duration)
		return
	session.call("play_track", audio_path, safe_start, metadata, false, false, switch_fade_duration, target_volume_db)

func fade_out(duration: float = 0.18, stop_after_fade: bool = true) -> void:
	var session: Node = _session()
	if session != null and session.has_method("fade_out"):
		session.call("fade_out", duration, stop_after_fade)

func stop_immediately() -> void:
	cancel_pending_preview()
	var session: Node = _session()
	if session != null and session.has_method("stop_immediately"):
		session.call("stop_immediately")
	current_audio_path = ""
	preview_start_seconds = 0.0
	preview_end_seconds = 0.0
	if visual != null and visual.has_method("set_audio_levels"):
		visual.call("set_audio_levels", PackedFloat32Array())

func get_latest_levels() -> PackedFloat32Array:
	var session: Node = _session()
	if session != null and session.has_method("get_latest_levels"):
		var value: Variant = session.call("get_latest_levels")
		return value as PackedFloat32Array if value is PackedFloat32Array else PackedFloat32Array()
	return PackedFloat32Array()

func get_preview_range() -> Vector2:
	return Vector2(preview_start_seconds, preview_end_seconds)

func get_current_audio_path() -> String:
	var session: Node = _session()
	if session != null and session.has_method("get_current_audio_path"):
		return str(session.call("get_current_audio_path"))
	return current_audio_path

func get_audio_handoff_state() -> Dictionary:
	var session: Node = _session()
	if session != null and session.has_method("get_state"):
		var value: Variant = session.call("get_state")
		return (value as Dictionary).duplicate(true) if value is Dictionary else {}
	return {}

func _choose_preview_start(chart: Dictionary, duration: float) -> float:
	if chart.has("preview_start"):
		return _snap_to_phrase(float(chart.get("preview_start", 0.0)), chart, duration)

	# Generated charts store section identity in `role` (older charts may use
	# `name`). The old preview code only checked `name`, so most songs ignored
	# their musical sections and jumped to an arbitrary ~32% timestamp.
	# Prefer a short lead-in before the first strong section instead; this makes
	# card previews recognizable and avoids beginning on an abrupt transient.
	var bpm := maxf(1.0, float(chart.get("bpm", 120.0)))
	var phrase_length := 60.0 / bpm * 16.0
	var sections_value: Variant = chart.get("sections", [])
	if sections_value is Array:
		var sections := sections_value as Array
		var preferred_roles := ["chorus", "refrain", "drop", "climax", "main_b", "main_a", "build"]
		for preferred_role in preferred_roles:
			for section_value in sections:
				if not (section_value is Dictionary):
					continue
				var section := section_value as Dictionary
				var role := str(section.get("role", section.get("name", ""))).to_lower()
				if role.contains(preferred_role):
					var section_start := float(section.get("start", 0.0))
					return _snap_to_phrase(maxf(0.0, section_start - phrase_length), chart, duration)

	var musical_center := maxf(float(chart.get("beat_offset", 0.0)), duration * 0.20)
	return _snap_to_phrase(musical_center, chart, duration)

func _snap_to_phrase(time_seconds: float, chart: Dictionary, duration: float) -> float:
	var bpm := maxf(1.0, float(chart.get("bpm", 120.0)))
	var beat_offset := float(chart.get("beat_offset", 0.0))
	var phrase_length := 60.0 / bpm * 16.0
	var phrase_index: float = roundf((time_seconds - beat_offset) / phrase_length)
	var snapped_time: float = beat_offset + phrase_index * phrase_length
	return _clamp_preview_start(snapped_time, duration)

func _clamp_preview_start(start_time: float, duration: float) -> float:
	if duration <= 0.0:
		return maxf(0.0, start_time)
	var latest_start := maxf(0.0, duration - preview_length - 1.0)
	return clampf(start_time, 0.0, latest_start)

func _load_audio_stream(path: String) -> AudioStream:
	if path.is_empty():
		return null
	if path.begins_with("res://"):
		var imported_stream: AudioStream = load(path) as AudioStream
		if imported_stream != null:
			return imported_stream
	var filesystem_path := ProjectSettings.globalize_path(path) if path.begins_with("user://") else path
	if path.begins_with("res://"):
		filesystem_path = ProjectSettings.globalize_path(path)
	match filesystem_path.get_extension().to_lower():
		"ogg": return AudioStreamOggVorbis.load_from_file(filesystem_path)
		"mp3": return AudioStreamMP3.load_from_file(filesystem_path)
		"wav": return AudioStreamWAV.load_from_file(filesystem_path)
	return null



# v17.4.52.1 typed spectrum compatibility API.
func get_band_frequency_range(index: int) -> Vector2:
	var session: Node = _session()
	if session != null and session.has_method("get_band_frequency_range"):
		var value: Variant = session.call("get_band_frequency_range", index)
		if value is Vector2:
			return value as Vector2
	return Vector2.ZERO

func is_spectrum_configured() -> bool:
	var session: Node = _session()
	return bool(session.call("is_spectrum_configured")) if session != null and session.has_method("is_spectrum_configured") else false
