extends Resource

# Beat UP! Album Flow presentation tokens.
# Gameplay rules are intentionally not encoded here; this resource is visual only.

@export_group("Core Palette")
@export var base_dark: Color = Color("0b0e14")
@export var text_primary: Color = Color("f4f6fb")
@export var text_secondary: Color = Color("c8d0dd")
@export var accent_primary: Color = Color("a9b8ff")
@export var accent_secondary: Color = Color("d8e0ff")
@export var danger: Color = Color("b76c75")
@export var success: Color = Color("7dce9e")
@export var space_accent: Color = Color("f5c96a")

@export_group("Judgement Palette")
@export var perfect_color: Color = Color("d3a4ff")
@export var great_color: Color = Color("7dce9e")
@export var good_color: Color = Color("7db4ce")
@export var miss_color: Color = Color("b76c75")

@export_group("Gameplay Palette")
@export var normal_note_color: Color = Color("d8e0ff")
@export var note_fill_color: Color = Color("101722")
@export var diagonal_note_outline: Color = Color("c7d4ff")
@export var reverse_note_outline: Color = Color("ff5a64")
@export var hit_zone_fill: Color = Color(0.66, 0.72, 1.0, 0.055)
@export var hit_zone_border: Color = Color(0.85, 0.88, 1.0, 0.72)
@export var hit_zone_inner_fill: Color = Color(0.85, 0.88, 1.0, 0.022)
@export var hit_zone_inner_border: Color = Color(0.85, 0.88, 1.0, 0.30)

@export_group("Typography")
@export_range(8, 96, 1) var caption_size: int = 11
@export_range(8, 96, 1) var body_size: int = 15
@export_range(8, 96, 1) var meta_size: int = 15
@export_range(8, 128, 1) var title_size: int = 32
@export_range(8, 160, 1) var score_size: int = 68
@export_range(8, 220, 1) var rank_size: int = 150
@export_range(8, 96, 1) var card_value_size: int = 28
@export_range(8, 96, 1) var button_size: int = 16

@export_group("UI Opacity")
@export_range(0.0, 1.0, 0.01) var muted_alpha: float = 0.72

@export_group("Scene Effects")
@export var lane_shadow: Color = Color(0.01, 0.015, 0.025, 0.34)
