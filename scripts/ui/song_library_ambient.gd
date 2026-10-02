extends Control
class_name SongLibraryAmbient

const AMBIENT := Color("171d29")
const AMBIENT_SOFT := Color("111621")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var radius := minf(size.x * 0.48, size.y * 0.47)
	var circle_center := Vector2(size.x * 0.58, size.y * 0.18)
	draw_circle(circle_center, radius, Color(AMBIENT, 0.52))
	var diamond_center := Vector2(size.x * 0.86, size.y * 0.08)
	var half_extent := minf(size.x, size.y) * 0.30
	var diamond := PackedVector2Array([
		diamond_center + Vector2(0.0, -half_extent),
		diamond_center + Vector2(half_extent, 0.0),
		diamond_center + Vector2(0.0, half_extent),
		diamond_center + Vector2(-half_extent, 0.0),
	])
	draw_colored_polygon(diamond, Color(AMBIENT_SOFT, 0.58))
