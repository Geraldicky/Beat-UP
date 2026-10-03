extends Button

const MinimalThemeScript = preload("res://scripts/ui/minimal_theme.gd")

@onready var play_icon: Control = $MockupPlayContent/PlayContentRow/PlayIcon
@onready var play_arrow: Control = $MockupPlayContent/PlayContentRow/PlayArrow
@onready var title_label: Label = $MockupPlayContent/PlayContentRow/PlayTitle
@onready var divider: Control = $MockupPlayContent/PlayContentRow/PlayDivider

func _ready() -> void:
	text = ""
	play_icon.set("kind", "double_diamond")
	play_arrow.set("kind", "arrow")
	play_arrow.set("ink", MinimalThemeScript.TEXT)

func set_label(label_text: String) -> void:
	title_label.text = label_text
	var standard_play := label_text == "PLAY"
	play_icon.visible = standard_play
	play_arrow.visible = standard_play
	divider.visible = standard_play
