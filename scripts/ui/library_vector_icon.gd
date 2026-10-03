extends TextureRect
## Canonical Song Library icon renderer backed by SVG assets.
##
## Keep the legacy `kind` / `ink` API so existing Song Library controls can
## switch icon state without rebuilding their layout. Geometry now lives in the
## canonical SVG library instead of procedural draw_* calls.

const ICONS := {
	"diamond": preload("res://assets/ui/icons/diamond.svg"),
	"double_diamond": preload("res://assets/ui/icons/play_diamond.svg"),
	"rank": preload("res://assets/ui/icons/rank_diamond.svg"),
	"arrow": preload("res://assets/ui/icons/arrow_right.svg"),
	"previous": preload("res://assets/ui/icons/chevron_left.svg"),
	"next": preload("res://assets/ui/icons/chevron_right.svg"),
	"shuffle": preload("res://assets/ui/icons/random.svg"),
	"target": preload("res://assets/ui/icons/practice.svg"),
	"help": preload("res://assets/ui/icons/info.svg"),
}

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
	texture = ICONS.get(kind, ICONS["diamond"]) as Texture2D
