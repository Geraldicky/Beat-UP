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
	for node_name in ["MenuBackground", "MenuDim", "MenuTitle", "MenuRule", "NowPlayingCard"]:
		var node := main_menu.get_node_or_null(node_name) as CanvasItem
		if node != null:
			node.show()
	for node_name in ["OrbCluster", "BackgroundInfo", "SelectionIndex", "SelectionDescription", "MainFooter", "TopAccent"]:
		var node := main_menu.get_node_or_null(node_name) as CanvasItem
		if node != null:
			node.hide()
	var dim := main_menu.get_node_or_null("MenuDim") as ColorRect
	if dim != null:
		dim.color = Color(0.018, 0.026, 0.042, 0.52)
	var background := main_menu.get_node_or_null("MenuBackground") as TextureRect
	if background != null:
		background.modulate = Color(0.80, 0.84, 0.90, 0.64)

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


	# Soft top/bottom vignette only. No realtime blur or shader dependency.
	for i in range(18):
		var t := float(i) / 18.0
		var h := size.y * 0.018
		draw_rect(Rect2(0, i * h, size.x, h + 1.0), Color(0.01, 0.015, 0.025, lerpf(0.24, 0.0, t)))
		draw_rect(Rect2(0, size.y - (i + 1) * h, size.x, h + 1.0), Color(0.01, 0.015, 0.025, lerpf(0.20, 0.0, t)))

	var artwork_rect := _artwork_rect()
	var diamond_center := artwork_rect.get_center() + Vector2(artwork_rect.size.x * 0.12, -artwork_rect.size.y * 0.10)
	var diamond_radius := artwork_rect.size.x * 0.68
	_draw_diamond(diamond_center, diamond_radius, Color(accent, 0.055), 1.0)
	_draw_diamond(diamond_center, diamond_radius * 0.74, Color(MinimalThemeScript.TEXT, 0.026), 1.0)

	_draw_current_artwork(artwork_rect, accent)
	_draw_flow_line(artwork_rect, accent)

func _artwork_rect() -> Rect2:
	var side := minf(size.y * 0.49, size.x * 0.30)
	side = clampf(side, 310.0, 560.0)
	var x := clampf(size.x * 0.625, size.x * 0.54, size.x - side - size.x * 0.055)
	var y := clampf(size.y * 0.155, 86.0, size.y - side - 180.0)
	return Rect2(Vector2(x, y), Vector2(side, side))

func _draw_current_artwork(dst_rect: Rect2, accent: Color) -> void:
	var main_menu := get_parent()
	var background: TextureRect = null
	if main_menu != null:
		background = main_menu.get_node_or_null("MenuBackground") as TextureRect
	var tex: Texture2D = background.texture if background != null else null

	# Quiet depth without a card stack.
	draw_rect(Rect2(dst_rect.position + Vector2(14.0, 18.0), dst_rect.size), Color(0.0, 0.0, 0.0, 0.22), true)
	if tex != null:
		var tex_size := tex.get_size()
		if tex_size.x > 1.0 and tex_size.y > 1.0:
			var crop_side := minf(tex_size.x, tex_size.y)
			var src := Rect2(Vector2((tex_size.x - crop_side) * 0.5, (tex_size.y - crop_side) * 0.5), Vector2(crop_side, crop_side))
			draw_texture_rect_region(tex, dst_rect, src, Color(1.0, 1.0, 1.0, 0.96))
		else:
			draw_texture_rect(tex, dst_rect, false, Color(1.0, 1.0, 1.0, 0.96))
	else:
		draw_rect(dst_rect, Color(MinimalThemeScript.SURFACE, 0.82), true)
		_draw_diamond(dst_rect.get_center(), dst_rect.size.x * 0.28, Color(accent, 0.18), 2.0)

	# Editorial edge: nearly invisible at rest, just enough to separate artwork
	# from similarly dark background frames.
	draw_rect(dst_rect, Color(MinimalThemeScript.TEXT, 0.12), false, 1.0)
	draw_line(Vector2(dst_rect.position.x, dst_rect.end.y + 16.0), Vector2(dst_rect.end.x, dst_rect.end.y + 16.0), Color(accent, 0.28), 2.0, true)

func _draw_flow_line(artwork_rect: Rect2, accent: Color) -> void:
	var energy_sum := 0.0
	for e in current_audio_levels:
		energy_sum += e
	var average := energy_sum / maxf(1.0, float(current_audio_levels.size()))
	var start := Vector2(artwork_rect.position.x, artwork_rect.end.y + 42.0)
	var width := artwork_rect.size.x
	var segments := 32
	for i in range(segments):
		var t := float(i) / float(segments - 1)
		var x := start.x + width * t
		var source_index := clampi(roundi(t * float(AUDIO_BAR_COUNT - 1)), 0, AUDIO_BAR_COUNT - 1)
		var local_energy := current_audio_levels[source_index]
		var wave := sin(phase * 2.0 + t * 10.0) * (1.2 + average * 1.8)
		var bar_h := 0.8 + local_energy * 7.0
		draw_line(Vector2(x, start.y + wave - bar_h), Vector2(x, start.y + wave + bar_h), Color(accent, 0.10 + local_energy * 0.18), 1.0, true)
	draw_line(start, start + Vector2(width, 0), Color(MinimalThemeScript.TEXT, 0.08), 1.0, true)
	draw_circle(start, 2.5, Color(accent, 0.48))

func _draw_diamond(center: Vector2, radius: float, color: Color, width: float) -> void:
	var points := PackedVector2Array([
		center + Vector2(0.0, -radius),
		center + Vector2(radius, 0.0),
		center + Vector2(0.0, radius),
		center + Vector2(-radius, 0.0),
		center + Vector2(0.0, -radius),
	])
	draw_polyline(points, color, width, true)
