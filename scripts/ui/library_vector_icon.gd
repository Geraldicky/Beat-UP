extends Control
## Song Library's static line icons. No fonts, input handling or animation state.

var kind := "diamond"
var ink := Color("58c9ff"):
	set(value):
		ink = value
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func diamond_points(radius: float) -> PackedVector2Array:
	var center := size * 0.5
	return PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius, 0), center + Vector2(0, radius), center + Vector2(-radius, 0), center + Vector2(0, -radius)])

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.40
	match kind:
		"diamond", "double_diamond", "rank":
			var points := diamond_points(radius)
			if kind == "rank":
				draw_colored_polygon(points, Color(ink, 0.045))
				draw_polyline(points, Color(ink, 0.04), 7.0, true)
			draw_polyline(points, Color(ink, 0.35) if kind == "rank" else ink, 1.0 if kind == "rank" else 1.5, true)
			if kind == "double_diamond":
				draw_polyline(diamond_points(radius * 0.67), ink, 1.5, true)
		"arrow", "previous", "next":
			var direction := -1.0 if kind == "previous" else 1.0
			var tip := center + Vector2(radius * 0.7 * direction, 0)
			if kind == "arrow":
				draw_line(center - Vector2(radius * direction, 0), tip, ink, 1.5, true)
			draw_polyline(PackedVector2Array([tip + Vector2(-radius * 0.6 * direction, -radius * 0.6), tip, tip + Vector2(-radius * 0.6 * direction, radius * 0.6)]), ink, 1.5, true)
		"shuffle":
			for sign_value in [-1.0, 1.0]:
				var tip := center + Vector2(radius, -radius * 0.6 * sign_value)
				draw_polyline(PackedVector2Array([center + Vector2(-radius, radius * 0.6 * sign_value), center + Vector2(-radius * 0.45, radius * 0.6 * sign_value), center + Vector2(radius * 0.45, -radius * 0.6 * sign_value), tip]), ink, 1.6, true)
				draw_polyline(PackedVector2Array([tip + Vector2(-radius * 0.35, -radius * 0.3), tip, tip + Vector2(-radius * 0.35, radius * 0.3)]), ink, 1.6, true)
		"target":
			draw_arc(center, radius, -PI * 0.1, PI * 1.6, 40, ink, 1.6, true)
			draw_arc(center, radius * 0.58, 0, TAU, 36, ink, 1.4, true)
			draw_circle(center, radius * 0.16, ink)
			draw_line(center, center + Vector2(radius * 0.88, -radius * 0.88), ink, 1.5, true)
		"help":
			draw_arc(center, radius, 0, TAU, 32, ink, 1.0, true)
			draw_circle(center + Vector2(0, -radius * 0.45), 1, ink)
			draw_line(center + Vector2(0, -radius * 0.1), center + Vector2(0, radius * 0.5), ink, 1.5, true)
