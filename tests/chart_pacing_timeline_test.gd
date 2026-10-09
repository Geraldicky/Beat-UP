extends SceneTree

const Timeline = preload("res://scripts/chart_timeline.gd")
const Integrity = preload("res://scripts/chart_integrity.gd")
const Settings = preload("res://scripts/user_settings.gd")
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var songs := DirAccess.get_directories_at("res://charts")
	check(songs.size() == 39, "Expected all 39 bundled songs")
	for song: String in songs:
		for difficulty: String in ["normal", "hard", "master"]:
			var path := "res://charts/%s/%s.json" % [song, difficulty]
			var chart: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
			check(bool(Integrity.validate_structure(chart).ok), path + " structure invalid")
			var original := JSON.stringify(chart)
			for raw_rest: Variant in chart.pacing_meta.rest_intervals:
				var rest: Array = raw_rest
				var start := float(rest[0])
				var end := float(rest[1])
				var timeline := Timeline.new()
				timeline.load_events(chart.events)
				# Drain all earlier notes. At maximum read time there must still
				# be a genuinely empty interval, then a preempted next phrase.
				timeline.collect_upcoming(start - Settings.MAX_NOTE_TRAVEL_TIME, Settings.MAX_NOTE_TRAVEL_TIME)
				check(timeline.collect_upcoming(start + 0.25, Settings.MAX_NOTE_TRAVEL_TIME).is_empty(), path + " rest spawns an arrow too early")
				for value: Variant in chart.space_events:
					check(float(value) < start or float(value) >= end - 0.000001, path + " SPACE interrupts rest")
				var resumed := timeline.collect_upcoming(end + 2.0, Settings.MAX_NOTE_TRAVEL_TIME)
				check(not resumed.is_empty(), path + " does not resume after rest")
				for event: Dictionary in resumed:
					check(float(event.time) >= end - 0.000001, path + " scheduler emits an input inside rest")
				timeline.free()
			check(JSON.stringify(chart) == original, path + " scheduler mutates source")
	if failures == 0:
		print("CHART_PACING_TIMELINE_TEST: PASS")
	quit(0 if failures == 0 else 1)
