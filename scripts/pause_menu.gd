extends Control

const ThemeConfigScript = preload("res://config/theme_config.gd")
const LayoutConfigScript = preload("res://config/ui_layout_config.gd")
const UserSettingsScript = preload("res://scripts/user_settings.gd")
const RhythmTimingScript = preload("res://scripts/rhythm_timing.gd")
const MinimalThemeScript = preload("res://scripts/ui/minimal_theme.gd")
const InteractionPolishScript = preload("res://scripts/ui/interaction_polish.gd")

signal resume_requested
signal retry_requested
signal song_list_requested
signal background_opacity_changed(value: float)
signal timing_offsets_changed(input_offset_ms: float, audio_offset_ms: float)

@export var theme_config: ThemeConfigScript
@export var layout_config: LayoutConfigScript

@onready var blur_surface: ColorRect = $BlurSurface
@onready var main_panel: PanelContainer = %MainPanel
@onready var main_vbox: VBoxContainer = %MainVBox
@onready var settings_vbox: VBoxContainer = %SettingsVBox
@onready var pause_label: Label = %Eyebrow
@onready var settings_title: Label = %SettingsTitle
@onready var master_label: Label = %MasterLabel
@onready var background_label: Label = %BackgroundLabel
@onready var input_offset_label: Label = %InputOffsetLabel
@onready var audio_offset_label: Label = %AudioOffsetLabel
@onready var settings_panel: PanelContainer = %SettingsPanel
@onready var buttons: VBoxContainer = %PauseButtons
@onready var resume_button: Button = %ResumeButton
@onready var retry_button: Button = %RetryButton
@onready var settings_button: Button = %SettingsButton
@onready var song_list_button: Button = %SongListButton
@onready var master_slider: HSlider = %MasterSlider
@onready var menu_sfx_toggle: CheckButton = %MenuSFXToggle
@onready var menu_sfx_slider: HSlider = %MenuSFXSlider
@onready var menu_sfx_value: Label = %MenuSFXValue
@onready var background_slider: HSlider = %BackgroundSlider
@onready var input_offset_slider: HSlider = %InputOffsetSlider
@onready var audio_offset_slider: HSlider = %AudioOffsetSlider
@onready var input_offset_value: Label = %InputOffsetValue
@onready var audio_offset_value: Label = %AudioOffsetValue
@onready var back_button: Button = %BackButton

var action_hint: Label
var master_value: Label
var background_value: Label

func _ready() -> void:
	if theme_config == null:
		theme_config = ThemeConfigScript.new()
	if layout_config == null:
		layout_config = LayoutConfigScript.new()
	MinimalThemeScript.apply_root(self)
	resume_button.pressed.connect(func(): resume_requested.emit())
	retry_button.pressed.connect(func(): retry_requested.emit())
	settings_button.pressed.connect(show_settings)
	song_list_button.pressed.connect(func(): song_list_requested.emit())
	back_button.pressed.connect(show_menu)
	master_slider.value_changed.connect(_on_master_volume_changed)
	menu_sfx_slider.value_changed.connect(_on_menu_sfx_volume_changed)
	menu_sfx_toggle.toggled.connect(_on_menu_sfx_toggled)
	background_slider.value_changed.connect(_on_background_opacity_changed)
	input_offset_slider.value_changed.connect(_on_input_offset_changed)
	audio_offset_slider.value_changed.connect(_on_audio_offset_changed)
	_build_action_hint()
	master_value = _add_slider_value(master_slider, "MasterValue")
	background_value = _add_slider_value(background_slider, "BackgroundValue")
	_apply_layout_config()
	_apply_theme_config()
	_wire_focus_neighbors()
	_apply_scene_effects()
	_refresh_settings()
	InteractionPolishScript.install_buttons([back_button])
	show_menu()

func _apply_scene_effects() -> void:
	if blur_surface != null:
		blur_surface.color = Color(MinimalThemeScript.BG, 0.68)

func _apply_layout_config() -> void:
	if layout_config == null:
		return
	main_panel.custom_minimum_size = Vector2(440.0, 0.0)
	settings_panel.custom_minimum_size = Vector2(560.0, 0.0)
	main_vbox.add_theme_constant_override("separation", 20)
	settings_vbox.add_theme_constant_override("separation", 8)
	buttons.add_theme_constant_override("separation", 8)
	settings_title.custom_minimum_size.y = layout_config.settings_title_height
	master_label.custom_minimum_size.y = layout_config.settings_label_height
	background_label.custom_minimum_size.y = layout_config.settings_label_height
	input_offset_label.custom_minimum_size.y = 22.0
	audio_offset_label.custom_minimum_size.y = 22.0
	master_slider.custom_minimum_size.y = layout_config.slider_height
	menu_sfx_slider.custom_minimum_size.y = layout_config.slider_height
	background_slider.custom_minimum_size.y = layout_config.slider_height
	input_offset_slider.custom_minimum_size.y = layout_config.slider_height
	audio_offset_slider.custom_minimum_size.y = layout_config.slider_height
	back_button.custom_minimum_size.y = layout_config.back_button_height
	var actions: Array[Button] = [resume_button, retry_button, settings_button, song_list_button]
	for index in range(actions.size()):
		buttons.move_child(actions[index], index)
		actions[index].custom_minimum_size = Vector2(0.0, 58.0)
	resume_button.custom_minimum_size.y = 68.0

