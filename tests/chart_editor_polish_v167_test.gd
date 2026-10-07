extends SceneTree

# The editor was explicitly retired. Keep this historical entry point truthful.
func _initialize() -> void:
	var retired := not ResourceLoader.exists("res://scenes/chart_editor.tscn")
	if not retired:
		push_error("Retired Chart Studio scene is still shipped.")
	print("CHART_EDITOR_RETIREMENT_TEST: %s" % ("PASS" if retired else "FAIL"))
	quit(0 if retired else 1)
