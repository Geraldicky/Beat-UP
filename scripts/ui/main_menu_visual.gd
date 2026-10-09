extends Control
class_name MainMenuVisual

const MinimalThemeScript = preload("res://scripts/ui/minimal_theme.gd")

var selection_index: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	_apply_album_flow_structure()
	# Startup owns boot presentation; AppShell owns resident route reveals.
	# A child-local tween would resume later when its hidden parent is activated.
	queue_redraw()

func set_selection(index: int) -> void:
	selection_index = clampi(index, 0, 6)
	queue_redraw()

func set_audio_levels(_levels: PackedFloat32Array) -> void:
	# Main Menu waveforms were intentionally removed. Keep this method as a
	# compatibility no-op for the existing controller contract.
	pass

func get_audio_levels() -> PackedFloat32Array:
	return PackedFloat32Array()

func _apply_album_flow_structure() -> void:
	var main_menu := get_parent()
	if main_menu == null:
		return
	for node_name in ["MenuBackground", "MenuDim", "MenuTitle", "NowPlayingCard", "MenuVersion", "UtilityRow"]:
		var node := main_menu.get_node_or_null(node_name) as CanvasItem
		if node != null:
			node.show()
	for node_name in ["MenuRule", "OrbCluster", "BackgroundInfo", "SelectionIndex", "SelectionDescription", "MainFooter", "TopAccent"]:
		var node := main_menu.get_node_or_null(node_name) as CanvasItem
		if node != null:
			node.hide()
	# Match the Library's restrained generic-background exposure so resident
	# navigation does not jump between authored brightness and a dark scrim.
	var background := main_menu.get_node_or_null("MenuBackground") as TextureRect
	if background != null:
		background.modulate = Color.WHITE
	var dim := main_menu.get_node_or_null("MenuDim") as ColorRect
	if dim != null:
		dim.color.a = 0.0

func _selection_accent() -> Color:
	if selection_index == 3:
		return MinimalThemeScript.DANGER
	if selection_index == 0:
		return MinimalThemeScript.ACCENT_LIGHT
	return MinimalThemeScript.ACCENT

func _draw() -> void:
	if size.x <= 2.0 or size.y <= 2.0:
		return
	var accent := _selection_accent()

	# Current-song artwork stays full screen behind the interface. Keep this
	# visual layer transparent so the background is not banded or corner-darkened.

	_draw_ambient_motifs(accent)

	var geometry := _brand_geometry()
	var hero_center: Vector2 = geometry["center"] as Vector2
	var hero_radius: float = float(geometry["radius"])
	_draw_brand_panel(hero_center, hero_radius, accent)
	_draw_rhythm_connector(hero_center, hero_radius, accent)

func _draw_ambient_motifs(accent: Color) -> void:
	# Lightweight geometry from the approved mockup. These are line-only accents:
	# no dark overlays, fills, or vignettes over the authored song background.
	var faint := Color(accent, 0.12)
	var faint_text := Color(MinimalThemeScript.TEXT, 0.075)

	draw_line(Vector2(-24.0, size.y * 0.12), Vector2(size.x * 0.23, size.y * 0.42), faint, 1.0, true)
	draw_line(Vector2(size.x * 0.50, size.y * 0.61), Vector2(size.x * 0.77, size.y * 0.92), faint_text, 1.0, true)
	draw_line(Vector2(size.x * 0.69, size.y * 0.36), Vector2(size.x * 0.82, size.y * 0.15), faint_text, 1.0, true)

	_draw_diamond(Vector2(size.x * 0.115, size.y * 0.31), 28.0, Color(accent, 0.16), 1.0)
	_draw_diamond(Vector2(size.x * 0.605, size.y * 0.74), 30.0, Color(accent, 0.18), 1.0)
	_draw_diamond(Vector2(size.x * 0.785, size.y * 0.17), 18.0, Color(accent, 0.17), 1.0)
	_draw_diamond(Vector2(size.x * 0.055, size.y * 0.88), 12.0, Color(accent, 0.12), 1.0)

	for i in range(4):
		var p := Vector2(size.x * (0.64 + 0.035 * float(i)), size.y * (0.19 + 0.04 * float(i)))
		_draw_small_diamond(p, 3.0 + float(i % 2), Color(accent, 0.16))

