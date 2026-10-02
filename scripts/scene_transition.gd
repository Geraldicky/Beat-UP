extends CanvasLayer
class_name SceneTransitionManager

signal transition_started(status: String)
signal transition_progress(value: float)
signal transition_finished

@onready var transition_root: Control = %TransitionRoot
@onready var song_launch_visual: SongLaunchTransitionVisual = %SongLaunchVisual

var transitioning: bool = false
var transition_tween: Tween
var scene_cache: Dictionary = {}
var preload_requests: Dictionary = {}

# Menu scenes are warmed while the player is still looking at the current page.
# Gameplay launches use a separate visual-continuity handoff: resources can keep
# loading, but the player never sees a loading page, spinner, percentage, or bar.
const QUICK_PRELOAD_SCENES := [
	# v17.4.24: Main Menu, Song Library and gameplay are already resident under
	# AppShell. Only truly external destinations need a resource warm-up.
	"res://scenes/chart_editor.tscn",
	"res://scenes/app_shell.tscn",
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120
	visible = false
	transition_root.modulate.a = 1.0
	song_launch_visual.visible = false
	song_launch_visual.set_process(false)
	set_process(true)
	for raw_path in QUICK_PRELOAD_SCENES:
		preload_scene(str(raw_path))

# Transitions are atomic. A key pressed while the visual handoff owns the screen
# must not leak into the destination scene after a scene swap.
func _input(event: InputEvent) -> void:
	if not transitioning:
		return
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	for raw_path in preload_requests.keys():
		var scene_path: String = str(raw_path)
		var status: int = ResourceLoader.load_threaded_get_status(scene_path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var packed: PackedScene = ResourceLoader.load_threaded_get(scene_path) as PackedScene
			if packed != null:
				scene_cache[scene_path] = packed
			preload_requests.erase(scene_path)
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			preload_requests.erase(scene_path)

func preload_scene(scene_path: String) -> void:
	if scene_path.is_empty() or scene_cache.has(scene_path) or preload_requests.has(scene_path):
		return
	if not ResourceLoader.exists(scene_path, "PackedScene"):
		return
	var request_error: Error = ResourceLoader.load_threaded_request(scene_path, "PackedScene")
	if request_error == OK:
		preload_requests[scene_path] = true
	else:
		var packed: PackedScene = load(scene_path) as PackedScene
		if packed != null:
			scene_cache[scene_path] = packed

func is_scene_cached(scene_path: String) -> bool:
	return scene_cache.has(scene_path)

func change_scene(scene_path: String, _status: String = "") -> void:
	await change_scene_quick(scene_path)

# v17.4.23: gameplay loading is masked by visual continuity instead of a
# loading screen. The selected artwork becomes the handoff layer, the song
# information performs a short launch animation and then leaves, and resource
# work continues behind the artwork until gameplay is genuinely ready.
func change_scene_to_gameplay(scene_path: String, visual_payload: Dictionary) -> void:
	if transitioning:
		return
	transitioning = true
	visible = true
	_set_song_launch_mode(true)
	transition_root.modulate.a = 1.0
	song_launch_visual.configure(_resolve_global_song_visual_payload(visual_payload))
	transition_started.emit("GAMEPLAY HANDOFF")

	# Start the threaded request BEFORE the launch animation. This overlaps disk
	# work with motion instead of waiting for a cover animation to finish first.
	preload_scene(scene_path)
	await song_launch_visual.animate_cover()

	var packed_scene: PackedScene = await _get_scene_for_gameplay_handoff(scene_path)
	if packed_scene == null:
		await _cancel_song_handoff(scene_path)
		return

	var change_error: Error = get_tree().change_scene_to_packed(packed_scene)
	if change_error != OK:
		await _cancel_song_handoff(scene_path)
		return

	await get_tree().process_frame
	await get_tree().process_frame

	# main.tscn prepares the selected chart/audio behind the persistent artwork.
	# There is deliberately no visible progress state. If preparation takes a
	# little longer, the artwork simply remains as part of the launch animation.
	var readiness_deadline: float = _clock_seconds() + 10.0
	while _clock_seconds() < readiness_deadline:
		var current_scene: Node = get_tree().current_scene
		if current_scene != null and current_scene.has_method("is_gameplay_transition_ready"):
			if bool(current_scene.call("is_gameplay_transition_ready")):
				break
		await get_tree().process_frame

	song_launch_visual.set_progress(1.0)
	await song_launch_visual.animate_reveal()
	_finish_song_handoff()

func _resolve_global_song_visual_payload(payload: Dictionary) -> Dictionary:
	var resolved: Dictionary = payload.duplicate(true)
	var selection_state: Node = get_node_or_null("/root/SongSelectionState")
	if selection_state != null and selection_state.has_method("get_state"):
		var selection_value: Variant = selection_state.call("get_state")
		if selection_value is Dictionary:
			var selection: Dictionary = selection_value as Dictionary
			for key_name in ["title", "artist", "bpm", "difficulty", "star_rating"]:
				if not resolved.has(key_name) or str(resolved.get(key_name, "")).is_empty():
					resolved[key_name] = selection.get(key_name, resolved.get(key_name, ""))
	var background_session: Node = get_node_or_null("/root/BackgroundSession")
	if (not resolved.has("background") or str(resolved.get("background", "")).is_empty()) and background_session != null and background_session.has_method("get_background_path"):
		resolved["background"] = str(background_session.call("get_background_path"))
	return resolved

func transition_action_to_gameplay(action: Callable, visual_payload: Dictionary) -> void:
	if transitioning:
		return
	transitioning = true
	visible = true
	_set_song_launch_mode(true)
	transition_root.modulate.a = 1.0
	song_launch_visual.configure(_resolve_global_song_visual_payload(visual_payload))
	transition_started.emit("GAMEPLAY HANDOFF")
	await song_launch_visual.animate_cover()

	# Retry and in-main Song Select do not need a scene reload. The same visual
	# continuity layer stays alive while start_level() rebuilds chart/audio state.
	action.call()
	await get_tree().process_frame
	var readiness_deadline: float = _clock_seconds() + 6.0
	while _clock_seconds() < readiness_deadline:
		var current_scene: Node = get_tree().current_scene
		if current_scene == null or not current_scene.has_method("is_gameplay_transition_ready"):
			break
		if bool(current_scene.call("is_gameplay_transition_ready")):
			break
		await get_tree().process_frame

	song_launch_visual.set_progress(1.0)
	await song_launch_visual.animate_reveal()
	_finish_song_handoff()

func change_scene_quick(scene_path: String) -> void:
	if transitioning:
		return
	transitioning = true
	transition_started.emit("SEAMLESS MENU HANDOFF")

	# v17.4.23.1: menu navigation has no intermediary visual at all. Keep the
	# source page fully visible while the destination finishes loading in the
	# background, then swap scenes immediately. This removes the center ribbon /
	# diamond screen that still read as a loading page.
	var packed_scene: PackedScene = await _get_scene_for_quick_transition(scene_path)
	if packed_scene == null:
		_finish_seamless_menu_handoff()
		push_error("Could not load transition destination: %s" % scene_path)
		return

	var current_scene: Node = get_tree().current_scene
	if current_scene != null and not current_scene.scene_file_path.is_empty():
		preload_scene(current_scene.scene_file_path)

	var change_error: Error = get_tree().change_scene_to_packed(packed_scene)
	if change_error != OK:
		_finish_seamless_menu_handoff()
		push_error("Could not change transition destination: %s" % scene_path)
		return

	# Give the destination one frame to settle before input is restored. There is
	# deliberately no overlay, wipe, ribbon, spinner, or loading text here.
	await get_tree().process_frame
	_finish_seamless_menu_handoff()

func transition_action_quick(action: Callable) -> void:
	if transitioning:
		return
	transitioning = true
	transition_started.emit("SEAMLESS UI HANDOFF")
	action.call()
	await get_tree().process_frame
	_finish_seamless_menu_handoff()

func transition_action(action: Callable, _status: String = "", _detail: String = "") -> void:
	# Generic UI actions use the same overlay-free handoff. Heavy gameplay entry
	# continues to use the persistent song-artwork continuity layer instead.
	await transition_action_quick(action)

func is_transitioning() -> bool:
	return transitioning

func _get_scene_for_quick_transition(scene_path: String) -> PackedScene:
	if scene_cache.has(scene_path):
		return scene_cache[scene_path] as PackedScene
	if not preload_requests.has(scene_path):
		preload_scene(scene_path)
	if preload_requests.has(scene_path):
		while preload_requests.has(scene_path):
			var status: int = ResourceLoader.load_threaded_get_status(scene_path)
			match status:
				ResourceLoader.THREAD_LOAD_IN_PROGRESS:
					await get_tree().process_frame
				ResourceLoader.THREAD_LOAD_LOADED:
					var packed: PackedScene = ResourceLoader.load_threaded_get(scene_path) as PackedScene
					preload_requests.erase(scene_path)
					if packed != null:
						scene_cache[scene_path] = packed
						return packed
				ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
					preload_requests.erase(scene_path)
					return null
	if scene_cache.has(scene_path):
		return scene_cache[scene_path] as PackedScene
	return load(scene_path) as PackedScene

func _get_scene_for_gameplay_handoff(scene_path: String) -> PackedScene:
	if scene_cache.has(scene_path):
		song_launch_visual.set_progress(0.82)
		return scene_cache[scene_path] as PackedScene
	if not preload_requests.has(scene_path):
		preload_scene(scene_path)
	if not preload_requests.has(scene_path):
		var fallback: PackedScene = load(scene_path) as PackedScene
		song_launch_visual.set_progress(0.82 if fallback != null else 0.0)
		return fallback

	var load_progress: Array = []
	while preload_requests.has(scene_path):
		var status: int = ResourceLoader.load_threaded_get_status(scene_path, load_progress)
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				var resource_progress: float = float(load_progress[0]) if not load_progress.is_empty() else 0.0
				var mapped: float = lerpf(0.12, 0.82, resource_progress)
				song_launch_visual.set_progress(mapped)
				transition_progress.emit(mapped)
				await get_tree().process_frame
			ResourceLoader.THREAD_LOAD_LOADED:
				var packed: PackedScene = ResourceLoader.load_threaded_get(scene_path) as PackedScene
				preload_requests.erase(scene_path)
				if packed != null:
					scene_cache[scene_path] = packed
					song_launch_visual.set_progress(0.86)
					return packed
				return null
			ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				preload_requests.erase(scene_path)
				return null
	return scene_cache.get(scene_path, null) as PackedScene

func _finish_seamless_menu_handoff() -> void:
	# Quick/menu transitions must never expose the global transition layer.
	visible = false
	transitioning = false
	transition_finished.emit()

func _set_song_launch_mode(enabled: bool) -> void:
	song_launch_visual.visible = enabled
	song_launch_visual.set_process(enabled and visible)

func _cancel_song_handoff(scene_path: String) -> void:
	push_error("Could not prepare gameplay destination: %s" % scene_path)
	await song_launch_visual.animate_reveal()
	_finish_song_handoff()

func _finish_song_handoff() -> void:
	_set_song_launch_mode(false)
	visible = false
	transitioning = false
	transition_finished.emit()

func _clock_seconds() -> float:
	return float(Time.get_ticks_usec()) / 1000000.0
