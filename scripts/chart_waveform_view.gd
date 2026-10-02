extends Control
class_name ChartWaveformView

const MinimalThemeScript = preload("res://scripts/ui/minimal_theme.gd")

signal seek_requested(time_seconds: float)

const BG := Color("0b0d11")
const SURFACE := Color("111722")
const GRID := Color("283243")
const WAVE := Color("65cfe3")
const WAVE_HOT := Color("ee5795")
const WAVE_FILL := Color("58b9d2")
const PLAYHEAD := Color("f3f1ed")
const TEXT := Color("9898a2")

var peaks: Array[float] = []
var duration := 1.0
var current_time := 0.0
var window_seconds := 12.0
var playhead_ratio := 0.32
var source_label := "WAVEFORM UNAVAILABLE"
var hover_x := -1.0
var dragging := false
var mono_font: Font

func _ready() -> void:
	mono_font = MinimalThemeScript.mono_font()
	if mono_font == null:
		mono_font = ThemeDB.fallback_font
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_exited.connect(_on_mouse_exited)

func set_waveform(raw_peaks: Variant, song_duration: float, label: String = "PCM AUDIO WAVEFORM") -> void:
	peaks.clear()
	if raw_peaks is Array:
		for raw_peak in raw_peaks:
			if raw_peak is float or raw_peak is int:
				peaks.append(clampf(float(raw_peak), 0.0, 1.0))
	duration = maxf(0.001, song_duration)
	var window_label := "WAVEFORM  ·  %.0f SEC WINDOW" % window_seconds
	source_label = label.replace("OVERVIEW", window_label) if not peaks.is_empty() else "WAVEFORM UNAVAILABLE · GENERATE FROM FLAC"
	queue_redraw()

func clear_waveform(song_duration: float = 1.0) -> void:
	peaks.clear()
	duration = maxf(0.001, song_duration)
	source_label = "WAVEFORM UNAVAILABLE · GENERATE FROM FLAC"
	queue_redraw()

func set_time(value: float) -> void:
	current_time = clampf(value, 0.0, duration)
	queue_redraw()

func set_view_window(seconds: float, ratio: float) -> void:
	window_seconds = maxf(0.25, seconds)
	playhead_ratio = clampf(ratio, 0.0, 1.0)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		hover_x = clampf(motion.position.x, 0.0, size.x)
		if dragging:
			_emit_seek(hover_x)
		queue_redraw()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			dragging = mouse.pressed
			if mouse.pressed:
				hover_x = clampf(mouse.position.x, 0.0, size.x)
				_emit_seek(hover_x)
			accept_event()

func _on_mouse_exited() -> void:
	dragging = false
	hover_x = -1.0
	queue_redraw()

func _emit_seek(x: float) -> void:
	if size.x <= 1.0:
		return
	seek_requested.emit(_time_at_x(x))

func _draw() -> void:
	if size.x <= 2.0 or size.y <= 2.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	_draw_second_grid()
	if peaks.is_empty():
		_draw_empty_state()
	else:
		_draw_waveform()
	_draw_song_bounds()
	_draw_playhead()
	_draw_labels()
	_draw_hover()

func _draw_second_grid() -> void:
	if duration <= 0.0 or window_seconds <= 0.0:
		return
	var visible_start := _visible_start()
	var visible_end := visible_start + window_seconds
	var target_lines := clampi(int(size.x / 150.0), 4, 16)
	var raw_step := window_seconds / float(target_lines)
	var step := _nice_time_step(raw_step)
	var tick := floorf(visible_start / step) * step
	while tick <= visible_end + step * 0.5:
		var x := (tick - visible_start) / window_seconds * size.x
		draw_line(Vector2(x, 0.0), Vector2(x, size.y), Color(GRID, 0.42), 1.0)
		tick += step

func _draw_waveform() -> void:
	# A dense filled silhouette is substantially easier to read than two thin
	# envelope outlines, especially for quiet passages. Keep the point count
	# bounded because this view is redrawn while audio is playing.
	var center_y := size.y * 0.55
	var usable_height := maxf(12.0, size.y - 28.0)
	var columns := clampi(ceili(size.x * 0.50), 64, 1024)
	var top_points := PackedVector2Array()
	var bottom_points := PackedVector2Array()
	var visible_start := _visible_start()
	for column in range(columns):
		var ratio := float(column) / maxf(1.0, float(columns - 1))
		var sample_time := visible_start + ratio * window_seconds
		var amplitude := _sample_amplitude_at_time(sample_time)
		# A small visual floor keeps silence visible without exaggerating it.
		var half_height := maxf(1.25, pow(amplitude, 0.78) * usable_height * 0.5)
		var x := ratio * size.x
		top_points.append(Vector2(x, center_y - half_height))
		bottom_points.append(Vector2(x, center_y + half_height))

	var full_shape := _closed_wave_shape(top_points, bottom_points, 0, columns - 1)
	draw_colored_polygon(full_shape, Color(WAVE_FILL, 0.62))
	draw_polyline(top_points, Color(WAVE, 0.92), 1.15, true)
	draw_polyline(bottom_points, Color(WAVE, 0.92), 1.15, true)

	var played_first := clampi(ceili((0.0 - visible_start) / window_seconds * float(columns - 1)), 0, columns - 1)
	var played_end := clampi(floori(playhead_ratio * float(columns - 1)), 0, columns - 1)
	if current_time > 0.0 and played_end > played_first:
		var played_shape := _closed_wave_shape(top_points, bottom_points, played_first, played_end)
		draw_colored_polygon(played_shape, Color(WAVE_HOT, 0.82))
		draw_polyline(top_points.slice(played_first, played_end + 1), Color(WAVE_HOT, 0.98), 1.25, true)
		draw_polyline(bottom_points.slice(played_first, played_end + 1), Color(WAVE_HOT, 0.98), 1.25, true)
	draw_line(Vector2(0.0, center_y), Vector2(size.x, center_y), Color(PLAYHEAD, 0.13), 1.0)

