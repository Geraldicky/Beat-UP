extends SceneTree

const TelemetryScript = preload("res://scripts/playtest_telemetry.gd")
const TEST_ROOT := "user://v17414_telemetry_test"

func _init() -> void:
    var failures: Array[String] = []
    _cleanup()
    _test_completed_session(failures)
    _test_aborted_session(failures)
    _cleanup()

    if failures.is_empty():
        print("v17.4.14 beta telemetry checks: PASS")
        quit(0)
    else:
        for failure: String in failures:
            push_error(failure)
        quit(1)


func _test_completed_session(failures: Array[String]) -> void:
    var telemetry = TelemetryScript.new()
    telemetry.set_storage_root(TEST_ROOT)
    var chart := {
        "song_id": "telemetry-test",
        "title": "Telemetry Test",
        "artist": "Beat UP!",
        "difficulty": "HARD",
        "chart_difficulty": "hard",
        "bpm": 160.0,
        "duration": 8.0,
        "events": [
            {"time": 1.0, "type": "normal", "direction": 4},
            {"time": 2.0, "type": "reverse", "direction": 6},
        ],
        "space_events": [3.0],
    }
    var session_id: String = telemetry.begin_session(chart, "8_direction", false, 12.0, -8.0, 0.0, Vector2(1280, 720))
    if session_id.is_empty():
        failures.append("Completed telemetry test did not create a session id.")
        return

    telemetry.record_note_judgement(0, 1.0, "normal", 4, "NUM4", "NUM4", "NUM4", "PERFECT", -4.0, "", false, 1, 100)
    telemetry.record_note_judgement(1, 2.0, "reverse", 6, "NUM6", "NUM4", "NUM6", "MISS", 22.0, "WRONG INPUT", false, 0, 100)
    telemetry.record_space_judgement(0, 3.0, "GREAT", 18.0, false, 0, 160)
    var saved: bool = telemetry.complete_session({
        "score": 160,
        "accuracy": 50.0,
        "max_combo": 1,
        "perfect": 1,
        "great": 0,
        "good": 0,
        "miss": 1,
        "space_hits": 1,
        "space_misses": 0,
        "reverse_hits": 0,
        "reverse_misses": 1,
        "rank": "D",
        "rank_sub": "CLEAR",
    })
    if not saved:
        failures.append("Completed telemetry session failed to save.")
        return

    var path := "%s/sessions/%s.json" % [TEST_ROOT, session_id]
    var parsed := _load_json(path)
    if parsed.is_empty():
        failures.append("Completed telemetry session JSON could not be read.")
        return
    if str(parsed.get("status", "")) != "completed":
        failures.append("Completed session status is incorrect.")
    var integrity: Dictionary = parsed.get("integrity", {}) as Dictionary
    if not bool(integrity.get("complete_event_coverage", false)):
        failures.append("Completed session did not report complete event coverage.")
    var events: Array = parsed.get("events", []) as Array
    if events.size() != 3:
        failures.append("Completed session event count mismatch: expected 3 got %d." % events.size())


func _test_aborted_session(failures: Array[String]) -> void:
    var telemetry = TelemetryScript.new()
    telemetry.set_storage_root(TEST_ROOT)
    var chart := {
        "song_id": "abort-test",
        "difficulty": "NORMAL",
        "chart_difficulty": "normal",
        "events": [
            {"time": 1.0, "type": "normal", "direction": 4},
            {"time": 5.0, "type": "normal", "direction": 6},
        ],
        "space_events": [],
    }
    var session_id: String = telemetry.begin_session(chart, "8_direction", false, 0.0, 0.0, 0.0, Vector2(1280, 720))
    telemetry.record_note_judgement(0, 1.0, "normal", 4, "NUM4", "NUM4", "NUM4", "GREAT", 15.0, "", false, 1, 80)
    if not telemetry.abort_session("retry"):
        failures.append("Aborted telemetry session failed to save.")
        return

    var path := "%s/sessions/%s.json" % [TEST_ROOT, session_id]
    var parsed := _load_json(path)
    if str(parsed.get("status", "")) != "aborted":
        failures.append("Aborted session status is incorrect.")
    if str(parsed.get("abort_reason", "")) != "retry":
        failures.append("Aborted session reason is incorrect.")
    var events: Array = parsed.get("events", []) as Array
    if events.size() != 1:
        failures.append("Aborted session fabricated unplayed events.")


func _load_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var parser := JSON.new()
    if parser.parse(FileAccess.get_file_as_string(path)) != OK:
        return {}
    if parser.data is Dictionary:
        return parser.data as Dictionary
    return {}


func _cleanup() -> void:
    var global_root := ProjectSettings.globalize_path(TEST_ROOT)
    if DirAccess.dir_exists_absolute(global_root):
        _remove_tree(global_root)


func _remove_tree(path: String) -> void:
    var dir := DirAccess.open(path)
    if dir == null:
        return
    dir.list_dir_begin()
    var entry := dir.get_next()
    while not entry.is_empty():
        if entry != "." and entry != "..":
            var child := path.path_join(entry)
            if dir.current_is_dir():
                _remove_tree(child)
            else:
                DirAccess.remove_absolute(child)
        entry = dir.get_next()
    dir.list_dir_end()
    DirAccess.remove_absolute(path)
