extends SceneTree
var failures: int = 0
func check(ok: bool, message: String) -> void:
 if not ok:
  failures += 1
  push_error(message)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 root.get_node("AppSessionState").mark_splash_seen()
 var shell: Control = load("res://scenes/app_shell.tscn").instantiate()
 root.add_child(shell)
 await create_timer(1.0).timeout
 await shell.show_song_library("big_daddy", false)
 var selection: Control = shell.song_library_screen.song_select
 var chart: Dictionary = selection._find_level("big_daddy", selection.selected_difficulty)
 var key: String = preload("res://scripts/score_identity.gd").key(chart, preload("res://scripts/user_settings.gd").get_input_style(), false)
 var run_data: Dictionary = {"run_id": "layout", "score": 999999999, "accuracy": 98.25, "max_combo": 9999, "rank": "S", "perfect": 9999, "great": 15, "good": 2, "miss": 1, "run_full_combo": false, "completed_at": 1700000000}
 selection.set_best_stats_store({key: preload("res://scripts/run_records.gd").merge({}, run_data).entry})
 for resolution: Vector2i in [Vector2i(1280,720), Vector2i(1600,900), Vector2i(1920,1080)]:
  root.size = resolution
  root.content_scale_size = resolution
  await create_timer(0.6).timeout
  print("LAYOUT ", resolution, " play ", selection.play_button.get_global_rect(), " card ", selection.best_card.get_global_rect())
  for control: Control in [selection.play_button, selection.export_button, selection.best_card, selection.wheel_column]:
   check(control.get_global_rect().end.x <= resolution.x + 1, "Horizontal overflow: " + str(control.name))
   check(control.get_global_rect().end.y <= resolution.y + 1, "Vertical overflow: " + str(control.name))
 selection.set_selected_song("ghost")
 var ghost: Dictionary = selection._find_level("ghost", selection.selected_difficulty)
 var original_audio: String = str(ghost.audio)
 ghost.audio = "res://music/missing_test.ogg"
 selection._update_detail(false)
 await create_timer(0.3).timeout
 var play_title := selection.play_button.find_child("PlayTitle", true, false) as Label
 check(selection.play_button.disabled and play_title != null and play_title.text == "AUDIO MISSING", "Missing audio visible and disabled")
 ghost.audio = original_audio
 selection.search_input.text = "nothing_matches_175"
 selection.search_input.text_changed.emit(selection.search_input.text)
 await create_timer(0.3).timeout
 check(selection.run_picker.disabled, "Empty search clears history")
 print("LIBRARY_LAYOUT: ", "PASS" if failures == 0 else "FAIL", " ", failures)
 shell.queue_free()
 await create_timer(0.5).timeout
 quit(1 if failures else 0)
