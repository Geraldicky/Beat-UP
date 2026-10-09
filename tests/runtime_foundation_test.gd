extends SceneTree

var failures := 0
var frame_count := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func count_frame() -> void:
	frame_count += 1

func _run() -> void:
	if OS.get_environment("BEAT_UP_QA_RUNTIME_FOUNDATION") != "isolated":
		push_error("Requires isolated QA user data.")
		quit(1)
		return
	var catalog := LevelCatalog.new()
	catalog.scan_roots = PackedStringArray(["res://charts"])
	root.add_child(catalog)
	process_frame.connect(count_frame)
	var resolved := await catalog.resolve_playable_async("bad_apple", "normal")
	process_frame.disconnect(count_frame)
	check(bool(resolved.get("ok", false)), "Async authoritative resolution failed.")
	check(frame_count > 0, "Preparation must yield frames to loading UI.")
	check(catalog.get("_launch_thread") == null and catalog.get("_launch_worker") == null, "Completed launch must release worker/thread.")
	var sync_result := catalog.resolve_playable("bad_apple", "normal", true)
	check(resolved.get("chart") == sync_result.get("chart"), "Async and sync resolution must select identical authoritative chart.")
	var invalid := await catalog.resolve_playable_async("no_such_song", "normal")
	check(not bool(invalid.get("ok", true)), "Missing chart must fail rather than use stale chart.")
	var recovered := await catalog.resolve_playable_async("bad_apple", "normal")
	check(bool(recovered.get("ok", false)), "Failed launch must not poison next preparation.")
	var session := root.get_node("MusicSession")
	var chart: Dictionary = resolved.get("chart", {})
	check(bool(session.call("play_track", str(chart.get("audio", "")), 2.0, {}, true, false, 0.0)), "Music fixture must play.")
	session.call("set_paused", true)
	session.call("ensure_playing", 0.0)
	check(bool(session.player.stream_paused), "Automatic keep-alive must preserve user pause.")
	session.call("set_paused", false)
	check(not bool(session.player.stream_paused), "Explicit Resume must revoke user pause.")
	var main := (load("res://main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await process_frame
	main.set_process(false)
	main.set("pause_raw_music_snapshot_s", 12.0)
	main.set("pause_timing_snapshot_valid", true)
	main.set("game_paused", true)
	main.set("user_audio_offset_ms", 50.0)
	check(is_equal_approx(float(main.call("get_music_time")), 11.95), "Paused canonical clock must freeze and apply audio offset once.")
	await process_frame
	check(is_equal_approx(float(main.call("get_raw_music_time")), 12.0), "Paused mixer interpolation must not advance the clock.")
	main.set("music_has_finished", true)
	main.set("fight_time", 20.0)
	check(is_equal_approx(float(main.call("get_music_time")), 20.0), "Paused post-audio tail must not advance wall-clock time.")
	main.call("_reset_runtime_timing_state")
	check(not bool(main.get("runtime_audio_clock_initialized")), "Seek/retry reset must allow a new clock origin.")
	main.queue_free()
	catalog.queue_free()
	await process_frame
	print("RUNTIME_FOUNDATION_TEST: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