func _brand_geometry() -> Dictionary:
	return {
		"center": Vector2(size.x * 0.36, size.y * 0.52),
		"radius": clampf(minf(size.x * 0.145, size.y * 0.25), 164.0, 270.0),
	}

func get_brand_panel_bounds() -> Rect2:
	var geometry := _brand_geometry()
	var center: Vector2 = geometry["center"] as Vector2
	var radius: float = float(geometry["radius"])
	return Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)

func has_foreground_artwork_card() -> bool:
	return false

func _draw_brand_panel(center: Vector2, radius: float, accent: Color) -> void:
	var outer_points := _rounded_diamond_points(center, radius, radius * 0.075, 5)
	var shadow_points := _rounded_diamond_points(center + Vector2(10.0, 14.0), radius, radius * 0.075, 5)
	draw_colored_polygon(shadow_points, Color(0.0, 0.0, 0.0, 0.20))
	draw_colored_polygon(outer_points, Color(MinimalThemeScript.BG, 0.66))
	draw_polyline(_closed(outer_points), Color(accent, 0.72), 2.0, true)

	var inset := radius * 0.76
	var inner_points := _rounded_diamond_points(center, inset, inset * 0.06, 4)
	draw_polyline(_closed(inner_points), Color(MinimalThemeScript.TEXT, 0.18), 1.0, true)
	var core := radius * 0.49
	var core_points := _rounded_diamond_points(center, core, core * 0.055, 4)
	draw_polyline(_closed(core_points), Color(accent, 0.17), 1.0, true)

	# Keep the emblem deliberately static. Waveform and audio-reactive perimeter
	# treatments were removed from the Main Menu.

func _rounded_diamond_points(center: Vector2, radius: float, corner: float, segments: int) -> PackedVector2Array:
	var vertices := PackedVector2Array([
		center + Vector2(0.0, -radius),
		center + Vector2(radius, 0.0),
		center + Vector2(0.0, radius),
		center + Vector2(-radius, 0.0),
	])
	var points := PackedVector2Array()
	var safe_corner := clampf(corner, 1.0, radius * 0.25)
	for index in range(vertices.size()):
		var vertex := vertices[index]
		var previous := vertices[posmod(index - 1, vertices.size())]
		var following := vertices[(index + 1) % vertices.size()]
		var incoming := vertex + (previous - vertex).normalized() * safe_corner
		var outgoing := vertex + (following - vertex).normalized() * safe_corner
		if points.is_empty():
			points.append(incoming)
		for segment in range(1, segments + 1):
			var t := float(segment) / float(segments)
			var point := incoming * (1.0 - t) * (1.0 - t) + vertex * 2.0 * (1.0 - t) * t + outgoing * t * t
			points.append(point)
	return points

func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	if not result.is_empty():
		result.append(result[0])
	return result

func _draw_rhythm_connector(hero_center: Vector2, hero_radius: float, accent: Color) -> void:
	var y := hero_center.y
	var start_x := hero_center.x + hero_radius * 1.05
	var end_x := size.x * 0.68
	if end_x <= start_x:
		return
	draw_line(Vector2(start_x, y), Vector2(end_x, y), Color(MinimalThemeScript.TEXT, 0.22), 1.0, true)
	_draw_small_diamond(Vector2(end_x, y), 4.0, Color(accent, 0.78))
	var span := end_x - start_x
	for i in range(1, 9):
		var x := start_x + span * float(i) / 9.0
		var major := i % 3 == 0
		var tick_h := 12.0 if major else 6.0
		var alpha := 0.28 if major else 0.16
		draw_line(Vector2(x, y - tick_h * 0.5), Vector2(x, y + tick_h * 0.5), Color(accent, alpha), 1.0, true)

func _draw_small_diamond(center: Vector2, radius: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0.0, -radius),
		center + Vector2(radius, 0.0),
		center + Vector2(0.0, radius),
		center + Vector2(-radius, 0.0),
	]), color)

func _draw_diamond(center: Vector2, radius: float, color: Color, width: float) -> void:
	var points := PackedVector2Array([
		center + Vector2(0.0, -radius),
		center + Vector2(radius, 0.0),
		center + Vector2(0.0, radius),
		center + Vector2(-radius, 0.0),
		center + Vector2(0.0, -radius),
	])
	draw_polyline(points, color, width, true)
