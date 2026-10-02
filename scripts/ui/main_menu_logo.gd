extends Control
class_name MainMenuLogo

const TEXT := "BEAT UP!"
const WHITE := Color("f4f6fb")
const PINK := Color("a9b8ff")
const CYAN := Color("d8e0ff")

@export var show_text: bool = true

const GLYPH_WIDTHS := {
	"B": 0.72,
	"E": 0.66,
	"A": 0.78,
	"T": 0.76,
	"U": 0.76,
	"P": 0.70,
	"!": 0.18,
}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	if not show_text or size.x <= 1.0 or size.y <= 1.0:
		return
	var letter_gap := 0.15
	var word_gap := 0.34
	var total_width := 0.0
	for character in TEXT:
		if character == " ":
			total_width += word_gap
		else:
			total_width += float(GLYPH_WIDTHS.get(character, 0.70)) + letter_gap
	total_width -= letter_gap
	var scale_factor := minf(size.x / total_width, size.y / 1.12)
	var origin := Vector2(
		(size.x - total_width * scale_factor) * 0.5,
		(size.y - scale_factor) * 0.5
	)
	var stroke := clampf(scale_factor * 0.066, 3.0, 9.0)
	# Album Flow wordmark: one quiet periwinkle offset, then a crisp neutral face.
	# The former chromatic/glitch stack was intentionally removed.
	var accent_offset := Vector2(stroke * 0.34, stroke * 0.34)
	_draw_word(origin + accent_offset, scale_factor, stroke * 0.74, Color(PINK, 0.34))
	_draw_word(origin, scale_factor, stroke * 0.66, WHITE)

func _draw_word(origin: Vector2, scale_factor: float, stroke: float, color: Color) -> void:
	var cursor := origin
	for character in TEXT:
		if character == " ":
			cursor.x += 0.34 * scale_factor
			continue
		_draw_glyph(character, cursor, scale_factor, stroke, color)
		cursor.x += (float(GLYPH_WIDTHS.get(character, 0.70)) + 0.15) * scale_factor

func _draw_glyph(character: String, origin: Vector2, scale_factor: float, stroke: float, color: Color) -> void:
	var segments: Array = []
	match character:
		"B":
			segments = [
				[Vector2(0.06, 0.00), Vector2(0.06, 0.42)],
				[Vector2(0.06, 0.58), Vector2(0.06, 1.00)],
				[Vector2(0.06, 0.00), Vector2(0.50, 0.00), Vector2(0.68, 0.14), Vector2(0.68, 0.36), Vector2(0.52, 0.49), Vector2(0.18, 0.49)],
				[Vector2(0.26, 0.49), Vector2(0.54, 0.49), Vector2(0.70, 0.63), Vector2(0.70, 0.86), Vector2(0.52, 1.00), Vector2(0.06, 1.00)],
			]
		"E":
			segments = [
				[Vector2(0.06, 0.00), Vector2(0.06, 1.00)],
				[Vector2(0.06, 0.00), Vector2(0.66, 0.00)],
				[Vector2(0.06, 0.49), Vector2(0.52, 0.49)],
				[Vector2(0.06, 1.00), Vector2(0.66, 1.00)],
			]
		"A":
			segments = [
				[Vector2(0.02, 1.00), Vector2(0.34, 0.00)],
				[Vector2(0.44, 0.00), Vector2(0.76, 1.00)],
				[Vector2(0.17, 0.58), Vector2(0.61, 0.58)],
			]
		"T":
			segments = [
				[Vector2(0.00, 0.00), Vector2(0.76, 0.00)],
				[Vector2(0.38, 0.00), Vector2(0.38, 0.44)],
				[Vector2(0.38, 0.58), Vector2(0.38, 1.00)],
			]
		"U":
			segments = [
				[Vector2(0.04, 0.00), Vector2(0.04, 0.75), Vector2(0.20, 0.96), Vector2(0.38, 1.00)],
				[Vector2(0.38, 1.00), Vector2(0.56, 0.96), Vector2(0.72, 0.75), Vector2(0.72, 0.00)],
			]
		"P":
			segments = [
				[Vector2(0.06, 0.00), Vector2(0.06, 0.42)],
				[Vector2(0.06, 0.58), Vector2(0.06, 1.00)],
				[Vector2(0.06, 0.00), Vector2(0.50, 0.00), Vector2(0.68, 0.15), Vector2(0.68, 0.37), Vector2(0.50, 0.52), Vector2(0.20, 0.52)],
			]
		"!":
			segments = [
				[Vector2(0.09, 0.00), Vector2(0.09, 0.64)],
				[Vector2(0.09, 0.90), Vector2(0.09, 1.00)],
			]
	for segment in segments:
		var points := PackedVector2Array()
		for point in segment:
			points.append(origin + (point as Vector2) * scale_factor)
		draw_polyline(points, color, stroke, true)
