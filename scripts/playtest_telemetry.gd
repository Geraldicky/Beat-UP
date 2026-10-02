extends RefCounted
class_name PlaytestTelemetry
const ScoreIdentity = preload("res://scripts/score_identity.gd")

const ReliableJsonStoreScript = preload("res://scripts/reliable_json_store.gd")
const PlayerProfileScript = preload("res://scripts/player_profile.gd")

const DEFAULT_STORAGE_ROOT := "user://playtest_data"
const SCHEMA_VERSION := 3
const MAX_INDEXED_SESSIONS := 250

var storage_root: String = DEFAULT_STORAGE_ROOT
var _active: bool = false
var _session: Dictionary = {}
var _note_expectations: Dictionary = {}
var _space_expectations: Dictionary = {}
var _recorded_keys: Dictionary = {}
var _sequence: int = 0
var _pause_count: int = 0


func set_storage_root(path: String) -> void:
    var trimmed: String = path.strip_edges()
    if trimmed.is_empty():
        storage_root = DEFAULT_STORAGE_ROOT
    else:
        storage_root = trimmed.trim_suffix("/")


func is_active() -> bool:
    return _active


func get_active_session_id() -> String:
    if not _active:
        return ""
    return str(_session.get("session_id", ""))


func begin_session(
    level_data: Dictionary,
    input_style: String,
    random_mode: bool,
    input_offset_ms: float,
    audio_offset_ms: float,
    chart_target_offset_s: float,
    viewport_size: Vector2
) -> String:
    if _active:
        abort_session("superseded")

    _ensure_storage_dirs()
    _note_expectations.clear()
    _space_expectations.clear()
    _recorded_keys.clear()
    _sequence = 0
    _pause_count = 0

    _build_expectations(level_data, chart_target_offset_s)

    var player_id: String = PlayerProfileScript.get_player_id()
    var session_id: String = _make_session_id()
    var difficulty_id: String = str(level_data.get("chart_difficulty", level_data.get("difficulty", "normal"))).to_lower()
    var song_id: String = str(level_data.get("song_id", level_data.get("id", "unknown-song")))
    var build_channel: String = "release"
    if OS.has_feature("editor"):
        build_channel = "editor"
    elif OS.has_feature("debug"):
        build_channel = "debug"

    _session = {
        "schema_version": SCHEMA_VERSION,
        "app_version": ScoreIdentity.app_version(),
        "local_only": true,
        "score_identity": ScoreIdentity.identity(level_data, input_style, random_mode),
        "player_id": player_id,
        "session_id": session_id,
        "status": "active",
        "started_at_unix_ms": _unix_ms(),
        "completed_at_unix_ms": 0,
        "abort_reason": "",
        "build_channel": build_channel,
        "song": {
            "song_id": song_id,
            "title": str(level_data.get("title", song_id)),
            "artist": str(level_data.get("artist", "Unknown Artist")),
            "difficulty": difficulty_id,
            "difficulty_label": str(level_data.get("difficulty", difficulty_id)).to_upper(),
            "bpm": float(level_data.get("bpm", 120.0)),
            "star_rating": int(level_data.get("star_rating", 0)),
            "duration_s": float(level_data.get("duration", 0.0)),
        },
        "gameplay": {
            "input_style": input_style,
            "random_mode": random_mode,
            "input_offset_ms": input_offset_ms,
            "audio_offset_ms": audio_offset_ms,
            "chart_target_offset_ms": chart_target_offset_s * 1000.0,
            "viewport_width": int(round(viewport_size.x)),
            "viewport_height": int(round(viewport_size.y)),
            "os": OS.get_name(),
        },
        "expected": {
            "notes": _note_expectations.size(),
            "space": _space_expectations.size(),
            "total": _note_expectations.size() + _space_expectations.size(),
        },
        "pause_count": 0,
        "events": [],
        "result": {},
        "integrity": {},
    }
    _active = true
    return session_id


func record_pause() -> void:
    if not _active:
        return
    _pause_count += 1
    _session["pause_count"] = _pause_count


