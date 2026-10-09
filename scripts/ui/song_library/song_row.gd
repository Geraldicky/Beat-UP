extends VBoxContainer

const MinimalThemeScript = preload("res://scripts/ui/minimal_theme.gd")
const AnimatedMarginScript = preload("res://scripts/ui/animated_margin_container.gd")
const SongBannerButtonScript = preload("res://scripts/ui/song_banner_button.gd")

@onready var header_wrapper: MarginContainer = $HeaderWrapper
@onready var header_button: Button = $HeaderWrapper/HeaderButton
@onready var index_label: Label = $HeaderWrapper/HeaderButton/Content/Row/SongIndex
@onready var jacket: TextureRect = $HeaderWrapper/HeaderButton/Content/Row/SongJacket
@onready var marker: Control = $HeaderWrapper/HeaderButton/Content/Row/SongMarker
@onready var title_label: Label = $HeaderWrapper/HeaderButton/Content/Row/SongIdentity/SongTitle
@onready var artist_label: Label = $HeaderWrapper/HeaderButton/Content/Row/SongIdentity/SongArtist
@onready var bpm_label: Label = $HeaderWrapper/HeaderButton/Content/Row/SongBpm
@onready var difficulty_box: VBoxContainer = $DifficultyClip/DifficultyBox

func configure_header(index: int, title: String, artist: String, bpm: int, texture: Texture2D, accent: Color, selected: bool, theme_value: Theme, left_margin: float) -> void:
	header_wrapper.call("set_margin_immediate", left_margin)
	header_button.toggle_mode = true
	header_button.focus_mode = Control.FOCUS_NONE
	header_button.set_pressed_no_signal(selected)
	header_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header_button.text = ""
	header_button.tooltip_text = ""
	header_button.theme = theme_value
	header_button.call("configure", texture, accent, "compact_song")

	index_label.text = "%02d" % (index + 1)
	MinimalThemeScript.apply_mono(index_label, 10, Color(MinimalThemeScript.TEXT, 0.52))
	jacket.texture = texture
	marker.set("ink", accent)

	title_label.text = title
	title_label.add_theme_font_override("font", MinimalThemeScript.semibold_font())
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.96))
	title_label.set_meta("base_alpha", 0.96)
	title_label.set_meta("label_role", "song_title")

	artist_label.text = artist
	artist_label.add_theme_font_override("font", MinimalThemeScript.body_font())
	artist_label.add_theme_font_size_override("font_size", 10)
	artist_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.58))
	artist_label.set_meta("base_alpha", 0.58)
	artist_label.set_meta("label_role", "song_subtitle")

	bpm_label.text = str(bpm)
	bpm_label.add_theme_font_override("font", MinimalThemeScript.mono_font())
	bpm_label.add_theme_font_size_override("font_size", 10)
	bpm_label.add_theme_color_override("font_color", Color(MinimalThemeScript.TEXT, 0.68))
	bpm_label.set_meta("base_alpha", 0.68)
	bpm_label.set_meta("label_role", "song_level")

func add_difficulty(diff: String, chart: Dictionary, progress_text: String, texture: Texture2D, accent: Color, selected: bool, theme_value: Theme, left_margin: float) -> Dictionary:
	var wrapper := AnimatedMarginScript.new() as MarginContainer
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.call("set_margin_immediate", left_margin)
	difficulty_box.add_child(wrapper)

	var button := SongBannerButtonScript.new() as Button
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.set_pressed_no_signal(selected)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text = ""
	button.custom_minimum_size.y = 36.0
	button.theme = theme_value
	button.call("configure", texture, accent, "difficulty")
	wrapper.add_child(button)
	_populate_difficulty_content(button, chart, diff, progress_text)
	return {"wrapper": wrapper, "button": button, "difficulty": diff}

func _populate_difficulty_content(button: Button, chart: Dictionary, diff: String, progress_text: String) -> void:
	var content := MarginContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("margin_left", 14)
	content.add_theme_constant_override("margin_right", 14)
	content.add_theme_constant_override("margin_top", 4)
	content.add_theme_constant_override("margin_bottom", 4)
	button.add_child(content)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", 14)
	content.add_child(row)

	var events: Variant = chart.get("events", [])
	var notes: int = (events as Array).size() if events is Array else 0
	var label_text: String = str(chart.get("difficulty", diff.to_upper())).to_upper()
	var stars: int = int(chart.get("star_rating", 1))
	var entries: Array = [
		[label_text, 0.98, 88],
		["%d★" % stars, 0.94, 48],
		[("%d NOTES" % notes) if notes > 0 else "— NOTES", 0.88, 96]
	]
	if progress_text != "UNPLAYED":
		entries.append([progress_text, 0.90, 0])

	for pair: Variant in entries:
		var txt: String = str((pair as Array)[0])
		if txt.is_empty():
			continue
		var item := Label.new()
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.text = txt
		item.add_theme_font_override("font", MinimalThemeScript.mono_font())
		item.add_theme_font_size_override("font_size", 12)
		item.custom_minimum_size.x = float((pair as Array)[2])
		item.add_theme_color_override("font_color", Color(1, 1, 1, float((pair as Array)[1])))
		item.set_meta("base_alpha", float((pair as Array)[1]))
		item.set_meta("label_role", "difficulty_item")
		item.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.72))
		item.add_theme_constant_override("shadow_offset_x", 1)
		item.add_theme_constant_override("shadow_offset_y", 1)
		row.add_child(item)
