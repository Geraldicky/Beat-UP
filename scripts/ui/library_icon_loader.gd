extends RefCounted
## Runtime SVG loader for the Song Library icon set.
##
## We intentionally avoid preload() on raw SVG files because this project can
## parse scripts before Godot has registered imported SVG resources on a fresh
## checkout. Calls are instance methods for compatibility with the current
## GDScript runtime; the cache remains shared between loader instances.

static var _texture_cache: Dictionary = {}

func texture_for(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D

	# Prefer Godot's imported texture when the SVG importer has already run.
	if ResourceLoader.exists(path):
		var imported: Resource = ResourceLoader.load(path)
		if imported is Texture2D:
			_texture_cache[path] = imported
			return imported as Texture2D

	# Fresh clones may not have SVG import metadata yet. Decode the source file
	# directly so the UI can still render on the first project scan.
	if not FileAccess.file_exists(path):
		push_warning("Song Library icon file is missing: %s" % path)
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Unable to open Song Library icon file: %s" % path)
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
