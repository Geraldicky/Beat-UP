extends RefCounted
class_name MinimalTheme

# Beat UP! — Album Flow visual foundation.
# These names intentionally keep the v18 API stable so existing screens can be
# restyled without touching gameplay/domain code.

const BG := Color("0b0e14")
const SURFACE := Color("131a24")
const SURFACE_RAISED := Color("1b2430")
const BORDER := Color("344052")
const TEXT := Color("f4f6fb")
const MUTED := Color("8b96a8")

const ACCENT := Color("a9b8ff")
const ACCENT_LIGHT := Color("d8e0ff")
const WARM := Color("f2c8b0")

# Compatibility aliases used throughout the existing project.
# PINK maps to PERFECT/selected-lilac, CYAN maps to GOOD, GOLD maps to Space.
const PINK := Color("d3a4ff")
const CYAN := Color("7db4ce")
const GOLD := Color("f5c96a")
const DANGER := Color("b76c75")
const SUCCESS := Color("7dce9e")

# Semantic rhythm colors. Keeping these named beside the shared UI palette makes
# presentation tests and gameplay drawing agree without moving ownership of any
# gameplay rule into the theme layer.
const NORMAL_BLUE := Color("5697ff")
const DIAGONAL_ORANGE := Color("ffa65c")
const REVERSE_RED := Color("ff5a64")
const SPACE_GOLD := GOLD
const PERFECT_PINK := PINK
const GREAT_GREEN := SUCCESS
const GOOD_CYAN := CYAN
const MISS_RED := DANGER

# Global design tokens.
const SPACE_XS := 4
const SPACE_SM := 8
const SPACE_MD := 12
const SPACE_LG := 16
const SPACE_XL := 24
const SPACE_2XL := 32
const SPACE_3XL := 48
const SPACE_4XL := 64
const SPACE_5XL := 96

const RADIUS_SM := 8
const RADIUS_MD := 14
const RADIUS_LG := 18
const RADIUS_XL := 20

const MOTION_FAST := 0.12
const MOTION_NORMAL := 0.18
const MOTION_SLOW := 0.24

# Type roles are intentionally compact at the 1080p target. Screens may scale
# these down at 720p, but should preserve this hierarchy.
const TYPE_DISPLAY := 52
const TYPE_SCREEN_HEADING := 28
const TYPE_PRIMARY_ACTION := 20
const TYPE_SONG_TITLE := 24
const TYPE_METADATA := 14
const TYPE_SUPPORTING := 12
const TYPE_HUD_VALUE := 36
const TYPE_COMPACT_LABEL := 10

const OPACITY_PRIMARY := 1.0
const OPACITY_SECONDARY := 0.76
const OPACITY_MUTED := 0.52
const OPACITY_DISABLED := 0.42
const MIN_ACTION_HEIGHT := 44

const PANEL_FILL := Color(0.075, 0.102, 0.145, 0.76)
const PANEL_FILL_SOFT := Color(0.075, 0.102, 0.145, 0.46)
const PANEL_BORDER := Color(0.34, 0.40, 0.53, 0.26)

static var _cached_theme: Theme

# Keep the bundled v18 font files so the remake remains deterministic and does
# not depend on operating-system fonts. Roles changed; assets did not.
const POPPINS_REGULAR_PATH := "res://assets/fonts/Poppins-Regular.ttf"
const POPPINS_MEDIUM_PATH := "res://assets/fonts/Poppins-Medium.ttf"
const POPPINS_SEMIBOLD_PATH := "res://assets/fonts/Poppins-SemiBold.ttf"
const IBM_PLEX_MONO_PATH := "res://assets/fonts/IBMPlexMono-Regular.ttf"
const SPACE_GROTESK_PATH := "res://assets/fonts/SpaceGrotesk-Variable.ttf"

