extends RefCounted
class_name WavAutoAnalyzer

const ChartIntegrityScript = preload("res://scripts/chart_integrity.gd")

# Local PCM feature analyzer + chart arranger. V16 treats local audio intensity
# as the primary density signal. All-In-One song form now supplies a restrained
# structural bias instead of locking every phrase to a role-wide note quota.

const MIN_BPM := 75.0
const MAX_BPM := 300.0
const ANALYSIS_HOP_FRAMES := 1024
const BAR_BEATS := 4
const PHRASE_BEATS := 16
const ANALYSIS_PART_BEATS := 8

# Machine-readable chart generator identity. Bulk generation uses the integer
# revision for stale/up-to-date checks; bump both values whenever chart output
# rules change. Charts without this metadata are treated as revision 0.
const CHART_GENERATOR_CODE := "BUP-CG-01871"
const CHART_GENERATOR_REVISION := 1871
const CHART_GENERATOR_VERSION := "18.7.0-readability.1"

func get_generator_code() -> String:
	return CHART_GENERATOR_CODE

func get_generator_revision() -> int:
	return CHART_GENERATOR_REVISION

func get_generator_version() -> String:
	return CHART_GENERATOR_VERSION

# Two-finger direction routing with v16.9.1 section-envelope motif bias. Continuous
# phrases still alternate between virtual left/right fingers, but a small song-
# signature motif bank now biases direction choice without overriding the anti-
# repetition guards or forcing a canned pattern on every note.
const TWO_FINGER_LEFT_KEYS := [4, 7, 1, 8, 2]
const TWO_FINGER_RIGHT_KEYS := [6, 9, 3, 8, 2]
const STRICT_LEFT_KEYS := [1, 4, 7]
const STRICT_RIGHT_KEYS := [3, 6, 9]
const VALID_DIRECTION_KEYS := [1, 2, 3, 4, 6, 7, 8, 9]

# Each v16 profile owns its own density, subdivision, speed, and burst limits.
# This makes difficulty a playability contract instead of a raw note multiplier.

