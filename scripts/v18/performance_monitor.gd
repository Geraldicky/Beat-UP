extends Node
class_name BeatUpPerformanceMonitor

const ReliableJsonStoreScript = preload("res://scripts/reliable_json_store.gd")
const REPORT_PATH := "user://performance/v18_performance.json"
const FRAME_SPIKE_THRESHOLD_MS := 25.0
const MAX_SPIKES := 120
const MAX_SPANS := 120
const ROUTE_TRANSITION_BUDGET_MS := 260.0
const PREVIEW_START_BUDGET_MS := 320.0

var _startup_started_ms: int = 0
var _spans_started: Dictionary = {}
var _recent_spans: Array = []
var _frame_spikes: Array = []
var _preview_requested_ms: Dictionary = {}
var _preview_samples: Array = []
var _frame_count: int = 0
var _frame_total_ms: float = 0.0
var _frame_worst_ms: float = 0.0
var _last_flush_ms: int = 0

func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_startup_started_ms = Time.get_ticks_msec()
	_last_flush_ms = _startup_started_ms

func _ready() -> void:
	begin_span("startup_to_first_frame")
	call_deferred("_finish_startup_span")

func _finish_startup_span() -> void:
	end_span("startup_to_first_frame", {"phase": "autoload_ready"})

func _process(delta: float) -> void:
	var frame_ms: float = maxf(0.0, delta * 1000.0)
	_frame_count += 1
	_frame_total_ms += frame_ms
	_frame_worst_ms = maxf(_frame_worst_ms, frame_ms)
	if frame_ms >= FRAME_SPIKE_THRESHOLD_MS:
		_frame_spikes.append({
			"time_ms": Time.get_ticks_msec(),
			"frame_ms": frame_ms,
			"fps": Engine.get_frames_per_second(),
		})
		_trim_array(_frame_spikes, MAX_SPIKES)
	var now_ms: int = Time.get_ticks_msec()
	if now_ms - _last_flush_ms >= 15000:
		flush_report()
		_last_flush_ms = now_ms

func begin_span(span_name: String) -> void:
	if span_name.is_empty():
		return
	_spans_started[span_name] = Time.get_ticks_usec()

func end_span(span_name: String, context: Dictionary = {}) -> float:
	if not _spans_started.has(span_name):
		return -1.0
	var started_us: int = int(_spans_started[span_name])
	_spans_started.erase(span_name)
	var elapsed_ms: float = float(Time.get_ticks_usec() - started_us) / 1000.0
	_recent_spans.append({
		"name": span_name,
		"duration_ms": elapsed_ms,
		"time_ms": Time.get_ticks_msec(),
		"context": context.duplicate(true),
	})
	_trim_array(_recent_spans, MAX_SPANS)
	return elapsed_ms

func mark_preview_requested(audio_path: String) -> void:
	if audio_path.is_empty():
		return
	_preview_requested_ms[audio_path] = Time.get_ticks_usec()

func mark_preview_started(audio_path: String) -> float:
	if audio_path.is_empty() or not _preview_requested_ms.has(audio_path):
		return -1.0
	var started_us: int = int(_preview_requested_ms[audio_path])
	_preview_requested_ms.erase(audio_path)
	var elapsed_ms: float = float(Time.get_ticks_usec() - started_us) / 1000.0
	_preview_samples.append({"audio": audio_path, "latency_ms": elapsed_ms, "time_ms": Time.get_ticks_msec()})
	_trim_array(_preview_samples, 80)
	return elapsed_ms

func snapshot() -> Dictionary:
	var average_frame_ms: float = _frame_total_ms / float(_frame_count) if _frame_count > 0 else 0.0
	var memory_static_bytes: float = Performance.get_monitor(Performance.MEMORY_STATIC)
	return {
		"schema_version": 1,
		"app_version": str(ProjectSettings.get_setting("application/config/version", "unknown")),
		"captured_unix": int(Time.get_unix_time_from_system()),
		"uptime_ms": maxi(0, Time.get_ticks_msec() - _startup_started_ms),
		"frame": {
			"count": _frame_count,
			"average_ms": average_frame_ms,
			"worst_ms": _frame_worst_ms,
			"spike_threshold_ms": FRAME_SPIKE_THRESHOLD_MS,
			"spikes": _frame_spikes.duplicate(true),
		},
		"memory": {
			"static_bytes": memory_static_bytes,
			"static_mb": memory_static_bytes / 1048576.0,
		},
		"spans": _recent_spans.duplicate(true),
		"preview_latency": _preview_samples.duplicate(true),
		"budgets": {
			"route_transition_ms": ROUTE_TRANSITION_BUDGET_MS,
			"preview_start_ms": PREVIEW_START_BUDGET_MS,
			"frame_spike_ms": FRAME_SPIKE_THRESHOLD_MS,
		},
	}

func flush_report() -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://performance"))
	return ReliableJsonStoreScript.save_dictionary_atomic(REPORT_PATH, snapshot())

func _exit_tree() -> void:
	flush_report()

func _trim_array(values: Array, limit: int) -> void:
	while values.size() > limit:
		values.pop_front()
