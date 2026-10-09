extends Control
class_name HowToPlayVisual

const UserSettingsScript = preload("res://scripts/user_settings.gd")
const VisualTheme = preload("res://scripts/ui/minimal_theme.gd")


const BG := Color("0b0d11")
const SURFACE := Color("171a21")
const SURFACE_RAISED := Color("20242e")
const BORDER := Color("303541")
const TEXT := Color("f3f1ed")
const MUTED := Color("9898a2")
const PINK := VisualTheme.PERFECT_PINK
const CYAN := VisualTheme.GOOD_CYAN
const BLUE := VisualTheme.NORMAL_BLUE
const ORANGE := VisualTheme.DIAGONAL_ORANGE
const RED := VisualTheme.REVERSE_RED
const GOLD := VisualTheme.SPACE_GOLD
const DANGER := VisualTheme.MISS_RED
const SUCCESS := VisualTheme.GREAT_GREEN

const DIRECTIONS := {
	1: Vector2(-0.72, 0.72),
	2: Vector2(0.0, 1.0),
	3: Vector2(0.72, 0.72),
	4: Vector2(-1.0, 0.0),
	6: Vector2(1.0, 0.0),
	7: Vector2(-0.72, -0.72),
	8: Vector2(0.0, -1.0),
	9: Vector2(0.72, -0.72),
}
const KEYS_TO_NUMBERS := {
	KEY_KP_1: 1,
	KEY_KP_2: 2,
	KEY_KP_3: 3,
	KEY_KP_4: 4,
	KEY_KP_5: 5,
	KEY_KP_6: 6,
	KEY_KP_7: 7,
	KEY_KP_8: 8,
	KEY_KP_9: 9,
}

var body_font: Font
var mono_font: Font
var step_index := 0
var phase := 0.0
var demo_clock := 0.0
var highlighted_number := 0
var highlight_timer := 0.0
var space_flash_timer := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_font = load("res://assets/fonts/Poppins-Regular.ttf") as Font
	mono_font = load("res://assets/fonts/IBMPlexMono-Regular.ttf") as Font
	resized.connect(queue_redraw)
	queue_redraw()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	phase = fmod(phase + delta * 0.18, 1.0)
	demo_clock = fmod(demo_clock + delta, 2.65)
	highlight_timer = maxf(0.0, highlight_timer - delta)
	space_flash_timer = maxf(0.0, space_flash_timer - delta)
	if highlight_timer <= 0.0:
		highlighted_number = 0
	queue_redraw()

func set_step(index: int) -> void:
	step_index = clampi(index, 0, 2)
	queue_redraw()

func get_step() -> int:
	return step_index

func handle_input(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	if key_event.keycode == KEY_SPACE or key_event.physical_keycode == KEY_SPACE:
		space_flash_timer = 0.24
		queue_redraw()
		return step_index == 2
	var number := _number_from_event(key_event)
	if number <= 0:
		return false
	highlighted_number = number
	highlight_timer = 0.28
	queue_redraw()
	return true

func _number_from_event(event: InputEventKey) -> int:
	if UserSettingsScript.get_input_style() == "4_arrow":
		var arrow_map := {KEY_UP: 8, KEY_RIGHT: 6, KEY_DOWN: 2, KEY_LEFT: 4}
		for key_code in arrow_map:
			if event.keycode == key_code or event.physical_keycode == key_code:
				return int(arrow_map[key_code])
		return 0
	for key_code in KEYS_TO_NUMBERS:
		if event.keycode == key_code or event.physical_keycode == key_code:
			return int(KEYS_TO_NUMBERS[key_code])
	return 0

func _draw() -> void:
	if size.x <= 2.0 or size.y <= 2.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(BG, 0.98))
	_draw_grid()
	match step_index:
		0: _draw_controls()
		1: _draw_timing()
		2: _draw_note_types()

func _draw_grid() -> void:
	var spacing := clampf(minf(size.x, size.y) * 0.14, 44.0, 72.0)
	for x in range(int(ceil(size.x / spacing)) + 1):
		draw_line(Vector2(float(x) * spacing, 0.0), Vector2(float(x) * spacing, size.y), Color(BORDER, 0.12), 1.0)
	for y in range(int(ceil(size.y / spacing)) + 1):
		draw_line(Vector2(0.0, float(y) * spacing), Vector2(size.x, float(y) * spacing), Color(BORDER, 0.10), 1.0)
	draw_line(Vector2(0.0, 1.0), Vector2(size.x, 1.0), Color(PINK, 0.72), 2.0)

