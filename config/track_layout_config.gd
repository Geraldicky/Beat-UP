extends Resource

@export_group("Responsive Geometry")
@export_range(0.02, 0.35, 0.005) var hit_x_ratio: float = 0.20
@export_range(0.55, 0.99, 0.005) var spawn_x_ratio: float = 0.965
@export_range(0.25, 0.90, 0.005) var lane_y_ratio: float = 0.45
@export_range(0.08, 0.40, 0.005) var lane_height_ratio: float = 0.18
@export_range(0.0, 0.12, 0.005) var lane_side_padding_ratio: float = 0.018
@export_range(0.0, 0.08, 0.002) var shadow_offset_ratio: float = 0.006

@export_group("Hit Zone")
@export_range(80.0, 260.0, 1.0) var hit_zone_size: float = 112.0
@export_range(100.0, 260.0, 1.0) var hit_feedback_size: float = 164.0
@export_range(0.04, 0.40, 0.01) var hit_feedback_duration: float = 0.14
@export_range(0.04, 0.40, 0.01) var hit_burst_duration: float = 0.10
@export_range(0.04, 0.40, 0.01) var hit_receptor_return_duration: float = 0.13
@export_range(0.0, 1.0, 0.01) var hit_pulse_start_alpha: float = 0.74
@export_range(0.0, 1.0, 0.01) var hit_burst_start_alpha: float = 0.52
@export_range(0.2, 2.0, 0.01) var hit_pulse_start_scale: float = 0.72
@export_range(0.2, 2.5, 0.01) var hit_pulse_end_scale: float = 1.24
@export_range(0.2, 2.0, 0.01) var hit_burst_start_scale: float = 0.70
@export_range(0.2, 2.5, 0.01) var hit_burst_end_scale: float = 1.02
@export_range(0.5, 1.5, 0.01) var hit_receptor_hit_scale: float = 1.035
@export_range(0.5, 1.5, 0.01) var hit_receptor_miss_scale: float = 0.98
@export_range(80.0, 240.0, 1.0) var space_prompt_canvas_size: float = 158.0
@export_range(24.0, 96.0, 1.0) var space_badge_height: float = 30.0
@export_range(0.8, 1.3, 0.01) var space_badge_active_scale: float = 1.05

@export_group("Space Prompt Animation")
@export_range(80.0, 320.0, 1.0) var space_approach_max_size: float = 190.0
@export_range(40.0, 160.0, 1.0) var space_approach_target_size: float = 90.0
@export_range(0.0, 1.0, 0.01) var space_prompt_base_alpha: float = 0.82
@export_range(0.0, 0.5, 0.01) var space_prompt_pulse_alpha: float = 0.18
@export_range(0.0, 12.0, 0.25) var space_prompt_pulse_cycles: float = 4.0
