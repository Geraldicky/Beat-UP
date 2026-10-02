extends RefCounted
class_name BeatUpPracticeRecords

const ReliableJsonStoreScript = preload("res://scripts/reliable_json_store.gd")
const ScoreIdentity = preload("res://scripts/score_identity.gd")
const SAVE_PATH := "user://practice_records.json"
const SCHEMA_VERSION := 1

static func record(level_data: Dictionary, input_style: String, random_mode: bool, section_index: int, section: Dictionary, result: Dictionary) -> bool:
	var load_result: Dictionary = ReliableJsonStoreScript.load_dictionary(SAVE_PATH)
	var store: Dictionary = {}
	var raw: Variant = load_result.get("data", {})
	if raw is Dictionary:
		store = (raw as Dictionary).duplicate(true)
	var key: String = _key(level_data, input_style, random_mode, section_index)
	var entry: Dictionary = store.get(key, {}) as Dictionary
	var runs: Array = entry.get("runs", []) as Array
	var run: Dictionary = result.duplicate(true)
	run["completed_unix_ms"] = int(round(Time.get_unix_time_from_system() * 1000.0))
	run["section_index"] = section_index
	run["section_role"] = str(section.get("role", section.get("name", "section")))
	run["section_start"] = float(section.get("start", 0.0))
	run["section_end"] = float(section.get("end", 0.0))
	runs.append(run)
	while runs.size() > 30:
		runs.pop_front()
	entry["runs"] = runs
	entry["plays"] = int(entry.get("plays", 0)) + 1
	entry["best_accuracy"] = maxf(float(entry.get("best_accuracy", 0.0)), float(result.get("accuracy", 0.0)))
	entry["best_score"] = maxi(int(entry.get("best_score", 0)), int(result.get("score", 0)))
	entry["score_identity"] = ScoreIdentity.identity(level_data, input_style, random_mode)
	entry["section"] = section.duplicate(true)
	store["schema_version"] = SCHEMA_VERSION
	store[key] = entry
	return ReliableJsonStoreScript.save_dictionary_atomic(SAVE_PATH, store)

static func get_entry(level_data: Dictionary, input_style: String, random_mode: bool, section_index: int) -> Dictionary:
	var load_result: Dictionary = ReliableJsonStoreScript.load_dictionary(SAVE_PATH)
	var raw: Variant = load_result.get("data", {})
	if not (raw is Dictionary):
		return {}
	return ((raw as Dictionary).get(_key(level_data, input_style, random_mode, section_index), {}) as Dictionary).duplicate(true)

static func _key(level_data: Dictionary, input_style: String, random_mode: bool, section_index: int) -> String:
	var identity: Dictionary = ScoreIdentity.identity(level_data, input_style, random_mode)
	return "practice::%s::%d" % [JSON.stringify(identity).sha256_text(), section_index]
