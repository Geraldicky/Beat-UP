extends Control
class_name SongLaunchTransitionVisual

const TEXT := Color("f4f6fb")
const MUTED := Color("8b96a8")
const CYAN := Color("7db4ce")
const GOLD := Color("f5c96a")
const PINK := Color("d3a4ff")

@onready var artwork: TextureRect = %SongLaunchArtwork
@onready var dim: ColorRect = %SongLaunchDim
@onready var top_accent: ColorRect = %SongLaunchTopAccent
@onready var info_rail: Control = %SongLaunchInfoRail
@onready var info_accent: ColorRect = %SongLaunchInfoAccent
@onready var title_label: Label = %SongLaunchTitle
@onready var artist_label: Label = %SongLaunchArtist
@onready var detail_label: Label = %SongLaunchDetail
@onready var sweep: ColorRect = %SongLaunchSweep

var accent: Color = CYAN
var phase: float = 0.0
var activity: float = 0.0
var blur_amount: float = 0.0
var active_tween: Tween
var info_tween: Tween
var shader_material: ShaderMaterial
var handoff_generation: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	set_process(false)
	_setup_fonts()
	_setup_artwork_shader()
	resized.connect(Callable(self, "_update_artwork_pivot"))
	call_deferred("_update_artwork_pivot")

func configure(payload: Dictionary) -> void:
	handoff_generation += 1
	var difficulty: String = str(payload.get("difficulty", "NORMAL")).to_upper()
	accent = _difficulty_accent(difficulty)
	title_label.text = str(payload.get("title", "UNTITLED")).to_upper()
	artist_label.text = str(payload.get("artist", "UNKNOWN ARTIST"))
	var bpm: float = float(payload.get("bpm", 0.0))
	var star_rating: int = int(payload.get("star_rating", 0))
	var random_mode: bool = bool(payload.get("random_mode", false))
	var detail_parts: Array[String] = [difficulty]
	if bpm > 0.0:
		detail_parts.append("%d BPM" % roundi(bpm))
	if star_rating > 0:
		detail_parts.append("%d★" % star_rating)
	if random_mode:
		detail_parts.append("RANDOM")
	detail_label.text = "  ·  ".join(PackedStringArray(detail_parts))
	detail_label.add_theme_color_override("font_color", accent)
	top_accent.color = Color(accent, 0.0)
	info_accent.color = Color(accent, 0.72)
	sweep.color = Color(accent, 0.0)
	_load_artwork(str(payload.get("background", "")))
	set_progress(0.04)
	set_blur_amount(0.0)
	var dim_color: Color = dim.color
	dim_color.a = 0.0
	dim.color = dim_color
	artwork.scale = Vector2.ONE
	info_rail.scale = Vector2.ONE * 0.965
	info_rail.modulate.a = 0.0
	sweep.modulate.a = 0.0
	modulate.a = 0.0
	queue_redraw()

