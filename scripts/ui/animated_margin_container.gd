extends MarginContainer
class_name AnimatedMarginContainer

var animated_margin_left := 0.0:
	set(value):
		animated_margin_left = value
		add_theme_constant_override("margin_left", roundi(value))

func set_margin_immediate(value: float) -> void:
	animated_margin_left = value
