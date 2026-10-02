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

	var ascend := {}
	for raw: Variant in levels:
		if raw is Dictionary and str((raw as Dictionary).get("song_id", "")) == "ascend" and str((raw as Dictionary).get("chart_difficulty", "")) == "normal":
			ascend = raw as Dictionary
			break
	_check(not ascend.is_empty(), "Ascend NORMAL was not found.")
	_check(float(ascend.get("duration", 0.0)) > 220.0, "Ascend duration was not repaired to the bundled audio length.")
	var ascend_events: Array = ascend.get("events", [])
	_check(not ascend_events.is_empty() and float((ascend_events[ascend_events.size() - 1] as Dictionary).get("time", 0.0)) > 215.0, "Ascend still has a missing final song segment.")

	main.queue_free()
	await process_frame
	if failures == 0:
		print("GAMEPLAY_INTEGRITY_V168_REGRESSION_TEST: PASS")
	else:
		print("GAMEPLAY_INTEGRITY_V168_REGRESSION_TEST: FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
