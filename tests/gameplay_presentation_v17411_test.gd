extends SceneTree

const UserSettingsScript = preload("res://scripts/user_settings.gd")

var failures := 0

func _initialize() -> void:
	root.size = Vector2i(1440, 900)
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)

func _run() -> void:
	var background_script: Script = load("res://scripts/ui/battle_background.gd") as Script
	var background := background_script.new() as TextureRect
	root.add_child(background)
	await process_frame
	_check(background.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "Gameplay background must use aspect-cover scaling.")
	_check(bool(background.call("set_song_background", "res://assets/song_backgrounds/big_daddy.png", "big_daddy")), "Known song background did not load.")
	_check(background.texture != null, "Known song background produced no texture.")
	_check(str(background.call("get_current_background_path")) == "res://assets/song_backgrounds/big_daddy.png", "Gameplay background path tracking is incorrect.")
	background.queue_free()
	await process_frame

	var original_opacity: float = UserSettingsScript.get_background_opacity()
	UserSettingsScript.set_background_opacity(31.0)
	_check(is_equal_approx(UserSettingsScript.get_background_opacity(), 31.0), "Song background opacity did not persist.")
	UserSettingsScript.set_background_opacity(original_opacity)

	var note_scene := load("res://scenes/note.tscn") as PackedScene
	var note := note_scene.instantiate() as RhythmNote
	var palette := load("res://config/theme_config.tres")
	note.theme_config = palette
	note.configure({"type": "normal", "dx": 1.0, "dy": 0.0})
	_check(note.get_arrow_color().is_equal_approx(palette.base_dark), "Note arrow must be dark over the white fill.")
	_check(note.get_outline_color().is_equal_approx(palette.normal_note_color), "Normal note outline is no longer blue.")
	note.configure({"type": "normal", "dx": 1.0, "dy": -1.0})
	_check(note.get_outline_color().is_equal_approx(palette.diagonal_note_outline), "Diagonal note outline is no longer orange.")
	note.configure({"type": "reverse", "dx": 1.0, "dy": 0.0})
	_check(note.get_outline_color().is_equal_approx(palette.reverse_note_outline), "Reverse note outline is no longer red.")
	note.free()

	var main_scene := load("res://main.tscn") as PackedScene
	var game := main_scene.instantiate() as Control
	root.add_child(game)
	await process_frame
	await process_frame
	game.size = Vector2(1440.0, 900.0)
	game.call("_apply_ui_layout")
	var stats_panel := game.get_node("HUD/BattleStatsPanel") as Control
	var song_panel := game.get_node("HUD/SongInfoPanel") as Control
	var pause_button := game.get_node("HUD/PauseButton") as Control
	_check(stats_panel.position.x < song_panel.position.x, "Score/HUD stats panel is not on the left of song context.")
	_check(song_panel.position.x + song_panel.size.x <= pause_button.position.x + 1.0, "Song context overlaps the Pause area.")
	game.queue_free()
	await process_frame

	if failures == 0:
		print("GAMEPLAY_PRESENTATION_V17411_TEST: PASS")
	else:
		print("GAMEPLAY_PRESENTATION_V17411_TEST: FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
