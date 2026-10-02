extends Control
class_name CalibrationScreen

const UserSettingsScript = preload("res://scripts/user_settings.gd")
const RhythmTimingScript = preload("res://scripts/rhythm_timing.gd")
const ThemeConfigScript = preload("res://config/theme_config.gd")
const MinimalThemeScript = preload("res://scripts/ui/minimal_theme.gd")
const InteractionPolishScript = preload("res://scripts/ui/interaction_polish.gd")

signal back_requested
signal applied(input_offset_ms: float, audio_offset_ms: float)

@export var theme_config: ThemeConfigScript
@export_range(60.0, 200.0, 1.0) var calibration_bpm: float = 120.0
@export_range(0, 8, 1) var warmup_beats: int = 4
@export_range(8, 32, 1) var sample_count: int = 20
@export_range(80.0, 300.0, 5.0) var max_tap_error_ms: float = 220.0

@onready var title_label: Label = %TitleLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var stage_label: Label = %StageLabel
@onready var pulse_receptor: Control = %PulseReceptor
@onready var sample_label: Label = %SampleLabel
@onready var sample_progress: ProgressBar = %SampleProgress
@onready var status_label: Label = %StatusLabel
@onready var timing_graph: CalibrationTimingGraph = %TimingGraph
@onready var quality_label: Label = %QualityLabel
@onready var input_offset_slider: HSlider = %InputOffsetSlider
@onready var input_offset_value: Label = %InputOffsetValue
@onready var audio_offset_slider: HSlider = %AudioOffsetSlider
@onready var audio_offset_value: Label = %AudioOffsetValue
@onready var retry_button: Button = %RetryButton
@onready var apply_button: Button = %ApplyButton
@onready var reset_button: Button = %ResetButton
@onready var back_button: Button = %BackButton
@onready var beat_player: AudioStreamPlayer = %BeatPlayer
@onready var input_panel: Control = $Center/Panel/VBox/InputPanel
@onready var audio_panel: Control = $Center/Panel/VBox/AudioPanel
@onready var audio_hint: Label = $Center/Panel/VBox/AudioHint

var running := false
var session_start_s := 0.0
var beat_interval_s := 0.5
var next_pulse_index := 0
var last_tapped_beat := -1000000
var tap_deltas_s: Array[float] = []
var pulse_tween: Tween
var result_ready := false
var emitted_beat_times_s: Dictionary = {}

