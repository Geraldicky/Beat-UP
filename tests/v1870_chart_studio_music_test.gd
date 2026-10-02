extends SceneTree

const MusicSessionScript = preload("res://scripts/music_session.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = MusicSessionScript.new()
	session.name = "MusicSessionTest"
	root.add_child(session)
	await process_frame
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 44100.0
	stream.buffer_length = 1.0
	session.player.stream = stream
	session.player.play()
	session.set_paused(true)
	if not session.is_paused():
		push_error("Chart Studio music isolation could not pause the global player.")
		quit(1)
		return
	session.ensure_playing(0.01)
	if session.is_paused():
		push_error("Menu music did not resume after leaving Chart Studio.")
		quit(1)
		return
	print("V1870_CHART_STUDIO_MUSIC: PASS")
	session.queue_free()
	await process_frame
	quit(0)
