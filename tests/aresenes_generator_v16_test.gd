extends SceneTree

const AnalyzerScript = preload("res://scripts/wav_auto_analyzer.gd")
const DIFFICULTIES := ["normal", "hard", "master"]

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var analyzer := AnalyzerScript.new()
	var save_generated: bool = "--save" in OS.get_cmdline_user_args()
	var reference: Dictionary = _read_json("res://charts/aresenes_bazaar/normal.json")
	var wav_path := ProjectSettings.globalize_path("res://.test_tmp/aresenes_bazaar.wav")
	var analysis: Dictionary = analyzer.analyze_wav(wav_path)
	_check(bool(analysis.get("ok", false)), "PCM analysis failed: %s" % str(analysis.get("error", "unknown")))
	if failed:
		quit(1)
		return
	var bpm: float = float(reference.get("bpm", 154.0))
	var beat_offset: float = float(reference.get("beat_offset", 0.01))
	var duration: float = float(reference.get("duration", analysis.get("duration", 1.0)))
	var beat: float = 60.0 / bpm
	var beat_times: Array[float] = []
	var cursor: float = beat_offset
	while cursor <= duration + beat:
		beat_times.append(cursor)
		cursor += beat
	analysis["bpm"] = bpm
	analysis["beat_offset"] = beat_offset
	analysis["duration"] = duration
	analysis["active_start"] = 0.0
	analysis["active_end"] = duration
	analysis["beat_times"] = beat_times
	analysis["sections"] = (reference.get("sections", []) as Array).duplicate(true)
	analysis["energy_phrases"] = ((reference.get("energy_map", {}) as Dictionary).get("phrases", []) as Array).duplicate(true)
	analysis["allin1_used"] = true
	analysis["allin1_version"] = "reference-chart"
	analysis["allin1_model"] = "reference-chart"

	var summaries: Dictionary = {}
	for difficulty_id in DIFFICULTIES:
		var base_chart: Dictionary = _read_json("res://charts/aresenes_bazaar/%s.json" % difficulty_id)
		var chart: Dictionary = analyzer.generate_chart(base_chart, analysis, difficulty_id)
		var validation: Dictionary = analyzer.validate_generated_chart(chart)
		_check(bool(validation.get("ok", false)), "%s validation failed: %s" % [difficulty_id, str(validation.get("error", "unknown"))])
		var diagnostics: Dictionary = chart.get("generator_diagnostics", {}) as Dictionary
		var phrase_map: Array = (chart.get("energy_map", {}) as Dictionary).get("phrases", []) as Array
		var intense_interlude: int = _notes_near(phrase_map, 55.0)
		var calmer_chorus: int = _notes_near(phrase_map, 31.0)
		_check(intense_interlude > calmer_chorus, "%s still put fewer notes in the 52-59s peak than the calmer 28-34s chorus (%d <= %d)" % [difficulty_id, intense_interlude, calmer_chorus])
		_check(float(diagnostics.get("density_intensity_correlation", 0.0)) >= 0.55, "%s local-intensity correlation is too weak: %s" % [difficulty_id, str(diagnostics)])
		_check(float(diagnostics.get("peak_to_calm_density_ratio", 0.0)) >= 1.45, "%s peak/calm ratio is too weak: %s" % [difficulty_id, str(diagnostics)])
		summaries[difficulty_id] = {
			"notes": (chart.get("events", []) as Array).size(),
			"onset_share": diagnostics.get("onset_alignment_share", 0.0),
			"correlation": diagnostics.get("density_intensity_correlation", 0.0),
			"peak_calm_ratio": diagnostics.get("peak_to_calm_density_ratio", 0.0),
			"52_59s": intense_interlude,
			"28_34s": calmer_chorus,
		}
		if save_generated:
			_check(_write_json("res://charts/aresenes_bazaar/%s.json" % difficulty_id, chart), "Could not save the %s V16 chart" % difficulty_id)
	if failed:
		quit(1)
		return
	print("ARESENES_GENERATOR_V16_OK %s" % str(summaries))
	quit(0)

func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failed = true
		push_error("Could not open %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		failed = true
		push_error("Invalid JSON: %s" % path)
		return {}
	return parsed as Dictionary

func _notes_near(phrases: Array, midpoint: float) -> int:
	for raw_phrase in phrases:
		var phrase: Dictionary = raw_phrase as Dictionary
		if midpoint >= float(phrase.get("start", 0.0)) and midpoint < float(phrase.get("end", 0.0)):
			return int(phrase.get("generated_note_count", 0))
	return 0

func _write_json(path: String, chart: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(chart, "\t") + "\n")
	file.close()
	return true

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("ARESENES_GENERATOR_V16_TEST: %s" % message)
