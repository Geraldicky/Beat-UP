extends SceneTree

const SONG_ID := "diana_boncheva_feat_banya_beethoven_virus_full_version"

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
	var scene := load("res://main.tscn") as PackedScene
	var main := scene.instantiate() as Control
	root.add_child(main)
	await process_frame
	await process_frame

	var track := main.get_node("Battle/Track") as RhythmTrack
	var lane := track.get_node("Lane") as Control
	var hit_zone := track.get_node("HitZone") as Control
	var compass := track.get_node("Lane/InputCompass") as NumpadCompassVisual
	_check(not track.has_node("Lane/ModeCaption") and not track.has_node("Lane/KeyHint"), "Legacy NUMPAD BLADE copy is still present")
	_check(compass != null, "Reactive numpad compass is missing")
	_check(lane.get_global_rect().encloses(compass.get_global_rect()), "Numpad compass escaped the input deck")
	_check(not compass.get_global_rect().intersects(hit_zone.get_global_rect()), "Numpad compass overlaps the hit receptor")
	track.flash_input(KEY_KP_7)
	_check(compass.get_active_key() == KEY_KP_7 and compass.get_activity() > 0.9, "Numpad compass did not react to input")

	var level_index := int(main.call("find_level_index", SONG_ID, "normal"))
	_check(level_index >= 0, "Countdown test song is missing")
	if level_index >= 0:
		main.call("start_level", level_index)
		await process_frame
		await process_frame
		var overlay := main.get_node("CountdownOverlay") as Control
		var stack := main.get_node("CountdownOverlay/Center/Stack") as Control
		var number := stack.get_node("Number") as Label
		var status := stack.get_node("Status") as Label
		var mode := stack.get_node("Mode") as Label
		var feedback := main.get_node("Feedback/Main") as Label
		_check(overlay.visible and number.text == "3" and status.text == "READY", "READY → 3 countdown did not initialize")
		_check(mode.text == "8 KEY · NUMPAD", "Countdown input mode hint is incorrect")
		_check(not stack.has_node("Hint") and not stack.has_node("Song"), "Countdown still contains redundant hint or song copy")
		_check(number.get_theme_font("font").resource_path.ends_with("Poppins-SemiBold.ttf"), "Countdown number is not using Poppins SemiBold")
		var input_event := InputEventKey.new()
		input_event.keycode = KEY_KP_9
		input_event.physical_keycode = KEY_KP_9
		input_event.pressed = true
		main.call("_input", input_event)
		_check(compass.get_active_key() == KEY_KP_9, "Gameplay input did not reach the numpad compass")

		main.set("gameplay_prepare_remaining", 1.9)
		main.call("_update_gameplay_countdown_display", true)
		_check(number.text == "2", "Countdown did not advance to 2")
		main.set("gameplay_prepare_remaining", 0.9)
		main.call("_update_gameplay_countdown_display", true)
		_check(number.text == "1", "Countdown did not advance to 1")
		main.call("_finish_gameplay_countdown")
		_check(number.text == "1" and status.text == "READY", "Countdown should release directly from 1 without a GO card")
		_check(not feedback.visible and feedback.text.is_empty(), "Song title still appears beneath the lane when gameplay starts")

	root.size = Vector2i(960, 540)
	await process_frame
	await process_frame
	main.call("_apply_ui_layout")
	track.apply_layout()
	await process_frame
	_check(lane.get_global_rect().encloses(compass.get_global_rect()), "Compact numpad compass escaped the lane at 960 × 540")
	_check(not compass.get_global_rect().intersects(hit_zone.get_global_rect()), "Compact numpad compass overlaps the hit receptor at 960 × 540")

	main.queue_free()
	await process_frame
	await process_frame
	if failures == 0:
		print("GAMEPLAY_INTRO_POLISH_TEST: PASS")
	else:
		print("GAMEPLAY_INTRO_POLISH_TEST: FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
