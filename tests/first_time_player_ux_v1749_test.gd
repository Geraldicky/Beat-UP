extends SceneTree

const UserSettingsScript = preload("res://scripts/user_settings.gd")

var failures := 0

func _initialize() -> void:
	root.size = Vector2i(1440, 900)
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)

func _run() -> void:
	var original_input_style := UserSettingsScript.get_input_style()
	var scene := load("res://scenes/startup.tscn") as PackedScene
	var startup := scene.instantiate() as Control
	root.add_child(startup)
	await process_frame
	await process_frame

	var help := startup.get_node("HelpScreen") as Control
	var input_block := startup.get_node("HelpScreen/HelpMargin/HelpVBox/HelpBody/TutorialCopyPanel/TutorialCopy/InputStyleBlock") as Control
	var numpad_button := startup.get_node("HelpScreen/HelpMargin/HelpVBox/HelpBody/TutorialCopyPanel/TutorialCopy/InputStyleBlock/InputStyleVBox/InputStyleButtons/TutorialNumpadButton") as Button
	var arrow_button := startup.get_node("HelpScreen/HelpMargin/HelpVBox/HelpBody/TutorialCopyPanel/TutorialCopy/InputStyleBlock/InputStyleVBox/InputStyleButtons/TutorialArrowButton") as Button
	var description := startup.get_node("HelpScreen/HelpMargin/HelpVBox/HelpBody/TutorialCopyPanel/TutorialCopy/TutorialDescription") as Label
	var visual := startup.get_node("HelpScreen/HelpMargin/HelpVBox/HelpBody/TutorialVisualPanel/TutorialVisual") as Control

	_check(numpad_button != null and arrow_button != null, "v17.4.9 input-mode controls are missing from HOW TO PLAY.")
	startup.call("_set_tutorial_step", 0, false)
	_check(input_block.visible, "Input-mode selector must be visible on tutorial Step 01.")

	startup.call("_set_tutorial_step", 1, false)
	_check(not input_block.visible, "Input-mode selector leaked onto non-input tutorial pages.")
	_check("Calibration" in description.text, "Timing page no longer recommends Calibration for persistent early/late feel.")

	startup.call("_set_tutorial_step", 2, false)
	_check("opposite" in description.text.to_lower(), "Reverse note opposite-input rule is missing.")
	_check("gold" in description.text.to_lower() and "space" in description.text.to_lower(), "SPACE gold-cue rule is missing.")

	_check(not visual.has_method("reset_practice"), "Retired tutorial Practice still exists.")
	_check(help.find_child("TutorialPracticeTab", true, false) == null, "Retired Practice tab still exists.")

	# Direction keys on the final demonstration page must not navigate pages.
	startup.call("_on_tutorial_input_style_selected", "4_arrow")
	startup.call("_set_tutorial_step", 2, false)
	help.visible = true
	var left_event := InputEventKey.new()
	left_event.keycode = KEY_LEFT
	left_event.physical_keycode = KEY_LEFT
	left_event.pressed = true
	startup.call("_input", left_event)
	_check(int(startup.get("tutorial_step_index")) == 2, "Left Arrow navigated away from the demonstration in 4-Direction mode.")

	UserSettingsScript.set_input_style(original_input_style)
	startup.queue_free()
	await process_frame

	if failures == 0:
		print("FIRST_TIME_PLAYER_UX_V1749_TEST: PASS")
	else:
		print("FIRST_TIME_PLAYER_UX_V1749_TEST: FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
