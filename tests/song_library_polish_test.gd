extends SceneTree

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
	var scene := load("res://main.tscn") as PackedScene
	var instance := scene.instantiate() as Control
	root.add_child(instance)
	await process_frame
	await process_frame
	await create_timer(0.12).timeout

	var selector := instance.get_node("LevelSelect") as Control
	var info_panel := selector.get_node("MainMargin/RootVBox/Body/InfoPanel") as Control
	var library_panel := selector.get_node("MainMargin/RootVBox/Body/WheelColumn/LibraryPanel") as Control
	var filters_panel := selector.get_node("MainMargin/RootVBox/Body/WheelColumn/LibraryPanel/LibraryVBox/LibraryToolbar/FiltersPanel") as Control
	var search_input := selector.get_node("MainMargin/RootVBox/Body/WheelColumn/LibraryPanel/LibraryVBox/LibraryToolbar/SearchInput") as LineEdit
	var play_button := selector.get_node("MainMargin/RootVBox/Body/InfoPanel/InfoVBox/ActionRow/PlayButton") as Button
	var mode_status := selector.get_node("MainMargin/RootVBox/Body/InfoPanel/InfoVBox/HeroPanel/HeroContent/HeroOverlay/HeroVBox/HeroBottom/ModeStatus") as Label
	var best_grid := selector.get_node("MainMargin/RootVBox/Body/InfoPanel/InfoVBox/BestGrid") as GridContainer
	var best_rank := selector.get_node("MainMargin/RootVBox/Body/InfoPanel/InfoVBox/BestHeader/BestRank") as Label
	var footer_status := selector.get_node("MainMargin/RootVBox/FooterPanel/Footer/FooterStatus") as Label

	_check(not info_panel.get_global_rect().intersects(library_panel.get_global_rect()), "Song detail and library panels overlap.")
	_check(library_panel.is_ancestor_of(filters_panel), "Song filters are not integrated into the library panel.")
	_check(library_panel.is_ancestor_of(search_input), "Song search is not integrated into the library panel.")
	_check(library_panel.get_global_rect().encloses(search_input.get_global_rect()), "Song search extends outside the library panel.")
	_check(not search_input.get_global_rect().intersects(filters_panel.get_global_rect()), "Song search overlaps the filter controls.")
	_check(selector.get_global_rect().encloses(play_button.get_global_rect()), "Primary Play action extends outside the viewport.")
	_check(footer_status.text.is_empty(), "Song Library still shows redundant footer copy by default.")

	selector.call("set_best_stats_store", {})
	await process_frame
	var default_song := str(selector.call("get_selected_song_id"))
	var default_difficulty := str(selector.call("get_selected_difficulty"))
	var default_chart := selector.call("_find_level", default_song, default_difficulty) as Dictionary
	_check(bool(selector.call("_chart_is_playable", default_chart)), "Song Library did not prefer a playable song on entry.")
	_check(not play_button.disabled and not mode_status.visible and mode_status.text.is_empty(), "Playable chart still exposes redundant READY status copy.")
	_check(best_grid.visible and not best_rank.visible, "v17.1.1 should keep the flat personal-best fields visible with dash placeholders.")

	selector.call("set_selected_song", "2_starting_over")
	await process_frame
	await create_timer(0.08).timeout
	_check(not play_button.disabled, "2 Starting Over is generated but Play is disabled.")
	_check(not mode_status.visible and mode_status.text.is_empty(), "Playable generated chart still exposes redundant READY status copy.")
	var rows: Array = selector.get("song_difficulty_rows")
	var filtered_ids: Array = selector.get("filtered_song_ids")
	var generated_song_index := filtered_ids.find("2_starting_over")
	if generated_song_index >= 0 and generated_song_index < rows.size() and not (rows[generated_song_index] as Array).is_empty():
		var row := (rows[generated_song_index] as Array)[0] as Dictionary
		_check(not (row["button"] as Button).text.contains("NOT GENERATED"), "Generated difficulty row is still labeled NOT GENERATED.")
	else:
		_check(false, "2 Starting Over is missing from the library.")

	search_input.text = "megalovania"
	selector.call("_on_search_changed", search_input.text)
	await process_frame
	filtered_ids = selector.get("filtered_song_ids")
	_check(filtered_ids.size() == 1 and str(filtered_ids[0]) == "megalovania", "Song search did not filter by title.")

	search_input.text = "no song can match this"
	selector.call("_on_search_changed", search_input.text)
	await process_frame
	filtered_ids = selector.get("filtered_song_ids")
	_check(filtered_ids.is_empty(), "Song search did not expose an empty result state.")
	_check(play_button.disabled, "Play remains enabled when search has no results.")
	_check(selector.find_child("EmptyLibraryState", true, false) != null, "Empty search result has no clear visual state.")

	search_input.clear()
	selector.call("_on_search_changed", "")
	await process_frame
	_check(not (selector.get("filtered_song_ids") as Array).is_empty(), "Clearing search did not restore the song catalog.")

	instance.queue_free()
	await process_frame
	await process_frame
	if failures == 0:
		print("SONG_LIBRARY_POLISH_TEST: PASS")
	else:
		print("SONG_LIBRARY_POLISH_TEST: FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
