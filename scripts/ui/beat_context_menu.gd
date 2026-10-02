extends Node
class_name BeatContextMenu

signal id_pressed(id: int)

const MinimalThemeScript = preload("res://scripts/ui/minimal_theme.gd")

var _items: Array[Dictionary] = []
var _layer: CanvasLayer
var _root: Control
var _panel: PanelContainer
var _list: VBoxContainer
var _anchor_rect := Rect2()
var _prefer_above := false

func clear() -> void:
	_items.clear()
	close(true)

func add_item(label: String, id: int = -1) -> void:
	_items.append({"label": label, "id": _items.size() if id < 0 else id, "disabled": false})

func set_item_disabled(index: int, disabled: bool) -> void:
	if index >= 0 and index < _items.size():
		_items[index]["disabled"] = disabled

func popup_near(anchor: Control, prefer_above: bool = false) -> void:
	if anchor == null or _items.is_empty() or not anchor.is_inside_tree():
		return
	close(true)
	_anchor_rect = anchor.get_global_rect()
	_prefer_above = prefer_above
	_build_popup()

func close(immediate: bool = false) -> void:
	if _layer == null or not is_instance_valid(_layer):
		_clear_refs()
		return
	if immediate or _panel == null:
		_layer.queue_free()
		_clear_refs()
		return
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var closing_layer := _layer
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tween.tween_property(_panel, "modulate:a", 0.0, 0.07)
	tween.tween_property(_panel, "scale", Vector2(0.99, 0.97), 0.08)
	tween.chain().tween_callback(func():
		if is_instance_valid(closing_layer):
			closing_layer.queue_free()
	)
	_clear_refs()

func _unhandled_input(event: InputEvent) -> void:
	if _layer == null:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	close(true)

func _build_popup() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 970
	var host := get_tree().current_scene
	if host == null:
		host = get_tree().root
	host.add_child(_layer)

	_root = Control.new()
	_root.position = Vector2.ZERO
	_root.size = get_viewport().get_visible_rect().size
	_root.mouse_filter = Control.MOUSE_FILTER_PASS
	_layer.add_child(_root)
	var blocker := Button.new()
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blocker.flat = true
	blocker.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "focus"]:
		blocker.add_theme_stylebox_override(state, _transparent_style())
	blocker.pressed.connect(func(): close())
	_root.add_child(blocker)

	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override("panel", MinimalThemeScript.panel_style(Color("111720"), 10, Color(MinimalThemeScript.PINK, 0.72), 1, 7.0))
	_root.add_child(_panel)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 3)
	_panel.add_child(_list)

	for index in range(_items.size()):
		var data := _items[index]
		var option := Button.new()
		option.text = str(data.label)
		option.alignment = HORIZONTAL_ALIGNMENT_LEFT
		option.custom_minimum_size = Vector2(330, 40)
		option.disabled = bool(data.disabled)
		MinimalThemeScript.style_tertiary(option, MinimalThemeScript.PINK)
		option.pressed.connect(_choose.bind(int(data.id)))
		_list.add_child(option)

	_panel.reset_size()
	var desired := Vector2(maxf(330, _panel.get_combined_minimum_size().x), minf(420, _panel.get_combined_minimum_size().y))
	_panel.size = desired
	_position_panel(desired)
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.985, 0.96)
	_panel.pivot_offset = Vector2(desired.x, desired.y if _prefer_above else 0.0)
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.10)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	for child in _list.get_children():
		if child is Button and not child.disabled:
			(child as Button).grab_focus()
			break

func _position_panel(panel_size: Vector2) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var x := clampf(_anchor_rect.position.x, 12.0, maxf(12.0, viewport_size.x - panel_size.x - 12.0))
	var below := _anchor_rect.end.y + 7.0
	var above := _anchor_rect.position.y - panel_size.y - 7.0
	var y := above if _prefer_above else below
	if y < 12.0 or y + panel_size.y > viewport_size.y - 12.0:
		y = below if _prefer_above else above
	y = clampf(y, 12.0, maxf(12.0, viewport_size.y - panel_size.y - 12.0))
	_panel.position = Vector2(x, y)

func _choose(id: int) -> void:
	close()
	id_pressed.emit(id)

func _clear_refs() -> void:
	_layer = null
	_root = null
	_panel = null
	_list = null

func _transparent_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(0, 0, 0, 0)
	return style
