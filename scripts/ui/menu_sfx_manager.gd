extends Node

const UserSettingsScript = preload("res://scripts/user_settings.gd")

const MIX_RATE := 44100.0
const SCAN_INTERVAL := 0.32
const MIN_SOUND_GAP_USEC := 42000

var players: Array[AudioStreamPlayer] = []
var player_cursor := 0
var scan_elapsed := 0.0
var last_sound_usec := 0
var rank_fill_active := false
var rank_fill_elapsed := 0.0
var rank_fill_interval := 0.06
var rank_fill_value := 0.0
var rank_fill_target := 100.0
var rank_fill_tick_count := 0
var rank_fill_lock_count := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for index in range(4):
		var player := AudioStreamPlayer.new()
		player.name = "ProceduralVoice%d" % (index + 1)
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		var generator := AudioStreamGenerator.new()
		generator.mix_rate = MIX_RATE
		generator.buffer_length = 0.18
		player.stream = generator
		add_child(player)
		player.play()
		players.append(player)
	_update_volume()
	call_deferred("_scan_current_scene")

func _process(delta: float) -> void:
	scan_elapsed += delta
	if scan_elapsed >= SCAN_INTERVAL:
		scan_elapsed = 0.0
		_scan_current_scene()
		_update_volume()
	if rank_fill_active:
		rank_fill_elapsed += delta
		while rank_fill_elapsed >= rank_fill_interval:
			rank_fill_elapsed -= rank_fill_interval
			_play_rank_fill_tick()

func _exit_tree() -> void:
	# Stop generator voices before audio-server teardown releases their playback.
	rank_fill_active = false
	for player in players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	players.clear()

func _scan_current_scene() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	_wire_branch(scene)

func _wire_branch(node: Node) -> void:
	if node is BaseButton:
		_wire_button(node as BaseButton)
	elif node is Slider:
		_wire_slider(node as Slider)
	for child in node.get_children():
		_wire_branch(child)

func _wire_button(button: BaseButton) -> void:
	if button.has_meta("beat_up_menu_sfx_wired"):
		return
	button.set_meta("beat_up_menu_sfx_wired", true)
	button.mouse_entered.connect(_on_control_highlighted)
	button.focus_entered.connect(_on_control_highlighted)
	button.pressed.connect(_on_button_pressed.bind(button))

func _wire_slider(slider: Slider) -> void:
	if slider.has_meta("beat_up_menu_sfx_wired"):
		return
	slider.set_meta("beat_up_menu_sfx_wired", true)
	slider.mouse_entered.connect(_on_control_highlighted)
	slider.focus_entered.connect(_on_control_highlighted)
	slider.drag_ended.connect(_on_slider_drag_ended)

func _on_control_highlighted() -> void:
	play_hover()

func _on_button_pressed(button: BaseButton) -> void:
	var control_name := button.name.to_lower()
	if "back" in control_name or "exit" in control_name or "cancel" in control_name or "songlist" in control_name:
		play_back()
	else:
		play_select()

func _on_slider_drag_ended(_value_changed: bool) -> void:
	play_select(0.72)

func play_hover(strength := 1.0) -> void:
	_play_tone(510.0, 610.0, 0.032, 0.16 * strength, 0.25)

func play_select(strength := 1.0) -> void:
	_play_tone(520.0, 850.0, 0.072, 0.25 * strength, 0.58)

func play_back(strength := 1.0) -> void:
	_play_tone(430.0, 250.0, 0.085, 0.22 * strength, 0.48)

func play_error(strength := 1.0) -> void:
	_play_tone(185.0, 145.0, 0.11, 0.25 * strength, 0.74)

func begin_rank_fill(target_value: float, duration_s: float) -> void:
	rank_fill_target = clampf(target_value, 0.0, 100.0)
	rank_fill_active = rank_fill_target > 0.01
	rank_fill_elapsed = 0.0
	rank_fill_value = 0.0
	rank_fill_interval = clampf(duration_s / 15.0, 0.045, 0.075)
	rank_fill_tick_count = 0
	rank_fill_lock_count = 0
	if rank_fill_active:
		_play_rank_fill_tick(true)

func update_rank_fill(value: float) -> void:
	rank_fill_value = clampf(value, 0.0, rank_fill_target)

func finish_rank_fill(final_rank: String) -> void:
	rank_fill_active = false
	rank_fill_elapsed = 0.0
	rank_fill_value = rank_fill_target
	rank_fill_lock_count += 1
	var lock_pitch := 392.0
	match final_rank.to_upper():
		"SS":
			lock_pitch = 784.0
		"S":
			lock_pitch = 659.0
		"A":
			lock_pitch = 523.0
		"B":
			lock_pitch = 440.0
		"C":
			lock_pitch = 392.0
		_:
			lock_pitch = 330.0
	_play_tone(lock_pitch * 0.78, lock_pitch, 0.13, 0.19, 0.42, true)

func cancel_rank_fill() -> void:
	rank_fill_active = false
	rank_fill_elapsed = 0.0

func get_rank_fill_debug_state() -> Dictionary:
	return {
		"active": rank_fill_active,
		"ticks": rank_fill_tick_count,
		"locks": rank_fill_lock_count,
		"value": rank_fill_value,
		"target": rank_fill_target,
	}

func _play_rank_fill_tick(force := false) -> void:
	var progress := clampf(rank_fill_value / maxf(1.0, rank_fill_target), 0.0, 1.0)
	var start_hz := lerpf(210.0, 610.0, progress)
	var end_hz := start_hz + lerpf(28.0, 92.0, progress)
	rank_fill_tick_count += 1
	_play_tone(start_hz, end_hz, 0.045, lerpf(0.075, 0.12, progress), 0.30, force)

func _play_tone(start_hz: float, end_hz: float, duration_s: float, amplitude: float, grit: float, force := false) -> void:
	if not UserSettingsScript.get_menu_sfx_enabled() or UserSettingsScript.get_menu_sfx_volume() <= 0.0:
		return
	var now_usec := Time.get_ticks_usec()
	if not force and now_usec - last_sound_usec < MIN_SOUND_GAP_USEC:
		return
	last_sound_usec = now_usec
	if players.is_empty():
		return
	var player := players[player_cursor]
	player_cursor = (player_cursor + 1) % players.size()
	if not player.playing:
		player.play()
	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	# Voices rotate faster than their short tone buffers drain. Avoid clearing an
	# active generator, which can race the audio thread during scene transitions.
	var frame_count := maxi(1, int(duration_s * MIX_RATE))
	var phase := 0.0
	for frame in range(frame_count):
		var t := float(frame) / float(maxi(1, frame_count - 1))
		var hz := lerpf(start_hz, end_hz, t * t * (3.0 - 2.0 * t))
		phase = fmod(phase + TAU * hz / MIX_RATE, TAU)
		var envelope := pow(1.0 - t, 2.2) * minf(1.0, t * 24.0)
		var clean := sin(phase)
		var overtone := sin(phase * 2.0 + 0.4) * grit * 0.34
		var sample := (clean + overtone) * amplitude * envelope
		playback.push_frame(Vector2(sample, sample))

func _update_volume() -> void:
	var volume_linear := clampf(UserSettingsScript.get_menu_sfx_volume() / 100.0, 0.0001, 1.0)
	var target_db := linear_to_db(volume_linear)
	for player in players:
		player.volume_db = target_db
