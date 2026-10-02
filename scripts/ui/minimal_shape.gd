extends Control
class_name MinimalShape

@export_enum("panel", "lane", "ring", "diamond", "burst") var shape := "panel"
@export var fill_color := Color("171a21")
@export var stroke_color := Color("303541")
@export_range(0.0, 12.0, 0.5) var stroke_width := 2.0
@export_range(0.0, 48.0, 1.0) var radius := 12.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	match shape:
		"ring":
			var center := size * 0.5
			var ring_radius := maxf(2.0, minf(size.x, size.y) * 0.5 - stroke_width)
			if fill_color.a > 0.0:
				draw_circle(center, ring_radius, fill_color)
			draw_arc(center, ring_radius, 0.0, TAU, 96, stroke_color, stroke_width, true)
		"diamond":
			var points := PackedVector2Array([
				Vector2(size.x * 0.5, stroke_width),
				Vector2(size.x - stroke_width, size.y * 0.5),
				Vector2(size.x * 0.5, size.y - stroke_width),
				Vector2(stroke_width, size.y * 0.5),
			])
			if fill_color.a > 0.0:
				draw_colored_polygon(points, fill_color)
			for i in range(points.size()):
				draw_line(points[i], points[(i + 1) % points.size()], stroke_color, stroke_width, true)
		"burst":
			var center := size * 0.5
			var burst_radius := minf(size.x, size.y) * 0.48
			for i in range(12):
				var angle := float(i) * TAU / 12.0
				var direction := Vector2(cos(angle), sin(angle))
				draw_line(center + direction * burst_radius * 0.44, center + direction * burst_radius, stroke_color, stroke_width, true)
		_:
			var style := StyleBoxFlat.new()
			style.bg_color = fill_color
			style.border_color = stroke_color
			style.set_border_width_all(int(round(stroke_width)))
			style.set_corner_radius_all(int(round(radius if shape == "panel" else minf(radius, size.y * 0.5))))
			draw_style_box(style, Rect2(Vector2.ZERO, size))

