extends RefCounted
static func accuracy(perfect: int, great: int, good: int, miss: int, config: Resource) -> float:
 var judged: int = perfect + great + good + miss
 if judged <= 0: return 0.0
 if config == null: return float(perfect + great + good) / float(judged) * 100.0
 var weighted: float = perfect * float(config.perfect_accuracy_weight) + great * float(config.great_accuracy_weight) + good * float(config.good_accuracy_weight) + miss * float(config.miss_accuracy_weight)
 return clampf(weighted / float(judged) * 100.0, 0.0, 100.0)
static func rank_for_accuracy(value: float, config: Resource) -> String:
 if config == null: return "D"
 for grade: String in ["SS", "S", "A", "B", "C"]:
  if value >= float(config.get(grade.to_lower() + "_accuracy")): return grade
 return "D"

static func judgement(distance: float, perfect_window: float, great_window: float) -> String:
 if distance <= perfect_window: return "PERFECT"
 if distance <= great_window: return "GREAT"
 return "GOOD"
