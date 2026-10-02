extends SceneTree

const ResultConfigScript = preload("res://config/result_config.gd")

func _init() -> void:
	var failures: Array[String] = []
	var cfg = ResultConfigScript.new()

	_check_accuracy(cfg, 100, 0, 0, 0, 100.0, failures)
	_check_accuracy(cfg, 0, 100, 0, 0, 80.0, failures)
	_check_accuracy(cfg, 0, 0, 100, 0, 50.0, failures)
	_check_accuracy(cfg, 0, 0, 0, 100, 0.0, failures)
	_check_rank(cfg, 98.5, "SS", failures)
	_check_rank(cfg, 95.0, "S", failures)
	_check_rank(cfg, 88.0, "A", failures)
	_check_rank(cfg, 78.0, "B", failures)
	_check_rank(cfg, 65.0, "C", failures)
	_check_rank(cfg, 64.99, "D", failures)

	if failures.is_empty():
		print("v17.4.12 result model checks: PASS")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)

func _weighted_accuracy(cfg, perfect: int, great: int, good: int, miss: int) -> float:
	var judged: int = perfect + great + good + miss
	if judged <= 0:
		return 0.0
	return (
		float(perfect) * cfg.perfect_accuracy_weight
		+ float(great) * cfg.great_accuracy_weight
		+ float(good) * cfg.good_accuracy_weight
		+ float(miss) * cfg.miss_accuracy_weight
	) / float(judged) * 100.0

func _check_accuracy(cfg, perfect: int, great: int, good: int, miss: int, expected: float, failures: Array[String]) -> void:
	var actual: float = _weighted_accuracy(cfg, perfect, great, good, miss)
	if absf(actual - expected) > 0.001:
		failures.append("Accuracy mismatch: expected %.3f got %.3f" % [expected, actual])

func _rank(cfg, accuracy: float) -> String:
	if accuracy >= cfg.ss_accuracy: return "SS"
	if accuracy >= cfg.s_accuracy: return "S"
	if accuracy >= cfg.a_accuracy: return "A"
	if accuracy >= cfg.b_accuracy: return "B"
	if accuracy >= cfg.c_accuracy: return "C"
	return "D"

func _check_rank(cfg, accuracy: float, expected: String, failures: Array[String]) -> void:
	var actual: String = _rank(cfg, accuracy)
	if actual != expected:
		failures.append("Rank mismatch at %.2f: expected %s got %s" % [accuracy, expected, actual])
