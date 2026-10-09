extends Control
class_name SongLaunchTransitionVisual

const TEXT := Color("f4f6fb")
const MUTED := Color("8b96a8")
const ACCENT := Color("92a7ff")

@onready var artwork: TextureRect = %SongLaunchArtwork
@onready var info_rail: Control = %SongLaunchInfoRail
@onready var title_label: Label = %SongLaunchTitle
@onready var artist_label: Label = %SongLaunchArtist
@onready var detail_label: Label = %SongLaunchDetail

var phase := 0.0
var activity := 0.0
var active_tween: Tween
var handoff_generation := 0
var loading_status := "PREPARING CHART"
var rail := Rect2()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	set_process(false)
	title_label.add_theme_font_override("font", load("res://assets/fonts/Poppins-SemiBold.ttf") as Font)
	artist_label.add_theme_font_override("font", load("res://assets/fonts/Poppins-Regular.ttf") as Font)
	title_label.add_theme_color_override("font_color", TEXT)
	artist_label.add_theme_color_override("font_color", MUTED)
	detail_label.hide()
	resized.connect(_layout_content)
	call_deferred("_layout_content")

func configure(payload: Dictionary, keep_cover: bool = false) -> void:
	handoff_generation += 1
	title_label.text = str(payload.get("title", "Untitled"))
	artist_label.text = str(payload.get("artist", "Unknown Artist"))
	# Album art is a jacket only, never a fullscreen song-art background.
	artwork.texture = null
	var song_id := str(payload.get("song_id", ""))
	var path := "res://assets/song_thumbnails/%s.png" % song_id
	if not song_id.is_empty() and song_id == song_id.validate_filename() and ResourceLoader.exists(path):
		artwork.texture = load(path) as Texture2D
	_layout_content()
	if keep_cover:
		return
	set_progress(0.04)
	phase = 0.0
	info_rail.modulate.a = 1.0
	modulate.a = 0.0
	queue_redraw()

func animate_cover() -> void:
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()
	visible = true
	set_process(true)
	modulate.a = 0.0
	info_rail.modulate.a = 1.0
	_layout_content()
	active_tween = create_tween()
	active_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	active_tween.tween_property(self, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.22, true, false, true).timeout

func animate_reveal() -> void:
	handoff_generation += 1
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()
	var generation := handoff_generation
	active_tween = create_tween()
	active_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	active_tween.tween_property(self, "modulate:a", 0.0, 0.24).set_delay(0.06).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await active_tween.finished
	if generation != handoff_generation:
		return
	visible = false
	set_process(false)
	modulate.a = 1.0

# Preparation has no measurable percentage: show activity, not fake completion.
func set_progress(value: float) -> void:
	activity = clampf(value, 0.0, 1.0)

func _process(delta: float) -> void:
	phase = fmod(phase + delta * (1.5 + activity * 0.35), TAU)
	queue_redraw()

func _layout_content() -> void:
	if not is_node_ready():
		return
	var ui_scale := clampf(size.y / 1080.0, 0.65, 1.0)
	var jacket_side := 280.0 * ui_scale
	var copy_width := minf(600.0 * ui_scale, size.x - 64.0)
	var total_height := jacket_side + 146.0 * ui_scale
	var top := (size.y - total_height) * 0.5
	artwork.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	artwork.position = Vector2((size.x - jacket_side) * 0.5, top)
	artwork.size = Vector2.ONE * jacket_side
	info_rail.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	info_rail.position = Vector2((size.x - copy_width) * 0.5, top + jacket_side + 18.0 * ui_scale)
	info_rail.size = Vector2(copy_width, 84.0 * ui_scale)
	title_label.add_theme_font_size_override("font_size", roundi(32.0 * ui_scale))
	artist_label.add_theme_font_size_override("font_size", roundi(18.0 * ui_scale))
	var rail_width := minf(copy_width, 420.0 * ui_scale)
	rail = Rect2((size.x - rail_width) * 0.5, top + total_height - 20.0 * ui_scale, rail_width, 4.0 * ui_scale)
	queue_redraw()

func _draw() -> void:
	if rail.size.x <= 0:
		return
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("171c27")
	frame.border_color = Color(ACCENT, 0.35)
	frame.set_border_width_all(1)
	frame.set_corner_radius_all(4)
	draw_style_box(frame, Rect2(artwork.position - Vector2.ONE, artwork.size + Vector2.ONE * 2.0))
	if artwork.texture == null:
		var center := artwork.position + artwork.size * 0.5
		var radius := artwork.size.x * 0.15
		draw_polyline(PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius, 0), center + Vector2(0, radius), center + Vector2(-radius, 0), center + Vector2(0, -radius)]), Color(ACCENT, 0.45), 1.5, true)
	draw_rect(rail, Color("252d3b"))
	var segment_width := rail.size.x * 0.28
	var x := rail.position.x + (0.5 + 0.5 * sin(phase)) * (rail.size.x - segment_width)
	draw_rect(Rect2(x, rail.position.y, segment_width, rail.size.y), ACCENT)
