extends RefCounted
var run_id: String = ""
var committed: bool = false
var save_error: bool = false
var previous_best: Dictionary = {}
func begin() -> void:
 run_id = "%d-%d" % [int(Time.get_unix_time_from_system() * 1000000), Time.get_ticks_usec()]
 committed = false
 save_error = false
 previous_best = {}
