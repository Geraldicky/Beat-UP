extends Control
class_name SongSelectVisual

const MinimalThemeScript = preload("res://scripts/ui/minimal_theme.gd")

const BG := Color("0b0e14")
const GRID := Color("1b2430")
const CYAN := Color("7db4ce")
const GOLD := Color("f5c96a")
const PINK := Color("d3a4ff")
const BACKGROUND_ROOT := "res://assets/song_backgrounds"

var difficulty := "normal"
var current_texture: Texture2D
var previous_texture: Texture2D
var background_fade := 1.0
var current_background_path := ""
var pending_background_path := ""
var pending_generation := 0
var current_song_id := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func _process(delta: float) -> void:
	_poll_background_request()
	if background_fade < 1.0:
		background_fade = minf(1.0, background_fade + delta / 0.38)
		queue_redraw()

func set_song(song_id: String, difficulty_id: String, background_path: String = "") -> void:
	current_song_id = song_id
	difficulty = difficulty_id.to_lower()
	var resolved_path := _resolve_background_path(song_id, background_path)
	if resolved_path == current_background_path or resolved_path == pending_background_path:
		queue_redraw()
		return
	_request_background_async(resolved_path)
	queue_redraw()

func set_audio_levels(_levels: PackedFloat32Array) -> void:
	pass

func get_audio_levels() -> PackedFloat32Array:
	return PackedFloat32Array()

func _accent() -> Color:
	match difficulty:
		"master": return PINK
		"hard": return GOLD
		_:
			return CYAN

func _resolve_background_path(song_id: String, explicit_path: String) -> String:
	var candidates: Array[String] = []
	if not explicit_path.is_empty():
		candidates.append(explicit_path)
	var safe_id := song_id.to_lower().replace(" ", "_")
	for extension in ["png", "webp", "jpg", "jpeg"]:
		candidates.append("%s/%s.%s" % [BACKGROUND_ROOT, safe_id, extension])
	for path in candidates:
		if ResourceLoader.exists(path):
			return path
	return ""

func _request_background_async(path: String) -> void:
	pending_generation += 1
	if path.is_empty():
		pending_background_path = ""
		_apply_loaded_background("", null)
		return
	pending_background_path = path
	# Never call load() from the selection/navigation path. Threaded loading keeps
	# the shell tween responsive even when a 1600x900 image has not been cached yet.
	var error := ResourceLoader.load_threaded_request(path, "Texture2D", true, ResourceLoader.CACHE_MODE_REUSE)
	if error != OK:
		# If another threaded request already owns the path, polling it is still safe.
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE or status == ResourceLoader.THREAD_LOAD_FAILED:
			pending_background_path = ""

func _poll_background_request() -> void:
	if pending_background_path.is_empty():
		return
	var path := pending_background_path
	var status := ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		return
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var resource := ResourceLoader.load_threaded_get(path)
		pending_background_path = ""
		if resource is Texture2D:
			_apply_loaded_background(path, resource as Texture2D)
		return
	if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		pending_background_path = ""

func _apply_loaded_background(path: String, texture: Texture2D) -> void:
	if texture == current_texture and path == current_background_path:
		return
	previous_texture = current_texture
	current_texture = texture
	current_background_path = path
	background_fade = 0.0
	queue_redraw()

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	if current_texture == null and previous_texture == null:
		_draw_fallback_artwork()
	_draw_background_image(previous_texture, (1.0 - background_fade) * 0.22, -16.0 * background_fade)
	_draw_background_image(current_texture, 0.98 if previous_texture == null else lerpf(0.0, 0.98, background_fade), 12.0 * (1.0 - background_fade))

	var left_width := size.x * 0.36
	var left_steps := 40
	for i in range(left_steps):
		var t0 := float(i) / float(left_steps)
		var t1 := float(i + 1) / float(left_steps)
		var x0 := lerpf(0.0, left_width, t0)
		var x1 := lerpf(0.0, left_width, t1)
		var alpha := lerpf(0.12, 0.0, pow(t1, 1.55))
		draw_rect(Rect2(Vector2(x0, 0.0), Vector2(x1 - x0, size.y)), Color(0.018, 0.024, 0.036, alpha))

	var grad_start := size.x * 0.66
	var strips := 28
	for i in range(strips):
		var t0 := float(i) / float(strips)
		var t1 := float(i + 1) / float(strips)
		var x0 := lerpf(grad_start, size.x, t0)
		var x1 := lerpf(grad_start, size.x, t1)
		var alpha := lerpf(0.0, 0.10, pow(t1, 1.08))
		draw_rect(Rect2(Vector2(x0, 0.0), Vector2(x1 - x0, size.y)), Color(0.010, 0.014, 0.022, alpha))


	var accent := _accent()
	draw_line(Vector2(0.0, 2.0), Vector2(size.x, 2.0), Color(accent, 0.16), 2.0)

func _draw_fallback_artwork() -> void:
	# Designed missing-art state: quiet gradient-like bands, one large diamond,
	# a Flow Line, and compact initials derived from the selected song id.
	var strips := 28
	for i in range(strips):
		var t0 := float(i) / float(strips)
		var t1 := float(i + 1) / float(strips)
		var x0 := size.x * t0
		var x1 := size.x * t1
		var col := MinimalThemeScript.BG.lerp(MinimalThemeScript.SURFACE_RAISED, 0.34 * t1)
		draw_rect(Rect2(Vector2(x0, 0.0), Vector2(x1 - x0 + 1.0, size.y)), col)
	var center := Vector2(size.x * 0.77, size.y * 0.46)
	var radius := minf(size.x, size.y) * 0.23
	var points := PackedVector2Array([
		center + Vector2(0.0, -radius),
		center + Vector2(radius, 0.0),
		center + Vector2(0.0, radius),
		center + Vector2(-radius, 0.0),
		center + Vector2(0.0, -radius),
	])
	draw_polyline(points, Color(MinimalThemeScript.ACCENT, 0.10), 2.0, true)
	var line_y := size.y * 0.78
	draw_line(Vector2(size.x * 0.60, line_y), Vector2(size.x * 0.92, line_y), Color(MinimalThemeScript.TEXT, 0.10), 1.0, true)
	draw_circle(Vector2(size.x * 0.60, line_y), 2.5, Color(MinimalThemeScript.ACCENT, 0.48))
	var initials := _song_initials(current_song_id)
	if not initials.is_empty():
		var font := MinimalThemeScript.display_font()
		draw_string(font, Vector2(size.x * 0.70, size.y * 0.51), initials, HORIZONTAL_ALIGNMENT_CENTER, size.x * 0.14, 44, Color(MinimalThemeScript.TEXT, 0.18))

func _song_initials(song_id: String) -> String:
	var clean := song_id.replace("_", " ").replace("-", " ").strip_edges()
	if clean.is_empty():
		return "BU"
	var out := ""
	for part: String in clean.split(" ", false):
		if not part.is_empty():
			out += part.substr(0, 1).to_upper()
		if out.length() >= 2:
			break
	return out

func _draw_background_image(texture: Texture2D, alpha: float, offset_x: float = 0.0) -> void:
	if texture == null or alpha <= 0.001:
		return
	var tex_size := texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var fit_scale := maxf(size.x / tex_size.x, size.y / tex_size.y)
	var draw_size := tex_size * fit_scale
	var pos := (size - draw_size) * 0.5 + Vector2(offset_x, 0.0)
	draw_texture_rect(texture, Rect2(pos, draw_size), false, Color(1, 1, 1, alpha))
