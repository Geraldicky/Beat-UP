extends Label
class_name RollingValueLabel

@export_range(0, 3, 1) var decimal_places := 0
@export_range(1, 8, 1) var minimum_integer_digits := 1
@export var prefix := ""
@export var suffix := ""
@export_range(0.0, 0.04, 0.001) var digit_stagger := 0.010

var _current_units := 0
var _target_units := 0
var _integer_width := 1
var _roll_tween: Tween

func _ready() -> void:
	text = ""
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)
	reset_numeric_value(0.0)

func reset_numeric_value(value: float = 0.0) -> void:
	_current_units = _to_units(value)
	_target_units = _current_units
	_integer_width = maxi(minimum_integer_digits, _integer_digit_count(_current_units))
	_cancel_roll()
	_render_static(_format_units(_current_units, _integer_width))

func animate_to(value: float, duration: float = 0.65, start_delay: float = 0.0) -> void:
	_target_units = _to_units(value)
	_integer_width = maxi(
		minimum_integer_digits,
		maxi(_integer_digit_count(_current_units), _integer_digit_count(_target_units))
	)
	var previous_text := _format_units(_current_units, _integer_width)
	var next_text := _format_units(_target_units, _integer_width)
	_animate_roll(previous_text, next_text, maxf(0.05, duration), maxf(0.0, start_delay))

func set_numeric_value(value: float, animated := true, duration: float = 0.65) -> void:
	if animated:
		animate_to(value, duration)
	else:
		reset_numeric_value(value)

func refresh_style() -> void:
	_cancel_roll()
	_render_static(_format_units(_current_units, _integer_width))

func is_rolling() -> bool:
	return _roll_tween != null

func get_numeric_value() -> float:
	return float(_target_units) / float(_scale_factor())

func _animate_roll(previous_text: String, next_text: String, duration: float, start_delay: float) -> void:
	_cancel_roll()
	_clear_columns()
	var column_height := maxf(1.0, size.y)
	var widths := _measure_characters(next_text)
	var total_width := 0.0
	for width in widths:
		total_width += width
	var x_position := _aligned_start_x(total_width)
	var animated_reels: Array[Dictionary] = []

	for index in range(next_text.length()):
		var next_character := next_text.substr(index, 1)
		var previous_character := previous_text.substr(index, 1)
		var column_width: float = widths[index]
		var column := _create_column(x_position, column_width, column_height)
		x_position += column_width

		if next_character.is_valid_int() and previous_character.is_valid_int():
			var from_digit := int(previous_character)
			var to_digit := int(next_character)
			var forward_steps := (to_digit - from_digit + 10) % 10
			var reel := Control.new()
			reel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			reel.size = Vector2(column_width, column_height * (forward_steps + 1))
			column.add_child(reel)
			for step in range(forward_steps + 1):
				var digit_label := _create_character_label(str((from_digit + step) % 10), column_width, column_height)
				digit_label.position.y = column_height * step
				reel.add_child(digit_label)
			if forward_steps > 0:
				animated_reels.append({
					"reel": reel,
					"steps": forward_steps,
					"delay": start_delay + float(next_text.length() - index - 1) * digit_stagger,
				})
		else:
			column.add_child(_create_character_label(next_character, column_width, column_height))

	if animated_reels.is_empty():
		_current_units = _target_units
		_render_static(next_text)
		return

	_roll_tween = create_tween()
	_roll_tween.set_parallel(true)
	for reel_data in animated_reels:
		var reel := reel_data["reel"] as Control
		var steps := int(reel_data["steps"])
		var delay := float(reel_data["delay"])
		_roll_tween.tween_property(
			reel,
			"position:y",
			-column_height * steps,
			duration
		).set_delay(delay).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_roll_tween.chain().tween_callback(Callable(self, "_finish_roll"))

func _render_static(value_text: String) -> void:
	_clear_columns()
	if value_text.is_empty():
		return
	var column_height := maxf(1.0, size.y)
	var widths := _measure_characters(value_text)
	var total_width := 0.0
	for width in widths:
		total_width += width
	var x_position := _aligned_start_x(total_width)
	for index in range(value_text.length()):
		var column_width: float = widths[index]
		var column := _create_column(x_position, column_width, column_height)
		column.add_child(_create_character_label(value_text.substr(index, 1), column_width, column_height))
		x_position += column_width

func _measure_characters(value_text: String) -> Array[float]:
	var result: Array[float] = []
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")
	for index in range(value_text.length()):
		var character := value_text.substr(index, 1)
		result.append(maxf(4.0, ceilf(font.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 1.0)))
	return result

func _aligned_start_x(total_width: float) -> float:
	match horizontal_alignment:
		HORIZONTAL_ALIGNMENT_CENTER:
			return maxf(0.0, (size.x - total_width) * 0.5)
		HORIZONTAL_ALIGNMENT_RIGHT:
			return maxf(0.0, size.x - total_width)
		_:
			return 0.0

func _create_column(x_position: float, column_width: float, column_height: float) -> Control:
	var column := Control.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.clip_contents = true
	column.position = Vector2(x_position, 0.0)
	column.size = Vector2(column_width, column_height)
	add_child(column)
	return column

func _create_character_label(character: String, column_width: float, column_height: float) -> Label:
	var character_label := Label.new()
	character_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character_label.text = character
	character_label.size = Vector2(column_width, column_height)
	character_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	character_label.add_theme_font_override("font", get_theme_font("font"))
	character_label.add_theme_font_size_override("font_size", get_theme_font_size("font_size"))
	character_label.add_theme_color_override("font_color", get_theme_color("font_color"))
	return character_label

func _format_units(units: int, integer_width: int) -> String:
	var unit_scale := _scale_factor()
	var integer_part := floori(float(units) / float(unit_scale))
	var value_text := str(integer_part).pad_zeros(integer_width)
	if decimal_places > 0:
		var fractional_part := posmod(units, unit_scale)
		value_text += "." + str(fractional_part).pad_zeros(decimal_places)
	return prefix + value_text + suffix

func _to_units(value: float) -> int:
	return maxi(0, int(round(value * float(_scale_factor()))))

func _scale_factor() -> int:
	var result := 1
	for _index in range(decimal_places):
		result *= 10
	return result

func _integer_digit_count(units: int) -> int:
	return str(maxi(0, floori(float(units) / float(_scale_factor())))).length()

func _finish_roll() -> void:
	_roll_tween = null
	_current_units = _target_units
	_render_static(_format_units(_current_units, _integer_width))

func _cancel_roll() -> void:
	if _roll_tween != null:
		_roll_tween.kill()
		_roll_tween = null

func _clear_columns() -> void:
	for child in get_children():
		child.free()

func _on_resized() -> void:
	_cancel_roll()
	_render_static(_format_units(_current_units, _integer_width))
