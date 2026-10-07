extends Control
class_name RhythmTrack

const TrackLayoutConfigScript = preload("res://config/track_layout_config.gd")
const ThemeConfigScript = preload("res://config/theme_config.gd")

@export var note_scene: PackedScene
@export var layout_config: TrackLayoutConfigScript
@export var theme_config: ThemeConfigScript

@onready var notes: Control = $Notes
@onready var lane_shadow: Control = $LaneShadow
@onready var lane: Control = $Lane
@onready var hit_point: Marker2D = $HitPoint
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var hit_zone: Control = $HitZone
@onready var hit_zone_inner: Control = $HitZone/InnerDiamond
@onready var hit_zone_caption: Label = $HitZone/HitCaption
@onready var space_prompt: Control = $SpacePrompt
@onready var space_approach: Control = $SpacePrompt/ApproachDiamond
@onready var space_badge: Control = $SpacePrompt/PromptBadge
@onready var space_target: Control = $SpacePrompt/TargetDiamond
@onready var hit_pulse: Control = $FX/HitPulse
@onready var hit_burst: Control = $FX/HitBurst

var hit_feedback_tween: Tween
var effect_intensity: float = 0.75
var _has_position_snapshot := false
var _last_visual_time := 0.0
var _last_travel_time := 1.0
var _last_current_note: RhythmNote

func _ready() -> void:
	if layout_config == null:
		layout_config = TrackLayoutConfigScript.new()
	if theme_config == null:
		theme_config = ThemeConfigScript.new()
	_apply_gameplay_palette()
	resized.connect(apply_layout)
	call_deferred("apply_layout")

func _apply_gameplay_palette() -> void:
	hit_zone.set("fill_color", theme_config.hit_zone_fill)
	hit_zone.set("stroke_color", theme_config.hit_zone_border)
	hit_zone.set("stroke_width", 4.0)
	hit_zone_inner.set("fill_color", theme_config.hit_zone_inner_fill)
	hit_zone_inner.set("stroke_color", theme_config.hit_zone_inner_border)
	hit_zone_caption.add_theme_color_override("font_color", Color(theme_config.base_dark, 0.82))
	hit_zone.queue_redraw()
	hit_zone_inner.queue_redraw()

func apply_layout() -> void:
	if layout_config == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var hit_x: float = size.x * layout_config.hit_x_ratio
	var spawn_x: float = size.x * layout_config.spawn_x_ratio
	var lane_y: float = size.y * layout_config.lane_y_ratio
	var lane_height: float = size.y * layout_config.lane_height_ratio
	# Hotfix 1: extend the gameplay lane flush to the screen edges. Notes still
	# spawn from the responsive spawn_x position, but the lane visual itself now
	# reads as one continuous strip across the whole viewport.
	var lane_left: float = 0.0
	var lane_right: float = size.x
	var lane_top: float = lane_y - lane_height * 0.5
	var shadow_offset: float = size.y * layout_config.shadow_offset_ratio

	hit_point.position = Vector2(hit_x, lane_y)
	spawn_point.position = Vector2(spawn_x, lane_y)
	lane.position = Vector2(lane_left, lane_top)
	lane.size = Vector2(maxf(1.0, lane_right - lane_left), lane_height)
	if lane.has_method("set_receptor_x"):
		lane.call("set_receptor_x", hit_x - lane_left)
	lane_shadow.position = lane.position + Vector2(0.0, shadow_offset)
	lane_shadow.modulate = theme_config.lane_shadow
	lane_shadow.size = lane.size

	var hit_size: Vector2 = Vector2.ONE * get_visual_hit_zone_size()
	hit_zone.position = hit_point.position - hit_size * 0.5
	hit_zone.size = hit_size
	hit_zone.pivot_offset = hit_size * 0.5

	var fx_size: Vector2 = Vector2.ONE * layout_config.hit_feedback_size
	hit_pulse.position = hit_point.position - fx_size * 0.5
	hit_pulse.size = fx_size
	hit_pulse.pivot_offset = fx_size * 0.5
	hit_burst.position = hit_point.position - fx_size * 0.5
	hit_burst.size = fx_size
	hit_burst.pivot_offset = fx_size * 0.5

	var prompt_size: Vector2 = Vector2.ONE * layout_config.space_prompt_canvas_size
	space_prompt.position = hit_point.position - prompt_size * 0.5
	space_prompt.size = prompt_size
	space_approach.pivot_offset = prompt_size * 0.5
	var badge_height: float = layout_config.space_badge_height
	space_badge.position = Vector2(0.0, (prompt_size.y + hit_size.y) * 0.5 + 10.0)
	space_badge.size = Vector2(prompt_size.x, badge_height)
	space_badge.pivot_offset = space_badge.size * 0.5
	var target_size := layout_config.space_approach_target_size
	space_target.position = Vector2.ONE * ((prompt_size.x - target_size) * 0.5)
	space_target.size = Vector2.ONE * target_size
	space_target.set("stroke_color", theme_config.space_accent)
	# Resize can happen while the song clock is frozen. Reproject the last visual
	# snapshot onto the new lane; never advance the clock or judge notes here.
	if _has_position_snapshot:
		update_note_positions(_last_visual_time, _last_travel_time, _last_current_note if is_instance_valid(_last_current_note) else null)