static func theme() -> Theme:
	if _cached_theme != null:
		return _cached_theme
	var result := Theme.new()
	result.default_font = body_font()
	result.default_font_size = 15

	_set_label_defaults(result)
	_set_button_defaults(result, "Button")
	_set_button_defaults(result, "OptionButton")
	_set_option_button_defaults(result)
	_set_popup_menu_defaults(result)
	_set_slider_defaults(result)
	_set_check_button_defaults(result)
	_set_line_edit_defaults(result)
	_set_panel_defaults(result)
	_set_progress_defaults(result)
	_set_separator_defaults(result)
	_cached_theme = result
	return result

static func mono_font() -> Font:
	return load(IBM_PLEX_MONO_PATH) as Font

static func body_font() -> Font:
	return load(POPPINS_REGULAR_PATH) as Font

static func medium_font() -> Font:
	return load(POPPINS_MEDIUM_PATH) as Font

static func semibold_font() -> Font:
	return load(POPPINS_SEMIBOLD_PATH) as Font

static func display_font() -> Font:
	return load(SPACE_GROTESK_PATH) as Font

static func numeric_font() -> Font:
	return load(IBM_PLEX_MONO_PATH) as Font

static func technical_font() -> Font:
	return load(IBM_PLEX_MONO_PATH) as Font

# S0 = no surface, S1 = interaction rail, S2 = group surface,
# S3 = modal/task surface. Existing screen code can still call panel_style().
static func surface_s0(padding: float = 0.0) -> StyleBoxFlat:
	return panel_style(Color(0, 0, 0, 0), 0, Color(0, 0, 0, 0), 0, padding)

