extends SceneTree
const Settings = preload("res://scripts/user_settings.gd")
const Identity = preload("res://scripts/score_identity.gd")
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if OS.get_environment("BEAT_UP_QA_READABILITY") != "isolated":
		push_error("Readability QA requires isolated APPDATA/XDG_DATA_HOME and BEAT_UP_QA_READABILITY=isolated.")
		quit(2)
		return
	var config := ConfigFile.new()
	config.set_value("gameplay", "note_travel_time", "broken")
	Settings.normalize_config(config)
	check(float(config.get_value("gameplay", "note_travel_time")) == 1.5, "Malformed speed does not normalize to default.")
	Settings.set_note_travel_time(1.8)
	var gameplay := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(gameplay)
	await process_frame
	await process_frame
	check(not gameplay.has_method("_complete_v18_practice_loop") and not gameplay.has_method("_restart_v18_practice_loop"), "Retired Practice loop remains callable.")
	check(not bool(gameplay.prepare_launch_request({"song_id": "bad_apple", "difficulty_id": "normal", "practice_section_index": 0}, true).ok), "Retired Practice launch is silently accepted.")
	var preparation: Dictionary = gameplay.prepare_launch_request({"song_id": "bad_apple", "difficulty_id": "normal"}, true)
	check(bool(preparation.ok), "Chart resolution failed.")
	var source: Dictionary = preparation.request._resolved_chart
	var original := JSON.stringify(source)
	check(gameplay._launch_from_song_library(preparation.request), "Launch failed.")
	root.get_node("SceneTransition").transition_finished.emit()
	gameplay.game_paused = true
	gameplay.music.stop()
	check(is_equal_approx(gameplay.get_travel_time(), 1.8), "Launch did not capture chosen speed.")
	var identity: Dictionary = Identity.identity(gameplay.level_data, gameplay.input_style, false)
	gameplay.level_data.bpm = 240
	check(is_equal_approx(gameplay.get_travel_time(), 1.8), "High BPM changes visual read time.")
	Settings.set_note_travel_time(1.2)
	check(is_equal_approx(gameplay.get_travel_time(), 1.8), "Active run reads live settings.")
	gameplay.game_paused = false
	gameplay.show_pause_overlay()
	gameplay.resume_gameplay()
	gameplay._finish_resume_countdown()
	check(is_equal_approx(gameplay.get_travel_time(), 1.8), "Pause/resume changes captured read time.")
	gameplay.game_paused = true
	gameplay.music.stop()
	var manager := root.get_node("ReplayManager")
	manager.begin_recording(gameplay.level_data, gameplay.input_style, false, 0)
	check(manager.finish_recording({"score": 0}), "Replay save failed.")
	var replay: Dictionary = manager.load_latest(gameplay.level_data, gameplay.input_style, false)
	check(is_equal_approx(float(replay.get("note_travel_time", 0)), 1.8), "Replay loses visual speed.")
	var retry: Dictionary = gameplay.prepare_retry_request(true)
	check(gameplay._launch_from_song_library(retry.request), "Retry failed.")
	root.get_node("SceneTransition").transition_finished.emit()
	gameplay.game_paused = true
	gameplay.music.stop()
	check(is_equal_approx(gameplay.get_travel_time(), 1.2), "Retry did not capture current settings.")
	check(Identity.identity(gameplay.level_data, gameplay.input_style, false) == identity, "Visual speed changes score identity.")
	var replay_launch: Dictionary = gameplay.prepare_launch_request({"song_id": "bad_apple", "difficulty_id": "normal", "replay_data": replay}, true)
	check(bool(replay_launch.ok), "Current replay rejected.")
	check(gameplay._launch_from_song_library(replay_launch.request), "Replay launch failed.")
	root.get_node("SceneTransition").transition_finished.emit()
	gameplay.game_paused = true
	gameplay.music.stop()
	check(is_equal_approx(gameplay.get_travel_time(), 1.8), "Replay does not restore recorded speed.")
	check(JSON.stringify(source) == original, "Runtime preparation mutated source.")
	var old := replay.duplicate(true)
	old.score_identity.erase("reverse_version")
	check(not bool(gameplay.prepare_launch_request({"song_id": "bad_apple", "difficulty_id": "normal", "replay_data": old}, true).ok), "Historical authored reverse replay silently uses new rules.")

	var startup := (load("res://scenes/startup.tscn") as PackedScene).instantiate()
	root.add_child(startup)
	await process_frame
	await process_frame
	check(startup.note_speed_preview != null and startup.note_speed_slider != null, "Settings has no live speed preview.")
	var presets: HBoxContainer = startup.note_speed_slider.get_parent().get_parent().get_child(3)
	for index in range(3):
		(presets.get_child(index) as Button).pressed.emit()
		check(is_equal_approx(startup.note_speed_slider.value, [1.2, 1.5, 1.8][index]), "Speed preset uses a stale captured value.")
	startup.note_speed_slider.value = 2.0
	check(is_equal_approx(startup.note_speed_preview.travel_time, 2.0) and is_equal_approx(Settings.get_note_travel_time(), 2.0), "Slider fails to update preview/persistence.")
	var preview: Control = startup.note_speed_preview
	for mode: String in ["4_arrow", "8_direction", "4_arrow"]:
		preview.set_context(mode, 250.0)
		for dense: bool in [false, true]:
			preview.set_dense_pattern(dense)
			check(preview.demo_bpm == 250.0, "Preview lost selected BPM.")
			for demo_note: RhythmNote in preview.notes:
				var direction := demo_note.direction_vector
				if mode == "4_arrow":
					check(is_zero_approx(direction.x) or is_zero_approx(direction.y), "4K preview contains a diagonal.")
			check((absf(preview.notes[1].direction_vector.x) > 0.25 and absf(preview.notes[1].direction_vector.y) > 0.25) == (mode == "8_direction"), "Preview mode change retained stale direction semantics.")
	preview.set_dense_pattern(true)
	check(preview._beat_offset(5) - preview._beat_offset(4) == 0.5, "Dense example has no half-beat burst.")
	preview.set_read_time(1.5)
	var standard_count := 0
	for demo_note: RhythmNote in preview.notes:
		standard_count += int(demo_note.visible)
	preview.set_read_time(2.6)
	var slow_count := 0
	for demo_note: RhythmNote in preview.notes:
		slow_count += int(demo_note.visible)
	check(slow_count > standard_count, "Longer reading time incorrectly hides upcoming demo notes.")
	preview.set_context("4_arrow", NAN)
	check(preview.demo_bpm == 140.0, "Invalid preview BPM lacks safe fallback.")
	startup._on_input_style_selected(1)
	check(preview.input_style == "4_arrow" and preview.notes[1].direction_vector == Vector2.RIGHT, "Settings preview does not follow 4K selection.")
	startup._on_input_style_selected(0)
	check(preview.input_style == "8_direction" and absf(preview.notes[1].direction_vector.y) > 0.25, "Settings preview does not follow 8K selection.")
	var library := (load("res://scenes/song_library.tscn") as PackedScene).instantiate()
	root.add_child(library)
	await process_frame
	var select: Control = library.song_select
	select.set_selected_song("aleph_0")
	for mode: String in ["4_arrow", "8_direction"]:
		Settings.set_input_style(mode)
		select._open_note_speed()
		var dialog: AcceptDialog = select.note_speed_dialog
		check(dialog.preview.input_style == mode and dialog.preview.demo_bpm == 250.0, "Library popup did not capture current mode/song BPM.")
		dialog.pattern_button.button_pressed = true
		check(dialog.preview.dense_pattern, "Dense-example control does not update preview.")
		dialog.hide()
	library.queue_free()
	startup._show_settings()
	startup._set_settings_tab(2)
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]:
		root.size = resolution
		await process_frame
		await process_frame
		check(startup.note_speed_slider.get_global_rect().end.y <= startup.settings_panel.get_global_rect().end.y, "Speed slider is clipped away from its preview.")
		check(preview.size.x > 400, "Preview lane collapses at supported desktop resolution.")
	preview.size = Vector2(900, 172)
	preview._update_notes()
	var note: RhythmNote = preview.notes[0]
	note.configure({"type": "normal", "target": 2.0, "travel_time": 2.0, "dx": 0.0, "dy": -1.0})
	note.update_track_position(0.0, 180, 846, 100, 2)
	var start := note.position.x
	note.update_track_position(1.0, 180, 846, 100, 2)
	check(note.position.x < start, "Preview does not travel right to left.")
	note.update_track_position(2.0, 180, 846, 100, 2)
	check(is_equal_approx(note.position.x + note.judgement_anchor.position.x, 180), "Preview does not arrive at hit time.")
	var frozen: float = preview.demo_time
	startup.hide()
	preview._process(0.5)
	check(preview.demo_time == frozen, "Hidden preview keeps animating.")
	var analyzer := preload("res://scripts/wav_auto_analyzer.gd").new()
	var energy: Array[float] = []
	var onset: Array[float] = []
	for sample in range(3000):
		energy.append(0.5 + 0.3 * sin(sample * 0.002))
		onset.append(1.0 if sample % 25 == 0 else 0.1)
	var analysis := {"bpm": 240.0, "duration": 60.0, "hop_seconds": 0.02, "active_start": 0.0, "active_end": 59.0, "energy": energy, "onset": onset}
	for difficulty: String in ["normal", "hard", "master"]:
		var profile: Dictionary = analyzer._difficulty_profile_v10(difficulty)
		var crowded: Array = []
		for index in range(100):
			crowded.append({"time": index * 0.025, "type": "normal"})
		var readable: Array = analyzer._enforce_playability_v15(crowded, 240.0, profile)
		for index in range(1, readable.size()):
			check(float(readable[index].time) - float(readable[index - 1].time) >= float(profile.minimum_gap_seconds) - 0.000001, "Generator allows unreadable high-BPM spacing.")
		var generated: Dictionary = analyzer.generate_chart({"song_id": "qa_readability_synthetic", "chart_difficulty": difficulty}, analysis, difficulty)
		check(not generated.events.is_empty(), "Generator returned an empty difficulty.")
		check(bool(analyzer.validate_generated_chart(generated).ok), "Generated high-BPM chart fails playability validation.")
		for event: Dictionary in generated.events:
			check(event.type == "normal", "Generator still authors reverse notes.")
		for index in range(1, generated.events.size()):
			check(float(generated.events[index].time) - float(generated.events[index - 1].time) >= float(profile.minimum_gap_seconds) - 0.000001, "Generated chart bypasses absolute readability floor.")
	analyzer = null
	manager.abort_recording()
	manager.stop_playback()
	startup.queue_free()
	gameplay.queue_free()
	await process_frame
	print("NOTE_READABILITY_TEST: ", "PASS" if failures == 0 else "FAIL", " ", failures)
	quit(0 if failures == 0 else 1)
