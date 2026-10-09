extends SceneTree

const Background = preload("res://scripts/ui/procedural_background.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	root.size = Vector2i(1920, 1080)
	var host := Control.new()
	root.add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var view := Background.install(host)
	await process_frame
	await process_frame
	check(view.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Atmosphere intercepts input")
	check(view.size.is_equal_approx(host.size), "Atmosphere does not fill owner")
	check(Background.install(host) == view, "Duplicate atmosphere installed")
	check(view.material is ShaderMaterial, "Procedural shader missing")
	var previous := float(view.get("phase"))
	await create_timer(0.05).timeout
	check(float(view.get("phase")) > previous, "Visible background does not animate")
	host.hide()
	previous = float(view.get("phase"))
	await create_timer(0.05).timeout
	check(is_equal_approx(float(view.get("phase")), previous), "Hidden resident background animates")
	host.show()
	view.call("set_motion_enabled", false)
	await create_timer(0.05).timeout
	check(is_equal_approx(float(view.get("phase")), previous), "Motion off does not freeze")
	view.call("set_motion_enabled", true)
	paused = true
	await create_timer(0.05, true).timeout
	check(is_equal_approx(float(view.get("phase")), previous), "Paused background animates")
	paused = false
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]:
		root.size = resolution
		await process_frame
		await process_frame
		check(view.size.is_equal_approx(host.size), "Atmosphere clipped after resize")
		var mat := view.material as ShaderMaterial
		check(is_equal_approx(float(mat.get_shader_parameter("aspect")), view.size.x / view.size.y), "Diamond aspect distorted")
	var capture := OS.get_environment("BEAT_UP_QA_ATMOSPHERE_CAPTURE")
	if not capture.is_empty():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(capture)
	host.queue_free()
	await process_frame
	for child in root.get_children():
		child.queue_free()
	await process_frame
	await process_frame
	if failures == 0:
		print("PROCEDURAL BACKGROUND: PASS")
	quit(0 if failures == 0 else 1)
