extends Node
class_name BeatUpMusicSession

signal track_changed(state: Dictionary)
signal playback_state_changed(state: Dictionary)

const BUS_NAME := &"BeatUpMusic"
const BAR_COUNT := 18
const MIN_FREQUENCY_HZ := 45.0
const MAX_FREQUENCY_HZ := 5200.0
const SILENCE_DB := -58.0
const HIGH_FREQUENCY_GAIN_DB := 16.0
const BAND_DYNAMIC_RANGE_DB := 25.0
const PEAK_DECAY_DB_PER_SECOND := 6.0
const GATE_CLOSED_DB := -69.0
const GATE_OPEN_DB := -42.0

var player: AudioStreamPlayer
var current_audio_path: String = ""
var current_metadata: Dictionary = {}
var current_loop: bool = false
var target_volume_db: float = -10.0
var volume_tween: Tween
var play_generation: int = 0
# Stable playback clock for pause/resume. Some engine states can report
# `playing == false` while stream_paused is true, so the current position must
# not be inferred from `playing` alone.
var last_known_position: float = 0.0

# v17.4.49 media prefetch cache. Song browsing can request the next OGG on a
# loader thread and only commit playback after it is ready, avoiding synchronous
# resource decode on the UI frame.
const AUDIO_CACHE_LIMIT := 5
var audio_stream_cache: Dictionary = {}
var audio_cache_order: Array[String] = []
var audio_preload_requests: Dictionary = {}
var audio_preload_failed: Dictionary = {}

var bus_index: int = -1
var spectrum_effect_index: int = -1
var spectrum_instance: AudioEffectSpectrumAnalyzerInstance
var latest_levels := PackedFloat32Array()
var band_peak_db := PackedFloat32Array()
var created_bus: bool = false
var created_spectrum_effect: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	latest_levels.resize(BAR_COUNT)
	band_peak_db.resize(BAR_COUNT)
	band_peak_db.fill(SILENCE_DB)
	player = AudioStreamPlayer.new()
	player.name = "GlobalMusicPlayer"
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	_setup_spectrum_bus()
	call_deferred("_resolve_spectrum_instance")

func _exit_tree() -> void:
	if volume_tween != null:
		volume_tween.kill()
	spectrum_instance = null
	var current_bus_index: int = AudioServer.get_bus_index(BUS_NAME)
	if current_bus_index < 0:
		return
	if created_spectrum_effect and spectrum_effect_index >= 0 and spectrum_effect_index < AudioServer.get_bus_effect_count(current_bus_index):
		AudioServer.remove_bus_effect(current_bus_index, spectrum_effect_index)
	if created_bus:
		AudioServer.remove_bus(current_bus_index)

func _process(delta: float) -> void:
	_poll_audio_preloads()
	if player != null and player.stream != null and player.playing and not player.stream_paused:
		last_known_position = maxf(player.get_playback_position(), 0.0)
	if spectrum_instance == null:
		_resolve_spectrum_instance()
	_sample_spectrum(delta)