func record_note_judgement(
    event_index: int,
    target_time_s: float,
    note_type: String,
    authored_direction: int,
    expected_input: String,
    displayed_input: String,
    player_input: String,
    judgement: String,
    timing_error_ms: Variant,
    reason: String,
    automatic: bool,
    combo_after: int,
    score_after: int
) -> void:
    if not _active:
        return

    var key: String = "note:unknown:%d" % _sequence
    if event_index >= 0:
        key = "note:%d" % event_index
    if event_index >= 0 and _recorded_keys.has(key):
        push_warning("Beat UP! telemetry: duplicate note judgement ignored for event %d." % event_index)
        return

    var event: Dictionary = {
        "sequence": _sequence,
        "kind": "note",
        "event_index": event_index,
        "target_time_ms": int(round(target_time_s * 1000.0)),
        "note_type": note_type,
        "authored_direction": authored_direction,
        "expected_input": expected_input,
        "displayed_input": displayed_input,
        "player_input": player_input,
        "judgement": judgement,
        "timing_error_ms": timing_error_ms,
        "input_time_ms": _input_time_ms(target_time_s, timing_error_ms),
        "automatic": automatic,
        "reason": reason,
        "combo_after": maxi(0, combo_after),
        "score_after": maxi(0, score_after),
    }
    _append_event(key, event)


func record_space_judgement(
    space_index: int,
    target_time_s: float,
    judgement: String,
    timing_error_ms: Variant,
    automatic: bool,
    combo_after: int,
    score_after: int
) -> void:
    if not _active:
        return

    var key: String = "space:unknown:%d" % _sequence
    if space_index >= 0:
        key = "space:%d" % space_index
    if space_index >= 0 and _recorded_keys.has(key):
        push_warning("Beat UP! telemetry: duplicate SPACE judgement ignored for event %d." % space_index)
        return

    var event: Dictionary = {
        "sequence": _sequence,
        "kind": "space",
        "event_index": space_index,
        "target_time_ms": int(round(target_time_s * 1000.0)),
        "note_type": "space",
        "expected_input": "SPACE",
        "displayed_input": "SPACE",
        "player_input": _space_player_input(automatic),
        "judgement": judgement,
        "timing_error_ms": timing_error_ms,
        "input_time_ms": _input_time_ms(target_time_s, timing_error_ms),
        "automatic": automatic,
        "reason": "MISS" if judgement == "MISS" else "",
        "combo_after": maxi(0, combo_after),
        "score_after": maxi(0, score_after),
    }
    _append_event(key, event)


func complete_session(result_snapshot: Dictionary) -> bool:
    if not _active:
        return false

    _reconcile_missing_completed_events()
    _session["status"] = "completed"
    _session["completed_at_unix_ms"] = _unix_ms()
    _session["abort_reason"] = ""
    _session["result"] = _compact_result(result_snapshot)
    return _finalize_and_save()


func abort_session(reason: String) -> bool:
    if not _active:
        return false

    _session["status"] = "aborted"
    _session["completed_at_unix_ms"] = _unix_ms()
    _session["abort_reason"] = reason
    _session["result"] = {
        "judged_event_count": _current_event_count(),
    }
    return _finalize_and_save()


func _append_event(key: String, event: Dictionary) -> void:
    var raw_events: Variant = _session.get("events", [])
    var events: Array = []
    if raw_events is Array:
        events = raw_events as Array
    events.append(event)
    _session["events"] = events
    _recorded_keys[key] = true
    _sequence += 1


func _build_expectations(level_data: Dictionary, chart_target_offset_s: float) -> void:
    var raw_events: Variant = level_data.get("events", [])
    if raw_events is Array:
        var events: Array = raw_events as Array
        for note_index in range(events.size()):
            var raw_event: Variant = events[note_index]
            if not (raw_event is Dictionary):
                continue
            var event_data: Dictionary = raw_event as Dictionary
            _note_expectations[note_index] = {
                "event_index": note_index,
                "target_time_ms": int(round((float(event_data.get("time", 0.0)) + chart_target_offset_s) * 1000.0)),
                "note_type": str(event_data.get("type", "normal")),
                "authored_direction": int(event_data.get("direction", 0)),
            }

    var raw_space: Variant = level_data.get("space_events", [])
    if raw_space is Array:
        var spaces: Array = raw_space as Array
        for space_index in range(spaces.size()):
            var value: Variant = spaces[space_index]
            if value is int or value is float:
                _space_expectations[space_index] = {
                    "event_index": space_index,
                    "target_time_ms": int(round((float(value) + chart_target_offset_s) * 1000.0)),
                }


