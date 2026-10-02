extends RefCounted

# Central scoring policy for v18.5.0. Keeping the presentation scale here makes
# normal notes and SPACE prompts use one rule and prevents future drift.

const MAX_DISPLAY_SCORE := 9_999_999

static func note_award(base_points: int, combo_multiplier: float, score_scale: float) -> int:
	return maxi(0, int(round(float(base_points) * maxf(0.0, combo_multiplier) * maxf(1.0, score_scale))))

static func space_award(base_points: int, combo_multiplier: float, rating_multiplier: float, score_scale: float) -> int:
	return maxi(0, int(round(
		float(base_points)
		* maxf(0.0, combo_multiplier)
		* maxf(0.0, rating_multiplier)
		* maxf(1.0, score_scale)
	)))

static func accumulate(current_score: int, awarded_score: int) -> int:
	return clampi(current_score + maxi(0, awarded_score), 0, MAX_DISPLAY_SCORE)

static func clamp_score(value: int) -> int:
	return clampi(value, 0, MAX_DISPLAY_SCORE)
