extends Control
class_name MainMenuVisual

const MinimalThemeScript = preload("res://scripts/ui/minimal_theme.gd")

const AUDIO_BAR_COUNT := 48

var selection_index: int = 0
var target_audio_levels := PackedFloat32Array()
var current_audio_levels := PackedFloat32Array()
var phase := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	target_audio_levels.resize(AUDIO_BAR_COUNT)
	current_audio_levels.resize(AUDIO_BAR_COUNT)
	resized.connect(queue_redraw)
	_apply_album_flow_structure()
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	queue_redraw()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	phase = fmod(phase + delta * 0.42, TAU)
	for index in range(AUDIO_BAR_COUNT):
		var target: float = target_audio_levels[index]
		var response_speed: float = 16.0 if target > current_audio_levels[index] else 5.5
		var weight: float = 1.0 - exp(-response_speed * delta)
		current_audio_levels[index] = lerpf(current_audio_levels[index], target, weight)
	queue_redraw()

func set_selection(index: int) -> void:
	selection_index = clampi(index, 0, 6)
	queue_redraw()

func set_audio_levels(levels: PackedFloat32Array) -> void:
	for index in range(AUDIO_BAR_COUNT):
		target_audio_levels[index] = clampf(levels[index] if index < levels.size() else 0.0, 0.0, 1.0)

func get_audio_levels() -> PackedFloat32Array:
	return current_audio_levels.duplicate()

func _apply_album_flow_structure() -> void:
	var main_menu := get_parent()
	if main_menu == null:
		return
	for node_name in ["MenuBackground", "MenuDim", "MenuTitle", "MenuRule", "NowPlayingCard", "MenuVersion", "UtilityRow"]:
		var node := main_menu.get_node_or_null(node_name) as CanvasItem
		if node != null:
			node.show()
	for node_name in ["OrbCluster", "BackgroundInfo", "SelectionIndex", "SelectionDescription", "MainFooter", "TopAccent"]:
		var node := main_menu.get_node_or_null(node_name) as CanvasItem
		if node != null:
			node.hide()
	var dim := main_menu.get_node_or_null("MenuDim") as ColorRect
	if dim != null:
		dim.color = Color(0.010, 0.016, 0.028, 0.64)
	var background := main_menu.get_node_or_null("MenuBackground") as TextureRect
	if background != null:
		background.modulate = Color(0.58, 0.64, 0.74, 0.48)

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

	# Current-song artwork stays full screen and is controlled by scrims only.
	# No second copy of that artwork is drawn as a foreground content card.
	_draw_edge_vignette()

	var geometry := _brand_geometry()
	var hero_center: Vector2 = geometry["center"] as Vector2
	var hero_radius: float = float(geometry["radius"])
	_draw_brand_panel(hero_center, hero_radius, accent)
	_draw_rhythm_connector(hero_center, hero_radius, accent)

func _draw_edge_vignette() -> void:
	for i in range(20):
		var t := float(i) / 20.0
		var h := size.y * 0.017
		draw_rect(Rect2(0, i * h, size.x, h + 1.0), Color(0.005, 0.009, 0.017, lerpf(0.30, 0.0, t)))
		draw_rect(Rect2(0, size.y - (i + 1) * h, size.x, h + 1.0), Color(0.005, 0.009, 0.017, lerpf(0.26, 0.0, t)))
	# Right-side action scrim improves text stability across bright artwork while
	# remaining borderless and subordinate to the brand panel.
	for i in range(18):
		var t := float(i) / 17.0
		var x := size.x * 0.58 + size.x * 0.025 * float(i)
		var w := size.x * 0.028
		draw_rect(Rect2(x, size.y * 0.13, w, size.y * 0.76), Color(0.004, 0.008, 0.015, lerpf(0.0, 0.25, t)))

