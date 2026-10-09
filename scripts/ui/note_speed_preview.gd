extends Control
## Presentation-only demo, using the actual gameplay note renderer/positioning.
const NoteScene = preload("res://scenes/note.tscn")
const Settings = preload("res://scripts/user_settings.gd")
var travel_time := Settings.DEFAULT_NOTE_TRAVEL_TIME
var demo_bpm := 140.0
var demo_time := 0.0
var input_style := "8_direction"
var dense_pattern := false
var notes: Array[RhythmNote] = []

func _ready() -> void:
	custom_minimum_size = Vector2(0, 172)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for index in range(16):
		var note := NoteScene.instantiate() as RhythmNote
		add_child(note)
		note.theme_config = load("res://config/theme_config.tres")
		notes.append(note)
	resized.connect(queue_redraw)
	_update_notes()

func set_context(style: String, bpm: float) -> void:
	input_style = "4_arrow" if style == "4_arrow" else "8_direction"
	demo_bpm = bpm if is_finite(bpm) and bpm > 0.0 else 140.0
	demo_time = 0.0
	if is_node_ready():
		_update_notes()
	queue_redraw()

func set_dense_pattern(enabled: bool) -> void:
	dense_pattern = enabled
	demo_time = 0.0
	if is_node_ready():
		_update_notes()
	queue_redraw()

func _beat_offset(index: int) -> float:
	# Illustrative rhythm, not a cached or converted playable chart.
	if dense_pattern:
		return [0.0, 1.0, 2.0, 3.0, 4.0, 4.5, 5.0, 5.5, 6.0, 7.0, 8.0, 9.0, 10.0, 10.5, 11.0, 11.5][index]
	return float(index)

func set_read_time(value: float) -> void:
	travel_time = clampf(value, Settings.MIN_NOTE_TRAVEL_TIME, Settings.MAX_NOTE_TRAVEL_TIME)
	if is_node_ready():
		_update_notes()
	queue_redraw()

func _process(delta: float) -> void:
	# Resident Main Menu children can be locally visible under a hidden route.
	if not is_visible_in_tree():
		return
	demo_time += delta
	_update_notes()
	queue_redraw()

func _update_notes() -> void:
	var beat := 60.0 / demo_bpm
	var cycle := beat * (12.0 if dense_pattern else float(notes.size()))
	for index in range(notes.size()):
		var until := fposmod(_beat_offset(index) * beat - demo_time, cycle)
		var direction := Vector2.UP if index % 2 == 0 else (Vector2.RIGHT if input_style == "4_arrow" else Vector2(1, -1).normalized())
		var note := notes[index]
		note.configure({"type": "normal", "target": demo_time + until, "travel_time": travel_time, "dx": direction.x, "dy": direction.y})
		note.update_track_position(demo_time, size.x * 0.20, size.x * 0.94, size.y * 0.58, travel_time)
		note.visible = until >= 0.0 and until <= travel_time

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0b1018"))
	var center := Vector2(size.x * 0.20, size.y * 0.58)
	draw_line(Vector2(12, center.y), Vector2(size.x - 12, center.y), Color(0.4, 0.7, 0.8, 0.25), 1.0)
	_draw_diamond(center, 40.0, Color.WHITE)
	_draw_diamond(center, 23.0, Color("ffd36b"))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(14, 24), "EXAMPLE PATTERN · %s · %d BPM" % ["4K" if input_style == "4_arrow" else "8K", roundi(demo_bpm)], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("a6bacb"))
	draw_string(font, Vector2(14, size.y - 12), "More reading time also puts more notes on screen.", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("a6bacb"))

func _draw_diamond(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius, 0), center + Vector2(0, radius), center + Vector2(-radius, 0), center + Vector2(0, -radius)])
	draw_polyline(points, color, 2.0, true)
