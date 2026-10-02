extends SceneTree

const AnalyzerScript = preload("res://scripts/wav_auto_analyzer.gd")
const DIFFICULTIES := ["normal", "hard", "master"]

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var analyzer := AnalyzerScript.new()
	var analysis: Dictionary = _synthetic_analysis()
	analysis["source_wav"] = "reference.wav"
	analysis["source_audio_name"] = "reference.wav"
	analysis["source_audio_format"] = "wav"
	var counts: Dictionary = {}
	var generated_set: Array = []
	for difficulty_id in DIFFICULTIES:
		var base_chart: Dictionary = {
			"id": "generator_test_%s" % difficulty_id,
			"song_id": "generator_test",
			"title": "GENERATOR TEST",
			"difficulty": difficulty_id.to_upper(),
			"chart_difficulty": difficulty_id,
			"star_rating": 3 if difficulty_id == "normal" else (6 if difficulty_id == "hard" else 9),
			"seed": 42137,
			"events": [],
			"space_events": [],
		}
		var chart: Dictionary = analyzer.generate_chart(base_chart, analysis, difficulty_id)
		generated_set.append(chart)
		var generator_meta: Dictionary = chart.get("generator_meta", {}) as Dictionary
		_check(str(generator_meta.get("code", "")) == "BUP-CG-01870", "%s did not stamp the V18.7 generator code" % difficulty_id)
		_check(str(generator_meta.get("analysis_source_format", "")) == "wav", "%s lost the WAV analysis-source metadata" % difficulty_id)
		var validation: Dictionary = analyzer.validate_generated_chart(chart)
		_check(bool(validation.get("ok", false)), "%s validation: %s" % [difficulty_id, str(validation.get("error", "unknown"))])
		var events: Array = chart.get("events", []) as Array
		counts[difficulty_id] = events.size()
		_check(events.size() >= 24, "%s generated too few notes" % difficulty_id)
		_check(_unique_direction_count(events) >= 7, "%s did not use enough directions" % difficulty_id)
		_check(_largest_ngram_share(events, 3) < 0.09, "%s overused one three-note cell" % difficulty_id)
		_check(_timing_is_on_grid(events, float(analysis["bpm"]), float(analysis["beat_offset"])), "%s timing escaped the onset/grid window" % difficulty_id)
		var diagnostics: Dictionary = chart.get("generator_diagnostics", {}) as Dictionary
		_check(float(diagnostics.get("density_intensity_correlation", 0.0)) >= 0.45, "%s density did not follow local intensity: %s" % [difficulty_id, str(diagnostics)])
		_check(float(diagnostics.get("onset_alignment_share", 0.0)) >= 0.20, "%s selected too few onset-aligned notes: %s" % [difficulty_id, str(diagnostics)])
		if int(diagnostics.get("peak_phrase_count", 0)) > 0 and int(diagnostics.get("calm_phrase_count", 0)) > 0:
			_check(float(diagnostics.get("peak_to_calm_density_ratio", 0.0)) >= 1.35, "%s peak/calm separation is too weak: %s" % [difficulty_id, str(diagnostics)])

	_check(int(counts.get("normal", 0)) < int(counts.get("hard", 0)), "Hard must contain more playable detail than Normal")
	_check(int(counts.get("hard", 0)) < int(counts.get("master", 0)), "Master must contain more playable detail than Hard")
	var quality_gate: Dictionary = analyzer.call("finalize_generated_set", generated_set, analysis)
	_check(bool(quality_gate.get("ok", false)), "V18.7 quality gate rejected a balanced synthetic chart set: %s" % str(quality_gate))
	for raw_chart in generated_set:
		var quality: Dictionary = (raw_chart as Dictionary).get("generation_quality", {}) as Dictionary
		_check(float(quality.get("beat_grid_alignment", 0.0)) >= 0.94, "V18.7 quality gate lost beat alignment: %s" % str(quality))
		_check(bool(quality.get("playability_valid", false)), "V18.7 quality gate accepted an unplayable chart")
	_test_wrong_section_label_override(analyzer)
	_test_legacy_upgrade(analyzer)
	if failed:
		quit(1)
		return
	print("CHART_GENERATOR_V16_OK counts=%s" % str(counts))
	quit(0)

