extends RefCounted
class_name InteractionPolish

const VisualTheme = preload("res://scripts/ui/minimal_theme.gd")

# Small motion only. Screen-specific controllers can still own larger transitions.
static func install_buttons(buttons: Array) -> void:
	for value: Variant in buttons:
		if not (value is Button):
			continue
		var button := value as Button
		if button == null or button.has_meta("beat_up_micro_motion"):
			continue
		button.set_meta("beat_up_micro_motion", true)
		button.resized.connect(func() -> void:
			if is_instance_valid(button):
				button.pivot_offset = button.size * 0.5
		)
		button.mouse_entered.connect(func() -> void: _animate(button, 1.012))
		button.focus_entered.connect(func() -> void: _animate(button, 1.012))
		button.mouse_exited.connect(func() -> void: _restore(button))
		button.focus_exited.connect(func() -> void: _restore(button))
		button.button_down.connect(func() -> void: _animate(button, 0.988))
		button.button_up.connect(func() -> void:
			if is_instance_valid(button):
				_animate(button, 1.012 if button.has_focus() or button.is_hovered() else 1.0)
		)
		button.pivot_offset = button.size * 0.5

static func _restore(button: Button) -> void:
	if button == null or not is_instance_valid(button):
		return
	_animate(button, 1.012 if button.has_focus() or button.is_hovered() else 1.0)

static func _animate(button: Button, target: float) -> void:
	if button == null or not is_instance_valid(button):
		return
	var tween := button.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(button, "scale", Vector2.ONE * target, VisualTheme.MOTION_FAST).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
