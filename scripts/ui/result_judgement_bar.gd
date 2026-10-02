extends Control
class_name ResultJudgementBar

var perfect := 0
var great := 0
var good := 0
var miss := 0
var reveal := 0.0:
	set(value):
		reveal = clampf(value, 0.0, 1.0)
		queue_redraw()

var perfect_color := Color("d3a4ff")
var great_color := Color("7dce9e")
var good_color := Color("7db4ce")
var miss_color := Color("b76c75")
var track_color := Color(0.12, 0.14, 0.18, 0.72)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not resized.is_connected(queue_redraw):
		resized.connect(queue_redraw)
	queue_redraw()

func set_counts(perfect_count: int, great_count: int, good_count: int, miss_count: int) -> void:
	perfect = maxi(0, perfect_count)
	great = maxi(0, great_count)
	good = maxi(0, good_count)
	miss = maxi(0, miss_count)
	queue_redraw()

func set_palette(perfect_value: Color, great_value: Color, good_value: Color, miss_value: Color) -> void:
	perfect_color = perfect_value
	great_color = great_value
	good_color = good_value
	miss_color = miss_value
	queue_redraw()

func set_reveal(value: float) -> void:
	reveal = value

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var rect := Rect2(Vector2.ZERO, size)
	draw_style_box(_rounded_box(track_color), rect)
	var total := perfect + great + good + miss
	if total <= 0 or reveal <= 0.0:
		return

	var visible_width := rect.size.x * reveal
	var cursor := 0.0
	var entries := [
		[perfect, perfect_color],
		[great, great_color],
		[good, good_color],
		[miss, miss_color],
	]
	for entry in entries:
		var count := int(entry[0])
		if count <= 0:
			continue
		var segment_width := rect.size.x * float(count) / float(total)
		var draw_width := clampf(visible_width - cursor, 0.0, segment_width)
		if draw_width > 0.0:
			draw_rect(Rect2(Vector2(cursor, 0.0), Vector2(draw_width, rect.size.y)), entry[1])
		cursor += segment_width
		if cursor >= visible_width:
			break

	# Thin separators keep small judgement categories readable without adding labels.
	cursor = 0.0
	for index in range(entries.size() - 1):
		var entry = entries[index]
		cursor += rect.size.x * float(int(entry[0])) / float(maxi(1, total))
		if cursor > 1.0 and cursor < visible_width - 1.0:
			draw_line(Vector2(cursor, 1.0), Vector2(cursor, rect.size.y - 1.0), Color(0.02, 0.03, 0.05, 0.72), 1.0)

func _rounded_box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(3)
	return box
