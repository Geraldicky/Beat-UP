extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1440, 900)
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/result_screen.tscn") as PackedScene
	var result := packed.instantiate() as Control
	root.add_child(result)
	await process_frame
	await process_frame

	_check(not result.has_signal("next_requested"), "Removed next_requested signal still exists")
	_check(result.get_node_or_null("MainMargin/RootVBox/BottomBar/NextButton") == null, "NEXT button still exists")
	var back_button := result.get_node("MainMargin/RootVBox/BottomBar/BackButton") as Button
	var replay_button := result.get_node("MainMargin/RootVBox/BottomBar/ReplayButton") as Button
	_check(back_button.visible and replay_button.visible, "The two remaining result actions are not visible")
	_check(back_button.text == "BACK TO LIBRARY", "Back action is not labelled BACK TO LIBRARY")

	var actions := {"back": 0, "replay": 0}
	result.back_requested.connect(func(): actions["back"] = int(actions["back"]) + 1)
	result.replay_requested.connect(func(): actions["replay"] = int(actions["replay"]) + 1)
	back_button.pressed.emit()
	replay_button.pressed.emit()
	_check(int(actions["back"]) == 0 and int(actions["replay"]) == 0, "Actions were enabled before a result reveal")

	result.call("set_result", {
		"title": "RESULT TEST",
		"meta": "TEST ARTIST  •  HARD  •  AUTHORED  •  6★  •  154 BPM",
		"score": 46940,
		"accuracy": 92.5,
		"max_combo": 58,
		"perfect_rate": 76.0,
		"perfect": 76,
		"great": 18,
		"good": 5,
		"miss": 1,
		"rank": "A",
		"rank_sub": "CLEAR",
	})
	await create_timer(0.55).timeout
	var sfx := root.get_node("MenuSFX")
	var motion_state: Dictionary = sfx.call("get_rank_fill_debug_state")
	_check(bool(motion_state.get("active", false)), "Rank charge SFX was not active while the ring filled")
	_check(int(motion_state.get("ticks", 0)) >= 2, "Rank charge did not produce repeated fill cues")

	await create_timer(0.90).timeout
	var final_state: Dictionary = sfx.call("get_rank_fill_debug_state")
	_check(not bool(final_state.get("active", true)), "Rank charge SFX did not stop with the ring")
	_check(int(final_state.get("locks", 0)) == 1, "Rank reveal did not produce exactly one lock cue")
	_check(absf(float(final_state.get("value", 0.0)) - 92.9) < 0.05, "Rank SFX progress did not settle on count-derived accuracy")
	back_button.pressed.emit()
	replay_button.pressed.emit()
	_check(int(actions["back"]) == 1 and int(actions["replay"]) == 0, "Action lock did not admit exactly one completed-result navigation")

	result.queue_free()
	await process_frame
	if failures.is_empty():
		print("RESULT_ACTIONS_V166_TEST: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
