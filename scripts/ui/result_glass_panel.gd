extends PanelContainer

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	# Arc accents follow the actual rounded StyleBox, not square brackets.
	var radius := 14.0 * clampf(get_viewport_rect().size.y / 1080.0, 0.66, 1.0)
	var color := Color(0.85, 0.92, 1.0, 0.65)
	for arc in [[Vector2(radius, radius), PI], [Vector2(size.x - radius, radius), PI * 1.5], [size - Vector2.ONE * radius, 0.0], [Vector2(radius, size.y - radius), PI * 0.5]]:
		draw_arc(arc[0], radius, arc[1], arc[1] + PI * 0.5, 16, color, 1.0, true)