func _ready() -> void:
	if theme_config == null:
		theme_config = ThemeConfigScript.new()
	MinimalThemeScript.apply_root(self)
	_apply_theme()
	InteractionPolishScript.install_buttons([retry_button, apply_button, reset_button, back_button])
	input_offset_slider.min_value = RhythmTimingScript.MIN_OFFSET_MS
	input_offset_slider.max_value = RhythmTimingScript.MAX_OFFSET_MS
	audio_offset_slider.min_value = RhythmTimingScript.MIN_OFFSET_MS
	audio_offset_slider.max_value = RhythmTimingScript.MAX_OFFSET_MS
	input_offset_slider.value_changed.connect(_on_input_offset_changed)
	audio_offset_slider.value_changed.connect(_on_audio_offset_changed)
	retry_button.pressed.connect(begin_calibration)
	apply_button.pressed.connect(_on_apply_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	back_button.pressed.connect(_on_back_pressed)
	visible = false
	set_process(false)

func _apply_theme() -> void:
	if theme_config == null:
		return
	title_label.add_theme_color_override("font_color", theme_config.text_primary)
	MinimalThemeScript.apply_heading(title_label, 28, MinimalThemeScript.TEXT)
	MinimalThemeScript.apply_mono(stage_label, 11, MinimalThemeScript.CYAN)
	instruction_label.add_theme_color_override("font_color", theme_config.text_secondary)
	sample_label.add_theme_color_override("font_color", theme_config.text_primary)
	status_label.add_theme_color_override("font_color", theme_config.text_secondary)
	input_offset_value.add_theme_color_override("font_color", theme_config.accent_secondary)
	audio_offset_value.add_theme_color_override("font_color", theme_config.space_accent)
	MinimalThemeScript.apply_mono(sample_label, 14, MinimalThemeScript.TEXT)
	MinimalThemeScript.apply_mono(status_label, 13, MinimalThemeScript.MUTED)
	MinimalThemeScript.apply_mono(quality_label, 12, MinimalThemeScript.CYAN)
	MinimalThemeScript.apply_mono(input_offset_value, 14, MinimalThemeScript.CYAN)
	MinimalThemeScript.apply_mono(audio_offset_value, 14, MinimalThemeScript.GOLD)
	MinimalThemeScript.style_primary(apply_button)
	MinimalThemeScript.style_secondary(retry_button, MinimalThemeScript.CYAN)
	MinimalThemeScript.style_tertiary(reset_button, MinimalThemeScript.GOLD)
	MinimalThemeScript.style_tertiary(back_button, MinimalThemeScript.CYAN)

func open() -> void:
	Input.use_accumulated_input = false
	visible = true
	_load_saved_offsets()
	begin_calibration()

func close() -> void:
	running = false
	set_process(false)
	if beat_player != null:
		beat_player.stop()
	visible = false

func begin_calibration() -> void:
	beat_interval_s = 60.0 / maxf(1.0, calibration_bpm)
	tap_deltas_s.clear()
	timing_graph.reset()
	emitted_beat_times_s.clear()
	next_pulse_index = 0
	last_tapped_beat = -1000000
	result_ready = false
	running = true
	session_start_s = _clock_s() + 0.80
	sample_progress.max_value = float(sample_count)
	sample_progress.value = 0.0
	sample_label.text = "0 / %d taps" % sample_count
	status_label.text = "Get ready — ignore the first %d warm-up beats." % warmup_beats
	quality_label.text = "TIMING QUALITY  ·  COLLECTING SAMPLES"
	stage_label.text = "STEP 1 / 2  ·  LISTEN + TAP"
	input_panel.visible = false
	audio_panel.visible = false
	audio_hint.visible = false
	apply_button.disabled = true
	apply_button.text = "APPLY RESULT"
	set_process(true)
	back_button.grab_focus()

func _process(_delta: float) -> void:
	if not running:
		return
	var now_s: float = _clock_s()
	while now_s >= _scheduled_beat_s(next_pulse_index):
		_emit_calibration_beat(next_pulse_index, now_s)
		next_pulse_index += 1
		if next_pulse_index > 100000:
			break

func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey):
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_ESCAPE or key_event.physical_keycode == KEY_ESCAPE:
		_on_back_pressed()
		get_viewport().set_input_as_handled()
		return
	if not running or not _is_calibration_key(key_event):
		return
	_register_tap(_clock_s())
	get_viewport().set_input_as_handled()

func _is_calibration_key(event: InputEventKey) -> bool:
	if event.keycode == KEY_SPACE or event.physical_keycode == KEY_SPACE:
		return true
	var calibration_keys: Array[int] = []
	if UserSettingsScript.get_input_style() == "4_arrow":
		calibration_keys.assign([KEY_LEFT, KEY_UP, KEY_RIGHT, KEY_DOWN])
	else:
		calibration_keys.assign([KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_4, KEY_KP_6, KEY_KP_7, KEY_KP_8, KEY_KP_9])
	for key_code: int in calibration_keys:
		if event.keycode == key_code or event.physical_keycode == key_code:
			return true
	return false

