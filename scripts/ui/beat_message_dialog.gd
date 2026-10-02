extends Control
class_name BeatMessageDialog

signal confirmed
signal action_requested

const MinimalThemeScript = preload("res://scripts/ui/minimal_theme.gd")

var _heading: Label
var _body: Label
var _action_button: Button
var _confirm_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 990
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_interface()

func show_message(heading: String, message: String, action_label: String = "") -> void:
	_heading.text = heading.to_upper()
	_body.text = message
	_action_button.visible = not action_label.is_empty()
	_action_button.text = action_label
	visible = true
	modulate.a = 0.0
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, 0.12)
	if _action_button.visible:
		_action_button.grab_focus()
	else:
		_confirm_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_finish()
		get_viewport().set_input_as_handled()

func _build_interface() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.006, 0.009, 0.015, 0.88)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 300)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override(
		"panel",
		MinimalThemeScript.panel_style(
			Color("141820"), 16, Color(MinimalThemeScript.PINK, 0.66), 1, 28.0
		)
	)
	center.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 18)
	panel.add_child(stack)
	_heading = Label.new()
	MinimalThemeScript.apply_heading(_heading, 27, MinimalThemeScript.TEXT)
	stack.add_child(_heading)
	var rule := HSeparator.new()
	stack.add_child(rule)
	_body = Label.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	MinimalThemeScript.apply_body(_body, 15, Color(MinimalThemeScript.TEXT, 0.90))
	stack.add_child(_body)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 10)
	stack.add_child(actions)
	_action_button = Button.new()
	_action_button.custom_minimum_size = Vector2(170, 44)
	MinimalThemeScript.style_secondary(_action_button, MinimalThemeScript.CYAN)
	_action_button.pressed.connect(func():
		action_requested.emit()
		queue_free()
	)
	actions.add_child(_action_button)
	_confirm_button = Button.new()
	_confirm_button.text = "DONE"
	_confirm_button.custom_minimum_size = Vector2(140, 44)
	MinimalThemeScript.style_primary(_confirm_button)
	_confirm_button.pressed.connect(_finish)
	actions.add_child(_confirm_button)

func _finish() -> void:
	confirmed.emit()
	queue_free()