func get_visual_hit_zone_size() -> float:
	# Visual geometry only: HitPoint, spawn, travel and judgement are unchanged.
	return layout_config.hit_zone_size * 1.25 * clampf(size.y / 1080.0, 0.85, 1.1)

func clear_notes() -> void:
	_has_position_snapshot = false
	for child in notes.get_children():
		notes.remove_child(child)
		child.queue_free()
	set_space_prompt(false, 0.0, false)

func clear_notes_batched(batch_size: int = 96) -> void:
	_has_position_snapshot = false
	# Used by the persistent AppShell after gameplay has become hidden. Freeing a
	# full MASTER chart in one frame can stall the newly revealed Song Library,
	# so distribute node detachment across idle frames.
	var pending: Array[Node] = []
	for child: Node in notes.get_children():
		pending.append(child)
	var safe_batch_size: int = maxi(16, batch_size)
	for index: int in range(pending.size()):
		var child: Node = pending[index]
		if is_instance_valid(child) and child.get_parent() == notes:
			notes.remove_child(child)
			child.queue_free()
		if (index + 1) % safe_batch_size == 0:
			await get_tree().process_frame
	set_space_prompt(false, 0.0, false)

func set_input_binding_labels(snapshot: Dictionary) -> void:
	# Keep the Space timing prompt accurate without a compass or live settings I/O.
	var bindings: Dictionary = snapshot.get("bindings", {})
	($SpacePrompt/PromptBadge/Label as Label).text = OS.get_keycode_string(int(bindings.get("space", KEY_SPACE))).to_upper()

func set_effect_intensity_percent(value: float) -> void:
	effect_intensity = clampf(value / 100.0, 0.0, 1.0)

func spawn_note(data: Dictionary) -> RhythmNote:
	if note_scene == null:
		push_error("RhythmTrack.note_scene is not assigned")
		return null
	var note: RhythmNote = note_scene.instantiate() as RhythmNote
	note.theme_config = theme_config
	notes.add_child(note)
	note.configure(data)
	return note

func update_note_positions(current_time: float, travel_time: float, current_note: RhythmNote) -> void:
	_has_position_snapshot = true
	_last_visual_time = current_time
	_last_travel_time = travel_time
	_last_current_note = current_note
	var hit_x: float = hit_point.position.x
	var spawn_x: float = spawn_point.position.x
	var lane_y: float = hit_point.position.y
	for child in notes.get_children():
		var note: RhythmNote = child as RhythmNote
		if note == null:
			continue
		note.update_track_position(current_time, hit_x, spawn_x, lane_y, travel_time)
		note.set_current(note == current_note)

func set_hit_prompt(_current_note: RhythmNote) -> void:
	return

