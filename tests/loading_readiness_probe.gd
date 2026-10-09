extends Control

var prepared := false

func prepare() -> void:
	prepared = false

func is_gameplay_transition_ready() -> bool:
	return prepared
