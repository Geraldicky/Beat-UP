extends RefCounted
class_name MainMenuBackgroundController

var host: Control
var menu_background: TextureRect
var background_song: Label
var background_artist: Label
var menu_bgm: Node
var main_menu: Control
var candidates: Array = []
var refresh_now_playing: Callable

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var current_background_path: String = ""
var current_background_index: int = -1
var visit_count: int = 0
var track_override: Dictionary = {}
var background_randomization_suppressed := false

func configure(
	owner: Control,
	background_view: TextureRect,
	song_label: Label,
	artist_label: Label,
	bgm_controller: Node,
	main_menu_view: Control,
	candidate_list: Array,
	refresh_callback: Callable
) -> void:
	host = owner
	menu_background = background_view
	background_song = song_label
	background_artist = artist_label
	menu_bgm = bgm_controller
	main_menu = main_menu_view
	candidates = candidate_list.duplicate(true)
	refresh_now_playing = refresh_callback
	rng.randomize()

func connect_global_state() -> void:
	var selection_state: Node = _song_selection_state()
	if selection_state != null and selection_state.has_signal("selection_changed"):
		var selection_callback: Callable = Callable(self, "_on_global_selection_changed")
		if not selection_state.is_connected("selection_changed", selection_callback):
			selection_state.connect("selection_changed", selection_callback)
	var background_session: Node = _background_session()
	if background_session != null and background_session.has_signal("background_changed"):
		var background_callback: Callable = Callable(self, "_on_global_background_changed")
		if not background_session.is_connected("background_changed", background_callback):
			background_session.connect("background_changed", background_callback)

func randomize(force: bool = false) -> void:
	if candidates.is_empty():
		return
	var chosen_index: int = 0
	if candidates.size() > 1:
		for _attempt in range(12):
			chosen_index = rng.randi_range(0, candidates.size() - 1)
			if force or chosen_index != current_background_index:
				break
	set_by_index(chosen_index, main_menu != null and main_menu.is_visible_in_tree(), true)

func set_by_index(index: int, force_animation: bool = false, autoplay: bool = true) -> void:
	if candidates.is_empty():
		return
	var safe_index: int = int(posmod(index, candidates.size()))
	var chosen: Dictionary = candidates[safe_index] as Dictionary
	current_background_index = safe_index
	_randomize_ambient_background(chosen, false)
	_publish_candidate_selection(chosen)
	background_song.text = str(chosen.get("title", "SONG LIBRARY")).to_upper()
	background_artist.text = str(chosen.get("artist", ""))
	visit_count += 1
	_apply_background_audio(chosen, autoplay)
	_refresh_now_playing()
	if main_menu != null and main_menu.is_visible_in_tree() and force_animation:
		animate_visit()

func cycle(step: int) -> void:
	track_override.clear()
	if candidates.is_empty():
		return
	var base_index: int = current_background_index if current_background_index >= 0 else 0
	set_by_index(base_index + step, true, true)

func ensure_music_ready(fade_duration: float = 0.18) -> bool:
	# v17.4.35: Cold-launch guard. The initial random artwork can be chosen
	# before the Main Menu is visible, so make the selected candidate capable of
	# rebuilding the global MusicSession if it has no stream yet. Existing music
	# is never restarted; paused state also remains untouched.
	if menu_bgm == null:
		return false
	var state: Dictionary = {}
	if menu_bgm.has_method("get_music_state"):
		var raw_state: Variant = menu_bgm.call("get_music_state")
		if raw_state is Dictionary:
			state = (raw_state as Dictionary).duplicate(true)
	var audio_path: String = str(state.get("audio", ""))
	if not audio_path.is_empty():
		if menu_bgm.has_method("start_menu_music"):
			menu_bgm.call("start_menu_music", fade_duration)
		_refresh_now_playing()
		return true

	var candidate: Dictionary = get_current_candidate()
	if candidate.is_empty() and not candidates.is_empty():
		var fallback_index: int = current_background_index if current_background_index >= 0 else 0
		fallback_index = int(posmod(fallback_index, candidates.size()))
		current_background_index = fallback_index
		candidate = (candidates[fallback_index] as Dictionary).duplicate(true)
		_randomize_ambient_background(candidate, false)
	if candidate.is_empty():
		return false

	_apply_background_audio(candidate, true)
	if menu_bgm.has_method("get_music_state"):
		var refreshed_value: Variant = menu_bgm.call("get_music_state")
		if refreshed_value is Dictionary:
			var refreshed_state: Dictionary = refreshed_value as Dictionary
			return not str(refreshed_state.get("audio", "")).is_empty()
	return false

