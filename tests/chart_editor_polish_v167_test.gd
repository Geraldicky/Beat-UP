extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	root.size = Vector2i(1440, 900)
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/chart_editor.tscn") as PackedScene
	var editor := packed.instantiate() as Control
	root.add_child(editor)
	await process_frame
	await process_frame
	await process_frame
	editor.size = Vector2(1440.0, 900.0)
	editor.call("_apply_responsive_layout")
	await process_frame
	_validate_desktop(editor)

	root.size = Vector2i(960, 540)
	editor.size = Vector2(960.0, 540.0)
	editor.call("_apply_responsive_layout")
	await process_frame
	await process_frame
	await process_frame
	_validate_compact(editor)

	editor.queue_free()
	await process_frame
	if failures.is_empty():
		print("CHART_EDITOR_POLISH_V167_TEST: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _validate_desktop(editor: Control) -> void:
	_check(editor.size.x >= 1400.0 and editor.size.y >= 880.0, "Chart Editor did not fill the desktop viewport: %s" % editor.size)
	var timeline_panel := editor.get_node("TimelinePanel") as Control
	var transport := editor.get_node("Transport") as Control
	var tools := editor.get_node("Tools") as Control
	var generator := editor.get_node("AutoPanel") as Control
	_check(timeline_panel.size.y >= 250.0, "Desktop timeline is not the dominant workspace")
	_check(transport.get_global_rect().end.y < timeline_panel.get_global_rect().position.y, "Transport overlaps the timeline")
	_check(timeline_panel.get_global_rect().end.y < tools.get_global_rect().position.y, "Timeline overlaps note tools")
	_check(tools.get_global_rect().end.y < generator.get_global_rect().position.y, "Note tools overlap generator")
	_check(editor.get_global_rect().encloses(generator.get_global_rect()), "Generator escaped the desktop viewport")
	_validate_source_row(editor)
	_validate_top_bar(editor)
	_validate_transport(editor)
	var timeline := editor.get_node("TimelinePanel/Timeline") as ChartTimelineView
	_check(timeline.grid_subdivisions == 2 and timeline.snap_enabled, "Timeline did not inherit the default 1/8 snap grid")
	timeline.set_time(30.0)
	var playhead_time := float(timeline.call("_time_for_x", timeline.size.x * timeline.playhead_ratio))
	_check(absf(playhead_time - 30.0) < 0.001, "Timeline playhead no longer maps to the current time")
	_check((editor.get_node("Header") as Label).text == "CHART EDITOR", "Editor header still uses the crowded legacy title")
	_check((editor.get_node("TopBar/SaveButton") as Button).text == "SAVE CHART", "Save action is not clearly labelled")

func _validate_compact(editor: Control) -> void:
	_check(editor.size.x >= 940.0 and editor.size.y >= 520.0, "Chart Editor did not resize to the compact viewport: %s" % editor.size)
	_check(not (editor.get_node("Hint") as Label).visible, "Compact layout should hide the subtitle")
	_check(not (editor.get_node("Info") as Panel).visible, "Compact layout should remove the duplicate summary panel")
	_check(not (editor.get_node("Legend") as Label).visible, "Compact layout should hide the footer shortcut legend")
	for node_path in ["TopBar", "Transport", "TimelinePanel", "Tools", "AutoPanel", "Status"]:
		var control := editor.get_node(node_path) as Control
		_check(editor.get_global_rect().encloses(control.get_global_rect()), "Compact control escaped the viewport: %s %s" % [node_path, control.get_global_rect()])
	_validate_source_row(editor)
	_validate_tool_row(editor)
	_validate_top_bar(editor)
	_validate_transport(editor)

func _validate_source_row(editor: Control) -> void:
	var panel := editor.get_node("AutoPanel") as Control
	var controls: Array[Control] = [
		editor.get_node("AutoPanel/AnalysisSource") as Control,
		editor.get_node("AutoPanel/BrowseWav") as Control,
		editor.get_node("AutoPanel/BrowseFolder") as Control,
		editor.get_node("AutoPanel/TempoMode") as Control,
		editor.get_node("AutoPanel/TempoBpm") as Control,
		editor.get_node("AutoPanel/GenerateAll") as Control,
	]
	for control in controls:
		_check(panel.get_global_rect().encloses(control.get_global_rect()), "Generator control escaped its panel: %s" % control.name)
	for index in range(controls.size() - 1):
		_check(not controls[index].get_global_rect().intersects(controls[index + 1].get_global_rect()), "Generator controls overlap: %s / %s" % [controls[index].name, controls[index + 1].name])

func _validate_tool_row(editor: Control) -> void:
	var controls: Array[Control] = [
		editor.get_node("Tools/AddNormal") as Control,
		editor.get_node("Tools/AddReverse") as Control,
		editor.get_node("Tools/AddSpace") as Control,
		editor.get_node("Tools/DeleteNearest") as Control,
		editor.get_node("Tools/Reload") as Control,
	]
	for index in range(controls.size() - 1):
		_check(not controls[index].get_global_rect().intersects(controls[index + 1].get_global_rect()), "Compact note tools overlap: %s / %s" % [controls[index].name, controls[index + 1].name])

func _validate_top_bar(editor: Control) -> void:
	var controls: Array[Control] = [
		editor.get_node("TopBar/SongSelect") as Control,
		editor.get_node("TopBar/DifficultySelect") as Control,
		editor.get_node("TopBar/SaveButton") as Control,
		editor.get_node("TopBar/UndoButton") as Control,
		editor.get_node("TopBar/RedoButton") as Control,
		editor.get_node("TopBar/BackButton") as Control,
	]
	var panel := editor.get_node("TopBar") as Control
	for control in controls:
		_check(panel.get_global_rect().encloses(control.get_global_rect()), "Top-bar control escaped its panel: %s panel=%s control=%s viewport=%s" % [control.name, panel.get_global_rect(), control.get_global_rect(), editor.size])
	for left_index in range(controls.size()):
		for right_index in range(left_index + 1, controls.size()):
			_check(not controls[left_index].get_global_rect().intersects(controls[right_index].get_global_rect()), "Top-bar controls overlap: %s %s / %s %s viewport=%s" % [controls[left_index].name, controls[left_index].get_global_rect(), controls[right_index].name, controls[right_index].get_global_rect(), editor.size])

func _validate_transport(editor: Control) -> void:
	var controls: Array[Control] = [
		editor.get_node("Transport/Back5") as Control,
		editor.get_node("Transport/Back1") as Control,
		editor.get_node("Transport/PlayPause") as Control,
		editor.get_node("Transport/Forward1") as Control,
		editor.get_node("Transport/Forward5") as Control,
		editor.get_node("Transport/TimeLabel") as Control,
		editor.get_node("Transport/SnapToggle") as Control,
		editor.get_node("Transport/SnapSelect") as Control,
	]
	var panel := editor.get_node("Transport") as Control
	for control in controls:
		_check(panel.get_global_rect().encloses(control.get_global_rect()), "Transport control escaped its panel: %s panel=%s control=%s viewport=%s" % [control.name, panel.get_global_rect(), control.get_global_rect(), editor.size])
	for index in range(controls.size() - 1):
		_check(not controls[index].get_global_rect().intersects(controls[index + 1].get_global_rect()), "Transport controls overlap: %s / %s" % [controls[index].name, controls[index + 1].name])

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
