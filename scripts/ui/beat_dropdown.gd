extends Button
class_name BeatDropdown

signal item_selected(index: int)

const MinimalThemeScript = preload("res://scripts/ui/minimal_theme.gd")

var selected: int = -1
var item_count: int:
	get:
		return _items.size()

var _items: Array[Dictionary] = []
var _popup_layer: CanvasLayer
var _popup_root: Control
var _popup_panel: PanelContainer
var _popup_list: VBoxContainer
var _popup_scroll: ScrollContainer
var _popup_open := false
var _popup_tween: Tween
var _chevron: Label

func _ready() -> void:
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	focus_mode = Control.FOCUS_ALL
	clip_text = true
	text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_to_group("beat_dropdowns")
	_create_chevron()
	_apply_default_style()
	pressed.connect(_toggle_dropdown)
	resized.connect(_layout_chevron)
	visibility_changed.connect(_on_visibility_changed)
	_layout_chevron()

func _exit_tree() -> void:
	_close_dropdown(true)

func _unhandled_key_input(event: InputEvent) -> void:
	if not _popup_open or not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.keycode == KEY_ESCAPE:
		_close_dropdown()
		grab_focus()
		get_viewport().set_input_as_handled()

func clear() -> void:
	_items.clear()
	selected = -1
	text = ""
	_close_dropdown(true)

func add_item(label: String, id: int = -1) -> void:
	var resolved_id := _items.size() if id < 0 else id
	_items.append({"text": label, "id": resolved_id, "metadata": null, "disabled": false})
	if selected < 0:
		select(0)

func select(index: int) -> void:
	if index < 0 or index >= _items.size():
		selected = -1
		text = ""
		return
	selected = index
	text = str(_items[index].get("text", ""))
	_refresh_popup_selection()

func get_item_count() -> int:
	return _items.size()

func get_item_text(index: int) -> String:
	if index < 0 or index >= _items.size():
		return ""
	return str(_items[index].get("text", ""))

func get_item_id(index: int) -> int:
	if index < 0 or index >= _items.size():
		return -1
	return int(_items[index].get("id", index))

func get_selected_id() -> int:
	return get_item_id(selected)

func set_item_metadata(index: int, metadata: Variant) -> void:
	if index < 0 or index >= _items.size():
		return
	_items[index]["metadata"] = metadata

func get_item_metadata(index: int) -> Variant:
	if index < 0 or index >= _items.size():
		return null
	return _items[index].get("metadata", null)

func set_item_disabled(index: int, value: bool) -> void:
	if index < 0 or index >= _items.size():
		return
	_items[index]["disabled"] = value
	_refresh_popup_selection()

func is_item_disabled(index: int) -> bool:
	if index < 0 or index >= _items.size():
		return false
	return bool(_items[index].get("disabled", false))

func remove_item(index: int) -> void:
	if index < 0 or index >= _items.size():
		return
	_items.remove_at(index)
	if _items.is_empty():
		selected = -1
		text = ""
	else:
		select(clampi(selected, 0, _items.size() - 1))
	_close_dropdown(true)

func close_dropdown() -> void:
	_close_dropdown()

func _request_close_from_other(requester: Node) -> void:
	if requester != self:
		_close_dropdown(true)

func _toggle_dropdown() -> void:
	if disabled or _items.is_empty():
		return
	if _popup_open:
		_close_dropdown()
	else:
		_open_dropdown()