func sync_from_music_session() -> bool:
	if menu_bgm == null or not menu_bgm.has_method("get_music_state"):
		return false
	var raw_state: Variant = menu_bgm.call("get_music_state")
	if not (raw_state is Dictionary):
		return false
	var state: Dictionary = (raw_state as Dictionary).duplicate(true)
	var audio_path: String = str(state.get("audio", ""))
	if audio_path.is_empty():
		return false
	var global_song: Dictionary = _global_song_state()
	track_override = state.duplicate(true)
	for key_value in global_song.keys():
		var key: Variant = key_value
		track_override[key] = global_song[key]
	var matched_index: int = _find_candidate_index_by_audio(audio_path)
	current_background_index = matched_index
	# Synchronising persistent music is not a new background visit.
	apply_global_state(_global_background_state(), false)
	var was_paused: bool = bool(state.get("paused", false))
	if not was_paused and menu_bgm.has_method("start_menu_music"):
		menu_bgm.call("start_menu_music", 0.18)
	_refresh_now_playing()
	return true

func apply_library_audio_handoff(handoff: Dictionary) -> bool:
	# Compatibility path for standalone navigation. Persistent AppShell normally
	# shares the same MusicSession, so this should only run as a fallback.
	if sync_from_music_session():
		return true
	if handoff.is_empty():
		return false
	var audio_path: String = str(handoff.get("audio", ""))
	if audio_path.is_empty():
		return false
	var position: float = maxf(float(handoff.get("position", 0.0)), 0.0)
	var metadata: Dictionary = handoff.duplicate(true)
	metadata["source"] = "song_library"
	if menu_bgm == null or not menu_bgm.has_method("play_menu_track"):
		return false
	var started: bool = bool(menu_bgm.call("play_menu_track", audio_path, position, metadata, false, 0.18, false))
	if not started:
		return false
	track_override = metadata.duplicate(true)
	var paused: bool = bool(handoff.get("paused", not bool(handoff.get("playing", true))))
	if menu_bgm.has_method("set_music_paused"):
		menu_bgm.call("set_music_paused", paused)
	sync_from_music_session()
	return true

func apply_global_state(state: Dictionary, animate: bool = false) -> bool:
	if state.is_empty():
		return false
	var background_path: String = str(state.get("background", ""))
	if background_path.is_empty():
		return false
	var background_session: Node = _background_session()
	var texture: Texture2D = null
	if background_session != null and background_session.has_method("get_texture_for_path"):
		texture = background_session.call("get_texture_for_path", background_path) as Texture2D
	elif ResourceLoader.exists(background_path):
		var resource: Resource = ResourceLoader.load(background_path)
		if resource is Texture2D:
			texture = resource as Texture2D
	if texture == null:
		return false
	var changed: bool = current_background_path != background_path or menu_background.texture != texture
	current_background_path = background_path
	menu_background.texture = texture
	background_song.text = str(state.get("title", "SONG LIBRARY")).to_upper()
	background_artist.text = str(state.get("artist", ""))
	if changed and animate:
		animate_visit()
	return true

func _randomize_ambient_background(metadata: Dictionary = {}, animate: bool = false) -> bool:
	if background_randomization_suppressed:
		return apply_global_state(_global_background_state(), false)
	var background_session: Node = _background_session()
	if background_session == null or not background_session.has_method("randomize_background"):
		return false
	var path := str(background_session.call("randomize_background", "main_menu", true, metadata))
	if path.is_empty():
		return false
	return apply_global_state(background_session.call("get_state") as Dictionary, animate)

