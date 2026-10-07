extends SceneTree

const QA_ENVIRONMENT_VARIABLE := "BEAT_UP_QA_PHASE4_UI"
const QA_ENVIRONMENT_VALUE := "isolated"
const MinimalThemeScript = preload("res://scripts/ui/minimal_theme.gd")

const TARGET_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]

var failures := 0
var shell: Control
var navigation: Node

func _initialize() -> void:
	if OS.get_environment(QA_ENVIRONMENT_VARIABLE) != QA_ENVIRONMENT_VALUE:
		push_error("Refusing to run Phase 4 UI QA outside its isolated environment.")
		quit(2)
		return
	call_deferred("_run")

func _run() -> void:
	var baseline_orphans: Array[int] = Node.get_orphan_node_ids()
	root.get_node("AppSessionState").call("mark_splash_seen")
	navigation = root.get_node("NavigationController")
	shell = (load("res://scenes/app_shell.tscn") as PackedScene).instantiate() as Control
	root.add_child(shell)
	await _settle(4)

	var startup := shell.get("startup_screen") as Control
	for resolution in TARGET_RESOLUTIONS:
		await _resize_to(resolution)
		_check_main_menu(startup, resolution)

	var library_result: Dictionary = await navigation.call("request_song_library", "bad_apple", false)
	_check(str(library_result.get("outcome", "")) == "success", "Main Menu -> Song Library failed.")
	var library := shell.get("song_library_screen") as Control
	var selection := library.get("song_select") as Control
	await _settle(4)
	for resolution in TARGET_RESOLUTIONS:
		await _resize_to(resolution)
		_check_song_library(selection, resolution)

	# Mode and modifier controls must expose their state without changing launch
	# ownership. The test runs in isolated user data because these calls exercise
	# the same canonical settings consumer as the real screen.
	selection.call("_on_mode_4_selected")
	await _settle(2)
	_check(bool((selection.get("album_flow_mode_4_button") as Button).button_pressed), "4K selection is not visible.")
	_check(not bool((selection.get("album_flow_mode_8_button") as Button).button_pressed), "8K remained selected after choosing 4K.")
	selection.call("_on_mode_8_selected")
	await _settle(2)
	_check(bool((selection.get("album_flow_mode_8_button") as Button).button_pressed), "8K selection is not visible.")
	selection.call("set_random_mode", true)
	await _settle(2)
	_check(bool((selection.get("album_flow_random_button") as Button).button_pressed), "Random selection is not visible.")
	selection.call("set_random_mode", false)

	# The route assertions deliberately use NavigationController so this visual
	# suite cannot bypass the approved AppShell transaction boundary.
	var menu_result: Dictionary = await navigation.call("request_main_menu", 0)
	_check(str(menu_result.get("outcome", "")) == "success", "Song Library -> Main Menu failed.")
	_check(str(shell.call("get_active_route")) == "main_menu", "Main Menu was not active after returning from Song Library.")
	library_result = await navigation.call("request_song_library", "bad_apple", false)
	_check(str(library_result.get("outcome", "")) == "success", "Second Main Menu -> Song Library request failed.")

	_check(not navigation.has_method("request_chart_studio"), "Retired Chart Studio route remains exposed.")

	var launch_request := {"song_id": "bad_apple", "difficulty_id": "normal", "random_mode": false}
	var gameplay_result: Dictionary = await navigation.call("request_gameplay", launch_request, {})
	_check(str(gameplay_result.get("outcome", "")) == "success", "Song Library -> Gameplay failed.")
	var gameplay := shell.get("gameplay_screen") as Control
	await _settle(4)
	for resolution in TARGET_RESOLUTIONS:
		await _resize_to(resolution)
		gameplay.call("update_hud")
		_check_gameplay_hud(gameplay, resolution)
	_check_gameplay_identity(gameplay)
	await _check_pause_presentation(gameplay)
	await _check_playfield_feedback(gameplay)
	await _check_audio_completion(gameplay)

	library_result = await navigation.call("request_song_library", "bad_apple", false)
	_check(str(library_result.get("outcome", "")) == "success", "Gameplay -> Song Library failed.")
	_check(str(shell.call("get_active_route")) == "song_library", "Song Library was not restored after Gameplay.")

	print("PHASE4_UI_FOUNDATION_TEST: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	root.remove_child(shell)
	shell.free()
	await process_frame
	_cleanup_new_orphan_nodes(baseline_orphans)
	call_deferred("_finish", 1 if failures > 0 else 0)

func _check_main_menu(startup: Control, resolution: Vector2i) -> void:
	var play := startup.get("play_button") as Button
	var settings := startup.get("settings_button") as Button
	var title := startup.get("menu_title") as Control
	var now_playing := startup.get("now_playing_card") as Control
	var menu_stack := startup.get("menu_stack") as VBoxContainer
	var utility_row := startup.get("utility_row") as HBoxContainer
	var menu_visual := startup.get("menu_visual") as Control
	var menu_background := startup.get("menu_background") as TextureRect
	var now_playing_kicker := startup.get("now_playing_kicker") as Label
	var background_controller := startup.get("main_menu_background_controller") as RefCounted
	var brand_bounds: Rect2 = menu_visual.call("get_brand_panel_bounds") as Rect2
	_check(_inside_viewport(play, resolution), "Main Menu Play is clipped at %s." % resolution)
	_check(_inside_viewport(now_playing, resolution), "Main Menu Now Playing is clipped at %s." % resolution)
	_check(_inside_viewport(menu_stack, resolution), "Main Menu action column is clipped at %s." % resolution)
	_check(_inside_viewport(utility_row, resolution), "Main Menu utility links are clipped at %s." % resolution)
	_check(_rect_inside_viewport(brand_bounds, resolution), "Beat UP! brand diamond is clipped at %s." % resolution)
	_check(not title.get_global_rect().intersects(now_playing.get_global_rect()), "Main Menu wordmark overlaps Now Playing at %s." % resolution)
	_check(now_playing.get_global_rect().end.y < brand_bounds.position.y, "Now Playing is not a top rail at %s." % resolution)
	_check(menu_stack.get_global_rect().position.x > brand_bounds.end.x, "Main Menu actions are not right of the brand diamond at %s." % resolution)
	_check(not menu_stack.get_global_rect().intersects(brand_bounds), "Main Menu actions overlap the brand diamond at %s." % resolution)
	_check(utility_row.get_global_rect().position.y > menu_stack.get_global_rect().position.y, "Utility links do not sit below primary actions at %s." % resolution)
	_check(menu_stack.get_child_count() == 3, "Main Menu primary column must contain PLAY, SETTINGS, and QUIT only.")
	_check(utility_row.get_child_count() == 3, "Main Menu utility row did not preserve Help, Calibration, and Credits.")
	_check(not bool(menu_visual.call("has_foreground_artwork_card")), "Main Menu restored a foreground cover-art card.")
	_check(menu_background.texture != null, "Main Menu randomized background is missing at %s." % resolution)
	var current_background_path := str(background_controller.call("get_current_background_path"))
	_check(not current_background_path.is_empty(), "Main Menu randomized background path is empty.")
	_check(current_background_path.begins_with("res://assets/backgrounds/background_"), "Main Menu background is not sourced from the randomized generic pool.")
	if not current_background_path.is_empty() and ResourceLoader.exists(current_background_path):
		_check(ResourceLoader.load(current_background_path) == menu_background.texture, "Main Menu full-screen background does not match BackgroundSession.")
	_check(now_playing_kicker.visible and now_playing_kicker.text == "NOW PLAYING", "Now Playing rail lost its hierarchy label.")
	_check(play.size.y > settings.size.y, "Main Menu Play is not more prominent than secondary actions at %s." % resolution)
	_check(play.focus_mode == Control.FOCUS_ALL, "Main Menu Play lost keyboard focus support.")
	for property_name in ["prev_track_button", "play_pause_track_button", "next_track_button"]:
		var transport := startup.get(property_name) as Button
		_check(_inside_viewport(transport, resolution), "Now Playing control %s is clipped at %s: %s." % [property_name, resolution, transport.get_global_rect()])
		_check(transport.focus_mode == Control.FOCUS_ALL, "Now Playing control %s is not keyboard focusable." % property_name)

func _check_song_library(selection: Control, resolution: Vector2i) -> void:
	var play := selection.get("play_button") as Button
	var title := selection.get("detail_title") as Label
	var difficulty_row := selection.get("album_flow_difficulty_row") as Control
	var mode_row := selection.get("album_flow_mode_row") as Control
	var random_button := selection.get("album_flow_random_button") as Button
	var wheel_column := selection.get("wheel_column") as Control
	_check(_inside_viewport(play, resolution), "Song Library Play is clipped at %s: %s." % [resolution, play.get_global_rect()])
	_check(not play.disabled, "Song Library Play is unavailable for the bundled fixture at %s." % resolution)
	_check(_inside_viewport(title, resolution), "Selected song title is clipped at %s." % resolution)
	_check(_inside_viewport(difficulty_row, resolution), "Difficulty state is clipped at %s: %s." % [resolution, difficulty_row.get_global_rect()])
	_check(_inside_viewport(mode_row, resolution), "4K/8K state is clipped at %s." % resolution)
	_check(_inside_viewport(random_button, resolution), "Random state is clipped at %s." % resolution)
	_check(_inside_viewport(wheel_column, resolution), "Song list is clipped at %s: %s." % [resolution, wheel_column.get_global_rect()])
	_check(not title.get_global_rect().intersects(play.get_global_rect()), "Selected song title overlaps Play at %s." % resolution)
	var song_buttons: Array = selection.get("song_buttons") as Array
	var song_ids: Array = selection.get("filtered_song_ids") as Array
	var selected_index := song_ids.find(str(selection.get("selected_song_id")))
	_check(selected_index >= 0 and selected_index < song_buttons.size(), "Selected Song Library item is missing at %s." % resolution)
	if selected_index >= 0 and selected_index < song_buttons.size():
		var selected_button := song_buttons[selected_index] as Button
		var scroll := selection.get("song_scroll") as ScrollContainer
		_check(selected_button.button_pressed, "Selected song row has no visible selected state at %s." % resolution)
		_check(selected_button.get_global_rect().intersects(scroll.get_global_rect()), "Selected song row is outside the visible list at %s." % resolution)

func _check_gameplay_hud(gameplay: Control, resolution: Vector2i) -> void:
	var stats := gameplay.get_node("HUD/BattleStatsPanel") as Control
	var pause := gameplay.get_node("HUD/PauseButton") as Control
	var score := gameplay.get_node("HUD/ScoreDigits") as Control
	var accuracy := gameplay.get_node("HUD/AccuracyLabel") as Control
	var progress := gameplay.get_node("HUD/SongInfoPanel/DurationBar") as Control
	var judgment := gameplay.get_node("Feedback/JudgmentSprite") as Control
	var hit_zone := gameplay.get_node("Battle/Track/HitZone") as Control
	var combo_label := gameplay.get_node("HUD/ComboLabel") as Label
	var song_panel := gameplay.get_node("HUD/SongInfoPanel") as Control
	var title := song_panel.get_node("SongTitleLabel") as Label
	var artist := song_panel.get_node("ArtistLabel") as Label
	var difficulty := song_panel.get_node("DifficultyLabel") as Label
	var time_label := song_panel.get_node("DurationLabel") as Label
	judgment.visible = true
	for control in [stats, pause, score, accuracy, progress, judgment, hit_zone, song_panel, title, artist, difficulty, time_label]:
		_check(_inside_viewport(control, resolution), "Gameplay control %s is clipped at %s." % [control.name, resolution])
	_check(not stats.get_global_rect().intersects(pause.get_global_rect()), "Score/accuracy overlaps Pause at %s." % resolution)
	var skip := gameplay.get_node("HUD/SkipIntroButton") as Button
	_check(_rect_inside_viewport(skip.get_global_rect(), resolution), "Skip Intro is clipped at %s." % resolution)
	_check(not skip.get_global_rect().intersects(stats.get_global_rect()) and not skip.get_global_rect().intersects(song_panel.get_global_rect()), "Skip Intro overlaps song/performance HUD at %s." % resolution)
	_check(is_equal_approx(skip.get_global_rect().get_center().x, float(resolution.x) * 0.5), "Skip Intro is not horizontally centered.")
	_check(skip.get_global_rect().position.y > hit_zone.get_global_rect().end.y and skip.get_global_rect().position.y >= float(resolution.y) * 0.7, "Skip Intro is not in the lower free area below the playfield.")
	_check(judgment.get_global_rect().end.y <= hit_zone.get_global_rect().position.y + 1.0, "Judgment is not above the hit zone at %s." % resolution)
	_check(not combo_label.visible, "Retired gameplay combo label became visible at %s." % resolution)
	_check(title.visible and difficulty.visible and time_label.visible, "Gameplay song context is hidden.")
	_check(song_panel.get_global_rect().end.x < stats.position.x, "Song identity and score are not separated left/right.")
	_check(not title.get_global_rect().intersects(artist.get_global_rect()), "Song title overlaps artist: %s / %s" % [title.get_global_rect(), artist.get_global_rect()])
	var bpm := song_panel.get_node("BPMLabel") as Label
	var artwork := song_panel.get_node("SongArtwork") as Control
	_check(not bpm.visible and difficulty.text.contains(bpm.text), "BPM is not integrated into the gameplay metadata row.")
	_check(is_equal_approx(song_panel.position.x, stats.position.y), "Gameplay header groups do not share their edge margin.")
	_check(song_panel.size.x < float(resolution.x) * 0.5, "Song progress still stretches across the empty central HUD space.")
	_check(artwork.position.is_equal_approx(Vector2.ZERO) and is_equal_approx(title.position.y, 0.0), "Artwork/title top edges are misaligned.")
	_check(not artist.get_global_rect().intersects(difficulty.get_global_rect()), "Artist overlaps gameplay metadata.")
	_check(progress.position.y > difficulty.position.y + difficulty.size.y, "Progress overlaps gameplay metadata.")
	_check(song_panel.get_global_rect().encloses(time_label.get_global_rect()), "Song time escapes its compact header group at %s: %s / %s." % [resolution, song_panel.get_global_rect(), time_label.get_global_rect()])
	_check(not score.get_global_rect().intersects(accuracy.get_global_rect()), "Score overlaps accuracy: %s / %s" % [score.get_global_rect(), accuracy.get_global_rect()])
	_check(stats.get_global_rect().encloses(score.get_global_rect()) and stats.get_global_rect().encloses(accuracy.get_global_rect()), "Compact performance panel clips score or accuracy at %s: %s / %s / %s." % [resolution, stats.get_global_rect(), score.get_global_rect(), accuracy.get_global_rect()])
	_check(gameplay.get_node_or_null("Battle/Track/Lane/InputCompass") == null, "Retired gameplay key display returned.")
	var track := gameplay.get_node("Battle/Track") as Control
	var config: Resource = track.get("layout_config") as Resource
	var hit_point := track.get_node("HitPoint") as Marker2D
	_check(hit_point.position.is_equal_approx(Vector2(track.size.x * float(config.get("hit_x_ratio")), track.size.y * float(config.get("lane_y_ratio")))), "Visual redesign moved the timing receptor.")

func _check_pause_presentation(gameplay: Control) -> void:
	gameplay.call("show_pause_overlay")
	var pause := gameplay.get_node("PauseOverlay") as Control
	var panel := pause.get_node("Center/MainPanel") as Control
	var actions := panel.get_node("MainVBox/PauseButtons") as VBoxContainer
	var resume := actions.get_node("ResumeButton") as Button
	var snapshot: Dictionary = gameplay.call("get_run_input_binding_snapshot")
	_check(bool(gameplay.get("game_paused")), "Pause presentation did not freeze gameplay.")
	for resolution in TARGET_RESOLUTIONS:
		await _resize_to(resolution)
		_check(_inside_viewport(panel, resolution), "Pause panel is clipped at %s." % resolution)
		_check(actions.get_child(0) == resume, "Resume is not the primary action.")
		var previous: Button
		for child in actions.get_children():
			var button := child as Button
			_check(not button.text.is_empty() and button.icon != null, "Pause action lacks a permanent label/SVG icon.")
			_check(_inside_viewport(button, resolution), "Pause action is clipped.")
			_check(panel.get_global_rect().encloses(button.get_global_rect()), "Pause action escapes its panel.")
			if previous != null:
				_check(not previous.get_global_rect().intersects(button.get_global_rect()), "Pause actions overlap.")
				_check(previous.focus_neighbor_bottom == previous.get_path_to(button), "Vertical pause keyboard navigation is broken.")
			previous = button
	_check(resume.has_focus(), "Pause did not default focus to Resume.")
	(actions.get_node("SettingsButton") as Button).pressed.emit()
	_check(bool(pause.get_node("Center/SettingsPanel").visible) and not panel.visible, "Quick Settings action did not open settings.")
	(pause.get_node("Center/SettingsPanel/SettingsVBox/BackButton") as Button).pressed.emit()
	_check(panel.visible and resume.has_focus(), "Quick Settings Back did not restore Resume focus.")
	resume.pressed.emit()
	_check(not pause.visible and bool(gameplay.get("resume_countdown_active")), "Resume button did not enter the existing safety countdown.")
	var countdown := gameplay.get_node("CountdownOverlay") as Control
	var number := countdown.get_node("Center/Stack/Number") as TextureRect
	var visual := countdown.get_node("Center/Stack/Visual") as Control
	var music := gameplay.get_node("Audio/Music") as AudioStreamPlayer
	var was_processing := gameplay.is_processing()
	gameplay.set_process(false)
	for resolution in TARGET_RESOLUTIONS:
		await _resize_to(resolution)
		_check(_inside_viewport(number, resolution), "Resume numeral is clipped at %s." % resolution)
		_check(is_equal_approx(number.get_global_rect().get_center().x, countdown.get_global_rect().get_center().x), "Resume numeral is not horizontally centered.")
		var status := countdown.get_node("Center/Stack/Status") as Label
		var top_gap := number.position.y - status.position.y - status.size.y
		var rail: Rect2 = visual.call("get_progress_rect")
		var bottom_gap := rail.position.y - number.position.y - number.size.y
		_check(top_gap >= 8.0 and top_gap <= 16.0 and bottom_gap >= 8.0 and bottom_gap <= 16.0, "Countdown label/number/progress padding is not compact.")
		_check(not (countdown.get_node("Center/Stack/Mode") as Label).visible, "Redundant countdown helper text returned.")
	for second in [3, 2, 1]:
		_check(int(gameplay.get("countdown_displayed_second")) == second, "Resume countdown skipped or reordered a step.")
		_check(number.texture == visual.call("get_number_texture", second), "Resume step does not use its generated asset.")
		var atlas := number.texture as AtlasTexture
		_check(atlas != null and atlas.atlas.resource_path.ends_with("resume_%d.png" % second), "Wrong generated countdown numeral.")
		if atlas != null:
			_check(atlas.atlas.get_image().get_pixel(0, 0).a == 0.0, "Generated numeral lacks real alpha transparency.")
			_check(atlas.region.size.y < atlas.atlas.get_height() * 0.8, "Faint PNG noise reintroduced oversized numeral padding.")
		_check(bool(gameplay.get("game_paused")) and music.stream_paused, "Countdown released gameplay/audio before zero.")
		if second > 1:
			gameplay.call("_update_resume_countdown", 1.0)
	gameplay.set_process(was_processing)
	await create_timer(float(gameplay.get("resume_countdown_duration")) + 0.2).timeout
	_check(not bool(gameplay.get("game_paused")) and not bool(gameplay.get("resume_countdown_active")), "Resume countdown did not return to gameplay.")
	_check(gameplay.call("get_run_input_binding_snapshot") == snapshot, "Pause presentation changed the input snapshot.")

func _check_playfield_feedback(gameplay: Control) -> void:
	var was_paused := bool(gameplay.get("game_paused"))
	gameplay.set("game_paused", true)
	var track := gameplay.get_node("Battle/Track") as Control
	var original: Dictionary = gameplay.call("get_run_input_binding_snapshot")
	var labels := {"input_style": "8_direction", "bindings": {"8k_8": KEY_W, "space": KEY_F}}
	track.call("set_input_binding_labels", labels)
	labels.bindings["space"] = KEY_Q
	_check((track.get_node("SpacePrompt/PromptBadge/Label") as Label).text == "F", "Space label retained mutable snapshot data.")
	_check(str((track.get_node("SpacePrompt/PromptBadge/Label") as Label).text) == "F", "Custom Space binding label was not presented.")
	track.call("set_input_binding_labels", {"bindings": {"4k_up": KEY_I, "space": KEY_SPACE}})
	track.call("set_input_binding_labels", original)
	_check(gameplay.call("get_run_input_binding_snapshot") == original, "Visual feedback mutated authoritative input bindings.")
	var target := track.get_node("SpacePrompt/TargetDiamond") as Control
	var hit := track.get_node("HitZone") as Control
	track.call("set_space_prompt", true, 0.5, false)
	var target_size := target.size
	track.call("set_space_prompt", true, 1.0, true)
	_check(target.size == target_size, "Fixed Space target changed with approach progress.")
	_check(target.get("stroke_color").is_equal_approx(MinimalThemeScript.SPACE_GOLD), "Fixed Space target lost gold semantics.")
	_check((target.get_global_rect().get_center() - hit.get_global_rect().get_center()).length() < 1.0, "Space target is not centered on timing receptor.")
	track.call("set_space_prompt", false, 0.0, false)
	for rating in ["PERFECT", "GREAT", "GOOD", "MISS"]:
		gameplay.call("show_judgment_popup", rating)
		var label := gameplay.get_node("Feedback/JudgmentSprite") as Label
		_check(label.visible and label.modulate.a == 1.0 and label.text == rating, "Judgement is not immediately readable.")
		_check(label.get_theme_color("font_color").is_equal_approx(gameplay.call("_judgment_color", rating)), "Judgement colour changed during popup replacement.")
		track.call("play_hit_feedback", rating)
		_check(hit.modulate.is_equal_approx(Color.WHITE), "Feedback tinted the white timing anchor.")
	await create_timer(0.4).timeout
	_check(not (gameplay.get_node("Feedback/JudgmentSprite") as Control).visible, "Brief judgement feedback never cleared.")
	gameplay.set("game_paused", was_paused)

func _check_audio_completion(gameplay: Control) -> void:
	var shared := root.get_node("MusicSession").call("get_current_stream") as AudioStream
	var run_stream := (gameplay.get_node("Audio/Music") as AudioStreamPlayer).stream
	_check(shared != run_stream, "Bundled gameplay retained MusicSession's cached preview resource.")
	if shared is AudioStreamOggVorbis:
		_check(not (run_stream as AudioStreamOggVorbis).loop, "Bundled run inherited looping.")
		var looped_preview := shared.duplicate() as AudioStreamOggVorbis
		looped_preview.loop = true
		var isolated := gameplay.call("create_gameplay_audio_stream", looped_preview) as AudioStreamOggVorbis
		_check(isolated != looped_preview and not isolated.loop and looped_preview.loop, "Compressed preview/run loop policies are not isolated.")
	# Model a cached preview stream whose owner enabled looping. Launch must
	# isolate that policy, not alter the preview or depend on a duration watchdog.
	var preview := AudioStreamWAV.new()
	preview.format = AudioStreamWAV.FORMAT_16_BITS
	preview.mix_rate = 22050
	preview.data = PackedByteArray()
	var silence := PackedByteArray()
	silence.resize(22050)
	silence.fill(0)
	preview.data = silence
	preview.loop_mode = AudioStreamWAV.LOOP_FORWARD
	preview.loop_end = 11025
	var chart: Dictionary = (gameplay.get("level_data") as Dictionary).duplicate(true)
	chart["song_id"] = "qa_gameplay_completion"
	chart["id"] = "qa_gameplay_completion"
	chart["duration"] = 0.5
	chart["events"] = [{"time": 0.1, "direction": 8, "type": "normal"}]
	chart["space_events"] = []
	_check(bool(gameplay.call("_start_resolved_level", chart, preview)), "Synthetic completion run failed to launch.")
	var player := gameplay.get_node("Audio/Music") as AudioStreamPlayer
	_check(player.stream != preview, "Gameplay retained shared preview stream.")
	_check((player.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_DISABLED, "Gameplay inherited preview looping.")
	_check(preview.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Gameplay mutated preview looping.")
	var finished_count := [0]
	player.finished.connect(func() -> void: finished_count[0] += 1)
	var deadline := Time.get_ticks_msec() + 6000
	while not bool(gameplay.get("fight_over")) and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(finished_count[0] == 1, "Non-looping run must emit one natural audio completion.")
	_check(bool(gameplay.get("fight_over")), "Audio completion never finalized the run.")
	while root.get_node("SceneTransition").call("is_transitioning") and Time.get_ticks_msec() < deadline:
		await process_frame
	var result := gameplay.get("result_overlay") as Control
	_check(result.is_visible_in_tree(), "Finished song did not reveal Results.")
	await create_timer(0.6).timeout
	_check(not player.playing and finished_count[0] == 1, "Completed song restarted after Results.")

func _check_gameplay_identity(gameplay: Control) -> void:
	var scrim := gameplay.get_node("Background/ReadabilityScrim") as ColorRect
	_check(scrim.mouse_filter == Control.MOUSE_FILTER_IGNORE and scrim.color.a > 0.5, "Gameplay ambience lacks its non-interactive readability scrim.")
	var palette: Resource = load("res://config/theme_config.tres")
	_check(palette.get("normal_note_color").is_equal_approx(MinimalThemeScript.NORMAL_BLUE), "Normal note is not Beat UP! blue.")
	_check(palette.get("diagonal_note_outline").is_equal_approx(MinimalThemeScript.DIAGONAL_ORANGE), "Diagonal note is not Beat UP! orange.")
	_check(palette.get("reverse_note_outline").is_equal_approx(MinimalThemeScript.REVERSE_RED), "Reverse note outline is not red.")
	_check(palette.get("space_accent").is_equal_approx(MinimalThemeScript.SPACE_GOLD), "Space timing color is not gold.")
	_check(palette.get("hit_zone_border").is_equal_approx(Color(1.0, 1.0, 1.0, 0.82)), "Hit-zone diamond is not white.")
	_check(gameplay.call("_judgment_color", "PERFECT").is_equal_approx(MinimalThemeScript.PERFECT_PINK), "PERFECT is not pink.")
	_check(gameplay.call("_judgment_color", "GREAT").is_equal_approx(MinimalThemeScript.GREAT_GREEN), "GREAT is not green.")
	_check(gameplay.call("_judgment_color", "GOOD").is_equal_approx(MinimalThemeScript.GOOD_CYAN), "GOOD is not cyan.")
	_check(gameplay.call("_judgment_color", "MISS").is_equal_approx(MinimalThemeScript.MISS_RED), "MISS is not red.")

	var note_scene := load("res://scenes/note.tscn") as PackedScene
	var normal := note_scene.instantiate() as Control
	var reverse := note_scene.instantiate() as Control
	var space := note_scene.instantiate() as Control
	for note in [normal, reverse, space]:
		note.set("theme_config", palette)
	normal.call("configure", {"type": "normal", "dx": 1.0, "dy": 0.0})
	reverse.call("configure", {"type": "reverse", "dx": 1.0, "dy": 0.0})
	space.call("configure", {"type": "space", "dx": 0.0, "dy": 0.0})
	_check(normal.size == reverse.size, "Reverse note no longer uses the normal note geometry.")
	_check(normal.call("get_outline_color").is_equal_approx(MinimalThemeScript.NORMAL_BLUE), "Normal note runtime outline is not blue.")
	_check(reverse.call("get_outline_color").is_equal_approx(MinimalThemeScript.REVERSE_RED), "Reverse note runtime outline is not red.")
	_check(space.call("get_outline_color").is_equal_approx(MinimalThemeScript.SPACE_GOLD), "Space target runtime outline is not gold.")
	normal.free()
	reverse.free()
	space.free()

func _inside_viewport(control: Control, resolution: Vector2i) -> bool:
	if control == null or not control.is_visible_in_tree():
		return false
	var rect := control.get_global_rect()
	var bounds := Rect2(Vector2.ZERO, Vector2(resolution))
	return rect.size.x > 0.0 and rect.size.y > 0.0 and bounds.encloses(rect.grow(-0.5))

func _rect_inside_viewport(rect: Rect2, resolution: Vector2i) -> bool:
	var bounds := Rect2(Vector2.ZERO, Vector2(resolution))
	return rect.size.x > 0.0 and rect.size.y > 0.0 and bounds.encloses(rect.grow(-0.5))

func _resize_to(resolution: Vector2i) -> void:
	root.size = resolution
	root.content_scale_size = resolution
	await _settle(4)

func _settle(frame_count: int) -> void:
	for _frame in range(frame_count):
		await process_frame

func _wait_for_navigation(max_frames: int = 600) -> void:
	for _frame in range(max_frames):
		if not bool(navigation.call("is_navigating")):
			await process_frame
			return
		await process_frame
	_check(false, "Navigation did not finish within the UI test deadline.")

func _cleanup_new_orphan_nodes(baseline_ids: Array[int]) -> void:
	for instance_id: int in Node.get_orphan_node_ids():
		if baseline_ids.has(instance_id):
			continue
		var orphan := instance_from_id(instance_id)
		if orphan is Node and is_instance_valid(orphan):
			(orphan as Node).free()

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)

func _finish(exit_code: int) -> void:
	quit(exit_code)
