extends Control
class_name ChartTimelineView

const MinimalThemeScript = preload("res://scripts/ui/minimal_theme.gd")

signal seek_requested(time_seconds: float)

@export var window_seconds := 12.0
@export var playhead_ratio := 0.32

var events: Array = []
var space_events: Array[float] = []
var current_time := 0.0
var duration := 1.0
var bpm := 120.0
var beat_offset := 0.0
var grid_subdivisions := 2
var snap_enabled := true
var hover_x := -1.0
var body_font: Font
var mono_font: Font

const BG := Color("0b0d11")
const LANE_A := Color("10141c")
const LANE_B := Color("0d1118")
const RULER := Color("151a23")
const GRID_MINOR := Color("202733")
const GRID_BEAT := Color("303a49")
const GRID_MEASURE := Color("52657c")
const TEXT := Color("9898a2")
const NORMAL := Color("5bcbe0")
const REVERSE := Color("ee5795")
const SPACE := Color("f7c75e")
const PLAYHEAD := Color("f3f1ed")

func _ready() -> void:
	body_font = MinimalThemeScript.body_font()
	mono_font = MinimalThemeScript.mono_font()
	if body_font == null:
		body_font = ThemeDB.fallback_font
	if mono_font == null:
		mono_font = ThemeDB.fallback_font
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_exited.connect(_clear_hover)

func set_chart(chart_events: Array, raw_spaces: Array, chart_bpm: float, offset: float, song_duration: float) -> void:
	events = chart_events
	space_events.clear()
	for value in raw_spaces:
		if value is float or value is int:
			space_events.append(float(value))
	bpm = maxf(1.0, chart_bpm)
	beat_offset = offset
	duration = maxf(0.001, song_duration)
	queue_redraw()

func set_time(value: float) -> void:
	current_time = clampf(value, 0.0, duration)
	queue_redraw()

func set_grid_subdivisions(value: int, enabled: bool = true) -> void:
	grid_subdivisions = clampi(value, 1, 8)
	snap_enabled = enabled
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hover_x = clampf((event as InputEventMouseMotion).position.x, 0.0, size.x)
		queue_redraw()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
			seek_requested.emit(_time_for_x(mouse.position.x))
			accept_event()

func _clear_hover() -> void:
	hover_x = -1.0
	queue_redraw()

func _draw() -> void:
	if size.x <= 2.0 or size.y <= 2.0:
		return
	var ruler_height := clampf(size.y * 0.18, 24.0, 34.0)
	var lane_height := (size.y - ruler_height) * 0.5
	var space_rect := Rect2(0.0, ruler_height, size.x, lane_height)
	var note_rect := Rect2(0.0, ruler_height + lane_height, size.x, lane_height)
	var playhead_x := size.x * playhead_ratio
	var seconds_per_pixel := window_seconds / maxf(1.0, size.x)
	var visible_start := current_time - playhead_x * seconds_per_pixel
	var visible_end := visible_start + window_seconds

	draw_rect(Rect2(Vector2.ZERO, size), BG)
	_draw_measure_bands(visible_start, visible_end, seconds_per_pixel, ruler_height)
	draw_rect(Rect2(0.0, 0.0, size.x, ruler_height), RULER)
	draw_rect(space_rect, LANE_A)
	draw_rect(note_rect, LANE_B)
	_draw_grid(visible_start, visible_end, seconds_per_pixel, ruler_height)
	_draw_outside_song(visible_start, visible_end, seconds_per_pixel, ruler_height)
	draw_line(Vector2(0.0, space_rect.end.y), Vector2(size.x, space_rect.end.y), Color(GRID_BEAT, 0.72), 1.0)

	var visible_note_count := _draw_notes(visible_start, visible_end, seconds_per_pixel, note_rect.get_center().y)
	var visible_space_count := _draw_space_notes(visible_start, visible_end, seconds_per_pixel, space_rect.get_center().y)
	_draw_empty_state(visible_note_count + visible_space_count, ruler_height)
	_draw_lane_labels(space_rect, note_rect)
	_draw_playhead(playhead_x, ruler_height)
	_draw_hover(visible_start, seconds_per_pixel, ruler_height)

