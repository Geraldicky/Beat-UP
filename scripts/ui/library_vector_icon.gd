extends TextureRect
## Canonical Song Library icon renderer backed by SVG assets.
##
## The project currently cannot parse raw .svg files through preload() before
## Godot's import pipeline has registered them. Keep SVG as the source asset,
## but resolve it at runtime: prefer an imported Texture2D when available and
## fall back to Image.load_svg_from_string() for a fresh checkout.

const ICON_PATHS: Dictionary = {
	"diamond": "res://assets/ui/icons/diamond.svg",
	"double_diamond": "res://assets/ui/icons/play_diamond.svg",
	"rank": "res://assets/ui/icons/rank_diamond.svg",
	"arrow": "res://assets/ui/icons/arrow_right.svg",
	"previous": "res://assets/ui/icons/chevron_left.svg",
	"next": "res://assets/ui/icons/chevron_right.svg",
	"shuffle": "res://assets/ui/icons/random.svg",
	"target": "res://assets/ui/icons/practice.svg",
	"help": "res://assets/ui/icons/info.svg",
}

static var _texture_cache: Dictionary = {}

var kind := "diamond":
	set(value):
		kind = value
		_sync_texture()

var ink := Color("58c9ff"):
	set(value):
		ink = value
		modulate = value

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sync_texture()
	modulate = ink

static func texture_for(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D

	# Once Godot has imported the SVG, ResourceLoader is the preferred path and
	# remains compatible with exported resource remapping.
	if ResourceLoader.exists(path):
		var imported: Resource = ResourceLoader.load(path)
		if imported is Texture2D:
			_texture_cache[path] = imported
			return imported as Texture2D

	# Fresh clones can reach script parsing before SVG import metadata exists.
	# Decode the source SVG directly so the UI still has a valid Texture2D.
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var svg_source := file.get_as_text()
	var image := Image.new()
	var error := image.load_svg_from_string(svg_source, 1.0)
	if error != OK:
		push_warning("Unable to decode Song Library SVG icon: %s" % path)
		return null
	var generated := ImageTexture.create_from_image(image)
	_texture_cache[path] = generated
	return generated

func _sync_texture() -> void:
	var path: String = str(ICON_PATHS.get(kind, ICON_PATHS["diamond"]))
	texture = texture_for(path)
