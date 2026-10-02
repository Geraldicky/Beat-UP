extends SceneTree

const QA_ENVIRONMENT_VARIABLE := "BEAT_UP_QA_STANDALONE_NAVIGATION"
const QA_ENVIRONMENT_VALUE := "isolated"

var failures := 0

func _initialize() -> void:
	if OS.get_environment(QA_ENVIRONMENT_VARIABLE) != QA_ENVIRONMENT_VALUE:
		push_error("Refusing to run standalone Main Menu navigation QA outside its isolated environment.")
		quit(2)
		return
	call_deferred("_run")

func _run() -> void:
	await _wait_for_scene_preloads()
	var navigation: Node = root.get_node("NavigationController")
	_check(not bool(navigation.call("has_registered_shell")), "Standalone test unexpectedly began with a registered AppShell.")
	var startup := Control.new()
	startup.set_script(load("res://scripts/startup.gd"))
	_check(not bool(startup.call("_has_registered_app_shell", navigation)), "Standalone Main Menu accepted NavigationController without a registered AppShell.")
	var startup_source := FileAccess.get_file_as_string("res://scripts/startup.gd")
	_check(startup_source.count("_resident_navigation_controller()") == 3, "Song Library and Chart Studio must both use the registered-shell routing guard.")
	_check(startup_source.contains("SceneTransition.change_scene_quick(path)"), "Standalone Main Menu no longer retains its direct SceneTransition fallback.")
	_check(not bool(navigation.call("is_navigating")), "Standalone routing guard unexpectedly began a navigation transaction.")

	print("MAIN_MENU_STANDALONE_FALLBACK_TEST: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	startup.free()
	await process_frame
	quit(1 if failures > 0 else 0)

func _wait_for_scene_preloads(max_frames: int = 600) -> void:
	var transition: Node = root.get_node("SceneTransition")
	for _frame in range(max_frames):
		var requests: Dictionary = transition.get("preload_requests") as Dictionary
		if requests.is_empty():
			return
		await process_frame
	_check(false, "SceneTransition warm-up did not settle before standalone routing QA.")

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
