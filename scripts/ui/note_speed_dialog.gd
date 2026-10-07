extends AcceptDialog
## Library shortcut to the canonical preference; never launches a gameplay run.
const Settings = preload("res://scripts/user_settings.gd")
var slider: HSlider
var preview: Control
var value_label: Label
var pattern_button: Button
var _scrim_layer: CanvasLayer
var _scrim: ColorRect
var _return_focus: Control

func _ready() -> void:
	title = "NOTE SPEED · LIVE PREVIEW"
	ok_button_text = "DONE"
	min_size = Vector2i(520, 330)
	transient = true
	exclusive = true
	theme = preload("res://scripts/ui/minimal_theme.gd").theme().duplicate()
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("0e1219")
	panel.set_corner_radius_all(6)
	panel.border_color = Color("344052")
	panel.set_border_width_all(1)
	panel.content_margin_left = 16
	panel.content_margin_right = 16
	panel.content_margin_top = 36
	panel.content_margin_bottom = 16
	theme.set_stylebox("panel", "AcceptDialog", panel)
	var window_border := panel.duplicate() as StyleBoxFlat
	window_border.expand_margin_top = 32
	theme.set_stylebox("embedded_border", "Window", window_border)
	var content := VBoxContainer.new()
	content.custom_minimum_size.x = 500
	content.add_theme_constant_override("separation", 12)
	add_child(content)
	preview = preload("res://scripts/ui/note_speed_preview.gd").new()
	content.add_child(preview)
	var row := HBoxContainer.new()
	content.add_child(row)
	slider = HSlider.new()
	slider.min_value = Settings.MIN_NOTE_TRAVEL_TIME
	slider.max_value = Settings.MAX_NOTE_TRAVEL_TIME
	slider.step = 0.1
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	value_label = Label.new()
	value_label.custom_minimum_size.x = 165
	row.add_child(value_label)
	slider.value_changed.connect(_on_speed_changed)
	var presets := HBoxContainer.new()
	content.add_child(presets)
	for item: Dictionary in [{"text": "FAST", "time": 1.2}, {"text": "STANDARD", "time": 1.5}, {"text": "RELAXED", "time": 1.8}]:
		var button := Button.new()
		button.text = "%s · %.1fs" % [item.text, item.time]
		button.pressed.connect(func(): slider.value = float(item.time))
		presets.add_child(button)
	pattern_button = Button.new()
	pattern_button.text = "DENSE EXAMPLE"
	pattern_button.toggle_mode = true
	pattern_button.toggled.connect(func(enabled: bool): preview.set_dense_pattern(enabled))
	presets.add_child(pattern_button)
	var hint := Label.new()
	hint.text = "More seconds = slower notes and more time to read.\nExample rhythm, not the actual chart · Saved automatically · Applies next run."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.x = 500
	content.add_child(hint)
	close_requested.connect(hide)
	visibility_changed.connect(_sync_modal_visibility)
	_scrim_layer = CanvasLayer.new()
	_scrim_layer.layer = 95
	_scrim = ColorRect.new()
	_scrim.name = "NoteSpeedScrim"
	_scrim.color = Color(0.02, 0.025, 0.035, 0.72)
	_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_scrim.hide()
	_scrim_layer.add_child(_scrim)
	get_parent().call_deferred("add_child", _scrim_layer)
	preload("res://scripts/ui/minimal_theme.gd").style_primary(get_ok_button())

func _exit_tree() -> void:
	if is_instance_valid(_scrim_layer):
		_scrim_layer.queue_free()

func _sync_modal_visibility() -> void:
	if is_instance_valid(_scrim):
		_scrim.visible = visible
	if not visible and is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree():
		_return_focus.call_deferred("grab_focus")

func open(input_style: String = "8_direction", bpm: float = 140.0) -> void:
	_return_focus = get_parent().get_viewport().gui_get_focus_owner()
	preview.set_context(input_style, bpm)
	var value := Settings.get_note_travel_time()
	slider.set_value_no_signal(value)
	_refresh(value)
	popup_centered_clamped(Vector2i(840, 360), 0.9)
	slider.grab_focus()

func _on_speed_changed(value: float) -> void:
	Settings.set_note_travel_time(value)
	_refresh(value)

func _refresh(value: float) -> void:
	preview.set_read_time(value)
	value_label.text = "%.2f s · TRAVEL TIME" % value
