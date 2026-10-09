extends TextureRect
class_name BattleBackground

var current_background_path := ""

func _ready() -> void:
	preload("res://scripts/ui/procedural_background.gd").install(self, "gameplay")
	set_process(true)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func _process(_delta: float) -> void:
	# Existing gameplay lifecycle enables/disables this owner; the atmosphere
	# uses that same pause contract rather than shader TIME (which never pauses).
	pass

func set_song_background(path: String, _song_id: String = "") -> bool:
	var requested_path := path.strip_edges()
	if requested_path.is_empty():
		var session: Node = get_node_or_null("/root/BackgroundSession")
		if session != null and session.has_method("get_background_path"):
			requested_path = str(session.call("get_background_path"))
	if requested_path.is_empty() or not ResourceLoader.exists(requested_path):
		texture = null
		current_background_path = ""
		return false
	var loaded_resource: Resource = ResourceLoader.load(requested_path)
	if not (loaded_resource is Texture2D):
		texture = null
		current_background_path = ""
		return false
	texture = loaded_resource as Texture2D
	current_background_path = requested_path
	return true

func clear_song_background() -> void:
	texture = null
	current_background_path = ""

func get_current_background_path() -> String:
	return current_background_path
