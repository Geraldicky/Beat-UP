extends Control
class_name GameplayCountdownVisual

const PINK := Color("d3a4ff")
const CYAN := Color("7db4ce")
const GOLD := Color("f5c96a")
const TEXT := Color("f3f1ed")
const MUTED := Color(0.82, 0.84, 0.88, 0.34)

var _remaining: float = 3.0
var _duration: float = 3.0
var _phase: float = 0.0
var _complete: bool = false
var _step_pulse: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	_phase = fmod(_phase + delta * 2.0, TAU)
	_step_pulse = maxf(0.0, _step_pulse - delta * 4.8)
	queue_redraw()

func set_countdown(remaining: float, duration: float) -> void:
	_remaining = maxf(0.0, remaining)
	_duration = maxf(0.001, duration)
	_complete = false
	queue_redraw()

func set_go() -> void:
	# Retained for compatibility with the visual component. Initial launch no longer
	# uses this overlay; pause -> resume only needs numbered countdown steps.
	_remaining = 0.0
	_complete = true
	_step_pulse = 1.0
	queue_redraw()

func trigger_step() -> void:
	_step_pulse = 1.0
	queue_redraw()

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return

	var center: Vector2 = Vector2(size.x * 0.5, size.y * 0.49)
	var shown_second: int = clampi(ceili(_remaining), 1, maxi(1, ceili(_duration)))
	var accent: Color = _accent_for_step(shown_second)
	if _complete:
		accent = PINK

	var pulse: float = _ease_out(_step_pulse)
	var breathe: float = 0.5 + 0.5 * sin(_phase)
	var rail_alpha: float = 0.24 + breathe * 0.04 + pulse * 0.20
	var rail_span: float = minf(size.x * 0.30, 154.0)
	var rail_gap: float = 76.0
	var rail_y: float = center.y + 2.0

	# Typography is now the focal point. Thin rails create a timing gate around
	# the number without wrapping it in another heavy badge/card.
	draw_line(
		Vector2(center.x - rail_gap - rail_span, rail_y),
		Vector2(center.x - rail_gap, rail_y),
		Color(accent, rail_alpha),
		2.0,
		true
	)
	draw_line(
		Vector2(center.x + rail_gap, rail_y),
		Vector2(center.x + rail_gap + rail_span, rail_y),
		Color(accent, rail_alpha),
		2.0,
		true
	)

	# Four short diagonal brackets preserve Beat UP!'s diamond language while
	# leaving the center open and readable.
	var bracket_radius: float = 72.0 + pulse * 7.0
	var bracket_len: float = 18.0
	_draw_corner_bracket(center + Vector2(0.0, -bracket_radius), Vector2(1.0, 1.0), bracket_len, accent, pulse)
	_draw_corner_bracket(center + Vector2(bracket_radius, 0.0), Vector2(-1.0, 1.0), bracket_len, accent, pulse)
	_draw_corner_bracket(center + Vector2(0.0, bracket_radius), Vector2(-1.0, -1.0), bracket_len, accent, pulse)
	_draw_corner_bracket(center + Vector2(-bracket_radius, 0.0), Vector2(1.0, -1.0), bracket_len, accent, pulse)

	# Three compact diamonds fill from left to right as 3 -> 2 -> 1 advances.
	var total_steps: int = maxi(1, ceili(_duration))
	var active_steps: int = total_steps if _complete else clampi(total_steps - shown_second + 1, 1, total_steps)
	var tick_gap: float = 22.0
	var tick_y: float = size.y * 0.91
	var tick_start_x: float = center.x - float(total_steps - 1) * tick_gap * 0.5
	for index in range(total_steps):
		var tick_center: Vector2 = Vector2(tick_start_x + float(index) * tick_gap, tick_y)
		var active: bool = index < active_steps
		var fill: Color = Color(accent, 0.92 if active else 0.05)
		var stroke: Color = Color(accent if active else TEXT, 0.96 if active else 0.22)
		_draw_small_diamond(tick_center, 4.5 if active else 4.0, fill, stroke)

	# A very faint guide under the ticks gives the sequence a shared baseline.
	var guide_half: float = maxf(30.0, float(total_steps - 1) * tick_gap * 0.5 + 13.0)
	draw_line(
		Vector2(center.x - guide_half, tick_y + 14.0),
		Vector2(center.x + guide_half, tick_y + 14.0),
		Color(TEXT, 0.08),
		1.0,
		true
	)

func _accent_for_step(second: int) -> Color:
	match second:
		1:
			return PINK
		2:
			return GOLD
		_:
			return CYAN

func _ease_out(value: float) -> float:
	var safe: float = clampf(value, 0.0, 1.0)
	return 1.0 - pow(1.0 - safe, 3.0)

func _draw_corner_bracket(origin: Vector2, direction: Vector2, length: float, accent: Color, pulse: float) -> void:
	var horizontal: Vector2 = Vector2(direction.x, 0.0)
	var vertical: Vector2 = Vector2(0.0, direction.y)
	var alpha: float = 0.50 + pulse * 0.38
	draw_line(origin, origin + horizontal * length, Color(accent, alpha), 2.0, true)
	draw_line(origin, origin + vertical * length, Color(accent, alpha), 2.0, true)

func _draw_small_diamond(center: Vector2, radius: float, fill: Color, stroke: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(0.0, -radius),
		center + Vector2(radius, 0.0),
		center + Vector2(0.0, radius),
		center + Vector2(-radius, 0.0),
	])
	if fill.a > 0.0:
		draw_colored_polygon(points, fill)
	var outline := PackedVector2Array(points)
	outline.append(points[0])
	draw_polyline(outline, stroke, 1.4, true)
