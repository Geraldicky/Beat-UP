extends Control
class_name CalibrationTimingGraph

const BG := Color("10131a")
const GRID := Color("2b313d")
const MUTED := Color("7d8390")
const TEXT := Color("f2f1ee")
const CYAN := Color("7db4ce")
const PINK := Color("d3a4ff")
const GOLD := Color("f5c96a")
const DANGER := Color("ff704d")

@export_range(80.0, 300.0, 5.0) var range_ms := 220.0

var samples_ms: Array[float] = []
var result_offset_ms := 0.0
var result_jitter_ms := 0.0
var has_result := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func reset() -> void:
	samples_ms.clear()
	has_result = false
	result_offset_ms = 0.0
	result_jitter_ms = 0.0
	queue_redraw()

func add_sample(delta_ms: float) -> void:
	samples_ms.append(clampf(delta_ms, -range_ms, range_ms))
	queue_redraw()

func set_result(offset_ms: float, jitter_ms: float) -> void:
	result_offset_ms = clampf(offset_ms, -range_ms, range_ms)
	result_jitter_ms = maxf(0.0, jitter_ms)
	has_result = true
	queue_redraw()

func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	draw_rect(bounds, Color(BG, 0.72), true)
	var plot := Rect2(22.0, 30.0, maxf(1.0, size.x - 44.0), maxf(1.0, size.y - 48.0))
	draw_line(Vector2(plot.position.x, plot.position.y), Vector2(plot.position.x, plot.end.y), Color(GRID, 0.55), 1.0)
	draw_line(Vector2(plot.end.x, plot.position.y), Vector2(plot.end.x, plot.end.y), Color(GRID, 0.55), 1.0)
	for guide_ms in [-100.0, 0.0, 100.0]:
		var x := _x_for_ms(guide_ms, plot)
		var guide_color := Color(PINK, 0.72) if is_zero_approx(guide_ms) else Color(GRID, 0.82)
		draw_line(Vector2(x, plot.position.y), Vector2(x, plot.end.y), guide_color, 1.0 if not is_zero_approx(guide_ms) else 2.0)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(plot.position.x, 18.0), "EARLY", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, MUTED)
	draw_string(font, Vector2(plot.position.x + plot.size.x * 0.5 - 18.0, 18.0), "0 MS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, PINK)
	draw_string(font, Vector2(plot.end.x - 30.0, 18.0), "LATE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, MUTED)
	var center_y := plot.position.y + plot.size.y * 0.56
	draw_line(Vector2(plot.position.x, center_y), Vector2(plot.end.x, center_y), Color(GRID, 0.64), 1.0)
	for index in range(samples_ms.size()):
		var value := samples_ms[index]
		var x := _x_for_ms(value, plot)
		var lane := float(index % 5) / 4.0
		var y := lerpf(plot.position.y + 9.0, plot.end.y - 9.0, lane)
		var dot_color := CYAN
		if absf(value) > 120.0:
			dot_color = DANGER
		elif absf(value) > 60.0:
			dot_color = GOLD
		draw_line(Vector2(x, center_y), Vector2(x, y), Color(dot_color, 0.18), 1.0)
		draw_circle(Vector2(x, y), 4.2, dot_color)
	if has_result:
		var result_x := _x_for_ms(result_offset_ms, plot)
		var jitter_width := maxf(2.0, result_jitter_ms / (range_ms * 2.0) * plot.size.x)
		draw_rect(Rect2(result_x - jitter_width, plot.position.y, jitter_width * 2.0, plot.size.y), Color(PINK, 0.08), true)
		draw_line(Vector2(result_x, plot.position.y), Vector2(result_x, plot.end.y), PINK, 2.5)

func _x_for_ms(value_ms: float, plot: Rect2) -> float:
	return remap(clampf(value_ms, -range_ms, range_ms), -range_ms, range_ms, plot.position.x, plot.end.x)
