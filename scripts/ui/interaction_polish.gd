extends RefCounted
class_name InteractionPolish

const VisualTheme = preload("res://scripts/ui/minimal_theme.gd")

const HOVER_SCALE := 1.010
const PRESSED_SCALE := 0.990
const TWEEN_META := "beat_up_micro_tween"

# Small motion only. Screen-specific controllers own larger route/selection motion.
# Every new interaction cancels the previous micro-tween so rapid hover/focus/click
# changes converge to the newest state instead of allocating a competing tween chain.
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
		button.mouse_entered.connect(func() -> void: _animate(button, _rest_scale(button)))
		button.focus_entered.connect(func() -> void: _animate(button, _rest_scale(button)))
		button.mouse_exited.connect(func() -> void: _animate(button, _rest_scale(button)))
		button.focus_exited.connect(func() -> void: _animate(button, _rest_scale(button)))
		button.button_down.connect(func() -> void: _animate(button, PRESSED_SCALE))
		button.button_up.connect(func() -> void: _animate(button, _rest_scale(button)))
		button.pivot_offset = button.size * 0.5

static func _rest_scale(button: Button) -> float:
	if button == null or not is_instance_valid(button) or button.disabled:
		return 1.0
	return HOVER_SCALE if button.has_focus() or button.is_hovered() else 1.0

static func _animate(button: Button, target: float) -> void:
	if button == null or not is_instance_valid(button):
		return
	if button.disabled:
		target = 1.0
	var previous: Variant = button.get_meta(TWEEN_META) if button.has_meta(TWEEN_META) else null
	if previous is Tween:
		var previous_tween := previous as Tween
		if previous_tween.is_valid():
			previous_tween.kill()
	var tween := button.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE * target, VisualTheme.MOTION_FAST)
	button.set_meta(TWEEN_META, tween)