func _reconcile_missing_completed_events() -> void:
    for raw_index: Variant in _note_expectations.keys():
        var note_index: int = int(raw_index)
        var key: String = "note:%d" % note_index
        if _recorded_keys.has(key):
            continue
        var expected: Dictionary = _note_expectations.get(note_index, {}) as Dictionary
        var event: Dictionary = {
            "sequence": _sequence,
            "kind": "note",
            "event_index": note_index,
            "target_time_ms": int(expected.get("target_time_ms", 0)),
            "note_type": str(expected.get("note_type", "normal")),
            "authored_direction": int(expected.get("authored_direction", 0)),
            "expected_input": "",
            "displayed_input": "",
            "player_input": "",
            "judgement": "MISS",
            "timing_error_ms": null,
            "input_time_ms": null,
            "automatic": true,
            "reason": "RESULT_RECONCILIATION",
            "combo_after": null,
            "score_after": null,
        }
        _append_event(key, event)

    for raw_index: Variant in _space_expectations.keys():
        var space_index: int = int(raw_index)
        var key: String = "space:%d" % space_index
        if _recorded_keys.has(key):
            continue
        var expected: Dictionary = _space_expectations.get(space_index, {}) as Dictionary
        var event: Dictionary = {
            "sequence": _sequence,
            "kind": "space",
            "event_index": space_index,
            "target_time_ms": int(expected.get("target_time_ms", 0)),
            "note_type": "space",
            "expected_input": "SPACE",
            "displayed_input": "SPACE",
            "player_input": "",
            "judgement": "MISS",
            "timing_error_ms": null,
            "input_time_ms": null,
            "automatic": true,
            "reason": "RESULT_RECONCILIATION",
            "combo_after": null,
            "score_after": null,
        }
        _append_event(key, event)


func _compact_result(data: Dictionary) -> Dictionary:
    return {
        "score": maxi(0, int(data.get("score", 0))),
        "accuracy": clampf(float(data.get("accuracy", 0.0)), 0.0, 100.0),
        "max_combo": maxi(0, int(data.get("max_combo", 0))),
        "perfect": maxi(0, int(data.get("perfect", 0))),
        "great": maxi(0, int(data.get("great", 0))),
        "good": maxi(0, int(data.get("good", 0))),
        "miss": maxi(0, int(data.get("miss", 0))),
        "space_hits": maxi(0, int(data.get("space_hits", 0))),
        "space_misses": maxi(0, int(data.get("space_misses", 0))),
        "reverse_hits": maxi(0, int(data.get("reverse_hits", 0))),
        "reverse_misses": maxi(0, int(data.get("reverse_misses", 0))),
        "rank": str(data.get("rank", "D")),
        "rank_sub": str(data.get("rank_sub", "CLEAR")),
        "new_best": bool(data.get("new_best", false)),
    }


func _finalize_and_save() -> bool:
    var raw_events: Variant = _session.get("events", [])
    var events: Array = []
    if raw_events is Array:
        events = (raw_events as Array).duplicate(true)
    events.sort_custom(Callable(self, "_sort_event_by_target"))
    _session["events"] = events

    var expected_total: int = _note_expectations.size() + _space_expectations.size()
    var completed: bool = str(_session.get("status", "")) == "completed"
    _session["integrity"] = {
        "expected_event_count": expected_total,
        "recorded_event_count": events.size(),
        "complete_event_coverage": completed and events.size() == expected_total,
    }

    var session_id: String = str(_session.get("session_id", "unknown"))
    var session_path: String = "%s/%s.json" % [_sessions_dir(), session_id]
    var saved: bool = ReliableJsonStoreScript.save_dictionary_atomic(session_path, _session)
    if saved:
        _append_index_entry(session_path)
        var profile_saved: bool = PlayerProfileScript.record_session(
            session_id,
            str(_session.get("status", "")),
            int(_session.get("started_at_unix_ms", 0)),
            int(_session.get("completed_at_unix_ms", 0))
        )
        if not profile_saved:
            push_warning("Beat UP! telemetry: session saved, but local player profile stats update failed.")
        print("Beat UP! telemetry saved: %s" % session_path)
    else:
        push_error("Beat UP! telemetry: failed to save session %s." % session_id)

    _active = false
    _session = {}
    _note_expectations.clear()
    _space_expectations.clear()
    _recorded_keys.clear()
    _sequence = 0
    _pause_count = 0
    return saved


