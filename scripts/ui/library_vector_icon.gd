extends TextureRect
## Canonical Song Library icon view backed by SVG assets.
##
## Keep the legacy `kind` / `ink` API so the rest of Song Library can change
## icon state without rebuilding layout code. SVG decoding is delegated to the
## shared runtime loader instead of calling static methods on a preloaded script.

const LibraryIconLoader = preload("res://scripts/ui/library_icon_loader.gd")

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

var _icon_loader = LibraryIconLoader.new()

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

func _sync_texture() -> void:
	var path: String = str(ICON_PATHS.get(kind, ICON_PATHS["diamond"]))
	texture = _icon_loader.texture_for(path)
