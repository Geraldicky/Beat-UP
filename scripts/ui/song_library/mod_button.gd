extends Button

const MinimalThemeScript = preload("res://scripts/ui/minimal_theme.gd")

@onready var icon_label: Control = $MockupContent/ContentRow/IconLabel
@onready var title_label: Label = $MockupContent/ContentRow/Copy/TitleLabel
@onready var state_label: Label = $MockupContent/ContentRow/Copy/StateLabel

func configure(icon_kind: String, title_text: String, state_text: String, accent: Color, active: bool, compact: bool) -> void:
	text = ""
	toggle_mode = true
	focus_mode = Control.FOCUS_ALL
	icon_label.set("kind", icon_kind)
	title_label.text = title_text
	set_state(state_text, accent, active, compact)

func set_state(state_text: String, accent: Color, active: bool, compact: bool) -> void:
	icon_label.set("ink", accent if active else Color(MinimalThemeScript.TEXT, 0.82))
	MinimalThemeScript.apply_mono(title_label, 11 if compact else 13, MinimalThemeScript.TEXT)
	title_label.add_theme_font_override("font", MinimalThemeScript.semibold_font())
	state_label.text = state_text
	MinimalThemeScript.apply_mono(state_label, 12, accent if active else Color(MinimalThemeScript.TEXT, 0.62))