func _test_wrong_section_label_override(analyzer: RefCounted) -> void:
	var analysis: Dictionary = _synthetic_analysis()
	var sections: Array = analysis.get("sections", []) as Array
	for raw_section in sections:
		var section: Dictionary = raw_section as Dictionary
		var role: String = str(section.get("role", ""))
		if role == "verse":
			section["role"] = "chorus"
			section["name"] = "calm_wrong_chorus"
			section["chorus_score"] = 1.0
			section["arrangement_intensity"] = 0.96
		elif role == "chorus":
			section["role"] = "interlude"
			section["name"] = "intense_wrong_interlude"
			section["chorus_score"] = 0.0
			section["arrangement_intensity"] = 0.48
	var chart: Dictionary = analyzer.generate_chart({
		"id": "role_inversion_normal",
		"song_id": "role_inversion",
		"title": "ROLE INVERSION",
		"difficulty": "NORMAL",
		"chart_difficulty": "normal",
		"star_rating": 3,
		"seed": 9713,
		"events": [],
		"space_events": [],
	}, analysis, "normal")
	var phrase_map: Array = (chart.get("energy_map", {}) as Dictionary).get("phrases", []) as Array
	var calm_chorus_density: float = _role_note_density(phrase_map, "chorus")
	var intense_interlude_density: float = _role_note_density(phrase_map, "interlude")
	_check(intense_interlude_density >= calm_chorus_density * 1.25, "A mislabeled calm chorus still overruled an intense interlude: chorus=%.3f interlude=%.3f" % [calm_chorus_density, intense_interlude_density])

func _role_note_density(phrases: Array, role: String) -> float:
	var notes: int = 0
	var beats: int = 0
	for raw_phrase in phrases:
		var phrase: Dictionary = raw_phrase as Dictionary
		if str(phrase.get("role", "")) != role:
			continue
		notes += int(phrase.get("generated_note_count", 0))
		var start_time: float = float(phrase.get("start", 0.0))
		var end_time: float = float(phrase.get("end", start_time))
		beats += maxi(1, int(round((end_time - start_time) * 128.0 / 60.0)))
	return float(notes) / float(maxi(1, beats))

func _synthetic_analysis() -> Dictionary:
	var bpm := 128.0
	var beat := 60.0 / bpm
	var beat_offset := 0.20
	var duration := 66.0
	var hop := 0.02
	var beat_times: Array[float] = []
	var cursor := beat_offset
	while cursor < duration:
		beat_times.append(cursor)
		cursor += beat
	var sample_count := ceili(duration / hop) + 2
	var energy: Array[float] = []
	var onset: Array[float] = []
	var rhythm: Array[float] = []
	var brightness: Array[float] = []
	energy.resize(sample_count)
	onset.resize(sample_count)
	rhythm.resize(sample_count)
	brightness.resize(sample_count)
	for i in range(sample_count):
		energy[i] = 0.22
		onset[i] = 0.015
		rhythm[i] = 0.20
		brightness[i] = 0.35
	for beat_index in range(beat_times.size() - 1):
		var base_time: float = beat_times[beat_index]
		var jitter: float = 0.014 if posmod(beat_index, 3) == 0 else -0.010
		_add_peak(onset, energy, hop, base_time + jitter, 0.96 if posmod(beat_index, 4) == 0 else 0.66)
		if posmod(beat_index, 4) in [1, 3]:
			_add_peak(onset, energy, hop, base_time + beat * 0.5 - jitter * 0.5, 0.70)
		if beat_index >= 64 and beat_index < 112 and posmod(beat_index, 2) == 0:
			_add_peak(onset, energy, hop, base_time + beat * 0.25 + jitter * 0.35, 0.74)
			_add_peak(onset, energy, hop, base_time + beat * 0.75 - jitter * 0.35, 0.68)
	var sections: Array = [
		_section(beat_times, 0, 16, "intro", 0.34),
		_section(beat_times, 16, 48, "verse", 0.54),
		_section(beat_times, 48, 64, "pre_chorus", 0.72),
		_section(beat_times, 64, 112, "chorus", 0.94),
		_section(beat_times, 112, beat_times.size() - 1, "outro", 0.38),
	]
	var phrases: Array = []
	for section in sections:
		var data: Dictionary = section as Dictionary
		phrases.append({
			"start": data["start"],
			"end": data["end"],
			"activity": data["activity"],
			"rhythmic_density": data["activity"],
			"drive_score": data["activity"],
			"chorus_score": 0.96 if data["role"] == "chorus" else 0.08,
			"arrangement_intensity": data["activity"],
		})
	return {
		"ok": true,
		"allin1_used": true,
		"allin1_version": "test",
		"allin1_model": "test",
		"duration": duration,
		"bpm": bpm,
		"beat_offset": beat_offset,
		"tempo_confidence": 1.0,
		"hop_seconds": hop,
		"energy": energy,
		"onset": onset,
		"rhythm": rhythm,
		"brightness": brightness,
		"active_start": beat_offset,
		"active_end": duration - 0.5,
		"beat_times": beat_times,
		"allin1_downbeats": _every_fourth(beat_times),
		"energy_phrases": phrases,
		"sections": sections,
	}

