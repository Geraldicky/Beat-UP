extends SceneTree

const RhythmTimingScript = preload("res://scripts/rhythm_timing.gd")

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)

func _near(a: float, b: float, epsilon: float = 0.0001) -> bool:
	return absf(a - b) <= epsilon

func _run() -> void:
	_check(_near(RhythmTimingScript.clamp_offset_ms(999.0), 200.0), "Positive timing clamp changed unexpectedly.")
	_check(_near(RhythmTimingScript.clamp_offset_ms(-999.0), -200.0), "Negative timing clamp changed unexpectedly.")

	# Established Beat UP! sign convention must remain unchanged.
	_check(_near(RhythmTimingScript.get_input_judgment_time(10.0, 50.0), 9.95), "Positive Input Offset must judge a late input earlier.")
	_check(_near(RhythmTimingScript.get_input_judgment_time(10.0, -50.0), 10.05), "Negative Input Offset sign is incorrect.")
	_check(_near(RhythmTimingScript.get_gameplay_song_time_from_raw(10.0, 50.0), 9.95), "Positive Audio Offset must delay the chart by moving gameplay time earlier.")
	_check(_near(RhythmTimingScript.get_gameplay_song_time_from_raw(10.0, -50.0), 10.05), "Negative Audio Offset sign is incorrect.")

	# Normal playback may never run backwards because of mixer interpolation jitter.
	_check(_near(RhythmTimingScript.stabilize_monotonic_audio_time(12.001, 12.000, true), 12.001), "Forward audio time must advance.")
	_check(_near(RhythmTimingScript.stabilize_monotonic_audio_time(11.999, 12.000, true), 12.000), "Backwards audio jitter must be clamped.")
	_check(_near(RhythmTimingScript.stabilize_monotonic_audio_time(0.0, 99.0, false), 0.0), "A reset clock must accept the new song start.")

	if failures == 0:
		print("TIMING_V1748_REGRESSION_TEST: PASS")
	else:
		print("TIMING_V1748_REGRESSION_TEST: FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