func _sample_amplitude_at_time(sample_time: float) -> float:
	if peaks.is_empty() or sample_time < 0.0 or sample_time > duration:
		return 0.0
	var sample_position := clampf(sample_time / duration, 0.0, 1.0) * float(peaks.size() - 1)
	var left_index := clampi(floori(sample_position), 0, peaks.size() - 1)
	var right_index := mini(left_index + 1, peaks.size() - 1)
	return lerpf(peaks[left_index], peaks[right_index], sample_position - float(left_index))

func _closed_wave_shape(top: PackedVector2Array, bottom: PackedVector2Array, first: int, last: int) -> PackedVector2Array:
	var shape := PackedVector2Array()
	for index in range(first, last + 1):
		shape.append(top[index])
	for index in range(last, first - 1, -1):
		shape.append(bottom[index])
	return shape

func _draw_song_bounds() -> void:
	if duration <= 0.0:
		return
	var visible_start := _visible_start()
	var visible_end := visible_start + window_seconds
	if visible_start < 0.0:
		var song_start_x := clampf((0.0 - visible_start) / window_seconds * size.x, 0.0, size.x)
		draw_rect(Rect2(0.0, 19.0, song_start_x, size.y - 19.0), Color(BG, 0.62))
		draw_line(Vector2(song_start_x, 19.0), Vector2(song_start_x, size.y), Color(WAVE, 0.58), 1.0)
	if visible_end > duration:
		var song_end_x := clampf((duration - visible_start) / window_seconds * size.x, 0.0, size.x)
		draw_rect(Rect2(song_end_x, 19.0, size.x - song_end_x, size.y - 19.0), Color(BG, 0.66))
		draw_line(Vector2(song_end_x, 19.0), Vector2(song_end_x, size.y), Color(WAVE, 0.58), 1.0)

func _draw_playhead() -> void:
	var x := size.x * playhead_ratio
	draw_line(Vector2(x, 0.0), Vector2(x, size.y), PLAYHEAD, 2.0)
	var marker := PackedVector2Array([Vector2(x - 4.0, 0.0), Vector2(x + 4.0, 0.0), Vector2(x, 6.0)])
	draw_colored_polygon(marker, PLAYHEAD)

func _draw_labels() -> void:
	draw_rect(Rect2(0.0, 0.0, size.x, 19.0), Color(SURFACE, 0.76))
	draw_string(mono_font, Vector2(9.0, 13.0), source_label, HORIZONTAL_ALIGNMENT_LEFT, size.x - 18.0, 9, Color(TEXT, 0.82))

func _draw_hover() -> void:
	if hover_x < 0.0:
		return
	var x := clampf(hover_x, 0.0, size.x)
	draw_line(Vector2(x, 19.0), Vector2(x, size.y), Color(WAVE, 0.46), 1.0)
	var label := _format_time(_time_at_x(x))
	var label_width := mono_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 12.0
	var label_x := clampf(x - label_width * 0.5, 4.0, size.x - label_width - 4.0)
	var label_rect := Rect2(label_x, size.y - 18.0, label_width, 15.0)
	draw_rect(label_rect, Color(BG, 0.92))
	draw_rect(label_rect, Color(WAVE, 0.55), false, 1.0)
	draw_string(mono_font, Vector2(label_x + 6.0, size.y - 7.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, WAVE)

func _visible_start() -> float:
	return current_time - window_seconds * playhead_ratio

func _time_at_x(x: float) -> float:
	var seconds_per_pixel := window_seconds / maxf(1.0, size.x)
	return clampf(current_time + (clampf(x, 0.0, size.x) - size.x * playhead_ratio) * seconds_per_pixel, 0.0, duration)

func _draw_empty_state() -> void:
	var message := "GENERATE THIS SONG FROM FLAC TO BUILD ITS AUDIO WAVEFORM"
	var width := mono_font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	draw_string(mono_font, Vector2((size.x - width) * 0.5, size.y * 0.60), message, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(TEXT, 0.60))

func _nice_time_step(raw_step: float) -> float:
	for candidate in [1.0, 2.0, 5.0, 10.0, 15.0, 30.0, 60.0, 120.0, 300.0]:
		if candidate >= raw_step:
			return candidate
	return 600.0

func _format_time(seconds: float) -> String:
	var safe_seconds := maxf(0.0, seconds)
	return "%02d:%02d" % [floori(safe_seconds / 60.0), floori(fmod(safe_seconds, 60.0))]