static func surface_s1(padding: float = 12.0, accent: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var border := Color(BORDER, 0.16) if accent.a <= 0.001 else Color(accent, 0.28)
	return panel_style(Color(SURFACE, 0.40), RADIUS_SM, border, 1, padding)

static func surface_s2(padding: float = 18.0) -> StyleBoxFlat:
	return panel_style(Color(SURFACE_RAISED, 0.72), RADIUS_MD, Color(BORDER, 0.24), 1, padding)

static func surface_s3(padding: float = 22.0) -> StyleBoxFlat:
	var style := panel_style(Color(SURFACE_RAISED, 0.96), RADIUS_XL, Color(ACCENT_LIGHT, 0.20), 1, padding)
	style.shadow_color = Color(0, 0, 0, 0.30)
	style.shadow_size = 14
	return style

static func panel_style(fill: Color = SURFACE, radius: int = RADIUS_LG, border: Color = Color(BORDER, 0.26), border_width: int = 1, padding: float = 18.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = padding
	style.content_margin_top = padding
	style.content_margin_right = padding
	style.content_margin_bottom = padding
	return style

static func button_style(fill: Color, border: Color, radius: int = RADIUS_SM) -> StyleBoxFlat:
	var style := panel_style(fill, radius, border, 1, 12.0)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 11.0
	style.content_margin_bottom = 11.0
	return style

static func _rail_button_style(fill: Color, border: Color, left_width: int, radius: int = RADIUS_SM) -> StyleBoxFlat:
	var style := button_style(fill, border, radius)
	style.border_width_left = left_width
	style.content_margin_left = 20.0
	return style

static func apply_root(root: Control) -> void:
	root.theme = theme()

static func apply_mono(label: Label, size: int = -1, color: Color = MUTED) -> void:
	label.add_theme_font_override("font", technical_font())
	label.add_theme_color_override("font_color", color)
	if size > 0:
		label.add_theme_font_size_override("font_size", size)

static func apply_numeric(label: Label, size: int = -1, color: Color = TEXT) -> void:
	label.add_theme_font_override("font", numeric_font())
	label.add_theme_color_override("font_color", color)
	if size > 0:
		label.add_theme_font_size_override("font_size", size)

static func apply_heading(label: Label, size: int = -1, color: Color = TEXT) -> void:
	label.add_theme_font_override("font", display_font())
	label.add_theme_color_override("font_color", color)
	if size > 0:
		label.add_theme_font_size_override("font_size", size)

static func apply_body(label: Label, size: int = -1, color: Color = TEXT) -> void:
	label.add_theme_font_override("font", body_font())
	label.add_theme_color_override("font_color", color)
	if size > 0:
		label.add_theme_font_size_override("font_size", size)

static func apply_screen_heading(label: Label) -> void:
	apply_heading(label, TYPE_SCREEN_HEADING, TEXT)

static func apply_song_title(label: Label) -> void:
	label.add_theme_font_override("font", semibold_font())
	label.add_theme_font_size_override("font_size", TYPE_SONG_TITLE)
	label.add_theme_color_override("font_color", TEXT)

static func apply_metadata(label: Label) -> void:
	apply_body(label, TYPE_METADATA, Color(TEXT, OPACITY_SECONDARY))

static func apply_supporting(label: Label) -> void:
	apply_body(label, TYPE_SUPPORTING, Color(TEXT, OPACITY_MUTED))

static func apply_hud_value(label: Label) -> void:
	apply_numeric(label, TYPE_HUD_VALUE, TEXT)

static func apply_compact_label(label: Label, color: Color = MUTED) -> void:
	apply_mono(label, TYPE_COMPACT_LABEL, color)

# Primary actions are intentionally not solid neon buttons. They read as a
# stronger S1 rail with a persistent accent edge and high-contrast type.
static func style_primary(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _rail_button_style(Color(SURFACE_RAISED, 0.76), Color(ACCENT, 0.34), 3))
	button.add_theme_stylebox_override("hover", _rail_button_style(Color(ACCENT, 0.11), Color(ACCENT, 0.82), 5))
	button.add_theme_stylebox_override("pressed", _rail_button_style(Color(ACCENT, 0.18), ACCENT, 5))
	button.add_theme_stylebox_override("focus", _rail_button_style(Color(SURFACE_RAISED, 0.94), TEXT, 4))
	button.add_theme_stylebox_override("disabled", _rail_button_style(Color(SURFACE, 0.28), Color(BORDER, 0.16), 2))
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_name, TEXT)
	button.add_theme_color_override("font_disabled_color", Color(MUTED, 0.48))

static func style_secondary(button: Button, accent: Color = ACCENT) -> void:
	button.add_theme_stylebox_override("normal", button_style(Color(SURFACE, 0.34), Color(BORDER, 0.22)))
	button.add_theme_stylebox_override("hover", button_style(Color(accent, 0.08), Color(accent, 0.50)))
	button.add_theme_stylebox_override("pressed", button_style(Color(accent, 0.13), Color(accent, 0.72)))
	button.add_theme_stylebox_override("focus", button_style(Color(SURFACE_RAISED, 0.68), TEXT))
	button.add_theme_stylebox_override("disabled", button_style(Color(SURFACE, 0.20), Color(BORDER, 0.14)))
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_name, TEXT)
	button.add_theme_color_override("font_disabled_color", Color(MUTED, 0.45))

static func style_tertiary(button: Button, accent: Color = ACCENT) -> void:
	button.add_theme_stylebox_override("normal", button_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), RADIUS_SM))
	button.add_theme_stylebox_override("hover", button_style(Color(SURFACE, 0.42), Color(accent, 0.30), RADIUS_SM))
	button.add_theme_stylebox_override("pressed", button_style(Color(accent, 0.09), Color(accent, 0.48), RADIUS_SM))
	button.add_theme_stylebox_override("focus", button_style(Color(SURFACE, 0.42), TEXT, RADIUS_SM))
	button.add_theme_stylebox_override("disabled", button_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), RADIUS_SM))
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_name, TEXT)
	button.add_theme_color_override("font_disabled_color", Color(MUTED, 0.42))

static func style_compact(button: Button, accent: Color = ACCENT) -> void:
	style_tertiary(button, accent)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_font_override("font", medium_font())
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box: StyleBox = button.get_theme_stylebox(state)
		if box is StyleBoxFlat:
			(box as StyleBoxFlat).content_margin_left = 12.0
			(box as StyleBoxFlat).content_margin_right = 12.0
			(box as StyleBoxFlat).content_margin_top = 7.0
			(box as StyleBoxFlat).content_margin_bottom = 7.0

