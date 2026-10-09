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
var _input_style := "8_direction"
var _binding_labels: Dictionary = {}
var _space_label := "SPACE"

func set_binding_snapshot(snapshot: Dictionary) -> void:
	# Presentation-only copy of the run snapshot; no live settings lookup.
	_binding_labels.clear()
	var bindings: Dictionary = snapshot.get("bindings", {})
	for item in _active_layout():
		var action := "8k_%s" % str(item["label"])
		if _input_style == "4_arrow":
			action = {KEY_UP: "4k_up", KEY_DOWN: "4k_down", KEY_LEFT: "4k_left", KEY_RIGHT: "4k_right"}[item["key"]]
		var keycode := int(bindings.get(action, item["key"]))
		_binding_labels[int(item["key"])] = OS.get_keycode_string(keycode).replace("Kp ", "").to_upper()
	_space_label = OS.get_keycode_string(int(bindings.get("space", KEY_SPACE))).to_upper()
	queue_redraw()

func get_binding_label(keycode: int) -> String:
	return str(_binding_labels.get(keycode, ""))

func get_space_label() -> String:
	return _space_label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mono_font = load("res://assets/fonts/IBMPlexMono-Regular.ttf") as Font
	resized.connect(queue_redraw)
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	if _activity > 0.0:
		_activity = maxf(0.0, _activity - delta * 4.8)
		if _activity <= 0.0:
			_active_key = KEY_NONE
		queue_redraw()

func set_input_style(style: String) -> void:
	_input_style = "4_arrow" if style == "4_arrow" else "8_direction"
	_binding_labels.clear()
	reset_activity()
	queue_redraw()

func _active_layout() -> Array:
	return ARROW_LAYOUT if _input_style == "4_arrow" else NUMPAD_LAYOUT

func flash_key(keycode: int) -> void:
	if not _supports_key(keycode):
		return
	_active_key = keycode
	_activity = 1.0
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
	var cell_radius := clampf(short_side * 0.12, 12.0, 21.0)
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
		var radius := cell_radius
		var rect := Rect2(key_position - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
		draw_rect(rect, Color(CYAN, 0.16) if active else Color(SURFACE, 0.88))
		draw_rect(rect, Color(CYAN, 0.95) if active else Color(TEXT, 0.28), false, 1.0)
		var label_color := CYAN if active else Color(TEXT, 0.76)
		var direction: Vector2 = (item["grid"] as Vector2).normalized()
		var arrow_center := key_position + Vector2(0, radius * 0.40)
		var tip := arrow_center + direction * radius * 0.22
		draw_line(arrow_center - direction * radius * 0.22, tip, label_color, 1.5, true)
		for sign_value: float in [-1.0, 1.0]:
			draw_line(tip, tip - direction * radius * 0.18 + direction.orthogonal() * sign_value * radius * 0.15, label_color, 1.5, true)
		var label := str(_binding_labels.get(keycode, item["label"]))
		var label_size := font_size
		while label_size > 7 and _mono_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x > radius * 1.8:
			label_size -= 1
		if label.length() > 5:
			label = label.substr(0, 4) + "…"
		draw_string(
			_mono_font,
			Vector2(key_position.x - radius, key_position.y - radius * 0.1),
			label,
			HORIZONTAL_ALIGNMENT_CENTER,
			radius * 2.0,
			label_size,
			label_color
		)
	draw_string(_mono_font, Vector2(0, 12), "INPUT · %s" % ("4K" if _input_style == "4_arrow" else "8K"), HORIZONTAL_ALIGNMENT_LEFT, size.x, 10, Color(TEXT, 0.55))
	draw_string(_mono_font, Vector2(0, size.y - 1), _space_label, HORIZONTAL_ALIGNMENT_CENTER, size.x, 10, Color("f6c96a"))

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
