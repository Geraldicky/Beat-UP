extends RefCounted
class_name MainMenuController

const MinimalThemeScript = preload("res://scripts/ui/minimal_theme.gd")

var host: Control
var menu_buttons: Array[Button] = []
var menu_items: Array = []
var main_menu: Control
var settings_menu: Control
var selection_index: Label
var main_logo: Label
var selection_description: Label
var orb_cluster: Control
var orb_ring: Control
var orb_fill: Control
var menu_visual: Control
var menu_rule: ColorRect
var fallback_button: Button

var focus_index: int = 0
var focus_tween: Tween
var rule_tween: Tween

func configure(
	owner: Control,
	buttons: Array[Button],
	items: Array,
	main_menu_view: Control,
	settings_view: Control,
	selection_index_view: Label,
	logo_view: Label,
	description_view: Label,
	orb_cluster_view: Control,
	orb_ring_view: Control,
	orb_fill_view: Control,
	visual_view: Control,
	rule_view: ColorRect,
	fallback: Button
) -> void:
	host = owner
	menu_buttons = buttons
	menu_items = items.duplicate(true)
	main_menu = main_menu_view
	settings_menu = settings_view
	selection_index = selection_index_view
	main_logo = logo_view
	selection_description = description_view
	orb_cluster = orb_cluster_view
	orb_ring = orb_ring_view
	orb_fill = orb_fill_view
	menu_visual = visual_view
	menu_rule = rule_view
	fallback_button = fallback

func set_focus_index(index: int) -> void:
	focus_index = clampi(index, 0, maxi(0, menu_buttons.size() - 1))

func get_focus_index() -> int:
	return focus_index

func button_for_index(index: int) -> Button:
	if menu_buttons.is_empty():
		return fallback_button
	var safe_index: int = clampi(index, 0, menu_buttons.size() - 1)
	return menu_buttons[safe_index]

func remember_focus(button: Button) -> void:
	var index: int = menu_buttons.find(button)
	if index >= 0:
		focus_index = index

func focus_default() -> void:
	var button: Button = button_for_index(focus_index)
	if button == null:
		return
	button.grab_focus()
	update_selection(button)

func update_selection(button: Button) -> void:
	var index: int = menu_buttons.find(button)
	if index < 0 or index >= menu_items.size():
		return
	focus_index = index
	selection_index.text = ""
	main_logo.text = ""
	selection_description.text = ""
	var accent: Color = MinimalThemeScript.ACCENT_LIGHT if index == 0 else MinimalThemeScript.ACCENT
	if index == menu_buttons.size() - 1:
		accent = MinimalThemeScript.DANGER
	selection_index.add_theme_color_override("font_color", accent)
	orb_ring.set("accent", accent)
	orb_ring.queue_redraw()
	orb_fill.set("fill_color", Color(0.018, 0.024, 0.034, 0.44))
	orb_fill.set("stroke_color", Color(accent, 0.78))
	orb_fill.queue_redraw()
	_move_selection_rule(button, accent)
	if menu_visual != null and menu_visual.has_method("set_selection"):
		menu_visual.call("set_selection", index)

func _move_selection_rule(button: Button, accent: Color) -> void:
	if menu_rule == null or main_menu == null or host == null or not button.is_inside_tree():
		return
	menu_rule.color = Color(accent, 0.92)
	var button_rect := button.get_global_rect()
	var menu_rect := main_menu.get_global_rect()
	var target_y := button_rect.position.y - menu_rect.position.y + (button_rect.size.y - menu_rule.size.y) * 0.5
	if rule_tween != null:
		rule_tween.kill()
	rule_tween = host.create_tween()
	rule_tween.tween_property(menu_rule, "position:y", target_y, 0.16).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

func highlight(button: Button, in_transition: bool) -> void:
	if main_menu == null or not main_menu.visible or settings_menu == null or settings_menu.visible or in_transition:
		return
	update_selection(button)
	if focus_tween != null:
		focus_tween.kill()
	focus_tween = host.create_tween()
	focus_tween.set_parallel(true)
	for item in menu_buttons:
		focus_tween.tween_property(item, "scale", Vector2(1.012, 1.0) if item == button else Vector2.ONE, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		focus_tween.tween_property(item, "modulate:a", 1.0 if item == button else 0.74, 0.12)
	if orb_cluster != null and orb_cluster.visible:
		focus_tween.tween_property(orb_cluster, "scale", Vector2.ONE * 1.012, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func unhighlight(button: Button) -> void:
	if button.has_focus() or main_menu == null or not main_menu.visible or host == null:
		return
	var focused: Button = host.get_viewport().gui_get_focus_owner() as Button
	if focused != null and menu_buttons.has(focused):
		highlight(focused, false)

func process_visual(delta: float, enabled: bool, levels: PackedFloat32Array) -> void:
	if menu_visual != null and menu_visual.has_method("set_audio_levels"):
		menu_visual.call("set_audio_levels", levels if enabled else PackedFloat32Array())
	if enabled:
		var energy: float = 0.0
		for level in levels:
			energy += float(level)
		if levels.size() > 0:
			energy /= float(levels.size())
		if orb_cluster != null and orb_cluster.visible:
			orb_ring.rotation += delta * 0.055
			var pulse: float = energy * 0.055
			if orb_fill != null:
				orb_fill.scale = Vector2.ONE * (1.0 + pulse)
				orb_fill.modulate = Color(1.0, 1.0, 1.0, 0.96 + minf(energy * 0.10, 0.04))
		apply_live_pulse(energy, delta)
	elif orb_fill != null and orb_cluster != null and orb_cluster.visible:
		orb_fill.scale = orb_fill.scale.lerp(Vector2.ONE, minf(delta * 8.0, 1.0))

func apply_live_pulse(energy: float, delta: float) -> void:
	if menu_buttons.is_empty() or host == null:
		return
	var focused: Button = host.get_viewport().gui_get_focus_owner() as Button
	var active_button: Button = focused if focused != null and menu_buttons.has(focused) else button_for_index(focus_index)
	var beat_scale: float = 1.0 + energy * 0.018
	for button in menu_buttons:
		var target_scale: Vector2 = Vector2.ONE
		var target_alpha: float = 0.74
		if button == active_button:
			target_scale = Vector2(1.012 * beat_scale, 1.0 + energy * 0.004)
			target_alpha = 1.0
		button.scale = button.scale.lerp(target_scale, minf(delta * 10.0, 1.0))
		button.modulate.a = lerpf(button.modulate.a, target_alpha, minf(delta * 12.0, 1.0))
