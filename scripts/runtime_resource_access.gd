extends RefCounted
class_name RuntimeResourceAccess

# ResourceLoader understands Godot's export-time resource remapping.
# FileAccess.file_exists() does not, so imported res:// assets can appear
# "missing" in exported builds even when ResourceLoader can load them.
static func resource_exists(path: String) -> bool:
	if path.is_empty():
		return false
	if path.begins_with("res://"):
		return ResourceLoader.exists(path)
	return FileAccess.file_exists(path)

static func audio_exists(path: String) -> bool:
	return resource_exists(path)
