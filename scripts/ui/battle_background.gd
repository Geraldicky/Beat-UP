extends TextureRect
class_name BattleBackground

const BACKGROUND_ROOT := "res://assets/song_backgrounds"

var current_background_path := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func set_song_background(path: String, song_id: String = "") -> bool:
	var candidates: Array[String] = []
	var requested_path: String = path.strip_edges()
	if not requested_path.is_empty():
		candidates.append(requested_path)

	var safe_song_id: String = _safe_song_id(song_id)
	if not safe_song_id.is_empty():
		var fallback_path: String = "%s/%s.png" % [BACKGROUND_ROOT, safe_song_id]
		if not candidates.has(fallback_path):
			candidates.append(fallback_path)

	for candidate: String in candidates:
		if not ResourceLoader.exists(candidate):
			continue
		var loaded_resource: Resource = load(candidate)
		if loaded_resource is Texture2D:
			texture = loaded_resource as Texture2D
			current_background_path = candidate
			return true

	texture = null
	current_background_path = ""
	return false

func clear_song_background() -> void:
	texture = null
	current_background_path = ""

func get_current_background_path() -> String:
	return current_background_path

func _safe_song_id(song_id: String) -> String:
	return song_id.strip_edges().to_lower().replace(" ", "_").replace("-", "_")