static func style_danger(button: Button) -> void:
	button.add_theme_stylebox_override("normal", button_style(Color(0, 0, 0, 0), Color(DANGER, 0.20)))
	button.add_theme_stylebox_override("hover", button_style(Color(DANGER, 0.10), Color(DANGER, 0.72)))
	button.add_theme_stylebox_override("pressed", button_style(Color(DANGER, 0.16), DANGER))
	button.add_theme_stylebox_override("focus", button_style(Color(DANGER, 0.08), TEXT))
	button.add_theme_color_override("font_color", Color(DANGER, 0.94))
	button.add_theme_color_override("font_hover_color", TEXT)
	button.add_theme_color_override("font_pressed_color", TEXT)
	button.add_theme_color_override("font_focus_color", TEXT)

static func _set_label_defaults(result: Theme) -> void:
	result.set_color("font_color", "Label", TEXT)
	result.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0))

static func _set_button_defaults(result: Theme, type_name: StringName) -> void:
	result.set_color("font_color", type_name, TEXT)
	result.set_color("font_hover_color", type_name, TEXT)
	result.set_color("font_pressed_color", type_name, TEXT)
	result.set_color("font_focus_color", type_name, TEXT)
	result.set_color("font_disabled_color", type_name, Color(MUTED, 0.48))
	result.set_font_size("font_size", type_name, 15)
	result.set_font("font", type_name, medium_font())
	result.set_constant("outline_size", type_name, 0)
	result.set_stylebox("normal", type_name, button_style(Color(SURFACE, 0.28), Color(BORDER, 0.18)))
	result.set_stylebox("hover", type_name, button_style(Color(SURFACE_RAISED, 0.62), Color(ACCENT, 0.46)))
	result.set_stylebox("pressed", type_name, button_style(Color(ACCENT, 0.10), Color(ACCENT, 0.66)))
	result.set_stylebox("focus", type_name, button_style(Color(SURFACE_RAISED, 0.72), TEXT))
	result.set_stylebox("disabled", type_name, button_style(Color(SURFACE, 0.18), Color(BORDER, 0.12)))

static func _set_option_button_defaults(result: Theme) -> void:
	var normal := button_style(Color(SURFACE, 0.44), Color(BORDER, 0.24), RADIUS_SM)
	var hover := button_style(Color(ACCENT, 0.07), Color(ACCENT, 0.48), RADIUS_SM)
	var pressed := button_style(Color(ACCENT, 0.12), Color(ACCENT, 0.70), RADIUS_SM)
	var focus := button_style(Color(SURFACE_RAISED, 0.72), TEXT, RADIUS_SM)
	var disabled := button_style(Color(SURFACE, 0.18), Color(BORDER, 0.12), RADIUS_SM)
	for style in [normal, hover, pressed, focus, disabled]:
		style.content_margin_left = 18.0
		style.content_margin_right = 44.0
		style.content_margin_top = 11.0
		style.content_margin_bottom = 11.0
	result.set_stylebox("normal", "OptionButton", normal)
	result.set_stylebox("hover", "OptionButton", hover)
	result.set_stylebox("pressed", "OptionButton", pressed)
	result.set_stylebox("focus", "OptionButton", focus)
	result.set_stylebox("disabled", "OptionButton", disabled)
	result.set_font("font", "OptionButton", medium_font())
	result.set_font_size("font_size", "OptionButton", 14)
	result.set_constant("arrow_margin", "OptionButton", 16)
	result.set_constant("h_separation", "OptionButton", 12)
	result.set_icon("arrow", "OptionButton", _chevron_texture(Color(TEXT, 0.68)))
	result.set_icon("arrow_pressed", "OptionButton", _chevron_texture(ACCENT_LIGHT))

