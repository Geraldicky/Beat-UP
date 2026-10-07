extends Control

const SHELL_PATH := "res://scenes/app_shell.tscn"
const LOAD_DEADLINE_SECONDS := 30.0
const LogoScript = preload("res://scripts/ui/main_menu_logo.gd")

var reveal_width := 0.0
var logo_window: Control
var logo: Control
var status: Label
var reveal_tween: Tween

func _ready() -> void:
	logo_window = Control.new()
	logo_window.clip_contents = true
	logo_window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo_window)
	logo = LogoScript.new()
	logo_window.add_child(logo)
	status = Label.new()
	# Keep the splash logo-only; this label is reserved for startup failures.
	status.text = ""
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 16)
	status.modulate = Color("9198a6")
	add_child(status)
	resized.connect(_layout)
	_layout()
	call_deferred("_start")

func _layout() -> void:
	# The wordmark never resizes with its mask: reveal L->R, retire R->L.
	logo.size = Vector2(minf(size.x * 0.55, 840.0), minf(size.y * 0.18, 180.0))
	logo_window.position = (size - logo.size) * 0.5
	logo_window.size = Vector2(logo.size.x * reveal_width, logo.size.y)
	status.position = Vector2(0.0, size.y * 0.5 + logo.size.y * 0.5 + 36.0)
	status.size = Vector2(size.x, 28.0)

func _set_reveal(value: float) -> void:
	reveal_width = value
	_layout()

func _start() -> void:
	await get_tree().process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
	# SceneTransition owns the existing threaded scene cache. No second loader.
	var transition: Node = get_node("/root/SceneTransition")
	transition.call("preload_scene", SHELL_PATH)
	reveal_tween = create_tween()
	reveal_tween.tween_method(_set_reveal, 0.0, 1.0, 0.58).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	var deadline := Time.get_ticks_msec() + int(LOAD_DEADLINE_SECONDS * 1000.0)
	while not bool(transition.call("is_scene_cached", SHELL_PATH)):
		if Time.get_ticks_msec() >= deadline or not (transition.get("preload_requests") as Dictionary).has(SHELL_PATH):
			status.text = "COULD NOT START BEAT UP! — PLEASE RESTART"
			return
		await get_tree().process_frame
	if reveal_tween.is_running():
		await reveal_tween.finished
	await get_tree().create_timer(0.24).timeout
	reveal_tween = create_tween()
	reveal_tween.tween_method(_set_reveal, 1.0, 0.0, 0.42).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	await reveal_tween.finished
	# Startup's resident splash must not run a second time after the bootstrap.
	get_tree().set_meta("beat_up_boot_splash_completed", true)
	get_node("/root/AppSessionState").call("mark_splash_seen")
	var cache: Dictionary = transition.get("scene_cache")
	var error := get_tree().change_scene_to_packed(cache[SHELL_PATH] as PackedScene)
	if error != OK:
		status.text = "COULD NOT OPEN MAIN MENU — PLEASE RESTART"
