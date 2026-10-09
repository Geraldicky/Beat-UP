extends RefCounted

# Increment when judgement, direction conversion, or scoring semantics change.
const RULES_VERSION := "beatup_rules_v2"
const LEGACY_RULES_VERSION := "beatup_rules_v1"
const HASH_VERSION := "chart_v1"

static func app_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "unknown"))

static func chart_hash(chart: Dictionary) -> String:
	# Explicit gameplay fields: cosmetics, catalog paths and runtime caches are excluded.
	var payload: Dictionary = {}
	for field: String in ["events", "space_events", "bpm", "duration", "audio", "chart_offset_ms"]:
		payload[field] = chart.get(field, null)
	return (HASH_VERSION + JSON.stringify(_canonical(payload))).sha256_text()

static func _canonical(value: Variant) -> Variant:
	if value is Dictionary:
		var result: Dictionary = {}
		var keys: Array = value.keys()
		keys.sort()
		for canonical_key: Variant in keys:
			if not str(canonical_key).begins_with("_"):
				result[canonical_key] = _canonical(value[canonical_key])
		return result
	if value is Array:
		var result: Array = []
		for item: Variant in value:
			result.append(_canonical(item))
		return result
	return value

static func identity(chart: Dictionary, input_style: String, random_mode: bool, reverse_percent: int = -1) -> Dictionary:
	var result := {
		"song_id": str(chart.get("song_id", chart.get("id", ""))),
		"difficulty": str(chart.get("chart_difficulty", chart.get("difficulty", "normal"))).to_lower(),
		"input_style": input_style,
		"random_mode": random_mode,
		"chart_hash": str(chart["_source_chart_hash"]) if chart.has("_source_chart_hash") else chart_hash(chart),
		"chart_hash_version": HASH_VERSION,
		"rules_version": RULES_VERSION,
		"rules_hash": str(chart["_rules_hash"]) if chart.has("_rules_hash") else rules_hash(),
	}
	var percent := int(chart.get("_reverse_mod_percent", 0)) if reverse_percent < 0 else reverse_percent
	# Unchanged normal-only OFF charts retain their old keys. Authored reverse
	# normalization changes gameplay, so keep historical PBs in their old scope.
	if percent > 0:
		result["reverse_percent"] = percent
	var normalized_authored_reverse := bool(chart.get("_reverse_policy")) if chart.has("_reverse_policy") else preload("res://scripts/reverse_mod.gd").has_authored_reverse(chart)
	if percent > 0 or normalized_authored_reverse:
		result["reverse_version"] = preload("res://scripts/reverse_mod.gd").VERSION
	return result

static func key(chart: Dictionary, input_style: String, random_mode: bool, reverse_percent: int = -1) -> String:
	return "v17441::" + JSON.stringify(identity(chart, input_style, random_mode, reverse_percent)).sha256_text()

static func migrate_legacy(store: Dictionary) -> bool:
	# Preserve old keys and every historical value. Never guess their mode/revision.
	var changed := false
	for old_key: Variant in store.keys():
		if str(old_key).begins_with("v17441::") or not (store[old_key] is Dictionary):
			continue
		var entry: Dictionary = store[old_key]
		if not entry.has("record_scope"):
			entry["record_scope"] = "legacy_unknown_mode_and_revision"
			changed = true
	return changed

static func migrate_v185_score_scale(store: Dictionary, charts: Array, gameplay: Resource = null, result: Resource = null) -> bool:
	# v18.5 raises presentation scores by the configured presentation scale.
	# Preserve each compatible v1 run
	# under the new rules identity instead of making the player's Ranking empty.
	if gameplay == null:
		gameplay = load("res://config/gameplay_config.tres")
	if result == null:
		result = load("res://config/result_config.tres")
	var score_scale: float = maxf(1.0, float(gameplay.get("score_scale_multiplier")))
	var changed := false
	for chart_value: Variant in charts:
		if not (chart_value is Dictionary):
			continue
		var chart: Dictionary = chart_value
		for input_style: String in ["8_direction", "4_arrow"]:
			for random_mode: bool in [false, true]:
				var old_identity := _identity_for_rules(chart, input_style, random_mode, LEGACY_RULES_VERSION, _legacy_v1_rules_hash(gameplay, result))
				var new_identity := _identity_for_rules(chart, input_style, random_mode, RULES_VERSION, rules_hash(gameplay, result))
				var old_key := _key_from_identity(old_identity)
				var new_key := _key_from_identity(new_identity)
				if not store.has(old_key) or store.has(new_key) or not (store[old_key] is Dictionary):
					continue
				var migrated: Dictionary = _scale_score_fields((store[old_key] as Dictionary).duplicate(true), score_scale)
				migrated["identity"] = new_identity.duplicate(true)
				migrated["score_scale_migration"] = score_scale
				var runs_value: Variant = migrated.get("runs", [])
				if runs_value is Array:
					var runs: Array = runs_value
					for index: int in range(runs.size()):
						if runs[index] is Dictionary:
							var run: Dictionary = runs[index]
							run["identity"] = new_identity.duplicate(true)
							run["score_identity"] = new_identity.duplicate(true)
							runs[index] = run
					migrated["runs"] = runs
				store[new_key] = migrated
				changed = true
	return changed