# The cover is intentionally brief. Song information behaves like an intro
# flourish, not a loading status: it enters, confirms the chosen chart, and then
# leaves even if resource preparation is still continuing behind the artwork.
func animate_cover() -> void:
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()
	if info_tween != null and info_tween.is_valid():
		info_tween.kill()
	visible = true
	set_process(true)
	modulate.a = 0.0
	info_rail.modulate.a = 0.0
	info_rail.scale = Vector2.ONE * 0.965
	artwork.scale = Vector2.ONE
	_update_artwork_pivot()

	active_tween = create_tween()
	active_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	active_tween.set_parallel(true)
	active_tween.tween_property(self, "modulate:a", 1.0, 0.11).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	active_tween.tween_method(Callable(self, "set_blur_amount"), 0.0, 0.0, 0.01)
	active_tween.tween_property(dim, "color:a", 0.20, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(artwork, "scale", Vector2.ONE * 1.014, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(info_rail, "modulate:a", 1.0, 0.13).set_delay(0.03).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(info_rail, "scale", Vector2.ONE, 0.20).set_delay(0.02).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(top_accent, "color:a", 0.58, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(sweep, "modulate:a", 0.55, 0.08).set_delay(0.04)
	await get_tree().create_timer(0.22, true, false, true).timeout

	var generation: int = handoff_generation
	call_deferred("_fade_intro_copy", generation)

func _fade_intro_copy(generation: int) -> void:
	await get_tree().create_timer(0.34, true, false, true).timeout
	if generation != handoff_generation or not visible:
		return
	if info_tween != null and info_tween.is_valid():
		info_tween.kill()
	info_tween = create_tween()
	info_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	info_tween.set_parallel(true)
	info_tween.tween_property(info_rail, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	info_tween.tween_property(info_rail, "scale", Vector2.ONE * 1.018, 0.20).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	info_tween.tween_property(top_accent, "color:a", 0.20, 0.22)
	info_tween.tween_property(sweep, "modulate:a", 0.0, 0.16)

func animate_reveal() -> void:
	handoff_generation += 1
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()
	if info_tween != null and info_tween.is_valid():
		info_tween.kill()
	info_rail.modulate.a = 0.0
	active_tween = create_tween()
	active_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	active_tween.set_parallel(true)
	active_tween.tween_method(Callable(self, "set_blur_amount"), blur_amount, 0.0, 0.01)
	active_tween.tween_property(dim, "color:a", 0.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(artwork, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(top_accent, "color:a", 0.0, 0.14)
	active_tween.tween_property(self, "modulate:a", 0.0, 0.24).set_delay(0.06).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	var generation = handoff_generation
	await active_tween.finished
	if handoff_generation != generation:
		return
		
	visible = false
	set_process(false)
	modulate.a = 1.0
	artwork.scale = Vector2.ONE

# Loader progress is intentionally invisible. It only changes the very subtle
# background motion speed so long preparation times still feel alive rather
# than frozen, without exposing a loading-state metaphor to the player.
func set_progress(value: float) -> void:
	activity = clampf(value, 0.0, 1.0)

func set_blur_amount(value: float) -> void:
	blur_amount = maxf(0.0, value)
	if shader_material != null:
		shader_material.set_shader_parameter("blur_amount", blur_amount)

func _process(delta: float) -> void:
	phase = fmod(phase + delta * (0.55 + activity * 0.35), TAU)
	queue_redraw()

func _draw() -> void:
	if size.x <= 2.0 or size.y <= 2.0:
		return
	# Non-loading ambient motion: a restrained beat line near the bottom edge.
	# It reads as song presentation rather than a spinner/progress indicator.
	var y: float = size.y * 0.885
	var width: float = minf(size.x * 0.24, 420.0)
	var start_x: float = size.x * 0.07
	var segments: int = 18
	for index in range(segments):
		var t: float = float(index) / float(segments - 1)
		var x: float = start_x + width * t
		var wave: float = 0.5 + 0.5 * sin(phase * 2.0 + float(index) * 0.72)
		var h: float = 2.0 + wave * 5.0
		draw_line(Vector2(x, y - h), Vector2(x, y + h), Color(accent, 0.12 + wave * 0.12), 1.0, true)

func _load_artwork(path: String) -> void:
	artwork.texture = null
	if path.is_empty():
		return
	if ResourceLoader.exists(path):
		var loaded: Resource = load(path)
		if loaded is Texture2D:
			artwork.texture = loaded as Texture2D

func _difficulty_accent(difficulty: String) -> Color:
	match difficulty:
		"MASTER": return PINK
		"HARD": return GOLD
		_: return CYAN

func _setup_fonts() -> void:
	var display_font: Font = load("res://assets/fonts/Poppins-SemiBold.ttf") as Font
	var body_font: Font = load("res://assets/fonts/Poppins-Regular.ttf") as Font
	var mono_font: Font = load("res://assets/fonts/IBMPlexMono-Regular.ttf") as Font
	title_label.add_theme_font_override("font", display_font)
	artist_label.add_theme_font_override("font", body_font)
	detail_label.add_theme_font_override("font", mono_font)
	title_label.add_theme_color_override("font_color", TEXT)
	artist_label.add_theme_color_override("font_color", Color(TEXT, 0.72))
	detail_label.add_theme_color_override("font_color", accent)

func _setup_artwork_shader() -> void:
	# Album Flow baseline intentionally avoids mandatory realtime blur. The cover
	# handoff remains alive through scale, dim and typography motion only.
	shader_material = null
	artwork.material = null

func _update_artwork_pivot() -> void:
	if is_instance_valid(artwork):
		artwork.pivot_offset = artwork.size * 0.5
