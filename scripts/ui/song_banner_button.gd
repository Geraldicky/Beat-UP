extends Button
class_name SongBannerButton

const FALLBACK_BG := Color("1a2436")
const TEXT_VEIL := Color("07101d")

var banner_texture: Texture2D
var accent_color: Color = Color("a9b8ff")
var card_variant := "song"
var visual_emphasis := 1.0

func _ready() -> void:
	clip_contents = true
	focus_mode = Control.FOCUS_ALL
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	toggled.connect(_on_toggled)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_THEME_CHANGED:
		queue_redraw()

func configure(texture: Texture2D, accent: Color, variant_name: String = "song") -> void:
	banner_texture = texture
	accent_color = accent
	card_variant = variant_name
	queue_redraw()

func _on_toggled(_pressed: bool) -> void:
	queue_redraw()

func set_visual_emphasis(value: float) -> void:
	visual_emphasis = clampf(value, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		return

	_draw_banner(rect)
	_draw_overlay(rect)
	_draw_accent(rect)

func _draw_banner(rect: Rect2) -> void:
	if card_variant == "compact_song":
		var surface := Color("142334") if button_pressed else (Color("111b28") if is_hovered() else Color("0d141e"))
		draw_rect(rect, surface)
		if button_pressed:
			draw_rect(Rect2(Vector2(4.0, 1.0), Vector2(maxf(0.0, rect.size.x - 5.0), maxf(0.0, rect.size.y - 2.0))), Color(accent_color, 0.075))
		elif is_hovered():
			draw_rect(rect, Color(accent_color, 0.025))
		return
	if banner_texture == null:
		draw_rect(rect, FALLBACK_BG)
		return
	var tex_size := banner_texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		draw_rect(rect, FALLBACK_BG)
		return
	var crop := _cover_region(tex_size, rect.size, 0.38 if card_variant == "song" else 0.46)
	var alpha := 1.0 if button_pressed else lerpf(0.72, 0.86, visual_emphasis)
	if card_variant == "difficulty":
		alpha = maxf(0.72, alpha - 0.05)
	if is_hovered():
		alpha = minf(1.0, alpha + 0.05)
	draw_texture_rect_region(banner_texture, rect, crop, Color(1, 1, 1, alpha))

func _draw_overlay(rect: Rect2) -> void:
	if card_variant == "compact_song":
		if is_hovered() and not button_pressed:
			draw_rect(rect, Color(1, 1, 1, 0.022))
		return
	var selected := button_pressed
	# Distance affects only the artwork treatment. Child labels stay fully opaque.
	var overlay_alpha := 0.14 if selected else lerpf(0.68, 0.46, visual_emphasis)
	if card_variant == "difficulty":
		overlay_alpha += 0.05
	if is_hovered():
		overlay_alpha = maxf(0.13, overlay_alpha - 0.05)
	draw_rect(rect, Color(TEXT_VEIL, overlay_alpha))

	var veil_width := rect.size.x * (0.80 if card_variant == "song" else 0.92)
	var strips := 30
	var lead_alpha := 0.11 if selected else lerpf(0.36, 0.20, visual_emphasis)
	var tail_alpha := 0.015 if selected else lerpf(0.12, 0.045, visual_emphasis)
	if card_variant == "difficulty":
		lead_alpha += 0.025
		tail_alpha += 0.015
	for i in range(strips):
		var t0 := float(i) / float(strips)
		var t1 := float(i + 1) / float(strips)
		var x0 := lerpf(0.0, veil_width, t0)
		var x1 := lerpf(0.0, veil_width, t1)
		var alpha := lerpf(lead_alpha, tail_alpha, pow(t1, 1.2))
		draw_rect(Rect2(Vector2(x0, 0.0), Vector2(x1 - x0, rect.size.y)), Color(TEXT_VEIL, alpha))

	var tint_alpha := 0.045 if selected else lerpf(0.018, 0.030, visual_emphasis)
	if card_variant == "difficulty":
		tint_alpha += 0.025
	draw_rect(rect, Color(accent_color, tint_alpha))

func _draw_accent(rect: Rect2) -> void:
	var border_alpha := 0.34 if button_pressed else 0.025
	if card_variant != "compact_song":
		border_alpha = 1.0 if button_pressed else 0.14
	if is_hovered() and not button_pressed:
		border_alpha = 0.24 if card_variant == "compact_song" else 0.42
	if has_focus():
		border_alpha = maxf(border_alpha, 0.75)
	var border_color := Color(accent_color, border_alpha)
	draw_rect(rect, border_color, false, 1.0)
	var strip_width := 4.0 if card_variant == "compact_song" else (5.0 if card_variant == "song" else 3.0)
	var strip_alpha := 1.0 if button_pressed else 0.0
	if strip_alpha > 0.0:
		draw_rect(Rect2(Vector2.ZERO, Vector2(strip_width, rect.size.y)), Color(accent_color, strip_alpha))
	var shine_alpha := 0.16 if button_pressed else 0.0
	if shine_alpha > 0.0:
		draw_rect(Rect2(Vector2(0.0, 0.0), Vector2(rect.size.x, 1.0)), Color(1, 1, 1, shine_alpha))

func _cover_region(tex_size: Vector2, target_size: Vector2, vertical_bias: float) -> Rect2:
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return Rect2(Vector2.ZERO, tex_size)
	var source_ratio := tex_size.x / tex_size.y
	var target_ratio := target_size.x / target_size.y
	if source_ratio > target_ratio:
		var crop_width := tex_size.y * target_ratio
		var crop_x := (tex_size.x - crop_width) * 0.5
		return Rect2(crop_x, 0.0, crop_width, tex_size.y)
	var crop_height := tex_size.x / target_ratio
	var crop_y := clampf((tex_size.y - crop_height) * vertical_bias, 0.0, tex_size.y - crop_height)
	return Rect2(0.0, crop_y, tex_size.x, crop_height)