func _brand_geometry() -> Dictionary:
	return {
		"center": Vector2(size.x * 0.36, size.y * 0.55),
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
	draw_colored_polygon(shadow_points, Color(0.0, 0.0, 0.0, 0.30))
	draw_colored_polygon(outer_points, Color(MinimalThemeScript.BG, 0.82))
	draw_polyline(_closed(outer_points), Color(accent, 0.58), 2.0, true)

	var inset := radius * 0.76
	var inner_points := _rounded_diamond_points(center, inset, inset * 0.06, 4)
	draw_polyline(_closed(inner_points), Color(MinimalThemeScript.TEXT, 0.13), 1.0, true)
	var core := radius * 0.49
	var core_points := _rounded_diamond_points(center, core, core * 0.055, 4)
	draw_polyline(_closed(core_points), Color(accent, 0.13), 1.0, true)

	# Restrained timing ticks and a low-amplitude waveform make the emblem feel
	# musical without turning it into an animated button.
	for step in range(-3, 4):
		if step == 0:
			continue
		var x := center.x + float(step) * radius * 0.13
		var tick := 8.0 if absi(step) % 2 == 0 else 5.0
		draw_line(Vector2(x, center.y - tick), Vector2(x, center.y + tick), Color(accent, 0.17), 1.0, true)
	_draw_center_waveform(center, radius * 0.58, accent)
	_draw_audio_diamond(center, radius * 1.035, accent)

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

func _draw_center_waveform(center: Vector2, half_width: float, accent: Color) -> void:
	var energy_sum := 0.0
	for level in current_audio_levels:
		energy_sum += level
	var average := energy_sum / maxf(1.0, float(current_audio_levels.size()))
	var points := PackedVector2Array()
	for index in range(25):
		var t := float(index) / 24.0
		var sample_index := clampi(roundi(t * float(AUDIO_BAR_COUNT - 1)), 0, AUDIO_BAR_COUNT - 1)
		var level := current_audio_levels[sample_index]
		var x := center.x - half_width + half_width * 2.0 * t
		var y := center.y + sin(phase * 1.6 + t * 12.0) * (1.0 + average * 2.0) + (level - 0.5) * 7.0
		points.append(Vector2(x, y))
	draw_polyline(points, Color(accent, 0.16 + average * 0.16), 1.0, true)

func _draw_rhythm_connector(hero_center: Vector2, hero_radius: float, accent: Color) -> void:
	var y := hero_center.y
	var start_x := hero_center.x + hero_radius * 1.05
	var end_x := size.x * 0.68
	if end_x <= start_x:
		return
	draw_line(Vector2(start_x, y), Vector2(end_x, y), Color(MinimalThemeScript.TEXT, 0.085), 1.0, true)
	_draw_small_diamond(Vector2(end_x, y), 3.5, Color(accent, 0.52))
	var span := end_x - start_x
	for i in range(1, 9):
		var x := start_x + span * float(i) / 9.0
		var major := i % 3 == 0
		var tick_h := 12.0 if major else 6.0
		var alpha := 0.16 if major else 0.085
		draw_line(Vector2(x, y - tick_h * 0.5), Vector2(x, y + tick_h * 0.5), Color(accent, alpha), 1.0, true)

func _draw_small_diamond(center: Vector2, radius: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0.0, -radius),
		center + Vector2(radius, 0.0),
		center + Vector2(0.0, radius),
		center + Vector2(-radius, 0.0),
	]), color)

func _draw_audio_diamond(center: Vector2, radius: float, accent: Color) -> void:
	var energy_sum := 0.0
	for level in current_audio_levels:
		energy_sum += level
	var average := energy_sum / maxf(1.0, float(current_audio_levels.size()))
	var points := PackedVector2Array([
		center + Vector2(0.0, -radius),
		center + Vector2(radius, 0.0),
		center + Vector2(0.0, radius),
		center + Vector2(-radius, 0.0),
		center + Vector2(0.0, -radius),
	])
	var sample_index := 0
	for edge in range(4):
		var a := points[edge]
		var b := points[edge + 1]
		var tangent := (b - a).normalized()
		var outward := Vector2(tangent.y, -tangent.x)
		if outward.dot((a + b) * 0.5 - center) < 0.0:
			outward = -outward
		var segments: int = int(AUDIO_BAR_COUNT / 4)
		for i in range(segments):
			var t := (float(i) + 0.5) / float(segments)
			var base := a.lerp(b, t)
			var level := current_audio_levels[sample_index] if sample_index < current_audio_levels.size() else 0.0
			var idle := 1.0 + sin(phase * 2.0 + float(sample_index) * 0.48) * 0.7
			var length := idle + level * (9.0 + average * 6.0)
			draw_line(base, base + outward * length, Color(accent, 0.10 + level * 0.42), 1.0, true)
			sample_index += 1

func _draw_diamond(center: Vector2, radius: float, color: Color, width: float) -> void:
	var points := PackedVector2Array([
		center + Vector2(0.0, -radius),
		center + Vector2(radius, 0.0),
		center + Vector2(0.0, radius),
		center + Vector2(-radius, 0.0),
		center + Vector2(0.0, -radius),
	])
	draw_polyline(points, color, width, true)
