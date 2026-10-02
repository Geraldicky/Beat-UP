extends Label
class_name ComboDigits

@export_group("Popup Animation")
@export var pop_in_duration := 0.07
@export var pop_start_scale := Vector2(0.92, 0.92)

var _last_value := -1
var _popup_tween: Tween

func _ready() -> void:
	add_theme_font_override("font", load("res://assets/fonts/IBMPlexMono-Regular.ttf"))
	add_theme_font_size_override("font_size", 42)
	add_theme_color_override("font_color", Color("f3f1ed"))
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	set_value(0)

func set_value(value: int) -> void:
	value = maxi(0, value)
	if value == _last_value:
		return
	_last_value = value
	text = str(value)
	if value <= 0:
		reset_popup()
		return
	_show_popup()

func _show_popup() -> void:
	if _popup_tween != null:
		_popup_tween.kill()
	visible = true
	modulate = Color.WHITE
	pivot_offset = size * 0.5
	scale = pop_start_scale
	_popup_tween = create_tween()
	_popup_tween.tween_property(self, "scale", Vector2.ONE, pop_in_duration).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

func _hide_popup() -> void:
	if _popup_tween != null:
		_popup_tween.kill()
		_popup_tween = null
	visible = false
	scale = Vector2.ONE
	modulate = Color.WHITE

func reset_popup() -> void:
	_hide_popup()