func _open_dropdown() -> void:
	if _popup_open or not is_inside_tree():
		return
	get_tree().call_group("beat_dropdowns", "_request_close_from_other", self)
	_popup_open = true
	_update_chevron_state()

	_popup_layer = CanvasLayer.new()
	_popup_layer.layer = 96
	var host := get_tree().current_scene
	if host == null:
		host = get_tree().root
	host.add_child(_popup_layer)

	_popup_root = Control.new()
	_popup_root.name = "BeatDropdownOverlay"
	_popup_root.position = Vector2.ZERO
	_popup_root.size = get_viewport_rect().size
	_popup_root.mouse_filter = Control.MOUSE_FILTER_PASS
	_popup_layer.add_child(_popup_root)

	var blocker := Button.new()
	blocker.name = "OutsideClickBlocker"
	blocker.position = Vector2.ZERO
	blocker.size = _popup_root.size
	blocker.flat = true
	blocker.focus_mode = Control.FOCUS_NONE
	blocker.mouse_default_cursor_shape = Control.CURSOR_ARROW
	for state in ["normal", "hover", "pressed", "focus"]:
		blocker.add_theme_stylebox_override(state, _transparent_style())
	blocker.pressed.connect(func(): _close_dropdown())
	_popup_root.add_child(blocker)

	_popup_panel = PanelContainer.new()
	_popup_panel.name = "DropdownPanel"
	_popup_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_popup_panel.add_theme_stylebox_override("panel", _popup_panel_style())
	_popup_root.add_child(_popup_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	_popup_panel.add_child(margin)

	_popup_scroll = ScrollContainer.new()
	_popup_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_popup_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_popup_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	margin.add_child(_popup_scroll)
	_style_popup_scrollbar(_popup_scroll)

	_popup_list = VBoxContainer.new()
	_popup_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_popup_list.add_theme_constant_override("separation", 2)
	_popup_scroll.add_child(_popup_list)

	for index in range(_items.size()):
		_popup_list.add_child(_make_item_button(index))

	var item_height := 38.0
	var panel_width := clampf(maxf(size.x, 210.0), 210.0, minf(460.0, get_viewport_rect().size.x - 24.0))
	var desired_height := minf(float(_items.size()) * item_height + 14.0, 322.0)
	_popup_panel.size = Vector2(panel_width, desired_height)
	_popup_scroll.custom_minimum_size = Vector2(panel_width - 12.0, desired_height - 12.0)
	_position_popup(panel_width, desired_height)

	_popup_panel.modulate.a = 0.0
	_popup_panel.scale = Vector2(0.985, 0.96)
	_popup_panel.pivot_offset = Vector2(panel_width, 0.0) if _popup_panel.position.x < global_position.x else Vector2.ZERO
	_popup_tween = create_tween()
	_popup_tween.set_parallel(true)
	_popup_tween.tween_property(_popup_panel, "modulate:a", 1.0, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_popup_tween.tween_property(_popup_panel, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	if selected >= 0 and selected < _popup_list.get_child_count():
		(_popup_list.get_child(selected) as Button).grab_focus()

func _close_dropdown(immediate: bool = false) -> void:
	if not _popup_open and _popup_layer == null:
		return
	_popup_open = false
	_update_chevron_state()
	if _popup_tween != null and _popup_tween.is_valid():
		_popup_tween.kill()
		_popup_tween = null
	if _popup_layer == null or not is_instance_valid(_popup_layer):
		_popup_layer = null
		_popup_root = null
		_popup_panel = null
		_popup_list = null
		_popup_scroll = null
		return
	if immediate or _popup_panel == null or not is_instance_valid(_popup_panel):
		_popup_layer.queue_free()
		_clear_popup_refs()
		return
	_popup_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_popup_tween = create_tween()
	_popup_tween.set_parallel(true)
	_popup_tween.tween_property(_popup_panel, "modulate:a", 0.0, 0.07)
	_popup_tween.tween_property(_popup_panel, "scale", Vector2(0.99, 0.97), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_popup_tween.chain().tween_callback(_finish_popup_close)

func _finish_popup_close() -> void:
	if _popup_layer != null and is_instance_valid(_popup_layer):
		_popup_layer.queue_free()
	_clear_popup_refs()

func _clear_popup_refs() -> void:
	_popup_layer = null
	_popup_root = null
	_popup_panel = null
	_popup_list = null
	_popup_scroll = null
	_popup_tween = null

func _position_popup(panel_width: float, panel_height: float) -> void:
	if _popup_panel == null:
		return
	var viewport_size := get_viewport_rect().size
	var rect := get_global_rect()
	var x := rect.position.x
	if x + panel_width > viewport_size.x - 10.0:
		x = viewport_size.x - panel_width - 10.0
	x = maxf(10.0, x)
	var y := rect.end.y + 6.0
	if y + panel_height > viewport_size.y - 10.0:
		y = rect.position.y - panel_height - 6.0
	if y < 10.0:
		y = 10.0
	_popup_panel.position = Vector2(x, y)

func _make_item_button(index: int) -> Button:
	var data: Dictionary = _items[index]
	var option := Button.new()
	option.name = "Option_%d" % index
	option.text = str(data.get("text", ""))
	option.alignment = HORIZONTAL_ALIGNMENT_LEFT
	option.custom_minimum_size = Vector2(0.0, 36.0)
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.focus_mode = Control.FOCUS_ALL
	option.disabled = bool(data.get("disabled", false))
	option.add_theme_font_override("font", MinimalThemeScript.medium_font())
	option.add_theme_font_size_override("font_size", 12)
	option.add_theme_color_override("font_color", MinimalThemeScript.TEXT)
	option.add_theme_color_override("font_hover_color", MinimalThemeScript.TEXT)
	option.add_theme_color_override("font_pressed_color", MinimalThemeScript.TEXT)
	option.add_theme_color_override("font_focus_color", MinimalThemeScript.TEXT)
	option.add_theme_color_override("font_disabled_color", Color(MinimalThemeScript.MUTED, 0.38))
	var is_selected := index == selected
	option.add_theme_stylebox_override("normal", _popup_item_style(is_selected, false))
	option.add_theme_stylebox_override("hover", _popup_item_style(is_selected, true))
	option.add_theme_stylebox_override("pressed", _popup_item_style(true, true))
	option.add_theme_stylebox_override("focus", _popup_item_style(is_selected, true))
	option.add_theme_stylebox_override("disabled", _popup_item_disabled_style())
	option.pressed.connect(_select_popup_item.bind(index))
	return option

func _select_popup_item(index: int) -> void:
	if index < 0 or index >= _items.size() or is_item_disabled(index):
		return
	select(index)
	item_selected.emit(index)
	_close_dropdown()
	grab_focus()

func _refresh_popup_selection() -> void:
	if _popup_list == null or not is_instance_valid(_popup_list):
		return
	for index in range(_popup_list.get_child_count()):
		var option := _popup_list.get_child(index) as Button
		if option == null:
			continue
		var is_selected := index == selected
		option.add_theme_stylebox_override("normal", _popup_item_style(is_selected, false))
		option.add_theme_stylebox_override("hover", _popup_item_style(is_selected, true))
		option.add_theme_stylebox_override("focus", _popup_item_style(is_selected, true))

func _create_chevron() -> void:
	_chevron = Label.new()
	_chevron.name = "Chevron"
	_chevron.text = "▾"
	_chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chevron.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chevron.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_chevron.add_theme_font_override("font", MinimalThemeScript.medium_font())
	_chevron.add_theme_font_size_override("font_size", 13)
	_chevron.add_theme_color_override("font_color", MinimalThemeScript.CYAN)
	add_child(_chevron)

func _layout_chevron() -> void:
	if _chevron == null:
		return
	# Keep the chevron in a full-height right-side slot so the glyph's baseline
	# never makes it look too high/low across different button heights.
	_chevron.position = Vector2(maxf(0.0, size.x - 38.0), 0.0)
	_chevron.size = Vector2(28.0, size.y)

func _update_chevron_state() -> void:
	if _chevron == null:
		return
	_chevron.text = "▴" if _popup_open else "▾"
	_chevron.add_theme_color_override("font_color", MinimalThemeScript.PINK if _popup_open else MinimalThemeScript.CYAN)

func _on_visibility_changed() -> void:
	if not visible:
		_close_dropdown(true)

func _apply_default_style() -> void:
	add_theme_font_override("font", MinimalThemeScript.medium_font())
	add_theme_font_size_override("font_size", 13)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		add_theme_color_override(color_name, MinimalThemeScript.TEXT)
	add_theme_color_override("font_disabled_color", Color(MinimalThemeScript.MUTED, 0.44))
	add_theme_stylebox_override("normal", _closed_style(Color(MinimalThemeScript.SURFACE_RAISED, 0.82), Color(MinimalThemeScript.BORDER, 0.84)))
	add_theme_stylebox_override("hover", _closed_style(Color(MinimalThemeScript.CYAN, 0.10), Color(MinimalThemeScript.CYAN, 0.82)))
	add_theme_stylebox_override("pressed", _closed_style(Color(MinimalThemeScript.CYAN, 0.15), MinimalThemeScript.CYAN))
	add_theme_stylebox_override("focus", _closed_style(Color(MinimalThemeScript.SURFACE_RAISED, 0.96), Color(MinimalThemeScript.PINK, 0.82)))
	add_theme_stylebox_override("disabled", _closed_style(Color(MinimalThemeScript.SURFACE, 0.50), Color(MinimalThemeScript.BORDER, 0.36)))

func _closed_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := MinimalThemeScript.panel_style(fill, 8, border, 1, 0.0)
	style.content_margin_left = 14.0
	style.content_margin_right = 40.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	return style

func _popup_panel_style() -> StyleBoxFlat:
	var style := MinimalThemeScript.panel_style(Color("111720"), 9, Color(MinimalThemeScript.CYAN, 0.72), 1, 0.0)
	return style

func _popup_item_style(is_selected: bool, highlighted: bool) -> StyleBoxFlat:
	var fill := Color(MinimalThemeScript.CYAN, 0.15) if is_selected else Color(MinimalThemeScript.SURFACE_RAISED, 0.35)
	if highlighted:
		fill = Color(MinimalThemeScript.CYAN, 0.22 if is_selected else 0.11)
	var border := Color(MinimalThemeScript.CYAN, 0.82 if is_selected else (0.48 if highlighted else 0.0))
	var style := MinimalThemeScript.panel_style(fill, 6, border, 0, 0.0)
	style.border_width_left = 3 if is_selected else 0
	style.content_margin_left = 14.0
	style.content_margin_right = 12.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	return style

func _popup_item_disabled_style() -> StyleBoxFlat:
	var style := MinimalThemeScript.panel_style(Color(MinimalThemeScript.SURFACE, 0.30), 6, Color(0, 0, 0, 0), 0, 0.0)
	style.content_margin_left = 14.0
	style.content_margin_right = 12.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	return style

func _transparent_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(0, 0, 0, 0)
	style.set_border_width_all(0)
	return style

func _style_popup_scrollbar(scroll: ScrollContainer) -> void:
	var bar := scroll.get_v_scroll_bar()
	if bar == null:
		return
	bar.custom_minimum_size.x = 3.0
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0, 0, 0, 0)
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color(MinimalThemeScript.CYAN, 0.28)
	grabber.set_corner_radius_all(2)
	var hover := grabber.duplicate()
	hover.bg_color = Color(MinimalThemeScript.CYAN, 0.58)
	bar.add_theme_stylebox_override("scroll", track)
	bar.add_theme_stylebox_override("scroll_focus", track)
	bar.add_theme_stylebox_override("grabber", grabber)
	bar.add_theme_stylebox_override("grabber_highlight", hover)
	bar.add_theme_stylebox_override("grabber_pressed", hover)
