extends Panel

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var cut := size.y * 0.26
	var points := PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(cut, size.y), Vector2(0, size.y - cut)])
	draw_colored_polygon(points, Color(0.012, 0.018, 0.025, 0.78))
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, Color(0.52, 0.73, 0.8, 0.35), 1.0, true)
	draw_line(Vector2(16, size.y * 0.65), Vector2(size.x - 16, size.y * 0.65), Color(0.52, 0.73, 0.8, 0.28), 1.0)
	for corner in [Vector2.ZERO, Vector2(size.x, 0), size]:
		var dx := -1.0 if corner.x > 0 else 1.0
		var dy := -1.0 if corner.y > 0 else 1.0
		draw_line(corner, corner + Vector2(dx * 14, 0), Color(0.55, 0.88, 1.0, 0.7), 1.0)
		draw_line(corner, corner + Vector2(0, dy * 14), Color(0.55, 0.88, 1.0, 0.7), 1.0)
