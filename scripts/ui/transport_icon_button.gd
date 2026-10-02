extends Button
class_name TransportIconButton

@export_enum("previous", "play", "pause", "next") var icon_mode: String = "play"

const IDLE_COLOR := Color(1.0, 1.0, 1.0, 0.84)
const HOVER_COLOR := Color("ee5795")
const HALO_IDLE := Color(1.0, 1.0, 1.0, 0.00)
const HALO_HOVER := Color(1.0, 1.0, 1.0, 0.06)
const HALO_PRESSED := Color("ee5795", 0.16)

func _ready() -> void:
	text = ""
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	resized.connect(queue_redraw)
	queue_redraw()

func set_icon_mode(value: String) -> void:
	if icon_mode == value:
		return
	icon_mode = value
	queue_redraw()

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var color: Color = HOVER_COLOR if is_hovered() else IDLE_COLOR
	var halo: Color = HALO_HOVER if is_hovered() else HALO_IDLE
	if is_pressed():
		color = Color(HOVER_COLOR, 0.96)
		halo = HALO_PRESSED

	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.46
	draw_circle(center, radius, halo)
	var h: float = size.y * 0.30
	var half_h: float = h * 0.5
	var w: float = h * 0.78

	match icon_mode:
		"previous":
			_draw_left_triangle(center, w, h, color)
		"next":
			_draw_right_triangle(center, w, h, color)
		"pause":
			var bar_w: float = maxf(2.2, h * 0.22)
			var pause_gap: float = h * 0.18
			draw_rect(Rect2(center.x - pause_gap - bar_w, center.y - half_h, bar_w, h), color)
			draw_rect(Rect2(center.x + pause_gap, center.y - half_h, bar_w, h), color)
		_:
			_draw_right_triangle(center, w, h, color)

func _draw_left_triangle(center: Vector2, width: float, height: float, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(-width * 0.5, 0.0),
		center + Vector2(width * 0.5, -height * 0.5),
		center + Vector2(width * 0.5, height * 0.5),
	])
	draw_colored_polygon(points, color)

func _draw_right_triangle(center: Vector2, width: float, height: float, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(width * 0.5, 0.0),
		center + Vector2(-width * 0.5, -height * 0.5),
		center + Vector2(-width * 0.5, height * 0.5),
	])
	draw_colored_polygon(points, color)