func animate_visit() -> void:
	if menu_background == null or host == null or not host.is_visible_in_tree():
		return
	# The route owns the reveal; transport/background updates must not add a
	# second fade or repeat-visit zoom (including on hidden resident screens).
	menu_background.modulate = Color.WHITE
	menu_background.scale = Vector2.ONE

func get_track_override() -> Dictionary:
	return track_override.duplicate(true)

func get_current_candidate() -> Dictionary:
	if current_background_index < 0 or current_background_index >= candidates.size():
		return {}
	return (candidates[current_background_index] as Dictionary).duplicate(true)

func get_current_background_path() -> String:
	return current_background_path

func get_current_background_index() -> int:
	return current_background_index

func _apply_background_audio(candidate: Dictionary, autoplay: bool = true) -> void:
	track_override.clear()
	var audio_path: String = str(candidate.get("audio", ""))
	if audio_path.is_empty() or menu_bgm == null or not menu_bgm.has_method("play_menu_track"):
		return
	var metadata: Dictionary = candidate.duplicate(true)
	metadata["source"] = "main_menu"
	var started: bool = bool(menu_bgm.call("play_menu_track", audio_path, 0.0, metadata, true, 0.24, true))
	if not started:
		return
	_refresh_now_playing()
	# play_menu_track() owns the complete fade-out -> stream swap -> fade-in
	# transaction. Calling start_menu_music() here killed MusicSession's active
	# volume tween before its _begin_track() callback could swap the stream, which
	# made Previous/Next look like they did nothing.

func _publish_candidate_selection(candidate: Dictionary) -> void:
	var selection_state: Node = _song_selection_state()
	if selection_state == null or not selection_state.has_method("set_selection"):
		return
	var audio_path: String = str(candidate.get("audio", ""))
	var song_id: String = audio_path.get_file().get_basename() if not audio_path.is_empty() else ""
	if song_id.is_empty():
		return
	var existing_difficulty: String = "normal"
	if selection_state.has_method("get_song_id") and str(selection_state.call("get_song_id")) == song_id and selection_state.has_method("get_difficulty_id"):
		existing_difficulty = str(selection_state.call("get_difficulty_id"))
		if existing_difficulty.is_empty():
			existing_difficulty = "normal"
	var metadata: Dictionary = candidate.duplicate(true)
	metadata["background"] = current_background_path
	metadata["source"] = "main_menu"
	selection_state.call("set_selection", song_id, existing_difficulty, metadata)

func _find_candidate_index_by_audio(audio_path: String) -> int:
	for index in range(candidates.size()):
		var candidate: Dictionary = candidates[index] as Dictionary
		if str(candidate.get("audio", "")) == audio_path:
			return index
	return -1

func _on_global_selection_changed(_state: Dictionary) -> void:
	_refresh_now_playing()

func _on_global_background_changed(state: Dictionary) -> void:
	apply_global_state(state, main_menu != null and main_menu.is_visible_in_tree())

func _song_selection_state() -> Node:
	return host.get_node_or_null("/root/SongSelectionState") if host != null else null

func _background_session() -> Node:
	return host.get_node_or_null("/root/BackgroundSession") if host != null else null

func _global_song_state() -> Dictionary:
	var selection_state: Node = _song_selection_state()
	if selection_state != null and selection_state.has_method("get_state"):
		var value: Variant = selection_state.call("get_state")
		if value is Dictionary:
			return (value as Dictionary).duplicate(true)
	return {}

func _global_background_state() -> Dictionary:
	var background_session: Node = _background_session()
	if background_session != null and background_session.has_method("get_state"):
		var value: Variant = background_session.call("get_state")
		if value is Dictionary:
			return (value as Dictionary).duplicate(true)
	return {}

func _refresh_now_playing() -> void:
	if refresh_now_playing.is_valid():
		refresh_now_playing.call()
