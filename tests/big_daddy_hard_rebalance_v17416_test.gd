extends SceneTree

func _init() -> void:
    var path := "res://charts/big_daddy/hard.json"
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("v17.4.16: cannot open Big Daddy HARD chart")
        quit(1)
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not (parsed is Dictionary):
        push_error("v17.4.16: invalid chart JSON")
        quit(1)
        return
    var chart: Dictionary = parsed as Dictionary
    var events: Array = chart.get("events", [])
    var spaces: Array = chart.get("space_events", [])
    var reverse_count := 0
    var previous_time := -1.0
    for raw_event: Variant in events:
        if not (raw_event is Dictionary):
            push_error("v17.4.16: malformed event")
            quit(1)
            return
        var event: Dictionary = raw_event as Dictionary
        var time_value := float(event.get("time", -1.0))
        if time_value < previous_time:
            push_error("v17.4.16: chart timestamps are not sorted")
            quit(1)
            return
        previous_time = time_value
        if str(event.get("type", "normal")) == "reverse":
            reverse_count += 1

    if events.size() != 820:
        push_error("v17.4.16: expected 820 notes, got %d" % events.size())
        quit(1)
        return
    if spaces.size() != 17:
        push_error("v17.4.16: expected 17 SPACE events, got %d" % spaces.size())
        quit(1)
        return
    if reverse_count != 101:
        push_error("v17.4.16: expected 101 Reverse notes, got %d" % reverse_count)
        quit(1)
        return
    if int(chart.get("star_rating", 0)) != 8:
        push_error("v17.4.16: Big Daddy HARD must remain 8 stars")
        quit(1)
        return

    print("v17.4.16 Big Daddy HARD rebalance checks: PASS")
    quit(0)
