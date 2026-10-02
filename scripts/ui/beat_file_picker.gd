extends Control
class_name BeatFilePicker

signal file_selected(path: String)
signal files_selected(paths: PackedStringArray)
signal dir_selected(path: String)
signal canceled

const MinimalThemeScript = preload("res://scripts/ui/minimal_theme.gd")

enum PickerMode {
	OPEN_FILE = 0,
	OPEN_FILES = 1,
	OPEN_DIRECTORY = 2,
}

@export var title := "Choose a file"
@export_enum("Open File", "Open Files", "Open Directory") var file_mode: int = PickerMode.OPEN_FILE
@export var filters: PackedStringArray = PackedStringArray()
@export var access: int = 2
@export var initial_position: int = 2

var _current_dir := ""
var _selected_paths: PackedStringArray = PackedStringArray()
var _panel: PanelContainer
var _title_label: Label
var _path_input: LineEdit
var _file_list: VBoxContainer
var _scroll: ScrollContainer
var _selection_label: Label
var _confirm_button: Button
var _empty_label: Label
var _sidebar: VBoxContainer
var _list_generation := 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 980
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_interface()

func popup_centered(_minimum_size: Vector2i = Vector2i.ZERO) -> void:
	_open_picker()

func popup_centered_ratio(_ratio: float = 0.8) -> void:
	_open_picker()

func close_requested() -> void:
	_cancel()

func set_current_dir(path: String) -> void:
	if _is_readable_directory(path):
		_current_dir = path.simplify_path()
		if is_node_ready():
			_refresh_directory()

func get_current_dir() -> String:
	return _current_dir

func _open_picker() -> void:
	if _current_dir.is_empty() or not _is_readable_directory(_current_dir):
		_current_dir = _default_directory()
	_selected_paths = PackedStringArray()
	visible = true
	_title_label.text = title.to_upper()
	_refresh_shortcuts()
	_refresh_directory()
	_path_input.grab_focus()
	_path_input.select_all()
	modulate.a = 0.0
	_panel.scale = Vector2(0.985, 0.97)
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.12)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_cancel()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") and not _path_input.has_focus():
		_confirm_selection()
		get_viewport().set_input_as_handled()

func _build_interface() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.008, 0.011, 0.018, 0.90)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_dim_input)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(1040, 700)
	_panel.pivot_offset = Vector2(520, 350)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override("panel", MinimalThemeScript.panel_style(Color("11151d"), 16, Color(MinimalThemeScript.PINK, 0.60), 1, 0.0))
	center.add_child(_panel)

	var outer := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		outer.add_theme_constant_override("margin_" + side, 24)
	_panel.add_child(outer)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	outer.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)
	_title_label = Label.new()
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MinimalThemeScript.apply_heading(_title_label, 28, MinimalThemeScript.TEXT)
	header.add_child(_title_label)
	var close_button := Button.new()
	close_button.text = "CLOSE  ×"
	close_button.custom_minimum_size = Vector2(112, 42)
	MinimalThemeScript.style_tertiary(close_button, MinimalThemeScript.PINK)
	close_button.pressed.connect(_cancel)
	header.add_child(close_button)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	root.add_child(nav)
	var up_button := Button.new()
	up_button.text = "↑  UP"
	up_button.custom_minimum_size = Vector2(92, 42)
	MinimalThemeScript.style_secondary(up_button)
	up_button.pressed.connect(_go_parent)
	nav.add_child(up_button)
	_path_input = LineEdit.new()
	_path_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_input.custom_minimum_size.y = 42
	_path_input.placeholder_text = "Enter a folder path"
	_path_input.text_submitted.connect(_navigate_from_path)
	nav.add_child(_path_input)
	var refresh_button := Button.new()
	refresh_button.text = "REFRESH"
	refresh_button.custom_minimum_size = Vector2(112, 42)
	MinimalThemeScript.style_secondary(refresh_button)
	refresh_button.pressed.connect(_refresh_directory)
	nav.add_child(refresh_button)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	root.add_child(body)

	var side_panel := PanelContainer.new()
	side_panel.custom_minimum_size.x = 190
	side_panel.add_theme_stylebox_override("panel", MinimalThemeScript.panel_style(Color(MinimalThemeScript.SURFACE, 0.72), 10, Color(MinimalThemeScript.BORDER, 0.70), 1, 10.0))
	body.add_child(side_panel)
	_sidebar = VBoxContainer.new()
	_sidebar.add_theme_constant_override("separation", 5)
	side_panel.add_child(_sidebar)

	var list_panel := PanelContainer.new()
	list_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_panel.add_theme_stylebox_override("panel", MinimalThemeScript.panel_style(Color("0b0f16"), 10, Color(MinimalThemeScript.BORDER, 0.72), 1, 8.0))
	body.add_child(list_panel)
	var list_stack := VBoxContainer.new()
	list_stack.add_theme_constant_override("separation", 4)
	list_panel.add_child(list_stack)
	var columns := HBoxContainer.new()
	columns.custom_minimum_size.y = 26
	list_stack.add_child(columns)
	var name_header := Label.new()
	name_header.text = "NAME"
	name_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MinimalThemeScript.apply_mono(name_header, 10, MinimalThemeScript.MUTED)
	columns.add_child(name_header)
	var type_header := Label.new()
	type_header.text = "TYPE"
	type_header.custom_minimum_size.x = 120
	MinimalThemeScript.apply_mono(type_header, 10, MinimalThemeScript.MUTED)
	columns.add_child(type_header)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_stack.add_child(_scroll)
	_file_list = VBoxContainer.new()
	_file_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_file_list.add_theme_constant_override("separation", 3)
	_scroll.add_child(_file_list)
	_empty_label = Label.new()
	_empty_label.text = "NO MATCHING FILES"
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty_label.custom_minimum_size.y = 100
	MinimalThemeScript.apply_mono(_empty_label, 12, MinimalThemeScript.MUTED)
	_file_list.add_child(_empty_label)
	_style_scrollbar()

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	root.add_child(footer)
	_selection_label = Label.new()
	_selection_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_selection_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	MinimalThemeScript.apply_mono(_selection_label, 11, MinimalThemeScript.MUTED)
	footer.add_child(_selection_label)
	var cancel_button := Button.new()
	cancel_button.text = "CANCEL"
	cancel_button.custom_minimum_size = Vector2(132, 44)
	MinimalThemeScript.style_secondary(cancel_button)
	cancel_button.pressed.connect(_cancel)
	footer.add_child(cancel_button)
	_confirm_button = Button.new()
	_confirm_button.text = "CHOOSE"
	_confirm_button.custom_minimum_size = Vector2(170, 44)
	_confirm_button.disabled = true
	MinimalThemeScript.style_primary(_confirm_button)
	_confirm_button.pressed.connect(_confirm_selection)
	footer.add_child(_confirm_button)

