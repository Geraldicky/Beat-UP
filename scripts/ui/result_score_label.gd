extends Label

func get_display_digits() -> String:
	return str(maxi(0, int(text.replace(",", "")))).pad_zeros(8)

func _draw() -> void:
	var digits := get_display_digits()
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")
	var zero_width := font.get_string_size("0", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var baseline := (size.y - font.get_height(font_size)) * 0.5 + font.get_ascent(font_size)
	var leading := true
	for index in range(digits.length()):
		var character := digits.substr(index, 1)
		if character != "0" or index == digits.length() - 1:
			leading = false
		draw_string(font, Vector2(index * zero_width, baseline), character, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("536070") if leading else Color("f4f6fb"))
