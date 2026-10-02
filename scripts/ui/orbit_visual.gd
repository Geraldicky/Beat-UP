extends Control
class_name OrbitVisual

@export var accent := Color("ee5795")
@export var secondary := Color("a9b8ff")
@export_range(1.0, 8.0, 0.5) var line_width := 2.0
@export var show_directions := true
@export var show_crosshair := true
@export_range(0.0, 1.0, 0.01) var inner_fill_alpha := 0.03

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var radius := maxf(8.0, minf(size.x, size.y) * 0.39)
	draw_circle(center, radius * 0.74, Color(accent, inner_fill_alpha))
	draw_arc(center, radius, 0.0, TAU, 128, Color(accent, 0.88), line_width, true)
	draw_arc(center, radius * 0.78, -0.25, 4.55, 96, Color(secondary, 0.42), maxf(1.0, line_width * 0.75), true)
	draw_arc(center, radius * 0.58, 0.75, 5.8, 96, Color(accent, 0.24), 1.0, true)
	if show_crosshair:
		draw_line(center + Vector2(-radius * 1.12, 0), center + Vector2(radius * 1.12, 0), Color(secondary, 0.16), 1.0)
		draw_line(center + Vector2(0, -radius * 1.12), center + Vector2(0, radius * 1.12), Color(secondary, 0.16), 1.0)
	if show_directions:
		for i in range(8):
			var angle := -PI * 0.5 + float(i) * TAU / 8.0
			var direction := Vector2(cos(angle), sin(angle))
			var p1 := center + direction * radius * 0.87
			var p2 := center + direction * radius * 1.04
			draw_line(p1, p2, Color("f3f1ed"), 2.0, true)
			var tangent := Vector2(-direction.y, direction.x)
			draw_line(p2, p2 - direction * 8.0 + tangent * 4.0, Color("f3f1ed"), 2.0, true)
			draw_line(p2, p2 - direction * 8.0 - tangent * 4.0, Color("f3f1ed"), 2.0, true)

