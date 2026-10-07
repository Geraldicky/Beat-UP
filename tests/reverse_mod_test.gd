extends SceneTree

const ReverseMod = preload("res://scripts/reverse_mod.gd")
const Identity = preload("res://scripts/score_identity.gd")
const Settings = preload("res://scripts/user_settings.gd")
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if OS.get_environment("BEAT_UP_QA_REVERSE_MOD") != "isolated":
		push_error("Reverse QA requires isolated APPDATA/XDG_DATA_HOME and BEAT_UP_QA_REVERSE_MOD=isolated.")
		quit(2)
		return
	var source := {"_source_chart_hash": "qa-readonly", "events": [], "space_events": [1.0, 2.0]}
	for index in range(8):
		source.events.append({"type": "normal", "direction": 8, "time": float(index)})
	source.events.append({"type": "reverse", "direction": 4, "time": 9.0})
	source.events.append({"type": "space", "time": 10.0})
	var original := JSON.stringify(source)
	var keys: Array[String] = []
	for percent: int in ReverseMod.LEVELS:
		var chart := source.duplicate(true)
		ReverseMod.apply(chart, percent)
		var added := 0
		for event: Dictionary in chart.events:
			if bool(event.get("_mod_reverse", false)):
				added += 1
		check(added == roundi(9 * percent / 100.0), "Wrong Reverse fraction, including formerly authored reverse.")
		check(chart.events[8].direction == source.events[8].direction and chart.events[8].time == source.events[8].time, "Normalization changed authored timing/direction.")
		if percent == 0:
			for event: Dictionary in chart.events:
				check(event.type != "reverse", "OFF retains authored reverse.")
		check(chart.events[9] == source.events[9] and chart.space_events == source.space_events, "Space was transformed.")
		var retry := source.duplicate(true)
		ReverseMod.apply(retry, percent)
		check(chart == retry, "Reverse pattern is not deterministic.")
		keys.append(Identity.key(source, "8_direction", false, percent))
	check(JSON.stringify(source) == original, "Source fixture mutated.")
	check(keys[0] == Identity.key(source, "8_direction", false), "OFF identity differs between explicit and default percent.")
	check(Identity.identity(source, "8_direction", false).get("reverse_version") == ReverseMod.VERSION, "Changed authored reverse rules collide with historical PBs.")
	check(not Identity.identity(source, "8_direction", false).has("reverse_percent"), "OFF changes historical identity shape.")
	for index in range(keys.size()):
		check(keys.count(keys[index]) == 1, "Reverse record levels collide.")
	check(keys[2] != Identity.key(source, "4_arrow", false, 50) and keys[2] != Identity.key(source, "8_direction", true, 50), "Mode/Random record scopes collide.")

	var gameplay := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(gameplay)
	await process_frame
	await process_frame
	Settings.set_input_style("8_direction")
	var preparation: Dictionary = gameplay.prepare_launch_request({"song_id": "bad_apple", "difficulty_id": "normal", "reverse_percent": 50, "random_mode": true}, true)
	check(bool(preparation.get("ok", false)), "Reverse launch preparation failed.")
	var request: Dictionary = preparation.get("request", {})
	var authored: Dictionary = request.get("_resolved_chart", {})
	var authored_text := JSON.stringify(authored)
	check(gameplay._launch_from_song_library(request), "Reverse launch failed.")
	root.get_node("SceneTransition").transition_finished.emit()
	gameplay.game_paused = true
	gameplay.music.stop()
	var events: Array = gameplay.level_data.events.duplicate(true)
	check(JSON.stringify(authored) == authored_text, "Launch mutated resolved source.")
	check(gameplay.reverse_mod_percent == 50, "Launch lost the selected Reverse level.")
	var directions: Array = []
	for index in range(mini(24, events.size())):
		directions.append(gameplay.build_note_data(events[index]))
	var retry_preparation: Dictionary = gameplay.prepare_retry_request(true)
	check(int(retry_preparation.request.reverse_percent) == 50, "Retry lost Reverse.")
	check(gameplay._launch_from_song_library(retry_preparation.request), "Retry failed.")
	root.get_node("SceneTransition").transition_finished.emit()
	gameplay.game_paused = true
	gameplay.music.stop()
	check(gameplay.level_data.events == events, "Retry changed Reverse pattern.")
	for index in range(directions.size()):
		check(gameplay.build_note_data(events[index]) == directions[index], "Retry changed RANDOM direction sequence.")

	var manager := root.get_node("ReplayManager")
	manager.begin_recording(gameplay.level_data, gameplay.input_style, true, gameplay.current_random_seed)
	manager.record_action(1.0, "up", KEY_KP_8)
	check(manager.finish_recording({"score": 1}), "Reverse replay could not be saved.")
	var replay: Dictionary = manager.load_latest(gameplay.level_data, gameplay.input_style, true)
	check(not replay.is_empty(), "Reverse replay lookup failed.")
	var wrong: Dictionary = gameplay.level_data.duplicate(true)
	wrong["_reverse_mod_percent"] = 25
	check(not manager.begin_playback(replay, wrong, gameplay.input_style, true), "Replay accepted the wrong Reverse level.")
	var replay_launch: Dictionary = gameplay.prepare_launch_request({"song_id": "bad_apple", "difficulty_id": "normal", "random_mode": true, "replay_data": replay}, true)
	check(gameplay._launch_from_song_library(replay_launch.request), "Reverse replay launch failed.")
	root.get_node("SceneTransition").transition_finished.emit()
	gameplay.game_paused = true
	gameplay.music.stop()
	check(gameplay.replay_playback_active and gameplay.level_data.events == events, "Replay lost its Reverse layout.")
	for index in range(directions.size()):
		check(gameplay.build_note_data(events[index]) == directions[index], "Replay changed RANDOM direction sequence.")

	# Mod-added reverse must not inherit the authored reverse scoring bonus.
	gameplay.replay_playback_active = false
	gameplay.playtest_telemetry.abort_session("qa isolated score probe")
	var mod_event: Dictionary = {}
	for event: Dictionary in gameplay.level_data.events:
		if bool(event.get("_mod_reverse", false)):
			mod_event = event
			break
	check(not mod_event.is_empty(), "No mod reverse candidate found.")
	gameplay.spawn_chart_note(mod_event)
	var note = gameplay.stream_notes.back()
	gameplay.combo = 0
	gameplay.score = 0
	gameplay.register_hit(0.0, note)
	var no_bonus: int = gameplay.score
	note.set_meta("mod_reverse", false)
	gameplay.combo = 0
	gameplay.score = 0
	gameplay.register_hit(0.0, note)
	check(gameplay.score > no_bonus, "Authored bonus was lost or mod reverse gains a bonus.")
	for style: String in ["4_arrow", "8_direction"]:
		Settings.set_input_style(style)
		var roundtrip: Dictionary = gameplay.prepare_launch_request({"song_id": "bad_apple", "difficulty_id": "normal", "reverse_percent": 50}, true)
		check(gameplay._launch_from_song_library(roundtrip.request), "Mode round-trip failed.")
		root.get_node("SceneTransition").transition_finished.emit()
		gameplay.game_paused = true
		gameplay.music.stop()
		check(gameplay.level_data.events == events, "Mode round-trip changed authored/Reverse data.")
		for index in range(mini(24, events.size())):
			var data: Dictionary = gameplay.build_note_data(events[index])
			if style == "4_arrow":
				check(int(data.key) in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN] and int(data.display_key) in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN], "4K Reverse projects to a diagonal input.")
	check(JSON.stringify(authored) == authored_text, "Mode round-trip mutated source chart.")
	gameplay.score = 123
	check(gameplay.commit_best_stats(50.0), "Reverse PB commit failed.")
	var reverse_key := Identity.key(gameplay.level_data, gameplay.input_style, false)
	check(gameplay.best_stats_store.has(reverse_key), "Reverse PB stored under the wrong identity.")
	var off_key := Identity.key(gameplay.level_data, gameplay.input_style, false, 0)
	check(not gameplay.best_stats_store.has(off_key), "Reverse PB overwrote the unmodded record.")
	var off: Dictionary = gameplay.prepare_launch_request({"song_id": "bad_apple", "difficulty_id": "normal"}, true)
	check(gameplay._launch_from_song_library(off.request), "OFF launch failed after Reverse.")
	root.get_node("SceneTransition").transition_finished.emit()
	gameplay.game_paused = true
	gameplay.music.stop()
	check(gameplay.reverse_mod_percent == 0, "OFF retains previous Reverse state.")
	for event: Dictionary in gameplay.level_data.events:
		check(not bool(event.get("_mod_reverse", false)), "OFF leaks transformed runtime notes.")
		check(str(event.get("type", "normal")) != "reverse", "OFF launches authored reverse.")
	check(not bool(gameplay.prepare_launch_request({"song_id": "bad_apple", "difficulty_id": "normal", "reverse_percent": 13}, true).get("ok", false)), "Unsupported Reverse level was accepted.")
	manager.abort_recording()
	manager.stop_playback()
	gameplay.queue_free()
	await process_frame
	print("REVERSE_MOD_TEST: ", "PASS" if failures == 0 else "FAIL", " ", failures)
	quit(0 if failures == 0 else 1)
