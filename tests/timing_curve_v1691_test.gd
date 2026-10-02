extends SceneTree

const ChartIntegrityScript = preload("res://scripts/chart_integrity.gd")

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)

func _grid_deviation(event_time: float, bpm: float, offset: float, division: int) -> float:
	var step := 60.0 / maxf(1.0, bpm) / float(maxi(1, division))
	var index := roundf((event_time - offset) / step)
	return absf(event_time - (offset + index * step))

func _run() -> void:
	var scene := load("res://main.tscn") as PackedScene
	var main := scene.instantiate() as Control
	root.add_child(main)
	await process_frame
	await process_frame
	var catalog: LevelCatalog = main.get_node("LevelCatalog")
	var levels: Array = catalog.load_all(true)
	_check(levels.size() >= 39, "v16.9.1 must retain all bundled charts.")
	var song_difficulties: Dictionary = {}
	for raw: Variant in levels:
		if not (raw is Dictionary):
			continue
		var chart: Dictionary = raw as Dictionary
		var id := str(chart.get("id", "unknown"))
		var integrity := ChartIntegrityScript.validate_structure(chart)
		_check(bool(integrity.get("ok", false)), "v16.9.1 structural integrity failed: %s" % id)
		var timing: Variant = chart.get("timing_precision_meta", {})
		var curve: Variant = chart.get("difficulty_curve_meta", {})
		_check(timing is Dictionary and str((timing as Dictionary).get("version", "")) == "16.9.1", "Missing timing precision metadata: %s" % id)
		_check(curve is Dictionary and str((curve as Dictionary).get("version", "")) == "16.9.1", "Missing difficulty curve metadata: %s" % id)
		if curve is Dictionary:
			_check(float((curve as Dictionary).get("pressure_max", 0.0)) >= 0.99, "Chart has no explicit musical climax: %s" % id)
		var diff := str(chart.get("chart_difficulty", "normal")).to_lower()
		var division := 2 if diff == "normal" else 4
		var bpm := float(chart.get("bpm", 120.0))
		var offset := float(chart.get("beat_offset", 0.0))
		for event_raw: Variant in chart.get("events", []):
			if not (event_raw is Dictionary):
				continue
			var time := float((event_raw as Dictionary).get("time", 0.0))
			_check(_grid_deviation(time, bpm, offset, division) <= 0.0015, "Bundled note is off the v16.9.1 grid: %s @ %.6f" % [id, time])
		var song_id := str(chart.get("song_id", ""))
		if not song_difficulties.has(song_id):
			song_difficulties[song_id] = {}
		(song_difficulties[song_id] as Dictionary)[diff] = chart

	for song_id_raw: Variant in song_difficulties.keys():
		var song_id := str(song_id_raw)
		var set: Dictionary = song_difficulties[song_id] as Dictionary
		if not (set.has("normal") and set.has("hard") and set.has("master")):
			continue
		var normal: Dictionary = set["normal"] as Dictionary
		var hard: Dictionary = set["hard"] as Dictionary
		var master: Dictionary = set["master"] as Dictionary
		_check((normal.get("events", []) as Array).size() < (hard.get("events", []) as Array).size(), "NORMAL/HARD note-count progression broke: %s" % song_id)
		_check((hard.get("events", []) as Array).size() < (master.get("events", []) as Array).size(), "HARD/MASTER note-count progression broke: %s" % song_id)
		_check(int(normal.get("star_rating", 1)) < int(hard.get("star_rating", 1)), "NORMAL/HARD stars must escalate: %s" % song_id)
		_check(int(hard.get("star_rating", 1)) < int(master.get("star_rating", 1)), "HARD/MASTER stars must escalate: %s" % song_id)

	main.queue_free()
	await process_frame
	if failures == 0:
		print("TIMING_CURVE_V1691_TEST: PASS")
	else:
		print("TIMING_CURVE_V1691_TEST: FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
