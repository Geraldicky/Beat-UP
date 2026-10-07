extends Button

const MinimalThemeScript = preload("res://scripts/ui/minimal_theme.gd")

@onready var level_label: Label = $Content/DifficultyLevel
@onready var name_label: Label = $Content/DifficultyName

func configure(diff: String, level: int, selected: bool, available: bool, accent: Color, compact: bool) -> void:
	name = "%sDifficultyButton" % diff.capitalize()
	text = ""
	focus_mode = Control.FOCUS_ALL
	disabled = not available
	custom_minimum_size = Vector2(0, 58 if compact else 76)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	level_label.text = str(level) if available else "—"
	MinimalThemeScript.apply_numeric(level_label, 26 if selected else 23, accent if selected else Color(MinimalThemeScript.TEXT, 0.84 if available else 0.22))
	name_label.text = diff.to_upper()
	MinimalThemeScript.apply_mono(name_label, 11 if compact else 12, accent if selected else Color(MinimalThemeScript.TEXT, 0.66 if available else 0.28))
