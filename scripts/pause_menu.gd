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
@onready var buttons: HBoxContainer = %PauseButtons
@onready var resume_button: Button = %ResumeButton
@onready var retry_button: Button = %RetryButton
@onready var settings_button: Button = %SettingsButton
@onready var song_list_button: Button = %SongListButton
@onready var resume_icon: BeatUpActionIcon = $Center/MainPanel/MainVBox/PauseButtons/ResumeButton/Icon
@onready var retry_icon: BeatUpActionIcon = $Center/MainPanel/MainVBox/PauseButtons/RetryButton/Icon
@onready var settings_icon: BeatUpActionIcon = $Center/MainPanel/MainVBox/PauseButtons/SettingsButton/Icon
@onready var song_list_icon: BeatUpActionIcon = $Center/MainPanel/MainVBox/PauseButtons/SongListButton/Icon
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
	_apply_layout_config()
	_apply_theme_config()
	_wire_action_motion()
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
	main_panel.custom_minimum_size.x = maxf(690.0, float(layout_config.menu_panel_min_width))
	settings_panel.custom_minimum_size.x = maxf(float(layout_config.settings_panel_min_width), 560.0)
	main_vbox.add_theme_constant_override("separation", layout_config.section_gap)
	settings_vbox.add_theme_constant_override("separation", layout_config.compact_gap)
	buttons.add_theme_constant_override("separation", layout_config.section_gap)
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
	for button in [song_list_button, retry_button, settings_button, resume_button]:
		button.custom_minimum_size = Vector2(maxf(136.0, layout_config.pause_icon_button_size * 1.34), maxf(132.0, layout_config.pause_icon_button_size * 1.30))

func _apply_theme_config() -> void:
	if theme_config == null:
		return
	pause_label.add_theme_color_override("font_color", MinimalThemeScript.TEXT)
	pause_label.add_theme_font_size_override("font_size", 30)
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
	main_panel.add_theme_stylebox_override("panel", MinimalThemeScript.surface_s1(0.82))
	settings_panel.add_theme_stylebox_override("panel", MinimalThemeScript.surface_s3())
	for icon_button in [song_list_button, retry_button, settings_button, resume_button]:
		_style_icon_only_button(icon_button)
	MinimalThemeScript.apply_mono(input_offset_value, 14, MinimalThemeScript.CYAN)
	MinimalThemeScript.apply_mono(audio_offset_value, 14, MinimalThemeScript.GOLD)
	MinimalThemeScript.apply_mono(menu_sfx_value, 14, MinimalThemeScript.CYAN)

func _build_action_hint() -> void:
	action_hint = Label.new()
	action_hint.name = "PauseActionHint"
	action_hint.custom_minimum_size.y = 24
	action_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	MinimalThemeScript.apply_mono(action_hint, 11, Color(MinimalThemeScript.TEXT, 0.72))
	main_vbox.add_child(action_hint)
	main_vbox.move_child(action_hint, buttons.get_index() + 1)
	song_list_button.tooltip_text = "Song List"
	retry_button.tooltip_text = "Retry"
	settings_button.tooltip_text = "Settings"
	resume_button.tooltip_text = "Resume"

func _refresh_settings() -> void:
	var master_value: float = UserSettingsScript.get_master_volume()
	var sfx_value: float = UserSettingsScript.get_menu_sfx_volume()
	var sfx_enabled: bool = UserSettingsScript.get_menu_sfx_enabled()
	var bg_value: float = UserSettingsScript.get_background_opacity()
	var input_value: float = UserSettingsScript.get_input_offset_ms()
	var audio_value: float = UserSettingsScript.get_audio_offset_ms()
	master_slider.set_value_no_signal(master_value)
	menu_sfx_slider.set_value_no_signal(sfx_value)
	menu_sfx_toggle.set_pressed_no_signal(sfx_enabled)
	menu_sfx_slider.editable = sfx_enabled
	menu_sfx_value.text = "%d%%" % roundi(sfx_value)
	menu_sfx_value.modulate.a = 1.0 if sfx_enabled else 0.38
	background_slider.set_value_no_signal(bg_value)
	input_offset_slider.set_value_no_signal(input_value)
	audio_offset_slider.set_value_no_signal(audio_value)
	_update_timing_labels()

func show_menu() -> void:
	_refresh_settings()
	main_panel.visible = true
	settings_panel.visible = false
	for icon in [song_list_icon, retry_icon, settings_icon, resume_icon]:
		icon.set_active(false)
	resume_button.grab_focus()
	_set_action_active(resume_button, resume_icon, true)
	if action_hint != null:
		action_hint.text = "RESUME"

func show_settings() -> void:
	main_panel.visible = false
	settings_panel.visible = true
	master_slider.grab_focus()

func _wire_focus_neighbors() -> void:
	var action_buttons: Array[Button] = [song_list_button, retry_button, settings_button, resume_button]
	for index in range(action_buttons.size()):
		var button: Button = action_buttons[index]
		var previous: Button = action_buttons[posmod(index - 1, action_buttons.size())]
		var next: Button = action_buttons[(index + 1) % action_buttons.size()]
		button.focus_neighbor_left = button.get_path_to(previous)
		button.focus_neighbor_right = button.get_path_to(next)

func _wire_action_motion() -> void:
	var action_pairs: Array = [
		[song_list_button, song_list_icon],
		[retry_button, retry_icon],
		[settings_button, settings_icon],
		[resume_button, resume_icon],
	]
	for pair in action_pairs:
		var button := pair[0] as Button
		var icon := pair[1] as BeatUpActionIcon
		button.mouse_entered.connect(_set_action_active.bind(button, icon, true))
		button.focus_entered.connect(_set_action_active.bind(button, icon, true))
		button.mouse_exited.connect(_set_action_active.bind(button, icon, false))
		button.focus_exited.connect(_set_action_active.bind(button, icon, false))

func _set_action_active(button: Button, icon: BeatUpActionIcon, active: bool) -> void:
	if button == null or icon == null:
		return
	icon.set_active(active)
	if active and action_hint != null:
		action_hint.text = button.tooltip_text.to_upper()
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var target_scale := Vector2.ONE * (1.035 if active else 1.0)
	tween.tween_property(icon, "scale", target_scale, MinimalThemeScript.MOTION_FAST).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

func _style_icon_only_button(button: Button) -> void:
	button.text = ""
	var empty_style := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, empty_style)

func _on_master_volume_changed(value: float) -> void:
	UserSettingsScript.set_master_volume(value)

func _on_menu_sfx_volume_changed(value: float) -> void:
	UserSettingsScript.set_menu_sfx_volume(value)
	menu_sfx_value.text = "%d%%" % roundi(value)

func _on_menu_sfx_toggled(enabled: bool) -> void:
	UserSettingsScript.set_menu_sfx_enabled(enabled)
	menu_sfx_slider.editable = enabled
	menu_sfx_value.modulate.a = 1.0 if enabled else 0.38

func _on_background_opacity_changed(value: float) -> void:
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
	if not visible or not (event is InputEventKey):
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo or key.keycode != KEY_ESCAPE:
		return
	if settings_panel.visible:
		show_menu()
	else:
		resume_requested.emit()
	get_viewport().set_input_as_handled()
