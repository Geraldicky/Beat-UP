extends Resource

@export_group("Screen Spacing")
@export_range(0, 96, 1) var screen_margin: int = 24
@export_range(0, 64, 1) var section_gap: int = 14
@export_range(0, 48, 1) var item_gap: int = 8
@export_range(0, 48, 1) var compact_gap: int = 6

@export_group("Result Screen")
@export_range(0.5, 3.0, 0.05) var result_left_ratio: float = 1.65
@export_range(0.5, 3.0, 0.05) var result_rank_ratio: float = 0.9
@export_range(120, 360, 8) var result_button_min_width: int = 208
@export_range(44, 120, 4) var result_button_min_height: int = 56
@export_range(260, 460, 4) var result_rank_min_width: int = 304
@export_range(108, 220, 4) var result_score_panel_min_height: int = 124
@export_range(72, 180, 4) var result_card_min_height: int = 88
@export_range(100, 220, 4) var result_breakdown_min_height: int = 132
@export_range(72, 160, 4) var result_special_panel_min_height: int = 96

@export_group("Song Select")
@export_range(100, 320, 4) var filter_min_width: int = 180
@export_range(480, 1600, 20) var import_dialog_width: int = 900
@export_range(320, 1000, 20) var import_dialog_height: int = 560


@export_group("Song Select Layout")
@export_range(320, 760, 4) var v12_song_info_width: int = 540
@export_range(420, 760, 4) var v12_song_wheel_min_width: int = 620
@export_range(42, 88, 2) var v12_song_row_height: int = 48
@export_range(48, 100, 2) var v12_song_selected_row_height: int = 56
@export_range(10, 40, 1) var v12_song_screen_margin: int = 16
@export_range(6, 30, 1) var v12_song_gap: int = 8
@export_range(0.30, 0.70, 0.01) var v12_song_left_ratio: float = 0.42
@export_range(0.30, 0.70, 0.01) var v12_song_wheel_ratio: float = 0.58

@export_group("Battle HUD")
@export_range(0.12, 0.32, 0.01) var battle_stats_width_ratio: float = 0.18
@export_range(96, 300, 4) var battle_stats_min_height: int = 96
@export_range(6, 40, 2) var battle_panel_inner_margin: int = 10
@export_range(0.30, 0.75, 0.01) var battle_song_info_width_ratio: float = 0.42
@export_range(56, 120, 2) var battle_song_info_height: int = 68
@export_range(120, 360, 4) var battle_judgment_width: int = 236
@export_range(40, 120, 2) var battle_judgment_height: int = 58
@export_range(0.75, 1.8, 0.05) var battle_judgment_scale: float = 1.0
@export_range(0, 100, 2) var battle_feedback_gap: int = 12

@export_group("Startup / Pause")
@export_range(280, 720, 8) var menu_panel_min_width: int = 460
@export_range(280, 720, 8) var settings_panel_min_width: int = 540
@export_range(72, 180, 4) var pause_icon_button_size: int = 96
@export_range(32, 120, 2) var settings_title_height: int = 70
@export_range(24, 96, 2) var settings_label_height: int = 42
@export_range(24, 96, 2) var slider_height: int = 38
@export_range(40, 120, 2) var back_button_height: int = 58
@export_range(8, 96, 2) var hud_edge_margin: int = 22
@export_range(40, 96, 2) var pause_button_size: int = 50
