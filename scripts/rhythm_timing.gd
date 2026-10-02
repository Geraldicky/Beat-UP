extends RefCounted
class_name RhythmTiming

# User-facing timing offsets. Positive input offset compensates for a late key
# press by judging it earlier. Positive audio offset delays the chart relative
# to the audible song by moving the gameplay song clock earlier.
#
# v17.4.8 keeps this established sign convention unchanged.
const MIN_OFFSET_MS := -200.0
const MAX_OFFSET_MS := 200.0
const RESUME_WARNING_THRESHOLD_MS := 80.0

static func clamp_offset_ms(value: float) -> float:
	return clampf(value, MIN_OFFSET_MS, MAX_OFFSET_MS)

static func get_raw_audio_time(player: AudioStreamPlayer, fallback_time: float = 0.0) -> float:
	if player == null or not player.playing:
		return maxf(0.0, fallback_time)
	# Playback position updates on the mix boundary. Interpolate to the current
	# mix time and compensate output latency so this approximates the sound that
	# has actually reached the output device.
	var raw_time: float = player.get_playback_position()
	raw_time += AudioServer.get_time_since_last_mix()
	raw_time -= AudioServer.get_output_latency()
	return maxf(0.0, raw_time)

static func stabilize_monotonic_audio_time(sample_time: float, previous_time: float, initialized: bool) -> float:
	# Gameplay never intentionally seeks while a run is active. Retry/start resets
	# the runtime clock state first, so a backwards sample during active playback
	# is mixer/interpolation jitter and must not make notes move backwards or be
	# judged twice.
	var safe_sample := maxf(0.0, sample_time)
	if not initialized:
		return safe_sample
	return maxf(maxf(0.0, previous_time), safe_sample)

static func get_gameplay_song_time_from_raw(raw_time: float, audio_offset_ms: float) -> float:
	# Positive Audio Offset delays the chart relative to audible music by moving
	# the gameplay clock earlier. Keep this operation centralized and apply once.
	return maxf(0.0, maxf(0.0, raw_time) - clamp_offset_ms(audio_offset_ms) / 1000.0)

static func get_gameplay_song_time(player: AudioStreamPlayer, fallback_time: float, audio_offset_ms: float) -> float:
	if player == null or not player.playing:
		return maxf(0.0, fallback_time)
	return get_gameplay_song_time_from_raw(get_raw_audio_time(player, fallback_time), audio_offset_ms)

static func get_input_judgment_time(song_time: float, input_offset_ms: float) -> float:
	# Positive Input Offset compensates a late key by judging that key earlier.
	return maxf(0.0, song_time - clamp_offset_ms(input_offset_ms) / 1000.0)

static func format_offset_ms(value: float) -> String:
	var rounded_value: int = int(round(clamp_offset_ms(value)))
	if rounded_value > 0:
		return "+%d ms" % rounded_value
	return "%d ms" % rounded_value
