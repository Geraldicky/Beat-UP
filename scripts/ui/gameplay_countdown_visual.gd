extends Control
class_name GameplayCountdownVisual

# Generated source sprites remain untouched. These measured alpha >= 50%
# silhouette bounds (+6 px safety) exclude faint generated edge noise, which
# makes Image.get_used_rect() mistakenly include most of the source canvas.
const NUMERAL_SOURCES: Array[Texture2D] = [
	preload("res://assets/ui/countdown/resume_1.png"),
	preload("res://assets/ui/countdown/resume_2.png"),
	preload("res://assets/ui/countdown/resume_3.png"),
]
const NUMERAL_REGIONS: Array[Rect2] = [
	Rect2(462, 200, 301, 873),
	Rect2(307, 175, 650, 932),
	Rect2(359, 218, 537, 815),
]
const ACCENT := Color("8bdcff")
var _numerals: Array[AtlasTexture] = []
var _remaining := 3.0
var _duration := 3.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for index in range(NUMERAL_SOURCES.size()):
		var atlas := AtlasTexture.new()
		atlas.atlas = NUMERAL_SOURCES[index]
		atlas.region = NUMERAL_REGIONS[index]
		atlas.filter_clip = true
		_numerals.append(atlas)

func get_number_texture(second: int) -> Texture2D:
	if second < 1 or second > _numerals.size():
		return null
	return _numerals[second - 1]

func set_countdown(remaining: float, duration: float) -> void:
	_remaining = maxf(0.0, remaining)
	_duration = maxf(0.001, duration)
	queue_redraw()

func set_go() -> void:
	_remaining = 0.0
	queue_redraw()

func trigger_step() -> void:
	queue_redraw()

func get_progress_rect() -> Rect2:
	return Rect2(Vector2(size.x * 0.5 - 90.0, size.y - 20.0), Vector2(180.0, 3.0))

func _draw() -> void:
	# One linear rail shows actual time remaining. No breathing, expanding
	# brackets, decorative ticks or animation-owned gameplay deadlines.
	var rail := get_progress_rect()
	draw_rect(rail, Color(ACCENT, 0.16))
	var fill := rail
	fill.size.x *= clampf(1.0 - _remaining / _duration, 0.0, 1.0)
	draw_rect(fill, Color(ACCENT, 0.9))
