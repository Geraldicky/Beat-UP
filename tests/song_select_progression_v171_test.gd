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

	var selector := instance.get_node("LevelSelect") as Control
	var progress_filter := selector.get_node("MainMargin/RootVBox/Body/WheelColumn/LibraryPanel/LibraryVBox/ProgressToolbar/ProgressFilter")
	var sort_filter := selector.get_node("MainMargin/RootVBox/Body/WheelColumn/LibraryPanel/LibraryVBox/ProgressToolbar/SortFilter")
	var progress_status := selector.get_node("MainMargin/RootVBox/Body/InfoPanel/InfoVBox/ProgressStatus") as Label
	var best_rank := selector.get_node("MainMargin/RootVBox/Body/InfoPanel/InfoVBox/BestHeader/BestRank") as Label
	var count_label := selector.get_node("MainMargin/RootVBox/HeaderRow/TitleBlock/CountLabel") as Label

	_check(progress_filter.get_item_count() == 4, "v17.1 progress filter options are incomplete.")
	_check(sort_filter.get_item_count() == 4, "v17.1 sort options are incomplete.")

	var dummy_store := {
		"megalovania::normal": {
			"score": 123456,
			"accuracy": 91.0,
			"rank": "A",
			"max_combo": 120,
			"perfect": 100,
			"great": 20,
			"good": 4,
			"miss": 0,
			"plays": 3,
			"cleared": true,
			"full_combo": true,
			"best_accuracy": 93.5,
			"best_rank": "S",
			"best_max_combo": 144,
			"progression_model": "v171",
		},
	}
	selector.call("set_best_stats_store", dummy_store)
	selector.call("set_selected_song", "megalovania")
	selector.call("_select_difficulty", "normal")
	await process_frame

	_check(str(selector.call("_recommended_difficulty", "megalovania")) == "hard", "90%+ NORMAL clear should recommend HARD when available.")
	_check(progress_status.text.contains("FULL COMBO"), "Selected chart does not expose Full Combo progression status.")
	_check(progress_status.text.contains("RECOMMENDED: HARD"), "Selected song does not expose recommended difficulty.")
	_check(best_rank.text.contains("S") and best_rank.text.contains("FC"), "Personal-best header does not use aggregate rank / FC progression.")
	_check(count_label.text.contains("CLEARED") and count_label.text.contains("FC"), "Library header does not expose completion totals.")

	selector.set("selected_progress_filter", "Full Combo")
	selector.call("_apply_filters", false)
	await process_frame
	var filtered: Array = selector.get("filtered_song_ids")
	_check(filtered.has("megalovania"), "Full Combo filter did not retain the FC song.")

	instance.queue_free()
	await process_frame
	if failures == 0:
		print("SONG_SELECT_PROGRESSION_V171_TEST: PASS")
	else:
		print("SONG_SELECT_PROGRESSION_V171_TEST: FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
