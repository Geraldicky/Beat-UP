extends Control
class_name ResultRankMeter

@export_range(0.0, 100.0, 0.01) var value := 0.0:
	set(next_value):
		value = clampf(next_value, 0.0, 100.0)
		queue_redraw()
@export_range(4.0, 28.0, 0.5) var ring_width := 14.0
@export var track_color := Color(0.188, 0.208, 0.255, 0.45)
@export var danger_color := Color("ff704d")
@export var caution_color := Color("f7c75e")
@export var success_color := Color("9ad878")
@export var accent_secondary := Color("7db4ce")
@export var accent_primary := Color("ee5795")

var c_threshold := 70.0
var b_threshold := 80.0
var a_threshold := 90.0
var s_threshold := 97.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not resized.is_connected(queue_redraw):
		resized.connect(queue_redraw)
	queue_redraw()

func set_thresholds(c_value: float, b_value: float, a_value: float, s_value: float) -> void:
	c_threshold = clampf(c_value, 0.0, 100.0)
	b_threshold = clampf(b_value, c_threshold, 100.0)
	a_threshold = clampf(a_value, b_threshold, 100.0)
	s_threshold = clampf(s_value, a_threshold, 100.0)
	queue_redraw()

func set_palette(danger: Color, caution: Color, success: Color, secondary: Color, primary: Color) -> void:
	danger_color = danger
	caution_color = caution
	success_color = success
	accent_secondary = secondary
	accent_primary = primary
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var radius := maxf(12.0, minf(size.x, size.y) * 0.5 - ring_width - 8.0)
	draw_arc(center, radius, -PI * 0.5, PI * 1.5, 160, track_color, ring_width, true)

	var segments := [
		{"from": 0.0, "to": c_threshold, "color": danger_color},
		{"from": c_threshold, "to": b_threshold, "color": caution_color},
		{"from": b_threshold, "to": a_threshold, "color": success_color},
		{"from": a_threshold, "to": s_threshold, "color": accent_secondary},
		{"from": s_threshold, "to": 100.0, "color": accent_primary},
	]
	for segment in segments:
		_draw_percent_arc(center, radius, float(segment["from"]), float(segment["to"]), Color(segment["color"], 0.18), ring_width)
	for segment in segments:
		var start_value := float(segment["from"])
		var end_value := minf(value, float(segment["to"]))
		if end_value > start_value:
			_draw_percent_arc(center, radius, start_value, end_value, segment["color"], ring_width)

	for threshold in [c_threshold, b_threshold, a_threshold, s_threshold]:
		_draw_tick(center, radius, threshold)
	draw_arc(center, radius - ring_width * 0.82, -PI * 0.5, PI * 1.5, 128, Color(track_color, 0.36), 1.0, true)

func _draw_percent_arc(center: Vector2, radius: float, start_percent: float, end_percent: float, color: Color, width: float) -> void:
	var start_angle := -PI * 0.5 + TAU * start_percent / 100.0
	var end_angle := -PI * 0.5 + TAU * end_percent / 100.0
	var points := maxi(4, ceili(absf(end_angle - start_angle) / TAU * 160.0))
	draw_arc(center, radius, start_angle, end_angle, points, color, width, true)

func _draw_tick(center: Vector2, radius: float, percent: float) -> void:
	var angle := -PI * 0.5 + TAU * percent / 100.0
	var direction := Vector2(cos(angle), sin(angle))
	var inner := center + direction * (radius - ring_width * 0.66)
	var outer := center + direction * (radius + ring_width * 0.66)
	draw_line(inner, outer, Color("0b0d11"), 3.0, true)