static func _set_popup_menu_defaults(result: Theme) -> void:
	result.set_font("font", "PopupMenu", medium_font())
	result.set_font_size("font_size", "PopupMenu", 13)
	result.set_color("font_color", "PopupMenu", TEXT)
	result.set_color("font_hover_color", "PopupMenu", TEXT)
	result.set_color("font_disabled_color", "PopupMenu", Color(MUTED, 0.42))
	result.set_color("font_accelerator_color", "PopupMenu", MUTED)
	result.set_constant("item_start_padding", "PopupMenu", 18)
	result.set_constant("item_end_padding", "PopupMenu", 18)
	result.set_constant("v_separation", "PopupMenu", 8)
	result.set_stylebox("panel", "PopupMenu", surface_s3(8.0))
	result.set_stylebox("hover", "PopupMenu", panel_style(Color(ACCENT, 0.11), RADIUS_SM, Color(ACCENT, 0.26), 1, 8.0))
	var separator := StyleBoxLine.new()
	separator.color = Color(BORDER, 0.42)
	separator.thickness = 1
	separator.content_margin_top = 5.0
	separator.content_margin_bottom = 5.0
	result.set_stylebox("separator", "PopupMenu", separator)

static func _set_slider_defaults(result: Theme) -> void:
	var rail := _slider_track_style(Color(SURFACE_RAISED, 0.68), Color(BORDER, 0.22))
	var fill := _slider_track_style(Color(ACCENT, 0.78), Color(ACCENT, 0.28))
	var fill_highlight := _slider_track_style(Color(ACCENT_LIGHT, 0.92), Color(ACCENT_LIGHT, 0.48))
	result.set_stylebox("slider", "HSlider", rail)
	result.set_stylebox("grabber_area", "HSlider", fill)
	result.set_stylebox("grabber_area_highlight", "HSlider", fill_highlight)
	result.set_icon("grabber", "HSlider", _circle_texture(TEXT, ACCENT, 18, 3))
	result.set_icon("grabber_highlight", "HSlider", _circle_texture(TEXT, ACCENT_LIGHT, 20, 3))
	result.set_icon("grabber_disabled", "HSlider", _circle_texture(MUTED, BORDER, 18, 3))
	result.set_constant("center_grabber", "HSlider", 1)

static func _set_check_button_defaults(result: Theme) -> void:
	result.set_font("font", "CheckButton", medium_font())
	result.set_font_size("font_size", "CheckButton", 13)
	result.set_color("font_color", "CheckButton", TEXT)
	result.set_color("font_hover_color", "CheckButton", TEXT)
	result.set_color("font_pressed_color", "CheckButton", TEXT)
	result.set_color("font_disabled_color", "CheckButton", Color(MUTED, 0.42))
	result.set_constant("h_separation", "CheckButton", 18)
	result.set_icon("checked", "CheckButton", _toggle_texture(true, false))
	result.set_icon("unchecked", "CheckButton", _toggle_texture(false, false))
	result.set_icon("checked_disabled", "CheckButton", _toggle_texture(true, true))
	result.set_icon("unchecked_disabled", "CheckButton", _toggle_texture(false, true))
	var empty := StyleBoxEmpty.new()
	empty.content_margin_left = 0.0
	empty.content_margin_right = 0.0
	empty.content_margin_top = 6.0
	empty.content_margin_bottom = 6.0
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		result.set_stylebox(state, "CheckButton", empty)

static func _slider_track_style(fill: Color, outline: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = outline
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	return style

static func _circle_texture(fill: Color, border: Color, diameter: int, border_width: int) -> ImageTexture:
	var image := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var center := Vector2(float(diameter - 1), float(diameter - 1)) * 0.5
	var outer_radius := float(diameter) * 0.5 - 0.75
	var inner_radius := outer_radius - float(border_width)
	for y in range(diameter):
		for x in range(diameter):
			var distance := Vector2(float(x), float(y)).distance_to(center)
			if distance > outer_radius + 0.5:
				continue
			var color := fill if distance <= inner_radius else border
			color.a *= clampf(outer_radius + 0.5 - distance, 0.0, 1.0)
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)

