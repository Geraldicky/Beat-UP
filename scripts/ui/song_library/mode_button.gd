extends Button

func configure(label_text: String) -> void:
	text = label_text
	toggle_mode = true
	focus_mode = Control.FOCUS_ALL
