extends Node
class_name BeatUpBackgroundSession

signal background_changed(state: Dictionary)

var state: Dictionary = {}
var texture_cache: Dictionary = {}
var selection_state: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_bind_selection_state")

func _bind_selection_state() -> void:
	selection_state = get_node_or_null("/root/SongSelectionState")
	if selection_state == null:
		return
	if selection_state.has_signal("selection_changed"):
		var callback: Callable = Callable(self, "_on_selection_changed")
		if not selection_state.is_connected("selection_changed", callback):
			selection_state.connect("selection_changed", callback)
	if selection_state.has_method("get_state"):
		var value: Variant = selection_state.call("get_state")
		if value is Dictionary:
			_on_selection_changed(value as Dictionary)

func _on_selection_changed(selection: Dictionary) -> void:
	if selection.is_empty():
		clear()
		return
	var background_path: String = str(selection.get("background", ""))
	if background_path.is_empty():
		clear()
		return
	set_background(background_path, selection)

func set_background(background_path: String, metadata: Dictionary = {}) -> void:
	if background_path.is_empty():
		return
	var next_state: Dictionary = metadata.duplicate(true)
	next_state["background"] = background_path
	if next_state == state:
		return
	state = next_state
	background_changed.emit(get_state())

func clear() -> void:
	if state.is_empty():
		return
	state.clear()
	background_changed.emit({})

func get_state() -> Dictionary:
	return state.duplicate(true)

func get_background_path() -> String:
	return str(state.get("background", ""))

func get_texture() -> Texture2D:
	return get_texture_for_path(get_background_path())

func get_texture_for_path(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if texture_cache.has(path):
		return texture_cache[path] as Texture2D
	var texture: Texture2D = _load_texture(path)
	texture_cache[path] = texture
	return texture

func _load_texture(path: String) -> Texture2D:
	if path.begins_with("res://") and ResourceLoader.exists(path):
		var resource: Resource = ResourceLoader.load(path)
		if resource is Texture2D:
			return resource as Texture2D
	var filesystem_path: String = ProjectSettings.globalize_path(path) if path.begins_with("user://") or path.begins_with("res://") else path
	if not FileAccess.file_exists(filesystem_path):
		return null
	var image: Image = Image.new()
	var error: int = image.load(filesystem_path)
	if error != OK or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)
