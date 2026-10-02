extends AudioStreamPlayer
class_name MenuBGMController

@export var visual_path: NodePath
@export_range(-40.0, 0.0, 0.5) var target_volume_db := -12.0
@export_range(0.05, 3.0, 0.05) var default_fade_duration := 0.65

var visual: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visual = get_node_or_null(visual_path) as Control

func _process(_delta: float) -> void:
	var levels: PackedFloat32Array = get_latest_levels()
	if visual != null and visual.has_method("set_audio_levels"):
		visual.call("set_audio_levels", levels)

func _session() -> Node:
	return get_node_or_null("/root/MusicSession")

func play_menu_track(audio_path: String, start_position: float, metadata: Dictionary, loop: bool = true, fade_duration: float = 0.18, restart_if_same: bool = false) -> bool:
	var session: Node = _session()
	if session == null or not session.has_method("play_track"):
		return false
	return bool(session.call("play_track", audio_path, start_position, metadata, restart_if_same, loop, fade_duration, target_volume_db))

func start_menu_music(fade_duration: float = -1.0) -> void:
	var session: Node = _session()
	if session == null:
		return
	var duration: float = default_fade_duration if fade_duration < 0.0 else fade_duration
	if session.has_method("set_target_volume"):
		session.call("set_target_volume", target_volume_db, duration)
	if session.has_method("ensure_playing"):
		session.call("ensure_playing", duration)

func start_menu_music_at(playback_position: float, fade_duration: float = 0.18) -> void:
	var session: Node = _session()
	if session == null:
		return
	if session.has_method("seek"):
		session.call("seek", playback_position)
	start_menu_music(fade_duration)

func fade_out(fade_duration: float = 0.24, stop_after_fade: bool = false) -> void:
	var session: Node = _session()
	if session != null and session.has_method("fade_out"):
		session.call("fade_out", fade_duration, stop_after_fade)

func stop_immediately() -> void:
	var session: Node = _session()
	if session != null and session.has_method("stop_immediately"):
		session.call("stop_immediately")

func set_music_paused(paused: bool) -> void:
	var session: Node = _session()
	if session != null and session.has_method("set_paused"):
		session.call("set_paused", paused)

func is_music_paused() -> bool:
	var session: Node = _session()
	return bool(session.call("is_paused")) if session != null and session.has_method("is_paused") else false

func is_music_playing() -> bool:
	var session: Node = _session()
	return bool(session.call("is_playing")) if session != null and session.has_method("is_playing") else false

func get_music_playback_position() -> float:
	var session: Node = _session()
	return float(session.call("get_playback_position")) if session != null and session.has_method("get_playback_position") else 0.0

func get_music_duration() -> float:
	var session: Node = _session()
	return float(session.call("get_duration")) if session != null and session.has_method("get_duration") else 0.0

func get_current_stream() -> AudioStream:
	var session: Node = _session()
	if session != null and session.has_method("get_current_stream"):
		return session.call("get_current_stream") as AudioStream
	return null

func get_music_state() -> Dictionary:
	var session: Node = _session()
	if session != null and session.has_method("get_state"):
		var value: Variant = session.call("get_state")
		return (value as Dictionary).duplicate(true) if value is Dictionary else {}
	return {}

func get_latest_levels() -> PackedFloat32Array:
	var session: Node = _session()
	if session != null and session.has_method("get_latest_levels"):
		var value: Variant = session.call("get_latest_levels")
		return value as PackedFloat32Array if value is PackedFloat32Array else PackedFloat32Array()
	return PackedFloat32Array()


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
