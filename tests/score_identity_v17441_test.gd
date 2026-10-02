extends SceneTree

const Identity = preload("res://scripts/score_identity.gd")
const Store = preload("res://scripts/reliable_json_store.gd")
const Telemetry = preload("res://scripts/playtest_telemetry.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var chart: Dictionary = {"song_id": "fixture", "chart_difficulty": "hard", "audio": "res://music/ascend.ogg", "bpm": 120.0, "duration": 10.0, "events": [{"time": 1.0, "direction": 8, "type": "normal"}], "space_events": [2.0]}
	var key8 := Identity.key(chart, "8_direction", false)
	var key4 := Identity.key(chart, "4_arrow", false)
	check(key8 != key4, "4K and 8K must be isolated")
	check(key8 != Identity.key(chart, "8_direction", true), "Random must be isolated")
	var modified := chart.duplicate(true)
	modified.events[0].time = 1.1
	check(key8 != Identity.key(modified, "8_direction", false), "Timing revision must be isolated")
	modified = chart.duplicate(true)
	modified.space_events[0] = 2.1
	check(key8 != Identity.key(modified, "8_direction", false), "SPACE revision must be isolated")
	modified = chart.duplicate(true)
	modified.title = "New display title"
	modified.background = "cosmetic.png"
	modified.events[0]["_runtime_event_index"] = 0
	check(key8 == Identity.key(modified, "8_direction", false), "Cosmetics/runtime caches must not reset records")
	modified = chart.duplicate(true)
	modified.chart_offset_ms = 10.0
	check(key8 != Identity.key(modified, "8_direction", false), "Authored offset must be isolated")
	var config: Resource = load("res://config/gameplay_config.tres").duplicate()
	config.perfect_score += 1
	check(Identity.rules_hash(config) != Identity.rules_hash(), "Scoring config revision must be isolated")
	var legacy := {"fixture::hard": {"score": 987, "accuracy": 72.5, "plays": 9}}
	check(Identity.migrate_legacy(legacy), "First legacy migration must mark records")
	check(not Identity.migrate_legacy(legacy), "Migration must be idempotent")
	check(legacy["fixture::hard"].score == 987 and legacy["fixture::hard"].accuracy == 72.5, "Migration must preserve historical values")
	check(not legacy.has(key8) and not legacy.has(key4), "Legacy must not be assigned a guessed mode")
	var path := "user://v17441_test/records.json"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://v17441_test"))
	check(Store.save_dictionary_atomic(path, legacy), "Legacy save")
	var restored: Dictionary = Store.load_dictionary(path).data
	check(restored["fixture::hard"].score == 987 and restored["fixture::hard"].accuracy == 72.5 and restored["fixture::hard"].record_scope == "legacy_unknown_mode_and_revision", "Migration roundtrip")
	var telemetry := Telemetry.new()
	telemetry.set_storage_root("user://v17441_test/telemetry")
	telemetry.begin_session(chart, "4_arrow", false, 0.0, 0.0, 0.0, Vector2(1600, 900))
	check(telemetry._session.app_version == Identity.app_version(), "Telemetry version")
	check(telemetry._session.score_identity == Identity.identity(chart, "4_arrow", false), "Telemetry chart/rules/mode identity")
	telemetry.abort_session("regression_test")
	# Exercise actual gameplay save and actual Song Library lookup in the engine.
	var game: Control = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.level_data = chart.duplicate(true)
	game.best_stats_store = legacy.duplicate(true)
	game.input_style = "8_direction"
	game.random_mode_enabled = false
	game.score = 1234
	game.total_hits = 1
	game.perfect_hits = 1
	check(game.commit_best_stats(100.0), "8K first best")
	game.input_style = "4_arrow"
	game.score = 456
	check(game.commit_best_stats(80.0), "4K first best independent of higher 8K score")
	check(game.best_stats_store[key8].score == 1234 and game.best_stats_store[key4].score == 456, "Both records preserved")
	game.load_best_stats_store()
	check(game.best_stats_store[key8].score == 1234 and game.best_stats_store[key4].score == 456, "Both records survive reload")
	var selection: Control = game.level_select
	selection.set_catalog([chart])
	selection.set_best_stats_store(game.best_stats_store)
	selection._on_mode_4_selected()
	check(selection._progress_entry("fixture", "hard").get("score") == 456, "Library 4K lookup")
	selection._on_mode_8_selected()
	check(selection._progress_entry("fixture", "hard").get("score") == 1234, "Library 8K lookup")
	selection._on_random_mod_toggled(true)
	check(selection._progress_entry("fixture", "hard").is_empty(), "Random must not inherit authored progress")
	game.queue_free()
	await process_frame
	print("SCORE_IDENTITY_V17441: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(1 if failures else 0)
