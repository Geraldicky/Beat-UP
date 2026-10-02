extends SceneTree
const Identity = preload("res://scripts/score_identity.gd")
const Settings = preload("res://scripts/user_settings.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
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
	game.fight_over = true
	game.music.stop()
	game.score = 123456
	game.total_hits = game._expected_note_count()
	game.perfect_hits = game.total_hits
	game.space_hits = game._expected_space_count()
	game.space_perfects = game.space_hits
	game._finalize_end_fight()
	var key: String = Identity.key(game.level_data, "8_direction", false)
	check(game.best_stats_store.has(key), "Result was saved by gameplay")
	game._on_result_back_pressed()
	await create_timer(0.5).timeout
	check(shell.get_active_route() == "song_library", "Result Back returns to resident library")
	check(library.best_stats_store.has(key), "Visible library receives score without restart")
	check(selection.best_score_value.text == "123,456", "Visible personal best displays new score")
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
	game.space_hits = game._expected_space_count()
	game.space_perfects = game.space_hits
	game._finalize_end_fight()
	await shell.show_main_menu()
	await create_timer(0.2).timeout
	await shell.show_song_library("big_daddy", false)
	check(selection.best_plays_value.text == "2", "Play count refreshes through Main Menu route")
	check(selection._progress_entry("big_daddy", "hard").get("score", 0) == 123456, "Lower run preserves best")
	selection._on_mode_4_selected()
	check(selection._progress_entry("big_daddy", "hard").is_empty(), "4K remains separate")
	selection._on_mode_8_selected()
	check(selection._progress_entry("big_daddy", "hard").get("score", 0) == 123456, "8K record survives mode switch")
	print("LIVE_LIBRARY_RECORDS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	shell.queue_free()
	await create_timer(0.3).timeout
	quit(1 if failures else 0)
