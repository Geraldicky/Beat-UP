extends RefCounted
class_name ChartIntegrity

const VALID_DIRECTIONS := [1, 2, 3, 4, 6, 7, 8, 9]
const VALID_TYPES := ["normal", "reverse"]
const INTEGRITY_VERSION := "16.9.1"

static func decorate_chart(chart: Dictionary) -> Dictionary:
	var report := validate_structure(chart)
	chart["_integrity"] = report
	var previous_stars := int(chart.get("star_rating", 1))
	var estimated_stars := estimate_star_rating(chart)
	chart["legacy_star_rating"] = previous_stars
	chart["star_rating"] = estimated_stars
	chart["difficulty_rating_meta"] = {
		"version": INTEGRITY_VERSION,
		"model": "density_peak_speed_special_curve_v1691",
		"legacy_stars": previous_stars,
		"estimated_stars": estimated_stars,
	}
	return chart

static func validate_structure(chart: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var events_value: Variant = chart.get("events", [])
	if not (events_value is Array):
		errors.append("events must be an Array")
		return {"ok": false, "playable": false, "errors": errors, "warnings": warnings, "version": INTEGRITY_VERSION}
	var events: Array = events_value as Array
	if events.is_empty():
		errors.append("chart contains no directional events")
	var previous_time := -INF
	for i in range(events.size()):
		var raw: Variant = events[i]
		if not (raw is Dictionary):
			errors.append("event %d is not a Dictionary" % i)
			continue
		var event: Dictionary = raw as Dictionary
		if not (event.get("time") is int or event.get("time") is float):
			errors.append("event %d time must be numeric" % i)
			continue
		var time := float(event.get("time", -1.0))
		if not is_finite(time):
			errors.append("event %d time must be finite" % i)
		if float(chart.get("duration", 0.0)) > 0.0 and time > float(chart.duration):
			errors.append("event %d exceeds duration" % i)
		if time < 0.0:
			errors.append("event %d has a negative time" % i)
		if time <= previous_time + 0.0000001:
			errors.append("event timing is not strictly increasing at index %d" % i)
		previous_time = time
		var note_type := str(event.get("type", "normal"))
		if not VALID_TYPES.has(note_type):
			errors.append("event %d has unsupported type '%s'" % [i, note_type])
		var direction := int(event.get("direction", 0))
		if not VALID_DIRECTIONS.has(direction):
			errors.append("event %d has invalid direction" % i)
	var spaces_value: Variant = chart.get("space_events", [])
	if not (spaces_value is Array):
		errors.append("space_events must be an Array")
	else:
		var previous_space := -INF
		var spaces: Array = spaces_value as Array
		for raw_space: Variant in spaces:
			if not (raw_space is float or raw_space is int):
				errors.append("SPACE timing must be numeric")
				continue
			var space_time := float(raw_space)
			if not is_finite(space_time) or space_time < 0.0:
				errors.append("SPACE time must be finite and nonnegative")
			if float(chart.get("duration", 0.0)) > 0.0 and space_time > float(chart.duration):
				errors.append("SPACE time exceeds duration")
			if space_time <= previous_space + 0.0000001:
				errors.append("SPACE timings must be strictly increasing")
			previous_space = space_time
	var duration := float(chart.get("duration", 0.0))
	if duration <= 0.0:
		warnings.append("chart duration is missing; runtime audio length will be preferred")
	elif not events.is_empty():
		var last_raw: Variant = events[events.size() - 1]
		if last_raw is Dictionary:
			var tail_gap := duration - float((last_raw as Dictionary).get("time", 0.0))
			if tail_gap > 20.0:
				warnings.append("chart has an unusually long silent tail (%.1fs)" % tail_gap)
	return {
		"ok": errors.is_empty(),
		"playable": errors.is_empty() and not events.is_empty() and not str(chart.get("audio", "")).is_empty(),
		"errors": errors,
		"warnings": warnings,
		"version": INTEGRITY_VERSION,
	}

static func estimate_star_rating(chart: Dictionary) -> int:
	var events_value: Variant = chart.get("events", [])
	if not (events_value is Array) or (events_value as Array).is_empty():
		return 1
	var events: Array = events_value as Array
	var times: Array[float] = []
	var reverse_count := 0
	for raw: Variant in events:
		if not (raw is Dictionary):
			continue
		var event: Dictionary = raw as Dictionary
		times.append(float(event.get("time", 0.0)))
		match str(event.get("type", "normal")):
			"reverse": reverse_count += 1
	times.sort()
	var duration := maxf(1.0, float(chart.get("duration", 0.0)))
	var average_nps := float(times.size()) / duration
	var peak_1s := 0
	var right := 0
	for left in range(times.size()):
		if right < left:
			right = left
		while right < times.size() and times[right] <= times[left] + 1.0 + 0.000001:
			right += 1
		peak_1s = maxi(peak_1s, right - left)
	var gaps: Array[float] = []
	for i in range(1, times.size()):
		var gap := times[i] - times[i - 1]
		if gap > 0.000001:
			gaps.append(gap)
	gaps.sort()
	var p10_gap_ms := 1000.0
	if not gaps.is_empty():
		var p10_index := clampi(int(floor(float(gaps.size() - 1) * 0.10)), 0, gaps.size() - 1)
		p10_gap_ms = gaps[p10_index] * 1000.0
	var difficulty_id := str(chart.get("chart_difficulty", chart.get("difficulty", "normal"))).to_lower()
	var difficulty_bonus := 0.25
	match difficulty_id:
		"normal": difficulty_bonus = 0.0
		"hard": difficulty_bonus = 0.60
		"master": difficulty_bonus = 1.20
	var speed_pressure := maxf(0.0, (220.0 - p10_gap_ms) / 35.0)
	var special_pressure := minf(1.4, float(reverse_count) * 0.035)
	var raw_rating := 0.5 + average_nps * 1.10 + float(maxi(0, peak_1s - 3)) * 0.35 + speed_pressure * 0.70 + difficulty_bonus + special_pressure * 0.50
	return clampi(int(floor(raw_rating + 0.5)), 1, 12)
