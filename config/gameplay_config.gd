extends Resource

@export_group("Timing Windows")
@export_range(0.005, 0.200, 0.001) var perfect_window: float = 0.035
@export_range(0.005, 0.250, 0.001) var great_window: float = 0.060
@export_range(0.005, 0.300, 0.001) var good_window: float = 0.090

@export_group("SPACE Timing")
@export_range(0.005, 0.250, 0.001) var space_perfect_window: float = 0.060
@export_range(0.005, 0.350, 0.001) var space_great_window: float = 0.110
@export_range(0.005, 0.450, 0.001) var space_good_window: float = 0.170
@export_range(0.20, 2.00, 0.05) var space_approach_time: float = 0.80

@export_group("Scoring")
@export var perfect_score: int = 120
@export var great_score: int = 95
@export var good_score: int = 70
@export var reverse_score_bonus: int = 35
@export var space_base_score: int = 250
@export var space_perfect_multiplier: float = 1.20
@export var space_great_multiplier: float = 1.00
@export var space_good_multiplier: float = 0.80
@export_range(1.0, 50.0, 0.5) var score_scale_multiplier: float = 13.0

@export_group("Combo Multipliers")
@export var combo_thresholds: PackedInt32Array = PackedInt32Array([10, 25, 50, 100, 200])
@export var combo_multipliers: PackedFloat32Array = PackedFloat32Array([1.25, 1.50, 2.00, 2.50, 3.00])

@export_group("Note Travel")
@export_range(0.5, 4.0, 0.05) var scroll_speed_multiplier: float = 1.00
@export_range(30.0, 300.0, 1.0) var reference_bpm: float = 120.0
@export_range(0.5, 8.0, 0.05) var base_travel_time: float = 1.80
@export_range(0.0, 6.0, 0.05) var bpm_speed_influence: float = 1.80
@export_range(0.45, 8.0, 0.05) var minimum_travel_time: float = 0.50
@export_range(0.5, 8.0, 0.05) var maximum_travel_time: float = 2.60

func get_combo_multiplier(combo_count: int) -> float:
	var multiplier: float = 1.0
	var count: int = mini(combo_thresholds.size(), combo_multipliers.size())
	for i: int in range(count):
		if combo_count < combo_thresholds[i]:
			break
		multiplier = combo_multipliers[i]
	return multiplier

func get_space_rating_multiplier(rating: String) -> float:
	match rating:
		"PERFECT":
			return space_perfect_multiplier
		"GREAT":
			return space_great_multiplier
		_:
			return space_good_multiplier

func get_bpm_speed_factor(bpm: float) -> float:
	# v17.4.5.3: Scroll speed is authored entirely from song BPM.
	# Higher BPM means a shorter approach/travel time, which increases physical
	# spacing between dense notes without changing their hit timing or audio.
	var safe_bpm: float = maxf(1.0, bpm)
	return pow(safe_bpm / maxf(1.0, reference_bpm), bpm_speed_influence)

func get_speed_multiplier(bpm: float) -> float:
	return maxf(0.05, scroll_speed_multiplier * get_bpm_speed_factor(bpm))

func get_travel_time(bpm: float) -> float:
	return clampf(
		base_travel_time / get_speed_multiplier(bpm),
		minimum_travel_time,
		maximum_travel_time
	)