func _section(beat_times: Array[float], start_index: int, end_index: int, role: String, activity: float) -> Dictionary:
	var safe_end: int = mini(end_index, beat_times.size() - 1)
	return {
		"name": role,
		"role": role,
		"start": beat_times[mini(start_index, beat_times.size() - 1)],
		"end": beat_times[safe_end],
		"activity": activity,
		"rhythmic_density": activity,
		"drive_score": activity,
		"chorus_score": 0.96 if role == "chorus" else 0.08,
		"arrangement_intensity": activity,
	}

func _add_peak(onset: Array[float], energy: Array[float], hop: float, time: float, value: float) -> void:
	var index := clampi(roundi(time / hop), 1, onset.size() - 2)
	onset[index - 1] = maxf(onset[index - 1], value * 0.36)
	onset[index] = maxf(onset[index], value)
	onset[index + 1] = maxf(onset[index + 1], value * 0.48)
	energy[index] = maxf(energy[index], value * 0.82)

func _every_fourth(values: Array[float]) -> Array[float]:
	var result: Array[float] = []
	for i in range(0, values.size(), 4):
		result.append(values[i])
	return result

func _unique_direction_count(events: Array) -> int:
	var found: Dictionary = {}
	for raw_event in events:
		found[int((raw_event as Dictionary).get("direction", 0))] = true
	return found.size()

func _largest_ngram_share(events: Array, size: int) -> float:
	if events.size() < size:
		return 0.0
	var counts: Dictionary = {}
	var largest := 0
	for i in range(events.size() - size + 1):
		var parts: PackedStringArray = PackedStringArray()
		for offset in range(size):
			parts.append(str(int((events[i + offset] as Dictionary).get("direction", 0))))
		var key := "-".join(parts)
		counts[key] = int(counts.get(key, 0)) + 1
		largest = maxi(largest, int(counts[key]))
	return float(largest) / float(events.size() - size + 1)

func _timing_is_on_grid(events: Array, bpm: float, beat_offset: float) -> bool:
	var quarter_step := (60.0 / bpm) * 0.25
	for raw_event in events:
		var time := float((raw_event as Dictionary).get("time", 0.0))
		var nearest := beat_offset + roundf((time - beat_offset) / quarter_step) * quarter_step
		if absf(time - nearest) > (60.0 / bpm) * 0.095:
			return false
	return true

func _test_legacy_upgrade(analyzer: RefCounted) -> void:
	var original_types := ["normal", "reverse", "normal", "reverse"]
	var events: Array = []
	for i in range(64):
		events.append({"time": 1.0 + float(i) * 0.25, "type": original_types[posmod(i, original_types.size())]})
	var upgraded: Dictionary = analyzer.call("author_legacy_directions", {
		"id": "legacy_test",
		"song_id": "legacy_test",
		"difficulty": "HARD",
		"chart_difficulty": "hard",
		"bpm": 120.0,
		"beat_offset": 0.0,
		"seed": 77,
		"events": events,
	})
	var upgraded_events: Array = upgraded.get("events", []) as Array
	_check(upgraded_events.size() == events.size(), "Legacy upgrade changed the event count")
	_check(_unique_direction_count(upgraded_events) >= 7, "Legacy upgrade still looks templated")
	for i in range(upgraded_events.size()):
		_check(str((upgraded_events[i] as Dictionary).get("type", "")) == original_types[posmod(i, original_types.size())], "Legacy upgrade changed a special note type")

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("CHART_GENERATOR_V16_TEST: %s" % message)
