extends Control
class_name ResultBackdrop

@export var background_color := Color("0b0e14")
@export var grid_color := Color(0.20, 0.24, 0.32, 0.06)
@export var accent_color := Color(0.66, 0.72, 1.0, 0.14)
@export_range(36.0, 120.0, 2.0) var grid_spacing := 72.0

var song_texture: Texture2D
var song_texture_path := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not resized.is_connected(queue_redraw):
		resized.connect(queue_redraw)
	queue_redraw()

func set_song_background(path: String, accent: Color) -> void:
	accent_color = Color(accent, 0.14)
	if path == song_texture_path:
		queue_redraw()
		return
	song_texture_path = path
	song_texture = null
	if not path.is_empty() and ResourceLoader.exists(path):
		var loaded := load(path)
		if loaded is Texture2D:
			song_texture = loaded
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), background_color)
	if song_texture != null:
		_draw_song_art()

	# Album Flow result backdrop: preserve the chosen song instead of replacing it
	# with a technical grid. A strong left veil keeps metrics readable while the
	# right side retains recognisable album context.
	_draw_readability_veil()
	_draw_flow_line()

func _draw_song_art() -> void:
	var tex_size := song_texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0 or size.x <= 0.0 or size.y <= 0.0:
		return
	var crop := _cover_region(tex_size, size)
	draw_texture_rect_region(song_texture, Rect2(Vector2.ZERO, size), crop, Color(0.88, 0.91, 0.97, 0.72))
	# Calm the art globally before metric-specific veils are added.
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.028, 0.045, 0.40))

func _draw_readability_veil() -> void:
	var strips := 48
	for index in range(strips):
		var t0 := float(index) / float(strips)
		var t1 := float(index + 1) / float(strips)
		var x0 := size.x * t0
		var x1 := size.x * t1
		var alpha := lerpf(0.86, 0.10, pow(t1, 1.28))
		draw_rect(Rect2(Vector2(x0, 0.0), Vector2(x1 - x0 + 1.0, size.y)), Color(0.025, 0.035, 0.055, alpha))

	# Top/bottom edge control gives the result screen a presentation frame without
	# a literal card around the entire composition.
	for index in range(12):
		var t := float(index) / 12.0
		var h := size.y * 0.018
		var a := lerpf(0.20, 0.0, t)
		draw_rect(Rect2(0, index * h, size.x, h + 1.0), Color(0.01, 0.015, 0.025, a))
		draw_rect(Rect2(0, size.y - (index + 1) * h, size.x, h + 1.0), Color(0.01, 0.015, 0.025, a))

func _draw_flow_line() -> void:
	var y := size.y * 0.885
	var x0 := size.x * 0.055
	var x1 := size.x * 0.94
	draw_line(Vector2(x0, y), Vector2(x1, y), Color(0.96, 0.97, 0.99, 0.08), 1.0, true)
	var marker_x := lerpf(x0, x1, 0.76)
	draw_line(Vector2(marker_x, y - 5.0), Vector2(marker_x, y + 5.0), Color(accent_color, 0.64), 2.0, true)

func _cover_region(tex_size: Vector2, target_size: Vector2) -> Rect2:
	var source_ratio := tex_size.x / tex_size.y
	var target_ratio := target_size.x / target_size.y
	if source_ratio > target_ratio:
		var crop_width := tex_size.y * target_ratio
		return Rect2((tex_size.x - crop_width) * 0.5, 0.0, crop_width, tex_size.y)
	var crop_height := tex_size.x / target_ratio
	return Rect2(0.0, (tex_size.y - crop_height) * 0.42, tex_size.x, crop_height)