func _register_tap(now_s: float) -> void:
	if emitted_beat_times_s.is_empty():
		return
	var beat_index := -1
	var best_delta_s := 999.0
	for beat_key: Variant in emitted_beat_times_s.keys():
		var candidate_index: int = int(beat_key)
		if candidate_index < warmup_beats or candidate_index == last_tapped_beat:
			continue
		# v17.4.8 stores the predicted audible click time directly. This includes
		# both the next audio-mix boundary and output-device latency.
		var expected_audible_s: float = float(emitted_beat_times_s[beat_key])
		var candidate_delta_s: float = now_s - expected_audible_s
		if absf(candidate_delta_s) < absf(best_delta_s):
			beat_index = candidate_index
			best_delta_s = candidate_delta_s
	if beat_index < 0 or absf(best_delta_s) * 1000.0 > max_tap_error_ms:
		status_label.text = "Tap ignored: too far from the nearest beat."
		return
	var delta_s: float = best_delta_s
	last_tapped_beat = beat_index
	tap_deltas_s.append(delta_s)
	timing_graph.add_sample(delta_s * 1000.0)
	sample_progress.value = float(tap_deltas_s.size())
	sample_label.text = "%d / %d taps" % [tap_deltas_s.size(), sample_count]
	status_label.text = "Tap %d: %+d ms" % [tap_deltas_s.size(), int(round(delta_s * 1000.0))]
	if tap_deltas_s.size() >= sample_count:
		_finish_calibration()

func _finish_calibration() -> void:
	running = false
	set_process(false)
	if beat_player != null:
		beat_player.stop()
	var inliers: Array[float] = _robust_inliers(tap_deltas_s)
	if inliers.is_empty():
		status_label.text = "Calibration failed. Press RETRY and tap closer to the beat."
		return
	var median_delay_ms: float = _median(inliers) * 1000.0
	var recommended_ms: float = RhythmTimingScript.clamp_offset_ms(round(median_delay_ms))
	var jitter_ms: float = _standard_deviation_ms(inliers)
	timing_graph.set_result(recommended_ms, jitter_ms)
	input_offset_slider.set_value_no_signal(recommended_ms)
	_update_offset_labels()
	status_label.text = "Result %s • jitter %.1f ms • %d/%d clean taps" % [
		RhythmTimingScript.format_offset_ms(recommended_ms),
		jitter_ms,
		inliers.size(),
		tap_deltas_s.size(),
	]
	quality_label.text = "TIMING QUALITY  ·  %s  ·  JITTER %.1f MS" % [_quality_for_jitter(jitter_ms), jitter_ms]
	stage_label.text = "STEP 2 / 2  ·  REVIEW + APPLY"
	input_panel.visible = true
	audio_panel.visible = true
	audio_hint.visible = true
	result_ready = true
	apply_button.disabled = false
	apply_button.grab_focus()

func _quality_for_jitter(jitter_ms: float) -> String:
	if jitter_ms <= 12.0:
		return "EXCELLENT"
	if jitter_ms <= 24.0:
		return "STABLE"
	if jitter_ms <= 40.0:
		return "PLAYABLE"
	return "INCONSISTENT"

func _robust_inliers(values: Array[float]) -> Array[float]:
	if values.is_empty():
		var empty_values: Array[float] = []
		return empty_values
	var center: float = _median(values)
	var deviations: Array[float] = []
	for value in values:
		deviations.append(absf(value - center))
	var mad: float = _median(deviations)
	var threshold: float = maxf(0.020, mad * 3.0)
	var filtered: Array[float] = []
	for value in values:
		if absf(value - center) <= threshold:
			filtered.append(value)
	if filtered.size() < maxi(6, int(round(float(values.size()) * 0.55))):
		var fallback_values: Array[float] = []
		for value in values:
			fallback_values.append(value)
		return fallback_values
	return filtered