func _apply_theme_config() -> void:
	if theme_config == null:
		return
	pause_label.add_theme_color_override("font_color", MinimalThemeScript.TEXT)
	pause_label.add_theme_font_size_override("font_size", 36)
	pause_label.add_theme_font_override("font", MinimalThemeScript.semibold_font())
	settings_title.add_theme_font_override("font", MinimalThemeScript.semibold_font())
	for label in [input_offset_label, audio_offset_label]:
		label.add_theme_color_override("font_color", theme_config.text_primary)
		label.add_theme_font_size_override("font_size", theme_config.body_size)
	input_offset_value.add_theme_color_override("font_color", theme_config.accent_secondary)
	audio_offset_value.add_theme_color_override("font_color", theme_config.space_accent)
	for button in [resume_button, retry_button, settings_button, song_list_button, back_button]:
		button.add_theme_color_override("font_color", theme_config.text_primary)
		button.add_theme_color_override("font_hover_color", theme_config.text_primary)
		button.add_theme_font_size_override("font_size", theme_config.button_size)
	main_panel.add_theme_stylebox_override("panel", MinimalThemeScript.panel_style(Color(0.045, 0.055, 0.075, 0.97), 4, Color(MinimalThemeScript.BORDER, 0.55), 1, 28.0))
	settings_panel.add_theme_stylebox_override("panel", MinimalThemeScript.panel_style(Color("0e1219"), 6, MinimalThemeScript.BORDER, 1, 24.0))
	background_label.text = "BACKGROUND ATMOSPHERE"
	for action in [resume_button, retry_button, settings_button, song_list_button]:
		_style_action_button(action, action == resume_button)
	MinimalThemeScript.apply_mono(input_offset_value, 14, MinimalThemeScript.CYAN)
	MinimalThemeScript.apply_mono(audio_offset_value, 14, MinimalThemeScript.GOLD)
	MinimalThemeScript.apply_mono(menu_sfx_value, 14, MinimalThemeScript.CYAN)

func _build_action_hint() -> void:
	action_hint = Label.new()
	action_hint.name = "PauseActionHint"
	action_hint.custom_minimum_size.y = 24
	action_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	MinimalThemeScript.apply_mono(action_hint, 11, MinimalThemeScript.MUTED)
	action_hint.text = "ESC TO RESUME"
	main_vbox.add_child(action_hint)
	song_list_button.set_meta("action_label", "Song Library")
	retry_button.set_meta("action_label", "Retry")
	settings_button.set_meta("action_label", "Quick Settings")
	resume_button.set_meta("action_label", "Resume")

func _add_slider_value(slider: HSlider, label_name: String) -> Label:
	var parent := slider.get_parent()
	var index := slider.get_index()
	var row := HBoxContainer.new()
	row.name = label_name + "Row"
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	parent.move_child(row, index)
	slider.reparent(row)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	label.name = label_name
	label.custom_minimum_size.x = 82
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	MinimalThemeScript.apply_mono(label, 14, MinimalThemeScript.CYAN)
	row.add_child(label)
	return label

func _refresh_settings() -> void:
	var master_percent: float = UserSettingsScript.get_master_volume()
	var sfx_value: float = UserSettingsScript.get_menu_sfx_volume()
	var sfx_enabled: bool = UserSettingsScript.get_menu_sfx_enabled()
	var bg_value: float = UserSettingsScript.get_background_opacity()
	var input_value: float = UserSettingsScript.get_input_offset_ms()
	var audio_value: float = UserSettingsScript.get_audio_offset_ms()
	master_slider.set_value_no_signal(master_percent)
	master_value.text = "%d%%" % roundi(master_percent)
	menu_sfx_slider.set_value_no_signal(sfx_value)
	menu_sfx_toggle.set_pressed_no_signal(sfx_enabled)
	menu_sfx_slider.editable = sfx_enabled
	menu_sfx_value.text = "%d%%" % roundi(sfx_value)
	menu_sfx_value.modulate.a = 1.0 if sfx_enabled else 0.38
	background_slider.set_value_no_signal(bg_value)
	background_value.text = "%d%%" % roundi(bg_value)
	input_offset_slider.set_value_no_signal(input_value)
	audio_offset_slider.set_value_no_signal(audio_value)
	_update_timing_labels()

