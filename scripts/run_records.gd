extends RefCounted
# One atomic store entry contains a coherent best run, history, and aggregates.
const MAX_RUN_HISTORY := 100

static func merge(previous: Dictionary, run: Dictionary) -> Dictionary:
 var entry: Dictionary = previous.duplicate(true)
 var history: Array = entry.get("runs", []).duplicate(true)
 for old: Dictionary in history:
  if str(old.get("run_id", "")) == str(run.get("run_id", "")):
   return {"entry": entry, "better": false, "duplicate": true}
 var better: bool = previous.is_empty() or int(run.score) > int(previous.get("score", -1)) or (int(run.score) == int(previous.get("score", -1)) and float(run.accuracy) > float(previous.get("accuracy", -1.0)))
 if not previous.is_empty() and not previous.has("runs"):
  entry["legacy_record"] = previous.duplicate(true)
 if better:
  for field: String in run:
   entry[field] = run[field]
 history.append(run.duplicate(true))
 while history.size() > MAX_RUN_HISTORY:
  history.pop_front()
 entry["runs"] = history
 entry["plays"] = int(previous.get("plays", 0)) + 1
 entry["cleared"] = true
 entry["best_accuracy"] = maxf(float(previous.get("best_accuracy", previous.get("accuracy", 0.0))), float(run.accuracy))
 entry["best_max_combo"] = maxi(int(previous.get("best_max_combo", previous.get("max_combo", 0))), int(run.max_combo))
 entry["full_combo"] = bool(previous.get("full_combo", false)) or bool(run.run_full_combo)
 entry["record_schema"] = 2
 return {"entry": entry, "better": better, "duplicate": false}

static func ranked(entry: Dictionary) -> Array:
 var rows: Array = entry.get("runs", []).duplicate(true)
 rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
  if int(a.score) != int(b.score): return int(a.score) > int(b.score)
  if float(a.accuracy) != float(b.accuracy): return float(a.accuracy) > float(b.accuracy)
  return float(a.get("completed_at", 0)) > float(b.get("completed_at", 0)))
 return rows