func _median(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var sorted_values: Array[float] = []
	for value in values:
		sorted_values.append(value)
	sorted_values.sort()
	var count: int = sorted_values.size()
	var middle: int = floori(float(count) / 2.0)
	if count % 2 == 1:
		return sorted_values[middle]
	return (sorted_values[middle - 1] + sorted_values[middle]) * 0.5

func _standard_deviation_ms(values: Array[float]) -> float:
	if values.size() <= 1:
		return 0.0
	var mean: float = 0.0
	for value in values:
		mean += value
	mean /= float(values.size())
	var variance: float = 0.0
	for value in values:
		var diff: float = value - mean
		variance += diff * diff
	variance /= float(values.size())
	return sqrt(variance) * 1000.0

func _scheduled_beat_s(index: int) -> float:
	return session_start_s + float(index) * beat_interval_s

func _emit_calibration_beat(index: int, emitted_at_s: float) -> void:
	# AudioStreamPlayer.play() becomes audible after the next mix boundary plus
	# output latency. Calibrating against the process-frame timestamp alone would
	# bake audio-buffer delay into the user's Input Offset.
	var expected_audible_s := emitted_at_s
	expected_audible_s += maxf(0.0, AudioServer.get_time_to_next_mix())
	expected_audible_s += maxf(0.0, AudioServer.get_output_latency())
	emitted_beat_times_s[index] = expected_audible_s
	# Keep only a small recent window so tap matching cannot lock onto an old beat.
	var stale_index: int = index - 6
	if emitted_beat_times_s.has(stale_index):
		emitted_beat_times_s.erase(stale_index)
	if beat_player != null:
		beat_player.play()
	if index < warmup_beats:
		status_label.text = "Warm-up %d / %d" % [index + 1, warmup_beats]
	elif tap_deltas_s.size() < sample_count:
		status_label.text = "Tap any arrow direction or SPACE on the click." if UserSettingsScript.get_input_style() == "4_arrow" else "Tap any numpad direction or SPACE on the click."
	_play_pulse()

func _play_pulse() -> void:
	if pulse_receptor == null:
		return
	if pulse_tween != null:
		pulse_tween.kill()
	pulse_receptor.pivot_offset = pulse_receptor.size * 0.5
	pulse_receptor.scale = Vector2.ONE * 0.82
	pulse_receptor.modulate = theme_config.space_accent if theme_config != null else Color.WHITE
	pulse_tween = create_tween()
	pulse_tween.set_parallel(true)
	pulse_tween.tween_property(pulse_receptor, "scale", Vector2.ONE * 1.12, 0.08).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	pulse_tween.tween_property(pulse_receptor, "modulate", Color.WHITE, 0.16)
	pulse_tween.chain().tween_property(pulse_receptor, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _load_saved_offsets() -> void:
	input_offset_slider.set_value_no_signal(UserSettingsScript.get_input_offset_ms())
	audio_offset_slider.set_value_no_signal(UserSettingsScript.get_audio_offset_ms())
	_update_offset_labels()

func _on_input_offset_changed(_value: float) -> void:
	_update_offset_labels()

func _on_audio_offset_changed(_value: float) -> void:
	_update_offset_labels()

func _update_offset_labels() -> void:
	input_offset_value.text = RhythmTimingScript.format_offset_ms(input_offset_slider.value)
	audio_offset_value.text = RhythmTimingScript.format_offset_ms(audio_offset_slider.value)

func _on_apply_pressed() -> void:
	UserSettingsScript.set_timing_offsets(input_offset_slider.value, audio_offset_slider.value)
	var saved_input: float = UserSettingsScript.get_input_offset_ms()
	var saved_audio: float = UserSettingsScript.get_audio_offset_ms()
	input_offset_slider.set_value_no_signal(saved_input)
	audio_offset_slider.set_value_no_signal(saved_audio)
	_update_offset_labels()
	status_label.text = "Saved · Input %s · Audio %s" % [RhythmTimingScript.format_offset_ms(saved_input), RhythmTimingScript.format_offset_ms(saved_audio)]
	applied.emit(saved_input, saved_audio)

func _on_reset_pressed() -> void:
	running = false
	set_process(false)
	if beat_player != null:
		beat_player.stop()
	tap_deltas_s.clear()
	timing_graph.reset()
	result_ready = false
	input_offset_slider.set_value_no_signal(0.0)
	audio_offset_slider.set_value_no_signal(0.0)
	_update_offset_labels()
	status_label.text = "Offsets reset locally. Apply zero offsets or run calibration again."
	quality_label.text = "TIMING QUALITY  ·  RESET"
	stage_label.text = "STEP 2 / 2  ·  REVIEW + APPLY"
	input_panel.visible = true
	audio_panel.visible = true
	audio_hint.visible = true
	apply_button.disabled = false
	sample_progress.value = 0.0
	sample_label.text = "0 / %d taps" % sample_count

func _on_back_pressed() -> void:
	close()
	back_requested.emit()

func _clock_s() -> float:
	return float(Time.get_ticks_usec()) / 1000000.0
