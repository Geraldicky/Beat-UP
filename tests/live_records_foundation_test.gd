extends SceneTree
const Identity = preload("res://scripts/score_identity.gd")
const Settings = preload("res://scripts/user_settings.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func control_tree_contains_text(root_control: Node, needle: String) -> bool:
	if root_control == null:
		return false
	if root_control is Label and (root_control as Label).text.contains(needle):
		return true
	if root_control is BaseButton and (root_control as BaseButton).text.contains(needle):
		return true
	for child in root_control.get_children():
		if child is Node and control_tree_contains_text(child as Node, needle):
			return true
	return false
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var baseline_orphans: Array[int] = Node.get_orphan_node_ids()
	Settings.set_input_style("8_direction")
	root.get_node("AppSessionState").mark_splash_seen()
	var shell: Control = load("res://scenes/app_shell.tscn").instantiate()
	root.add_child(shell)
	await create_timer(0.5).timeout
	await shell.show_song_library("big_daddy", false)
	var library: Control = shell.song_library_screen
	var selection: Control = library.song_select
	var game: Control = shell.gameplay_screen
	selection._select_difficulty("hard")
	var request := {"song_id": "big_daddy", "difficulty_id": "hard", "random_mode": false}
	shell.launch_gameplay(request, {})
	await create_timer(1.5).timeout
	check(shell.get_active_route() == "gameplay", "Gameplay launch completes")
	game._auto_pause_on_focus_loss()
	check(game.game_paused, "Focus loss pauses gameplay")
	var paused_time: float = game.fight_time
	await create_timer(0.1).timeout
	check(absf(game.fight_time - paused_time) < 0.005, "Clock stays frozen while paused")
	game.resume_gameplay()
	game._finish_resume_countdown()
	check(not game.game_paused, "Resume restores gameplay")
	game._on_music_finished()
	check(game.music_has_finished and not game.fight_over, "Audio endpoint preserves final judgement tail")
	game.fight_over = true
	game.music.stop()
	game.score = 123456
	game.total_hits = game._expected_note_count()
	game.perfect_hits = game.total_hits - 1
	game.great_hits = 1
	game.space_hits = game._expected_space_count()
	game.space_perfects = game.space_hits
	game._finalize_end_fight()
	var key: String = Identity.key(game.level_data, "8_direction", false)
	check(game.best_stats_store.has(key), "Result was saved by gameplay")
	game._on_result_back_pressed()
	await create_timer(0.5).timeout
	check(shell.get_active_route() == "song_library", "Result Back returns to resident library")
	check(library.best_stats_store.has(key), "Visible library receives score without restart")
	check(selection.album_flow_best_score_value != null and selection.album_flow_best_score_value.text == "123,456", "Visible Best Record component displays new score")
	check(selection.ranking_list.get_child_count() > 0 and control_tree_contains_text(selection.ranking_list.get_child(0), "123,456"), "Local run history displays new score")
	check(selection._progress_entry("big_daddy", "hard").get("score", 0) == 123456, "Progress lookup receives new record")
	# Subsequent lower-score run must update plays, while retaining the best.
	shell.launch_gameplay(request, {})
	await create_timer(1.5).timeout
	check(shell.get_active_route() == "gameplay", "Gameplay launch completes")
	game.fight_over = true
	game.music.stop()
	game.score = 100
	game.total_hits = game._expected_note_count()
	game.perfect_hits = game.total_hits
	game.great_hits = 0
	game.space_hits = game._expected_space_count()
	game.space_perfects = game.space_hits
	game._finalize_end_fight()
	await shell.show_main_menu()
	await create_timer(0.2).timeout
	await shell.show_song_library("big_daddy", false)
	check(selection.record_rows.size() == 2, "Play count refreshes through Main Menu route")
	check(selection._progress_entry("big_daddy", "hard").get("score", 0) == 123456, "Lower run preserves best")
	check(float(selection.record_rows[0].accuracy) < 100.0, "Ranking uses accuracy from best-score run")
	check(selection.record_rows.size() == 2, "Both completed runs appear in ranking")
	var lower_run_button := selection.ranking_list.get_child(1) as Button
	check(lower_run_button != null, "Lower-score run row is not interactive.")
	if lower_run_button != null:
		lower_run_button.pressed.emit()
		await process_frame
	var run_dialog := selection.get_child(selection.get_child_count() - 1) as Control
	check(run_dialog != null and run_dialog.get_script() == preload("res://scripts/ui/beat_message_dialog.gd"), "Selecting a run did not open the current Beat Message dialog.")
	check(run_dialog != null and control_tree_contains_text(run_dialog, "Score 100 ·") and control_tree_contains_text(run_dialog, "100.00%"), "Selecting lower-score run displays its coherent metrics")
	if run_dialog != null:
		run_dialog.queue_free()
		await process_frame
	var result_data: Dictionary = game._build_result_snapshot(100.0, false)
	check(result_data.previous_best.score == 123456, "Result comparison retains pre-commit best")
	var export: Dictionary = preload("res://scripts/playtest_export.gd").export_zip()
	var reader := ZIPReader.new()
	check(reader.open(str(export.path)) == OK, "Playtest export opens")
	check(reader.get_files().has("best_level_stats.json"), "Export includes local history")
	check(reader.get_files().size() >= 3, "Export includes both telemetry sessions")
	reader.close()
	selection._on_mode_4_selected()
	check(selection._progress_entry("big_daddy", "hard").is_empty(), "4K remains separate")
	selection._on_mode_8_selected()
	check(selection._progress_entry("big_daddy", "hard").get("score", 0) == 123456, "8K record survives mode switch")
	shell.queue_free()
	await create_timer(0.3).timeout
	for instance_id: int in Node.get_orphan_node_ids():
		if instance_id not in baseline_orphans:
			var orphan := instance_from_id(instance_id) as Node
			check(false, "Resident records lifecycle leaked node: %s" % orphan.name)
	print("LIVE_LIBRARY_RECORDS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(1 if failures else 0)
