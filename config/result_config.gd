extends Resource

@export_group("Accuracy Weights")
@export_range(0.0, 1.0, 0.01) var perfect_accuracy_weight: float = 1.00
@export_range(0.0, 1.0, 0.01) var great_accuracy_weight: float = 0.80
@export_range(0.0, 1.0, 0.01) var good_accuracy_weight: float = 0.50
@export_range(0.0, 1.0, 0.01) var miss_accuracy_weight: float = 0.00

@export_group("Rank Thresholds")
@export_range(0.0, 100.0, 0.1) var ss_accuracy: float = 98.5
@export_range(0.0, 100.0, 0.1) var s_accuracy: float = 95.0
@export_range(0.0, 100.0, 0.1) var a_accuracy: float = 88.0
@export_range(0.0, 100.0, 0.1) var b_accuracy: float = 78.0
@export_range(0.0, 100.0, 0.1) var c_accuracy: float = 65.0

@export_group("Result Labels")
@export var full_combo_label: String = "FULL COMBO"
@export var excellent_label: String = "EXCELLENT"
@export var great_clear_label: String = "GREAT CLEAR"
@export var clear_label: String = "CLEAR"
@export_range(0.0, 100.0, 0.1) var excellent_accuracy: float = 95.0
@export_range(0.0, 100.0, 0.1) var great_clear_accuracy: float = 88.0

@export_group("Result Reveal")
@export_range(0.05, 0.60, 0.01) var header_reveal_duration: float = 0.14
@export_range(0.05, 0.80, 0.01) var rank_reveal_duration: float = 0.24
@export_range(0.05, 0.60, 0.01) var stats_reveal_duration: float = 0.16
@export_range(0.10, 1.50, 0.05) var score_count_duration: float = 0.85
@export_range(0.05, 0.60, 0.01) var actions_reveal_duration: float = 0.12
@export_range(0.00, 0.30, 0.01) var action_unlock_delay: float = 0.08
@export_range(0.50, 1.00, 0.01) var rank_pop_start_scale: float = 0.82