func play_track(audio_path: String, start_position: float = 0.0, metadata: Dictionary = {}, restart_if_same: bool = false, loop: bool = false, fade_duration: float = 0.18, target_db: float = -10.0) -> bool:
	if audio_path.is_empty():
		return false
	var same_track: bool = current_audio_path == audio_path and player != null and player.stream != null
	current_metadata = metadata.duplicate(true)
	current_loop = loop
	target_volume_db = target_db
	if same_track and player.playing and not restart_if_same:
		_apply_loop_to_stream(player.stream, loop)
		# A caller asking to play the current track owns the audible state. This
		# also restores previews/menu BGM after Chart Studio paused the session.
		player.stream_paused = false
		_set_target_volume(target_db, fade_duration)
		track_changed.emit(get_state())
		playback_state_changed.emit(get_state())
		return true
	var loaded_stream: AudioStream = null
	if audio_stream_cache.has(audio_path):
		loaded_stream = audio_stream_cache[audio_path] as AudioStream
	else:
		loaded_stream = _load_audio_stream(audio_path)
		if loaded_stream != null:
			_cache_audio_stream(audio_path, loaded_stream)
	if loaded_stream == null:
		return false
	play_generation += 1
	var generation := play_generation
	if volume_tween != null:
		volume_tween.kill()
	var generation_path: String = audio_path
	if player.playing and fade_duration > 0.01:
		volume_tween = create_tween()
		volume_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		volume_tween.tween_property(player, "volume_db", SILENCE_DB, fade_duration * 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		volume_tween.tween_callback(_begin_track.bind(generation, generation_path, loaded_stream, start_position, loop, target_db, fade_duration * 0.55))
	else:
		_begin_track(generation, generation_path, loaded_stream, start_position, loop, target_db, fade_duration)
	return true

func _begin_track(generation: int, audio_path: String, loaded_stream: AudioStream, start_position: float, loop: bool, target_db: float, fade_in: float) -> void:
	if generation != play_generation:
		return
	if player == null:
		return
	player.stop()
	player.stream = loaded_stream
	_apply_loop_to_stream(player.stream, loop)
	current_audio_path = audio_path
	current_loop = loop
	target_volume_db = target_db
	band_peak_db.fill(SILENCE_DB)
	latest_levels.fill(0.0)
	var length: float = maxf(player.stream.get_length(), 0.0)
	var safe_position: float = maxf(start_position, 0.0)
	if length > 0.0:
		safe_position = clampf(safe_position, 0.0, maxf(length - 0.01, 0.0))
	player.volume_db = SILENCE_DB
	last_known_position = safe_position
	player.play(safe_position)
	player.stream_paused = false
	_set_target_volume(target_db, fade_in)
	track_changed.emit(get_state())
	playback_state_changed.emit(get_state())

func update_metadata(metadata: Dictionary) -> void:
	current_metadata = metadata.duplicate(true)
	track_changed.emit(get_state())

func ensure_playing(fade_duration: float = 0.18) -> void:
	if player == null or player.stream == null:
		return
	var was_paused: bool = player.stream_paused
	player.stream_paused = false
	if not player.playing:
		player.volume_db = SILENCE_DB
		player.play(last_known_position if was_paused else 0.0)
	_set_target_volume(target_volume_db, fade_duration)
	playback_state_changed.emit(get_state())

func set_paused(paused: bool) -> void:
	if player == null or player.stream == null:
		return
	if paused:
		if player.playing:
			last_known_position = maxf(player.get_playback_position(), 0.0)
		player.stream_paused = true
	else:
		var was_paused: bool = player.stream_paused
		player.stream_paused = false
		if was_paused and not player.playing:
			player.play(last_known_position)
	playback_state_changed.emit(get_state())

func is_paused() -> bool:
	return player != null and player.stream != null and player.stream_paused

func is_playing() -> bool:
	return player != null and player.stream != null and player.playing

func seek(playback_position: float) -> void:
	if player == null or player.stream == null:
		return
	var length: float = maxf(player.stream.get_length(), 0.0)
	var safe_position: float = maxf(playback_position, 0.0)
	if length > 0.0:
		safe_position = clampf(safe_position, 0.0, maxf(length - 0.01, 0.0))
	last_known_position = safe_position
	player.seek(safe_position)
	playback_state_changed.emit(get_state())

func fade_out(duration: float = 0.18, stop_after_fade: bool = false) -> void:
	if player == null or not player.playing:
		return
	if volume_tween != null:
		volume_tween.kill()
	volume_tween = create_tween()
	volume_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	volume_tween.tween_property(player, "volume_db", SILENCE_DB, maxf(duration, 0.01)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	if stop_after_fade:
		volume_tween.tween_callback(stop_immediately)

func stop_immediately() -> void:
	play_generation += 1
	if volume_tween != null:
		volume_tween.kill()
		volume_tween = null
	if player != null:
		player.stop()
		player.stream = null
	current_audio_path = ""
	current_metadata.clear()
	current_loop = false
	last_known_position = 0.0
	latest_levels.fill(0.0)
	band_peak_db.fill(SILENCE_DB)
	track_changed.emit(get_state())
	playback_state_changed.emit(get_state())

func set_target_volume(target_db: float, duration: float = 0.18) -> void:
	target_volume_db = target_db
	_set_target_volume(target_db, duration)

func _set_target_volume(target_db: float, duration: float) -> void:
	if player == null or player.stream == null:
		return
	if volume_tween != null:
		volume_tween.kill()
	volume_tween = create_tween()
	volume_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	volume_tween.tween_property(player, "volume_db", target_db, maxf(duration, 0.01)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func get_state() -> Dictionary:
	var state: Dictionary = current_metadata.duplicate(true)
	state["audio"] = current_audio_path
	state["position"] = get_playback_position()
	state["duration"] = get_duration()
	state["playing"] = is_playing() and not is_paused()
	state["paused"] = is_paused()
	state["loop"] = current_loop
	return state

func get_current_stream() -> AudioStream:
	return player.stream if player != null else null

func get_playback_position() -> float:
	if player == null or player.stream == null:
		return 0.0
	if player.stream_paused:
		return maxf(last_known_position, 0.0)
	if player.playing:
		last_known_position = maxf(player.get_playback_position(), 0.0)
		return last_known_position
	return maxf(last_known_position, 0.0)

func get_duration() -> float:
	if player == null or player.stream == null:
		return 0.0
	return maxf(player.stream.get_length(), 0.0)

func get_current_audio_path() -> String:
	return current_audio_path

func get_latest_levels() -> PackedFloat32Array:
	return latest_levels.duplicate()

func preload_track(path: String) -> bool:
	if path.is_empty():
		return false
	if path == current_audio_path and player != null and player.stream != null:
		_cache_audio_stream(path, player.stream)
		return true
	if audio_stream_cache.has(path):
		_touch_audio_cache(path)
		return true
	if audio_preload_requests.has(path):
		return true
	audio_preload_failed.erase(path)
	if not path.begins_with("res://") or not ResourceLoader.exists(path):
		return false
	var error := ResourceLoader.load_threaded_request(path, "AudioStream", true, ResourceLoader.CACHE_MODE_REUSE)
	if error == OK or ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		audio_preload_requests[path] = true
		return true
	audio_preload_failed[path] = true
	return false

func is_track_ready(path: String) -> bool:
	if path == current_audio_path and player != null and player.stream != null:
		return true
	if audio_stream_cache.has(path):
		return true
	_poll_audio_preload_path(path)
	return audio_stream_cache.has(path)

func is_track_preload_failed(path: String) -> bool:
	return bool(audio_preload_failed.get(path, false))

func _poll_audio_preloads() -> void:
	for path_value in audio_preload_requests.keys():
		_poll_audio_preload_path(str(path_value))

func _poll_audio_preload_path(path: String) -> void:
	if not audio_preload_requests.has(path):
		return
	var status := ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		return
	audio_preload_requests.erase(path)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var resource := ResourceLoader.load_threaded_get(path)
		if resource is AudioStream:
			_cache_audio_stream(path, resource as AudioStream)
			audio_preload_failed.erase(path)
			return
	audio_preload_failed[path] = true

func _cache_audio_stream(path: String, stream: AudioStream) -> void:
	if path.is_empty() or stream == null:
		return
	audio_stream_cache[path] = stream
	_touch_audio_cache(path)
	while audio_cache_order.size() > AUDIO_CACHE_LIMIT:
		var evict_path: String = str(audio_cache_order.pop_front())
		if evict_path == current_audio_path:
			audio_cache_order.append(evict_path)
			if audio_cache_order.size() <= AUDIO_CACHE_LIMIT + 1:
				break
			continue
		audio_stream_cache.erase(evict_path)

func _touch_audio_cache(path: String) -> void:
	audio_cache_order.erase(path)
	audio_cache_order.append(path)

func _load_audio_stream(path: String) -> AudioStream:
	if path.is_empty():
		return null
	if path.begins_with("res://") and ResourceLoader.exists(path):
		var resource: Resource = ResourceLoader.load(path)
		if resource is AudioStream:
			return resource as AudioStream
	var filesystem_path: String = ProjectSettings.globalize_path(path) if path.begins_with("user://") or path.begins_with("res://") else path
	match filesystem_path.get_extension().to_lower():
		"ogg": return AudioStreamOggVorbis.load_from_file(filesystem_path)
		"mp3": return AudioStreamMP3.load_from_file(filesystem_path)
		"wav": return AudioStreamWAV.load_from_file(filesystem_path)
	return null

func _apply_loop_to_stream(audio_stream: AudioStream, loop: bool) -> void:
	if audio_stream is AudioStreamOggVorbis:
		(audio_stream as AudioStreamOggVorbis).loop = loop
	elif audio_stream is AudioStreamMP3:
		(audio_stream as AudioStreamMP3).loop = loop
	elif audio_stream is AudioStreamWAV:
		(audio_stream as AudioStreamWAV).loop_mode = (AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED) as AudioStreamWAV.LoopMode

func _setup_spectrum_bus() -> void:
	bus_index = AudioServer.get_bus_index(BUS_NAME)
	if bus_index < 0:
		AudioServer.add_bus()
		bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_index, BUS_NAME)
		AudioServer.set_bus_send(bus_index, &"Master")
		created_bus = true
	player.bus = BUS_NAME
	for effect_index in range(AudioServer.get_bus_effect_count(bus_index)):
		var effect: AudioEffect = AudioServer.get_bus_effect(bus_index, effect_index)
		if effect is AudioEffectSpectrumAnalyzer:
			spectrum_effect_index = effect_index
			break
	if spectrum_effect_index < 0:
		var analyzer := AudioEffectSpectrumAnalyzer.new()
		analyzer.buffer_length = 2.0
		analyzer.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_4096
		AudioServer.add_bus_effect(bus_index, analyzer)
		spectrum_effect_index = AudioServer.get_bus_effect_count(bus_index) - 1
		created_spectrum_effect = true

func _resolve_spectrum_instance() -> void:
	if bus_index < 0 or spectrum_effect_index < 0:
		return
	spectrum_instance = AudioServer.get_bus_effect_instance(bus_index, spectrum_effect_index) as AudioEffectSpectrumAnalyzerInstance

func _sample_spectrum(delta: float) -> void:
	if spectrum_instance == null or player == null or not player.playing or player.stream_paused:
		latest_levels.fill(0.0)
		return
	for index in range(BAR_COUNT):
		var frequency_ratio: float = MAX_FREQUENCY_HZ / MIN_FREQUENCY_HZ
		var lower_weight: float = float(index) / float(BAR_COUNT)
		var upper_weight: float = float(index + 1) / float(BAR_COUNT)
		var lower_hz: float = MIN_FREQUENCY_HZ * pow(frequency_ratio, lower_weight)
		var upper_hz: float = MIN_FREQUENCY_HZ * pow(frequency_ratio, upper_weight)
		var frequency_weight: float = (float(index) + 0.5) / float(BAR_COUNT)
		var magnitude: Vector2 = spectrum_instance.get_magnitude_for_frequency_range(lower_hz, upper_hz, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE)
		var linear_energy: float = maxf(magnitude.x, magnitude.y)
		var frequency_compensation_db: float = HIGH_FREQUENCY_GAIN_DB * pow(frequency_weight, 0.90)
		var energy_db: float = linear_to_db(maxf(linear_energy, 0.000001)) + frequency_compensation_db
		band_peak_db[index] = maxf(energy_db, band_peak_db[index] - PEAK_DECAY_DB_PER_SECOND * delta)
		var relative_level: float = clampf(inverse_lerp(band_peak_db[index] - BAND_DYNAMIC_RANGE_DB, band_peak_db[index], energy_db), 0.0, 1.0)
		var absolute_gate: float = smoothstep(GATE_CLOSED_DB, GATE_OPEN_DB, energy_db)
		latest_levels[index] = pow(relative_level, 0.72) * absolute_gate


# v17.4.52.1: typed public spectrum helpers.  UI/test controllers delegate to
# the centralized session instead of maintaining duplicate analyzer state.
func get_band_frequency_range(index: int) -> Vector2:
	var safe_index: int = clampi(index, 0, BAR_COUNT - 1)
	var frequency_ratio: float = MAX_FREQUENCY_HZ / MIN_FREQUENCY_HZ
	var lower_weight: float = float(safe_index) / float(BAR_COUNT)
	var upper_weight: float = float(safe_index + 1) / float(BAR_COUNT)
	var lower_hz: float = MIN_FREQUENCY_HZ * pow(frequency_ratio, lower_weight)
	var upper_hz: float = MIN_FREQUENCY_HZ * pow(frequency_ratio, upper_weight)
	return Vector2(lower_hz, upper_hz)

func is_spectrum_configured() -> bool:
	if bus_index < 0 or spectrum_effect_index < 0:
		return false
	if spectrum_effect_index >= AudioServer.get_bus_effect_count(bus_index):
		return false
	return AudioServer.get_bus_effect(bus_index, spectrum_effect_index) is AudioEffectSpectrumAnalyzer