func set_space_prompt(active: bool, progress: float, in_window: bool) -> void:
	if space_prompt == null:
		return
	space_prompt.visible = active
	if not active or layout_config == null:
		return
	var t: float = clampf(progress, 0.0, 1.0)
	var current_size: float = lerpf(layout_config.space_approach_max_size, layout_config.space_approach_target_size, t)
	var pulse: float = 0.5 + 0.5 * sin(t * TAU * layout_config.space_prompt_pulse_cycles)
	var alpha: float = clampf(layout_config.space_prompt_base_alpha + pulse * layout_config.space_prompt_pulse_alpha, 0.0, 1.0)
	var canvas_size: float = layout_config.space_prompt_canvas_size
	space_approach.position = Vector2.ONE * ((canvas_size - current_size) * 0.5)
	space_approach.size = Vector2.ONE * current_size
	var prompt_modulate: Color = Color.WHITE
	prompt_modulate.a = alpha
	for prompt_visual: Control in [space_approach, space_badge]:
		prompt_visual.modulate = prompt_modulate
	space_badge.scale = Vector2.ONE * (layout_config.space_badge_active_scale if in_window else 1.0)
func play_hit_feedback(rating: String) -> void:
	if hit_pulse == null or hit_burst == null or hit_zone == null:
		return
	if hit_feedback_tween != null:
		hit_feedback_tween.kill()
	if effect_intensity <= 0.01:
		_hide_hit_feedback()
		return
	var feedback_color: Color = _feedback_color_for_rating(rating)
	var fx: float = clampf(effect_intensity, 0.0, 1.0)
	var pulse_start_scale: float = lerpf(1.0, layout_config.hit_pulse_start_scale, fx)
	var pulse_end_scale: float = lerpf(1.0, layout_config.hit_pulse_end_scale, fx)
	var burst_start_scale: float = lerpf(1.0, layout_config.hit_burst_start_scale, fx)
	var burst_end_scale: float = lerpf(1.0, layout_config.hit_burst_end_scale, fx)
	var receptor_target: float = layout_config.hit_receptor_miss_scale if rating == "MISS" else layout_config.hit_receptor_hit_scale
	var receptor_scale: float = lerpf(1.0, receptor_target, fx)
	hit_pulse.visible = true
	hit_burst.visible = true
	hit_pulse.modulate = feedback_color
	hit_burst.modulate = feedback_color
	hit_pulse.modulate.a = layout_config.hit_pulse_start_alpha * fx
	hit_burst.modulate.a = layout_config.hit_burst_start_alpha * fx
	hit_pulse.scale = Vector2.ONE * pulse_start_scale
	hit_burst.scale = Vector2.ONE * burst_start_scale
	hit_zone.scale = Vector2.ONE * receptor_scale
	# Keep the timing anchor white; judgement colour belongs to the brief FX.
	hit_zone.modulate = Color.WHITE

	hit_feedback_tween = create_tween()
	hit_feedback_tween.set_parallel(true)
	hit_feedback_tween.tween_property(hit_pulse, "scale", Vector2.ONE * pulse_end_scale, layout_config.hit_feedback_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hit_feedback_tween.tween_property(hit_pulse, "modulate:a", 0.0, layout_config.hit_feedback_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	hit_feedback_tween.tween_property(hit_burst, "scale", Vector2.ONE * burst_end_scale, layout_config.hit_burst_duration).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	hit_feedback_tween.tween_property(hit_burst, "modulate:a", 0.0, layout_config.hit_burst_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	hit_feedback_tween.tween_property(hit_zone, "scale", Vector2.ONE, layout_config.hit_receptor_return_duration).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	hit_feedback_tween.tween_property(hit_zone, "modulate", Color.WHITE, layout_config.hit_receptor_return_duration)
	hit_feedback_tween.set_parallel(false)
	hit_feedback_tween.tween_callback(_hide_hit_feedback)

func _hide_hit_feedback() -> void:
	hit_pulse.visible = false
	hit_burst.visible = false
	hit_pulse.modulate = Color.WHITE
	hit_burst.modulate = Color.WHITE
	hit_pulse.scale = Vector2.ONE
	hit_burst.scale = Vector2.ONE
	hit_zone.scale = Vector2.ONE
	hit_zone.modulate = Color.WHITE

func _feedback_color_for_rating(rating: String) -> Color:
	match rating:
		"PERFECT":
			return theme_config.perfect_color
		"GREAT":
			return theme_config.great_color
		"GOOD":
			return theme_config.good_color
		"MISS":
			return theme_config.miss_color
		_:
			return theme_config.text_primary
