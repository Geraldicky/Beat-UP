extends Control
class_name TaikoLaneVisual

# Code-native lane renderer inspired by the clear hierarchy of taiko rhythm
# games. It deliberately uses only flat colour, lines, and spacing so the
# gameplay remains readable without depending on image assets.

@export var surface_color := Color(0.018, 0.025, 0.036, 0.58)
@export var input_surface_color := Color(0.018, 0.025, 0.036, 0.64)
@export var border_color := Color(0.36, 0.42, 0.56, 0.30)
@export var guide_color := Color(0.85, 0.88, 1.0, 0.28)
@export var tick_color := Color(0.85, 0.88, 1.0, 0.10)
@export_range(24.0, 120.0, 1.0) var tick_spacing := 58.0
@export_range(1, 8, 1) var major_tick_interval := 4

var receptor_x := 180.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func set_receptor_x(value: float) -> void:
	receptor_x = clampf(value, 0.0, size.x)
	queue_redraw()

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var full_rect := Rect2(Vector2.ZERO, size)
	draw_rect(full_rect, surface_color)

	# The darker input deck anchors the receptor and visually separates input
	# from the scrolling note field without introducing another colour.
	var deck_right := clampf(receptor_x + minf(54.0, size.y * 0.34), 0.0, size.x)
	draw_rect(Rect2(0.0, 0.0, deck_right, size.y), input_surface_color)
	draw_line(Vector2(deck_right, 0.0), Vector2(deck_right, size.y), border_color, 1.0)

	var center_y := size.y * 0.5
	draw_line(Vector2(deck_right, center_y), Vector2(size.x, center_y), Color(border_color, 0.22), 1.0)
	draw_line(Vector2(0.0, 1.0), Vector2(size.x, 1.0), border_color, 2.0)
	draw_line(Vector2(0.0, size.y - 1.0), Vector2(size.x, size.y - 1.0), border_color, 2.0)

	# Timing ticks originate at the hit receptor, reinforcing direction and
	# speed while staying subtle enough to sit behind notes.
	var tick_index := 1
	var tick_x := receptor_x + tick_spacing
	while tick_x < size.x:
		var is_major := tick_index % major_tick_interval == 0
		var tick_alpha := 0.11 if is_major else 0.04
		var tick_height := size.y * (0.34 if is_major else 0.20)
		var color := Color(tick_color, tick_alpha)
		draw_line(Vector2(tick_x, center_y - tick_height), Vector2(tick_x, center_y + tick_height), color, 2.0 if is_major else 1.0)
		tick_x += tick_spacing
		tick_index += 1

	# A short accent guide is the only saturated decoration on the lane.
	var guide_half := minf(size.y * 0.32, 54.0)
	draw_line(Vector2(receptor_x, center_y - guide_half), Vector2(receptor_x, center_y + guide_half), guide_color, 2.0)
	# Restrained alignment marks, not orbit/ring decoration. The eye returns to
	# the white diamond while the note field remains free of trails and bloom.
	var guide_end := size.y * 0.5 + 62.0
	for sign_value: float in [-1.0, 1.0]:
		draw_line(Vector2(receptor_x, center_y + sign_value * (guide_half + 28.0)), Vector2(receptor_x, center_y + sign_value * guide_end), Color(guide_color, 0.24), 1.0)
