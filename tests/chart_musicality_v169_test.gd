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

func _run() -> void:
	var scene := load("res://main.tscn") as PackedScene
	var main := scene.instantiate() as Control
	root.add_child(main)
	await process_frame
	await process_frame
	var catalog: LevelCatalog = main.get_node("LevelCatalog")
	var levels: Array = catalog.load_all(true)
	_check(levels.size() >= 39, "v16.9 must retain all 39 bundled charts.")
	var hard_specials := 0
	var master_reverse := 0
	for raw: Variant in levels:
		if not (raw is Dictionary):
			continue
		var chart: Dictionary = raw as Dictionary
		var integrity: Dictionary = ChartIntegrityScript.validate_structure(chart)
		_check(bool(integrity.get("ok", false)), "Bundled chart failed v16.9 integrity: %s" % str(chart.get("id", "unknown")))
		var arranger: Variant = chart.get("musicality_meta", {})
		_check(arranger is Dictionary and str((arranger as Dictionary).get("version", "")).begins_with("16.9"), "Missing v16.9+ musicality metadata: %s" % str(chart.get("id", "unknown")))
		var diff := str(chart.get("chart_difficulty", "normal")).to_lower()
		var events: Array = chart.get("events", [])
		for event_raw: Variant in events:
			if not (event_raw is Dictionary):
				continue
			var note_type := str((event_raw as Dictionary).get("type", "normal"))
			if diff == "normal":
				_check(note_type == "normal", "NORMAL gained a generated special note in v16.9.")
			elif diff == "hard" and note_type == "reverse":
				hard_specials += 1
			elif diff == "master":
				if note_type == "reverse": master_reverse += 1
	_check(hard_specials > 0, "Hard charts lost Reverse notes.")
	_check(master_reverse > 0, "Master charts must expose the Reverse mechanic.")
	main.queue_free()
	await process_frame
	if failures == 0:
		print("CHART_MUSICALITY_V169_TEST: PASS")
	else:
		print("CHART_MUSICALITY_V169_TEST: FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
