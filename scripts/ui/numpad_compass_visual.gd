extends Control
class_name NumpadCompassVisual

const PINK := Color("d3a4ff")
const CYAN := Color("7db4ce")
const TEXT := Color("f3f1ed")
const SURFACE := Color("171a21")
const BORDER := Color("303541")

const NUMPAD_LAYOUT := [
	{"key": KEY_KP_7, "label": "7", "grid": Vector2(-1.0, -1.0)},
	{"key": KEY_KP_8, "label": "8", "grid": Vector2(0.0, -1.0)},
	{"key": KEY_KP_9, "label": "9", "grid": Vector2(1.0, -1.0)},
	{"key": KEY_KP_4, "label": "4", "grid": Vector2(-1.0, 0.0)},
	{"key": KEY_KP_6, "label": "6", "grid": Vector2(1.0, 0.0)},
	{"key": KEY_KP_1, "label": "1", "grid": Vector2(-1.0, 1.0)},
	{"key": KEY_KP_2, "label": "2", "grid": Vector2(0.0, 1.0)},
	{"key": KEY_KP_3, "label": "3", "grid": Vector2(1.0, 1.0)},
]

const ARROW_LAYOUT := [
	{"key": KEY_UP, "label": "↑", "grid": Vector2(0.0, -1.0)},
	{"key": KEY_LEFT, "label": "←", "grid": Vector2(-1.0, 0.0)},
	{"key": KEY_RIGHT, "label": "→", "grid": Vector2(1.0, 0.0)},
	{"key": KEY_DOWN, "label": "↓", "grid": Vector2(0.0, 1.0)},
]

var _mono_font: Font
var _active_key := KEY_NONE
var _activity := 0.0
var _phase := 0.0
var _input_style := "8_direction"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mono_font = load("res://assets/fonts/IBMPlexMono-Regular.ttf") as Font
	resized.connect(queue_redraw)
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	_phase = fmod(_phase + delta * 8.0, TAU)
	if _activity > 0.0:
		_activity = maxf(0.0, _activity - delta * 4.8)
		if _activity <= 0.0:
			_active_key = KEY_NONE
		queue_redraw()

func set_input_style(style: String) -> void:
	_input_style = "4_arrow" if style == "4_arrow" else "8_direction"
	reset_activity()
	queue_redraw()

func _active_layout() -> Array:
	return ARROW_LAYOUT if _input_style == "4_arrow" else NUMPAD_LAYOUT

func flash_key(keycode: int) -> void:
	if not _supports_key(keycode):
		return
	_active_key = keycode
	_activity = 1.0
	_phase = 0.0
	queue_redraw()

func reset_activity() -> void:
	_active_key = KEY_NONE
	_activity = 0.0
	queue_redraw()

func get_active_key() -> int:
	return _active_key

func get_activity() -> float:
	return _activity

func _supports_key(keycode: int) -> bool:
	for item in _active_layout():
		if int(item["key"]) == keycode:
			return true
	return false

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var center := size * 0.5
	var short_side := minf(size.x, size.y)
	var spacing := short_side * 0.285
	var cell_radius := clampf(short_side * 0.105, 7.0, 14.0)
	var font_size := clampi(roundi(short_side * 0.087), 9, 12)

	# A faint radial scaffold makes the layout read as one compass rather than
	# eight unrelated key labels.
	for item in _active_layout():
		var key_position: Vector2 = center + (item["grid"] as Vector2) * spacing
		draw_line(center, key_position, Color(BORDER, 0.16), 1.0, true)

	_draw_diamond(center, cell_radius * 0.42, Color(PINK, 0.42), Color(PINK, 0.80), 1.0)
	for item in _active_layout():
		var keycode := int(item["key"])
		var key_position: Vector2 = center + (item["grid"] as Vector2) * spacing
		var active := keycode == _active_key and _activity > 0.0
		var pulse := 1.0 + (0.10 + sin(_phase) * 0.025) * _activity if active else 1.0
		var radius := cell_radius * pulse
		if active:
			_draw_diamond(key_position, radius + 5.0 * _activity, Color(CYAN, 0.08 * _activity), Color(CYAN, 0.34 * _activity), 1.5)
		_draw_diamond(
			key_position,
			radius,
			Color(CYAN, 0.82) if active else Color(SURFACE, 0.74),
			TEXT if active else Color(TEXT, 0.20),
			2.0 if active else 1.0
		)
		var label_color := Color("0b0d11") if active else Color(TEXT, 0.46)
		draw_string(
			_mono_font,
			Vector2(key_position.x - radius, key_position.y + float(font_size) * 0.36),
			str(item["label"]),
			HORIZONTAL_ALIGNMENT_CENTER,
			radius * 2.0,
			font_size,
			label_color
		)

func _draw_diamond(center: Vector2, radius: float, fill: Color, stroke: Color, width: float) -> void:
	var points := PackedVector2Array([
		center + Vector2(0.0, -radius),
		center + Vector2(radius, 0.0),
		center + Vector2(0.0, radius),
		center + Vector2(-radius, 0.0),
	])
	draw_colored_polygon(points, fill)
	var outline := PackedVector2Array(points)
	outline.append(points[0])
	draw_polyline(outline, stroke, width, true)
