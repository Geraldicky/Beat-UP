extends Node
class_name ChartTimeline

# Data-driven chart scheduler. Charts own rhythmic timestamps and special-note
# placement. SPACE events can be merged into the same scrolling lane so the
# player only has one visual focus point during combat.
var events: Array = []
var spawn_index := 0

func load_events(chart_events: Array) -> void:
	events = chart_events.duplicate(true)
	events.sort_custom(_sort_by_time)
	spawn_index = 0

func load_lane_events(chart_events: Array, space_events: Array, bpm: float, clearance_beats: float) -> Array:
	var merged: Array = []
	var spaces: Array[float] = []
	for value in space_events:
		if value is float or value is int:
			spaces.append(float(value))
	spaces.sort()

	# Avoid true chords around a SPACE prompt. Half-beat neighbours stay intact,
	# so the stream remains continuous, but an arrow cannot occupy essentially
	# the same judgement window as the Beat Strike.
	var clearance_seconds := maxf(0.0, clearance_beats) * 60.0 / maxf(1.0, bpm)
	for raw_event in chart_events:
		if not (raw_event is Dictionary):
			continue
		var event_data: Dictionary = raw_event.duplicate(true)
		var event_time := float(event_data.get("time", 0.0))
		var collides_with_space := false
		for space_time in spaces:
			if absf(event_time - space_time) <= clearance_seconds:
				collides_with_space = true
				break
		if not collides_with_space:
			merged.append(event_data)

	for space_time in spaces:
		merged.append({
			"time": space_time,
			"type": "space",
			"lane_special": true,
		})

	merged.sort_custom(_sort_by_time)
	events = merged
	spawn_index = 0
	return events.duplicate(true)

func reset() -> void:
	spawn_index = 0

func clear() -> void:
	events.clear()
	spawn_index = 0

func collect_upcoming(current_time: float, travel_time: float) -> Array:
	var result: Array = []
	var horizon := current_time + travel_time
	while spawn_index < events.size():
		var event_data = events[spawn_index]
		if not (event_data is Dictionary):
			spawn_index += 1
			continue
		if float(event_data.get("time", 0.0)) > horizon:
			break
		result.append(event_data)
		spawn_index += 1
	return result

func remaining_count() -> int:
	return maxi(0, events.size() - spawn_index)

func _sort_by_time(a: Dictionary, b: Dictionary) -> bool:
	return float(a.get("time", 0.0)) < float(b.get("time", 0.0))