func _draw_measure_bands(visible_start: float, visible_end: float, seconds_per_pixel: float, ruler_height: float) -> void:
	var measure := (60.0 / bpm) * 4.0
	var first_measure := int(floor((visible_start - beat_offset) / measure)) - 1
	var last_measure := int(ceil((visible_end - beat_offset) / measure)) + 1
	for measure_index in range(first_measure, last_measure + 1):
		if posmod(measure_index, 2) == 0:
			continue
		var start_time := beat_offset + float(measure_index) * measure
		var end_time := start_time + measure
		var x0 := (start_time - visible_start) / seconds_per_pixel
		var x1 := (end_time - visible_start) / seconds_per_pixel
		var left := clampf(x0, 0.0, size.x)
		var right := clampf(x1, 0.0, size.x)
		if right > left:
			draw_rect(Rect2(left, ruler_height, right - left, size.y - ruler_height), Color(NORMAL, 0.018))

func _draw_grid(visible_start: float, visible_end: float, seconds_per_pixel: float, ruler_height: float) -> void:
	var beat := 60.0 / bpm
	var divisions := grid_subdivisions if snap_enabled else 1
	var step := beat / float(maxi(1, divisions))
	var first_index := int(floor((visible_start - beat_offset) / step)) - 1
	var last_index := int(ceil((visible_end - beat_offset) / step)) + 1
	for sub_index in range(first_index, last_index + 1):
		var t := beat_offset + float(sub_index) * step
		var x := (t - visible_start) / seconds_per_pixel
		if x < 0.0 or x > size.x:
			continue
		var is_beat := posmod(sub_index, divisions) == 0
		var beat_index := floori(float(sub_index) / float(divisions))
		var is_measure := is_beat and posmod(beat_index, 4) == 0
		var color := GRID_MINOR
		var width := 1.0
		if is_measure:
			color = GRID_MEASURE
			width = 2.0
		elif is_beat:
			color = GRID_BEAT
		draw_line(Vector2(x, ruler_height), Vector2(x, size.y), color, width)
		if is_measure:
			var measure_number := str(floori(float(beat_index) / 4.0) + 1)
			draw_string(mono_font, Vector2(x + 6.0, ruler_height - 8.0), measure_number, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, TEXT)
	var view_label := "%.0f SEC VIEW" % window_seconds
	var view_width := mono_font.get_string_size(view_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	draw_string(mono_font, Vector2(size.x - view_width - 12.0, ruler_height - 8.0), view_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(TEXT, 0.72))

func _draw_outside_song(visible_start: float, visible_end: float, seconds_per_pixel: float, ruler_height: float) -> void:
	if visible_start < 0.0:
		var song_start_x := clampf((0.0 - visible_start) / seconds_per_pixel, 0.0, size.x)
		draw_rect(Rect2(0.0, ruler_height, song_start_x, size.y - ruler_height), Color(BG, 0.48))
		if song_start_x > 92.0:
			draw_string(mono_font, Vector2(14.0, ruler_height + 17.0), "PRE-ROLL", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(TEXT, 0.58))
	if visible_end > duration:
		var song_end_x := clampf((duration - visible_start) / seconds_per_pixel, 0.0, size.x)
		if song_end_x < size.x:
			draw_rect(Rect2(song_end_x, ruler_height, size.x - song_end_x, size.y - ruler_height), Color(BG, 0.52))

func _draw_notes(visible_start: float, visible_end: float, seconds_per_pixel: float, y: float) -> int:
	var visible_count := 0
	for raw in events:
		if not (raw is Dictionary):
			continue
		var event_data: Dictionary = raw
		var t := float(event_data.get("time", 0.0))
		if t < visible_start or t > visible_end:
			continue
		visible_count += 1
		var x := (t - visible_start) / seconds_per_pixel
		var kind := str(event_data.get("type", "normal"))
		draw_line(Vector2(x, y - 15.0), Vector2(x, y + 15.0), Color(PLAYHEAD, 0.10), 1.0)
		match kind:
			"reverse":
				draw_circle(Vector2(x, y), 8.0, Color(BG, 0.96))
				draw_arc(Vector2(x, y), 8.0, 0.0, TAU, 24, REVERSE, 2.5, true)
				draw_circle(Vector2(x, y), 2.2, REVERSE)
			_:
				draw_circle(Vector2(x, y), 6.0, PLAYHEAD)
				draw_arc(Vector2(x, y), 8.5, 0.0, TAU, 24, NORMAL, 2.3, true)
	return visible_count

func _draw_space_notes(visible_start: float, visible_end: float, seconds_per_pixel: float, y: float) -> int:
	var visible_count := 0
	for t in space_events:
		if t < visible_start or t > visible_end:
			continue
		visible_count += 1
		var x := (t - visible_start) / seconds_per_pixel
		draw_rect(Rect2(x - 12.0, y - 11.0, 24.0, 22.0), Color(SPACE, 0.07))
		draw_line(Vector2(x, y - 16.0), Vector2(x, y + 16.0), Color(SPACE, 0.28), 1.0)
		var points := PackedVector2Array([
			Vector2(x, y - 8.0), Vector2(x + 10.0, y), Vector2(x, y + 8.0), Vector2(x - 10.0, y)
		])
		draw_colored_polygon(points, Color(SPACE, 0.72))
		draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color(SPACE, 0.98), 1.6, true)
		draw_circle(Vector2(x, y), 2.0, PLAYHEAD)
	return visible_count