func _refresh_shortcuts() -> void:
	for child in _sidebar.get_children():
		child.queue_free()
	var label := Label.new()
	label.text = "PLACES"
	MinimalThemeScript.apply_mono(label, 10, MinimalThemeScript.PINK)
	_sidebar.add_child(label)
	var candidates: Array[Dictionary] = [
		{"label": "HOME", "path": OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP).get_base_dir()},
		{"label": "DESKTOP", "path": OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)},
		{"label": "DOWNLOADS", "path": OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)},
		{"label": "DOCUMENTS", "path": OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)},
		{"label": "MUSIC", "path": OS.get_system_dir(OS.SYSTEM_DIR_MUSIC)},
		{"label": "PROJECT", "path": ProjectSettings.globalize_path("res://")},
		{"label": "USER DATA", "path": ProjectSettings.globalize_path("user://")},
	]
	var seen := {}
	for item in candidates:
		var path := str(item.path).simplify_path()
		if path.is_empty() or seen.has(path) or not _is_readable_directory(path):
			continue
		seen[path] = true
		var button := Button.new()
		button.text = str(item.label)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 38
		MinimalThemeScript.style_tertiary(button)
		button.pressed.connect(_navigate_to.bind(path))
		_sidebar.add_child(button)

func _refresh_directory() -> void:
	if not is_node_ready() or not _is_readable_directory(_current_dir):
		return
	_list_generation += 1
	_selected_paths = PackedStringArray()
	_path_input.text = _current_dir
	for child in _file_list.get_children():
		_file_list.remove_child(child)
		child.queue_free()
	var directories: Array[String] = []
	var files: Array[String] = []
	var directory := DirAccess.open(_current_dir)
	if directory == null:
		_show_empty("THIS FOLDER CANNOT BE OPENED")
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if not entry.begins_with("."):
			if directory.current_is_dir():
				directories.append(entry)
			elif file_mode != PickerMode.OPEN_DIRECTORY and _matches_filters(entry):
				files.append(entry)
		entry = directory.get_next()
	directory.list_dir_end()
	directories.sort_custom(func(a: String, b: String) -> bool: return a.naturalnocasecmp_to(b) < 0)
	files.sort_custom(func(a: String, b: String) -> bool: return a.naturalnocasecmp_to(b) < 0)
	for directory_name in directories:
		_file_list.add_child(_make_entry_button(directory_name, true))
	for file_name in files:
		_file_list.add_child(_make_entry_button(file_name, false))
	_show_empty("NO MATCHING FILES")
	_update_selection_state()

func _make_entry_button(entry_name: String, is_directory: bool) -> Button:
	var button := Button.new()
	button.text = ("▸  " if is_directory else "     ") + entry_name
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 40
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.toggle_mode = not is_directory
	button.tooltip_text = _current_dir.path_join(entry_name)
	MinimalThemeScript.style_tertiary(button, MinimalThemeScript.GOLD if is_directory else MinimalThemeScript.CYAN)
	if is_directory:
		button.pressed.connect(_navigate_to.bind(button.tooltip_text))
	else:
		button.pressed.connect(_toggle_file.bind(button.tooltip_text, button))
		button.gui_input.connect(_on_file_gui_input.bind(button.tooltip_text))
	return button

