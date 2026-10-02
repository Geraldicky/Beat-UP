extends SceneTree

const SONG_ID := "diana_boncheva_feat_banya_beethoven_virus_full_version"

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://main.tscn") as PackedScene
	var main := scene.instantiate() as Control
	root.add_child(main)
	await process_frame
	await process_frame
	var level_index: int = int(main.call("find_level_index", SONG_ID, "normal"))
	_check(level_index >= 0, "Beethoven Virus chart is missing from the catalog")
	if level_index >= 0:
		main.call("start_level", level_index)
		await process_frame
		await process_frame
		var music := main.get_node("Audio/Music") as AudioStreamPlayer
		var selector := main.get_node("LevelSelect") as Control
		var countdown := main.get_node("CountdownOverlay") as Control
		_check(music.stream is AudioStreamOggVorbis, "Beethoven Virus did not load as Ogg Vorbis")
		_check(not selector.visible, "Gameplay returned to Song Library after loading Beethoven Virus")
		_check(countdown.visible, "Beethoven Virus did not enter the three-second countdown")
		_check(str((main.get("level_data") as Dictionary).get("song_id", "")) == SONG_ID, "Gameplay loaded the wrong chart")
	main.queue_free()
	await process_frame
	if failed:
		quit(1)
	else:
		print("BEETHOVEN PLAYBACK HOTFIX PASS • Ogg Vorbis loaded • countdown entered")
		quit(0)

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
