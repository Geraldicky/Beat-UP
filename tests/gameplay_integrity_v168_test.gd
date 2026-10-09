extends SceneTree

const ChartIntegrityScript = preload("res://scripts/chart_integrity.gd")
const ResultConfigScript = preload("res://config/result_config.gd")

var failures := 0

func _initialize() -> void:
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

	main.set("perfect_hits", 0)
	main.set("great_hits", 0)
	main.set("total_hits", 100)
	main.set("total_misses", 0)
	var all_good_accuracy := float(main.call("calculate_accuracy"))
	_check(absf(all_good_accuracy - 50.0) < 0.01, "100 GOOD judgments must be 50% accuracy, not 100%.")

	main.set("perfect_hits", 100)
	main.set("great_hits", 0)
	main.set("total_hits", 100)
	main.set("total_misses", 0)
	_check(absf(float(main.call("calculate_accuracy")) - 100.0) < 0.01, "All PERFECT judgments must remain 100% accuracy.")

	var catalog: LevelCatalog = main.get_node("LevelCatalog")
	var levels: Array = catalog.load_all(true)
	_check(levels.size() >= 39, "Bundled chart catalog unexpectedly lost charts.")
	for raw: Variant in levels:
		if not (raw is Dictionary):
			continue
		var chart: Dictionary = raw as Dictionary
		var integrity: Dictionary = chart.get("_integrity", {})
		_check(bool(integrity.get("playable", false)), "Bundled chart failed integrity: %s" % str(chart.get("id", "unknown")))
		_check(int(chart.get("star_rating", 0)) >= 1 and int(chart.get("star_rating", 0)) <= 12, "Estimated stars are outside 1..12.")

	# Ascend was retired. Keep the live invariant, not a deleted content name:
	# stale chart metadata must never truncate runtime audio or its final phrase.
	var resolved := catalog.resolve_playable("bad_apple", "normal", true)
	_check(bool(resolved.get("ok", false)), "Bundled duration fixture must resolve.")
	var audio := resolved.get("audio_stream") as AudioStream
	if audio != null:
		main.get_node("Audio/Music").set("stream", audio)
		main.set("level_data", {"duration": 10.0})
		var duration := audio.get_length()
		_check(duration > 220.0, "Duration fixture must exercise a long track.")
		_check(absf(float(main.call("get_song_duration")) - duration) < 0.01, "Runtime duration must prefer audio over stale JSON metadata.")
		var timeline := ChartTimeline.new()
		timeline.load_events([{"time": duration - 1.0, "direction": 0}])
		_check(not timeline.collect_upcoming(duration - 2.0, 2.0).is_empty(), "Final phrase must remain schedulable beyond stale metadata duration.")
		timeline.free()

	main.queue_free()
	await process_frame
	if failures == 0:
		print("GAMEPLAY_INTEGRITY_V168_REGRESSION_TEST: PASS")
	else:
		print("GAMEPLAY_INTEGRITY_V168_REGRESSION_TEST: FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