func _draw_controls() -> void:
	if UserSettingsScript.get_input_style() == "4_arrow":
		var arrow_key_size := clampf(minf(size.x / 5.4, size.y / 4.0), 58.0, 92.0)
		var center := size * 0.5 + Vector2(0.0, -8.0)
		var layout := [
			{"number": 8, "label": "↑", "offset": Vector2(0.0, -1.0)},
			{"number": 4, "label": "←", "offset": Vector2(-1.0, 0.0)},
			{"number": 6, "label": "→", "offset": Vector2(1.0, 0.0)},
			{"number": 2, "label": "↓", "offset": Vector2(0.0, 1.0)},
		]
		for item in layout:
			var pos := center + (item["offset"] as Vector2) * (arrow_key_size + 10.0)
			var rect := Rect2(pos - Vector2.ONE * arrow_key_size * 0.5, Vector2.ONE * arrow_key_size)
			var active := int(item["number"]) == highlighted_number and highlight_timer > 0.0
			draw_rect(rect, Color(CYAN, 0.20) if active else Color(SURFACE, 0.92), true)
			draw_rect(rect, CYAN if active else Color(BORDER, 0.92), false, 2.0 if active else 1.0, true)
			_draw_centered_text(mono_font, rect, str(item["label"]), 24, TEXT if active else Color(TEXT, 0.72))
		_draw_centered_text(mono_font, Rect2(24.0, size.y - 38.0, size.x - 48.0, 24.0), "PRESS ANY ARROW DIRECTION", 11, CYAN)
		return
	var key_size := clampf(minf(size.x / 5.2, size.y / 4.2), 52.0, 86.0)
	var gap := clampf(key_size * 0.12, 7.0, 11.0)
	var grid_size := Vector2(key_size * 3.0 + gap * 2.0, key_size * 3.0 + gap * 2.0)
	var top_left := Vector2((size.x - grid_size.x) * 0.5, (size.y - grid_size.y) * 0.5 - 8.0)
	var numbers := [[7, 8, 9], [4, 5, 6], [1, 2, 3]]
	for row in range(3):
		for column in range(3):
			var number := int(numbers[row][column])
			var rect := Rect2(top_left + Vector2(float(column), float(row)) * (key_size + gap), Vector2.ONE * key_size)
			var active := number == highlighted_number and highlight_timer > 0.0
			var fill := Color(CYAN, 0.20) if active else Color(SURFACE, 0.92)
			var border := CYAN if active else Color(BORDER, 0.92)
			draw_rect(rect, fill, true)
			draw_rect(rect, border, false, 2.0 if active else 1.0, true)
			_draw_text(mono_font, rect.position + Vector2(10.0, 17.0), str(number), 12, MUTED)
			if number == 5:
				_draw_centered_text(mono_font, rect, "REST", 11, Color(MUTED, 0.55))
			else:
				_draw_arrow(rect.get_center(), Vector2(DIRECTIONS[number]), TEXT, key_size * 0.21, 3.0)
	_draw_centered_text(mono_font, Rect2(24.0, size.y - 38.0, size.x - 48.0, 24.0), "PRESS ANY NUMPAD DIRECTION", 11, CYAN)

func _draw_timing() -> void:
	var lane_rect := Rect2(size.x * 0.08, size.y * 0.32, size.x * 0.84, size.y * 0.34)
	draw_rect(lane_rect, Color(SURFACE, 0.72), true)
	draw_line(Vector2(lane_rect.position.x, lane_rect.get_center().y), Vector2(lane_rect.end.x, lane_rect.get_center().y), Color(BORDER, 0.70), 1.0)
	var hit_center := Vector2(size.x * 0.28, lane_rect.get_center().y)
	var spawn_x := size.x * 0.86
	var timing_progress := clampf(demo_clock / 2.30, 0.0, 1.0)
	var note_center := Vector2(lerpf(spawn_x, hit_center.x, timing_progress), hit_center.y)
	for window_data in [
		{"offset": 34.0, "color": CYAN, "label": "GOOD"},
		{"offset": 22.0, "color": SUCCESS, "label": "GREAT"},
		{"offset": 10.0, "color": PINK, "label": "PERFECT"},
	]:
		var offset := float(window_data["offset"])
		var color := Color(window_data["color"], 0.34)
		draw_line(hit_center + Vector2(-offset, -58.0), hit_center + Vector2(-offset, 58.0), color, 1.0)
		draw_line(hit_center + Vector2(offset, -58.0), hit_center + Vector2(offset, 58.0), color, 1.0)
	_draw_diamond(hit_center, 52.0, Color(1, 1, 1, 0.055), Color(1, 1, 1, 0.82), 3.0)
	_draw_note(note_center, Vector2.UP, BLUE, "normal", 42.0)
	var judgement := "FOLLOW THE NOTE"
	var judgement_color := MUTED
	if timing_progress > 0.82:
		judgement = "HIT ON THE CENTER"
		judgement_color = PINK
	_draw_centered_text(body_font, Rect2(0.0, lane_rect.position.y - 62.0, size.x, 42.0), judgement, 22, judgement_color)
	var labels := ["PERFECT", "GREAT", "GOOD", "MISS"]
	var colors := [PINK, SUCCESS, CYAN, DANGER]
	var label_width := size.x * 0.19
	var start_x := (size.x - label_width * 4.0) * 0.5
	for index in range(labels.size()):
		_draw_centered_text(mono_font, Rect2(start_x + label_width * index, lane_rect.end.y + 26.0, label_width, 24.0), labels[index], 11, colors[index])

