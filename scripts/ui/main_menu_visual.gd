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
	for node_name in ["MenuBackground", "MenuDim", "MenuTitle", "MenuRule", "NowPlayingCard", "OrbCluster"]:
		var node := main_menu.get_node_or_null(node_name) as CanvasItem
		if node != null:
			node.show()
	for node_name in ["BackgroundInfo", "SelectionIndex", "SelectionDescription", "MainFooter", "TopAccent"]:
		var node := main_menu.get_node_or_null(node_name) as CanvasItem
		if node != null:
			node.hide()
	var dim := main_menu.get_node_or_null("MenuDim") as ColorRect
	if dim != null:
		dim.color = Color(0.012, 0.020, 0.033, 0.68)
	var background := main_menu.get_node_or_null("MenuBackground") as TextureRect
	if background != null:
		background.modulate = Color(0.66, 0.72, 0.82, 0.44)

func _selection_accent() -> Color:
	if selection_index == 6:
		return MinimalThemeScript.DANGER
	if selection_index == 0:
		return MinimalThemeScript.ACCENT_LIGHT
	return MinimalThemeScript.ACCENT

func _draw() -> void:
	if size.x <= 2.0 or size.y <= 2.0:
		return
	var accent := _selection_accent()

	# Keep the full-screen artwork quiet, but give the canvas directional depth:
	# darker at the navigation rail, slightly more open around the hero.
	_draw_edge_vignette()

	var hero_center := Vector2(size.x * 0.685, size.y * 0.455)
	var hero_radius := clampf(minf(size.x * 0.165, size.y * 0.275), 178.0, 282.0)

	# Reintroduce song identity as atmosphere rather than a foreground album card.
	_draw_ghost_artwork(hero_center, hero_radius)

	# One visual anchor with distinct hierarchy instead of several equally-faint
	# outlines. The outer field supplies scale; the primary diamond owns focus.
	_draw_diamond(hero_center, hero_radius * 1.28, Color(accent, 0.045), 1.0)
	_draw_diamond(hero_center, hero_radius * 1.06, Color(accent, 0.24), 2.0)
	_draw_diamond(hero_center, hero_radius * 0.77, Color(MinimalThemeScript.TEXT, 0.10), 1.0)
	_draw_diamond(hero_center, hero_radius * 0.54, Color(accent, 0.055), 1.0)
	_draw_audio_diamond(hero_center, hero_radius * 1.095, accent)

	# Rhythm connector ties the left navigation and hero into one composition.
	_draw_rhythm_connector(hero_center, hero_radius, accent)

func _draw_edge_vignette() -> void:
	for i in range(20):
		var t := float(i) / 20.0
		var h := size.y * 0.017
		draw_rect(Rect2(0, i * h, size.x, h + 1.0), Color(0.005, 0.009, 0.017, lerpf(0.30, 0.0, t)))
		draw_rect(Rect2(0, size.y - (i + 1) * h, size.x, h + 1.0), Color(0.005, 0.009, 0.017, lerpf(0.26, 0.0, t)))
	# Navigation-side scrim. This is intentionally broad and borderless.
	for i in range(18):
		var t := float(i) / 18.0
		var x := size.x * 0.035 + size.x * 0.022 * float(i)
		var w := size.x * 0.025
		draw_rect(Rect2(x, 0.0, w, size.y), Color(0.004, 0.008, 0.015, lerpf(0.18, 0.0, t)))

func _draw_ghost_artwork(center: Vector2, hero_radius: float) -> void:
	var main_menu := get_parent()
	if main_menu == null:
		return
	var background := main_menu.get_node_or_null("MenuBackground") as TextureRect
	var tex: Texture2D = background.texture if background != null else null
	if tex == null:
		return
	var tex_size := tex.get_size()
	if tex_size.x <= 1.0 or tex_size.y <= 1.0:
		return
	var side := hero_radius * 2.55
	var dst := Rect2(center - Vector2.ONE * side * 0.5, Vector2.ONE * side)
	var crop_side := minf(tex_size.x, tex_size.y)
	var src := Rect2(
		Vector2((tex_size.x - crop_side) * 0.5, (tex_size.y - crop_side) * 0.5),
		Vector2(crop_side, crop_side)
	)
	draw_texture_rect_region(tex, dst, src, Color(1.0, 1.0, 1.0, 0.105))
	# Fade the square silhouette back into the canvas with a soft dark field.
	draw_circle(center, side * 0.54, Color(0.006, 0.012, 0.022, 0.10))

func _draw_rhythm_connector(hero_center: Vector2, hero_radius: float, accent: Color) -> void:
	var y := hero_center.y
	var start_x := size.x * 0.335
	var end_x := hero_center.x - hero_radius * 1.34
	if end_x <= start_x:
		return
	draw_line(Vector2(start_x, y), Vector2(end_x, y), Color(MinimalThemeScript.TEXT, 0.085), 1.0, true)
	draw_circle(Vector2(end_x, y), 2.5, Color(accent, 0.52))
	var span := end_x - start_x
	for i in range(1, 9):
		var x := start_x + span * float(i) / 9.0
		var major := i % 3 == 0
		var tick_h := 12.0 if major else 6.0
		var alpha := 0.16 if major else 0.085
		draw_line(Vector2(x, y - tick_h * 0.5), Vector2(x, y + tick_h * 0.5), Color(accent, alpha), 1.0, true)

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
