extends Control
class_name RhythmNote

const ThemeConfigScript = preload("res://config/theme_config.gd")
const MinimalThemeScript = preload("res://scripts/ui/minimal_theme.gd")

@export var theme_config: ThemeConfigScript

@export_group("Visual Scale")
@export_range(0.2, 2.0, 0.01) var visual_scale := 0.98
@export_range(0.2, 2.0, 0.01) var current_visual_scale := 1.06
@export_range(0.0, 1.0, 0.01) var inactive_alpha := 0.94

@export_group("Hit Animation")
@export_range(1.0, 2.0, 0.01) var hit_scale_multiplier := 1.14
@export_range(0.0, 0.5, 0.005) var hit_pop_duration := 0.055
@export_range(0.0, 0.5, 0.005) var hit_fade_duration := 0.090

@export_group("Visibility")
@export_range(0.0, 300.0, 1.0) var spawn_visibility_margin := 60.0
@export_range(0.0, 300.0, 1.0) var hit_visibility_margin := 100.0
@export_range(0.5, 8.0, 0.05) var fallback_travel_duration := 3.2

@onready var judgement_anchor: Marker2D = $JudgementAnchor

var note_type := "normal"
var expected_key := KEY_NONE
var display_key := KEY_NONE
var target_time := 0.0
var travel_duration := 3.2
var direction_vector := Vector2.RIGHT
var runtime_event_index := -1
var authored_direction := 0
var judged := false
var resolving_hit := false
var is_current_note := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = size * 0.5
	resized.connect(func():
		pivot_offset = size * 0.5
		queue_redraw()
	)
	queue_redraw()

func configure(data: Dictionary) -> void:
	note_type = str(data.get("type", "normal"))
	expected_key = int(data.get("key", KEY_NONE))
	display_key = int(data.get("display_key", KEY_NONE))
	target_time = float(data.get("target", 0.0))
	travel_duration = float(data.get("travel_time", fallback_travel_duration))
	direction_vector = Vector2(float(data.get("dx", 1.0)), float(data.get("dy", 0.0))).normalized()
	runtime_event_index = int(data.get("runtime_event_index", -1))
	authored_direction = int(data.get("authored_direction", 0))
	apply_visual(false)

func set_current(value: bool) -> void:
	if judged or value == is_current_note:
		return
	apply_visual(value)

func apply_visual(value: bool) -> void:
	is_current_note = value
	scale = Vector2.ONE * (current_visual_scale if value else visual_scale)
	modulate = Color.WHITE if value else Color(1.0, 1.0, 1.0, inactive_alpha)
	queue_redraw()

func _draw() -> void:
	var palette := _note_palette()
	var center := size * 0.5
	var half_extent := minf(size.x, size.y) * 0.39

	# One soft shadow is enough to separate the diamond from artwork-derived
	# ambience without creating the old neon/glow stack.
	_draw_diamond(
		center + Vector2(0.0, 3.0),
		half_extent + 1.0,
		Color(0.0, 0.0, 0.0, 0.24),
		Color.TRANSPARENT,
		0.0
	)
	var outline_width: float = 3.0 if is_current_note else 2.4
	_draw_diamond(center, half_extent, palette[0], palette[1], outline_width)

	# Reverse intentionally keeps the exact Normal-note geometry. Its only visual
	# distinction is the red outer outline returned by get_outline_color().
	# Space retains the diamond silhouette but uses a small warm inner core rather
	# than a directional arrow, making the special input immediately recognisable.
	if note_type == "space":
		_draw_diamond(center, half_extent * 0.34, Color(palette[1], 0.92), Color(palette[1], 0.92), 1.0)

	if is_current_note:
		_draw_diamond(
			center,
			half_extent + 5.0,
			Color.TRANSPARENT,
			Color(MinimalThemeScript.ACCENT_LIGHT, 0.42),
			1.0
		)
	if note_type != "space":
		_draw_arrow(center, direction_vector, get_arrow_color())

func get_arrow_color() -> Color:
	# Album Flow keeps the arrow high-contrast and geometric; semantics live in
	# silhouette/stroke structure as well as colour.
	return theme_config.text_primary if theme_config != null else MinimalThemeScript.TEXT

func get_outline_color() -> Color:
	if note_type == "reverse":
		return theme_config.reverse_note_outline if theme_config != null else Color("ff5a64")
	if note_type == "space":
		return theme_config.space_accent if theme_config != null else MinimalThemeScript.GOLD
	if _is_diagonal_direction(direction_vector):
		return theme_config.diagonal_note_outline if theme_config != null else MinimalThemeScript.ACCENT_LIGHT
	return theme_config.normal_note_color if theme_config != null else MinimalThemeScript.ACCENT_LIGHT

func _is_diagonal_direction(direction: Vector2) -> bool:
	var safe_direction := direction.normalized()
	return absf(safe_direction.x) > 0.25 and absf(safe_direction.y) > 0.25

func _draw_diamond(center: Vector2, half_extent: float, fill: Color, stroke: Color, width: float) -> void:
	var points := PackedVector2Array([
		center + Vector2(0.0, -half_extent),
		center + Vector2(half_extent, 0.0),
		center + Vector2(0.0, half_extent),
		center + Vector2(-half_extent, 0.0),
	])
	if fill.a > 0.0:
		draw_colored_polygon(points, fill)
	if width <= 0.0 or stroke.a <= 0.0:
		return
	for i in range(points.size()):
		draw_line(points[i], points[(i + 1) % points.size()], stroke, width, true)

func _draw_arrow(center: Vector2, direction: Vector2, color: Color) -> void:
	var safe_direction := direction.normalized()
	if safe_direction == Vector2.ZERO:
		safe_direction = Vector2.RIGHT
	var start := center - safe_direction * 13.0
	var tip := center + safe_direction * 17.0
	var tangent := Vector2(-safe_direction.y, safe_direction.x)
	draw_line(start, tip, color, 4.0, true)
	draw_line(tip, tip - safe_direction * 10.0 + tangent * 7.0, color, 4.0, true)
	draw_line(tip, tip - safe_direction * 10.0 - tangent * 7.0, color, 4.0, true)

func _note_palette() -> Array[Color]:
	var dark_fill := theme_config.note_fill_color if theme_config != null else MinimalThemeScript.BG
	match note_type:
		"space":
			return [dark_fill, get_outline_color(), MinimalThemeScript.TEXT]
		_:
			# Normal and Reverse intentionally share the same fill and silhouette.
			# Reverse differs only through its red outline.
			return [dark_fill, get_outline_color(), MinimalThemeScript.TEXT]

func update_track_position(current_time: float, hit_x: float, spawn_x: float, lane_y: float, _travel_time: float) -> void:
	if judged:
		if not resolving_hit:
			visible = false
		return
	var time_until := target_time - current_time
	var ratio := time_until / maxf(0.001, travel_duration)
	var x := hit_x + ratio * (spawn_x - hit_x)
	position = Vector2(x, lane_y) - judgement_anchor.position
	visible = x <= spawn_x + spawn_visibility_margin and x >= hit_x - hit_visibility_margin

func mark_hit(hit_x: float, lane_y: float) -> void:
	if judged:
		return
	judged = true
	resolving_hit = true
	position = Vector2(hit_x, lane_y) - judgement_anchor.position
	visible = true
	modulate = Color.WHITE
	var start_scale := scale
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", start_scale * hit_scale_multiplier, hit_pop_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, hit_fade_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)

func mark_judged() -> void:
	if judged:
		return
	judged = true
	resolving_hit = false
	visible = false
	queue_free()