static func _chevron_texture(color: Color) -> ImageTexture:
	var width := 16
	var height := 10
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var left_start := Vector2(3.0, 2.0)
	var center := Vector2(8.0, 7.0)
	var right_end := Vector2(13.0, 2.0)
	for y in range(height):
		for x in range(width):
			var point := Vector2(float(x), float(y))
			var distance := minf(_distance_to_segment(point, left_start, center), _distance_to_segment(point, center, right_end))
			if distance <= 1.25:
				var pixel := color
				pixel.a *= clampf(1.75 - distance, 0.0, 1.0)
				image.set_pixel(x, y, pixel)
	return ImageTexture.create_from_image(image)

static func _toggle_texture(enabled: bool, disabled: bool) -> ImageTexture:
	var width := 44
	var height := 24
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var radius := float(height) * 0.5 - 1.0
	var left_center := Vector2(radius + 1.0, float(height) * 0.5)
	var right_center := Vector2(float(width) - radius - 1.0, float(height) * 0.5)
	var track_fill := Color(ACCENT, 0.28) if enabled else Color(SURFACE_RAISED, 0.80)
	var track_border := Color(ACCENT, 0.72) if enabled else Color(BORDER, 0.62)
	var knob_center := right_center if enabled else left_center
	var opacity := 0.38 if disabled else 1.0
	for y in range(height):
		for x in range(width):
			var point := Vector2(float(x), float(y))
			var clamped_x := clampf(point.x, left_center.x, right_center.x)
			var track_distance := point.distance_to(Vector2(clamped_x, left_center.y))
			var pixel := Color.TRANSPARENT
			if track_distance <= radius:
				pixel = track_fill if track_distance <= radius - 1.5 else track_border
			var knob_distance := point.distance_to(knob_center)
			if knob_distance <= radius - 3.0:
				pixel = TEXT if enabled else MUTED
			pixel.a *= opacity
			image.set_pixel(x, y, pixel)
	return ImageTexture.create_from_image(image)

static func _distance_to_segment(point: Vector2, start: Vector2, finish: Vector2) -> float:
	var segment := finish - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.0001:
		return point.distance_to(start)
	var t := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * t)

static func _set_line_edit_defaults(result: Theme) -> void:
	result.set_font("font", "LineEdit", body_font())
	result.set_color("font_color", "LineEdit", TEXT)
	result.set_color("font_placeholder_color", "LineEdit", Color(MUTED, 0.68))
	result.set_color("caret_color", "LineEdit", ACCENT_LIGHT)
	result.set_color("selection_color", "LineEdit", Color(ACCENT, 0.24))
	result.set_stylebox("normal", "LineEdit", button_style(Color(SURFACE, 0.40), Color(BORDER, 0.24)))
	result.set_stylebox("focus", "LineEdit", button_style(Color(SURFACE_RAISED, 0.66), ACCENT_LIGHT))

static func _set_panel_defaults(result: Theme) -> void:
	result.set_stylebox("panel", "Panel", surface_s2())
	result.set_stylebox("panel", "PanelContainer", surface_s2())

static func _set_progress_defaults(result: Theme) -> void:
	var background := panel_style(Color(SURFACE_RAISED, 0.56), 3, Color(0, 0, 0, 0), 0, 0.0)
	var fill := panel_style(ACCENT, 3, Color(0, 0, 0, 0), 0, 0.0)
	result.set_stylebox("background", "ProgressBar", background)
	result.set_stylebox("fill", "ProgressBar", fill)
	result.set_color("font_color", "ProgressBar", Color.TRANSPARENT)

static func _set_separator_defaults(result: Theme) -> void:
	var line := StyleBoxLine.new()
	line.color = Color(BORDER, 0.36)
	line.thickness = 1
	result.set_stylebox("separator", "HSeparator", line)
	result.set_stylebox("separator", "VSeparator", line)