func _toggle_file(path: String, button: Button) -> void:
	if file_mode == PickerMode.OPEN_FILES:
		if button.button_pressed:
			if not _selected_paths.has(path):
				_selected_paths.append(path)
		else:
			var selected_index := _selected_paths.find(path)
			if selected_index >= 0:
				_selected_paths.remove_at(selected_index)
	else:
		_selected_paths = PackedStringArray([path])
		for child in _file_list.get_children():
			if child is Button and child != button:
				(child as Button).button_pressed = false
		button.button_pressed = true
	_update_selection_state()

func _on_file_gui_input(event: InputEvent, path: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.double_click:
		_selected_paths = PackedStringArray([path])
		_confirm_selection()

func _confirm_selection() -> void:
	if file_mode == PickerMode.OPEN_DIRECTORY:
		dir_selected.emit(_current_dir)
		_close_picker()
		return
	if _selected_paths.is_empty():
		return
	var selected_copy := _selected_paths.duplicate()
	_close_picker()
	if file_mode == PickerMode.OPEN_FILES:
		files_selected.emit(selected_copy)
	else:
		file_selected.emit(selected_copy[0])

func _update_selection_state() -> void:
	var count := _selected_paths.size()
	_confirm_button.disabled = count == 0 and file_mode != PickerMode.OPEN_DIRECTORY
	_confirm_button.text = "CHOOSE FOLDER" if file_mode == PickerMode.OPEN_DIRECTORY else ("IMPORT %d FILES" % count if file_mode == PickerMode.OPEN_FILES and count > 0 else "CHOOSE FILE")
	if count == 0:
		_selection_label.text = _filter_summary()
	elif count == 1:
		_selection_label.text = _selected_paths[0].get_file()
	else:
		_selection_label.text = "%d FILES SELECTED" % count

func _show_empty(message: String) -> void:
	var has_entries := _file_list.get_child_count() > 0
	_empty_label = Label.new()
	_empty_label.text = message
	_empty_label.visible = not has_entries
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty_label.custom_minimum_size.y = 100
	MinimalThemeScript.apply_mono(_empty_label, 12, MinimalThemeScript.MUTED)
	_file_list.add_child(_empty_label)

func _matches_filters(file_name: String) -> bool:
	if filters.is_empty():
		return true
	for raw_filter in filters:
		var pattern_section := str(raw_filter).split(";", false, 1)[0]
		for pattern in pattern_section.split(","):
			var clean_pattern := pattern.strip_edges()
			if not clean_pattern.is_empty() and file_name.matchn(clean_pattern):
				return true
	return false

func _filter_summary() -> String:
	if filters.is_empty():
		return "ALL FILES"
	var labels: Array[String] = []
	for raw_filter in filters:
		var parts := str(raw_filter).split(";", false, 1)
		labels.append((parts[1] if parts.size() > 1 else parts[0]).strip_edges().to_upper())
	return "  ·  ".join(labels)

func _navigate_from_path(path: String) -> void:
	var normalized := path.strip_edges().simplify_path()
	if _is_readable_directory(normalized):
		_navigate_to(normalized)
	else:
		_selection_label.text = "FOLDER NOT FOUND"
		_path_input.grab_focus()
		_path_input.select_all()

func _navigate_to(path: String) -> void:
	if not _is_readable_directory(path):
		return
	_current_dir = path.simplify_path()
	_refresh_directory()

func _go_parent() -> void:
	var parent := _current_dir.get_base_dir()
	if not parent.is_empty() and parent != _current_dir:
		_navigate_to(parent)

func _cancel() -> void:
	if not visible:
		return
	canceled.emit()
	_close_picker()

func _close_picker() -> void:
	visible = false
	_selected_paths = PackedStringArray()

func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_cancel()

func _default_directory() -> String:
	var downloads := OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	if _is_readable_directory(downloads):
		return downloads
	var desktop := OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	if _is_readable_directory(desktop):
		return desktop
	return ProjectSettings.globalize_path("user://")

func _is_readable_directory(path: String) -> bool:
	return not path.is_empty() and DirAccess.open(path) != null

func _style_scrollbar() -> void:
	var bar := _scroll.get_v_scroll_bar()
	bar.custom_minimum_size.x = 5
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0, 0, 0, 0)
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color(MinimalThemeScript.CYAN, 0.35)
	grabber.set_corner_radius_all(3)
	var hover := grabber.duplicate()
	hover.bg_color = Color(MinimalThemeScript.CYAN, 0.72)
	bar.add_theme_stylebox_override("scroll", track)
	bar.add_theme_stylebox_override("scroll_focus", track)
	bar.add_theme_stylebox_override("grabber", grabber)
	bar.add_theme_stylebox_override("grabber_highlight", hover)
	bar.add_theme_stylebox_override("grabber_pressed", hover)