func _append_index_entry(session_path: String) -> void:
    var index_result: Dictionary = ReliableJsonStoreScript.load_dictionary(_index_path())
    var index_data: Dictionary = {}
    var raw_data: Variant = index_result.get("data", {})
    if raw_data is Dictionary:
        index_data = raw_data as Dictionary

    var sessions: Array = []
    var raw_sessions: Variant = index_data.get("sessions", [])
    if raw_sessions is Array:
        sessions = (raw_sessions as Array).duplicate(true)

    var song: Dictionary = _session.get("song", {}) as Dictionary
    var result: Dictionary = _session.get("result", {}) as Dictionary
    sessions.append({
        "player_id": str(_session.get("player_id", "")),
        "session_id": str(_session.get("session_id", "")),
        "status": str(_session.get("status", "")),
        "started_at_unix_ms": int(_session.get("started_at_unix_ms", 0)),
        "completed_at_unix_ms": int(_session.get("completed_at_unix_ms", 0)),
        "song_id": str(song.get("song_id", "")),
        "difficulty": str(song.get("difficulty", "")),
        "score": int(result.get("score", 0)),
        "accuracy": float(result.get("accuracy", 0.0)),
        "path": session_path,
    })

    while sessions.size() > MAX_INDEXED_SESSIONS:
        var removed_value: Variant = sessions.pop_front()
        if removed_value is Dictionary:
            var removed_path: String = str((removed_value as Dictionary).get("path", ""))
            if removed_path.begins_with(_sessions_dir() + "/") and FileAccess.file_exists(removed_path):
                DirAccess.remove_absolute(ProjectSettings.globalize_path(removed_path))

    index_data["schema_version"] = SCHEMA_VERSION
    index_data["app_version"] = ScoreIdentity.app_version()
    index_data["session_count"] = sessions.size()
    index_data["sessions"] = sessions
    if not ReliableJsonStoreScript.save_dictionary_atomic(_index_path(), index_data):
        push_warning("Beat UP! telemetry: session saved but index update failed.")


func _sort_event_by_target(a: Dictionary, b: Dictionary) -> bool:
    var a_time: int = int(a.get("target_time_ms", 0))
    var b_time: int = int(b.get("target_time_ms", 0))
    if a_time == b_time:
        return int(a.get("sequence", 0)) < int(b.get("sequence", 0))
    return a_time < b_time


func _current_event_count() -> int:
    var raw_events: Variant = _session.get("events", [])
    if raw_events is Array:
        return (raw_events as Array).size()
    return 0


func _input_time_ms(target_time_s: float, timing_error_ms: Variant) -> Variant:
    if timing_error_ms == null:
        return null
    if not (timing_error_ms is int or timing_error_ms is float):
        return null
    return float(target_time_s * 1000.0) + float(timing_error_ms)


func _space_player_input(automatic: bool) -> String:
    if automatic:
        return ""
    return "SPACE"


func _ensure_storage_dirs() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(storage_root))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_sessions_dir()))


func _sessions_dir() -> String:
    return "%s/sessions" % storage_root


func _index_path() -> String:
    return "%s/session_index.json" % storage_root


func _make_session_id() -> String:
    return "%d_%d" % [_unix_ms(), int(Time.get_ticks_usec() % 1000000)]


func _unix_ms() -> int:
    return int(round(Time.get_unix_time_from_system() * 1000.0))
