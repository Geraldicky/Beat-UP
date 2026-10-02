extends SceneTree

const AnalyzerScript = preload("res://scripts/wav_auto_analyzer.gd")

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var analyzer := AnalyzerScript.new()
	var freedom_beats := _grid(111.111, 2.49, 269.54)
	var freedom := analyzer.call("_resolve_tempo_grid_v162", {"bpm": 233.0, "tempo_confidence": 0.328}, freedom_beats, _downbeats(freedom_beats), 111.111, 269.54, "auto", 0.0) as Dictionary
	_check(absf(float(freedom.get("bpm", 0.0)) - 222.222) < 0.02, "Freedom Dive half-time grid was not resolved to 222.22 BPM")
	_check(absf(float(freedom.get("multiplier", 0.0)) - 2.0) < 0.001, "Freedom Dive AUTO mode did not choose 2x")
	_check((freedom.get("beats", []) as Array).size() == freedom_beats.size() * 2 - 1, "Double-time resolution did not rebuild the beat grid")

	var mega_beats := _grid(120.0, 13.37, 160.05)
	var mega := analyzer.call("_resolve_tempo_grid_v162", {"bpm": 120.0, "tempo_confidence": 0.57}, mega_beats, _downbeats(mega_beats), 120.0, 160.05, "auto", 0.0) as Dictionary
	_check(absf(float(mega.get("bpm", 0.0)) - 120.0) < 0.01, "Megalovania should remain 120 BPM")
	_check(absf(float(mega.get("multiplier", 0.0)) - 1.0) < 0.001, "Megalovania AUTO mode incorrectly changed tempo octave")

	var apple_beats := _grid(140.0, 1.41, 324.12)
	var apple := analyzer.call("_resolve_tempo_grid_v162", {"bpm": 138.0, "tempo_confidence": 0.43}, apple_beats, _downbeats(apple_beats), 140.0, 324.12, "auto", 0.0) as Dictionary
	_check(absf(float(apple.get("bpm", 0.0)) - 140.0) < 0.02, "Bad Apple should remain on its original 140 BPM grid")

	var half := analyzer.call("_resolve_tempo_grid_v162", {"bpm": 120.0, "tempo_confidence": 0.6}, mega_beats, _downbeats(mega_beats), 120.0, 160.05, "half", 0.0) as Dictionary
	_check(absf(float(half.get("bpm", 0.0)) - 60.0) < 0.01, "Manual half-time mode failed")
	var double := analyzer.call("_resolve_tempo_grid_v162", {"bpm": 120.0, "tempo_confidence": 0.6}, mega_beats, _downbeats(mega_beats), 120.0, 160.05, "double", 0.0) as Dictionary
	_check(absf(float(double.get("bpm", 0.0)) - 240.0) < 0.01, "Manual double-time mode failed")
	var custom := analyzer.call("_resolve_tempo_grid_v162", {"bpm": 120.0, "tempo_confidence": 0.6}, mega_beats, _downbeats(mega_beats), 120.0, 160.05, "custom", 175.0) as Dictionary
	_check(absf(float(custom.get("bpm", 0.0)) - 175.0) < 0.01, "Custom BPM mode failed")

	if failed:
		quit(1)
	else:
		print("TEMPO OCTAVE V16.2 TEST PASS • Freedom 222.22 • Mega 120 • manual modes synchronized")
		quit(0)

func _grid(bpm: float, offset: float, duration: float) -> Array[float]:
	var values: Array[float] = []
	var cursor := offset
	var step := 60.0 / bpm
	while cursor <= duration:
		values.append(snappedf(cursor, 0.000001))
		cursor += step
	return values

func _downbeats(beats: Array[float]) -> Array[float]:
	var values: Array[float] = []
	for i in range(0, beats.size(), 4):
		values.append(beats[i])
	return values

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