func _draw_lane_labels(space_rect: Rect2, note_rect: Rect2) -> void:
	var gutter_width := minf(124.0, size.x * 0.15)
	draw_rect(Rect2(0.0, space_rect.position.y, gutter_width, space_rect.size.y), Color(BG, 0.88))
	draw_rect(Rect2(0.0, note_rect.position.y, gutter_width, note_rect.size.y), Color(BG, 0.88))
	draw_line(Vector2(gutter_width, space_rect.position.y), Vector2(gutter_width, size.y), Color(GRID_BEAT, 0.82), 1.0)
	draw_string(mono_font, Vector2(14.0, space_rect.get_center().y + 4.0), "SPACE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, SPACE)
	draw_string(mono_font, Vector2(14.0, note_rect.get_center().y + 4.0), "NOTES", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, NORMAL)

func _draw_empty_state(visible_count: int, ruler_height: float) -> void:
	if visible_count > 0:
		return
	var chart_is_empty := events.is_empty() and space_events.is_empty()
	var title := "EMPTY CHART" if chart_is_empty else "NO NOTES IN THIS WINDOW"
	var subtitle := "Generate this level or add a note at the playhead." if chart_is_empty else "Seek along the timeline to inspect another section."
	var center_x := size.x * 0.62
	var center_y := ruler_height + (size.y - ruler_height) * 0.50
	var title_width := body_font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	var subtitle_width := body_font.get_string_size(subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	draw_string(body_font, Vector2(center_x - title_width * 0.5, center_y - 3.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(PLAYHEAD, 0.74))
	draw_string(body_font, Vector2(center_x - subtitle_width * 0.5, center_y + 18.0), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(TEXT, 0.68))

func _draw_playhead(x: float, ruler_height: float) -> void:
	draw_line(Vector2(x, 0.0), Vector2(x, size.y), PLAYHEAD, 2.4)
	var marker := PackedVector2Array([Vector2(x - 5.0, ruler_height), Vector2(x + 5.0, ruler_height), Vector2(x, ruler_height + 7.0)])
	draw_colored_polygon(marker, PLAYHEAD)
	var tag_rect := Rect2(x - 20.0, 4.0, 40.0, 18.0)
	draw_rect(tag_rect, Color(PLAYHEAD, 0.10))
	draw_rect(tag_rect, Color(PLAYHEAD, 0.44), false, 1.0)
	draw_string(mono_font, Vector2(x - 12.0, 17.0), "NOW", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, PLAYHEAD)

func _draw_hover(visible_start: float, seconds_per_pixel: float, ruler_height: float) -> void:
	if hover_x < 0.0 or absf(hover_x - size.x * playhead_ratio) < 3.0:
		return
	var target_time := clampf(visible_start + hover_x * seconds_per_pixel, 0.0, duration)
	draw_line(Vector2(hover_x, ruler_height), Vector2(hover_x, size.y), Color(NORMAL, 0.44), 1.0)
	var label := _format_time(target_time)
	var label_width := mono_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 14.0
	var label_x := clampf(hover_x - label_width * 0.5, 4.0, size.x - label_width - 4.0)
	var label_rect := Rect2(label_x, size.y - 22.0, label_width, 18.0)
	draw_rect(label_rect, Color(NORMAL, 0.12))
	draw_rect(label_rect, Color(NORMAL, 0.52), false, 1.0)
	draw_string(mono_font, Vector2(label_x + 7.0, size.y - 9.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, NORMAL)

func _time_for_x(x: float) -> float:
	var playhead_x := size.x * playhead_ratio
	var seconds_per_pixel := window_seconds / maxf(1.0, size.x)
	return clampf(current_time + (x - playhead_x) * seconds_per_pixel, 0.0, duration)

func _format_time(seconds: float) -> String:
	var safe_seconds := maxf(0.0, seconds)
	var minutes := floori(safe_seconds / 60.0)
	var remainder := fmod(safe_seconds, 60.0)
	return "%02d:%05.2f" % [minutes, remainder]