static func _identity_for_rules(chart: Dictionary, input_style: String, random_mode: bool, rules_version: String, resolved_rules_hash: String) -> Dictionary:
	return {
		"song_id": str(chart.get("song_id", chart.get("id", ""))),
		"difficulty": str(chart.get("chart_difficulty", chart.get("difficulty", "normal"))).to_lower(),
		"input_style": input_style,
		"random_mode": random_mode,
		"chart_hash": str(chart["_source_chart_hash"]) if chart.has("_source_chart_hash") else chart_hash(chart),
		"chart_hash_version": HASH_VERSION,
		"rules_version": rules_version,
		"rules_hash": resolved_rules_hash,
	}

static func _key_from_identity(resolved_identity: Dictionary) -> String:
	return "v17441::" + JSON.stringify(resolved_identity).sha256_text()

static func _legacy_v1_rules_hash(gameplay: Resource, result: Resource) -> String:
	var values: Array = [LEGACY_RULES_VERSION]
	for field: String in ["perfect_window", "great_window", "good_window", "space_perfect_window", "space_great_window", "space_good_window", "perfect_score", "great_score", "good_score", "reverse_score_bonus", "space_base_score", "space_perfect_multiplier", "space_great_multiplier", "space_good_multiplier", "combo_thresholds", "combo_multipliers"]:
		values.append(gameplay.get(field))
	for field: String in ["perfect_accuracy_weight", "great_accuracy_weight", "good_accuracy_weight", "miss_accuracy_weight", "ss_accuracy", "s_accuracy", "a_accuracy", "b_accuracy", "c_accuracy"]:
		values.append(result.get(field))
	return JSON.stringify(values).sha256_text()

static func _scale_score_fields(value: Variant, score_scale: float) -> Variant:
	if value is Dictionary:
		var scaled_dictionary: Dictionary = {}
		for field_key: Variant in value.keys():
			var child: Variant = value[field_key]
			if str(field_key) == "score" and (child is int or child is float):
				scaled_dictionary[field_key] = mini(9_999_999, int(round(float(child) * score_scale)))
			else:
				scaled_dictionary[field_key] = _scale_score_fields(child, score_scale)
		return scaled_dictionary
	if value is Array:
		var scaled_array: Array = []
		for child: Variant in value:
			scaled_array.append(_scale_score_fields(child, score_scale))
		return scaled_array
	return value

static func has_legacy(store: Dictionary, song_id: String, difficulty: String, random_mode: bool) -> bool:
	return store.has("%s::%s%s" % [song_id, difficulty.to_lower(), "::random" if random_mode else ""])

static func rules_hash(gameplay: Resource = null, result: Resource = null) -> String:
	if gameplay == null:
		gameplay = load("res://config/gameplay_config.tres")
	if result == null:
		result = load("res://config/result_config.tres")
	var values: Array = [RULES_VERSION]
	for field: String in ["perfect_window", "great_window", "good_window", "space_perfect_window", "space_great_window", "space_good_window", "perfect_score", "great_score", "good_score", "reverse_score_bonus", "space_base_score", "space_perfect_multiplier", "space_great_multiplier", "space_good_multiplier", "score_scale_multiplier", "combo_thresholds", "combo_multipliers"]:
		values.append(gameplay.get(field))
	for field: String in ["perfect_accuracy_weight", "great_accuracy_weight", "good_accuracy_weight", "miss_accuracy_weight", "ss_accuracy", "s_accuracy", "a_accuracy", "b_accuracy", "c_accuracy"]:
		values.append(result.get(field))
	return JSON.stringify(values).sha256_text()
