extends Node
class_name BeatUpBackgroundSession

signal background_changed(state: Dictionary)

const BACKGROUND_ROOT := "res://assets/backgrounds"
const BACKGROUND_PATHS: Array[String] = [
	"res://assets/backgrounds/background_01.png",
	"res://assets/backgrounds/background_02.png",
	"res://assets/backgrounds/background_03.png",
	"res://assets/backgrounds/background_04.png",
	"res://assets/backgrounds/background_05.png",
	"res://assets/backgrounds/background_06.png",
	"res://assets/backgrounds/background_07.png",
	"res://assets/backgrounds/background_08.png",
	"res://assets/backgrounds/background_09.png",
	"res://assets/backgrounds/background_10.png",
	"res://assets/backgrounds/background_11.png",
	"res://assets/backgrounds/background_12.png",
	"res://assets/backgrounds/background_13.png",
	"res://assets/backgrounds/background_14.png",
	"res://assets/backgrounds/background_15.png",
	"res://assets/backgrounds/background_16.png",
	"res://assets/backgrounds/background_17.png",
	"res://assets/backgrounds/background_18.png",
	"res://assets/backgrounds/background_19.png",
	"res://assets/backgrounds/background_20.png",
	"res://assets/backgrounds/background_21.png",
	"res://assets/backgrounds/background_22.png",
	"res://assets/backgrounds/background_23.png",
	"res://assets/backgrounds/background_24.png",
	"res://assets/backgrounds/background_25.png",
	"res://assets/backgrounds/background_26.png",
	"res://assets/backgrounds/background_27.png",
	"res://assets/backgrounds/background_28.png",
	"res://assets/backgrounds/background_29.png",
	"res://assets/backgrounds/background_30.png",
	"res://assets/backgrounds/background_31.png",
	"res://assets/backgrounds/background_32.png",
	"res://assets/backgrounds/background_33.png",
	"res://assets/backgrounds/background_34.png",
	"res://assets/backgrounds/background_35.png",
	"res://assets/backgrounds/background_36.png",
	"res://assets/backgrounds/background_37.png",
	"res://assets/backgrounds/background_38.png",
	"res://assets/backgrounds/background_39.png",
]

var state: Dictionary = {}
var texture_cache: Dictionary = {}
var rng := RandomNumberGenerator.new()
var current_background_index := -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	call_deferred("_ensure_background")

func _ensure_background() -> void:
	if get_background_path().is_empty():
		randomize_background("boot", true)

func randomize_background(source: String = "", avoid_repeat: bool = true, metadata: Dictionary = {}) -> String:
	if BACKGROUND_PATHS.is_empty():
		return ""
	var next_index := 0
	if BACKGROUND_PATHS.size() > 1:
		for _attempt in range(16):
			next_index = rng.randi_range(0, BACKGROUND_PATHS.size() - 1)
			if not avoid_repeat or next_index != current_background_index:
				break
	var background_path := BACKGROUND_PATHS[next_index]
	if not ResourceLoader.exists(background_path):
		for index in range(BACKGROUND_PATHS.size()):
			var fallback_path := BACKGROUND_PATHS[index]
			if ResourceLoader.exists(fallback_path):
				next_index = index
				background_path = fallback_path
				break
	if not ResourceLoader.exists(background_path):
		return ""
	current_background_index = next_index
	var next_state := metadata.duplicate(true)
	next_state["background"] = background_path
	next_state["background_index"] = current_background_index
	if not source.is_empty():
		next_state["source"] = source
	set_background(background_path, next_state)
	return background_path

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
	current_background_index = -1
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
	var image := Image.new()
	var error := image.load(filesystem_path)
	if error != OK or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)
