extends RefCounted
class_name BeatUpProgressInsights

const ReliableJsonStoreScript = preload("res://scripts/reliable_json_store.gd")
const TELEMETRY_INDEX := "user://playtest_data/session_index.json"

static func accuracy_history(record_entry: Dictionary, limit: int = 12) -> PackedFloat32Array:
	var rows: Array = record_entry.get("runs", []).duplicate(true)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("completed_at", 0)) < int(b.get("completed_at", 0))
	)
	var values := PackedFloat32Array()
	var start: int = maxi(0, rows.size() - maxi(1, limit))
	for i: int in range(start, rows.size()):
		values.append(float((rows[i] as Dictionary).get("accuracy", 0.0)))
	return values

static func weak_section(level_data: Dictionary, max_sessions: int = 12) -> Dictionary:
	var song_id: String = str(level_data.get("song_id", level_data.get("id", "")))
	var difficulty: String = str(level_data.get("chart_difficulty", level_data.get("difficulty", "normal"))).to_lower()
	var index_result: Dictionary = ReliableJsonStoreScript.load_dictionary(TELEMETRY_INDEX)
	var index_data: Variant = index_result.get("data", {})
	if not (index_data is Dictionary):
		return {}
	var sessions_value: Variant = (index_data as Dictionary).get("sessions", [])
	if not (sessions_value is Array):
		return {}
	var candidates: Array = []
	for raw: Variant in sessions_value as Array:
		if not (raw is Dictionary):
			continue
		var row: Dictionary = raw as Dictionary
		if str(row.get("song_id", "")) != song_id or str(row.get("difficulty", "")).to_lower() != difficulty:
			continue
		if str(row.get("status", "")) != "completed":
			continue
		candidates.append(row)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("completed_at_unix_ms", 0)) > int(b.get("completed_at_unix_ms", 0))
	)
	if candidates.size() > max_sessions:
		candidates.resize(max_sessions)
	var sections_value: Variant = level_data.get("sections", [])
	if not (sections_value is Array) or (sections_value as Array).is_empty():
		return {}
	var sections: Array = sections_value as Array
	var stats: Array = []
	for i: int in range(sections.size()):
		stats.append({"index": i, "good": 0, "miss": 0, "great": 0, "perfect": 0, "total": 0})
	for row_value: Variant in candidates:
		var row: Dictionary = row_value as Dictionary
		var path: String = str(row.get("path", ""))
		if path.is_empty():
			continue
		var session_result: Dictionary = ReliableJsonStoreScript.load_dictionary(path)
		var session_data: Variant = session_result.get("data", {})
		if not (session_data is Dictionary):
			continue
		var events_value: Variant = (session_data as Dictionary).get("events", [])
		if not (events_value is Array):
			continue
		for event_value: Variant in events_value as Array:
			if not (event_value is Dictionary):
				continue
			var event: Dictionary = event_value as Dictionary
			var t: float = float(event.get("target_time_ms", 0)) / 1000.0
			var section_index: int = _section_index_for_time(sections, t)
			if section_index < 0:
				continue
			var bucket: Dictionary = stats[section_index] as Dictionary
			var judgement: String = str(event.get("judgement", "MISS")).to_lower()
			if bucket.has(judgement):
				bucket[judgement] = int(bucket[judgement]) + 1
			bucket["total"] = int(bucket["total"]) + 1
			stats[section_index] = bucket
	var worst: Dictionary = {}
	var worst_score: float = -1.0
	for i: int in range(stats.size()):
		var bucket: Dictionary = stats[i] as Dictionary
		var total: int = int(bucket.get("total", 0))
		if total <= 0:
			continue
		var bad: int = int(bucket.get("miss", 0)) * 2 + int(bucket.get("good", 0))
		var score: float = float(bad) / float(total)
		if score > worst_score:
			worst_score = score
			worst = bucket.duplicate(true)
			var section: Dictionary = sections[i] as Dictionary
			worst["role"] = str(section.get("role", section.get("name", "section")))
			worst["start"] = float(section.get("start", 0.0))
			worst["end"] = float(section.get("end", 0.0))
			worst["bad_rate"] = score
			worst["sessions"] = candidates.size()
	return worst

static func _section_index_for_time(sections: Array, time_s: float) -> int:
	for i: int in range(sections.size()):
		var raw: Variant = sections[i]
		if not (raw is Dictionary):
			continue
		var section: Dictionary = raw as Dictionary
		var start: float = float(section.get("start", 0.0))
		var end: float = float(section.get("end", start))
		if time_s >= start and time_s <= end:
			return i
	return -1
