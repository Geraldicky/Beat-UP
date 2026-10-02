extends RefCounted
class_name PlayerProfile
const ScoreIdentity = preload("res://scripts/score_identity.gd")

const ReliableJsonStoreScript = preload("res://scripts/reliable_json_store.gd")

const PROFILE_DIR := "user://player_data"
const PROFILE_PATH := "user://player_data/profile.json"
const SCHEMA_VERSION := 1


static func initialize_profile() -> Dictionary:
	_ensure_profile_dir()
	var loaded: Dictionary = ReliableJsonStoreScript.load_dictionary(PROFILE_PATH)
	var raw_data: Variant = loaded.get("data", {})
	var profile: Dictionary = {}
	if raw_data is Dictionary:
		profile = (raw_data as Dictionary).duplicate(true)

	if not _has_valid_player_id(profile):
		profile = _new_profile()
		if not ReliableJsonStoreScript.save_dictionary_atomic(PROFILE_PATH, profile):
			push_error("Beat UP! player profile: failed to create local profile.")
		return profile

	var normalized: Dictionary = _normalize_profile(profile)
	if normalized != profile:
		if not ReliableJsonStoreScript.save_dictionary_atomic(PROFILE_PATH, normalized):
			push_warning("Beat UP! player profile: failed to persist normalized profile.")
	return normalized


static func get_player_id() -> String:
	var profile: Dictionary = initialize_profile()
	return str(profile.get("player_id", ""))


static func record_session(
	session_id: String,
	status: String,
	started_at_unix_ms: int,
	completed_at_unix_ms: int
) -> bool:
	var profile: Dictionary = initialize_profile()
	if not _has_valid_player_id(profile):
		return false

	# The normal telemetry flow finalizes each session once. This guard prevents
	# accidental double-counting if a caller retries the exact same finalize.
	if str(profile.get("last_session_id", "")) == session_id and not session_id.is_empty():
		return true

	var stats: Dictionary = {}
	var raw_stats: Variant = profile.get("stats", {})
	if raw_stats is Dictionary:
		stats = (raw_stats as Dictionary).duplicate(true)

	stats["session_count"] = maxi(0, int(stats.get("session_count", 0))) + 1
	if status == "completed":
		stats["completed_sessions"] = maxi(0, int(stats.get("completed_sessions", 0))) + 1
	else:
		stats["aborted_sessions"] = maxi(0, int(stats.get("aborted_sessions", 0))) + 1

	var duration_ms: int = maxi(0, completed_at_unix_ms - started_at_unix_ms)
	stats["total_session_time_ms"] = maxi(0, int(stats.get("total_session_time_ms", 0))) + duration_ms

	profile["schema_version"] = SCHEMA_VERSION
	profile["app_version"] = ScoreIdentity.app_version()
	profile["last_session_id"] = session_id
	profile["last_session_status"] = status
	profile["last_session_at_unix_ms"] = completed_at_unix_ms
	profile["stats"] = stats
	return ReliableJsonStoreScript.save_dictionary_atomic(PROFILE_PATH, profile)


static func reset_profile() -> Dictionary:
	_ensure_profile_dir()
	_remove_if_exists(PROFILE_PATH)
	_remove_if_exists("%s.bak" % PROFILE_PATH)
	_remove_if_exists("%s.tmp" % PROFILE_PATH)
	_remove_if_exists("%s.corrupt" % PROFILE_PATH)
	var profile: Dictionary = _new_profile()
	if not ReliableJsonStoreScript.save_dictionary_atomic(PROFILE_PATH, profile):
		push_error("Beat UP! player profile: failed to reset local profile.")
	return profile


static func _new_profile() -> Dictionary:
	var now_ms: int = _unix_ms()
	return {
		"schema_version": SCHEMA_VERSION,
		"app_version": ScoreIdentity.app_version(),
		"player_id": _generate_player_id(),
		"created_at_unix_ms": now_ms,
		"last_session_id": "",
		"last_session_status": "",
		"last_session_at_unix_ms": 0,
		"stats": {
			"session_count": 0,
			"completed_sessions": 0,
			"aborted_sessions": 0,
			"total_session_time_ms": 0,
		},
	}


static func _normalize_profile(profile: Dictionary) -> Dictionary:
	var normalized: Dictionary = profile.duplicate(true)
	normalized["schema_version"] = SCHEMA_VERSION
	normalized["app_version"] = ScoreIdentity.app_version()
	normalized["player_id"] = str(profile.get("player_id", ""))
	normalized["created_at_unix_ms"] = maxi(0, int(profile.get("created_at_unix_ms", _unix_ms())))
	normalized["last_session_id"] = str(profile.get("last_session_id", ""))
	normalized["last_session_status"] = str(profile.get("last_session_status", ""))
	normalized["last_session_at_unix_ms"] = maxi(0, int(profile.get("last_session_at_unix_ms", 0)))

	var stats: Dictionary = {}
	var raw_stats: Variant = profile.get("stats", {})
	if raw_stats is Dictionary:
		stats = raw_stats as Dictionary
	normalized["stats"] = {
		"session_count": maxi(0, int(stats.get("session_count", 0))),
		"completed_sessions": maxi(0, int(stats.get("completed_sessions", 0))),
		"aborted_sessions": maxi(0, int(stats.get("aborted_sessions", 0))),
		"total_session_time_ms": maxi(0, int(stats.get("total_session_time_ms", 0))),
	}
	return normalized


static func _has_valid_player_id(profile: Dictionary) -> bool:
	var player_id: String = str(profile.get("player_id", ""))
	if not player_id.begins_with("P-") or player_id.length() != 10:
		return false
	for index in range(2, player_id.length()):
		var character: String = player_id.substr(index, 1)
		if "0123456789ABCDEF".find(character) < 0:
			return false
	return true


static func _generate_player_id() -> String:
	var crypto := Crypto.new()
	var random_bytes: PackedByteArray = crypto.generate_random_bytes(4)
	if random_bytes.size() == 4:
		return "P-%s" % random_bytes.hex_encode().to_upper()

	# Crypto is expected to be available on supported Godot platforms. Keep a
	# non-device-derived fallback so identity never depends on OS/user hardware.
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var fallback_bytes := PackedByteArray()
	for _index in range(4):
		fallback_bytes.append(rng.randi_range(0, 255))
	return "P-%s" % fallback_bytes.hex_encode().to_upper()


static func _ensure_profile_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PROFILE_DIR))


static func _remove_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


static func _unix_ms() -> int:
	return int(round(Time.get_unix_time_from_system() * 1000.0))
