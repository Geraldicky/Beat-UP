extends Control
class_name BeatUpActionIcon

@export_enum("resume", "retry", "settings", "exit", "song_list", "power") var icon_type := "resume"
@export_enum("diamond", "hexagon", "none") var frame_shape := "diamond"
@export var icon_color := Color("f4f6fb")
@export var accent_color := Color("a9b8ff")
@export var badge_fill_color := Color(0.663, 0.722, 1.0, 0.06)
@export var badge_hover_fill_color := Color(0.663, 0.722, 1.0, 0.14)
@export_range(1.0, 8.0, 0.5) var stroke_width := 3.0

var _active := false
var _phase := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_sync_pivot)
	_sync_pivot()
	set_process(icon_type == "power" or frame_shape != "none")
	queue_redraw()

func _sync_pivot() -> void:
	pivot_offset = size * 0.5

func _process(delta: float) -> void:
	_phase = fmod(_phase + delta, TAU)
	if _active or icon_type == "power":
		queue_redraw()

func set_active(value: bool) -> void:
	_active = value
	set_process(icon_type == "power" or (frame_shape != "none" and _active))
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var unit := minf(size.x, size.y)
	var radius := unit * 0.27
	var frame_radius := unit * 0.45
	var glow_alpha := 0.12 + (0.05 * sin(_phase * 3.0) if _active else 0.0)
	_draw_frame(center, frame_radius, glow_alpha)

	match icon_type:
		"retry":
			_draw_retry(center, radius)
		"settings":
			_draw_settings(center, radius)
		"exit":
			_draw_exit(center, radius)
		"song_list":
			_draw_song_list(center, radius)
		"power":
			_draw_power(center, radius)
		_:
			_draw_resume(center, radius)

func _draw_frame(center: Vector2, radius: float, glow_alpha: float) -> void:
	if frame_shape == "none":
		return
	var frame := PackedVector2Array()
	if frame_shape == "hexagon":
		for index in range(6):
			var angle := PI / 6.0 + TAU * float(index) / 6.0
			frame.append(center + Vector2(cos(angle), sin(angle)) * radius)
		frame.append(frame[0])
	else:
		frame = PackedVector2Array([
			center + Vector2(0.0, -radius),
			center + Vector2(radius, 0.0),
			center + Vector2(0.0, radius),
			center + Vector2(-radius, 0.0),
			center + Vector2(0.0, -radius),
		])
	var fill := badge_hover_fill_color if _active else badge_fill_color
	fill.a = clampf(fill.a + (glow_alpha * 0.25 if _active else 0.0), 0.0, 1.0)
	draw_colored_polygon(PackedVector2Array(frame.slice(0, frame.size() - 1)), fill)
	draw_polyline(frame, Color(accent_color, 0.42 if not _active else 0.92), 2.4 if _active else 1.6, true)
	if _active:
		var inner := PackedVector2Array()
		for point in frame.slice(0, frame.size() - 1):
			inner.append(center + (point - center) * 0.88)
		inner.append(inner[0])
		draw_polyline(inner, Color(accent_color, 0.42), 1.5, true)

func _draw_resume(center: Vector2, radius: float) -> void:
	var triangle := PackedVector2Array([
		center + Vector2(-radius * 0.44, -radius * 0.72),
		center + Vector2(radius * 0.78, 0.0),
		center + Vector2(-radius * 0.44, radius * 0.72),
	])
	draw_colored_polygon(triangle, icon_color)

func _draw_retry(center: Vector2, radius: float) -> void:
	draw_arc(center, radius * 0.72, -PI * 0.12, PI * 1.44, 44, icon_color, stroke_width, true)
	var tip: Vector2 = center + Vector2(cos(-PI * 0.12), sin(-PI * 0.12)) * radius * 0.72
	var arrow := PackedVector2Array([
		tip + Vector2(-radius * 0.05, -radius * 0.34),
		tip + Vector2(radius * 0.36, -radius * 0.02),
		tip + Vector2(-radius * 0.15, radius * 0.12),
	])
	draw_colored_polygon(arrow, icon_color)

func _draw_exit(center: Vector2, radius: float) -> void:
	var door_left := center.x + radius * 0.10
	var door_right := center.x + radius * 0.72
	var top := center.y - radius * 0.78
	var bottom := center.y + radius * 0.78
	draw_line(Vector2(door_left, top), Vector2(door_right, top), icon_color, stroke_width, true)
	draw_line(Vector2(door_right, top), Vector2(door_right, bottom), icon_color, stroke_width, true)
	draw_line(Vector2(door_right, bottom), Vector2(door_left, bottom), icon_color, stroke_width, true)
	var arrow_y := center.y
	draw_line(Vector2(center.x - radius * 0.72, arrow_y), Vector2(center.x + radius * 0.28, arrow_y), icon_color, stroke_width + 1.0, true)
	draw_line(Vector2(center.x - radius * 0.72, arrow_y), Vector2(center.x - radius * 0.30, arrow_y - radius * 0.38), icon_color, stroke_width + 1.0, true)
	draw_line(Vector2(center.x - radius * 0.72, arrow_y), Vector2(center.x - radius * 0.30, arrow_y + radius * 0.38), icon_color, stroke_width + 1.0, true)

func _draw_settings(center: Vector2, radius: float) -> void:
	# Sliders communicate "settings" more clearly than a sun-like radial glyph.
	var half: float = radius * 0.78
	var ys: Array[float] = [-0.50, 0.0, 0.50]
	var knobs: Array[float] = [-0.20, 0.36, -0.42]
	for i: int in range(3):
		var y: float = center.y + ys[i] * radius
		draw_line(Vector2(center.x - half, y), Vector2(center.x + half, y), icon_color, stroke_width, true)
		var knob_x: float = center.x + knobs[i] * radius
		draw_circle(Vector2(knob_x, y), radius * 0.16, icon_color)
		draw_circle(Vector2(knob_x, y), radius * 0.085, Color(0.02, 0.025, 0.04, 1.0))

func _draw_song_list(center: Vector2, radius: float) -> void:
	var left := center.x - radius * 0.78
	for row in range(3):
		var y := center.y - radius * 0.52 + float(row) * radius * 0.50
		draw_circle(Vector2(left, y), stroke_width * 0.72, icon_color)
		draw_line(Vector2(left + radius * 0.24, y), Vector2(center.x + radius * 0.12, y), icon_color, stroke_width, true)
	var stem_x := center.x + radius * 0.48
	draw_line(Vector2(stem_x, center.y - radius * 0.72), Vector2(stem_x, center.y + radius * 0.38), icon_color, stroke_width, true)
	draw_line(Vector2(stem_x, center.y - radius * 0.72), Vector2(stem_x + radius * 0.42, center.y - radius * 0.52), icon_color, stroke_width, true)
	draw_circle(Vector2(stem_x - radius * 0.15, center.y + radius * 0.48), radius * 0.22, icon_color)

func _draw_power(center: Vector2, radius: float) -> void:
	var pulse := 1.0 + sin(_phase * 2.6) * 0.025
	draw_arc(center, radius * 0.88 * pulse, -PI * 0.24, PI * 1.24, 42, icon_color, stroke_width + 0.5, true)
	draw_line(center + Vector2(0.0, -radius * 1.00), center + Vector2(0.0, -radius * 0.05), icon_color, stroke_width + 0.5, true)
