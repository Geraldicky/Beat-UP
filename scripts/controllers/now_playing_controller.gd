extends RefCounted
class_name NowPlayingController

var host: Control
var title_label: Label
var artist_label: Label
var progress_bar: ProgressBar
var duration_label: Label
var previous_button: Button
var play_pause_button: Button
var next_button: Button
var menu_bgm: Node
var background_controller: RefCounted

func configure(
	owner: Control,
	title_view: Label,
	artist_view: Label,
	progress_view: ProgressBar,
	duration_view: Label,
	previous_view: Button,
	play_pause_view: Button,
	next_view: Button,
	bgm_controller: Node,
	background_state_controller: RefCounted
) -> void:
	host = owner
	title_label = title_view
	artist_label = artist_view
	progress_bar = progress_view
	duration_label = duration_view
	previous_button = previous_view
	play_pause_button = play_pause_view
	next_button = next_view
	menu_bgm = bgm_controller
	background_controller = background_state_controller

func update_card() -> void:
	var current_track: Dictionary = _global_song_state()
	if current_track.is_empty() and background_controller != null and background_controller.has_method("get_track_override"):
		var override_value: Variant = background_controller.call("get_track_override")
		if override_value is Dictionary:
			current_track = override_value as Dictionary
	if current_track.is_empty() and background_controller != null and background_controller.has_method("get_current_candidate"):
		var candidate_value: Variant = background_controller.call("get_current_candidate")
		if candidate_value is Dictionary:
			current_track = candidate_value as Dictionary
	if current_track.is_empty():
		title_label.text = "NO TRACK"
		artist_label.text = ""
		_set_transport_icons(true)
		update_progress()
		return
	title_label.text = str(current_track.get("title", ""))
	var artist: String = str(current_track.get("artist", ""))
	artist_label.text = "— " + artist if not artist.is_empty() else ""
	_set_transport_icons(is_paused())
	update_progress()

func set_paused(paused: bool) -> void:
	if menu_bgm == null:
		return
	if paused:
		if menu_bgm.has_method("set_music_paused"):
			menu_bgm.call("set_music_paused", true)
	else:
		# Resume an existing paused stream directly. AudioStreamPlayer.playing can
		# report false while paused; treating that as a cold start used to restart
		# the menu song from 00:00.
		var has_stream: bool = menu_bgm.has_method("get_current_stream") and menu_bgm.call("get_current_stream") != null
		if has_stream and menu_bgm.has_method("set_music_paused"):
			menu_bgm.call("set_music_paused", false)
		elif menu_bgm.has_method("start_menu_music"):
			menu_bgm.call("start_menu_music", 0.18)
	update_card()

func toggle_pause() -> void:
	set_paused(not is_paused())

func is_paused() -> bool:
	return menu_bgm != null and menu_bgm.has_method("is_music_paused") and bool(menu_bgm.call("is_music_paused"))

func update_progress() -> void:
	if progress_bar == null or duration_label == null or menu_bgm == null:
		return
	var length: float = get_track_length()
	var position: float = 0.0
	if menu_bgm.has_method("get_music_playback_position"):
		# Preserve the visible playback clock while paused. The old implementation
		# reset the displayed position to 0 whenever is_music_playing() was false.
		position = clampf(float(menu_bgm.call("get_music_playback_position")), 0.0, maxf(length, 0.0))
	progress_bar.max_value = maxf(length, 1.0)
	progress_bar.value = position
	duration_label.text = "%s / %s" % [format_time(position), format_time(length)]

func get_track_length() -> float:
	if menu_bgm != null and menu_bgm.has_method("get_music_duration"):
		return float(menu_bgm.call("get_music_duration"))
	return 0.0

func format_time(seconds: float) -> String:
	var total_seconds: int = maxi(0, int(round(seconds)))
	var minutes: int = floori(float(total_seconds) / 60.0)
	var secs: int = total_seconds % 60
	return "%d:%02d" % [minutes, secs]

func _set_transport_icons(show_play: bool) -> void:
	previous_button.text = ""
	play_pause_button.text = ""
	next_button.text = ""
	if previous_button.has_method("set_icon_mode"):
		previous_button.call("set_icon_mode", "previous")
	if play_pause_button.has_method("set_icon_mode"):
		play_pause_button.call("set_icon_mode", "play" if show_play else "pause")
	if next_button.has_method("set_icon_mode"):
		next_button.call("set_icon_mode", "next")

func _global_song_state() -> Dictionary:
	if host == null:
		return {}
	var selection_state: Node = host.get_node_or_null("/root/SongSelectionState")
	if selection_state != null and selection_state.has_method("get_state"):
		var value: Variant = selection_state.call("get_state")
		if value is Dictionary:
			return (value as Dictionary).duplicate(true)
	return {}
