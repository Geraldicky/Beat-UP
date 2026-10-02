extends SceneTree
const Records = preload("res://scripts/run_records.gd")
const Store = preload("res://scripts/reliable_json_store.gd")
const Integrity = preload("res://scripts/chart_integrity.gd")
const Timing = preload("res://scripts/rhythm_timing.gd")
var failures: int = 0
func check(ok: bool, message: String) -> void:
 if not ok:
  failures += 1
  push_error(message)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var shell_resource: PackedScene = load("res://scenes/app_shell.tscn")
 var editor_resource: PackedScene = load("res://scenes/chart_editor.tscn")
 check(shell_resource != null and editor_resource != null, "Resident and editor scenes load")
 var a: Dictionary = {"run_id": "a", "score": 2000, "accuracy": 90.0, "max_combo": 20, "rank": "A", "run_full_combo": false, "perfect": 8, "miss": 2}
 var b: Dictionary = {"run_id": "b", "score": 1000, "accuracy": 100.0, "max_combo": 40, "rank": "SS", "run_full_combo": true, "perfect": 10, "miss": 0}
 var first: Dictionary = Records.merge({}, a).entry
 var second: Dictionary = Records.merge(first, b).entry
 check(second.score == 2000 and second.accuracy == 90 and second.rank == "A" and not second.run_full_combo, "Best run must remain coherent")
 check(second.best_accuracy == 100 and second.best_max_combo == 40 and second.full_combo, "Aggregates preserved independently")
 check(second.runs.size() == 2 and Records.ranked(second)[1].run_id == "b", "Lower score retained in ranking")
 check(Records.merge(second, b).entry.plays == 2, "Duplicate completion does not increment plays")
 check(Store.save_dictionary_atomic("user://test_records.json", second), "Save succeeds")
 check(Store.load_dictionary("user://test_records.json").data.runs.size() == 2, "History survives restart")
 var legacy: Dictionary = {"score": 3000, "accuracy": 95, "max_combo": 50, "plays": 6, "full_combo": true}
 var migrated: Dictionary = Records.merge(legacy, a).entry
 check(migrated.legacy_record == legacy and migrated.plays == 7, "Legacy remains intact without invented runs")
 var chart: Dictionary = {"audio": "missing.ogg", "duration": 10.0, "events": [{"time": 1.0, "direction": 8}], "space_events": [-1.0]}
 check(not Integrity.validate_structure(chart).ok, "Reject negative SPACE")
 chart.space_events = [11.0]
 check(not Integrity.validate_structure(chart).ok, "Reject SPACE beyond duration")
 chart.space_events = []
 chart.events[0].time = "bad"
 check(not Integrity.validate_structure(chart).ok, "Reject nonnumeric event")
 for fps: int in [30, 60, 144]:
  var previous: float = 0.0
  for frame in range(fps * 2):
   var time: float = float(frame) / float(fps)
   var current: float = Timing.stabilize_monotonic_audio_time(time - (0.05 if frame % 7 == 0 else 0.0), previous, frame > 0)
   check(current >= previous, "Clock must not go backwards")
   previous = current
  check(is_equal_approx(Timing.get_input_judgment_time(1.1, 100), 1.0), "Offset applied once")
 var identity = preload("res://scripts/score_identity.gd")
 var valid_chart: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://charts/big_daddy/hard.json"))
 check(identity.key(valid_chart, "4_arrow", false) != identity.key(valid_chart, "8_direction", false), "Input modes stay separate")
 check(identity.key(valid_chart, "8_direction", false) != identity.key(valid_chart, "8_direction", true), "Random stays separate")
 valid_chart.song_id = "qa_import_foundation"
 var source := FileAccess.open("user://import_fixture.json", FileAccess.WRITE)
 source.store_string(JSON.stringify(valid_chart))
 source.close()
 var catalog = preload("res://scripts/level_catalog.gd").new()
 root.add_child(catalog)
 check(catalog.import_chart_file("user://import_fixture.json").ok, "Valid import succeeds")
 var imported_hash: String = FileAccess.get_sha256("user://songs/qa_import_foundation/hard.json")
 check(not catalog.import_chart_file("user://import_fixture.json").ok, "Duplicate import refused")
 check(imported_hash == FileAccess.get_sha256("user://songs/qa_import_foundation/hard.json"), "Duplicate import preserves original")
 catalog.queue_free()
 var export: Dictionary = preload("res://scripts/playtest_export.gd").export_zip()
 check(bool(export.ok), "Export ZIP created")
 var reader := ZIPReader.new()
 check(reader.open(str(export.path)) == OK, "Export readable")
 reader.close()
 await create_timer(1.0).timeout
 print("RECORDS_FOUNDATION: ", "PASS" if failures == 0 else "FAIL", " ", failures)
 quit(1 if failures else 0)
