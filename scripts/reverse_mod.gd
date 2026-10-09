extends RefCounted
## Pure launch-time transformation. Caller supplies its owned runtime chart copy.
const LEVELS := [0, 25, 50, 75, 100]
const VERSION := "reverse_v2_optional"

static func has_authored_reverse(chart: Dictionary) -> bool:
	for event: Variant in chart.get("events", []):
		if event is Dictionary and str(event.get("type", "normal")).to_lower() == "reverse":
			return true
	return false

static func apply(chart: Dictionary, percent: int) -> void:
	var candidates: Array[int] = []
	var events: Array = chart.get("events", [])
	# Preserve source identity; normalize only the caller-owned runtime copy.
	chart["_reverse_policy"] = has_authored_reverse(chart)
	for index in range(events.size()):
		if events[index] is Dictionary and str(events[index].get("type", "normal")).to_lower() in ["normal", "reverse"]:
			events[index]["type"] = "normal"
			events[index].erase("_mod_reverse")
			candidates.append(index)
	if percent == 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = (str(chart.get("_source_chart_hash", "")) + VERSION).sha256_text().left(15).hex_to_int()
	# Independent RNG: does not consume or alter RANDOM direction state.
	for index in range(candidates.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var saved := candidates[index]
		candidates[index] = candidates[other]
		candidates[other] = saved
	var count := roundi(candidates.size() * percent / 100.0)
	for index in range(count):
		var event: Dictionary = events[candidates[index]]
		event["type"] = "reverse"
		event["_mod_reverse"] = true