func _draw_note_types() -> void:
	var examples := [
		{"label": "NORMAL", "detail": "SHOWN INPUT", "direction": Vector2.UP, "outline": BLUE, "type": "normal"},
		{"label": "REVERSE", "detail": "OPPOSITE INPUT", "direction": Vector2.RIGHT, "outline": RED, "type": "reverse"},
		{"label": "SPACE", "detail": "GOLD HIT-ZONE CUE", "direction": Vector2.UP, "outline": GOLD, "type": "space"},
	]
	if UserSettingsScript.get_input_style() != "4_arrow":
		examples.insert(1, {"label": "DIAGONAL", "detail": "ORANGE OUTLINE", "direction": Vector2(0.72, -0.72), "outline": ORANGE, "type": "normal"})
	var columns := 2
	var rows := ceili(float(examples.size()) / float(columns))
	var gap := 12.0
	var margin := 22.0
	var card_size := Vector2(
		(size.x - margin * 2.0 - gap * float(columns - 1)) / float(columns),
		(size.y - margin * 2.0 - gap * float(rows - 1)) / float(rows)
	)
	for index in range(examples.size()):
		var column := index % columns
		var row: int = floori(float(index) / float(columns))
		var rect := Rect2(Vector2(margin, margin) + Vector2(float(column) * (card_size.x + gap), float(row) * (card_size.y + gap)), card_size)
		var data: Dictionary = examples[index]
		draw_rect(rect, Color(SURFACE, 0.88), true)
		draw_rect(rect, Color(BORDER, 0.88), false, 1.0, true)
		var note_center := Vector2(rect.get_center().x, rect.position.y + rect.size.y * 0.42)
		if str(data["type"]) == "space":
			_draw_diamond(note_center, minf(25.0, rect.size.y * 0.18), Color(MUTED, 0.08), Color(MUTED, 0.46), 2.0)
			_draw_diamond(note_center, minf(38.0, rect.size.y * 0.27), Color.TRANSPARENT, GOLD, 3.0)
			_draw_centered_text(mono_font, Rect2(note_center.x - 44.0, note_center.y - 8.0, 88.0, 18.0), "SPACE", 9, GOLD)
		else:
			_draw_note(note_center, Vector2(data["direction"]), Color(data["outline"]), str(data["type"]), minf(36.0, rect.size.y * 0.25))
		_draw_centered_text(mono_font, Rect2(rect.position.x + 6.0, rect.position.y + rect.size.y * 0.68, rect.size.x - 12.0, 20.0), str(data["label"]), 12, Color(data["outline"]))
		_draw_centered_text(mono_font, Rect2(rect.position.x + 6.0, rect.position.y + rect.size.y * 0.82, rect.size.x - 12.0, 18.0), str(data["detail"]), 9, MUTED)
	if space_flash_timer > 0.0:
		draw_rect(Rect2(3.0, 3.0, size.x - 6.0, size.y - 6.0), Color(GOLD, 0.20), false, 3.0, true)

func _draw_note(center: Vector2, direction: Vector2, outline: Color, note_type: String, half_extent: float) -> void:
	_draw_diamond(center + Vector2(0.0, 3.0), half_extent + 2.0, Color(0.0, 0.0, 0.0, 0.30), Color.TRANSPARENT, 0.0)
	_draw_diamond(center, half_extent, Color("101722"), outline, 3.0)
	if note_type == "space":
		_draw_centered_text(mono_font, Rect2(center - Vector2(half_extent, 10.0), Vector2(half_extent * 2.0, 22.0)), "SPACE", 9, TEXT)
	else:
		_draw_arrow(center, direction, TEXT, half_extent * 0.48, 4.0)

func _draw_diamond(center: Vector2, half_extent: float, fill: Color, stroke: Color, width: float) -> void:
	var points := PackedVector2Array([
		center + Vector2(0.0, -half_extent),
		center + Vector2(half_extent, 0.0),
		center + Vector2(0.0, half_extent),
		center + Vector2(-half_extent, 0.0),
	])
	if fill.a > 0.0:
		draw_colored_polygon(points, fill)
	if width > 0.0 and stroke.a > 0.0:
		for index in range(points.size()):
			draw_line(points[index], points[(index + 1) % points.size()], stroke, width, true)

func _draw_arrow(center: Vector2, direction: Vector2, color: Color, length: float, width: float) -> void:
	var safe_direction := direction.normalized()
	if safe_direction == Vector2.ZERO:
		return
	var start := center - safe_direction * length * 0.72
	var tip := center + safe_direction * length
	var tangent := Vector2(-safe_direction.y, safe_direction.x)
	draw_line(start, tip, color, width, true)
	draw_line(tip, tip - safe_direction * length * 0.58 + tangent * length * 0.42, color, width, true)
	draw_line(tip, tip - safe_direction * length * 0.58 - tangent * length * 0.42, color, width, true)

func _draw_text(font: Font, draw_position: Vector2, text: String, font_size: int, color: Color) -> void:
	draw_string(font, draw_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)

func _draw_centered_text(font: Font, rect: Rect2, text: String, font_size: int, color: Color) -> void:
	var baseline := rect.position + Vector2(0.0, rect.size.y * 0.72)
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, color)
