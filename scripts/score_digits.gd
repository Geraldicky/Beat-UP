extends Label
class_name ScoreDigits

@export_range(1, 12, 1) var minimum_digits := 8
@export_range(0.10, 0.50, 0.01) var roll_duration := 0.18
@export_range(0.0, 0.05, 0.001) var digit_stagger := 0.012
@export_range(0.0, 0.04, 0.001) var extra_step_duration := 0.012

var _last_value := -1
var _target_text := ""
var _roll_tween: Tween

func _ready() -> void:
	add_theme_font_override("font", load("res://assets/fonts/IBMPlexMono-Regular.ttf"))
	add_theme_font_size_override("font_size", 34)
	add_theme_color_override("font_color", Color("f3f1ed"))
	text = ""
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)
	reset_value(0)

func set_value(value: int, animated := true) -> void:
	value = maxi(0, value)
	if value == _last_value:
		return
	var next_text := _format_value(value)
	if _last_value < 0 or not animated or not is_inside_tree():
		_last_value = value
		_target_text = next_text
		_cancel_roll()
		_render_static(_target_text)
		return

	var previous_text := _target_text
	_last_value = value
	_target_text = next_text
	_animate_roll(previous_text, _target_text)

func reset_value(value: int = 0) -> void:
	_last_value = maxi(0, value)
	_target_text = _format_value(_last_value)
	_cancel_roll()
	_render_static(_target_text)

func refresh_style() -> void:
	_cancel_roll()
	_render_static(_target_text)

func is_rolling() -> bool:
	return _roll_tween != null

func get_value() -> int:
	return _last_value

func _format_value(value: int) -> String:
	return str(value).pad_zeros(minimum_digits)

func _animate_roll(previous_text: String, next_text: String) -> void:
	_cancel_roll()
	var digit_count: int = maxi(previous_text.length(), next_text.length())
	previous_text = previous_text.pad_zeros(digit_count)
	next_text = next_text.pad_zeros(digit_count)
	_clear_digit_columns()

	var digit_width := _get_digit_width()
	var column_height := maxf(1.0, size.y)
	var start_x := 0.0
	var animated_reels: Array[Dictionary] = []

	for index in range(digit_count):
		var from_digit := int(previous_text.substr(index, 1))
		var to_digit := int(next_text.substr(index, 1))
		var forward_steps := (to_digit - from_digit + 10) % 10
		var column := _create_column(start_x + digit_width * index, digit_width, column_height)
		var reel := Control.new()
		reel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		reel.size = Vector2(digit_width, column_height * (forward_steps + 1))
		column.add_child(reel)

		for step in range(forward_steps + 1):
			var digit := (from_digit + step) % 10
			var digit_label := _create_digit_label(str(digit), digit_width, column_height)
			digit_label.position.y = column_height * step
			reel.add_child(digit_label)

		if forward_steps > 0:
			animated_reels.append({
				"reel": reel,
				"steps": forward_steps,
				"delay": float(digit_count - index - 1) * digit_stagger,
			})

	if animated_reels.is_empty():
		_render_static(_target_text)
		return

	_roll_tween = create_tween()
	_roll_tween.set_parallel(true)
	for reel_data in animated_reels:
		var reel := reel_data["reel"] as Control
		var steps := int(reel_data["steps"])
		var delay := float(reel_data["delay"])
		var duration := roll_duration + float(maxi(0, steps - 1)) * extra_step_duration
		_roll_tween.tween_property(
			reel,
			"position:y",
			-column_height * steps,
			duration
		).set_delay(delay).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_roll_tween.chain().tween_callback(Callable(self, "_finish_roll"))

func _render_static(value_text: String) -> void:
	_clear_digit_columns()
	if value_text.is_empty():
		return
	var digit_width := _get_digit_width()
	var column_height := maxf(1.0, size.y)
	var start_x := 0.0
	for index in range(value_text.length()):
		var column := _create_column(start_x + digit_width * index, digit_width, column_height)
		column.add_child(_create_digit_label(value_text.substr(index, 1), digit_width, column_height))

func _create_column(x_position: float, digit_width: float, column_height: float) -> Control:
	var column := Control.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.clip_contents = true
	column.position = Vector2(x_position, 0.0)
	column.size = Vector2(digit_width, column_height)
	add_child(column)
	return column

func _create_digit_label(character: String, digit_width: float, column_height: float) -> Label:
	var digit_label := Label.new()
	digit_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	digit_label.text = character
	digit_label.size = Vector2(digit_width, column_height)
	digit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	digit_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	digit_label.add_theme_font_override("font", get_theme_font("font"))
	digit_label.add_theme_font_size_override("font_size", get_theme_font_size("font_size"))
	digit_label.add_theme_color_override("font_color", get_theme_color("font_color"))
	return digit_label

func _get_digit_width() -> float:
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")
	return maxf(12.0, ceilf(font.get_string_size("0", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 1.0))

func _finish_roll() -> void:
	_roll_tween = null
	_render_static(_target_text)

func _cancel_roll() -> void:
	if _roll_tween != null:
		_roll_tween.kill()
		_roll_tween = null

func _clear_digit_columns() -> void:
	for child in get_children():
		child.free()

func _on_resized() -> void:
	if _target_text.is_empty():
		return
	_cancel_roll()
	_render_static(_target_text)