func show_menu() -> void:
	_refresh_settings()
	main_panel.visible = true
	settings_panel.visible = false
	resume_button.grab_focus()

func show_settings() -> void:
	main_panel.visible = false
	settings_panel.visible = true
	master_slider.grab_focus()

func _wire_focus_neighbors() -> void:
	var action_buttons: Array[Button] = [resume_button, retry_button, settings_button, song_list_button]
	for index in range(action_buttons.size()):
		var button: Button = action_buttons[index]
		var previous: Button = action_buttons[posmod(index - 1, action_buttons.size())]
		var next: Button = action_buttons[(index + 1) % action_buttons.size()]
		button.focus_neighbor_left = button.get_path_to(previous)
		button.focus_neighbor_right = button.get_path_to(next)
		button.focus_neighbor_top = button.get_path_to(previous)
		button.focus_neighbor_bottom = button.get_path_to(next)

func _style_action_button(button: Button, primary: bool) -> void:
	button.text = str(button.get_meta("action_label", ""))
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_override("font", MinimalThemeScript.semibold_font() if primary else MinimalThemeScript.medium_font())
	button.add_theme_font_size_override("font_size", 20 if primary else 16)
	button.add_theme_color_override("font_color", MinimalThemeScript.TEXT if primary else Color(MinimalThemeScript.TEXT, 0.82))
	button.add_theme_constant_override("h_separation", 16)
	button.add_theme_constant_override("icon_max_width", 24)
	button.add_theme_color_override("icon_normal_color", MinimalThemeScript.CYAN if primary else MinimalThemeScript.MUTED)
	button.add_theme_color_override("icon_hover_color", MinimalThemeScript.TEXT)
	var edge := MinimalThemeScript.CYAN if primary else MinimalThemeScript.BORDER
	button.add_theme_stylebox_override("normal", MinimalThemeScript.panel_style(Color(MinimalThemeScript.CYAN, 0.07) if primary else Color(MinimalThemeScript.SURFACE, 0.32), 2, Color(edge, 0.8 if primary else 0.4), 1, 18.0))
	button.add_theme_stylebox_override("hover", MinimalThemeScript.panel_style(Color(MinimalThemeScript.SURFACE_RAISED, 0.9), 2, MinimalThemeScript.CYAN, 1, 18.0))
	button.add_theme_stylebox_override("pressed", MinimalThemeScript.panel_style(Color(MinimalThemeScript.CYAN, 0.14), 2, MinimalThemeScript.CYAN, 1, 18.0))
	button.add_theme_stylebox_override("focus", MinimalThemeScript.panel_style(Color.TRANSPARENT, 2, MinimalThemeScript.TEXT, 1, 18.0))
	button.add_theme_stylebox_override("disabled", MinimalThemeScript.panel_style(Color(MinimalThemeScript.SURFACE, 0.2), 2, Color(MinimalThemeScript.BORDER, 0.2), 1, 18.0))

func _on_master_volume_changed(value: float) -> void:
	master_value.text = "%d%%" % roundi(value)
	UserSettingsScript.set_master_volume(value)

func _on_menu_sfx_volume_changed(value: float) -> void:
	UserSettingsScript.set_menu_sfx_volume(value)
	menu_sfx_value.text = "%d%%" % roundi(value)

func _on_menu_sfx_toggled(enabled: bool) -> void:
	UserSettingsScript.set_menu_sfx_enabled(enabled)
	menu_sfx_slider.editable = enabled
	menu_sfx_value.modulate.a = 1.0 if enabled else 0.38

func _on_background_opacity_changed(value: float) -> void:
	background_value.text = "%d%%" % roundi(value)
	UserSettingsScript.set_background_opacity(value)
	background_opacity_changed.emit(value)

func _on_input_offset_changed(value: float) -> void:
	UserSettingsScript.set_input_offset_ms(value)
	_update_timing_labels()
	timing_offsets_changed.emit(input_offset_slider.value, audio_offset_slider.value)

func _on_audio_offset_changed(value: float) -> void:
	UserSettingsScript.set_audio_offset_ms(value)
	_update_timing_labels()
	timing_offsets_changed.emit(input_offset_slider.value, audio_offset_slider.value)

func _update_timing_labels() -> void:
	input_offset_value.text = RhythmTimingScript.format_offset_ms(input_offset_slider.value)
	audio_offset_value.text = RhythmTimingScript.format_offset_ms(audio_offset_slider.value)

func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not (event is InputEventKey):
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo or key.keycode != KEY_ESCAPE:
		return
	if settings_panel.visible:
		show_menu()
	else:
		resume_requested.emit()
	get_viewport().set_input_as_handled()
