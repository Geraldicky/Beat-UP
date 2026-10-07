extends SceneTree

const Palette = preload("res://scripts/ui/minimal_theme.gd")
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	call_deferred("run")

func run() -> void:
	var telemetry := preload("res://scripts/playtest_telemetry.gd").new()
	telemetry._session = {"events": [{"timing_error_ms": 12, "judgement": "PERFECT"}]}
	var presentation_copy := telemetry.get_result_events()
	presentation_copy[0].timing_error_ms = 999
	check(telemetry.get_result_events()[0].timing_error_ms == 12, "Results timeline mutates telemetry ownership")
	# Load after project autoloads register (Results uses the existing MenuSFX).
	var packed := load("res://scenes/result_screen.tscn") as PackedScene
	var result := packed.instantiate()
	root.add_child(result)
	var sample := {"song_id": "bad_apple", "title": "BAD APPLE!!",
		"meta": "Alstroemeria Records feat. nomico  ·  MASTER  ·  8K  ·  RANDOM  ·  REV 50%",
		"score": 2771869, "accuracy": 0.0, "rank": "D", "max_combo": 190,
		"perfect": 877, "great": 151, "good": 45, "miss": 53,
		"space_hits": 10, "space_total": 12, "reverse_hits": 20, "reverse_total": 25,
		"new_best": true, "previous_best": {"score": 2000000, "accuracy": 80.0},
		"background": "res://assets/backgrounds/background_01.png", "rank_sub": "CLEAR"}
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]:
		sample.random_mode = true
		sample.reverse_percent = 50
		sample.song_duration_s = 300.0
		sample.judgement_events = []
		for index in range(400):
			sample.judgement_events.append({"target_time_ms": index * 750, "timing_error_ms": sin(index * 1.7) * 40, "judgement": "PERFECT" if index % 4 != 0 else "GREAT", "combo_after": index})
		root.size = resolution
		result.set_result(sample)
		check(not result.rank_sub.visible, "Calculating status must stay hidden before reveal completes")
		await create_timer(1.6).timeout
		var bounds := Rect2(Vector2.ZERO, Vector2(resolution))
		for control: Control in [result.header_bar, result.rank_panel, result.stats_column,
			result.bottom_bar, result.back_button, result.replay_button, result.rank_stack,
			result.details, result.breakdown_panel, result.special_panel, result.song_column]:
			check(bounds.encloses(control.get_global_rect()), "%s %s clipped at %s (root %s)" % [control.name, control.get_global_rect(), resolution, result.size])
		check(not result.song_column.get_global_rect().intersects(result.rank_panel.get_global_rect()), "Song header %s overlaps outcome %s at %s" % [result.song_column.get_global_rect(), result.rank_panel.get_global_rect(), resolution])
		check(not result.rank_panel.get_global_rect().intersects(result.details.get_global_rect()), "Outcome overlaps performance summary")
		check(not result.rank_panel.get_global_rect().intersects(result.stats_column.get_global_rect()), "Rank card overlaps score")
		check(result.header_bar.get_global_rect().end.y <= result.content.get_global_rect().position.y, "Header overlaps summary")
		check(result.content.get_global_rect().end.y <= result.bottom_bar.get_global_rect().position.y, "Summary overlaps actions")
		check(result.details.get_global_rect().end.y <= result.bottom_bar.get_global_rect().position.y, "Judgement list overlaps actions")
		check(result.rank_panel.get_global_rect().end.x <= result.score_panel.get_global_rect().position.x, "Rank must sit beside score")
		var analyses := [result.details, result.get_node("%ModsPanel")]
		for panel: Control in analyses:
			check(bounds.encloses(panel.get_global_rect()), "Analysis panel clipped")
			check(not panel.get_global_rect().intersects(result.rank_panel.get_global_rect()), "Analysis panel overlaps rank")
			check(not panel.get_global_rect().intersects(result.stats_column.get_global_rect()), "Analysis panel overlaps score/accuracy")
		check(not analyses[0].get_global_rect().intersects(analyses[1].get_global_rect()), "Summary and mods overlap")
		check(result.perfect_title.get_global_rect().position.x < result.great_title.get_global_rect().position.x and result.great_title.get_global_rect().position.x < result.good_title.get_global_rect().position.x and result.good_title.get_global_rect().position.x < result.miss_title.get_global_rect().position.x, "Judgements must form four distinct summary columns")
		check(not result.get_node("%TimingGraph").is_visible_in_tree() and not result.get_node("%ProgressGraph").is_visible_in_tree(), "Removed graph panels returned")
		check(result.combo_card.is_visible_in_tree() and result.combo_card.get_parent() == result.primary_stats, "Max combo must remain beside accuracy")
		check(result.bottom_bar.alignment == BoxContainer.ALIGNMENT_END and result.replay_button.get_global_rect().position.x > resolution.x * 0.5, "Actions must stay on the right")
		var tags: Control = result.song_column.get_node("SongInfo/SongTags")
		check(absf(tags.get_global_rect().end.y - result.jacket_area.get_global_rect().end.y) < 2.0, "Run tags must align with cover bottom")
		check(result.rank_panel.get_theme_stylebox("panel").corner_radius_top_left > 5, "Rank panel must have genuinely rounded corners")
		check(not result.judgement_bar.visible and not result.accuracy_bar.visible, "Old horizontal dashboard rails returned")
		check(not result.rank_sub.visible, "CLEAR/CALCULATING must not appear during Results reveal")
		for caption in [result.rank_column.get_node("RankCaption"), result.score_vbox.get_node("ScoreHeader/ScoreCaption")]:
			check(caption.get_theme_font_size("font_size") > result.page_title.get_theme_font_size("font_size"), "Outcome captions must be stronger than supporting labels")
		for metric in [result.space_value, result.reverse_value]:
			for reel: Control in metric.get_children():
				check(Rect2(Vector2.ZERO, metric.size).encloses(reel.get_rect()), "Special-note digits overflow their inline slot")
		check(not result.space_value.get_global_rect().intersects(result.space_meta.get_global_rect()), "SPACE hits overlap misses")
		check(not result.reverse_value.get_global_rect().intersects(result.reverse_meta.get_global_rect()), "REVERSE hits overlap misses")
		check(not result.score_value.get_global_rect().intersects(result.primary_stats.get_global_rect()), "Score overlaps accuracy")
		check(result.score_value.text == "2,771,869", "Score changed")
		check(result.accuracy_value.get_numeric_value() > 90.0, "Counts must remain authoritative over stale accuracy")
		check(result.rank_value.text == "A", "Rank must remain derived from canonical accuracy")
		check(result.best_plate.visible and not result.score_status.text.is_empty(), "PB presentation missing")
		check(result.rank_panel.get_global_rect().encloses(result.best_plate.get_global_rect()), "New Best must belong to rank card")
		check(result.score_value.get_display_digits() == "02771869", "Score digit presentation lost zero padding or value")
		check(result.get_node("%TimingGraph").events.size() == sample.judgement_events.size(), "Timing graph lost real events")
		check(result.get_node("%ProgressGraph").max_combo == sample.max_combo, "Timeline combo differs from canonical result")
		check(result.accuracy_value.get_theme_font_size("font_size") > result.combo_value.get_theme_font_size("font_size"), "Accuracy must lead supporting statistics")
		check(result.score_status.text.contains("+10.61 pp"), "PB delta used stale accuracy instead of displayed count-derived accuracy")
		check(result.song_artwork.texture != null, "Bundled jacket missing")
		check(result.song_meta.get_line_count() > 0 and result.song_meta.size.y > 0.0, "Artist/run context collapsed")
		check(result.backdrop.song_texture_path == sample.background, "Generic background selection changed")
		check(result.is_navigation_ready(), "Actions never unlock")
		var labels := [result.perfect_title, result.great_title, result.good_title, result.miss_title,
			result.perfect_value, result.great_value, result.good_value, result.miss_value]
		var colors := [result.GraphScript.COLORS.PERFECT, result.GraphScript.COLORS.GREAT, result.GraphScript.COLORS.GOOD, result.GraphScript.COLORS.MISS]
		for index in labels.size():
			check(labels[index].get_theme_color("font_color").is_equal_approx(colors[index % 4]), "Judgement color overwritten")
		check(result.rank_meter.rank_id == "A" and not result.rank_value.visible, "Generated A is not the visible rank presentation")
		var capture_directory := OS.get_environment("BEAT_UP_QA_RESULT_CAPTURE_DIR")
		if not capture_directory.is_empty():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(capture_directory.path_join("results_%dx%d.png" % [resolution.x, resolution.y]))
	# Each canonical threshold selects its own actual generated letter asset.
	for pair: Array in [[100.0, "SS"], [95.0, "S"], [88.0, "A"], [78.0, "B"], [65.0, "C"], [64.9, "D"]]:
		check(result._rank_for_accuracy(pair[0]) == pair[1], "Rank threshold changed")
		result.set_result({"accuracy": pair[0], "score": 0})
		result._force_final_values()
		check(result.rank_value.text == pair[1], "Displayed badge letter disagrees with rank")
		var texture: Texture2D = result.rank_meter.get_rank_texture()
		check(result.rank_meter.rank_id == pair[1], "Generated glyph disagrees with canonical rank")
		check(result.rank_meter.material.get_shader_parameter("grade_color") == result.rank_meter.GRADE_COLORS[pair[1]], "Rank grade color incorrect")
		check(texture != null and texture.resource_path.ends_with("rank_%s.png" % str(pair[1]).to_lower()), "Wrong rank sprite selected")
		check(not result.rank_value.visible, "Native letter overlaps the generated sprite")
		if texture != null:
			var glyph_image := texture.get_image()
			check(glyph_image.get_pixel(0, 0).a == 0.0 and glyph_image.get_used_rect().has_area(), "Rank sprite must have transparent margins and visible glyph")
	result.rank_meter.set_rank("UNKNOWN")
	check(result.rank_meter.get_rank_texture() == null, "Unknown rank must not silently use another glyph")
	result.set_result({"score": 0})
	check(result.get_node("%TimingGraph").events.is_empty() and result.get_node("%ProgressGraph").events.is_empty(), "Missing timeline must not reuse/fabricate prior events")
	result.set_result({"meta": "xi • MASTER • 8-DIR • AUTHORED • 10★ • 200 BPM", "reverse_percent": 0, "space_hits": 18, "space_total": 18})
	await process_frame
	check(result.song_meta.text == "xi" and result._display_metadata(result.get_last_result_data()) == "xi\nMASTER · 8K · 10★ · 200 BPM", "Artist and run tags must use compact player-facing terminology")
	check(result.get_last_result_data().meta.contains("AUTHORED"), "Display formatting mutated canonical metadata")
	check(result.space_value.get_parent().visible and not result.reverse_value.get_parent().visible, "Unused Reverse row must hide independently of SPACE")
	result.set_result({"meta": "artist · HARD · 4-ARROW · RANDOM", "reverse_percent": 50, "reverse_hits": 1, "reverse_total": 2})
	check(result._display_metadata(result.get_last_result_data()) == "artist\nHARD · 4K", "Run header should not duplicate the mods panel")
	check(result.get_node("%ModsText").text.contains("RANDOM") and result.get_node("%ModsText").text.contains("REVERSE 50%"), "Active mods must remain visible in their panel")
	check(not result.space_value.get_parent().visible and result.reverse_value.get_parent().visible, "Special-note rows retained stale visibility")
	result.set_result({"song_id": "__qa_missing_result_jacket", "title": "A very long song title that must remain inside the header rather than pushing the actions off-screen", "score": 0, "accuracy": 0.0})
	result._force_final_values()
	await process_frame
	check(not result.song_artwork.visible, "Missing jacket leaves an empty artwork block")
	check(not result.special_panel.visible, "Empty special-note strip remains visible")
	check(result.song_column.get_global_rect().encloses(result.song_title.get_global_rect()), "Long title escapes song dossier")
	result.set_result(sample)
	var copy: Dictionary = result.get_last_result_data()
	copy.score = 1
	check(result.get_last_result_data().score == sample.score, "Results snapshot leaked mutable state")
	sample.new_best = false
	sample.record_save_failed = true
	result.set_result(sample)
	await create_timer(1.6).timeout
	check(result.score_status.text.begins_with("RECORD SAVE FAILED"), "Save failure is hidden")
	check(not result.best_plate.visible, "Stale new-best badge")
	var actions := {"retry": 0, "back": 0}
	result.replay_requested.connect(func(): actions.retry += 1)
	result.back_requested.connect(func(): actions.back += 1)
	result.replay_button.pressed.emit()
	result.back_button.pressed.emit()
	check(actions.retry == 1 and actions.back == 0, "Duplicate result action bypassed action lock")
	result.hide()
	check(not result.is_navigation_ready(), "Hidden Results remains actionable")
	result.show()
	result.set_result(sample)
	await create_timer(1.6).timeout
	result.back_button.pressed.emit()
	check(actions.back == 1, "Song Library action missing after fresh reveal")
	var grade_capture := OS.get_environment("BEAT_UP_QA_RESULT_CAPTURE_DIR")
	if not grade_capture.is_empty():
		for grade in ["D", "C", "B", "A", "S", "SS"]:
			result.rank_meter.set_rank(grade)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(grade_capture.path_join("grade_%s.png" % grade.to_lower()))
	result.queue_free()
	await process_frame
	if failures == 0:
		print("RESULT_REDESIGN_TEST: PASS")
	quit(0 if failures == 0 else 1)