func analyze_wav(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		return {"ok": false, "error": "WAV file not found."}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Could not open WAV file."}
	var bytes: PackedByteArray = file.get_buffer(file.get_length())
	file.close()
	if bytes.size() < 44 or _ascii(bytes, 0, 4) != "RIFF" or _ascii(bytes, 8, 4) != "WAVE":
		return {"ok": false, "error": "Only RIFF/WAVE files are supported."}

	var format_code: int = 0
	var channels: int = 0
	var sample_rate: int = 0
	var bits_per_sample: int = 0
	var block_align: int = 0
	var data_offset: int = -1
	var data_size: int = 0
	var cursor: int = 12
	while cursor + 8 <= bytes.size():
		var chunk_id: String = _ascii(bytes, cursor, 4)
		var declared_chunk_size: int = _u32(bytes, cursor + 4)
		var chunk_data: int = cursor + 8
		var chunk_size: int = declared_chunk_size

		# Some FFmpeg/Lavf WAV files use 0xFFFFFFFF as a sentinel when the
		# RIFF/data size was not back-patched after streaming the output. The
		# PCM payload is still valid; in that case the data chunk simply extends
		# to EOF. Clamp oversized chunks instead of rejecting the whole file.
		if declared_chunk_size == 0xFFFFFFFF or chunk_data + chunk_size > bytes.size():
			if chunk_id == "data":
				chunk_size = maxi(0, bytes.size() - chunk_data)
			else:
				break

		if chunk_id == "fmt " and chunk_size >= 16:
			format_code = _u16(bytes, chunk_data)
			channels = _u16(bytes, chunk_data + 2)
			sample_rate = _u32(bytes, chunk_data + 4)
			block_align = _u16(bytes, chunk_data + 12)
			bits_per_sample = _u16(bytes, chunk_data + 14)
		elif chunk_id == "data":
			data_offset = chunk_data
			data_size = chunk_size
			# PCM data is conventionally the final chunk. This also avoids integer
			# overflow/pointless scanning for sentinel-sized FFmpeg WAVs.
			break
		cursor = chunk_data + chunk_size + (chunk_size & 1)

	if format_code != 1:
		return {"ok": false, "error": "Auto analysis currently supports PCM WAV (format 1)."}
	if channels <= 0 or sample_rate <= 0 or block_align <= 0 or data_offset < 0 or data_size <= 0:
		return {"ok": false, "error": "Invalid WAV format/data chunks."}
	if bits_per_sample != 16 and bits_per_sample != 24 and bits_per_sample != 32:
		return {"ok": false, "error": "Supported PCM depths: 16/24/32 bit."}

	var frame_count: int = floori(float(data_size) / float(block_align))
	var duration: float = float(frame_count) / float(sample_rate)
	var envelope: Dictionary = _build_envelope(bytes, data_offset, frame_count, channels, sample_rate, bits_per_sample, block_align)
	var energy: Array[float] = []
	var onset: Array[float] = []
	var tempo_onset: Array[float] = []
	var rhythm: Array[float] = []
	var brightness: Array[float] = []
	var energy_value: Variant = envelope.get("energy", [])
	var onset_value: Variant = envelope.get("onset", [])
	var tempo_onset_value: Variant = envelope.get("tempo_onset", [])
	var rhythm_value: Variant = envelope.get("rhythm", [])
	var brightness_value: Variant = envelope.get("brightness", [])
	if energy_value is Array:
		energy.assign(energy_value)
	if onset_value is Array:
		onset.assign(onset_value)
	if tempo_onset_value is Array:
		tempo_onset.assign(tempo_onset_value)
	if rhythm_value is Array:
		rhythm.assign(rhythm_value)
	if brightness_value is Array:
		brightness.assign(brightness_value)
	var hop_seconds: float = float(envelope.get("hop_seconds", float(ANALYSIS_HOP_FRAMES) / float(sample_rate)))
	if energy.size() < 32 or onset.size() != energy.size() or tempo_onset.size() != energy.size() or rhythm.size() != energy.size() or brightness.size() != energy.size():
		return {"ok": false, "error": "Audio is too short for automatic analysis."}

	var tempo: Dictionary = _estimate_tempo(tempo_onset, hop_seconds)
	if not bool(tempo.get("ok", false)):
		return tempo
	var bpm: float = float(tempo.get("bpm", 120.0))
	var beat_offset: float = float(tempo.get("phase", 0.0))
	var active: Dictionary = _find_active_region(energy, onset, hop_seconds, duration)
	var active_start: float = float(active.get("start", 0.0))
	var active_end: float = float(active.get("end", duration))
	var beat_times: Array[float] = _build_adaptive_beats(tempo_onset, energy, hop_seconds, bpm, beat_offset, duration)
	var energy_phrases: Array = _analyze_energy_phrases(beat_times, energy, onset, rhythm, brightness, hop_seconds, active_start, active_end)
	var sections: Array = _sections_from_energy_phrases(energy_phrases, active_start, active_end, duration)

	return {
		"ok": true,
		"source_wav": path,
		"sample_rate": sample_rate,
		"channels": channels,
		"bits_per_sample": bits_per_sample,
		"duration": duration,
		"bpm": bpm,
		"beat_offset": beat_offset,
		"tempo_confidence": float(tempo.get("confidence", 0.0)),
		"hop_seconds": hop_seconds,
		"energy": energy,
		"onset": onset,
		"tempo_onset": tempo_onset,
		"rhythm": rhythm,
		"brightness": brightness,
		"active_start": active_start,
		"active_end": active_end,
		"beat_times": beat_times,
		"energy_phrases": energy_phrases,
		"sections": sections,
		"analysis_model": "song_form_arranger_v11",
	}


# V13 hybrid analysis: All-In-One-Infer owns musical structure + beat/downbeat
# timing. The local PCM analyzer still owns fine-grained activity/onset features
# used to decide how much detail to place *inside* each functional section.
func apply_allin1_analysis(local_analysis: Dictionary, allin1_result: Dictionary) -> Dictionary:
	if not bool(local_analysis.get("ok", false)):
		return local_analysis
	if not bool(allin1_result.get("ok", false)):
		return {"ok": false, "error": "All-In-One result is not valid: %s" % str(allin1_result.get("error", "unknown error"))}

	var raw_beat_times: Array[float] = _float_array_from_variant(allin1_result.get("beats", []))
	var raw_downbeats: Array[float] = _float_array_from_variant(allin1_result.get("downbeats", []))
	if raw_beat_times.size() < 8:
		return {"ok": false, "error": "All-In-One returned too few beats for chart generation."}
	var reported_bpm: float = float(allin1_result.get("bpm", 0.0))
	var raw_grid_bpm: float = _bpm_from_beat_times_v13(raw_beat_times)
	if raw_grid_bpm <= 1.0:
		raw_grid_bpm = reported_bpm
	if raw_grid_bpm <= 1.0:
		return {"ok": false, "error": "All-In-One did not return a usable BPM."}

	var result: Dictionary = local_analysis.duplicate(true)
	var duration: float = float(result.get("duration", 0.0))
	var tempo_resolution: Dictionary = _resolve_tempo_grid_v162(
		result,
		raw_beat_times,
		raw_downbeats,
		raw_grid_bpm,
		duration,
		str(allin1_result.get("beat_up_tempo_mode", "auto")),
		float(allin1_result.get("beat_up_custom_bpm", 0.0))
	)
	var beat_times: Array[float] = _float_array_from_variant(tempo_resolution.get("beats", raw_beat_times))
	var downbeats: Array[float] = _float_array_from_variant(tempo_resolution.get("downbeats", raw_downbeats))
	var bpm: float = float(tempo_resolution.get("bpm", raw_grid_bpm))
	var active_start: float = float(result.get("active_start", 0.0))
	var active_end: float = float(result.get("active_end", duration))
	var energy: Array[float] = _float_array_from_variant(result.get("energy", []))
	var onset: Array[float] = _float_array_from_variant(result.get("onset", []))
	var rhythm: Array[float] = _float_array_from_variant(result.get("rhythm", []))
	var brightness: Array[float] = _float_array_from_variant(result.get("brightness", []))
	var hop_seconds: float = float(result.get("hop_seconds", 0.02))

	# Recompute local phrase descriptors on the All-In-One beat grid. This keeps
	# onset/energy detail aligned with the model's metrical interpretation.
	var phrases: Array = _analyze_energy_phrases(beat_times, energy, onset, rhythm, brightness, hop_seconds, active_start, active_end)
	var raw_segments_value: Variant = allin1_result.get("segments", [])
	var raw_segments: Array = []
	if raw_segments_value is Array:
		raw_segments = (raw_segments_value as Array).duplicate(true)
	var sections: Array = _sections_from_allin1_v13(raw_segments, beat_times, downbeats, phrases, active_start, active_end, duration, bpm)
	if sections.is_empty():
		return {"ok": false, "error": "All-In-One returned no usable functional sections."}
	_apply_allin1_roles_to_phrases_v13(phrases, sections)

	result["bpm"] = snappedf(bpm, 0.000001)
	result["beat_times"] = beat_times
	result["beat_offset"] = beat_times[0]
	result["energy_phrases"] = phrases
	result["sections"] = sections
	result["section_override"] = sections
	result["analysis_model"] = "allin1_infer_hybrid_v13"
	result["structure_source"] = "all-in-one-infer"
	result["allin1_used"] = true
	result["allin1_version"] = str(allin1_result.get("version", "unknown"))
	result["allin1_model"] = str(allin1_result.get("model", "harmonix-all"))
	result["allin1_device"] = str(allin1_result.get("device", "auto"))
	result["allin1_downbeats"] = downbeats
	result["allin1_beat_positions"] = tempo_resolution.get("beat_positions", [])
	result["allin1_raw_segments"] = raw_segments
	result["tempo_raw_bpm"] = snappedf(raw_grid_bpm, 0.000001)
	result["tempo_reported_bpm"] = snappedf(reported_bpm, 0.000001)
	result["tempo_local_bpm"] = float(tempo_resolution.get("local_bpm", result.get("bpm", 0.0)))
	result["tempo_local_confidence"] = float(tempo_resolution.get("local_confidence", result.get("tempo_confidence", 0.0)))
	result["tempo_multiplier"] = float(tempo_resolution.get("multiplier", 1.0))
	result["tempo_mode"] = str(tempo_resolution.get("mode", "auto"))
	result["tempo_decision"] = str(tempo_resolution.get("decision", "original grid"))
	result["tempo_resolver_version"] = "v16.2"
	return result

func _bpm_from_beat_times_v13(beat_times: Array[float]) -> float:
	var intervals: Array[float] = []
	for i in range(1, beat_times.size()):
		var delta: float = beat_times[i] - beat_times[i - 1]
		if delta > 0.12 and delta < 1.5:
			intervals.append(delta)
	if intervals.is_empty():
		return 0.0
	intervals.sort()
	var median: float = intervals[floori(float(intervals.size()) * 0.5)]
	return 60.0 / maxf(0.001, median)

# V16.2 resolves the common tempo-octave ambiguity without changing a song's
# actual beat phase. All-In-One remains the structural/timing source; the local
# high-range tempo estimate is used only to decide whether that grid represents
# half-time, original-time, or double-time. Manual modes use the same grid
# transformation so the BPM label and every generated note stay synchronized.
func _resolve_tempo_grid_v162(local_analysis: Dictionary, raw_beats: Array[float], raw_downbeats: Array[float], raw_bpm: float, duration: float, requested_mode: String, custom_bpm: float) -> Dictionary:
	var mode: String = requested_mode.to_lower().strip_edges()
	if mode not in ["auto", "half", "original", "double", "custom"]:
		mode = "auto"
	var local_bpm: float = float(local_analysis.get("bpm", 0.0))
	var local_confidence: float = float(local_analysis.get("tempo_confidence", 0.0))
	var multiplier := 1.0
	var decision := "kept original All-In-One grid"
	var target_bpm := raw_bpm

	match mode:
		"half":
			multiplier = 0.5
			decision = "manual half-time grid"
		"original":
			multiplier = 1.0
			decision = "manual original grid"
		"double":
			multiplier = 2.0
			decision = "manual double-time grid"
		"custom":
			target_bpm = clampf(custom_bpm if custom_bpm > 1.0 else raw_bpm, 40.0, MAX_BPM)
			var ratio: float = target_bpm / maxf(1.0, raw_bpm)
			if absf(ratio - 0.5) <= 0.035:
				multiplier = 0.5
			elif absf(ratio - 1.0) <= 0.035:
				multiplier = 1.0
			elif absf(ratio - 2.0) <= 0.07:
				multiplier = 2.0
			else:
				multiplier = ratio
			decision = "custom %.3f BPM grid" % target_bpm
		_:
			multiplier = _auto_tempo_multiplier_v162(raw_bpm, local_bpm, local_confidence)
			target_bpm = raw_bpm * multiplier
			if multiplier > 1.5:
				decision = "AUTO selected double-time from local audio evidence"
			elif multiplier < 0.75:
				decision = "AUTO selected half-time from local audio evidence"
			else:
				decision = "AUTO kept original tempo"

	var beats: Array[float] = []
	if mode == "custom" and absf(multiplier - 0.5) > 0.04 and absf(multiplier - 1.0) > 0.04 and absf(multiplier - 2.0) > 0.08:
		beats = _uniform_tempo_grid_v162(raw_beats[0], target_bpm, duration)
	else:
		beats = _scale_beat_grid_v162(raw_beats, multiplier)
		target_bpm = _bpm_from_beat_times_v13(beats)
	if beats.size() < 8:
		beats = raw_beats.duplicate()
		target_bpm = raw_bpm
		multiplier = 1.0
		decision = "tempo override rejected because it produced too few beats"

	var downbeats: Array[float] = _rebuild_downbeats_v162(beats, raw_downbeats)
	return {
		"bpm": snappedf(target_bpm, 0.000001),
		"beats": beats,
		"downbeats": downbeats,
		"beat_positions": _beat_positions_v162(beats, downbeats),
		"multiplier": snappedf(multiplier, 0.000001),
		"mode": mode,
		"decision": decision,
		"local_bpm": snappedf(local_bpm, 0.000001),
		"local_confidence": snappedf(local_confidence, 0.000001),
	}

func _auto_tempo_multiplier_v162(raw_bpm: float, local_bpm: float, confidence: float) -> float:
	if raw_bpm <= 1.0 or local_bpm <= 1.0 or confidence < 0.18:
		return 1.0
	var double_error: float = absf(local_bpm - raw_bpm * 2.0) / maxf(1.0, raw_bpm * 2.0)
	var original_error: float = absf(local_bpm - raw_bpm) / maxf(1.0, raw_bpm)
	var half_error: float = absf(local_bpm - raw_bpm * 0.5) / maxf(1.0, raw_bpm * 0.5)
	if local_bpm >= raw_bpm * 1.72 and double_error <= 0.08 and double_error + 0.02 < original_error:
		return 2.0
	if local_bpm <= raw_bpm * 0.58 and half_error <= 0.08 and half_error + 0.02 < original_error:
		return 0.5
	return 1.0

func _scale_beat_grid_v162(raw_beats: Array[float], multiplier: float) -> Array[float]:
	var beats: Array[float] = []
	if multiplier > 1.5:
		for i in range(raw_beats.size() - 1):
			var current: float = raw_beats[i]
			var following: float = raw_beats[i + 1]
			beats.append(current)
			beats.append(snappedf((current + following) * 0.5, 0.000001))
		beats.append(raw_beats[raw_beats.size() - 1])
	elif multiplier < 0.75:
		for i in range(0, raw_beats.size(), 2):
			beats.append(raw_beats[i])
	else:
		beats = raw_beats.duplicate()
	return beats

func _uniform_tempo_grid_v162(first_beat: float, bpm: float, duration: float) -> Array[float]:
	var beats: Array[float] = []
	var interval: float = 60.0 / maxf(1.0, bpm)
	var cursor: float = first_beat
	var safe_end: float = maxf(duration, first_beat + interval * 8.0)
	while cursor <= safe_end + 0.000001:
		beats.append(snappedf(cursor, 0.000001))
		cursor += interval
	return beats

func _rebuild_downbeats_v162(beats: Array[float], raw_downbeats: Array[float]) -> Array[float]:
	var downbeats: Array[float] = []
	if beats.is_empty():
		return downbeats
	var anchor_index := 0
	if not raw_downbeats.is_empty():
		anchor_index = _nearest_beat_index_v162(beats, raw_downbeats[0])
	for i in range(anchor_index, beats.size(), BAR_BEATS):
		downbeats.append(beats[i])
	for i in range(anchor_index - BAR_BEATS, -1, -BAR_BEATS):
		downbeats.push_front(beats[i])
	return downbeats

func _beat_positions_v162(beats: Array[float], downbeats: Array[float]) -> Array[int]:
	var positions: Array[int] = []
	if beats.is_empty():
		return positions
	var anchor_index := 0
	if not downbeats.is_empty():
		anchor_index = _nearest_beat_index_v162(beats, downbeats[0])
	for i in range(beats.size()):
		positions.append(posmod(i - anchor_index, BAR_BEATS) + 1)
	return positions

func _nearest_beat_index_v162(beats: Array[float], target: float) -> int:
	var best_index := 0
	var best_distance := INF
	for i in range(beats.size()):
		var distance: float = absf(beats[i] - target)
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index

func _allin1_role_v13(label: String) -> String:
	match label.to_lower().strip_edges():
		"intro":
			return "intro"
		"verse":
			return "verse"
		"chorus":
			return "chorus"
		"bridge":
			return "bridge"
		"outro":
			return "outro"
		"break", "inst", "solo":
			return "interlude"
		_:
			return ""

func _sections_from_allin1_v13(raw_segments: Array, beat_times: Array[float], downbeats: Array[float], phrases: Array, active_start: float, active_end: float, duration: float, bpm: float) -> Array:
	var mapped: Array = []
	for raw_segment in raw_segments:
		if not (raw_segment is Dictionary):
			continue
		var segment: Dictionary = raw_segment as Dictionary
		var raw_label: String = str(segment.get("label", "")).to_lower().strip_edges()
		var role: String = _allin1_role_v13(raw_label)
		if role.is_empty():
			continue
		var start_time: float = clampf(float(segment.get("start", 0.0)), active_start, minf(active_end, duration))
		var end_time: float = clampf(float(segment.get("end", duration)), active_start, minf(active_end, duration))
		if end_time <= start_time + 0.05:
			continue
		if not mapped.is_empty():
			var previous: Dictionary = mapped[mapped.size() - 1] as Dictionary
			if str(previous.get("role", "")) == role and start_time <= float(previous.get("end", start_time)) + 0.20:
				previous["end"] = end_time
				previous["raw_labels"] = str(previous.get("raw_labels", raw_label)) + "+" + raw_label
				continue
		mapped.append({
			"start": snappedf(start_time, 0.000001),
			"end": snappedf(end_time, 0.000001),
			"role": role,
			"raw_label": raw_label,
			"raw_labels": raw_label,
			"source": "allin1_infer_v13",
		})

	# Harmonix functional labels do not contain a dedicated pre-chorus class.
	# Derive one only when a sufficiently long Verse directly feeds a Chorus.
	# The split is snapped to the model's beat/downbeat grid, not arbitrary time.
	var beat: float = 60.0 / maxf(1.0, bpm)
	var with_prechorus: Array = []
	for i in range(mapped.size()):
		var current: Dictionary = (mapped[i] as Dictionary).duplicate(true)
		if i + 1 < mapped.size():
			var next_section: Dictionary = mapped[i + 1] as Dictionary
			if str(current.get("role", "")) == "verse" and str(next_section.get("role", "")) == "chorus":
				var start_time: float = float(current.get("start", 0.0))
				var end_time: float = float(current.get("end", 0.0))
				var beat_count: float = (end_time - start_time) / maxf(0.001, beat)
				if beat_count >= 12.0:
					var pre_beats: int = 8 if beat_count >= 20.0 else 4
					var target: float = end_time - float(pre_beats) * beat
					var split: float = _preferred_structure_boundary_v13(target, beat_times, downbeats, start_time + 8.0 * beat, end_time - 3.0 * beat)
					if split > start_time + 4.0 * beat and end_time - split >= 3.0 * beat:
						var verse_part: Dictionary = current.duplicate(true)
						verse_part["end"] = snappedf(split, 0.000001)
						with_prechorus.append(verse_part)
						var pre_part: Dictionary = current.duplicate(true)
						pre_part["start"] = snappedf(split, 0.000001)
						pre_part["role"] = "pre_chorus"
						pre_part["source"] = "allin1_infer_v13_derived_pre_chorus"
						with_prechorus.append(pre_part)
						continue
		with_prechorus.append(current)

	var result: Array = []
	var role_counts: Dictionary = {}
	for raw_section in with_prechorus:
		var section: Dictionary = raw_section as Dictionary
		var role: String = str(section.get("role", "verse"))
		var start_time: float = float(section.get("start", active_start))
		var end_time: float = float(section.get("end", active_end))
		var local_activity: float = _metric_from_analysis_v10(phrases, "activity", start_time, end_time, 0.5)
		var local_rhythm: float = _metric_from_analysis_v10(phrases, "rhythmic_density", start_time, end_time, local_activity)
		var local_drive: float = _metric_from_analysis_v10(phrases, "drive_score", start_time, end_time, local_activity)
		var base_intensity: float = _role_arrangement_baseline_v13(role)
		var arrangement: float = clampf(base_intensity + (local_drive - 0.5) * 0.18, 0.0, 1.0)
		if role == "chorus":
			arrangement = maxf(arrangement, 0.86)
		elif role == "intro":
			arrangement = minf(arrangement, 0.46)
		elif role == "outro":
			arrangement = minf(arrangement, 0.48)
		var chorus_score: float = 1.0 if role == "chorus" else (0.45 if role == "pre_chorus" else 0.0)
		var occurrence: int = int(role_counts.get(role, 0)) + 1
		role_counts[role] = occurrence
		result.append({
			"name": role if occurrence == 1 else "%s_%d" % [role, occurrence],
			"start": snappedf(start_time, 0.000001),
			"end": snappedf(end_time, 0.000001),
			"intensity": _activity_to_intensity_v10(arrangement),
			"activity": snappedf(local_activity, 0.001),
			"rhythmic_density": snappedf(local_rhythm, 0.001),
			"drive_score": snappedf(local_drive, 0.001),
			"chorus_score": chorus_score,
			"refrain_score": chorus_score,
			"arrangement_intensity": snappedf(arrangement, 0.001),
			"role": role,
			"source": str(section.get("source", "allin1_infer_v13")),
			"allin1_label": str(section.get("raw_label", role)),
		})
	return result

func _apply_allin1_roles_to_phrases_v13(phrases: Array, sections: Array) -> void:
	for raw_phrase in phrases:
		if not (raw_phrase is Dictionary):
			continue
		var phrase: Dictionary = raw_phrase as Dictionary
		var midpoint: float = (float(phrase.get("start", 0.0)) + float(phrase.get("end", 0.0))) * 0.5
		var matched_role: String = "verse"
		for raw_section in sections:
			if not (raw_section is Dictionary):
				continue
			var section: Dictionary = raw_section as Dictionary
			if midpoint >= float(section.get("start", 0.0)) and midpoint < float(section.get("end", 0.0)) + 0.0001:
				matched_role = str(section.get("role", "verse"))
				break
		var drive: float = clampf(float(phrase.get("drive_score", phrase.get("activity", 0.5))), 0.0, 1.0)
		var arrangement: float = clampf(_role_arrangement_baseline_v13(matched_role) + (drive - 0.5) * 0.18, 0.0, 1.0)
		if matched_role == "chorus":
			arrangement = maxf(arrangement, 0.86)
		elif matched_role == "intro":
			arrangement = minf(arrangement, 0.46)
		elif matched_role == "outro":
			arrangement = minf(arrangement, 0.48)
		var chorus_score: float = 1.0 if matched_role == "chorus" else (0.45 if matched_role == "pre_chorus" else 0.0)
		phrase["role"] = matched_role
		phrase["chorus_score"] = chorus_score
		phrase["refrain_score"] = chorus_score
		phrase["arrangement_intensity"] = snappedf(arrangement, 0.001)
		phrase["intensity"] = _activity_to_intensity_v10(arrangement)

func _role_arrangement_baseline_v13(role: String) -> float:
	match role:
		"intro":
			return 0.28
		"verse":
			return 0.50
		"pre_chorus":
			return 0.72
		"chorus":
			return 0.94
		"bridge":
			return 0.58
		"interlude":
			return 0.52
		"outro":
			return 0.30
		_:
			return 0.50

func _preferred_structure_boundary_v13(target: float, beat_times: Array[float], downbeats: Array[float], min_time: float, max_time: float) -> float:
	var best: float = clampf(target, min_time, max_time)
	var best_distance: float = INF
	for raw_time in downbeats:
		var time: float = float(raw_time)
		if time < min_time or time > max_time:
			continue
		var distance: float = absf(time - target)
		if distance < best_distance:
			best = time
			best_distance = distance
	if best_distance < INF:
		return best
	for raw_time in beat_times:
		var time: float = float(raw_time)
		if time < min_time or time > max_time:
			continue
		var distance: float = absf(time - target)
		if distance < best_distance:
			best = time
			best_distance = distance
	return best


func generate_chart(base_chart: Dictionary, analysis: Dictionary, difficulty_id: String) -> Dictionary:
	var chart: Dictionary = base_chart.duplicate(true)
	var using_allin1: bool = bool(analysis.get("allin1_used", false))
	var generator_version: String = "allin1_balanced_arranger_v187" if using_allin1 else "local_balanced_arranger_v187"
	var profile: Dictionary = _difficulty_profile_v10(difficulty_id)
	var bpm: float = float(analysis.get("bpm", 120.0))
	var beat_offset: float = float(analysis.get("beat_offset", 0.0))
	var duration: float = float(analysis.get("duration", chart.get("duration", 1.0)))
	var hop_seconds: float = float(analysis.get("hop_seconds", 0.02))
	var energy: Array[float] = _float_array_from_variant(analysis.get("energy", []))
	var onset: Array[float] = _float_array_from_variant(analysis.get("onset", []))
	var active_start: float = float(analysis.get("active_start", 0.0))
	var active_end: float = float(analysis.get("active_end", duration))
	var beat: float = 60.0 / maxf(1.0, bpm)
	var beat_times: Array[float] = _float_array_from_variant(analysis.get("beat_times", []))
	if beat_times.size() < 8:
		beat_times = _build_fixed_beats(bpm, beat_offset, duration)
	var phase_refinement: Dictionary = _refine_grid_phase_v1691(beat_times, onset, hop_seconds, bpm, active_start, active_end)
	var phase_shift: float = float(phase_refinement.get("shift", 0.0))
	if absf(phase_shift) >= 0.000001:
		for i in range(beat_times.size()):
			beat_times[i] += phase_shift
		beat_offset += phase_shift

	var lead_in_bars: int = int(profile.get("lead_in_bars", 1))
	var nominal_start: float = maxf(active_start, beat_offset + float(lead_in_bars * BAR_BEATS) * beat)
	var playable_start: float = _first_beat_at_or_after(beat_times, nominal_start)
	if playable_start < 0.0:
		playable_start = nominal_start

	var sections: Array = []
	var analyzed_sections: Variant = analysis.get("sections", [])
	if analyzed_sections is Array:
		sections = _sanitize_sections(analyzed_sections as Array, playable_start, active_end, duration)
	if sections.is_empty():
		sections = _fallback_sections(playable_start, active_end, duration)

	var analyzed_phrase_value: Variant = analysis.get("energy_phrases", [])
	var analyzed_phrases: Array = []
	if analyzed_phrase_value is Array:
		analyzed_phrases = (analyzed_phrase_value as Array).duplicate(true)
	var phrases: Array = _build_generation_phrases_v10(sections, analyzed_phrases, beat_times, playable_start, active_end)
	var generation_seed: int = _stable_chart_seed_v15(chart, difficulty_id)
	_prepare_generation_phrases_v16(phrases)
	_prepare_generation_phrases_v169(phrases, difficulty_id, generation_seed)
	_prepare_difficulty_envelope_v1691(phrases, difficulty_id)
	var spaces: Array[float] = _generate_space_events_v10(phrases, beat_times, energy, onset, hop_seconds, bpm, playable_start, active_end, profile)
	var events: Array = _generate_music_events_v16(phrases, beat_times, energy, onset, hop_seconds, bpm, playable_start, active_end, spaces, profile, difficulty_id, generation_seed)
	_assign_musical_directions_v15(events, difficulty_id, bpm, generation_seed)
	# Reverse is a player-selected runtime mod, never a generated difficulty tax.
	var generator_diagnostics: Dictionary = _generator_diagnostics_v16(events, phrases, bpm, profile)
	_strip_generation_fields_v10(events)

	chart["bpm"] = bpm
	chart["beat_offset"] = beat_offset
	chart["duration"] = duration
	chart["events"] = events
	chart["space_events"] = spaces
	chart["sections"] = sections
	chart["runtime_directions"] = false
	chart["authored_directions"] = true
	chart["generator_meta"] = {
		"readability_policy": "optional_reverse_absolute_gap_v1",
		"generated_by": "Beat UP! chart generator",
		"code": CHART_GENERATOR_CODE,
		"revision": CHART_GENERATOR_REVISION,
		"version": CHART_GENERATOR_VERSION,
		"pipeline": generator_version,
		"analysis_source_name": str(analysis.get("source_audio_name", str(analysis.get("source_wav", "")).get_file())),
		"analysis_source_format": str(analysis.get("source_audio_format", str(analysis.get("source_wav", "")).get_extension())).to_lower(),
		"tempo_resolver": str(analysis.get("tempo_resolver_version", "")),
		"tempo_mode": str(analysis.get("tempo_mode", "local")),
		"tempo_multiplier": float(analysis.get("tempo_multiplier", 1.0)),
		"generated_unix": int(Time.get_unix_time_from_system()),
	}
	chart["energy_map"] = {
		"version": generator_version,
		"analysis_part_beats": ANALYSIS_PART_BEATS,
		"generation_phrase_beats": PHRASE_BEATS,
		"section_source": "allin1_song_form_plus_musical_arranger_v169" if using_allin1 else "local_song_form_plus_musical_arranger_v169",
		"form_roles": ["intro", "verse", "pre_chorus", "chorus", "bridge", "interlude", "outro"],
		"priority_rule": "local audio intensity owns density; v16.9 adds phrase arcs, cadential breathing, and recurring song-signature pattern grammar",
		"peak_rule": "local P85 peaks override quiet role labels; local P25 phrases remain restrained even when labeled chorus",
		"dynamic_window_beats": PHRASE_BEATS,
		"phrases": _export_phrase_map_v10(phrases),
	}
	chart["timing_grid"] = {
		"source": "allin1_beat_grid_quantized_v1691" if using_allin1 else "local_beat_grid_quantized_v1691",
		"detected_bpm": bpm,
		"detected_phase": beat_offset,
		"phase_refinement_ms": snappedf(float(phase_refinement.get("shift", 0.0)) * 1000.0, 0.01),
		"phase_score_gain": snappedf(float(phase_refinement.get("gain", 0.0)), 0.0001),
		"raw_bpm": float(analysis.get("tempo_raw_bpm", bpm)),
		"local_bpm": float(analysis.get("tempo_local_bpm", bpm)),
		"local_tempo_confidence": float(analysis.get("tempo_local_confidence", analysis.get("tempo_confidence", 0.0))),
		"tempo_multiplier": float(analysis.get("tempo_multiplier", 1.0)),
		"tempo_mode": str(analysis.get("tempo_mode", "local")),
		"tempo_decision": str(analysis.get("tempo_decision", "local analyzer grid")),
		"tempo_resolver_version": str(analysis.get("tempo_resolver_version", "")),
		"grid_division": int(profile.get("grid_division", 2)),
		"source_wav": str(analysis.get("source_wav", "")),
		"source_format": str(analysis.get("source_audio_format", str(analysis.get("source_wav", "")).get_extension())).to_lower(),
		"tempo_confidence": float(analysis.get("tempo_confidence", 0.0)),
		"lead_in_bars": lead_in_bars,
		"playable_start": snappedf(playable_start, 0.000001),
		"adaptive_beat_tracking": not using_allin1,
		"allin1_structure": using_allin1,
		"allin1_version": str(analysis.get("allin1_version", "")),
		"allin1_model": str(analysis.get("allin1_model", "")),
		"downbeat_count": (_float_array_from_variant(analysis.get("allin1_downbeats", [])).size() if using_allin1 else 0),
		"beat_count": beat_times.size(),
		"density_model": generator_version,
		"timing_precision_version": "v16.9.1",
		"timestamp_policy": "grid_locked_onset_evidence",
		"straight_subdivisions": [1, 2, 4],
		"triplet_support": difficulty_id.to_lower() != "normal",
	}
	chart["special_note_counts"] = {"reverse": _count_event_type_v168(events, "reverse")}
	chart["generator_diagnostics"] = generator_diagnostics
	var old_profile_value: Variant = chart.get("difficulty_profile", {})
	var difficulty_profile: Dictionary = {}
	if old_profile_value is Dictionary:
		difficulty_profile = (old_profile_value as Dictionary).duplicate(true)
	for stale_key in ["reverse_ratio", "reverse_min_gap_beats", "refrain_aware", "recurrence_detection"]:
		difficulty_profile.erase(stale_key)
	difficulty_profile["note_count"] = events.size()
	difficulty_profile["reverse_count"] = _count_event_type_v168(events, "reverse")
	difficulty_profile["space_count"] = spaces.size()
	difficulty_profile["analysis_driven"] = true
	difficulty_profile["song_form_aware"] = true
	difficulty_profile["local_intensity_priority"] = true
	difficulty_profile["chorus_priority"] = false
	difficulty_profile["normal_and_space_only"] = difficulty_id.to_lower() == "normal"
	difficulty_profile["lead_in_bars"] = lead_in_bars
	difficulty_profile["balance_version"] = "v18.7.0"
	difficulty_profile["max_notes_per_second"] = profile.get("max_notes_per_second", 5.0)
	difficulty_profile["max_rapid_run"] = profile.get("max_rapid_run", 8)
	difficulty_profile["minimum_gap_beats"] = profile.get("minimum_gap_beats", 0.5)
	difficulty_profile["section_difficulty_envelope"] = true
	difficulty_profile["grid_locked_timing"] = true
	difficulty_profile["adaptive_triplets"] = difficulty_id.to_lower() != "normal"
	chart["difficulty_profile"] = difficulty_profile
	chart["direction_profile"] = {
		"version": "musical_two_finger_choreography_v1691",
		"virtual_fingers": 2,
		"left_pool": [4, 7, 1, 8, 2],
		"right_pool": [6, 9, 3, 8, 2],
		"shared_center": [2, 8],
		"continuous_flow_gap_beats": _direction_flow_gap_beats_v12(difficulty_id),
		"motif_bank": true,
		"song_specific_seed": generation_seed,
		"music_cues": ["accent_strength", "beat_position", "phrase_role", "rest_boundaries", "phrase_arc", "song_signature"],
		"repetition_guards": ["same_key", "two_key_loop", "three_note_cell", "four_note_block", "global_ngram_frequency", "direction_balance"],
	}
	chart["star_rating"] = ChartIntegrityScript.estimate_star_rating(chart)
	chart["difficulty_rating_meta"] = {
		"version": "16.9.1",
		"model": "density_peak_speed_special_curve_v1691",
		"estimated_stars": int(chart["star_rating"]),
	}
	chart["chart_design"] = {
		"version": generator_version,
		"structure_backend": "all-in-one-infer" if using_allin1 else "local song-form analyzer",
		"principle": "lock note timing to a musical grid, then shape pressure across functional song sections instead of flattening the whole chart",
		"section_rule": "Intro/Verse/Pre-Chorus/Chorus/Bridge/Outro roles receive an occurrence-aware pressure envelope; repeated sections evolve and the detected musical climax owns the highest pressure",
		"density_rule": "local intensity sets the base target; section occurrence, song position, and climax pressure reshape density without forcing a monotonic ramp",
		"note_type_rule": "Reverse frequency scales by difficulty: Normal 6%, Hard 12%, Master 18%; SPACE remains independent.",
		"direction_rule": "two-finger flow is retained but phrase-scoped motif families and a stable per-song signature bias repeated sections toward recognizable choreography",
		"timing_rule": "timestamps stay on straight or evidence-backed triplet beat-grid positions; nearby transients affect candidate confidence/selection but no longer pull final note timestamps off-grid",
		"difficulty_rule": "difficulty changes density, subdivision complexity, pattern pressure, and the strength of section-to-section escalation—not only note count",
	}
	var recommendation_template: String = "%s • %d★ • %d notes • %d SPACE • generator v18.7.0"
	chart["recommended"] = recommendation_template % [
		str(chart.get("difficulty", difficulty_id.to_upper())),
		int(chart.get("star_rating", 1)),
		events.size(),
		spaces.size(),
	]
	return chart



func _prepare_generation_phrases_v169(phrases: Array, difficulty_id: String, generation_seed: int) -> void:
	if phrases.is_empty():
		return
	var signature_pattern_id: int = posmod(generation_seed, 6)
	for i in range(phrases.size()):
		if not (phrases[i] is Dictionary):
			continue
		var phrase: Dictionary = phrases[i] as Dictionary
		var role: String = str(phrase.get("role", "verse"))
		var intensity: float = clampf(float(phrase.get("play_intensity", 0.5)), 0.0, 1.0)
		var previous_intensity: float = intensity
		var next_intensity: float = intensity
		var next_role: String = role
		if i > 0 and phrases[i - 1] is Dictionary:
			previous_intensity = clampf(float((phrases[i - 1] as Dictionary).get("play_intensity", intensity)), 0.0, 1.0)
		if i + 1 < phrases.size() and phrases[i + 1] is Dictionary:
			next_intensity = clampf(float((phrases[i + 1] as Dictionary).get("play_intensity", intensity)), 0.0, 1.0)
			next_role = str((phrases[i + 1] as Dictionary).get("role", role))
		var section_progress: float = clampf(float(phrase.get("section_progress", 0.5)), 0.0, 1.0)
		var density_multiplier: float = 1.0
		var phrase_arc: String = "groove"
		match role:
			"intro":
				density_multiplier = lerpf(0.89, 0.97, section_progress)
				phrase_arc = "breath"
			"verse":
				density_multiplier = lerpf(0.95, 1.00, intensity)
				phrase_arc = "groove"
			"pre_chorus":
				density_multiplier = lerpf(0.96, 1.07, section_progress)
				phrase_arc = "build"
			"chorus":
				density_multiplier = lerpf(1.02, 1.08, intensity)
				phrase_arc = "payoff"
			"bridge":
				density_multiplier = lerpf(0.94, 1.02, intensity)
				phrase_arc = "contrast"
			"interlude":
				density_multiplier = lerpf(0.93, 1.01, intensity)
				phrase_arc = "contrast"
			"outro":
				density_multiplier = lerpf(0.96, 0.84, section_progress)
				phrase_arc = "release"
			_:
				density_multiplier = lerpf(0.95, 1.02, intensity)
		var rise: float = next_intensity - intensity
		var local_peak: bool = intensity > previous_intensity + 0.08 and intensity >= next_intensity - 0.02
		if local_peak:
			density_multiplier += 0.025
		var pre_climax_breath: bool = rise >= 0.19 or (next_role == "chorus" and role != "chorus" and next_intensity >= intensity - 0.03)
		if pre_climax_breath:
			density_multiplier -= 0.025
		if difficulty_id.to_lower() == "normal":
			# Normal exposes the largest dynamic contrast and least subdivision noise.
			density_multiplier = lerpf(1.0, density_multiplier, 1.08)
		phrase["density_multiplier"] = snappedf(clampf(density_multiplier, 0.84, 1.10), 0.001)
		phrase["phrase_arc"] = phrase_arc
		phrase["pre_climax_breath"] = pre_climax_breath
		phrase["signature_pattern_id"] = signature_pattern_id
		phrase["pattern_family"] = _pattern_family_v169(role, phrase_arc, intensity, signature_pattern_id, i, difficulty_id)

func _prepare_difficulty_envelope_v1691(phrases: Array, difficulty_id: String) -> void:
	if phrases.is_empty():
		return
	# Count functional-section occurrences (Chorus 1 -> Chorus 2 -> Final Chorus,
	# Verse 1 -> Verse 2, etc.) from section boundaries, not from individual
	# 16-beat phrases. This lets repeated sections evolve while still allowing a
	# bridge/outro to release pressure instead of enforcing a monotonic ramp.
	var role_totals: Dictionary = {}
	var section_role: Dictionary = {}
	var last_section: int = -999999
	for raw_phrase in phrases:
		if not (raw_phrase is Dictionary):
			continue
		var phrase: Dictionary = raw_phrase as Dictionary
		var section_index: int = int(phrase.get("section_index", 0))
		if section_index == last_section:
			continue
		last_section = section_index
		var role: String = str(phrase.get("role", "verse"))
		section_role[section_index] = role
		role_totals[role] = int(role_totals.get(role, 0)) + 1

	var role_seen: Dictionary = {}
	var section_occurrence: Dictionary = {}
	last_section = -999999
	for raw_phrase in phrases:
		if not (raw_phrase is Dictionary):
			continue
		var phrase: Dictionary = raw_phrase as Dictionary
		var section_index: int = int(phrase.get("section_index", 0))
		if section_index == last_section:
			continue
		last_section = section_index
		var role: String = str(phrase.get("role", "verse"))
		var occurrence: int = int(role_seen.get(role, 0)) + 1
		role_seen[role] = occurrence
		section_occurrence[section_index] = occurrence

	# First locate the musical climax. Audio energy is dominant; functional role
	# and later recurrence are only tie-breakers. The hardest point therefore
	# follows the song rather than blindly forcing the last 10% to be hardest.
	var climax_index: int = 0
	var climax_score: float = -999.0
	for i in range(phrases.size()):
		if not (phrases[i] is Dictionary):
			continue
		var phrase: Dictionary = phrases[i] as Dictionary
		var role: String = str(phrase.get("role", "verse"))
		var base: float = _section_pressure_base_v1691(role)
		var audio: float = clampf(float(phrase.get("play_intensity", 0.5)), 0.0, 1.0)
		var progress: float = float(i) / float(maxi(1, phrases.size() - 1))
		var section_index: int = int(phrase.get("section_index", 0))
		var occ: int = int(section_occurrence.get(section_index, 1))
		var total: int = maxi(1, int(role_totals.get(role, 1)))
		var recurrence: float = float(occ - 1) / float(maxi(1, total - 1)) if total > 1 else 0.0
		var score: float = audio * 0.64 + base * 0.24 + progress * 0.06 + recurrence * (0.08 if role == "chorus" else 0.03)
		if score > climax_score:
			climax_score = score
			climax_index = i

	var difficulty: String = difficulty_id.to_lower()
	for i in range(phrases.size()):
		if not (phrases[i] is Dictionary):
			continue
		var phrase: Dictionary = phrases[i] as Dictionary
		var role: String = str(phrase.get("role", "verse"))
		var section_index: int = int(phrase.get("section_index", 0))
		var occurrence: int = int(section_occurrence.get(section_index, 1))
		var occurrence_count: int = maxi(1, int(role_totals.get(role, 1)))
		var recurrence: float = float(occurrence - 1) / float(maxi(1, occurrence_count - 1)) if occurrence_count > 1 else 0.0
		var progress: float = float(i) / float(maxi(1, phrases.size() - 1))
		var audio: float = clampf(float(phrase.get("play_intensity", 0.5)), 0.0, 1.0)
		var pressure: float = _section_pressure_base_v1691(role) * 0.55 + audio * 0.35 + progress * 0.10
		match role:
			"chorus": pressure += recurrence * 0.10
			"verse": pressure += recurrence * 0.055
			"pre_chorus": pressure += recurrence * 0.065
			"interlude": pressure += recurrence * 0.035
			"bridge": pressure += recurrence * 0.025
		if i == climax_index:
			pressure = 1.0
		elif absi(i - climax_index) == 1:
			pressure = maxf(pressure, 0.88)
		if role == "outro":
			pressure *= lerpf(0.96, 0.72, clampf(float(phrase.get("section_progress", 0.5)), 0.0, 1.0))
		pressure = clampf(pressure, 0.20, 1.0)
		var low: float = 0.88
		var high: float = 1.06
		match difficulty:
			"hard":
				low = 0.86
				high = 1.10
			"master":
				low = 0.84
				high = 1.13
		var curve_multiplier: float = lerpf(low, high, pressure)
		phrase["section_occurrence"] = occurrence
		phrase["section_occurrence_count"] = occurrence_count
		phrase["difficulty_pressure"] = snappedf(pressure, 0.001)
		phrase["difficulty_density_multiplier"] = snappedf(curve_multiplier, 0.001)
		phrase["difficulty_stage"] = _difficulty_stage_v1691(role, pressure, i == climax_index)
		phrase["musical_climax"] = i == climax_index

func _section_pressure_base_v1691(role: String) -> float:
	match role:
		"intro":
			return 0.34
		"verse":
			return 0.50
		"pre_chorus":
			return 0.68
		"chorus":
			return 0.82
		"bridge":
			return 0.63
		"interlude":
			return 0.55
		"outro":
			return 0.39
		_:
			return 0.52

func _difficulty_stage_v1691(role: String, pressure: float, climax: bool) -> String:
	if climax:
		return "climax"
	if role == "intro":
		return "opening"
	if role == "pre_chorus":
		return "build"
	if role == "outro":
		return "release"
	if role == "chorus":
		return "payoff" if pressure < 0.90 else "peak"
	if role == "bridge":
		return "technical"
	return "develop"

func _pattern_family_v169(_role: String, phrase_arc: String, intensity: float, signature_pattern_id: int, phrase_index: int, difficulty_id: String) -> String:
	if phrase_arc == "breath" or intensity < 0.34:
		return "pulse"
	if phrase_arc == "build":
		return "stair"
	if phrase_arc == "release":
		return "pulse"
	if phrase_arc == "contrast":
		return "syncopated" if posmod(signature_pattern_id + phrase_index, 2) == 0 else "orbit"
	if phrase_arc == "payoff":
		var payoff_bank: Array[String] = ["orbit", "cross", "stair", "zigzag", "cross", "orbit"]
		if difficulty_id.to_lower() == "master" and intensity >= 0.80 and posmod(phrase_index + signature_pattern_id, 3) == 0:
			return "burst"
		return payoff_bank[posmod(signature_pattern_id, payoff_bank.size())]
	var groove_bank: Array[String] = ["pulse", "orbit", "stair", "syncopated"]
	return groove_bank[posmod(signature_pattern_id + phrase_index, groove_bank.size())]

func _candidate_suppressed_by_breath_v169(candidate: Dictionary, phrase: Dictionary, profile: Dictionary) -> bool:
	if not bool(phrase.get("pre_climax_breath", false)):
		return false
	var beat_count: float = float(phrase.get("beat_count", PHRASE_BEATS))
	var position: float = float(candidate.get("beat_in_phrase", 0)) + float(candidate.get("fraction", 0.0))
	var rest_beats: float = float(profile.get("pre_climax_rest_beats", 0.5))
	if position < beat_count - rest_beats:
		return false
	# Keep a truly strong terminal accent; remove ordinary tail subdivisions so
	# the next phrase can land with an audible visual reset.
	return not (bool(candidate.get("onset_anchored", false)) and float(candidate.get("onset_strength", 0.0)) >= 0.72 and float(candidate.get("fraction", 0.0)) <= 0.001)

func _pattern_slot_bonus_v169(candidate: Dictionary, phrase: Dictionary, profile: Dictionary, noise_seed: int) -> float:
	var family: String = str(phrase.get("pattern_family", "pulse"))
	var signature_id: int = int(phrase.get("signature_pattern_id", 0))
	var slot: int = posmod(int(candidate.get("slot_key", 0)), BAR_BEATS * 4)
	var bar_index: int = int(candidate.get("bar_index", 0))
	var preferred: Array[int] = _pattern_slots_v169(family, signature_id, bar_index)
	var bonus_scale: float = float(profile.get("pattern_slot_bonus", 0.32))
	if slot in preferred:
		return bonus_scale
	# Do not let pattern grammar overrule a very strong audio transient.
	if bool(candidate.get("onset_anchored", false)) and float(candidate.get("onset_strength", 0.0)) >= 0.66:
		return 0.0
	var noise: float = _deterministic_noise_v15(noise_seed + signature_id * 271, slot + 1, bar_index + 1)
	return -bonus_scale * 0.20 + noise * bonus_scale * 0.10

func _pattern_slots_v169(family: String, signature_id: int, bar_index: int) -> Array[int]:
	var slots: Array[int]
	match family:
		"stair": slots = [0, 2, 6, 8, 10, 14]
		"orbit": slots = [0, 2, 5, 8, 10, 13]
		"cross": slots = [0, 3, 6, 8, 11, 14]
		"zigzag": slots = [0, 2, 7, 8, 10, 15]
		"syncopated": slots = [0, 3, 6, 10, 14]
		"burst": slots = [0, 1, 2, 7, 8, 9, 10, 15]
		_: slots = [0, 4, 8, 12]
	var shift: int = posmod((signature_id + bar_index) * 2, BAR_BEATS * 4)
	var shifted: Array[int] = []
	for raw_slot in slots:
		shifted.append(posmod(raw_slot + shift, BAR_BEATS * 4))
	return shifted

func _direction_pattern_bonus_v169(direction: int, family: String, signature_id: int, beat_in_phrase: int, subdivision: int) -> float:
	# v17.4.5.1: Direction grammar must never force a canned numpad orbit.
	# Earlier ordered banks such as 8-9-6-3-2-1-4-7 could overpower the
	# anti-repetition score and create long clockwise loops. Keep only a
	# light family preference so rhythm placement remains the primary signal.
	var preferred: Array[int]
	match family:
		"cross": preferred = [8, 2, 4, 6]
		"zigzag": preferred = [7, 3, 9, 1]
		"syncopated": preferred = [4, 9, 2, 7]
		"burst": preferred = [8, 6, 1, 9]
		"stair": preferred = [7, 2, 9, 4]
		"orbit": preferred = [8, 3, 4, 9]
		_: preferred = [8, 6, 2, 4]
	var phase := posmod(beat_in_phrase + subdivision + signature_id, preferred.size())
	if direction == preferred[phase]:
		return 0.22
	if preferred.has(direction):
		return 0.08
	return 0.0

func _apply_musical_special_notes_v169(events: Array, spaces: Array[float], phrases: Array, difficulty_id: String, _bpm: float, generation_seed: int) -> void:
	# v17.4: Reverse is the only directional special note. Keep the algorithm
	# deliberately conservative and deterministic so generator support cannot
	# destabilize scene loading or authored chart playback.
	var difficulty: String = difficulty_id.to_lower()
	if events.is_empty() or difficulty not in ["normal", "hard", "master"]:
		return

	var target_ratio: float = 0.06
	var minimum_index_gap: int = 10
	var opening_guard: float = 5.0
	match difficulty:
		"hard":
			target_ratio = 0.12
			minimum_index_gap = 6
			opening_guard = 3.0
		"master":
			target_ratio = 0.18
			minimum_index_gap = 4
			opening_guard = 1.5

	var target_count: int = maxi(1, int(round(float(events.size()) * target_ratio)))
	var chosen_indices: Array[int] = []
	var candidate_indices: Array[int] = []
	var first_time: float = 0.0
	if events[0] is Dictionary:
		first_time = float((events[0] as Dictionary).get("time", 0.0))

	for i in range(events.size()):
		if not (events[i] is Dictionary):
			continue
		var event: Dictionary = events[i] as Dictionary
		var note_type: String = str(event.get("type", "normal"))
		if note_type == "reverse":
			chosen_indices.append(i)
			continue
		if note_type != "normal":
			continue
		var event_time: float = float(event.get("time", 0.0))
		if event_time < first_time + opening_guard:
			continue
		if _special_near_space_v168(event_time, spaces):
			continue
		candidate_indices.append(i)

	var active_gap: int = minimum_index_gap
	while chosen_indices.size() < target_count and not candidate_indices.is_empty():
		var best_candidate_position: int = -1
		var best_candidate_score: float = -1000000.0
		for candidate_position in range(candidate_indices.size()):
			var candidate_index: int = candidate_indices[candidate_position]
			var too_close: bool = false
			for other_index in chosen_indices:
				if absi(candidate_index - other_index) < active_gap:
					too_close = true
					break
			if too_close:
				continue

			var candidate_event: Dictionary = events[candidate_index] as Dictionary
			var strength: float = float(candidate_event.get("_onset_strength", candidate_event.get("_strength", 0.5)))
			var phrase_bonus: float = 0.0
			var phrase_index: int = int(candidate_event.get("_phrase_index", -1))
			if phrase_index >= 0 and phrase_index < phrases.size() and phrases[phrase_index] is Dictionary:
				var phrase: Dictionary = phrases[phrase_index] as Dictionary
				var role: String = str(phrase.get("role", "verse"))
				var arc: String = str(phrase.get("phrase_arc", "groove"))
				var intensity: float = clampf(float(phrase.get("play_intensity", 0.5)), 0.0, 1.0)
				phrase_bonus += intensity * (0.75 if difficulty == "master" else 0.45)
				if role in ["pre_chorus", "chorus"] or arc in ["build", "payoff"]:
					phrase_bonus += 0.45

			var downbeat_bonus: float = 0.0
			if absf(float(candidate_event.get("_fraction", 0.0))) <= 0.001:
				downbeat_bonus = 0.28
			var noise: float = _deterministic_noise_v15(generation_seed + candidate_index * 31, candidate_index + 1, 1740) * 0.34
			var score: float = strength * 1.15 + phrase_bonus + downbeat_bonus + noise
			if score > best_candidate_score:
				best_candidate_score = score
				best_candidate_position = candidate_position

		if best_candidate_position < 0:
			if active_gap <= 2:
				break
			active_gap = maxi(2, active_gap - 2)
			continue

		var selected_index: int = candidate_indices[best_candidate_position]
		(events[selected_index] as Dictionary)["type"] = "reverse"
		chosen_indices.append(selected_index)
		candidate_indices.remove_at(best_candidate_position)

func _mark_phrase_special_v169(events: Array, indices: Array, spaces: Array[float], chosen: Array[float], note_type: String, difficulty: String, noise_seed: int) -> bool:
	var best_index: int = -1
	var best_score: float = -999999.0
	var minimum_context: float = 0.105 if difficulty == "hard" else 0.080
	for raw_index in indices:
		var i: int = int(raw_index)
		if i < 0 or i >= events.size() or not (events[i] is Dictionary):
			continue
		var event: Dictionary = events[i] as Dictionary
		if str(event.get("type", "normal")) != "normal":
			continue
		var time: float = float(event.get("time", 0.0))
		if _special_near_space_v168(time, spaces) or _special_near_chosen_v168(time, chosen):
			continue
		var before: float = 9.0 if i == 0 else time - float((events[i - 1] as Dictionary).get("time", time))
		var after: float = 9.0 if i + 1 >= events.size() else float((events[i + 1] as Dictionary).get("time", time)) - time
		var context_gap: float = minf(before, after)
		if context_gap < minimum_context:
			continue
		var fraction: float = float(event.get("_fraction", 0.0))
		var beat_in_phrase: int = int(event.get("_beat_in_phrase", 0))
		var onset_strength: float = float(event.get("_onset_strength", event.get("_strength", 0.5)))
		var strength: float = float(event.get("_strength", 0.5))
		var score: float = onset_strength * 1.35 + strength * 0.55 + minf(context_gap, 0.45) * 0.65
		if note_type == "reverse":
			if absf(fraction) <= 0.001:
				score += 0.58
			if posmod(beat_in_phrase, BAR_BEATS) == 0:
				score += 0.35
		else:
			# Secondary special accents avoid primary downbeats.
			if fraction > 0.0:
				score += 0.52
			if posmod(beat_in_phrase, BAR_BEATS) == 0 and absf(fraction) <= 0.001:
				score -= 0.75
		score += _deterministic_noise_v15(noise_seed, i + 1, 919) * 0.30
		if score > best_score:
			best_score = score
			best_index = i
	if best_index < 0:
		return false
	var selected: Dictionary = events[best_index] as Dictionary
	selected["type"] = note_type
	chosen.append(float(selected.get("time", 0.0)))
	return true

func _count_event_type_v168(events: Array, note_type: String) -> int:
	var count := 0
	for raw: Variant in events:
		if raw is Dictionary and str((raw as Dictionary).get("type", "normal")) == note_type:
			count += 1
	return count

func _apply_sparse_special_notes_v168(events: Array, spaces: Array[float], difficulty_id: String) -> void:
	var difficulty := difficulty_id.to_lower()
	if events.is_empty() or not ["hard", "master"].has(difficulty):
		return
	var first_time := maxf(10.0, float((events[0] as Dictionary).get("time", 0.0)) + 6.0)
	var last_time := float((events[events.size() - 1] as Dictionary).get("time", 0.0)) - 7.0
	if last_time <= first_time:
		return
	var chosen: Array[float] = []
	var reverse_interval := 20.0 if difficulty == "hard" else 14.0
	var target := first_time
	while target < last_time:
		_mark_special_near_v168(events, spaces, chosen, target, "reverse", difficulty, 2.8)
		target += reverse_interval

func _mark_special_near_v168(events: Array, spaces: Array[float], chosen: Array[float], target: float, note_type: String, difficulty: String, radius: float) -> bool:
	var best_index := -1
	var best_score := INF
	var minimum_context := 0.105 if difficulty == "hard" else 0.080
	for i in range(events.size()):
		var raw: Variant = events[i]
		if not (raw is Dictionary):
			continue
		var event: Dictionary = raw as Dictionary
		if str(event.get("type", "normal")) != "normal":
			continue
		var time := float(event.get("time", 0.0))
		if absf(time - target) > radius or _special_near_space_v168(time, spaces) or _special_near_chosen_v168(time, chosen):
			continue
		var before := 9.0 if i == 0 else time - float((events[i - 1] as Dictionary).get("time", time))
		var after := 9.0 if i + 1 >= events.size() else float((events[i + 1] as Dictionary).get("time", time)) - time
		var context_gap := minf(before, after)
		if context_gap < minimum_context:
			continue
		var score := absf(time - target) - minf(context_gap, 0.5) * 0.55
		if score < best_score:
			best_score = score
			best_index = i
	if best_index < 0:
		return false
	var selected: Dictionary = events[best_index] as Dictionary
	selected["type"] = note_type
	chosen.append(float(selected.get("time", 0.0)))
	return true

func _special_near_space_v168(time: float, spaces: Array[float]) -> bool:
	for space_time in spaces:
		if absf(time - space_time) < 0.55:
			return true
	return false

func _special_near_chosen_v168(time: float, chosen: Array[float]) -> bool:
	for other in chosen:
		if absf(time - other) < 2.25:
			return true
	return false

func validate_generated_chart(chart: Dictionary) -> Dictionary:
	var events_value: Variant = chart.get("events", [])
	if not (events_value is Array):
		return {"ok": false, "error": "Generated chart has no events array."}
	var events: Array = events_value as Array
	var allowed_directions: Array[int] = []
	allowed_directions.assign(VALID_DIRECTION_KEYS)
	var previous_time: float = -999.0
	for i in range(events.size()):
		var raw_event: Variant = events[i]
		if not (raw_event is Dictionary):
			return {"ok": false, "error": "Event %d is not a Dictionary." % i}
		var event: Dictionary = raw_event as Dictionary
		var time: float = float(event.get("time", -1.0))
		if time < 0.0 or time <= previous_time + 0.0000001:
			return {"ok": false, "error": "Event timing is not strictly increasing at index %d." % i}
		var note_type := str(event.get("type", "normal"))
		if not ["normal", "reverse"].has(note_type):
			return {"ok": false, "error": "Unsupported generated note type at index %d." % i}
		var direction: int = int(event.get("direction", 0))
		if direction not in allowed_directions:
			return {"ok": false, "error": "Missing/invalid direction at index %d." % i}
		previous_time = time
	var spaces_value: Variant = chart.get("space_events", [])
	if not (spaces_value is Array):
		return {"ok": false, "error": "Generated chart has no space_events array."}
	var previous_space: float = -999.0
	var spaces: Array = spaces_value as Array
	for raw_space in spaces:
		if not (raw_space is float or raw_space is int):
			return {"ok": false, "error": "SPACE event is not numeric."}
		var space_time: float = float(raw_space)
		if space_time <= previous_space + 0.0000001:
			return {"ok": false, "error": "SPACE timing is not strictly increasing."}
		previous_space = space_time
	var difficulty_id: String = str(chart.get("chart_difficulty", chart.get("difficulty", "normal"))).to_lower()
	var playability_validation: Dictionary = _validate_playability_v15(events, float(chart.get("bpm", 120.0)), difficulty_id)
	if not bool(playability_validation.get("ok", false)):
		return playability_validation
	var direction_validation: Dictionary = _validate_two_finger_flow_v12(events, float(chart.get("bpm", 120.0)), difficulty_id)
	if not bool(direction_validation.get("ok", false)):
		return direction_validation
	return {"ok": true}

func finalize_generated_set(charts: Array, analysis: Dictionary) -> Dictionary:
	# A chart is only complete when the whole difficulty ladder is coherent.
	# This gate is intentionally deterministic and never invents extra notes: it
	# validates timing/playability, normalizes star progression, and records an
	# explainable quality score for review in Chart Studio.
	var by_difficulty: Dictionary = {}
	var reports: Dictionary = {}
	var errors: Array[String] = []
	var beat_times: Array[float] = _float_array_from_variant(analysis.get("beat_times", []))
	for raw_chart in charts:
		if not (raw_chart is Dictionary):
			continue
		var chart: Dictionary = raw_chart as Dictionary
		var difficulty: String = str(chart.get("chart_difficulty", chart.get("difficulty", "normal"))).to_lower()
		by_difficulty[difficulty] = chart
		var validation: Dictionary = validate_generated_chart(chart)
		if not bool(validation.get("ok", false)):
			errors.append("%s: %s" % [difficulty.to_upper(), str(validation.get("error", "validation failed"))])
		var events: Array = chart.get("events", []) as Array
		var diagnostics: Dictionary = chart.get("generator_diagnostics", {}) as Dictionary
		var profile: Dictionary = _difficulty_profile_v10(difficulty)
		var timing_grid: Dictionary = chart.get("timing_grid", {}) as Dictionary
		var phase_shift: float = float(timing_grid.get("phase_refinement_ms", 0.0)) / 1000.0
		var grid_share: float = _analysis_grid_alignment_share_v187(events, beat_times, difficulty, phase_shift)
		var onset_share: float = clampf(float(diagnostics.get("onset_alignment_share", 0.0)), 0.0, 1.0)
		var onset_target: float = maxf(0.01, float(profile.get("onset_priority_share", 0.4)))
		var onset_quality: float = clampf(onset_share / onset_target, 0.0, 1.0)
		var dynamic_quality: float = clampf((float(diagnostics.get("density_intensity_correlation", 0.0)) + 0.10) / 0.70, 0.0, 1.0)
		var diversity_quality: float = clampf(float(diagnostics.get("three_note_cell_diversity", 0.0)) / 0.55, 0.0, 1.0)
		var peak_count: float = float(diagnostics.get("peak_one_second_note_count", 0))
		var peak_cap: float = maxf(1.0, float(profile.get("max_notes_per_second", 5.0)))
		var speed_quality: float = 1.0 if peak_count <= peak_cap + 0.001 else 0.0
		var score: int = clampi(roundi(45.0 * grid_share + 18.0 * onset_quality + 15.0 * dynamic_quality + 10.0 * diversity_quality + 12.0 * speed_quality), 0, 100)
		var report: Dictionary = {
			"version": "18.7.0",
			"score": score,
			"grade": _quality_grade_v187(score),
			"beat_grid_alignment": snappedf(grid_share, 0.001),
			"onset_alignment": snappedf(onset_share, 0.001),
			"intensity_following": snappedf(float(diagnostics.get("density_intensity_correlation", 0.0)), 0.001),
			"pattern_diversity": snappedf(float(diagnostics.get("three_note_cell_diversity", 0.0)), 0.001),
			"peak_nps": int(peak_count),
			"peak_nps_cap": peak_cap,
			"fatigue_window_seconds": 4,
			"fatigue_note_cap": int(profile.get("max_notes_per_4_seconds", 20)),
			"playability_valid": bool(validation.get("ok", false)),
		}
		chart["generation_quality"] = report
		reports[difficulty] = report

	for required in ["normal", "hard", "master"]:
		if not by_difficulty.has(required):
			errors.append("Missing %s chart." % required.to_upper())
	if errors.is_empty():
		var normal: Dictionary = by_difficulty["normal"] as Dictionary
		var hard: Dictionary = by_difficulty["hard"] as Dictionary
		var master: Dictionary = by_difficulty["master"] as Dictionary
		var normal_count: int = (normal.get("events", []) as Array).size()
		var hard_count: int = (hard.get("events", []) as Array).size()
		var master_count: int = (master.get("events", []) as Array).size()
		if normal_count >= hard_count or hard_count >= master_count:
			errors.append("Difficulty density must increase strictly: N=%d, H=%d, M=%d." % [normal_count, hard_count, master_count])
		var normal_stars: int = clampi(int(normal.get("star_rating", 1)), 1, 5)
		var hard_stars: int = clampi(maxi(int(hard.get("star_rating", 2)), normal_stars + 1), 2, 9)
		var master_stars: int = clampi(maxi(int(master.get("star_rating", 3)), hard_stars + 1), 3, 12)
		normal["star_rating"] = normal_stars
		hard["star_rating"] = hard_stars
		master["star_rating"] = master_stars
		var bpm: float = maxf(1.0, float(normal.get("bpm", 120.0)))
		var tolerance: float = 60.0 / bpm * 0.12
		var normal_hard_share: float = _shared_timing_ratio_v187(normal.get("events", []) as Array, hard.get("events", []) as Array, tolerance)
		var hard_master_share: float = _shared_timing_ratio_v187(hard.get("events", []) as Array, master.get("events", []) as Array, tolerance)
		for difficulty in ["normal", "hard", "master"]:
			var report: Dictionary = reports[difficulty] as Dictionary
			report["difficulty_progression_valid"] = true
			report["shared_anchor_ratio"] = snappedf(normal_hard_share if difficulty == "normal" else hard_master_share, 0.001)
			var chart: Dictionary = by_difficulty[difficulty] as Dictionary
			var rating_meta: Dictionary = chart.get("difficulty_rating_meta", {}) as Dictionary
			rating_meta["estimated_stars"] = int(chart.get("star_rating", 1))
			rating_meta["quality_gate"] = "v18.7.0"
			chart["difficulty_rating_meta"] = rating_meta
	return {"ok": errors.is_empty(), "errors": errors, "reports": reports}

func _analysis_grid_alignment_share_v187(events: Array, beat_times: Array[float], difficulty: String, phase_shift: float = 0.0) -> float:
	if events.is_empty() or beat_times.size() < 2:
		return 0.0
	var aligned: int = 0
	var beat_index: int = 0
	var fractions: Array[float] = []
	if difficulty == "normal":
		fractions.assign([0.0, 0.5])
	else:
		fractions.assign([0.0, 0.25, 1.0 / 3.0, 0.5, 2.0 / 3.0, 0.75])
	for raw_event in events:
		var time: float = float((raw_event as Dictionary).get("time", 0.0))
		while beat_index + 1 < beat_times.size() - 1 and beat_times[beat_index + 1] + phase_shift <= time:
			beat_index += 1
		var start: float = beat_times[beat_index] + phase_shift
		var interval: float = maxf(0.000001, beat_times[mini(beat_index + 1, beat_times.size() - 1)] - beat_times[beat_index])
		var best: float = INF
		for fraction in fractions:
			best = minf(best, absf(time - (start + interval * fraction)))
		if best <= minf(0.003, interval * 0.018):
			aligned += 1
	return float(aligned) / float(maxi(1, events.size()))

func _shared_timing_ratio_v187(lower_events: Array, higher_events: Array, tolerance: float) -> float:
	if lower_events.is_empty() or higher_events.is_empty():
		return 0.0
	var matched: int = 0
	var high_index: int = 0
	for raw_lower in lower_events:
		var time: float = float((raw_lower as Dictionary).get("time", 0.0))
		while high_index + 1 < higher_events.size() and float((higher_events[high_index + 1] as Dictionary).get("time", 0.0)) <= time:
			high_index += 1
		var best: float = absf(float((higher_events[high_index] as Dictionary).get("time", 0.0)) - time)
		if high_index + 1 < higher_events.size():
			best = minf(best, absf(float((higher_events[high_index + 1] as Dictionary).get("time", 0.0)) - time))
		if best <= tolerance:
			matched += 1
	return float(matched) / float(maxi(1, lower_events.size()))

func _quality_grade_v187(score: int) -> String:
	if score >= 92:
		return "S"
	if score >= 84:
		return "A"
	if score >= 74:
		return "B"
	if score >= 64:
		return "C"
	return "REVIEW"

func _build_envelope(bytes: PackedByteArray, data_offset: int, frame_count: int, channels: int, sample_rate: int, bits: int, block_align: int) -> Dictionary:
	var hop_frames: int = ANALYSIS_HOP_FRAMES
	var hop_count: int = maxi(1, int(ceil(float(frame_count) / float(hop_frames))))
	var raw_energy: Array[float] = []
	var raw_high_frequency: Array[float] = []
	raw_energy.resize(hop_count)
	raw_high_frequency.resize(hop_count)
	var bytes_per_sample: int = floori(float(bits) / 8.0)
	var sample_stride: int = maxi(1, int(round(float(sample_rate) / 12000.0)))
	var previous_mono: float = 0.0
	var has_previous_mono: bool = false
	for hop_index in range(hop_count):
		var start_frame: int = hop_index * hop_frames
		var end_frame: int = mini(frame_count, start_frame + hop_frames)
		var sum_sq: float = 0.0
		var diff_sum_sq: float = 0.0
		var sample_count: int = 0
		var frame: int = start_frame
		while frame < end_frame:
			var frame_offset: int = data_offset + frame * block_align
			var mono: float = 0.0
			for channel in range(channels):
				var sample_offset: int = frame_offset + channel * bytes_per_sample
				mono += _pcm_sample(bytes, sample_offset, bits)
			mono /= float(channels)
			sum_sq += mono * mono
			if has_previous_mono:
				var delta: float = mono - previous_mono
				diff_sum_sq += delta * delta
			previous_mono = mono
			has_previous_mono = true
			sample_count += 1
			frame += sample_stride
		raw_energy[hop_index] = sqrt(sum_sq / float(maxi(1, sample_count)))
		raw_high_frequency[hop_index] = sqrt(diff_sum_sq / float(maxi(1, sample_count - 1)))

	# Loudness and high-frequency motion are deliberately measured separately.
	# Drum rolls can have almost flat RMS loudness while producing many attacks;
	# the older v3 onset (positive RMS delta only) therefore under-read them.
	var compressed: Array[float] = []
	var compressed_high: Array[float] = []
	compressed.resize(hop_count)
	compressed_high.resize(hop_count)
	for i in range(hop_count):
		compressed[i] = log(1.0 + 24.0 * raw_energy[i])
		compressed_high[i] = log(1.0 + 56.0 * raw_high_frequency[i])
	var smooth: Array[float] = _smooth_curve(compressed, 1)
	var high_smooth: Array[float] = _smooth_curve(compressed_high, 1)

	var energy_attack: Array[float] = []
	var high_attack: Array[float] = []
	var high_flux: Array[float] = []
	energy_attack.resize(hop_count)
	high_attack.resize(hop_count)
	high_flux.resize(hop_count)
	energy_attack[0] = 0.0
	high_attack[0] = 0.0
	high_flux[0] = 0.0
	for i in range(1, hop_count):
		energy_attack[i] = maxf(0.0, smooth[i] - smooth[i - 1])
		high_attack[i] = maxf(0.0, high_smooth[i] - high_smooth[i - 1])
		high_flux[i] = absf(high_smooth[i] - high_smooth[i - 1])

	_normalize_array(smooth)
	_normalize_array(high_smooth)
	_normalize_array(energy_attack)
	_normalize_array(high_attack)
	_normalize_array(high_flux)

	var onset: Array[float] = []
	var tempo_onset: Array[float] = []
	var rhythm: Array[float] = []
	onset.resize(hop_count)
	tempo_onset.resize(hop_count)
	rhythm.resize(hop_count)
	for i in range(hop_count):
		# Attack novelty favors percussive/high-frequency changes while retaining
		# enough RMS attack information for piano, strings and synth transients.
		onset[i] = energy_attack[i] * 0.34 + high_attack[i] * 0.46 + high_flux[i] * 0.20
		# Tempo needs both low-frequency/loudness pulses and crisp percussion.
		# Using RMS attack alone made kick-light electronic and acoustic tracks
		# drift toward half-time even though their hi-hat/snare pulse was clear.
		tempo_onset[i] = energy_attack[i] * 0.42 + high_attack[i] * 0.38 + high_flux[i] * 0.20
		# Rhythm/texture is not itself a note trigger. It is a part-level feature
		# used to distinguish a quiet sustained passage from a dense drum passage.
		rhythm[i] = onset[i] * 0.62 + high_smooth[i] * 0.38
	_normalize_array(onset)
	_normalize_array(tempo_onset)
	_normalize_array(rhythm)
	return {
		"energy": smooth,
		"onset": onset,
		"tempo_onset": tempo_onset,
		"rhythm": rhythm,
		"brightness": high_smooth,
		"hop_seconds": float(hop_frames) / float(sample_rate),
	}

func _smooth_curve(source: Array[float], radius: int) -> Array[float]:
	var result: Array[float] = []
	result.resize(source.size())
	for i in range(source.size()):
		var accum: float = 0.0
		var count: int = 0
		for j in range(maxi(0, i - radius), mini(source.size(), i + radius + 1)):
			accum += source[j]
			count += 1
		result[i] = accum / float(maxi(1, count))
	return result

func _estimate_tempo(onset: Array[float], hop_seconds: float) -> Dictionary:
	var mean: float = _mean(onset)
	var std: float = _stddev(onset, mean)
	var threshold: float = mean + std * 0.42
	var min_peak_steps: int = maxi(1, int(round(0.065 / hop_seconds)))
	var peaks: Array[int] = []
	for i in range(1, onset.size() - 1):
		if onset[i] < threshold or onset[i] < onset[i - 1] or onset[i] <= onset[i + 1]:
			continue
		if peaks.is_empty() or i - peaks[-1] >= min_peak_steps:
			peaks.append(i)
		elif onset[i] > onset[peaks[-1]]:
			peaks[-1] = i
	if peaks.size() < 10:
		return {"ok": false, "error": "Not enough rhythmic transients to estimate BPM."}

	var bpm_scores: Array[float] = []
	bpm_scores.resize(int(MAX_BPM) + 1)
	bpm_scores.fill(0.0)
	for a in range(peaks.size()):
		for b in range(a + 1, mini(peaks.size(), a + 8)):
			var delta: float = float(peaks[b] - peaks[a]) * hop_seconds
			if delta > 2.0:
				break
			if delta < 0.12:
				continue
			var candidate: float = 60.0 / delta
			while candidate < MIN_BPM:
				candidate *= 2.0
			while candidate > MAX_BPM:
				candidate *= 0.5
			if candidate < MIN_BPM or candidate > MAX_BPM:
				continue
			var bin: int = clampi(int(round(candidate)), int(MIN_BPM), int(MAX_BPM))
			var pair_distance: float = float(b - a)
			bpm_scores[bin] += onset[peaks[a]] * onset[peaks[b]] / pow(pair_distance, 0.35)

	var histogram_max: float = 0.0
	for bpm_i in range(int(MIN_BPM), int(MAX_BPM) + 1):
		histogram_max = maxf(histogram_max, bpm_scores[bpm_i])
	if histogram_max <= 0.000001:
		return {"ok": false, "error": "Could not estimate a stable tempo."}

	# Keep several interval-histogram candidates. A single top bin can be a
	# sub-harmonic (e.g. ~100 BPM instead of a real 150 BPM dance pulse).
	var candidate_bins: Array[int] = []
	var scratch: Array[float] = []
	scratch.assign(bpm_scores)
	for _pick in range(7):
		var best_bin: int = int(MIN_BPM)
		var best_bin_score: float = -1.0
		for bpm_i in range(int(MIN_BPM), int(MAX_BPM) + 1):
			if scratch[bpm_i] > best_bin_score:
				best_bin_score = scratch[bpm_i]
				best_bin = bpm_i
		if best_bin_score <= 0.0:
			break
		candidate_bins.append(best_bin)
		for suppress in range(maxi(int(MIN_BPM), best_bin - 3), mini(int(MAX_BPM) + 1, best_bin + 4)):
			scratch[suppress] = 0.0

	var best_bpm: float = 120.0
	var best_phase: float = 0.0
	var best_combined_score: float = -1.0
	for base_bpm in candidate_bins:
		var candidate_bpm: float = float(base_bpm) - 2.5
		while candidate_bpm <= float(base_bpm) + 2.501:
			if candidate_bpm >= MIN_BPM and candidate_bpm <= MAX_BPM:
				var phase_result: Dictionary = _best_phase(onset, hop_seconds, candidate_bpm)
				var phase_score: float = float(phase_result.get("score", 0.0))
				var rounded_bin: int = clampi(int(round(candidate_bpm)), int(MIN_BPM), int(MAX_BPM))
				var local_histogram: float = 0.0
				for nearby in range(maxi(int(MIN_BPM), rounded_bin - 2), mini(int(MAX_BPM) + 1, rounded_bin + 3)):
					local_histogram = maxf(local_histogram, bpm_scores[nearby])
				var histogram_factor: float = local_histogram / histogram_max
				var combined: float = phase_score * (0.80 + histogram_factor * 0.20)
				if combined > best_combined_score:
					best_combined_score = combined
					best_bpm = candidate_bpm
					best_phase = float(phase_result.get("phase", 0.0))
			candidate_bpm += 0.25

	var nearest_integer: float = roundf(best_bpm)
	if absf(best_bpm - nearest_integer) <= 0.36:
		best_bpm = nearest_integer
		var snapped_phase: Dictionary = _best_phase(onset, hop_seconds, best_bpm)
		best_phase = float(snapped_phase.get("phase", best_phase))
		best_combined_score = float(snapped_phase.get("score", best_combined_score))
	var confidence: float = clampf(best_combined_score / 8.0, 0.0, 1.0)
	return {
		"ok": true,
		"bpm": snappedf(best_bpm, 0.01),
		"phase": snappedf(best_phase, 0.000001),
		"confidence": confidence,
	}

func _best_phase(onset: Array[float], hop_seconds: float, bpm: float) -> Dictionary:
	var period: float = 60.0 / maxf(1.0, bpm)
	var best_phase: float = 0.0
	var best_score: float = -1.0
	var phase_steps: int = 48
	var duration: float = float(onset.size() - 1) * hop_seconds
	for phase_index in range(phase_steps):
		var phase: float = period * float(phase_index) / float(phase_steps)
		var raw_score: float = 0.0
		var beat_count: int = 0
		var time: float = phase
		while time < duration:
			var index: int = clampi(int(round(time / hop_seconds)), 0, onset.size() - 1)
			raw_score += onset[index]
			beat_count += 1
			time += period
		var score: float = raw_score / sqrt(float(maxi(1, beat_count)))
		if score > best_score:
			best_score = score
			best_phase = phase
	return {"phase": best_phase, "score": best_score}

func _find_active_region(energy: Array[float], onset: Array[float], hop_seconds: float, duration: float) -> Dictionary:
	var start_index: int = 0
	var end_index: int = energy.size() - 1
	for i in range(energy.size()):
		if energy[i] >= 0.09 or onset[i] >= 0.16:
			start_index = i
			break
	for i in range(energy.size() - 1, -1, -1):
		if energy[i] >= 0.07 or onset[i] >= 0.12:
			end_index = i
			break
	return {
		"start": clampf(float(start_index) * hop_seconds, 0.0, duration),
		"end": clampf(float(end_index) * hop_seconds, 0.0, duration),
	}

func _build_adaptive_beats(onset: Array[float], energy: Array[float], hop_seconds: float, bpm: float, beat_offset: float, duration: float) -> Array[float]:
	var result: Array[float] = []
	var base_period: float = 60.0 / maxf(1.0, bpm)
	var current: float = beat_offset
	while current < 0.0:
		current += base_period
	while current - base_period >= 0.0:
		current -= base_period
	var interval: float = base_period
	var safety: int = 0
	while current < duration and safety < 20000:
		result.append(snappedf(current, 0.000001))
		var predicted: float = current + interval
		if predicted >= duration:
			break
		var search_radius: float = base_period * 0.16
		var start_index: int = clampi(int(floor((predicted - search_radius) / maxf(0.000001, hop_seconds))), 1, maxi(1, onset.size() - 2))
		var end_index: int = clampi(int(ceil((predicted + search_radius) / maxf(0.000001, hop_seconds))), 1, maxi(1, onset.size() - 2))
		var best_time: float = predicted
		var best_score: float = -999.0
		var best_onset: float = 0.0
		for i in range(start_index, end_index + 1):
			var onset_value: float = onset[i]
			if i > 0 and i + 1 < onset.size() and onset_value < onset[i - 1] and onset_value < onset[i + 1]:
				continue
			var candidate_time: float = float(i) * hop_seconds
			var distance_penalty: float = absf(candidate_time - predicted) / maxf(0.000001, search_radius)
			var energy_value: float = energy[i] if i < energy.size() else 0.0
			var score: float = onset_value * 0.82 + energy_value * 0.18 - distance_penalty * 0.24
			if score > best_score:
				best_score = score
				best_time = candidate_time
				best_onset = onset_value
		var next_time: float = predicted
		if best_onset >= 0.12:
			var lock_amount: float = clampf(0.18 + best_onset * 0.36, 0.18, 0.52)
			next_time = lerpf(predicted, best_time, lock_amount)
		var measured_interval: float = next_time - current
		measured_interval = clampf(measured_interval, base_period * 0.82, base_period * 1.16)
		interval = clampf(lerpf(interval, measured_interval, 0.34), base_period * 0.84, base_period * 1.14)
		current += measured_interval
		safety += 1
	return result

func _build_fixed_beats(bpm: float, beat_offset: float, duration: float) -> Array[float]:
	var result: Array[float] = []
	var beat: float = 60.0 / maxf(1.0, bpm)
	var time: float = beat_offset
	while time < 0.0:
		time += beat
	while time - beat >= 0.0:
		time -= beat
	var safety: int = 0
	while time < duration and safety < 20000:
		result.append(snappedf(time, 0.000001))
		time += beat
		safety += 1
	return result



func _analyze_energy_phrases(beat_times: Array[float], energy: Array[float], onset: Array[float], rhythm: Array[float], brightness: Array[float], hop_seconds: float, active_start: float, active_end: float) -> Array:
	var phrases: Array = []
	if beat_times.size() < ANALYSIS_PART_BEATS + 1:
		return phrases
	var first_index: int = _first_beat_index_at_or_after(beat_times, active_start)
	if first_index < 0:
		first_index = 0
	first_index -= posmod(first_index, BAR_BEATS)
	first_index = maxi(0, first_index)
	var cursor: int = first_index
	var raw_activity_values: Array[float] = []
	var raw_rhythm_values: Array[float] = []
	var raw_energy_values: Array[float] = []
	while cursor < beat_times.size() - 1:
		var start_time: float = beat_times[cursor]
		if start_time >= active_end:
			break
		var end_index: int = mini(beat_times.size() - 1, cursor + ANALYSIS_PART_BEATS)
		var end_time: float = minf(active_end, beat_times[end_index])
		var range_start: float = maxf(active_start, start_time)
		if end_time <= range_start + 0.05:
			cursor += ANALYSIS_PART_BEATS
			continue
		var beat_count: int = maxi(1, end_index - cursor)
		var energy_mean: float = _sample_range_mean(energy, hop_seconds, range_start, end_time)
		var onset_mean: float = _sample_range_mean(onset, hop_seconds, range_start, end_time)
		var onset_peak: float = _sample_range_peak(onset, hop_seconds, range_start, end_time)
		var rhythm_mean: float = _sample_range_mean(rhythm, hop_seconds, range_start, end_time)
		var brightness_mean: float = _sample_range_mean(brightness, hop_seconds, range_start, end_time)
		var pulse_count: int = _count_local_peaks_v10(onset, hop_seconds, range_start, end_time)
		var pulses_per_beat: float = float(pulse_count) / float(beat_count)
		var absolute_rhythm_density: float = clampf((pulses_per_beat - 0.45) / 2.20, 0.0, 1.0)
		var raw_activity: float = energy_mean * 0.26 + onset_mean * 0.16 + onset_peak * 0.10 + rhythm_mean * 0.16 + absolute_rhythm_density * 0.32
		phrases.append({
			"start": snappedf(range_start, 0.000001),
			"end": snappedf(end_time, 0.000001),
			"start_beat_index": cursor,
			"end_beat_index": end_index,
			"energy_mean": energy_mean,
			"onset_mean": onset_mean,
			"onset_peak": onset_peak,
			"rhythm_mean": rhythm_mean,
			"brightness_mean": brightness_mean,
			"pulses_per_beat": pulses_per_beat,
			"raw_activity": raw_activity,
			"raw_rhythm_density": absolute_rhythm_density,
			"energy_shape": _range_shape_v10(energy, hop_seconds, range_start, end_time, 8),
			"onset_shape": _range_shape_v10(onset, hop_seconds, range_start, end_time, 8),
			"rhythm_shape": _range_shape_v10(rhythm, hop_seconds, range_start, end_time, 8),
			"brightness_shape": _range_shape_v10(brightness, hop_seconds, range_start, end_time, 8),
		})
		raw_activity_values.append(raw_activity)
		raw_rhythm_values.append(absolute_rhythm_density)
		raw_energy_values.append(energy_mean)
		cursor += ANALYSIS_PART_BEATS
	if phrases.is_empty():
		return phrases

	var activity_low: float = _percentile_v10(raw_activity_values, 0.10)
	var activity_high: float = maxf(activity_low + 0.04, _percentile_v10(raw_activity_values, 0.90))
	var rhythm_low: float = _percentile_v10(raw_rhythm_values, 0.10)
	var rhythm_high: float = maxf(rhythm_low + 0.08, _percentile_v10(raw_rhythm_values, 0.90))
	var energy_low: float = _percentile_v10(raw_energy_values, 0.10)
	var energy_high: float = maxf(energy_low + 0.08, _percentile_v10(raw_energy_values, 0.90))

	var base_activities: Array[float] = []
	for i in range(phrases.size()):
		var phrase: Dictionary = phrases[i] as Dictionary
		var normalized_activity: float = clampf((float(phrase["raw_activity"]) - activity_low) / (activity_high - activity_low), 0.0, 1.0)
		var relative_rhythm: float = clampf((float(phrase["raw_rhythm_density"]) - rhythm_low) / (rhythm_high - rhythm_low), 0.0, 1.0)
		var rhythmic_density: float = clampf(maxf(relative_rhythm * 0.82, float(phrase["raw_rhythm_density"]) * 0.96), 0.0, 1.0)
		var relative_energy: float = clampf((float(phrase["energy_mean"]) - energy_low) / (energy_high - energy_low), 0.0, 1.0)
		var pulse_presence: float = clampf((float(phrase["pulses_per_beat"]) - 0.55) / 1.75, 0.0, 1.0)
		var drive_score: float = clampf(relative_energy * 0.42 + rhythmic_density * 0.38 + pulse_presence * 0.20, 0.0, 1.0)
		var activity: float = clampf(maxf(normalized_activity, maxf(rhythmic_density * 0.86, drive_score * 0.91)), 0.0, 1.0)
		phrase["activity"] = activity
		phrase["rhythmic_density"] = rhythmic_density
		phrase["drive_score"] = drive_score
		phrase["relative_energy"] = relative_energy
		base_activities.append(activity)

	# Only macro-smooth the raw activity. Song-form classification below uses
	# recurrence + relative position + transitions, so one loud drum cell cannot
	# redefine an intro as the gameplay peak.
	for i in range(phrases.size()):
		var smooth_total: float = base_activities[i] * 0.70
		var smooth_weight: float = 0.70
		if i > 0:
			smooth_total += base_activities[i - 1] * 0.15
			smooth_weight += 0.15
		if i + 1 < phrases.size():
			smooth_total += base_activities[i + 1] * 0.15
			smooth_weight += 0.15
		(phrases[i] as Dictionary)["activity"] = clampf(smooth_total / smooth_weight, 0.0, 1.0)

	_apply_song_form_detection_v11(phrases)
	for i in range(phrases.size()):
		var phrase: Dictionary = phrases[i] as Dictionary
		phrase["phrase_index"] = i
		phrase["intensity"] = _activity_to_intensity_v10(float(phrase.get("arrangement_intensity", phrase.get("activity", 0.5))))
		phrase.erase("raw_activity")
		phrase.erase("raw_rhythm_density")
	return phrases

func _apply_song_form_detection_v11(phrases: Array) -> void:
	var total: int = phrases.size()
	if total <= 0:
		return
	for i in range(total):
		var phrase: Dictionary = phrases[i] as Dictionary
		phrase["role"] = "verse"
		phrase["chorus_score"] = 0.0
		phrase["refrain_score"] = 0.0 # legacy alias used by older chart readers
		phrase["repeat_similarity"] = 0.0
		phrase["global_repeat_score"] = 0.0
		phrase["chorus_occurrence"] = 0
		phrase["final_chorus"] = false

	_compute_global_repeat_scores_v11(phrases)
	var chorus_starts: Array[int] = _detect_chorus_occurrences_v11(phrases)
	var block_length: int = 4 if total >= 10 else 2
	block_length = clampi(block_length, 1, maxi(1, total - 2))
	if chorus_starts.is_empty():
		var fallback_start: int = _choose_hook_fallback_v11(phrases, block_length)
		if fallback_start >= 0:
			chorus_starts.append(fallback_start)

	chorus_starts.sort()
	for occurrence_index in range(chorus_starts.size()):
		var chorus_start: int = chorus_starts[occurrence_index]
		_mark_chorus_window_v11(phrases, chorus_start, block_length, occurrence_index + 1, occurrence_index == chorus_starts.size() - 1)

	var first_chorus_start: int = chorus_starts[0] if not chorus_starts.is_empty() else maxi(1, floori(float(total) * 0.35))
	var intro_end: int = _detect_intro_end_v11(phrases, first_chorus_start)
	for i in range(mini(intro_end, total)):
		if str((phrases[i] as Dictionary).get("role", "verse")) != "chorus":
			(phrases[i] as Dictionary)["role"] = "intro"

	var outro_start: int = _detect_outro_start_v11(phrases)
	for i in range(outro_start, total):
		if str((phrases[i] as Dictionary).get("role", "verse")) != "chorus":
			(phrases[i] as Dictionary)["role"] = "outro"

	_mark_pre_chorus_v11(phrases, chorus_starts, block_length, intro_end, outro_start)
	_mark_bridge_and_interlude_v11(phrases, chorus_starts, block_length, intro_end, outro_start)
	_assign_arrangement_intensity_v11(phrases)

func _compute_global_repeat_scores_v11(phrases: Array) -> void:
	var total: int = phrases.size()
	for i in range(total):
		var best: float = 0.0
		var support: int = 0
		for j in range(total):
			if i == j or abs(i - j) < 3:
				continue
			var similarity: float = _phrase_signature_similarity_v10(phrases[i] as Dictionary, phrases[j] as Dictionary)
			if similarity >= 0.58:
				support += 1
			best = maxf(best, similarity)
		var phrase: Dictionary = phrases[i] as Dictionary
		phrase["global_repeat_score"] = snappedf(best, 0.001)
		phrase["repeat_support"] = support

func _detect_chorus_occurrences_v11(phrases: Array) -> Array[int]:
	var result: Array[int] = []
	var total: int = phrases.size()
	if total < 4:
		return result
	var block_length: int = 4 if total >= 10 else 2
	block_length = clampi(block_length, 1, maxi(1, total - 2))
	var earliest_hook_start: int = maxi(1, floori(float(total) * 0.10))
	var pair_candidates: Array = []
	for a_start in range(earliest_hook_start, total - block_length):
		for b_start in range(a_start + block_length + 1, total - block_length + 1):
			if b_start + block_length > total:
				continue
			var similarity: float = _block_similarity_v10(phrases, a_start, b_start, block_length)
			if similarity < 0.50:
				continue
			var a_drive: float = _window_local_drive_v11(phrases, a_start, block_length)
			var b_drive: float = _window_local_drive_v11(phrases, b_start, block_length)
			var average_drive: float = (a_drive + b_drive) * 0.5
			var before_a: float = _window_local_drive_v11(phrases, maxi(0, a_start - 2), mini(2, a_start)) if a_start > 0 else a_drive
			var before_b: float = _window_local_drive_v11(phrases, maxi(0, b_start - 2), mini(2, b_start)) if b_start > 0 else b_drive
			var lift: float = clampf(((a_drive - before_a) + (b_drive - before_b)) * 0.5 + 0.35, 0.0, 1.0)
			var repeat_support: float = (_window_metric_v10(phrases, a_start, block_length, "global_repeat_score", 0.0) + _window_metric_v10(phrases, b_start, block_length, "global_repeat_score", 0.0)) * 0.5
			var score: float = similarity * 0.52 + average_drive * 0.22 + lift * 0.14 + repeat_support * 0.12
			pair_candidates.append({"a": a_start, "b": b_start, "similarity": similarity, "drive": average_drive, "score": score})

	var anchor: int = -1
	var anchor_similarity: float = 0.0
	var anchor_drive: float = 0.0
	if not pair_candidates.is_empty():
		pair_candidates.sort_custom(_sort_score_descending_v10)
		var best: Dictionary = pair_candidates[0] as Dictionary
		if float(best.get("similarity", 0.0)) >= 0.56 and float(best.get("score", 0.0)) >= 0.56:
			anchor = int(best.get("a", -1))
			var paired: int = int(best.get("b", -1))
			anchor_similarity = float(best.get("similarity", 0.0))
			anchor_drive = float(best.get("drive", 0.0))
			if anchor >= 0:
				result.append(anchor)
			if paired >= 0:
				result.append(paired)

	# Find additional appearances of the same hook family. Brightness/timbre is
	# part of the signature in v11, so repeated accompaniment alone is less likely
	# to be mistaken for the chorus.
	if anchor >= 0:
		var similarity_floor: float = maxf(0.56, anchor_similarity - 0.12)
		var occurrence_candidates: Array = []
		for start_index in range(earliest_hook_start, total - block_length + 1):
			if start_index + block_length > total:
				continue
			var separated: bool = true
			for existing in result:
				if abs(start_index - int(existing)) < block_length + 1:
					separated = false
					break
			if not separated:
				continue
			var similarity: float = _block_similarity_v10(phrases, anchor, start_index, block_length)
			if similarity < similarity_floor:
				continue
			var drive: float = _window_local_drive_v11(phrases, start_index, block_length)
			occurrence_candidates.append({"start": start_index, "score": similarity * 0.70 + drive * 0.30})
		occurrence_candidates.sort_custom(_sort_score_descending_v10)
		for raw_occurrence in occurrence_candidates:
			if result.size() >= 4:
				break
			if raw_occurrence is Dictionary:
				var occurrence_start: int = int((raw_occurrence as Dictionary).get("start", -1))
				if occurrence_start >= 0:
					result.append(occurrence_start)

	# Some music is through-composed or has a drop/final refrain whose envelope is
	# not similar enough to the earlier chorus. Treat sustained macro peaks as
	# chorus/hook gameplay peaks too. This prevents a percussion-heavy intro from
	# winning simply because it has more transients while the actual payoff stays easy.
	var peak_candidates: Array = []
	var block_drives: Array[float] = []
	for start_index in range(earliest_hook_start, total - block_length + 1):
		if start_index + block_length > total:
			continue
		var drive: float = _window_local_drive_v11(phrases, start_index, block_length)
		block_drives.append(drive)
		var before_drive: float = _window_local_drive_v11(phrases, maxi(0, start_index - block_length), mini(block_length, start_index)) if start_index > 0 else drive
		var after_start: int = start_index + block_length
		var after_drive: float = _window_local_drive_v11(phrases, after_start, mini(block_length, total - after_start)) if after_start < total else drive
		var peakness: float = clampf(drive - (before_drive + after_drive) * 0.5 + 0.34, 0.0, 1.0)
		var repeat_score: float = _window_metric_v10(phrases, start_index, block_length, "global_repeat_score", 0.0)
		var position: float = float(start_index) / float(maxi(1, total - 1))
		var position_score: float = clampf((position - 0.08) / 0.30, 0.0, 1.0)
		var family_similarity: float = _block_similarity_v10(phrases, anchor, start_index, block_length) if anchor >= 0 else repeat_score
		var score: float = drive * 0.43 + peakness * 0.25 + repeat_score * 0.13 + position_score * 0.09 + family_similarity * 0.10
		peak_candidates.append({"start": start_index, "drive": drive, "family_similarity": family_similarity, "score": score})
	if not peak_candidates.is_empty():
		peak_candidates.sort_custom(_sort_score_descending_v10)
		var drive_threshold: float = _percentile_v10(block_drives, 0.70) if not block_drives.is_empty() else 0.62
		var best_peak_score: float = float((peak_candidates[0] as Dictionary).get("score", 0.0))
		for raw_peak in peak_candidates:
			if result.size() >= 4:
				break
			if not (raw_peak is Dictionary):
				continue
			var peak: Dictionary = raw_peak as Dictionary
			var start_index: int = int(peak.get("start", -1))
			var drive: float = float(peak.get("drive", 0.0))
			var score: float = float(peak.get("score", 0.0))
			var family_similarity: float = float(peak.get("family_similarity", 0.0))
			if start_index < 0 or drive < maxf(0.54, drive_threshold) or score < best_peak_score * 0.82:
				continue
			# When a strong repeated chorus family exists, extra peaks must either be
			# related to it or clearly exceed its drive (typical final chorus/drop).
			if anchor >= 0 and anchor_similarity >= 0.66 and family_similarity < 0.45 and drive < anchor_drive + 0.035:
				continue
			var separated: bool = true
			for existing in result:
				if abs(start_index - int(existing)) < block_length + 1:
					separated = false
					break
			if separated:
				result.append(start_index)

	result.sort()
	return result

func _choose_hook_fallback_v11(phrases: Array, block_length: int) -> int:
	var total: int = phrases.size()
	var best_start: int = -1
	var best_score: float = -1.0
	for start_index in range(1, maxi(2, total - block_length)):
		if start_index + block_length >= total:
			break
		var drive: float = _window_local_drive_v11(phrases, start_index, block_length)
		var repeat_score: float = _window_metric_v10(phrases, start_index, block_length, "global_repeat_score", 0.0)
		var relative_position: float = float(start_index) / float(maxi(1, total - 1))
		var position_score: float = 1.0 - absf(relative_position - 0.58) * 0.55
		var score: float = drive * 0.62 + repeat_score * 0.22 + position_score * 0.16
		if score > best_score:
			best_score = score
			best_start = start_index
	return best_start

func _mark_chorus_window_v11(phrases: Array, start_index: int, block_length: int, occurrence: int, is_final: bool) -> void:
	for offset in range(block_length):
		var index: int = start_index + offset
		if index <= 0 or index >= phrases.size() - 1:
			continue
		var phrase: Dictionary = phrases[index] as Dictionary
		var drive: float = _window_local_drive_v11(phrases, index, 1)
		var repeat_score: float = float(phrase.get("global_repeat_score", 0.0))
		var chorus_score: float = clampf(0.72 + repeat_score * 0.16 + drive * 0.12 + (0.05 if is_final else 0.0), 0.72, 1.0)
		phrase["role"] = "chorus"
		phrase["chorus_score"] = snappedf(chorus_score, 0.001)
		phrase["refrain_score"] = snappedf(chorus_score, 0.001)
		phrase["chorus_occurrence"] = occurrence
		phrase["final_chorus"] = is_final

func _detect_intro_end_v11(phrases: Array, first_chorus_start: int) -> int:
	var total: int = phrases.size()
	if total <= 2:
		return mini(1, total)
	var limit: int = mini(first_chorus_start, mini(3, total - 1))
	if limit <= 1:
		return 1
	var body_values: Array[float] = []
	for i in range(limit, total):
		body_values.append(_window_local_drive_v11(phrases, i, 1))
	var body_median: float = _percentile_v10(body_values, 0.50) if not body_values.is_empty() else 0.55
	var intro_end: int = 1
	for i in range(1, limit):
		var current_drive: float = _window_local_drive_v11(phrases, i, 1)
		var previous_drive: float = _window_local_drive_v11(phrases, i - 1, 1)
		if current_drive >= body_median * 0.82 and current_drive >= previous_drive + 0.05:
			break
		intro_end = i + 1
	return clampi(intro_end, 1, maxi(1, first_chorus_start))

func _detect_outro_start_v11(phrases: Array) -> int:
	var total: int = phrases.size()
	if total <= 2:
		return maxi(0, total - 1)
	var start: int = total - 1
	var last_drive: float = _window_local_drive_v11(phrases, total - 1, 1)
	var previous_drive: float = _window_local_drive_v11(phrases, total - 2, 1)
	if last_drive <= previous_drive * 0.82 or last_drive <= 0.36:
		start = total - 1
		if total >= 3:
			var before_previous: float = _window_local_drive_v11(phrases, total - 3, 1)
			if previous_drive <= before_previous * 0.82 and previous_drive <= 0.48:
				start = total - 2
	return clampi(start, 1, total - 1)

func _mark_pre_chorus_v11(phrases: Array, chorus_starts: Array[int], block_length: int, intro_end: int, outro_start: int) -> void:
	for chorus_start in chorus_starts:
		if chorus_start <= intro_end or chorus_start >= outro_start:
			continue
		var chorus_drive: float = _window_local_drive_v11(phrases, chorus_start, mini(block_length, 2))
		var last_index: int = chorus_start - 1
		if last_index < intro_end:
			continue
		var last_phrase: Dictionary = phrases[last_index] as Dictionary
		if str(last_phrase.get("role", "verse")) == "chorus":
			continue
		var last_drive: float = _window_local_drive_v11(phrases, last_index, 1)
		var earlier_drive: float = _window_local_drive_v11(phrases, maxi(intro_end, last_index - 1), 1)
		var has_lift: bool = chorus_drive >= last_drive + 0.035 or last_drive >= earlier_drive + 0.07
		if has_lift:
			last_phrase["role"] = "pre_chorus"
			last_phrase["pre_chorus_progress"] = 1.0
			var second_index: int = last_index - 1
			if second_index >= intro_end:
				var second_phrase: Dictionary = phrases[second_index] as Dictionary
				var second_drive: float = _window_local_drive_v11(phrases, second_index, 1)
				if str(second_phrase.get("role", "verse")) == "verse" and last_drive >= second_drive - 0.03 and chorus_drive >= second_drive + 0.06:
					second_phrase["role"] = "pre_chorus"
					second_phrase["pre_chorus_progress"] = 0.35

func _mark_bridge_and_interlude_v11(phrases: Array, chorus_starts: Array[int], block_length: int, intro_end: int, outro_start: int) -> void:
	var total: int = phrases.size()
	# A bridge is a unique contrast after a chorus and before a later chorus. We
	# prefer the later half of the arrangement so ordinary Verse 2 is not mislabeled.
	if chorus_starts.size() >= 2:
		var best_bridge_index: int = -1
		var best_bridge_score: float = 0.0
		for i in range(intro_end, outro_start):
			var phrase: Dictionary = phrases[i] as Dictionary
			if str(phrase.get("role", "verse")) != "verse":
				continue
			var has_chorus_before: bool = false
			var has_chorus_after: bool = false
			for chorus_start in chorus_starts:
				if chorus_start + block_length <= i:
					has_chorus_before = true
				if chorus_start > i:
					has_chorus_after = true
			if not has_chorus_before or not has_chorus_after:
				continue
			var position: float = float(i) / float(maxi(1, total - 1))
			if position < 0.45:
				continue
			var repeat_score: float = float(phrase.get("global_repeat_score", 0.0))
			var drive: float = _window_local_drive_v11(phrases, i, 1)
			var previous_drive: float = _window_local_drive_v11(phrases, maxi(0, i - 1), 1)
			var next_drive: float = _window_local_drive_v11(phrases, mini(total - 1, i + 1), 1)
			var contrast: float = absf(drive - (previous_drive + next_drive) * 0.5)
			var score: float = (1.0 - repeat_score) * 0.62 + clampf(contrast * 2.3, 0.0, 1.0) * 0.26 + position * 0.12
			if score > best_bridge_score:
				best_bridge_score = score
				best_bridge_index = i
		if best_bridge_index >= 0 and best_bridge_score >= 0.48:
			(phrases[best_bridge_index] as Dictionary)["role"] = "bridge"
			# Extend by one neighboring unique cell when it belongs to the same contrast.
			for neighbor in [best_bridge_index - 1, best_bridge_index + 1]:
				if neighbor < intro_end or neighbor >= outro_start:
					continue
				var neighbor_phrase: Dictionary = phrases[neighbor] as Dictionary
				if str(neighbor_phrase.get("role", "verse")) == "verse" and float(neighbor_phrase.get("global_repeat_score", 0.0)) < 0.52:
					neighbor_phrase["role"] = "bridge"

	# Interludes are short, novel connectors, most often directly after a chorus.
	for chorus_start in chorus_starts:
		var index: int = chorus_start + block_length
		if index < intro_end or index >= outro_start or index >= total:
			continue
		var phrase: Dictionary = phrases[index] as Dictionary
		if str(phrase.get("role", "verse")) != "verse":
			continue
		var repeat_score: float = float(phrase.get("global_repeat_score", 0.0))
		var drive: float = _window_local_drive_v11(phrases, index, 1)
		var previous_drive: float = _window_local_drive_v11(phrases, maxi(0, index - 1), 1)
		if repeat_score < 0.48 and absf(drive - previous_drive) >= 0.10:
			phrase["role"] = "interlude"

func _assign_arrangement_intensity_v11(phrases: Array) -> void:
	var total: int = phrases.size()
	for i in range(total):
		var phrase: Dictionary = phrases[i] as Dictionary
		var role: String = str(phrase.get("role", "verse"))
		var local_drive: float = _window_local_drive_v11(phrases, i, 1)
		var intensity: float = 0.5
		match role:
			"intro":
				intensity = lerpf(0.18, 0.40, local_drive)
			"verse":
				intensity = lerpf(0.38, 0.60, local_drive)
			"pre_chorus":
				var progress: float = float(phrase.get("pre_chorus_progress", 0.65))
				intensity = lerpf(0.56, 0.79, clampf(progress * 0.72 + local_drive * 0.28, 0.0, 1.0))
			"chorus":
				var chorus_score: float = float(phrase.get("chorus_score", 0.78))
				intensity = lerpf(0.84, 0.98, clampf(chorus_score * 0.68 + local_drive * 0.32, 0.0, 1.0))
				if bool(phrase.get("final_chorus", false)):
					intensity = minf(1.0, intensity + 0.035)
			"bridge":
				intensity = lerpf(0.43, 0.68, local_drive)
			"interlude":
				intensity = lerpf(0.34, 0.60, local_drive)
			"outro":
				intensity = lerpf(0.16, 0.38, local_drive)
			_:
				intensity = lerpf(0.38, 0.62, local_drive)
		phrase["arrangement_intensity"] = snappedf(clampf(intensity, 0.0, 1.0), 0.001)

func _window_local_drive_v11(phrases: Array, start_index: int, block_length: int) -> float:
	if phrases.is_empty() or block_length <= 0:
		return 0.5
	var total: float = 0.0
	var count: int = 0
	for offset in range(block_length):
		var index: int = start_index + offset
		if index < 0 or index >= phrases.size():
			continue
		var phrase: Dictionary = phrases[index] as Dictionary
		var activity: float = float(phrase.get("activity", 0.5))
		var rhythm_density: float = float(phrase.get("rhythmic_density", activity))
		var drive_score: float = float(phrase.get("drive_score", activity))
		total += activity * 0.42 + rhythm_density * 0.28 + drive_score * 0.30
		count += 1
	return clampf(total / float(maxi(1, count)), 0.0, 1.0)

func _block_similarity_v10(phrases: Array, a_start: int, b_start: int, block_length: int) -> float:
	if a_start < 0 or b_start < 0 or a_start + block_length > phrases.size() or b_start + block_length > phrases.size():
		return 0.0
	var total: float = 0.0
	for offset in range(block_length):
		total += _phrase_signature_similarity_v10(phrases[a_start + offset] as Dictionary, phrases[b_start + offset] as Dictionary)
	return clampf(total / float(maxi(1, block_length)), 0.0, 1.0)

func _window_metric_v10(phrases: Array, start_index: int, block_length: int, field: String, fallback: float) -> float:
	var total: float = 0.0
	var count: int = 0
	for offset in range(block_length):
		var index: int = start_index + offset
		if index < 0 or index >= phrases.size():
			continue
		total += float((phrases[index] as Dictionary).get(field, fallback))
		count += 1
	return total / float(maxi(1, count))

func _phrase_signature_similarity_v10(a: Dictionary, b: Dictionary) -> float:
	# Exponential distance is intentionally strict. Broadly similar loudness is
	# not enough; onset/rhythm shape across the full 8-beat cell must also match.
	var distance: float = 0.0
	distance += absf(float(a.get("energy_mean", 0.0)) - float(b.get("energy_mean", 0.0))) * 0.08
	distance += absf(float(a.get("onset_mean", 0.0)) - float(b.get("onset_mean", 0.0))) * 0.08
	distance += absf(float(a.get("rhythm_mean", 0.0)) - float(b.get("rhythm_mean", 0.0))) * 0.08
	distance += absf(float(a.get("brightness_mean", 0.0)) - float(b.get("brightness_mean", 0.0))) * 0.10
	distance += minf(1.0, absf(float(a.get("pulses_per_beat", 0.0)) - float(b.get("pulses_per_beat", 0.0))) / 2.5) * 0.12
	distance += _shape_distance_v10(a.get("energy_shape", []), b.get("energy_shape", [])) * 0.08
	distance += _shape_distance_v10(a.get("onset_shape", []), b.get("onset_shape", [])) * 0.20
	distance += _shape_distance_v10(a.get("rhythm_shape", []), b.get("rhythm_shape", [])) * 0.14
	distance += _shape_distance_v10(a.get("brightness_shape", []), b.get("brightness_shape", [])) * 0.12
	return clampf(exp(-distance * 8.0), 0.0, 1.0)

func _shape_distance_v10(a_value: Variant, b_value: Variant) -> float:
	if not (a_value is Array) or not (b_value is Array):
		return 1.0
	var a: Array = a_value as Array
	var b: Array = b_value as Array
	var count: int = mini(a.size(), b.size())
	if count <= 0:
		return 1.0
	var total: float = 0.0
	for i in range(count):
		total += absf(float(a[i]) - float(b[i]))
	return clampf(total / float(count), 0.0, 1.0)

func _range_shape_v10(curve: Array[float], hop_seconds: float, start_time: float, end_time: float, slices: int) -> Array:
	var result: Array = []
	var count: int = maxi(1, slices)
	var duration: float = maxf(0.001, end_time - start_time)
	for i in range(count):
		var slice_start: float = start_time + duration * float(i) / float(count)
		var slice_end: float = start_time + duration * float(i + 1) / float(count)
		result.append(snappedf(_sample_range_mean(curve, hop_seconds, slice_start, slice_end), 0.001))
	return result

func _percentile_v10(values: Array[float], percentile: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted_values: Array[float] = []
	sorted_values.assign(values)
	sorted_values.sort()
	var position: float = clampf(percentile, 0.0, 1.0) * float(sorted_values.size() - 1)
	var lo: int = floori(position)
	var hi: int = mini(sorted_values.size() - 1, lo + 1)
	return lerpf(sorted_values[lo], sorted_values[hi], position - float(lo))

func _count_local_peaks_v10(curve: Array[float], hop_seconds: float, start_time: float, end_time: float) -> int:
	if curve.size() < 3 or end_time <= start_time:
		return 0
	var start_index: int = clampi(int(floor(start_time / maxf(0.000001, hop_seconds))), 1, curve.size() - 2)
	var end_index: int = clampi(int(ceil(end_time / maxf(0.000001, hop_seconds))), start_index, curve.size() - 2)
	var mean: float = 0.0
	var count: int = 0
	for i in range(start_index, end_index + 1):
		mean += curve[i]
		count += 1
	mean /= float(maxi(1, count))
	var variance: float = 0.0
	for i in range(start_index, end_index + 1):
		var delta: float = curve[i] - mean
		variance += delta * delta
	var stddev: float = sqrt(variance / float(maxi(1, count)))
	var threshold: float = maxf(0.08, mean + stddev * 0.26)
	var minimum_gap_steps: int = maxi(1, int(round(0.045 / maxf(0.000001, hop_seconds))))
	var peaks: int = 0
	var last_peak: int = -999999
	for i in range(start_index, end_index + 1):
		if curve[i] < threshold or curve[i] < curve[i - 1] or curve[i] <= curve[i + 1]:
			continue
		if i - last_peak < minimum_gap_steps:
			continue
		peaks += 1
		last_peak = i
	return peaks

func _activity_to_intensity_v10(activity: float) -> String:
	if activity < 0.22:
		return "sparse"
	if activity < 0.40:
		return "breathing"
	if activity < 0.60:
		return "medium"
	if activity < 0.80:
		return "high"
	return "peak"

func _sections_from_energy_phrases(phrases: Array, active_start: float, active_end: float, duration: float) -> Array:
	if phrases.is_empty():
		return _fallback_sections(active_start, active_end, duration)
	var sections: Array = []
	var role_counts: Dictionary = {}
	var current_role: String = ""
	var current_start: float = active_start
	var current_end: float = active_start
	var activity_sum: float = 0.0
	var rhythm_sum: float = 0.0
	var drive_sum: float = 0.0
	var chorus_sum: float = 0.0
	var arrangement_sum: float = 0.0
	var count: int = 0
	for raw_phrase in phrases:
		if not (raw_phrase is Dictionary):
			continue
		var phrase: Dictionary = raw_phrase as Dictionary
		var role: String = str(phrase.get("role", "verse"))
		if current_role.is_empty():
			current_role = role
			current_start = float(phrase.get("start", active_start))
		if role != current_role and count > 0:
			_append_section_v11(sections, role_counts, current_role, current_start, current_end, activity_sum / count, rhythm_sum / count, drive_sum / count, chorus_sum / count, arrangement_sum / count)
			current_role = role
			current_start = float(phrase.get("start", current_end))
			activity_sum = 0.0
			rhythm_sum = 0.0
			drive_sum = 0.0
			chorus_sum = 0.0
			arrangement_sum = 0.0
			count = 0
		current_end = float(phrase.get("end", active_end))
		activity_sum += float(phrase.get("activity", 0.5))
		rhythm_sum += float(phrase.get("rhythmic_density", 0.5))
		drive_sum += float(phrase.get("drive_score", 0.5))
		chorus_sum += float(phrase.get("chorus_score", 0.0))
		arrangement_sum += float(phrase.get("arrangement_intensity", 0.5))
		count += 1
	if count > 0:
		_append_section_v11(sections, role_counts, current_role, current_start, current_end, activity_sum / count, rhythm_sum / count, drive_sum / count, chorus_sum / count, arrangement_sum / count)
	if not sections.is_empty():
		(sections[0] as Dictionary)["start"] = snappedf(maxf(active_start, float((sections[0] as Dictionary).get("start", active_start))), 0.000001)
		(sections[sections.size() - 1] as Dictionary)["end"] = snappedf(minf(minf(active_end, duration), float((sections[sections.size() - 1] as Dictionary).get("end", active_end))), 0.000001)
	return sections

func _append_section_v11(sections: Array, role_counts: Dictionary, role: String, start_time: float, end_time: float, activity: float, rhythmic_density: float, drive_score: float, chorus_score: float, arrangement_intensity: float) -> void:
	if end_time <= start_time + 0.05:
		return
	var occurrence: int = int(role_counts.get(role, 0)) + 1
	role_counts[role] = occurrence
	sections.append({
		"name": role if occurrence == 1 else "%s_%d" % [role, occurrence],
		"start": snappedf(start_time, 0.000001),
		"end": snappedf(end_time, 0.000001),
		"intensity": _activity_to_intensity_v10(arrangement_intensity),
		"activity": snappedf(activity, 0.001),
		"rhythmic_density": snappedf(rhythmic_density, 0.001),
		"drive_score": snappedf(drive_score, 0.001),
		"chorus_score": snappedf(chorus_score, 0.001),
		"refrain_score": snappedf(chorus_score, 0.001),
		"arrangement_intensity": snappedf(arrangement_intensity, 0.001),
		"role": role,
		"source": "auto_song_form_v11",
	})

func _sanitize_sections(raw_sections: Array, playable_start: float, active_end: float, duration: float) -> Array:
	var result: Array = []
	for raw_section in raw_sections:
		if not (raw_section is Dictionary):
			continue
		var section: Dictionary = (raw_section as Dictionary).duplicate(true)
		var start_time: float = clampf(float(section.get("start", playable_start)), playable_start, duration)
		var end_time: float = clampf(float(section.get("end", active_end)), 0.0, minf(active_end, duration))
		if end_time <= start_time + 0.05:
			continue
		section["start"] = snappedf(start_time, 0.000001)
		section["end"] = snappedf(end_time, 0.000001)
		if not section.has("role"):
			section["role"] = _role_from_section_v10(section)
		if not section.has("activity"):
			section["activity"] = _activity_from_section_v10(section)
		result.append(section)
	result.sort_custom(_sort_section_time_ascending_v10)
	return result

func _sort_section_time_ascending_v10(a: Variant, b: Variant) -> bool:
	if not (a is Dictionary) or not (b is Dictionary):
		return false
	return float((a as Dictionary).get("start", 0.0)) < float((b as Dictionary).get("start", 0.0))

func _fallback_sections(playable_start: float, active_end: float, duration: float) -> Array:
	return [{
		"name": "verse",
		"start": snappedf(playable_start, 0.000001),
		"end": snappedf(minf(active_end, duration), 0.000001),
		"intensity": "medium",
		"activity": 0.52,
		"rhythmic_density": 0.50,
		"drive_score": 0.50,
		"refrain_score": 0.0,
		"role": "verse",
		"source": "fallback_song_form_v11",
	}]

func _role_from_section_v10(section: Dictionary) -> String:
	var name: String = str(section.get("name", "")).to_lower()
	var role: String = str(section.get("role", "")).to_lower()
	if role in ["intro", "verse", "pre_chorus", "chorus", "bridge", "interlude", "outro"]:
		return role
	if "pre_chorus" in name or "prechorus" in name or "pre-chorus" in name:
		return "pre_chorus"
	if "chorus" in name or "refrain" in name or "hook" in name or "ref" in name:
		return "chorus"
	if "bridge" in name:
		return "bridge"
	if "interlude" in name or "instrumental" in name:
		return "interlude"
	if "intro" in name:
		return "intro"
	if "outro" in name or "release" in name:
		return "outro"
	return "verse"

func _activity_from_section_v10(section: Dictionary) -> float:
	if section.has("arrangement_intensity"):
		return clampf(float(section.get("arrangement_intensity", 0.5)), 0.0, 1.0)
	if section.has("activity"):
		return clampf(float(section.get("activity", 0.5)), 0.0, 1.0)
	var role: String = _role_from_section_v10(section)
	match role:
		"intro":
			return 0.30
		"verse":
			return 0.50
		"pre_chorus":
			return 0.68
		"chorus":
			return 0.91
		"bridge":
			return 0.56
		"interlude":
			return 0.48
		"outro":
			return 0.28
		_:
			return 0.50

func _build_generation_phrases_v10(sections: Array, analyzed_phrases: Array, beat_times: Array[float], playable_start: float, active_end: float) -> Array:
	var result: Array = []
	var phrase_index: int = 0
	for section_index in range(sections.size()):
		var raw_section: Variant = sections[section_index]
		if not (raw_section is Dictionary):
			continue
		var section: Dictionary = raw_section as Dictionary
		var section_start: float = maxf(playable_start, float(section.get("start", playable_start)))
		var section_end: float = minf(active_end, float(section.get("end", active_end)))
		var start_index: int = _first_beat_index_at_or_after(beat_times, section_start - 0.02)
		var end_index: int = _first_beat_index_at_or_after(beat_times, section_end - 0.02)
		if start_index < 0:
			continue
		if end_index < 0:
			end_index = beat_times.size() - 1
		end_index = maxi(start_index + 1, end_index)
		var cursor: int = start_index
		var local_index: int = 0
		var phrase_count: int = maxi(1, int(ceil(float(end_index - start_index) / float(PHRASE_BEATS))))
		while cursor < end_index and cursor < beat_times.size() - 1:
			var phrase_end_index: int = mini(end_index, cursor + PHRASE_BEATS)
			var start_time: float = maxf(section_start, beat_times[cursor])
			var end_time: float = minf(section_end, beat_times[phrase_end_index])
			var role: String = _role_from_section_v10(section)
			var local_activity: float = _metric_from_analysis_v10(analyzed_phrases, "activity", start_time, end_time, float(section.get("activity", 0.5)))
			var rhythm_density: float = _metric_from_analysis_v10(analyzed_phrases, "rhythmic_density", start_time, end_time, float(section.get("rhythmic_density", local_activity)))
			var drive_score: float = _metric_from_analysis_v10(analyzed_phrases, "drive_score", start_time, end_time, float(section.get("drive_score", local_activity)))
			var relative_energy: float = _metric_from_analysis_v10(analyzed_phrases, "relative_energy", start_time, end_time, local_activity)
			var onset_mean: float = _metric_from_analysis_v10(analyzed_phrases, "onset_mean", start_time, end_time, local_activity * 0.55)
			var onset_peak: float = _metric_from_analysis_v10(analyzed_phrases, "onset_peak", start_time, end_time, maxf(onset_mean, local_activity * 0.72))
			var pulses_per_beat: float = _metric_from_analysis_v10(analyzed_phrases, "pulses_per_beat", start_time, end_time, 1.0)
			var chorus_score: float = _metric_from_analysis_v10(analyzed_phrases, "chorus_score", start_time, end_time, float(section.get("chorus_score", 0.0)))
			var arrangement_intensity: float = _metric_from_analysis_v10(analyzed_phrases, "arrangement_intensity", start_time, end_time, float(section.get("arrangement_intensity", _activity_from_section_v10(section))))
			var progress: float = float(local_index) / float(maxi(1, phrase_count - 1))
			result.append({
				"start": snappedf(start_time, 0.000001),
				"end": snappedf(end_time, 0.000001),
				"start_beat_index": cursor,
				"end_beat_index": phrase_end_index,
				"beat_count": phrase_end_index - cursor,
				"phrase_index": phrase_index,
				"section_index": section_index,
				"section_progress": snappedf(progress, 0.001),
				"role": role,
				"activity": snappedf(local_activity, 0.001),
				"rhythmic_density": snappedf(rhythm_density, 0.001),
				"drive_score": snappedf(drive_score, 0.001),
				"relative_energy": snappedf(relative_energy, 0.001),
				"onset_mean": snappedf(onset_mean, 0.001),
				"onset_peak": snappedf(onset_peak, 0.001),
				"pulses_per_beat": snappedf(pulses_per_beat, 0.001),
				"chorus_score": snappedf(chorus_score, 0.001),
				"refrain_score": snappedf(chorus_score, 0.001),
				"arrangement_intensity": snappedf(arrangement_intensity, 0.001),
				"intensity": _activity_to_intensity_v10(arrangement_intensity),
			})
			phrase_index += 1
			local_index += 1
			cursor = phrase_end_index
	return result

func _prepare_generation_phrases_v16(phrases: Array) -> void:
	if phrases.is_empty():
		return
	var raw_values: Array[float] = []
	for raw_phrase in phrases:
		if not (raw_phrase is Dictionary):
			continue
		var phrase: Dictionary = raw_phrase as Dictionary
		var activity: float = clampf(float(phrase.get("activity", 0.5)), 0.0, 1.0)
		var rhythm_density: float = clampf(float(phrase.get("rhythmic_density", activity)), 0.0, 1.0)
		var drive_score: float = clampf(float(phrase.get("drive_score", activity)), 0.0, 1.0)
		var relative_energy: float = clampf(float(phrase.get("relative_energy", activity)), 0.0, 1.0)
		var onset_peak: float = clampf(float(phrase.get("onset_peak", activity)), 0.0, 1.0)
		var pulse_density: float = clampf((float(phrase.get("pulses_per_beat", 1.0)) - 0.45) / 2.20, 0.0, 1.0)
		var local_audio: float = clampf(activity * 0.22 + rhythm_density * 0.24 + drive_score * 0.28 + relative_energy * 0.12 + onset_peak * 0.08 + pulse_density * 0.06, 0.0, 1.0)
		phrase["raw_audio_intensity"] = local_audio
		raw_values.append(local_audio)
	if raw_values.is_empty():
		return
	var low_threshold: float = _percentile_v10(raw_values, 0.25)
	var high_threshold: float = _percentile_v10(raw_values, 0.85)
	var intensity_floor: float = _percentile_v10(raw_values, 0.08)
	var intensity_ceiling: float = maxf(intensity_floor + 0.08, _percentile_v10(raw_values, 0.94))
	var normalized_values: Array[float] = []
	for raw_phrase in phrases:
		if not (raw_phrase is Dictionary):
			continue
		var phrase: Dictionary = raw_phrase as Dictionary
		var normalized: float = clampf((float(phrase.get("raw_audio_intensity", 0.5)) - intensity_floor) / (intensity_ceiling - intensity_floor), 0.0, 1.0)
		normalized_values.append(normalized)
	for i in range(phrases.size()):
		if not (phrases[i] is Dictionary):
			continue
		var phrase: Dictionary = phrases[i] as Dictionary
		var audio_intensity: float = float(normalized_values[mini(i, normalized_values.size() - 1)])
		var smoothed_audio: float = audio_intensity * 0.76
		var smooth_weight: float = 0.76
		if i > 0:
			smoothed_audio += float(normalized_values[i - 1]) * 0.12
			smooth_weight += 0.12
		if i + 1 < normalized_values.size():
			smoothed_audio += float(normalized_values[i + 1]) * 0.12
			smooth_weight += 0.12
		audio_intensity = clampf(smoothed_audio / smooth_weight, 0.0, 1.0)
		var previous_audio: float = float(normalized_values[maxi(0, i - 1)])
		var next_audio: float = float(normalized_values[mini(normalized_values.size() - 1, i + 1)])
		var rise: float = maxf(0.0, audio_intensity - previous_audio)
		var local_peak: float = maxf(0.0, audio_intensity - (previous_audio + next_audio) * 0.5)
		var role: String = str(phrase.get("role", "verse"))
		var role_signal: float = _role_density_signal_v16(role)
		var play_intensity: float = clampf(audio_intensity * 0.70 + role_signal * 0.20 + clampf(rise * 1.5 + local_peak, 0.0, 1.0) * 0.10, 0.0, 1.0)
		var raw_audio: float = float(phrase.get("raw_audio_intensity", 0.5))
		if raw_audio >= high_threshold:
			var peak_progress: float = clampf((raw_audio - high_threshold) / maxf(0.04, intensity_ceiling - high_threshold), 0.0, 1.0)
			play_intensity = maxf(play_intensity, lerpf(0.76, 0.96, peak_progress))
		if raw_audio <= low_threshold:
			var calm_progress: float = clampf((raw_audio - intensity_floor) / maxf(0.04, low_threshold - intensity_floor), 0.0, 1.0)
			play_intensity = minf(play_intensity, lerpf(0.24, 0.40, calm_progress))
		# Leave a deliberate breath immediately before a large upward transition.
		var upcoming_jump: float = next_audio - audio_intensity
		if upcoming_jump >= 0.24:
			play_intensity = maxf(0.18, play_intensity - minf(0.10, upcoming_jump * 0.28))
		phrase["audio_intensity"] = snappedf(audio_intensity, 0.001)
		phrase["play_intensity"] = snappedf(play_intensity, 0.001)
		phrase["peak_override"] = raw_audio >= high_threshold
		phrase["calm_cap"] = raw_audio <= low_threshold
		phrase["transition_rise"] = snappedf(rise, 0.001)
		phrase["dynamic_zone"] = _dynamic_zone_v16(play_intensity)
		phrase["intensity"] = _activity_to_intensity_v10(play_intensity)

func _role_density_signal_v16(role: String) -> float:
	match role:
		"intro":
			return 0.24
		"verse":
			return 0.45
		"pre_chorus":
			return 0.64
		"chorus":
			return 0.78
		"bridge":
			return 0.50
		"interlude":
			return 0.48
		"outro":
			return 0.26
		_:
			return 0.46

func _dynamic_zone_v16(intensity: float) -> String:
	if intensity >= 0.76:
		return "peak"
	if intensity >= 0.58:
		return "intense"
	if intensity >= 0.38:
		return "groove"
	return "calm"

func _metric_from_analysis_v10(analyzed_phrases: Array, field: String, start_time: float, end_time: float, fallback: float) -> float:
	var total: float = 0.0
	var weight: float = 0.0
	for raw_phrase in analyzed_phrases:
		if not (raw_phrase is Dictionary):
			continue
		var phrase: Dictionary = raw_phrase as Dictionary
		var overlap: float = maxf(0.0, minf(end_time, float(phrase.get("end", end_time))) - maxf(start_time, float(phrase.get("start", start_time))))
		if overlap <= 0.0:
			continue
		total += float(phrase.get(field, fallback)) * overlap
		weight += overlap
	if weight <= 0.000001:
		return fallback
	return clampf(total / weight, 0.0, 1.0)

func _generate_space_events_v10(phrases: Array, beat_times: Array[float], energy: Array[float], onset: Array[float], hop_seconds: float, bpm: float, playable_start: float, active_end: float, profile: Dictionary) -> Array[float]:
	var beat: float = 60.0 / maxf(1.0, bpm)
	var candidates: Array = []
	for raw_phrase in phrases:
		if not (raw_phrase is Dictionary):
			continue
		var phrase: Dictionary = raw_phrase as Dictionary
		var role: String = str(phrase.get("role", "verse"))
		var chorus_score: float = float(phrase.get("chorus_score", 0.0))
		var arrangement_intensity: float = float(phrase.get("arrangement_intensity", 0.5))
		var start_index: int = int(phrase.get("start_beat_index", 0))
		var end_index: int = int(phrase.get("end_beat_index", start_index + 1))
		var phrase_index: int = int(phrase.get("phrase_index", 0))
		for beat_index in range(start_index, mini(end_index, beat_times.size())):
			var time: float = beat_times[beat_index]
			if time < playable_start or time >= active_end:
				continue
			var local_beat: int = beat_index - start_index
			var strength: float = _musical_strength_v10(energy, onset, hop_seconds, time, beat)
			var structural: float = 0.0
			if local_beat == 0:
				structural += 1.0
			if posmod(local_beat, BAR_BEATS) == 0:
				structural += 0.45
			match role:
				"chorus":
					structural += 3.4 + chorus_score * 2.4
					if local_beat in [0, 8]:
						structural += 1.5
				"pre_chorus":
					if local_beat >= 12:
						structural += 1.8
				"bridge":
					structural += 0.7
				"interlude":
					structural += 0.45
				"intro", "outro":
					structural -= 0.65
			candidates.append({"time": time, "score": strength * 2.8 + structural + arrangement_intensity * 1.1, "phrase": phrase_index, "role": role})
	candidates.sort_custom(_sort_score_descending_v10)
	var target: int = int(round(float(maxi(1, beat_times.size())) / float(profile.get("space_beats_per_event", 40.0))))
	target = maxi(1, target)
	var result: Array[float] = []
	var minimum_gap: float = beat * float(profile.get("space_min_gap_beats", 8.0))
	for raw_candidate in candidates:
		if result.size() >= target:
			break
		if not (raw_candidate is Dictionary):
			continue
		var candidate: Dictionary = raw_candidate as Dictionary
		var time: float = float(candidate.get("time", 0.0))
		var valid: bool = true
		for existing in result:
			if absf(time - existing) < minimum_gap:
				valid = false
				break
		if valid:
			result.append(snappedf(time, 0.000001))
	result.sort()
	return result

func _generate_music_events_v10(phrases: Array, beat_times: Array[float], energy: Array[float], onset: Array[float], hop_seconds: float, bpm: float, playable_start: float, active_end: float, spaces: Array[float], profile: Dictionary, _difficulty_id: String) -> Array:
	var events: Array = []
	var beat: float = 60.0 / maxf(1.0, bpm)
	var division: int = maxi(1, int(profile.get("grid_division", 2)))
	for raw_phrase in phrases:
		if not (raw_phrase is Dictionary):
			continue
		var phrase: Dictionary = raw_phrase as Dictionary
		var candidates: Array = []
		var phrase_index: int = int(phrase.get("phrase_index", 0))
		var section_index: int = int(phrase.get("section_index", 0))
		var start_index: int = int(phrase.get("start_beat_index", 0))
		var end_index: int = int(phrase.get("end_beat_index", start_index + 1))
		var role: String = str(phrase.get("role", "verse"))
		var activity: float = float(phrase.get("activity", 0.5))
		var rhythmic_density: float = float(phrase.get("rhythmic_density", activity))
		var drive_score: float = float(phrase.get("drive_score", activity))
		var chorus_score: float = float(phrase.get("chorus_score", 0.0))
		var arrangement_intensity: float = float(phrase.get("arrangement_intensity", 0.5))
		for beat_index in range(start_index, mini(end_index, beat_times.size() - 1)):
			var start_time: float = beat_times[beat_index]
			var next_time: float = beat_times[beat_index + 1]
			var interval: float = next_time - start_time
			if interval <= 0.04:
				continue
			var local_beat: int = beat_index - start_index
			var subdivisions: Array[float] = [0.0]
			if division >= 2:
				subdivisions.append(0.5)
			if division >= 4:
				subdivisions.append(0.25)
				subdivisions.append(0.75)
			for slot_index in range(subdivisions.size()):
				var fraction: float = subdivisions[slot_index]
				var time: float = start_time + interval * fraction
				if time < playable_start - 0.01 or time >= active_end:
					continue
				if _time_near_space_v10(time, spaces, beat * float(profile.get("space_note_clearance_beats", 0.16))):
					continue
				var strength: float = _musical_strength_v10(energy, onset, hop_seconds, time, beat)
				if fraction in [0.25, 0.75] and not _allow_sixteenth_candidate_v13_2(role, activity, rhythmic_density, drive_score, arrangement_intensity, profile):
					continue
				var structural: float = _candidate_score_v13_2(role, local_beat, fraction, activity, rhythmic_density, drive_score, chorus_score, arrangement_intensity, float(phrase.get("section_progress", 0.5)), profile)
				candidates.append({
					"time": time,
					"score": structural + strength * 3.35,
					"strength": strength,
					"beat_in_phrase": local_beat,
					"subdivision": slot_index,
				})
		if candidates.is_empty():
			continue
		var target: int = _target_notes_v11(phrase, int(phrase.get("beat_count", end_index - start_index)), candidates.size(), profile)
		candidates.sort_custom(_sort_score_descending_v10)
		var chosen: Array = []
		for i in range(mini(target, candidates.size())):
			chosen.append(candidates[i])
		chosen.sort_custom(_sort_time_ascending_v10)
		for raw_candidate in chosen:
			var candidate: Dictionary = raw_candidate as Dictionary
			events.append({
				"time": snappedf(float(candidate.get("time", 0.0)), 0.000001),
				"type": "normal",
				"_strength": float(candidate.get("strength", 0.5)),
				"_phrase_index": phrase_index,
				"_section_index": section_index,
				"_beat_in_phrase": int(candidate.get("beat_in_phrase", 0)),
				"_subdivision": int(candidate.get("subdivision", 0)),
				"_role": role,
				"_chorus_score": chorus_score,
				"_pattern_family": str(phrase.get("pattern_family", "pulse")),
				"_signature_pattern_id": int(phrase.get("signature_pattern_id", 0)),
				"_phrase_arc": str(phrase.get("phrase_arc", "groove")),
				"_difficulty_pressure": float(phrase.get("difficulty_pressure", 0.5)),
				"_difficulty_stage": str(phrase.get("difficulty_stage", "develop")),
			})
	events.sort_custom(_sort_time_ascending_v10)
	return _deduplicate_events_v10(events)

func _refine_grid_phase_v1691(beat_times: Array[float], onset: Array[float], hop_seconds: float, bpm: float, active_start: float, active_end: float) -> Dictionary:
	if beat_times.size() < 8 or onset.is_empty() or hop_seconds <= 0.000001:
		return {"shift": 0.0, "gain": 0.0}
	var beat: float = 60.0 / maxf(1.0, bpm)
	var limit: float = minf(0.045, beat * 0.10)
	var step: float = maxf(0.0015, hop_seconds * 0.50)
	var base_score: float = _grid_phase_score_v1691(beat_times, onset, hop_seconds, 0.0, active_start, active_end)
	var best_score: float = base_score
	var best_shift: float = 0.0
	var shift: float = -limit
	while shift <= limit + 0.000001:
		var score: float = _grid_phase_score_v1691(beat_times, onset, hop_seconds, shift, active_start, active_end)
		if score > best_score:
			best_score = score
			best_shift = shift
		shift += step
	var gain: float = (best_score - base_score) / maxf(0.000001, base_score)
	# Three-percent evidence threshold deliberately avoids phase-jitter on songs
	# where several offsets score almost identically.
	if gain < 0.03:
		best_shift = 0.0
	return {"shift": snappedf(best_shift, 0.000001), "gain": gain}

func _grid_phase_score_v1691(beat_times: Array[float], onset: Array[float], hop_seconds: float, shift: float, active_start: float, active_end: float) -> float:
	var values: Array[float] = []
	for raw_time in beat_times:
		var time: float = float(raw_time) + shift
		if time < active_start or time > active_end:
			continue
		values.append(_sample_curve(onset, hop_seconds, time))
	if values.is_empty():
		return 0.0
	values.sort()
	var mean: float = 0.0
	for value in values:
		mean += value
	mean /= float(values.size())
	var p75: float = values[clampi(int(floor(float(values.size() - 1) * 0.75)), 0, values.size() - 1)]
	var p90: float = values[clampi(int(floor(float(values.size() - 1) * 0.90)), 0, values.size() - 1)]
	return mean + p75 * 0.35 + p90 * 0.15

func _subdivisions_v1691(start_time: float, next_time: float, onset: Array[float], hop_seconds: float, division: int, activity: float, rhythmic_density: float, drive_score: float, play_intensity: float, phrase: Dictionary, profile: Dictionary, difficulty_id: String) -> Array[float]:
	var result: Array[float] = [0.0]
	if division >= 2:
		result.append(0.5)
	var allow_sixteenth: bool = division >= 4 and _allow_sixteenth_candidate_v16(activity, rhythmic_density, drive_score, play_intensity, profile)
	if allow_sixteenth:
		result.append(0.25)
		result.append(0.75)
	# Triplets are opt-in and evidence-backed. NORMAL stays on quarter/eighth
	# pulse; HARD/MASTER may expose thirds only when the local onset envelope
	# supports them more strongly than the competing straight subdivisions.
	if difficulty_id.to_lower() != "normal" and float(phrase.get("difficulty_pressure", play_intensity)) >= float(profile.get("triplet_min_pressure", 0.66)):
		var interval: float = maxf(0.000001, next_time - start_time)
		var third_a: float = _sample_curve(onset, hop_seconds, start_time + interval / 3.0)
		var third_b: float = _sample_curve(onset, hop_seconds, start_time + interval * 2.0 / 3.0)
		var straight_a: float = _sample_curve(onset, hop_seconds, start_time + interval * 0.25) if allow_sixteenth else 0.0
		var straight_b: float = _sample_curve(onset, hop_seconds, start_time + interval * 0.75) if allow_sixteenth else 0.0
		var triplet_score: float = maxf(third_a, third_b) + minf(third_a, third_b) * 0.35
		var straight_score: float = maxf(straight_a, straight_b) + minf(straight_a, straight_b) * 0.35
		if triplet_score >= float(profile.get("triplet_onset_threshold", 0.46)) and triplet_score >= straight_score + float(profile.get("triplet_evidence_margin", 0.08)):
			result.append(1.0 / 3.0)
			result.append(2.0 / 3.0)
	result.sort()
	return result

func _generate_music_events_v16(phrases: Array, beat_times: Array[float], energy: Array[float], onset: Array[float], hop_seconds: float, bpm: float, playable_start: float, active_end: float, spaces: Array[float], profile: Dictionary, difficulty_id: String, generation_seed: int) -> Array:
	var events: Array = []
	var beat: float = 60.0 / maxf(1.0, bpm)
	var division: int = maxi(1, int(profile.get("grid_division", 2)))
	for raw_phrase in phrases:
		if not (raw_phrase is Dictionary):
			continue
		var phrase: Dictionary = raw_phrase as Dictionary
		var candidates: Array = []
		var phrase_index: int = int(phrase.get("phrase_index", 0))
		var section_index: int = int(phrase.get("section_index", 0))
		var start_index: int = int(phrase.get("start_beat_index", 0))
		var end_index: int = int(phrase.get("end_beat_index", start_index + 1))
		var role: String = str(phrase.get("role", "verse"))
		var activity: float = float(phrase.get("activity", 0.5))
		var rhythmic_density: float = float(phrase.get("rhythmic_density", activity))
		var drive_score: float = float(phrase.get("drive_score", activity))
		var chorus_score: float = float(phrase.get("chorus_score", 0.0))
		var arrangement_intensity: float = float(phrase.get("arrangement_intensity", 0.5))
		var play_intensity: float = float(phrase.get("play_intensity", drive_score))
		for beat_index in range(start_index, mini(end_index, beat_times.size() - 1)):
			var start_time: float = beat_times[beat_index]
			var next_time: float = beat_times[beat_index + 1]
			var interval: float = next_time - start_time
			if interval <= 0.04:
				continue
			var local_beat: int = beat_index - start_index
			var subdivisions: Array[float] = _subdivisions_v1691(start_time, next_time, onset, hop_seconds, division, activity, rhythmic_density, drive_score, play_intensity, phrase, profile, difficulty_id)
			for raw_fraction in subdivisions:
				var fraction: float = float(raw_fraction)
				var grid_time: float = start_time + interval * fraction
				if grid_time < playable_start - 0.01 or grid_time >= active_end:
					continue
				var anchor: Dictionary = _onset_anchor_v16(grid_time, beat, onset, hop_seconds, profile)
				var time: float = clampf(float(anchor.get("time", grid_time)), start_time, next_time - 0.00001)
				if _time_near_space_v10(time, spaces, beat * float(profile.get("space_note_clearance_beats", 0.16))):
					continue
				var strength: float = _musical_strength_v10(energy, onset, hop_seconds, time, beat)
				var onset_strength: float = float(anchor.get("strength", _sample_curve(onset, hop_seconds, grid_time)))
				var onset_contrast: float = float(anchor.get("contrast", 0.0))
				var onset_anchored: bool = bool(anchor.get("anchored", false))
				var timing_confidence: float = float(anchor.get("timing_confidence", onset_strength))
				var structural: float = _candidate_score_v16(role, local_beat, fraction, rhythmic_density, play_intensity, float(phrase.get("transition_rise", 0.0)), profile)
				var slot_key: int = local_beat * 4 + int(round(fraction * 4.0))
				var variation: float = _deterministic_noise_v15(generation_seed + phrase_index * 977, slot_key, section_index + 1)
				candidates.append({
					"time": time,
					"grid_time": grid_time,
					"score": structural + strength * 1.85 + onset_strength * 3.05 + onset_contrast * 2.10 + (float(profile.get("onset_anchor_bonus", 1.0)) if onset_anchored else 0.0) + variation * float(profile.get("rhythm_variation", 0.72)),
					"strength": strength,
					"onset_strength": onset_strength,
					"onset_contrast": onset_contrast,
					"onset_anchored": onset_anchored,
					"timing_confidence": timing_confidence,
					"play_intensity": play_intensity,
					"beat_in_phrase": local_beat,
					"bar_index": floori(float(local_beat) / float(BAR_BEATS)),
					"fraction": fraction,
					"slot_key": slot_key,
					"snap_delta": time - grid_time,
				})
		if candidates.is_empty():
			continue
		var target: int = _target_notes_v16(phrase, int(phrase.get("beat_count", end_index - start_index)), candidates.size(), profile, bpm)
		phrase["target_note_count"] = target
		var chosen: Array = _select_phrase_candidates_v16(candidates, target, phrase, profile, bpm, generation_seed + phrase_index * 7919)
		for raw_candidate in chosen:
			var candidate: Dictionary = raw_candidate as Dictionary
			events.append({
				"time": snappedf(float(candidate.get("time", 0.0)), 0.000001),
				"type": "normal",
				"_strength": float(candidate.get("strength", 0.5)),
				"_onset_strength": float(candidate.get("onset_strength", 0.0)),
				"_onset_contrast": float(candidate.get("onset_contrast", 0.0)),
				"_onset_anchor": bool(candidate.get("onset_anchored", false)),
				"_snap_delta": float(candidate.get("snap_delta", 0.0)),
				"_play_intensity": play_intensity,
				"_phrase_index": phrase_index,
				"_section_index": section_index,
				"_beat_in_phrase": int(candidate.get("beat_in_phrase", 0)),
				"_subdivision": int(round(float(candidate.get("fraction", 0.0)) * 4.0)),
				"_fraction": float(candidate.get("fraction", 0.0)),
				"_role": role,
				"_chorus_score": chorus_score,
				"_pattern_family": str(phrase.get("pattern_family", "pulse")),
				"_signature_pattern_id": int(phrase.get("signature_pattern_id", 0)),
				"_phrase_arc": str(phrase.get("phrase_arc", "groove")),
				"_difficulty_pressure": float(phrase.get("difficulty_pressure", 0.5)),
				"_difficulty_stage": str(phrase.get("difficulty_stage", "develop")),
			})
	events.sort_custom(_sort_time_ascending_v10)
	events = _deduplicate_events_v10(events)
	return _enforce_playability_v15(events, bpm, profile)

func _onset_anchor_v16(grid_time: float, beat: float, onset: Array[float], hop_seconds: float, profile: Dictionary) -> Dictionary:
	var grid_strength: float = _sample_curve(onset, hop_seconds, grid_time)
	if onset.is_empty() or hop_seconds <= 0.000001:
		return {"time": grid_time, "strength": grid_strength, "contrast": 0.0, "anchored": false, "nearest_onset_time": grid_time, "timing_confidence": grid_strength}
	var window: float = beat * float(profile.get("onset_snap_window_beats", 0.075))
	if window <= hop_seconds * 0.5:
		return {"time": grid_time, "strength": grid_strength, "contrast": 0.0, "anchored": false, "nearest_onset_time": grid_time, "timing_confidence": grid_strength}
	var start_index: int = clampi(floori((grid_time - window) / hop_seconds), 0, onset.size() - 1)
	var end_index: int = clampi(ceili((grid_time + window) / hop_seconds), 0, onset.size() - 1)
	var best_time: float = grid_time
	var best_strength: float = grid_strength
	var best_score: float = grid_strength
	for i in range(start_index, end_index + 1):
		var sample_time: float = float(i) * hop_seconds
		var distance_ratio: float = absf(sample_time - grid_time) / maxf(window, 0.000001)
		var sample_strength: float = onset[i]
		var sample_score: float = sample_strength - distance_ratio * float(profile.get("onset_distance_penalty", 0.14))
		if sample_score > best_score:
			best_score = sample_score
			best_strength = sample_strength
			best_time = sample_time
	var local_mean: float = _sample_mean(onset, hop_seconds, grid_time, maxf(window * 2.2, hop_seconds))
	var contrast: float = clampf((best_strength - local_mean) * 2.4, 0.0, 1.0)
	var anchored: bool = best_strength >= float(profile.get("onset_anchor_min_strength", 0.28)) and contrast >= float(profile.get("onset_snap_min_contrast", 0.06))
	var deviation: float = absf(best_time - grid_time)
	var timing_confidence: float = clampf(best_strength * 0.56 + contrast * 0.30 + (1.0 - clampf(deviation / maxf(window, 0.000001), 0.0, 1.0)) * 0.14, 0.0, 1.0)
	return {
		# v16.9.1 policy: onset peaks select/score grid slots, but never drag the
		# playable timestamp off the selected straight/triplet beat grid.
		"time": grid_time,
		"strength": clampf(best_strength, 0.0, 1.0),
		"contrast": contrast,
		"anchored": anchored,
		"nearest_onset_time": best_time,
		"timing_confidence": timing_confidence,
	}

func _target_notes_v16(phrase: Dictionary, beat_count: int, candidate_count: int, profile: Dictionary, bpm: float) -> int:
	var play_intensity: float = clampf(float(phrase.get("play_intensity", phrase.get("drive_score", 0.5))), 0.0, 1.0)
	var shaped_intensity: float = pow(play_intensity, float(profile.get("density_curve", 1.08)))
	var density: float = lerpf(float(profile.get("minimum_npb", 0.28)), float(profile.get("maximum_npb", 1.35)), shaped_intensity)
	density *= clampf(float(phrase.get("density_multiplier", 1.0)), 0.82, 1.12)
	density *= clampf(float(phrase.get("difficulty_density_multiplier", 1.0)), 0.82, 1.14)
	if bool(phrase.get("peak_override", false)):
		density = maxf(density, float(profile.get("peak_minimum_npb", 1.02)))
	if bool(phrase.get("calm_cap", false)):
		density = minf(density, float(profile.get("calm_maximum_npb", 0.58)))
	var target: int = int(round(float(maxi(1, beat_count)) * density))
	var max_notes_per_second: float = float(profile.get("max_notes_per_second", 5.0))
	var seconds: float = float(maxi(1, beat_count)) * 60.0 / maxf(1.0, bpm)
	var speed_cap: int = maxi(1, floori(seconds * max_notes_per_second + 0.5))
	var per_bar_cap: int = int(profile.get("max_notes_per_bar", 8)) * maxi(1, ceili(float(beat_count) / float(BAR_BEATS)))
	return clampi(mini(target, mini(speed_cap, per_bar_cap)), 0, candidate_count)

func _select_phrase_candidates_v16(candidates: Array, target: int, phrase: Dictionary, profile: Dictionary, bpm: float, noise_seed: int) -> Array:
	if target <= 0 or candidates.is_empty():
		return []
	var by_bar: Dictionary = {}
	for raw_candidate in candidates:
		var candidate: Dictionary = raw_candidate as Dictionary
		var bar_index: int = int(candidate.get("bar_index", 0))
		if not by_bar.has(bar_index):
			by_bar[bar_index] = []
		(by_bar[bar_index] as Array).append(candidate)
	var bar_indices: Array = by_bar.keys()
	bar_indices.sort()
	var quotas: Dictionary = _allocate_bar_quotas_v16(by_bar, bar_indices, target, profile, noise_seed)
	var selected: Array = []
	var previous_slots: Dictionary = {}
	var minimum_gap: float = maxf(float(profile.get("minimum_gap_seconds", 0.0)), 60.0 / maxf(1.0, bpm) * float(profile.get("minimum_gap_beats", 0.5)) * 0.92)
	for raw_bar_index in bar_indices:
		var bar_index: int = int(raw_bar_index)
		var pool: Array = (by_bar[bar_index] as Array).duplicate(true)
		var quota: int = int(quotas.get(bar_index, 0))
		var anchor_quota: int = int(round(float(quota) * float(profile.get("onset_priority_share", 0.40))))
		var current_slots: Dictionary = {}
		for pick_index in range(quota):
			var best_index: int = -1
			var best_score: float = -999999.0
			var anchor_first: bool = pick_index < anchor_quota
			var pass_count: int = 2 if anchor_first else 1
			for pass_index in range(pass_count):
				for i in range(pool.size()):
					var candidate: Dictionary = pool[i] as Dictionary
					if anchor_first and pass_index == 0 and not bool(candidate.get("onset_anchored", false)):
						continue
					if not _candidate_fits_v15(candidate, selected, minimum_gap):
						continue
					if _candidate_suppressed_by_breath_v169(candidate, phrase, profile):
						continue
					var slot_in_bar: int = posmod(int(candidate.get("slot_key", 0)), BAR_BEATS * 4)
					var score: float = float(candidate.get("score", 0.0))
					score += _pattern_slot_bonus_v169(candidate, phrase, profile, noise_seed)
					if previous_slots.has(slot_in_bar):
						score -= float(profile.get("previous_bar_slot_penalty", 0.82))
					if current_slots.has(slot_in_bar):
						score -= 1000.0
					var fraction: float = float(candidate.get("fraction", 0.0))
					var used_fraction_count: int = int(current_slots.get("fraction_%s" % str(fraction), 0))
					score -= float(used_fraction_count) * 0.18
					score += _deterministic_noise_v15(noise_seed + bar_index * 193, int(candidate.get("slot_key", 0)), pick_index + 1) * 0.26
					if score > best_score:
						best_score = score
						best_index = i
				if best_index >= 0:
					break
			if best_index < 0:
				break
			var picked: Dictionary = pool[best_index] as Dictionary
			selected.append(picked)
			var picked_slot: int = posmod(int(picked.get("slot_key", 0)), BAR_BEATS * 4)
			current_slots[picked_slot] = true
			var fraction_key: String = "fraction_%s" % str(float(picked.get("fraction", 0.0)))
			current_slots[fraction_key] = int(current_slots.get(fraction_key, 0)) + 1
			pool.remove_at(best_index)
		previous_slots = current_slots
	selected.sort_custom(_sort_time_ascending_v10)
	return selected

func _allocate_bar_quotas_v16(by_bar: Dictionary, bar_indices: Array, target: int, profile: Dictionary, noise_seed: int) -> Dictionary:
	var quotas: Dictionary = {}
	var weights: Dictionary = {}
	var capacity: Dictionary = {}
	var max_per_bar: int = int(profile.get("max_notes_per_bar", 8))
	for raw_bar_index in bar_indices:
		var bar_index: int = int(raw_bar_index)
		var pool: Array = by_bar[bar_index] as Array
		var onset_sum: float = 0.0
		var onset_peak: float = 0.0
		var strength_sum: float = 0.0
		var anchor_count: int = 0
		for raw_candidate in pool:
			var candidate: Dictionary = raw_candidate as Dictionary
			var value: float = float(candidate.get("onset_strength", candidate.get("strength", 0.5)))
			onset_sum += value
			onset_peak = maxf(onset_peak, value)
			strength_sum += float(candidate.get("strength", value))
			if bool(candidate.get("onset_anchored", false)):
				anchor_count += 1
		var onset_mean: float = onset_sum / float(maxi(1, pool.size()))
		var strength_mean: float = strength_sum / float(maxi(1, pool.size()))
		var anchor_share: float = float(anchor_count) / float(maxi(1, pool.size()))
		var bar_signal: float = clampf(onset_mean * 0.28 + onset_peak * 0.30 + strength_mean * 0.25 + anchor_share * 0.17, 0.0, 1.0)
		weights[bar_index] = 0.18 + bar_signal * 1.46 + _deterministic_noise_v15(noise_seed, bar_index + 1, 71) * 0.08
		var dynamic_cap: int = maxi(1, int(round(float(max_per_bar) * lerpf(0.58, 1.0, bar_signal))))
		capacity[bar_index] = mini(pool.size(), dynamic_cap)
		quotas[bar_index] = 0
	var remaining: int = target
	while remaining > 0:
		var best_bar: int = -1
		var best_demand: float = -999999.0
		for raw_bar_index in bar_indices:
			var bar_index: int = int(raw_bar_index)
			var current: int = int(quotas.get(bar_index, 0))
			if current >= int(capacity.get(bar_index, 0)):
				continue
			var demand: float = float(weights.get(bar_index, 1.0)) / pow(float(current + 1), 0.72)
			if demand > best_demand:
				best_demand = demand
				best_bar = bar_index
		if best_bar < 0:
			break
		quotas[best_bar] = int(quotas.get(best_bar, 0)) + 1
		remaining -= 1
	return quotas

func _candidate_fits_v15(candidate: Dictionary, selected: Array, minimum_gap: float) -> bool:
	var time: float = float(candidate.get("time", 0.0))
	for raw_selected in selected:
		var selected_candidate: Dictionary = raw_selected as Dictionary
		if absf(time - float(selected_candidate.get("time", 0.0))) < minimum_gap:
			return false
	return true

func _enforce_playability_v15(events: Array, bpm: float, profile: Dictionary) -> Array:
	if events.size() < 2:
		return events
	var result: Array = []
	var recent_times: Array[float] = []
	var fatigue_times: Array[float] = []
	var beat: float = 60.0 / maxf(1.0, bpm)
	var minimum_gap: float = maxf(float(profile.get("minimum_gap_seconds", 0.0)), beat * float(profile.get("minimum_gap_beats", 0.5)) * 0.90)
	var rapid_threshold: float = beat * float(profile.get("rapid_gap_beats", 0.55))
	var max_rapid_run: int = int(profile.get("max_rapid_run", 8))
	var max_window_hits: int = maxi(1, ceili(float(profile.get("max_notes_per_second", 5.0))))
	var max_four_second_hits: int = maxi(max_window_hits, int(profile.get("max_notes_per_4_seconds", max_window_hits * 4)))
	var rapid_run: int = 0
	var last_time: float = -999.0
	for raw_event in events:
		var event: Dictionary = raw_event as Dictionary
		var time: float = float(event.get("time", 0.0))
		if last_time > -900.0 and time - last_time < minimum_gap:
			continue
		while not recent_times.is_empty() and time - recent_times[0] >= 1.0:
			recent_times.pop_front()
		if recent_times.size() >= max_window_hits:
			continue
		while not fatigue_times.is_empty() and time - fatigue_times[0] >= 4.0:
			fatigue_times.pop_front()
		if fatigue_times.size() >= max_four_second_hits:
			continue
		if last_time > -900.0 and time - last_time <= rapid_threshold:
			rapid_run += 1
		else:
			rapid_run = 1
		if rapid_run > max_rapid_run:
			continue
		result.append(event)
		recent_times.append(time)
		fatigue_times.append(time)
		last_time = time
	return result

func _deterministic_noise_v15(noise_seed: int, primary: int, secondary: int) -> float:
	var value: float = absf(sin(float(abs(noise_seed) + 1) * 0.000137 + float(primary + 1) * 12.9898 + float(secondary + 1) * 78.233) * 43758.5453)
	return value - floorf(value)

func _generator_diagnostics_v15(events: Array, bpm: float, profile: Dictionary) -> Dictionary:
	var snapped_count: int = 0
	var snap_total_ms: float = 0.0
	var directions: Dictionary = {}
	var grams: Dictionary = {}
	var times: Array[float] = []
	for i in range(events.size()):
		var event: Dictionary = events[i] as Dictionary
		var snap_ms: float = absf(float(event.get("_snap_delta", 0.0))) * 1000.0
		if snap_ms >= 0.5:
			snapped_count += 1
			snap_total_ms += snap_ms
		var direction: int = int(event.get("direction", 0))
		directions[direction] = true
		times.append(float(event.get("time", 0.0)))
		if i >= 2:
			var d0: int = int((events[i - 2] as Dictionary).get("direction", 0))
			var d1: int = int((events[i - 1] as Dictionary).get("direction", 0))
			grams["%d-%d-%d" % [d0, d1, direction]] = true
	return {
		"version": "v15.0",
		"onset_snapped_notes": snapped_count,
		"average_onset_snap_ms": snappedf(snap_total_ms / float(maxi(1, snapped_count)), 0.01),
		"direction_count": directions.size(),
		"unique_three_note_cells": grams.size(),
		"three_note_cell_diversity": snappedf(float(grams.size()) / float(maxi(1, events.size() - 2)), 0.001),
		"peak_one_second_note_count": _peak_window_note_count_v15(times),
		"notes_per_second_cap": profile.get("max_notes_per_second", 5.0),
		"bpm": bpm,
	}

func _generator_diagnostics_v16(events: Array, phrases: Array, bpm: float, profile: Dictionary) -> Dictionary:
	for raw_phrase in phrases:
		if raw_phrase is Dictionary:
			(raw_phrase as Dictionary)["generated_note_count"] = 0
	var anchored_count: int = 0
	var snapped_count: int = 0
	var snap_total_ms: float = 0.0
	var directions: Dictionary = {}
	var grams: Dictionary = {}
	var times: Array[float] = []
	for i in range(events.size()):
		var event: Dictionary = events[i] as Dictionary
		var phrase_index: int = int(event.get("_phrase_index", -1))
		if phrase_index >= 0 and phrase_index < phrases.size() and phrases[phrase_index] is Dictionary:
			var phrase: Dictionary = phrases[phrase_index] as Dictionary
			phrase["generated_note_count"] = int(phrase.get("generated_note_count", 0)) + 1
		if bool(event.get("_onset_anchor", false)):
			anchored_count += 1
		var snap_ms: float = absf(float(event.get("_snap_delta", 0.0))) * 1000.0
		if snap_ms >= 0.5:
			snapped_count += 1
			snap_total_ms += snap_ms
		var direction: int = int(event.get("direction", 0))
		directions[direction] = true
		times.append(float(event.get("time", 0.0)))
		if i >= 2:
			var d0: int = int((events[i - 2] as Dictionary).get("direction", 0))
			var d1: int = int((events[i - 1] as Dictionary).get("direction", 0))
			grams["%d-%d-%d" % [d0, d1, direction]] = true
	var intensities: Array[float] = []
	var densities: Array[float] = []
	var peak_notes: int = 0
	var peak_beats: int = 0
	var calm_notes: int = 0
	var calm_beats: int = 0
	for raw_phrase in phrases:
		if not (raw_phrase is Dictionary):
			continue
		var phrase: Dictionary = raw_phrase as Dictionary
		var beat_count: int = maxi(1, int(phrase.get("beat_count", PHRASE_BEATS)))
		var note_count: int = int(phrase.get("generated_note_count", 0))
		var play_intensity: float = float(phrase.get("play_intensity", 0.5))
		intensities.append(play_intensity)
		densities.append(float(note_count) / float(beat_count))
		var zone: String = str(phrase.get("dynamic_zone", "groove"))
		if zone == "peak":
			peak_notes += note_count
			peak_beats += beat_count
		elif zone == "calm":
			calm_notes += note_count
			calm_beats += beat_count
	var peak_density: float = float(peak_notes) / float(maxi(1, peak_beats))
	var calm_density: float = float(calm_notes) / float(maxi(1, calm_beats))
	return {
		"version": "v16.9.1",
		"timing_policy": "grid_locked_onset_evidence",
		"onset_aligned_notes": anchored_count,
		"onset_alignment_share": snappedf(float(anchored_count) / float(maxi(1, events.size())), 0.001),
		"onset_alignment_target": profile.get("onset_priority_share", 0.40),
		"micro_snapped_notes": snapped_count,
		"average_onset_snap_ms": snappedf(snap_total_ms / float(maxi(1, snapped_count)), 0.01),
		"density_intensity_correlation": snappedf(_pearson_correlation_v16(intensities, densities), 0.001),
		"peak_note_density": snappedf(peak_density, 0.001),
		"calm_note_density": snappedf(calm_density, 0.001),
		"peak_to_calm_density_ratio": snappedf(peak_density / maxf(0.001, calm_density), 0.001),
		"peak_phrase_count": float(peak_beats) / float(PHRASE_BEATS),
		"calm_phrase_count": float(calm_beats) / float(PHRASE_BEATS),
		"direction_count": directions.size(),
		"unique_three_note_cells": grams.size(),
		"three_note_cell_diversity": snappedf(float(grams.size()) / float(maxi(1, events.size() - 2)), 0.001),
		"peak_one_second_note_count": _peak_window_note_count_v15(times),
		"notes_per_second_cap": profile.get("max_notes_per_second", 5.0),
		"bpm": bpm,
	}

func _pearson_correlation_v16(xs: Array[float], ys: Array[float]) -> float:
	var count: int = mini(xs.size(), ys.size())
	if count < 2:
		return 0.0
	var mean_x: float = 0.0
	var mean_y: float = 0.0
	for i in range(count):
		mean_x += xs[i]
		mean_y += ys[i]
	mean_x /= float(count)
	mean_y /= float(count)
	var covariance: float = 0.0
	var variance_x: float = 0.0
	var variance_y: float = 0.0
	for i in range(count):
		var dx: float = xs[i] - mean_x
		var dy: float = ys[i] - mean_y
		covariance += dx * dy
		variance_x += dx * dx
		variance_y += dy * dy
	if variance_x <= 0.000001 or variance_y <= 0.000001:
		return 0.0
	return clampf(covariance / sqrt(variance_x * variance_y), -1.0, 1.0)

func _peak_window_note_count_v15(times: Array[float]) -> int:
	var peak: int = 0
	var start_index: int = 0
	for end_index in range(times.size()):
		while start_index < end_index and times[end_index] - times[start_index] >= 1.0:
			start_index += 1
		peak = maxi(peak, end_index - start_index + 1)
	return peak

func _candidate_score_v16(role: String, beat_in_phrase: int, fraction: float, rhythmic_density: float, play_intensity: float, transition_rise: float, profile: Dictionary) -> float:
	var beat_in_bar: int = posmod(beat_in_phrase, BAR_BEATS)
	var score: float = play_intensity * 0.54
	if absf(fraction) <= 0.001:
		score += 0.74 if beat_in_bar == 0 else 0.36
	elif absf(fraction - 0.5) <= 0.001:
		score += 0.10 + rhythmic_density * 0.62
	else:
		score += float(profile.get("sixteenth_score_offset", -0.16)) + rhythmic_density * 0.72 + play_intensity * 0.48
	# Roles affect phrasing, but the maximum role bonus is deliberately much
	# smaller than a strong local onset.
	if beat_in_phrase == 0:
		match role:
			"chorus":
				score += 0.34
			"pre_chorus":
				score += 0.22
			"intro", "outro":
				score += 0.08
			_:
				score += 0.14
		score += transition_rise * 0.92
	return score

func _allow_sixteenth_candidate_v16(activity: float, rhythmic_density: float, drive_score: float, play_intensity: float, profile: Dictionary) -> bool:
	var mode: String = str(profile.get("sixteenth_mode", "none"))
	if mode == "legacy_hard":
		return true
	if mode != "payoff_only":
		return false
	var musical_drive: float = activity * 0.26 + rhythmic_density * 0.34 + drive_score * 0.40
	return play_intensity >= float(profile.get("sixteenth_min_intensity", 0.66)) and musical_drive >= float(profile.get("sixteenth_min_drive", 0.60))

func _candidate_score_v13_2(role: String, beat_in_phrase: int, fraction: float, activity: float, rhythmic_density: float, drive_score: float, chorus_score: float, arrangement_intensity: float, section_progress: float, profile: Dictionary) -> float:
	var beat_in_bar: int = posmod(beat_in_phrase, BAR_BEATS)
	var score: float = 0.0
	if is_equal_approx(fraction, 0.0):
		score += 2.45
		if beat_in_bar == 0:
			score += 1.65
		elif beat_in_bar == 2:
			score += 0.72
	elif is_equal_approx(fraction, 0.5):
		score += 0.72 + rhythmic_density * 1.82
	else:
		score += -0.12 + rhythmic_density * 2.15 + drive_score * 0.72
	match role:
		"chorus":
			score += 2.55 + chorus_score * 3.0 + arrangement_intensity * 0.9
			if not is_equal_approx(fraction, 0.0):
				score += 1.15
		"pre_chorus":
			score += 0.55 + clampf(section_progress, 0.0, 1.0) * 1.45
		"verse":
			score += 0.35 + activity * 0.35
		"bridge":
			score += 0.45 + drive_score * 0.55
		"interlude":
			score += 0.20 + rhythmic_density * 0.45
		"intro":
			score += 0.20 if is_equal_approx(fraction, 0.0) else -0.70
		"outro":
			score += 0.10 if is_equal_approx(fraction, 0.0) else -0.85

	# V15 keeps sixteenths difficulty-gated: Hard gets short payoff bursts while
	# Master may follow them throughout active phrases, still subject to NPS and
	# rapid-stream caps.
	if fraction in [0.25, 0.75]:
		var threshold: float = float(profile.get("sixteenth_bias_threshold", 0.56))
		var bias_scale: float = float(profile.get("sixteenth_bias_scale", 0.72))
		score += maxf(0.0, arrangement_intensity - threshold) * bias_scale
		score += float(profile.get("sixteenth_score_offset", 0.0))
	return score

func _allow_sixteenth_candidate_v13_2(role: String, activity: float, rhythmic_density: float, drive_score: float, arrangement_intensity: float, profile: Dictionary) -> bool:
	var mode: String = str(profile.get("sixteenth_mode", "none"))
	if mode == "legacy_hard":
		# This reproduces the previous HARD candidate space. It is now MASTER.
		return true
	if mode != "payoff_only":
		return false
	if role not in ["chorus", "pre_chorus"]:
		return false
	var musical_drive: float = activity * 0.28 + rhythmic_density * 0.34 + drive_score * 0.38
	return arrangement_intensity >= float(profile.get("sixteenth_min_arrangement", 0.78)) and musical_drive >= float(profile.get("sixteenth_min_drive", 0.64))

func _target_notes_v11(phrase: Dictionary, beat_count: int, candidate_count: int, profile: Dictionary) -> int:
	var role: String = str(phrase.get("role", "verse"))
	var arrangement_intensity: float = clampf(float(phrase.get("arrangement_intensity", 0.5)), 0.0, 1.0)
	var activity: float = clampf(float(phrase.get("activity", 0.5)), 0.0, 1.0)
	var rhythmic_density: float = clampf(float(phrase.get("rhythmic_density", activity)), 0.0, 1.0)
	var drive_score: float = clampf(float(phrase.get("drive_score", activity)), 0.0, 1.0)
	var chorus_score: float = clampf(float(phrase.get("chorus_score", 0.0)), 0.0, 1.0)
	var micro_drive: float = clampf(activity * 0.40 + rhythmic_density * 0.30 + drive_score * 0.30, 0.0, 1.0)
	var density: float = float(profile.get("verse_npb", 0.7))
	match role:
		"intro":
			density = float(profile.get("intro_npb", 0.34)) * lerpf(0.88, 1.08, micro_drive)
		"verse":
			density = float(profile.get("verse_npb", 0.70)) * lerpf(0.88, 1.14, micro_drive)
		"pre_chorus":
			var structural_ramp: float = clampf((arrangement_intensity - 0.56) / 0.23, 0.0, 1.0)
			var phrase_progress: float = clampf(float(phrase.get("section_progress", 0.5)), 0.0, 1.0)
			var progress: float = maxf(structural_ramp, phrase_progress * 0.82)
			density = lerpf(float(profile.get("pre_chorus_start_npb", 0.82)), float(profile.get("pre_chorus_end_npb", 1.12)), progress)
			density *= lerpf(0.94, 1.08, micro_drive)
		"chorus":
			density = float(profile.get("chorus_npb", 1.35)) * lerpf(0.98, 1.10, maxf(chorus_score, arrangement_intensity))
		"bridge":
			density = float(profile.get("bridge_npb", 0.82)) * lerpf(0.88, 1.14, micro_drive)
		"interlude":
			density = float(profile.get("interlude_npb", 0.66)) * lerpf(0.86, 1.16, micro_drive)
		"outro":
			density = float(profile.get("outro_npb", 0.30)) * lerpf(0.84, 1.04, micro_drive) * lerpf(1.0, 0.70, clampf(float(phrase.get("section_progress", 0.5)), 0.0, 1.0))
		_:
			density = float(profile.get("verse_npb", 0.70)) * lerpf(0.90, 1.12, arrangement_intensity)
	var target: int = int(round(float(maxi(1, beat_count)) * density))
	return clampi(target, 0, candidate_count)

func _stable_chart_seed_v15(chart: Dictionary, difficulty_id: String) -> int:
	var source: String = "%s|%s|%s|%s" % [
		str(chart.get("song_id", chart.get("id", "song"))),
		str(chart.get("title", "")),
		difficulty_id.to_lower(),
		str(chart.get("seed", 0)),
	]
	var seed_value: int = 104729
	for i in range(source.length()):
		seed_value = posmod(seed_value * 131 + source.unicode_at(i), 2147483629)
	return maxi(1, seed_value)

func _assign_musical_directions_v15(events: Array, difficulty_id: String, bpm: float, generation_seed: int, preserve_existing: bool = false) -> void:
	if events.is_empty():
		return
	var beat: float = 60.0 / maxf(1.0, bpm)
	var flow_gap_seconds: float = beat * _direction_flow_gap_beats_v12(difficulty_id)
	var history: Array[int] = []
	var gram_counts: Dictionary = {}
	var direction_counts: Dictionary = {}
	var active_finger: int = 0
	var previous_time: float = -999.0
	var previous_phrase_key: String = ""
	var phrase_seed: int = generation_seed
	for i in range(events.size()):
		var raw_event: Variant = events[i]
		if not (raw_event is Dictionary):
			continue
		var event: Dictionary = raw_event as Dictionary
		var time: float = float(event.get("time", 0.0))
		var phrase_index: int = int(event.get("_phrase_index", 0))
		var section_index: int = int(event.get("_section_index", 0))
		var phrase_key: String = "%d:%d" % [section_index, phrase_index]
		if phrase_key != previous_phrase_key:
			phrase_seed = posmod(generation_seed + (phrase_index + 1) * 1103515245 + (section_index + 7) * 12345 + int(round(time * 1000.0)), 2147483629)
			previous_phrase_key = phrase_key
		var continuous_flow: bool = previous_time > -900.0 and time - previous_time <= flow_gap_seconds
		if continuous_flow:
			active_finger = 1 - active_finger
		else:
			active_finger = posmod(phrase_seed + i * 17, 2)
		var existing_direction: int = int(event.get("direction", 0))
		var direction: int = existing_direction
		if not preserve_existing or existing_direction not in VALID_DIRECTION_KEYS:
			direction = _choose_musical_direction_v15(event, history, gram_counts, direction_counts, active_finger, phrase_seed, i)
		event["direction"] = direction
		event["_finger"] = active_finger
		_update_direction_memory_v15(history, gram_counts, direction_counts, direction)
		previous_time = time

func _choose_musical_direction_v15(event: Dictionary, history: Array[int], gram_counts: Dictionary, direction_counts: Dictionary, finger: int, phrase_seed: int, event_index: int) -> int:
	var pool_value: Variant = TWO_FINGER_LEFT_KEYS if finger == 0 else TWO_FINGER_RIGHT_KEYS
	var pool: Array = pool_value as Array
	var best_direction: int = int(pool[0])
	var best_score: float = -999999.0
	var strength: float = clampf(float(event.get("_strength", 0.5)), 0.0, 1.0)
	var fraction: float = float(event.get("_fraction", float(event.get("_subdivision", 0)) / 4.0))
	var role: String = str(event.get("_role", "verse"))
	var pattern_family: String = str(event.get("_pattern_family", "pulse"))
	var signature_pattern_id: int = int(event.get("_signature_pattern_id", 0))
	var beat_in_phrase: int = int(event.get("_beat_in_phrase", 0))
	var subdivision: int = int(event.get("_subdivision", 0))
	var n: int = history.size()
	for raw_direction in pool:
		var direction: int = int(raw_direction)
		var score: float = _deterministic_noise_v15(phrase_seed, event_index + 1, direction) * 1.55
		score += _direction_pattern_bonus_v169(direction, pattern_family, signature_pattern_id, beat_in_phrase, subdivision)
		var is_corner: bool = direction in [1, 3, 7, 9]
		var is_center: bool = direction in [2, 8]
		var recent_count: int = _recent_direction_count_v15(history, direction, 16)
		score -= float(recent_count) * 0.52
		score -= float(direction_counts.get(direction, 0)) * 0.018
		if strength >= 0.74:
			score += 0.72 if is_corner else -0.08
		elif fraction > 0.0:
			score += 0.28 if not is_corner else 0.0
		if role == "chorus" and is_corner:
			score += 0.26
		elif role in ["intro", "outro"] and is_center:
			score += 0.22
		if n >= 1:
			var previous: int = history[n - 1]
			if direction == previous:
				score -= 1000.0
			if direction in [2, 8] and previous in [2, 8]:
				score -= 4.0
			var distance: float = _direction_vector_v15(direction).distance_to(_direction_vector_v15(previous))
			var preferred_distance: float = lerpf(0.78, 1.65, strength)
			score -= absf(distance - preferred_distance) * 0.34
		if n >= 2:
			var same_finger_previous: int = history[n - 2]
			if direction == same_finger_previous:
				score -= 0.78
			else:
				var same_finger_distance: float = _direction_vector_v15(direction).distance_to(_direction_vector_v15(same_finger_previous))
				score += minf(same_finger_distance, 1.5) * 0.18
		if _completes_two_key_loop_v15(history, direction):
			score -= 1000.0
		if _continues_compass_orbit_v17451(history, direction):
			score -= 1000.0
		for block_size in range(3, 9):
			if _repeats_recent_block_v15(history, direction, block_size):
				score -= 1000.0
		for gram_size in range(2, 5):
			if n + 1 < gram_size:
				continue
			var gram_key: String = _direction_gram_key_v15(history, direction, gram_size)
			var occurrence: int = int(gram_counts.get(gram_key, 0))
			var penalty_scale: float = 0.55 if gram_size == 2 else (1.55 if gram_size == 3 else 3.1)
			score -= float(occurrence) * penalty_scale
		if score > best_score:
			best_score = score
			best_direction = direction
	return best_direction

func _update_direction_memory_v15(history: Array[int], gram_counts: Dictionary, direction_counts: Dictionary, direction: int) -> void:
	for gram_size in range(2, 5):
		if history.size() + 1 < gram_size:
			continue
		var gram_key: String = _direction_gram_key_v15(history, direction, gram_size)
		gram_counts[gram_key] = int(gram_counts.get(gram_key, 0)) + 1
	history.append(direction)
	direction_counts[direction] = int(direction_counts.get(direction, 0)) + 1

func _direction_gram_key_v15(history: Array[int], candidate: int, gram_size: int) -> String:
	var parts: PackedStringArray = PackedStringArray()
	var previous_count: int = gram_size - 1
	var start_index: int = maxi(0, history.size() - previous_count)
	for i in range(start_index, history.size()):
		parts.append(str(history[i]))
	parts.append(str(candidate))
	return "-".join(parts)

func _recent_direction_count_v15(history: Array[int], direction: int, lookback: int) -> int:
	var count: int = 0
	for i in range(maxi(0, history.size() - lookback), history.size()):
		if history[i] == direction:
			count += 1
	return count

func _completes_two_key_loop_v15(history: Array[int], candidate: int) -> bool:
	var n: int = history.size()
	if n < 5:
		return false
	return history[n - 5] == history[n - 3] and history[n - 3] == history[n - 1] and history[n - 4] == history[n - 2] and candidate == history[n - 4] and history[n - 5] != history[n - 4]

func _continues_compass_orbit_v17451(history: Array[int], candidate: int) -> bool:
	# Prevent four-note-or-longer clockwise/counter-clockwise perimeter walks.
	# Ring order follows numpad geometry around the outside edge.
	var ring: Array[int] = [8, 9, 6, 3, 2, 1, 4, 7]
	if history.size() < 3:
		return false
	var sequence: Array[int] = [history[history.size() - 3], history[history.size() - 2], history[history.size() - 1], candidate]
	var step_direction := 0
	for i in range(sequence.size() - 1):
		var a := ring.find(sequence[i])
		var b := ring.find(sequence[i + 1])
		if a < 0 or b < 0:
			return false
		var raw := posmod(b - a, ring.size())
		var step := 1 if raw == 1 else (-1 if raw == ring.size() - 1 else 0)
		if step == 0:
			return false
		if step_direction == 0:
			step_direction = step
		elif step != step_direction:
			return false
	return true

func _repeats_recent_block_v15(history: Array[int], candidate: int, block_size: int) -> bool:
	var n: int = history.size()
	if n + 1 < block_size * 2:
		return false
	var completed: Array[int] = history.duplicate()
	completed.append(candidate)
	var total: int = completed.size()
	for offset in range(block_size):
		if completed[total - block_size * 2 + offset] != completed[total - block_size + offset]:
			return false
	return true

func _direction_vector_v15(direction: int) -> Vector2:
	match direction:
		1: return Vector2(-0.72, 0.72)
		2: return Vector2(0.0, 1.0)
		3: return Vector2(0.72, 0.72)
		4: return Vector2(-1.0, 0.0)
		6: return Vector2(1.0, 0.0)
		7: return Vector2(-0.72, -0.72)
		8: return Vector2(0.0, -1.0)
		9: return Vector2(0.72, -0.72)
	return Vector2.ZERO

func author_legacy_directions(chart: Dictionary) -> Dictionary:
	var result: Dictionary = chart.duplicate(true)
	var events_value: Variant = result.get("events", [])
	if not (events_value is Array):
		return result
	var events: Array = events_value as Array
	var missing_count: int = 0
	for raw_event in events:
		if raw_event is Dictionary and int((raw_event as Dictionary).get("direction", 0)) not in VALID_DIRECTION_KEYS:
			missing_count += 1
	# Generator revision is not a reason to rewrite valid authored directions.
	# Only charts that actually lack a valid direction are upgraded at runtime.
	if missing_count <= 0:
		return result
	var bundled_legacy_chart := false
	var bpm: float = float(result.get("bpm", 120.0))
	var beat_offset: float = float(result.get("beat_offset", 0.0))
	var sections_value: Variant = result.get("sections", [])
	var legacy_sections: Array = []
	if sections_value is Array:
		legacy_sections = sections_value as Array
	_seed_legacy_generation_fields_v15(events, bpm, beat_offset, legacy_sections)
	var difficulty_id: String = str(result.get("chart_difficulty", result.get("difficulty", "normal"))).to_lower()
	_assign_musical_directions_v15(events, difficulty_id, bpm, _stable_chart_seed_v15(result, difficulty_id), not bundled_legacy_chart)
	_strip_generation_fields_v10(events)
	result["events"] = events
	result["runtime_directions"] = false
	result["authored_directions"] = true
	result["legacy_direction_upgrade"] = {
		"version": "musical_two_finger_choreography_v15",
		"filled": missing_count,
		"replaced": 0,
		"runtime_only": true,
	}
	return result

func _seed_legacy_generation_fields_v15(events: Array, bpm: float, beat_offset: float, sections: Array) -> void:
	var beat: float = 60.0 / maxf(1.0, bpm)
	for raw_event in events:
		if not (raw_event is Dictionary):
			continue
		var event: Dictionary = raw_event as Dictionary
		var time: float = float(event.get("time", 0.0))
		var beat_position: float = maxf(0.0, (time - beat_offset) / beat)
		var beat_index: int = floori(beat_position)
		var fraction: float = snappedf(beat_position - float(beat_index), 0.25)
		var section_info: Dictionary = _section_info_at_time_v15(sections, time)
		event["_phrase_index"] = floori(float(beat_index) / float(PHRASE_BEATS))
		event["_section_index"] = int(section_info.get("index", 0))
		event["_beat_in_phrase"] = posmod(beat_index, PHRASE_BEATS)
		event["_subdivision"] = int(round(fraction * 4.0))
		event["_fraction"] = fraction
		event["_role"] = str(section_info.get("role", "verse"))
		event["_strength"] = 0.78 if is_equal_approx(fraction, 0.0) else 0.48

func _section_info_at_time_v15(sections: Array, time: float) -> Dictionary:
	for i in range(sections.size()):
		var raw_section: Variant = sections[i]
		if not (raw_section is Dictionary):
			continue
		var section: Dictionary = raw_section as Dictionary
		if time >= float(section.get("start", 0.0)) and time < float(section.get("end", 999999.0)):
			return {"index": i, "role": _role_from_section_v10(section)}
	return {"index": 0, "role": "verse"}

func _assign_two_finger_directions_v12(events: Array, difficulty_id: String, bpm: float) -> void:
	if events.is_empty():
		return
	var beat: float = 60.0 / maxf(1.0, bpm)
	var flow_gap_beats: float = 1.22
	match difficulty_id.to_lower():
		"hard":
			flow_gap_beats = 1.26
		"master":
			flow_gap_beats = 1.32
	var flow_gap_seconds: float = beat * flow_gap_beats
	var history: Array[int] = []
	var active_finger: int = 0
	var previous_time: float = -999.0
	var previous_phrase_key: String = ""
	var phrase_seed: int = abs(difficulty_id.hash()) + 17

	for i in range(events.size()):
		var raw_event: Variant = events[i]
		if not (raw_event is Dictionary):
			continue
		var event: Dictionary = raw_event as Dictionary
		var time: float = float(event.get("time", 0.0))
		var phrase_index: int = int(event.get("_phrase_index", 0))
		var section_index: int = int(event.get("_section_index", 0))
		var phrase_key: String = "%d:%d" % [section_index, phrase_index]
		if phrase_key != previous_phrase_key:
			phrase_seed = abs((phrase_index + 1) * 1103515245 + (section_index + 7) * 12345 + difficulty_id.hash())
			previous_phrase_key = phrase_key

		var continuous_flow: bool = previous_time > -900.0 and time - previous_time <= flow_gap_seconds
		if continuous_flow:
			active_finger = 1 - active_finger
		else:
			# A musical rest resets fingering. The start finger is deterministic but
			# changes from phrase to phrase so every section does not begin identically.
			active_finger = posmod(phrase_seed + i * 17, 2)

		var direction: int = _choose_two_finger_direction_v12(event, history, active_finger, phrase_seed, i)
		event["direction"] = direction
		event["type"] = "normal"
		event["_finger"] = active_finger
		history.append(direction)
		if history.size() > 12:
			history.pop_front()
		previous_time = time

func _choose_two_finger_direction_v12(event: Dictionary, history: Array[int], finger: int, phrase_seed: int, event_index: int) -> int:
	var pool_value: Variant = TWO_FINGER_LEFT_KEYS if finger == 0 else TWO_FINGER_RIGHT_KEYS
	var pool: Array = pool_value as Array
	var best_direction: int = int(pool[0])
	var best_score: float = -999999.0
	for raw_direction in pool:
		var direction: int = int(raw_direction)
		var score: float = _two_finger_noise_v12(phrase_seed, event_index, direction) * 2.0
		var strength: float = clampf(float(event.get("_strength", 0.5)), 0.0, 1.0)
		var subdivision: int = int(event.get("_subdivision", 0))

		# Strong accents may reach to the outer corners; subdivisions get a mild
		# preference for center keys. These are soft musical biases, not motifs.
		if strength >= 0.72:
			if finger == 0 and direction in [7, 1]:
				score += 0.65
			elif finger == 1 and direction in [9, 3]:
				score += 0.65
		if subdivision > 0 and direction in [2, 8]:
			score += 0.18

		var n: int = history.size()
		if n >= 1 and direction == history[n - 1]:
			# Immediate repeats are possible to execute with two fingers, but they do
			# not communicate the alternating flow this generator is designed for.
			score -= 1000.0
		if n >= 2 and direction == history[n - 2]:
			# Let one finger keep an anchor for a couple of hits; this is ergonomic.
			score += 0.42
		if _history_contains_recent_v12(history, direction, 4):
			score -= 0.55
		else:
			score += 0.75

		# Do not let two stable finger anchors turn into 4-6-4-6 / 7-9-7-9 spam.
		if n >= 5:
			var completes_two_key_loop: bool = (
				history[n - 5] == history[n - 3]
				and history[n - 3] == history[n - 1]
				and history[n - 4] == history[n - 2]
				and direction == history[n - 4]
				and history[n - 5] != history[n - 4]
			)
			if completes_two_key_loop:
				score -= 1000.0

		# A four-note phrase may recur later in a song, but it should not be stamped
		# twice back-to-back (e.g. 3-7-9-1 / 3-7-9-1).
		if n >= 7:
			var repeats_previous_four: bool = (
				history[n - 7] == history[n - 3]
				and history[n - 6] == history[n - 2]
				and history[n - 5] == history[n - 1]
				and history[n - 4] == direction
			)
			if repeats_previous_four:
				score -= 1000.0

		# Softer penalty for immediately repeating a three-note cell. This keeps
		# generated phrases varied without introducing an arbitrary pattern bank.
		if n >= 5:
			var repeats_previous_three: bool = (
				history[n - 5] == history[n - 2]
				and history[n - 4] == history[n - 1]
				and history[n - 3] == direction
			)
			if repeats_previous_three:
				score -= 7.0

		if score > best_score:
			best_score = score
			best_direction = direction
	return best_direction

func _history_contains_recent_v12(history: Array[int], direction: int, lookback: int) -> bool:
	var start_index: int = maxi(0, history.size() - lookback)
	for i in range(start_index, history.size()):
		if history[i] == direction:
			return true
	return false

func _two_finger_noise_v12(noise_seed: int, event_index: int, direction: int) -> float:
	# Deterministic pseudo-random tiebreaker. This creates variety without Random
	# Mode and without storing a library of visible direction sequences.
	var value: float = absf(sin(float(noise_seed) * 0.000173 + float(event_index + 1) * 12.9898 + float(direction) * 78.233) * 43758.5453)
	return value - floorf(value)

func _direction_side_v12(direction: int) -> int:
	if direction in STRICT_LEFT_KEYS:
		return -1
	if direction in STRICT_RIGHT_KEYS:
		return 1
	return 0

func _direction_flow_gap_beats_v12(difficulty_id: String) -> float:
	match difficulty_id.to_lower():
		"hard":
			return 1.26
		"master":
			return 1.32
	return 1.22

func _validate_two_finger_flow_v12(events: Array, bpm: float, difficulty_id: String) -> Dictionary:
	if events.size() < 2:
		return {"ok": true}
	var beat: float = 60.0 / maxf(1.0, bpm)
	var max_gap: float = beat * _direction_flow_gap_beats_v12(difficulty_id)
	for i in range(1, events.size()):
		var previous: Dictionary = events[i - 1] as Dictionary
		var current: Dictionary = events[i] as Dictionary
		var gap: float = float(current.get("time", 0.0)) - float(previous.get("time", 0.0))
		if gap > max_gap:
			continue
		var previous_direction: int = int(previous.get("direction", 0))
		var current_direction: int = int(current.get("direction", 0))
		if previous_direction == current_direction:
			return {"ok": false, "error": "Two-finger flow repeated the same key in a continuous phrase near event %d." % i}
		var previous_side: int = _direction_side_v12(previous_direction)
		var current_side: int = _direction_side_v12(current_direction)
		if previous_side != 0 and previous_side == current_side:
			return {"ok": false, "error": "Two-finger flow stayed on the same strict side near event %d." % i}

	for i in range(5, events.size()):
		if not _events_are_continuous_v12(events, i - 5, i, max_gap):
			continue
		var d0: int = int((events[i - 5] as Dictionary).get("direction", 0))
		var d1: int = int((events[i - 4] as Dictionary).get("direction", 0))
		var d2: int = int((events[i - 3] as Dictionary).get("direction", 0))
		var d3: int = int((events[i - 2] as Dictionary).get("direction", 0))
		var d4: int = int((events[i - 1] as Dictionary).get("direction", 0))
		var d5: int = int((events[i] as Dictionary).get("direction", 0))
		if d0 == d2 and d2 == d4 and d1 == d3 and d3 == d5 and d0 != d1:
			return {"ok": false, "error": "Two-key alternation loop survived near event %d." % i}

	for i in range(7, events.size()):
		if not _events_are_continuous_v12(events, i - 7, i, max_gap):
			continue
		var repeated_block: bool = true
		for offset in range(4):
			var first_direction: int = int((events[i - 7 + offset] as Dictionary).get("direction", 0))
			var second_direction: int = int((events[i - 3 + offset] as Dictionary).get("direction", 0))
			if first_direction != second_direction:
				repeated_block = false
				break
		if repeated_block:
			return {"ok": false, "error": "Repeated four-note direction block survived near event %d." % i}
	return {"ok": true}

func _validate_playability_v15(events: Array, bpm: float, difficulty_id: String) -> Dictionary:
	if events.size() < 2:
		return {"ok": true}
	var profile: Dictionary = _difficulty_profile_v10(difficulty_id)
	var beat: float = 60.0 / maxf(1.0, bpm)
	var minimum_gap: float = beat * float(profile.get("minimum_gap_beats", 0.5)) * 0.86
	var rapid_threshold: float = beat * float(profile.get("rapid_gap_beats", 0.55))
	var max_rapid_run: int = int(profile.get("max_rapid_run", 8))
	var max_window_hits: int = maxi(1, ceili(float(profile.get("max_notes_per_second", 5.0))))
	var max_four_second_hits: int = maxi(max_window_hits, int(profile.get("max_notes_per_4_seconds", max_window_hits * 4)))
	var rapid_run: int = 1
	var recent_times: Array[float] = []
	var fatigue_times: Array[float] = []
	for i in range(events.size()):
		var event: Dictionary = events[i] as Dictionary
		var time: float = float(event.get("time", 0.0))
		if i > 0:
			var previous: Dictionary = events[i - 1] as Dictionary
			var gap: float = time - float(previous.get("time", 0.0))
			if gap < minimum_gap:
				return {"ok": false, "error": "%s chart has an impossible %.1f ms gap near event %d." % [difficulty_id.to_upper(), gap * 1000.0, i]}
			if gap <= rapid_threshold:
				rapid_run += 1
			else:
				rapid_run = 1
			if rapid_run > max_rapid_run:
				return {"ok": false, "error": "%s chart exceeds its rapid-stream limit near event %d." % [difficulty_id.to_upper(), i]}
		while not recent_times.is_empty() and time - recent_times[0] >= 1.0:
			recent_times.pop_front()
		if recent_times.size() >= max_window_hits:
			return {"ok": false, "error": "%s chart exceeds its notes-per-second cap near event %d." % [difficulty_id.to_upper(), i]}
		recent_times.append(time)
		while not fatigue_times.is_empty() and time - fatigue_times[0] >= 4.0:
			fatigue_times.pop_front()
		if fatigue_times.size() >= max_four_second_hits:
			return {"ok": false, "error": "%s chart exceeds its four-second fatigue budget near event %d." % [difficulty_id.to_upper(), i]}
		fatigue_times.append(time)
	return {"ok": true}

func _events_are_continuous_v12(events: Array, start_index: int, end_index: int, max_gap: float) -> bool:
	for i in range(start_index + 1, end_index + 1):
		var previous: Dictionary = events[i - 1] as Dictionary
		var current: Dictionary = events[i] as Dictionary
		if float(current.get("time", 0.0)) - float(previous.get("time", 0.0)) > max_gap:
			return false
	return true

func _strip_generation_fields_v10(events: Array) -> void:
	for raw_event in events:
		if not (raw_event is Dictionary):
			continue
		var event: Dictionary = raw_event as Dictionary
		for key in ["_strength", "_onset_strength", "_onset_contrast", "_onset_anchor", "_snap_delta", "_play_intensity", "_phrase_index", "_section_index", "_beat_in_phrase", "_subdivision", "_fraction", "_role", "_refrain_score", "_chorus_score", "_finger", "_pattern_family", "_signature_pattern_id", "_phrase_arc", "_timing_confidence", "_difficulty_pressure", "_difficulty_stage"]:
			event.erase(key)

func _deduplicate_events_v10(events: Array) -> Array:
	var result: Array = []
	var last_time: float = -999.0
	for raw_event in events:
		if not (raw_event is Dictionary):
			continue
		var event: Dictionary = raw_event as Dictionary
		var time: float = float(event.get("time", 0.0))
		if absf(time - last_time) <= 0.00001:
			continue
		result.append(event)
		last_time = time
	return result

func _time_near_space_v10(time: float, spaces: Array[float], clearance: float) -> bool:
	for space_time in spaces:
		if absf(time - space_time) <= clearance:
			return true
	return false

func _musical_strength_v10(energy: Array[float], onset: Array[float], hop_seconds: float, time: float, beat: float) -> float:
	var onset_peak: float = _sample_peak(onset, hop_seconds, time, beat * 0.16)
	var onset_mean: float = _sample_mean(onset, hop_seconds, time, beat * 0.34)
	var energy_value: float = _sample_curve(energy, hop_seconds, time)
	return clampf(onset_peak * 0.58 + onset_mean * 0.18 + energy_value * 0.24, 0.0, 1.0)

func _sort_score_descending_v10(a: Variant, b: Variant) -> bool:
	if not (a is Dictionary) or not (b is Dictionary):
		return false
	var score_a: float = float((a as Dictionary).get("score", 0.0))
	var score_b: float = float((b as Dictionary).get("score", 0.0))
	if absf(score_a - score_b) <= 0.000001:
		return float((a as Dictionary).get("time", 0.0)) < float((b as Dictionary).get("time", 0.0))
	return score_a > score_b

func _sort_time_ascending_v10(a: Variant, b: Variant) -> bool:
	if not (a is Dictionary) or not (b is Dictionary):
		return false
	return float((a as Dictionary).get("time", 0.0)) < float((b as Dictionary).get("time", 0.0))

func _export_phrase_map_v10(phrases: Array) -> Array:
	var result: Array = []
	for raw_phrase in phrases:
		if not (raw_phrase is Dictionary):
			continue
		var phrase: Dictionary = raw_phrase as Dictionary
		result.append({
			"start": phrase.get("start", 0.0),
			"end": phrase.get("end", 0.0),
			"role": phrase.get("role", "verse"),
			"intensity": phrase.get("intensity", "medium"),
			"arrangement_intensity": phrase.get("arrangement_intensity", 0.5),
			"audio_intensity": phrase.get("audio_intensity", phrase.get("activity", 0.5)),
			"play_intensity": phrase.get("play_intensity", phrase.get("activity", 0.5)),
			"dynamic_zone": phrase.get("dynamic_zone", "groove"),
			"phrase_arc": phrase.get("phrase_arc", "groove"),
			"density_multiplier": phrase.get("density_multiplier", 1.0),
			"pre_climax_breath": phrase.get("pre_climax_breath", false),
			"pattern_family": phrase.get("pattern_family", "pulse"),
			"difficulty_pressure": phrase.get("difficulty_pressure", 0.5),
			"difficulty_density_multiplier": phrase.get("difficulty_density_multiplier", 1.0),
			"difficulty_stage": phrase.get("difficulty_stage", "develop"),
			"section_occurrence": phrase.get("section_occurrence", 1),
			"section_occurrence_count": phrase.get("section_occurrence_count", 1),
			"musical_climax": phrase.get("musical_climax", false),
			"signature_pattern_id": phrase.get("signature_pattern_id", 0),
			"peak_override": phrase.get("peak_override", false),
			"calm_cap": phrase.get("calm_cap", false),
			"activity": phrase.get("activity", 0.5),
			"rhythmic_density": phrase.get("rhythmic_density", 0.5),
			"drive_score": phrase.get("drive_score", 0.5),
			"chorus_score": phrase.get("chorus_score", 0.0),
			"global_repeat_score": phrase.get("global_repeat_score", 0.0),
			"section_index": phrase.get("section_index", 0),
			"section_progress": phrase.get("section_progress", 0.0),
			"target_note_count": phrase.get("target_note_count", 0),
			"generated_note_count": phrase.get("generated_note_count", 0),
		})
	return result

func _difficulty_profile_v10(difficulty_id: String) -> Dictionary:
	match difficulty_id.to_lower():
		"hard":
			# Hard introduces short sixteenth bursts whenever local audio intensity
			# reaches a payoff, independent of the section label.
			return {
				"grid_division": 4,
				"minimum_npb": 0.34,
				"maximum_npb": 1.78,
				"peak_minimum_npb": 1.34,
				"calm_maximum_npb": 0.72,
				"density_curve": 1.08,
				"intro_npb": 0.38,
				"verse_npb": 0.80,
				"pre_chorus_start_npb": 0.98,
				"pre_chorus_end_npb": 1.32,
				"chorus_npb": 1.76,
				"bridge_npb": 0.99,
				"interlude_npb": 0.79,
				"outro_npb": 0.36,
				"space_beats_per_event": 42.0,
				"space_min_gap_beats": 9.0,
				"space_note_clearance_beats": 0.16,
				"lead_in_bars": 1,
				"sixteenth_mode": "payoff_only",
				"sixteenth_min_intensity": 0.64,
				"sixteenth_min_drive": 0.60,
				"sixteenth_bias_threshold": 0.72,
				"sixteenth_bias_scale": 0.42,
				"sixteenth_score_offset": -0.18,
				"minimum_gap_beats": 0.25,
				"minimum_gap_seconds": 0.14,
				"rapid_gap_beats": 0.31,
				"max_rapid_run": 12,
				"max_notes_per_second": 8.0,
				"max_notes_per_4_seconds": 27,
				"max_notes_per_bar": 10,
				"onset_priority_share": 0.46,
				"onset_anchor_bonus": 1.15,
				"onset_anchor_min_strength": 0.24,
				"onset_snap_window_beats": 0.095,
				"onset_snap_min_gain": 0.020,
				"onset_snap_min_contrast": 0.028,
				"onset_distance_penalty": 0.12,
				"rhythm_variation": 0.92,
				"previous_bar_slot_penalty": 0.94,
				"pattern_slot_bonus": 0.42,
				"pre_climax_rest_beats": 0.50,
				"triplet_min_pressure": 0.68,
				"triplet_onset_threshold": 0.50,
				"triplet_evidence_margin": 0.10,
			}
		"master":
			# Master exposes the full quarter-beat candidate grid, then uses speed
			# and burst caps to keep the final stream demanding but executable.
			return {
				"grid_division": 4,
				"minimum_npb": 0.42,
				"maximum_npb": 2.20,
				"peak_minimum_npb": 1.70,
				"calm_maximum_npb": 0.90,
				"density_curve": 1.05,
				"intro_npb": 0.46,
				"verse_npb": 0.98,
				"pre_chorus_start_npb": 1.20,
				"pre_chorus_end_npb": 1.62,
				"chorus_npb": 2.18,
				"bridge_npb": 1.22,
				"interlude_npb": 0.98,
				"outro_npb": 0.44,
				"space_beats_per_event": 38.0,
				"space_min_gap_beats": 8.0,
				"space_note_clearance_beats": 0.15,
				"lead_in_bars": 1,
				"sixteenth_mode": "legacy_hard",
				"sixteenth_bias_threshold": 0.56,
				"sixteenth_bias_scale": 0.72,
				"sixteenth_score_offset": 0.0,
				"minimum_gap_beats": 0.25,
				"minimum_gap_seconds": 0.10,
				"rapid_gap_beats": 0.28,
				"max_rapid_run": 20,
				"max_notes_per_second": 10.5,
				"max_notes_per_4_seconds": 36,
				"max_notes_per_bar": 13,
				"onset_priority_share": 0.54,
				"onset_anchor_bonus": 1.30,
				"onset_anchor_min_strength": 0.22,
				"onset_snap_window_beats": 0.090,
				"onset_snap_min_gain": 0.018,
				"onset_snap_min_contrast": 0.024,
				"onset_distance_penalty": 0.13,
				"rhythm_variation": 1.06,
				"previous_bar_slot_penalty": 1.05,
				"pattern_slot_bonus": 0.52,
				"pre_climax_rest_beats": 0.34,
				"triplet_min_pressure": 0.60,
				"triplet_onset_threshold": 0.44,
				"triplet_evidence_margin": 0.07,
			}
		_:
			return {
				"grid_division": 2,
				"minimum_npb": 0.24,
				"maximum_npb": 1.36,
				"peak_minimum_npb": 1.05,
				"calm_maximum_npb": 0.54,
				"density_curve": 1.10,
				"intro_npb": 0.30,
				"verse_npb": 0.62,
				"pre_chorus_start_npb": 0.78,
				"pre_chorus_end_npb": 1.04,
				"chorus_npb": 1.38,
				"bridge_npb": 0.76,
				"interlude_npb": 0.60,
				"outro_npb": 0.28,
				"space_beats_per_event": 46.0,
				"space_min_gap_beats": 10.0,
				"space_note_clearance_beats": 0.18,
				"lead_in_bars": 1,
				"sixteenth_mode": "none",
				"minimum_gap_beats": 0.50,
				"minimum_gap_seconds": 0.22,
				"rapid_gap_beats": 0.55,
				"max_rapid_run": 8,
				"max_notes_per_second": 5.2,
				"max_notes_per_4_seconds": 17,
				"max_notes_per_bar": 7,
				"onset_priority_share": 0.38,
				"onset_anchor_bonus": 1.00,
				"onset_anchor_min_strength": 0.26,
				"onset_snap_window_beats": 0.105,
				"onset_snap_min_gain": 0.022,
				"onset_snap_min_contrast": 0.032,
				"onset_distance_penalty": 0.11,
				"rhythm_variation": 0.82,
				"previous_bar_slot_penalty": 0.82,
				"pattern_slot_bonus": 0.30,
				"pre_climax_rest_beats": 0.72,
			}

func _float_array_from_variant(value: Variant) -> Array[float]:
	var result: Array[float] = []
	if value is Array:
		var source: Array = value as Array
		for raw_value in source:
			if raw_value is float or raw_value is int:
				result.append(float(raw_value))
	return result

func _first_beat_index_at_or_after(beat_times: Array[float], time: float) -> int:
	for i in range(beat_times.size()):
		if beat_times[i] >= time:
			return i
	return -1

func _first_beat_at_or_after(beat_times: Array[float], time: float) -> float:
	var index: int = _first_beat_index_at_or_after(beat_times, time)
	if index < 0:
		return -1.0
	return beat_times[index]

func _sample_range_mean(curve: Array[float], hop_seconds: float, start_time: float, end_time: float) -> float:
	if curve.is_empty() or end_time <= start_time:
		return 0.0
	var start_index: int = clampi(int(floor(start_time / maxf(0.000001, hop_seconds))), 0, curve.size() - 1)
	var end_index: int = clampi(int(ceil(end_time / maxf(0.000001, hop_seconds))), start_index, curve.size() - 1)
	var total: float = 0.0
	var count: int = 0
	for i in range(start_index, end_index + 1):
		total += curve[i]
		count += 1
	return total / float(maxi(1, count))

func _sample_range_peak(curve: Array[float], hop_seconds: float, start_time: float, end_time: float) -> float:
	if curve.is_empty() or end_time <= start_time:
		return 0.0
	var start_index: int = clampi(int(floor(start_time / maxf(0.000001, hop_seconds))), 0, curve.size() - 1)
	var end_index: int = clampi(int(ceil(end_time / maxf(0.000001, hop_seconds))), start_index, curve.size() - 1)
	var best: float = 0.0
	for i in range(start_index, end_index + 1):
		best = maxf(best, curve[i])
	return best

func _percentile_sorted(values: Array[float], percentile: float) -> float:
	if values.is_empty():
		return 0.0
	var position: float = clampf(percentile, 0.0, 1.0) * float(values.size() - 1)
	var low_index: int = floori(position)
	var high_index: int = mini(values.size() - 1, low_index + 1)
	var fraction: float = position - float(low_index)
	return lerpf(values[low_index], values[high_index], fraction)

func _sample_curve(curve: Array[float], hop_seconds: float, time: float) -> float:
	if curve.is_empty():
		return 0.0
	var index: int = clampi(int(round(time / maxf(0.000001, hop_seconds))), 0, curve.size() - 1)
	return curve[index]

func _sample_mean(curve: Array[float], hop_seconds: float, time: float, radius_seconds: float) -> float:
	if curve.is_empty():
		return 0.0
	var center: int = clampi(int(round(time / maxf(0.000001, hop_seconds))), 0, curve.size() - 1)
	var radius: int = maxi(1, int(ceil(radius_seconds / maxf(0.000001, hop_seconds))))
	var total: float = 0.0
	var count: int = 0
	for i in range(maxi(0, center - radius), mini(curve.size(), center + radius + 1)):
		total += curve[i]
		count += 1
	return total / float(maxi(1, count))

func _sample_peak(curve: Array[float], hop_seconds: float, time: float, radius_seconds: float) -> float:
	if curve.is_empty():
		return 0.0
	var center: int = clampi(int(round(time / maxf(0.000001, hop_seconds))), 0, curve.size() - 1)
	var radius: int = maxi(1, int(ceil(radius_seconds / maxf(0.000001, hop_seconds))))
	var best: float = 0.0
	for i in range(maxi(0, center - radius), mini(curve.size(), center + radius + 1)):
		best = maxf(best, curve[i])
	return best

func _count_event_type(events: Array, kind: String) -> int:
	var count: int = 0
	for raw in events:
		if raw is Dictionary and str((raw as Dictionary).get("type", "normal")) == kind:
			count += 1
	return count

func _normalize_array(values: Array[float]) -> void:
	var maximum: float = 0.0
	for value in values:
		maximum = maxf(maximum, value)
	if maximum <= 0.000001:
		return
	for i in range(values.size()):
		values[i] = values[i] / maximum

func _mean(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for value in values:
		total += value
	return total / float(values.size())

func _stddev(values: Array[float], mean: float) -> float:
	if values.size() < 2:
		return 0.0
	var total: float = 0.0
	for value in values:
		var delta: float = value - mean
		total += delta * delta
	return sqrt(total / float(values.size()))

func _ascii(bytes: PackedByteArray, offset: int, length: int) -> String:
	var output := ""
	for i in range(length):
		if offset + i >= bytes.size():
			break
		output += String.chr(int(bytes[offset + i]))
	return output

func _u16(bytes: PackedByteArray, offset: int) -> int:
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8)

func _u32(bytes: PackedByteArray, offset: int) -> int:
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8) | (int(bytes[offset + 2]) << 16) | (int(bytes[offset + 3]) << 24)

func _pcm_sample(bytes: PackedByteArray, offset: int, bits: int) -> float:
	if bits == 16:
		var value16: int = _u16(bytes, offset)
		if value16 >= 32768:
			value16 -= 65536
		return float(value16) / 32768.0
	if bits == 24:
		var value24: int = int(bytes[offset]) | (int(bytes[offset + 1]) << 8) | (int(bytes[offset + 2]) << 16)
		if value24 >= 8388608:
			value24 -= 16777216
		return float(value24) / 8388608.0
	var unsigned32: int = _u32(bytes, offset)
	var signed32: int = unsigned32
	if unsigned32 >= 2147483648:
		signed32 = unsigned32 - 4294967296
	return float(signed32) / 2147483648.0
