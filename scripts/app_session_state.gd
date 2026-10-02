extends Node

# Process-lifetime UI state. This is intentionally NOT written to user://.
# Closing the game destroys this autoload, so the launch splash is shown again
# on the next real application launch, but never on scene returns in the same run.
var splash_seen: bool = false

func mark_splash_seen() -> void:
	splash_seen = true

func should_show_launch_splash() -> bool:
	return not splash_seen
