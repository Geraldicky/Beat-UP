extends Control

const Palette = preload("res://scripts/ui/minimal_theme.gd")
const COLORS = {"PERFECT": Color("ff5dc8"), "GREAT": Color("52e0ae"), "GOOD": Color("38d6f5"), "MISS": Color("ff647e")}
@export var progress_mode := false
var events: Array = []
var duration_s := 0.0
var max_combo := 0

func _ready() -> void:
	resized.connect(queue_redraw)

func set_events(source: Array, duration: float) -> void:
	events = source.duplicate(true)
	duration_s = maxf(0.0, duration)
	queue_redraw()

func _color(judgement: String) -> Color:
	return COLORS.get(judgement.to_upper(), COLORS.MISS)

func _draw() -> void:
	var font := preload("res://assets/fonts/SpaceGrotesk-Variable.ttf")
	var scale_factor := clampf(get_viewport_rect().size.y / 1080.0, 0.66, 1.0)
	var inset := 24.0 * scale_factor
	var box := Rect2(Vector2.ZERO, size)
	draw_rect(box, Color(0.025, 0.035, 0.05, 0.72))
	draw_rect(box, Color(0.7, 0.78, 0.87, 0.35), false, 1.0)
	var caption := "COMBO / PROGRESS" if progress_mode else "JUDGEMENT TIMING"
	draw_string(font, Vector2(inset, inset), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(15 * scale_factor), Palette.MUTED)
	var plot := Rect2(inset, size.y * (0.66 if progress_mode else 0.30), size.x - inset * 2, size.y * (0.10 if progress_mode else 0.48))
	if progress_mode:
		draw_string(font, Vector2(inset, size.y * 0.32), "MAX COMBO", HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(14 * scale_factor), Palette.MUTED)
		draw_string(font, Vector2(inset, size.y * 0.56), str(max_combo), HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(40 * scale_factor), Palette.TEXT)
	draw_rect(plot, Color(0.12, 0.15, 0.20, 0.65))
	if events.is_empty() or duration_s <= 0:
		draw_string(font, Vector2(inset, size.y * 0.65), "No judgement timeline available", HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(14 * scale_factor), Palette.MUTED)
		return
	if not progress_mode:
		draw_line(Vector2(plot.position.x, plot.get_center().y), Vector2(plot.end.x, plot.get_center().y), Color(Palette.MUTED, 0.4))
		draw_string(font, Vector2(inset, plot.position.y - 5), "+180 ms", HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(10 * scale_factor), Palette.MUTED)
		draw_string(font, Vector2(inset, plot.end.y + 16 * scale_factor), "−180 ms", HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(10 * scale_factor), Palette.MUTED)
	for event: Dictionary in events:
		var x := plot.position.x + clampf(float(event.get("target_time_ms", 0)) / (duration_s * 1000.0), 0, 1) * plot.size.x
		var color := _color(str(event.get("judgement", "MISS")))
		if progress_mode:
			draw_line(Vector2(x, plot.position.y), Vector2(x, plot.end.y), Color(color, 0.8), maxf(1, 2 * scale_factor))
		elif event.get("timing_error_ms") != null:
			var error := clampf(float(event.timing_error_ms), -180, 180)
			draw_circle(Vector2(x, plot.get_center().y - error / 360.0 * plot.size.y), 1.7 * scale_factor, Color(color, 0.8))
	if progress_mode:
		draw_string(font, Vector2(inset, plot.end.y + 22 * scale_factor), "0:00", HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(12 * scale_factor), Palette.MUTED)
		var duration_text := "%d:%02d" % [int(duration_s) / 60, int(duration_s) % 60]
		draw_string(font, Vector2(plot.end.x - 45 * scale_factor, plot.end.y + 22 * scale_factor), duration_text, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(12 * scale_factor), Palette.MUTED)
