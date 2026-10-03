extends SceneTree

const Identity = preload("res://scripts/score_identity.gd")
const Settings = preload("res://scripts/user_settings.gd")

var failures := 0

func _initialize() -> void:
	root.size = Vector2i(1440, 900)
	root.content_scale_size = root.size
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)

func _run() -> void:
	Settings.set_input_style("8_direction")
	var library := load("res://scenes/song_library.tscn").instantiate() as Control
	root.add_child(library)
	await process_frame
	await process_frame
	var selector: Control = library.song_select

	_check(selector.progress_filter.get_item_count() == 4, "Progress filter backend options are incomplete.")
	_check(not selector.progress_filter.is_visible_in_tree(), "Secondary progress filter leaked into the release-facing top bar.")
	_check(selector.sort_filter.get_item_count() == 2, "Release sort options must be BPM Asc/Desc only.")

	var chart: Dictionary = selector._find_level("megalovania", "normal")
	_check(not chart.is_empty(), "Progression fixture chart is unavailable.")
	if not chart.is_empty():
		var key: String = Identity.key(chart, Settings.get_input_style(), false)
		var dummy_store := {
			key: {
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
			},
		}
		selector.set_best_stats_store(dummy_store)
		selector.set_selected_song("megalovania")
		selector._select_difficulty("normal")
		await process_frame
		_check(str(selector._recommended_difficulty("megalovania")) == "hard", "90%+ NORMAL clear should recommend HARD when available.")
		selector.selected_progress_filter = "Full Combo"
		selector._apply_filters(false)
		await process_frame
		_check(selector.filtered_song_ids.has("megalovania"), "Full Combo filter did not retain the FC song.")
		selector.selected_progress_filter = "All Progress"
		selector._apply_filters(false)

	library.queue_free()
	await process_frame
	print("SONG_SELECT_PROGRESSION_V171_TEST: ", "PASS" if failures == 0 else "FAIL", " ", failures)
	quit(1 if failures > 0 else 0)
