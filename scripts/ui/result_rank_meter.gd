extends Control
class_name ResultRankMeter

# Actual generated rank glyphs; no shared frame or native letter overlay.
const RANK_TEXTURES = {
	"D": preload("res://assets/ui/ranks/rank_d.png"),
	"C": preload("res://assets/ui/ranks/rank_c.png"),
	"B": preload("res://assets/ui/ranks/rank_b.png"),
	"A": preload("res://assets/ui/ranks/rank_a.png"),
	"S": preload("res://assets/ui/ranks/rank_s.png"),
	"SS": preload("res://assets/ui/ranks/rank_ss.png"),
}
var rank_id := "D"
const GRADE_COLORS = preload("res://scripts/ui/minimal_theme.gd").RANK_COLORS
var _glyph_regions: Dictionary = {}
@export_range(0.0, 100.0, 0.01) var value := 0.0:
	set(next_value):
		value = clampf(next_value, 0.0, 100.0)
		queue_redraw()
@export var track_color := Color(0.188, 0.208, 0.255, 0.45)
var rank_tint := Color.WHITE:
	set(next_color):
		rank_tint = next_color
		queue_redraw()

func _ready() -> void:
	var tint_material := ShaderMaterial.new()
	tint_material.shader = preload("res://assets/ui/ranks/rank_palette.gdshader")
	material = tint_material
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	set_rank(rank_id)

func set_rank(next_rank: String) -> void:
	rank_id = next_rank
	if material is ShaderMaterial:
		material.set_shader_parameter("grade_color", GRADE_COLORS.get(rank_id, Color.WHITE))
	var texture := get_rank_texture()
	if texture != null and not _glyph_regions.has(rank_id):
		# Fit the visible glyph, not the generator's varying transparent margins.
		# Keep the original PNG and alpha untouched.
		_glyph_regions[rank_id] = Rect2(texture.get_image().get_used_rect())
	queue_redraw()

func get_rank_texture() -> Texture2D:
	return RANK_TEXTURES.get(rank_id) as Texture2D

func _draw() -> void:
	var edge := minf(size.x, size.y)
	var texture := get_rank_texture()
	if texture != null and _glyph_regions.has(rank_id):
		var region: Rect2 = _glyph_regions[rank_id]
		# SS needs more horizontal room so its two glyphs share the optical height
		# of single-letter grades. Keep the generated source art untouched.
		var available := Vector2(minf(size.x, edge * (1.34 if rank_id == "SS" else 1.10)), edge * 1.04)
		var fit := minf(available.x / region.size.x, available.y / region.size.y)
		var glyph_size := region.size * fit
		draw_texture_rect_region(texture, Rect2((size - glyph_size) * 0.5, glyph_size), region)
