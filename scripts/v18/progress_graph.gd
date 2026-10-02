extends Control
class_name BeatUpProgressGraph

var values := PackedFloat32Array()
var accent := Color("5bc0eb")
var line_color := Color(1, 1, 1, 0.18)

func _ready() -> void:
	custom_minimum_size = Vector2(0.0, 46.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_values(new_values: PackedFloat32Array, new_accent: Color = accent) -> void:
	values = new_values.duplicate()
	accent = new_accent
	queue_redraw()

func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2(0.0, 2.0), Vector2(maxf(1.0, size.x), maxf(1.0, size.y - 4.0)))
	draw_rect(rect, Color(0.0, 0.0, 0.0, 0.10), true)
	for ratio: float in [0.25, 0.5, 0.75]:
		var y: float = rect.position.y + rect.size.y * ratio
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), line_color, 1.0)
	if values.size() <= 0:
		return
	if values.size() == 1:
		var y_single: float = rect.end.y - rect.size.y * clampf(values[0] / 100.0, 0.0, 1.0)
		draw_circle(Vector2(rect.get_center().x, y_single), 3.0, accent)
		return
	var points := PackedVector2Array()
	for i: int in range(values.size()):
		var x: float = rect.position.x + rect.size.x * (float(i) / float(values.size() - 1))
		var y: float = rect.end.y - rect.size.y * clampf(values[i] / 100.0, 0.0, 1.0)
		points.append(Vector2(x, y))
	if points.size() >= 2:
		draw_polyline(points, accent, 2.0, true)
	for point: Vector2 in points:
		draw_circle(point, 2.5, accent)
