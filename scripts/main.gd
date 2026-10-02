extends Control
signal best_stats_changed(store: Dictionary)

const ScoreIdentity = preload("res://scripts/score_identity.gd")
const ScorePolicy = preload("res://scripts/score_policy.gd")
const RuntimeResourceAccessScript = preload("res://scripts/runtime_resource_access.gd")

const GameplayConfigScript = preload("res://config/gameplay_config.gd")
const UserSettingsScript = preload("res://scripts/user_settings.gd")
const RhythmTimingScript = preload("res://scripts/rhythm_timing.gd")
const WavAutoAnalyzerScript = preload("res://scripts/wav_auto_analyzer.gd")
const ThemeConfigScript = preload("res://config/theme_config.gd")
const ResultConfigScript = preload("res://config/result_config.gd")
const LayoutConfigScript = preload("res://config/ui_layout_config.gd")
const MinimalThemeScript = preload("res://scripts/ui/minimal_theme.gd")
const ReliableJsonStoreScript = preload("res://scripts/reliable_json_store.gd")
const PlaytestTelemetryScript = preload("res://scripts/playtest_telemetry.gd")
const PracticeRecordsScript = preload("res://scripts/v18/practice_records.gd")

# Song-driven rhythm gameplay controller. Exact note timestamps live in JSON
# chart files; scene composition remains editable in the hierarchy.
@export_group("Configuration")
@export var gameplay_config: GameplayConfigScript
@export var theme_config: ThemeConfigScript
@export var result_config: ResultConfigScript
@export var ui_layout_config: LayoutConfigScript

@export_group("Timing / Debug")
@export_range(-150.0, 150.0, 1.0) var chart_sync_offset_ms := 0.0
@export var timing_debug_visible_on_start := false
@export var result_debug_shortcut_enabled := true
# Initial chart launch no longer uses a READY/3/2/1 gate. This duration is
# reserved for pause -> resume so the player can safely regain rhythm.
@export_range(1.0, 5.0, 0.25) var resume_countdown_duration := 3.0
@export_range(5.0, 30.0, 0.5) var skip_intro_threshold := 8.0
@export_range(1.0, 5.0, 0.25) var skip_intro_lead_time := 2.25

@export_group("Judgment Popup Animation")
@export_range(0.05, 2.0, 0.01) var judgment_display_duration := 0.42
@export_range(0.01, 1.0, 0.01) var judgment_fade_out_duration := 0.14
@export_range(0.0, 1.0, 0.01) var judgment_pop_in_duration := 0.06
@export var judgment_pop_start_scale := Vector2(0.94, 0.94)
@export_range(0.0, 80.0, 1.0) var judgment_enter_offset_y := 10.0
@export_range(-80.0, 0.0, 1.0) var judgment_exit_offset_y := -14.0


const DIRECTIONS := [
	{"number": 1, "key": KEY_KP_1, "symbol": "↙", "numpad": "1", "dx": -0.72, "dy": 0.72},
	{"number": 2, "key": KEY_KP_2, "symbol": "↓", "numpad": "2", "dx": 0.0, "dy": 1.0},
	{"number": 3, "key": KEY_KP_3, "symbol": "↘", "numpad": "3", "dx": 0.72, "dy": 0.72},
	{"number": 4, "key": KEY_KP_4, "symbol": "←", "numpad": "4", "dx": -1.0, "dy": 0.0},
	{"number": 6, "key": KEY_KP_6, "symbol": "→", "numpad": "6", "dx": 1.0, "dy": 0.0},
	{"number": 7, "key": KEY_KP_7, "symbol": "↖", "numpad": "7", "dx": -0.72, "dy": -0.72},
	{"number": 8, "key": KEY_KP_8, "symbol": "↑", "numpad": "8", "dx": 0.0, "dy": -1.0},
	{"number": 9, "key": KEY_KP_9, "symbol": "↗", "numpad": "9", "dx": 0.72, "dy": -0.72},
]

const FOUR_DIRECTIONS := [
	{"number": 4, "key": KEY_LEFT, "symbol": "←", "numpad": "←", "dx": -1.0, "dy": 0.0},
	{"number": 8, "key": KEY_UP, "symbol": "↑", "numpad": "↑", "dx": 0.0, "dy": -1.0},
	{"number": 6, "key": KEY_RIGHT, "symbol": "→", "numpad": "→", "dx": 1.0, "dy": 0.0},
	{"number": 2, "key": KEY_DOWN, "symbol": "↓", "numpad": "↓", "dx": 0.0, "dy": 1.0},
]

@onready var level_catalog: LevelCatalog = $LevelCatalog
@onready var background_rect: ColorRect = $Background
@onready var background_visual: Control = $Background/BattleBackground
@onready var battle_layer: Control = $Battle
@onready var hud_layer: Control = $HUD
@onready var feedback_layer: Control = $Feedback
@onready var chart_timeline: ChartTimeline = $Battle/ChartTimeline
@onready var track: RhythmTrack = $Battle/Track
@onready var battle_stats_panel: Panel = $HUD/BattleStatsPanel
@onready var score_caption: Label = $HUD/ScoreCaption
@onready var score_digits: ScoreDigits = $HUD/ScoreDigits
@onready var accuracy_caption: Label = $HUD/AccuracyCaption
@onready var accuracy_label: Label = $HUD/AccuracyLabel
@onready var combo_digits: ComboDigits = $HUD/ComboDigits
@onready var combo_label: Label = $HUD/ComboLabel
@onready var song_info_panel: Panel = $HUD/SongInfoPanel
@onready var song_title_label: Label = $HUD/SongInfoPanel/SongTitleLabel
@onready var bpm_label: Label = $HUD/SongInfoPanel/BPMLabel
@onready var difficulty_label: Label = $HUD/SongInfoPanel/DifficultyLabel
@onready var duration_label: Label = $HUD/SongInfoPanel/DurationLabel
@onready var duration_bar: ProgressBar = $HUD/SongInfoPanel/DurationBar
@onready var feedback_main: Label = $Feedback/Main
@onready var feedback_sub: Label = $Feedback/Sub
@onready var judgment_sprite: Label = $Feedback/JudgmentSprite
@onready var result_overlay: Control = $ResultOverlay
@onready var level_select: Control = $LevelSelect
@onready var music: AudioStreamPlayer = $Audio/Music
@onready var hit_sfx: AudioStreamPlayer = $Audio/HitSFX
@onready var miss_sfx: AudioStreamPlayer = $Audio/MissSFX
@onready var pause_button: Button = $HUD/PauseButton
@onready var skip_intro_button: Button = %SkipIntroButton
@onready var pause_overlay: Control = $PauseOverlay
@onready var timing_debug_label: Label = $HUD/TimingDebug
@onready var countdown_overlay: Control = %CountdownOverlay
@onready var countdown_stack: Control = $CountdownOverlay/Center/Stack
@onready var countdown_visual: GameplayCountdownVisual = %Visual
@onready var countdown_number: Label = %Number
@onready var countdown_status: Label = %Status
@onready var countdown_mode: Label = %Mode

const BEST_STATS_SAVE_PATH := "user://best_level_stats.json"
const RESULT_DEBUG_REQUEST_META := "numpad_blade_result_debug_requested"
const RETURN_TO_MENU_META := "beat_up_return_to_main_menu"
const PENDING_LIBRARY_LAUNCH_META := "beat_up_pending_library_launch"

enum PrimaryScreen {
	SONG_SELECT,
	GAMEPLAY,
	RESULT,
}

var levels: Array = []
var selected_song_id := ""
var best_stats_store: Dictionary = {}
const RunRecords = preload("res://scripts/run_records.gd")
const ScoreProcessor = preload("res://scripts/score_processor.gd")
var run_session = preload("res://scripts/gameplay_session.gd").new()
var level_data: Dictionary = {}
var current_level_index := -1
var stream_notes: Array = []
var current_note_index := 0
var space_events: Array[float] = []
var current_space_index := 0
var fight_time := 0.0
var combo := 0
var max_combo := 0
var score := 0
var total_hits := 0
var perfect_hits := 0
var great_hits := 0
var total_misses := 0
var reverse_hits := 0
var space_hits := 0
var space_perfects := 0
var space_misses := 0
var fight_over := true
var feedback_timer := 0.0
var judgment_timer := 0.0
var judgment_popup_tween: Tween
var judgment_rest_position := Vector2.ZERO
var arrow_rng := RandomNumberGenerator.new()
var last_runtime_direction := -1
var repeated_runtime_direction := 0
var game_paused := false
var random_mode_enabled := false
var deterministic_direction_cursor := 0
var deterministic_direction_seed := 0
var deterministic_direction_history: Array[int] = []
# v17.4.5.2: Runtime direction layouts are prepared once per chart start.
# 8K always reads the authored JSON direction; 4K always reads a deterministic
# projection cached from that authored layout. Switching modes can never mutate
# or re-author the source chart in memory.
var authored_direction_cache: Dictionary = {}
var four_key_layout_cache: Dictionary = {}
var runtime_chart_identity := ""
var legacy_direction_author := WavAutoAnalyzerScript.new()
var user_input_offset_ms := 0.0
var user_audio_offset_ms := 0.0
var input_style := "8_direction"
var run_input_binding_snapshot: Dictionary = {
	"input_style": UserSettingsScript.DEFAULT_INPUT_STYLE,
	"bindings": UserSettingsScript.DEFAULT_GAMEPLAY_BINDINGS.duplicate(true),
}
var timing_debug_visible := false
var last_raw_hit_delta_ms := 0.0
var last_compensated_hit_delta_ms := 0.0
var music_has_finished := false
var music_finished_clock_s := 0.0
var music_finished_song_time := 0.0
var gameplay_preparing := false
var gameplay_transition_ready := false
var gameplay_prepare_remaining := 0.0
var countdown_displayed_second := -1
var countdown_tween: Tween
var countdown_reveal_tween: Tween
var resume_countdown_active := false
var skip_intro_available := false
var skip_intro_target_s := 0.0
var first_playable_event_s := 0.0

# v18 gameplay session modes. Practice filters the selected chart to one musical
# section and loops it without touching normal records. Replay injects semantic
# actions captured from a previous run against the exact same chart/rules identity.
var effect_intensity: float = 0.75
var practice_mode_active: bool = false
var practice_section_index: int = -1
var practice_section: Dictionary = {}
var practice_start_s: float = 0.0
var practice_end_s: float = 0.0
var practice_loop_count: int = 0
var practice_lead_in_s: float = 1.5
var replay_requested_data: Dictionary = {}
var replay_playback_active: bool = false
var current_random_seed: int = 0

# v17.4.8 timing QA state. The AudioStreamPlayer remains authoritative; this
# state only prevents backwards mixer jitter and verifies pause/resume continuity.
var runtime_raw_music_time_s := 0.0
var runtime_audio_clock_initialized := false
var pause_raw_music_snapshot_s := 0.0
var pause_timing_snapshot_valid := false
var resume_timing_check_pending := false
var last_resume_clock_delta_ms := 0.0

# v17.4.14 local-only Beta playtest telemetry. Judgement events remain in
# memory during gameplay and are written only when the run ends or is aborted.
var playtest_telemetry = PlaytestTelemetryScript.new()
var auto_paused_for_focus_loss: bool = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_auto_pause_on_focus_loss()

func _auto_pause_on_focus_loss() -> void:
	if not is_inside_tree() or not is_node_ready() or not visible:
		return
	if fight_over or game_paused or gameplay_preparing or resume_countdown_active:
		return
	if level_select.visible or result_overlay.visible or pause_overlay.visible:
		return
	var navigation: Node = get_node_or_null("/root/NavigationController")
	if navigation != null and navigation.has_method("is_navigating") and bool(navigation.call("is_navigating")):
		return
	auto_paused_for_focus_loss = true
	_report_runtime("gameplay", "Auto-paused after application focus loss", {"song_id": selected_song_id, "fight_time": fight_time})
	show_pause_overlay()

func _ready() -> void:
	if gameplay_config == null:
		gameplay_config = GameplayConfigScript.new()
	if theme_config == null:
		theme_config = ThemeConfigScript.new()
	if result_config == null:
		result_config = ResultConfigScript.new()
	if ui_layout_config == null:
		ui_layout_config = LayoutConfigScript.new()

	MinimalThemeScript.apply_root(self)
	# Rhythm input should be delivered as soon as possible instead of waiting for
	# frame-level input accumulation.
	Input.use_accumulated_input = false
	_apply_theme_config()
	_apply_ui_layout()
	if not resized.is_connected(_apply_ui_layout):
		resized.connect(_apply_ui_layout)
	combo_digits.set_value(0)
	_reset_feedback_visuals()
	sync_battle_layout()
	levels = level_catalog.load_all(true)
	load_best_stats_store()
	_connect_song_select_signals()
	level_select.call("set_catalog", levels)
	level_select.call("set_best_stats_store", best_stats_store)
	music.finished.connect(_on_music_finished)
	pause_button.pressed.connect(show_pause_overlay)
	skip_intro_button.pressed.connect(_on_skip_intro_pressed)
	_connect_screen_signal(pause_overlay, "resume_requested", Callable(self, "resume_gameplay"))
	_connect_screen_signal(pause_overlay, "retry_requested", Callable(self, "retry_gameplay"))
	_connect_screen_signal(pause_overlay, "song_list_requested", Callable(self, "_transition_to_song_library"))
	_connect_screen_signal(pause_overlay, "background_opacity_changed", Callable(self, "apply_background_opacity"))
	_connect_screen_signal(pause_overlay, "timing_offsets_changed", Callable(self, "apply_timing_offsets"))
	_connect_screen_signal(result_overlay, "back_requested", Callable(self, "_on_result_back_pressed"))
	_connect_screen_signal(result_overlay, "replay_requested", Callable(self, "_on_result_replay_pressed"))
	pause_overlay.visible = false
	countdown_overlay.visible = false
	skip_intro_button.visible = false
	pause_button.visible = false
	timing_debug_visible = timing_debug_visible_on_start and _developer_shortcuts_available()
	timing_debug_label.visible = timing_debug_visible
	load_user_preferences()
	selected_song_id = str(level_select.call("get_selected_song_id"))
	var pending_library_launch: Dictionary = {}
	if get_tree().has_meta(PENDING_LIBRARY_LAUNCH_META):
		var pending_variant: Variant = get_tree().get_meta(PENDING_LIBRARY_LAUNCH_META)
		get_tree().remove_meta(PENDING_LIBRARY_LAUNCH_META)
		if pending_variant is Dictionary:
			pending_library_launch = pending_variant as Dictionary
	if pending_library_launch.is_empty():
		show_level_select()
	else:
		# The outer SceneTransition is still covering the screen while this scene
		# initializes. Start the requested chart on the next frame so audio/chart
		# preparation happens behind the persistent song-artwork handoff layer.
		_set_primary_screen(PrimaryScreen.GAMEPLAY)
		call_deferred("_launch_from_song_library", pending_library_launch)
	update_hud()
	if get_tree().has_meta(RESULT_DEBUG_REQUEST_META):
		get_tree().remove_meta(RESULT_DEBUG_REQUEST_META)
		call_deferred("show_result_debug_screen")

func prepare_launch_request(request: Dictionary, force_refresh: bool = true) -> Dictionary:
	var song_id: String = str(request.get("song_id", ""))
	var difficulty_id: String = str(request.get("difficulty_id", "normal")).to_lower()
	var resolution: Dictionary = level_catalog.resolve_playable(song_id, difficulty_id, force_refresh)
	if not bool(resolution.get("ok", false)):
		return resolution

	levels = level_catalog.load_all(false)
	var chart_value: Variant = resolution.get("chart", {})
	if not (chart_value is Dictionary):
		return {
			"ok": false,
			"error": "Resolved chart data is unavailable.",
			"song_id": song_id,
			"difficulty_id": difficulty_id,
		}
	var chart: Dictionary = (chart_value as Dictionary).duplicate(true)
	var loaded_stream: AudioStream = resolution.get("audio_stream") as AudioStream
	if loaded_stream == null:
		return {
			"ok": false,
			"error": "Audio could not be loaded. Re-import it in Chart Studio (OGG Vorbis required).",
			"song_id": song_id,
			"difficulty_id": difficulty_id,
			"source_path": str(resolution.get("source_path", "")),
		}

	var prepared_request: Dictionary = request.duplicate(true)
	prepared_request["song_id"] = str(resolution.get("song_id", song_id))
	prepared_request["difficulty_id"] = str(resolution.get("difficulty_id", difficulty_id))
	prepared_request["_resolved_chart"] = chart
	prepared_request["_resolved_audio_stream"] = loaded_stream
	prepared_request["_resolved_source_path"] = str(resolution.get("source_path", ""))
	prepared_request["_resolved_source_kind"] = str(resolution.get("source_kind", "other"))
	prepared_request["_resolved_source_hash"] = str(resolution.get("source_hash", chart.get("_source_chart_hash", "")))
	return {
		"ok": true,
		"request": prepared_request,
		"chart": chart.duplicate(true),
		"source_path": prepared_request["_resolved_source_path"],
		"source_kind": prepared_request["_resolved_source_kind"],
		"source_hash": prepared_request["_resolved_source_hash"],
	}

func _launch_from_song_library(request: Dictionary) -> bool:
	gameplay_transition_ready = false
	var prepared_request: Dictionary = request
	if not prepared_request.has("_resolved_chart") or not prepared_request.has("_resolved_audio_stream"):
		var preparation: Dictionary = prepare_launch_request(request, true)
		if not bool(preparation.get("ok", false)):
			push_error("Song Library launch failed: %s" % str(preparation.get("error", "Unknown chart error.")))
			show_level_select()
			gameplay_transition_ready = true
			return false
		prepared_request = preparation.get("request", {}) as Dictionary

	var chart_value: Variant = prepared_request.get("_resolved_chart", {})
	var loaded_stream: AudioStream = prepared_request.get("_resolved_audio_stream") as AudioStream
	if not (chart_value is Dictionary) or loaded_stream == null:
		gameplay_transition_ready = true
		return false
	var resolved_chart: Dictionary = (chart_value as Dictionary).duplicate(true)
	var song_id: String = str(prepared_request.get("song_id", ""))
	var difficulty_id: String = str(prepared_request.get("difficulty_id", "normal")).to_lower()
	random_mode_enabled = bool(prepared_request.get("random_mode", false))
	practice_section_index = int(prepared_request.get("practice_section_index", -1))
	practice_mode_active = practice_section_index >= 0
	practice_section.clear()
	practice_loop_count = 0
	replay_requested_data.clear()
	var replay_value: Variant = prepared_request.get("replay_data", {})
	if replay_value is Dictionary:
		replay_requested_data = (replay_value as Dictionary).duplicate(true)
	replay_playback_active = not replay_requested_data.is_empty()
	selected_song_id = song_id
	if not _start_resolved_level(resolved_chart, loaded_stream):
		gameplay_transition_ready = true
		return false
	_prepare_gameplay_entry_motion()
	# start_level has already loaded the chart, artwork and audio stream. The
	# shared artwork handoff can now dissolve directly into gameplay; playback
	# remains armed until that visual transition has completed.
	gameplay_transition_ready = true
	return true

func is_gameplay_transition_ready() -> bool:
	return gameplay_transition_ready

func launch_from_app_shell(request: Dictionary) -> bool:
	# AppShell keeps this gameplay controller alive for the whole process. Reuse
	# the same node for every run instead of reloading main.tscn.
	if get_tree().has_meta(PENDING_LIBRARY_LAUNCH_META):
		get_tree().remove_meta(PENDING_LIBRARY_LAUNCH_META)
	return _launch_from_song_library(request)


func _prepare_gameplay_entry_motion() -> void:
	# The song artwork is already visible in the global transition layer. Keep
	# lane/HUD out of the way until that artwork dissolves, then bring gameplay
	# UI in as one short motion phrase instead of a hard scene cut.
	battle_layer.modulate.a = 0.0
	hud_layer.modulate.a = 0.0
	feedback_layer.modulate.a = 0.0
	SceneTransition.transition_finished.connect(Callable(self, "_on_gameplay_entry_transition_finished"), CONNECT_ONE_SHOT)

func _on_gameplay_entry_transition_finished() -> void:
	if not is_inside_tree():
		return
	_begin_gameplay_playback()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(battle_layer, "modulate:a", 1.0, 0.20).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(hud_layer, "modulate:a", 1.0, 0.18).set_delay(0.035).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(feedback_layer, "modulate:a", 1.0, 0.16).set_delay(0.07).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _apply_theme_config() -> void:
	if theme_config == null:
		return
	background_rect.color = theme_config.base_dark
	# Song identity was already established by Song Launch. During play, keep only
	# the timing-critical HUD and a thin progress line.
	song_title_label.visible = false
	bpm_label.visible = false
	difficulty_label.visible = false
	duration_label.visible = false
	combo_label.add_theme_color_override("font_color", theme_config.text_primary)
	accuracy_caption.add_theme_color_override("font_color", theme_config.text_secondary)
	accuracy_label.add_theme_color_override("font_color", theme_config.text_primary)
	song_title_label.add_theme_color_override("font_color", theme_config.text_primary)
	bpm_label.add_theme_color_override("font_color", theme_config.text_secondary)
	difficulty_label.add_theme_color_override("font_color", theme_config.accent_primary)
	duration_label.add_theme_color_override("font_color", theme_config.text_secondary)
	MinimalThemeScript.apply_heading(song_title_label, 14, MinimalThemeScript.TEXT)
	feedback_main.add_theme_color_override("font_color", theme_config.text_primary)
	feedback_sub.add_theme_color_override("font_color", theme_config.text_secondary)
	judgment_sprite.add_theme_font_override("font", MinimalThemeScript.semibold_font())
	judgment_sprite.add_theme_font_size_override("font_size", 42)
	judgment_sprite.add_theme_color_override("font_outline_color", Color(0.02, 0.025, 0.04, 0.82))
	judgment_sprite.add_theme_constant_override("outline_size", 4)
	MinimalThemeScript.apply_mono(score_caption, 10, Color(MinimalThemeScript.MUTED, 0.84))
	MinimalThemeScript.apply_mono(score_digits, 36, MinimalThemeScript.TEXT)
	score_digits.refresh_style()
	MinimalThemeScript.apply_mono(accuracy_label, 16, Color(MinimalThemeScript.TEXT, 0.90))
	MinimalThemeScript.apply_numeric(combo_digits, 64, MinimalThemeScript.TEXT)
	MinimalThemeScript.apply_mono(combo_label, 10, Color(MinimalThemeScript.MUTED, 0.82))
	MinimalThemeScript.apply_mono(duration_label, 12, MinimalThemeScript.MUTED)
	MinimalThemeScript.apply_mono(bpm_label, 12, MinimalThemeScript.CYAN)
	MinimalThemeScript.apply_mono(difficulty_label, 12, MinimalThemeScript.PINK)
	countdown_number.add_theme_font_override("font", MinimalThemeScript.semibold_font())
	countdown_number.add_theme_color_override("font_outline_color", Color(0.01, 0.015, 0.025, 0.68))
	countdown_number.add_theme_constant_override("outline_size", 6)
	countdown_status.add_theme_font_override("font", MinimalThemeScript.mono_font())
	countdown_status.add_theme_color_override("font_color", Color(MinimalThemeScript.TEXT, 0.90))
	countdown_mode.add_theme_font_override("font", MinimalThemeScript.mono_font())
	countdown_mode.add_theme_color_override("font_color", Color(MinimalThemeScript.TEXT, 0.48))
	battle_stats_panel.add_theme_stylebox_override("panel", MinimalThemeScript.surface_s0(0.0))
	song_info_panel.add_theme_stylebox_override("panel", MinimalThemeScript.surface_s0(0.0))
	pause_button.add_theme_stylebox_override("normal", MinimalThemeScript.button_style(Color(MinimalThemeScript.SURFACE, 0.34), Color(MinimalThemeScript.BORDER, 0.20), MinimalThemeScript.RADIUS_SM))
	pause_button.add_theme_stylebox_override("hover", MinimalThemeScript.button_style(Color(MinimalThemeScript.SURFACE_RAISED, 0.70), MinimalThemeScript.ACCENT, MinimalThemeScript.RADIUS_SM))
	pause_button.add_theme_stylebox_override("pressed", MinimalThemeScript.button_style(Color(MinimalThemeScript.ACCENT, 0.10), MinimalThemeScript.ACCENT, MinimalThemeScript.RADIUS_SM))
	pause_button.add_theme_stylebox_override("focus", MinimalThemeScript.button_style(Color(MinimalThemeScript.SURFACE_RAISED, 0.70), MinimalThemeScript.TEXT, MinimalThemeScript.RADIUS_SM))
	skip_intro_button.add_theme_font_override("font", MinimalThemeScript.mono_font())
	skip_intro_button.add_theme_font_size_override("font_size", 12)
	skip_intro_button.add_theme_color_override("font_color", MinimalThemeScript.TEXT)
	skip_intro_button.add_theme_color_override("font_hover_color", MinimalThemeScript.CYAN)
	skip_intro_button.add_theme_color_override("font_pressed_color", MinimalThemeScript.CYAN)
	skip_intro_button.add_theme_stylebox_override("normal", MinimalThemeScript.panel_style(Color(MinimalThemeScript.SURFACE, 0.72), 6, Color(MinimalThemeScript.BORDER, 0.60), 1, 6.0))
	skip_intro_button.add_theme_stylebox_override("hover", MinimalThemeScript.panel_style(Color(MinimalThemeScript.SURFACE_RAISED, 0.92), 6, MinimalThemeScript.CYAN, 1, 6.0))
	skip_intro_button.add_theme_stylebox_override("pressed", MinimalThemeScript.panel_style(Color(MinimalThemeScript.CYAN, 0.14), 6, MinimalThemeScript.CYAN, 1, 6.0))
	skip_intro_button.add_theme_stylebox_override("focus", MinimalThemeScript.panel_style(Color(MinimalThemeScript.SURFACE, 0.82), 6, MinimalThemeScript.CYAN, 1, 6.0))

func _apply_ui_layout() -> void:
	if ui_layout_config == null or track == null or track.layout_config == null:
		return
	var viewport_size: Vector2 = size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var reference_scale: float = clampf(minf(viewport_size.x / 1920.0, viewport_size.y / 1080.0), 0.72, 1.15)
	var margin: float = clampf(float(ui_layout_config.hud_edge_margin) * reference_scale, 16.0, 28.0)
	var button_size: float = clampf(float(ui_layout_config.pause_button_size) * reference_scale, 44.0, 56.0)
	var hit_x: float = viewport_size.x * track.layout_config.hit_x_ratio
	var lane_y: float = viewport_size.y * track.layout_config.lane_y_ratio
	var lane_height: float = viewport_size.y * track.layout_config.lane_height_ratio
	var lane_bottom: float = lane_y + lane_height * 0.5
	var hit_radius: float = track.layout_config.hit_zone_size * 0.5
	var inner: float = clampf(float(ui_layout_config.battle_panel_inner_margin) * reference_scale, 8.0, 12.0)

	# v17.4.11 gameplay hierarchy: score owns the top-left corner, song context
	# stays centered in the remaining top rail, and Pause remains top-right.
	# These panels are deliberately compact so the per-song artwork can remain
	# visible without competing with the timing-critical lane.
	var stats_width: float = clampf(viewport_size.x * 0.165, 232.0, 316.0)
	# Keep the live score and accuracy in two genuinely separate rows.  The
	# previous compact height worked for short scores, but seven-digit v18.5
	# totals let the score glyphs descend into the accuracy row.
	var stats_height: float = clampf(104.0 * reference_scale, 96.0, 112.0)
	var stats_left: float = margin
	battle_stats_panel.position = Vector2(stats_left, margin)
	battle_stats_panel.size = Vector2(stats_width, stats_height)

	score_caption.position = battle_stats_panel.position + Vector2(inner, 7.0)
	score_caption.size = Vector2(maxf(1.0, stats_width - inner * 2.0), 18.0)
	score_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	score_digits.position = battle_stats_panel.position + Vector2(inner, 19.0)
	score_digits.size = Vector2(maxf(1.0, stats_width - inner * 2.0), 42.0)
	accuracy_caption.position = battle_stats_panel.position + Vector2(inner, stats_height - 27.0)
	accuracy_caption.size = Vector2(maxf(70.0, stats_width - inner * 2.0 - 92.0), 16.0)
	accuracy_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	accuracy_label.position = battle_stats_panel.position + Vector2(stats_width - inner - 92.0, stats_height - 30.0)
	accuracy_label.size = Vector2(92.0, 22.0)

	var song_left_bound: float = stats_left + stats_width + float(ui_layout_config.section_gap)
	var song_right_bound: float = viewport_size.x - margin - button_size - float(ui_layout_config.item_gap) - float(ui_layout_config.section_gap)
	var song_available: float = maxf(1.0, song_right_bound - song_left_bound)
	var desired_song_width: float = maxf(320.0, viewport_size.x * ui_layout_config.battle_song_info_width_ratio)
	var song_width: float = minf(desired_song_width, song_available)
	var song_left: float = song_left_bound + maxf(0.0, (song_available - song_width) * 0.5)
	song_info_label_layout(song_left, margin, song_width, float(ui_layout_config.battle_song_info_height))

	pause_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause_button.offset_left = -margin - button_size
	pause_button.offset_top = margin
	pause_button.offset_right = -margin
	pause_button.offset_bottom = margin + button_size

	var skip_width: float = clampf(viewport_size.x * 0.10, 126.0, 164.0)
	var skip_height: float = 34.0
	skip_intro_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip_intro_button.offset_left = -margin - skip_width
	skip_intro_button.offset_top = margin + button_size + 10.0
	skip_intro_button.offset_right = -margin
	skip_intro_button.offset_bottom = margin + button_size + 10.0 + skip_height

	# Combo and judgment live below the lane in distinct columns. This preserves
	# the quick left-to-right scan of taiko HUDs without copying their skin.
	var combo_width: float = maxf(160.0, hit_x - margin * 2.0)
	combo_digits.position = Vector2(margin, lane_bottom + 16.0)
	combo_digits.size = Vector2(combo_width, 64.0)
	combo_digits.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	combo_label.position = Vector2(margin + 4.0, lane_bottom + 76.0)
	combo_label.size = Vector2(combo_width - 4.0, 20.0)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	# Judgment feedback is centered above the receptor. Combo stays exclusively
	# in the lower-left HUD so the popup carries only timing information.
	var judgment_width: float = float(ui_layout_config.battle_judgment_width)
	var judgment_height: float = float(ui_layout_config.battle_judgment_height)
	var popup_gap: float = float(ui_layout_config.battle_feedback_gap)
	var popup_bottom: float = lane_y - hit_radius - popup_gap
	var judgment_left: float = hit_x - judgment_width * 0.5
	var judgment_top: float = popup_bottom - judgment_height
	judgment_sprite.position = Vector2(judgment_left, judgment_top)
	judgment_sprite.size = Vector2(judgment_width, judgment_height)
	judgment_sprite.pivot_offset = judgment_sprite.size * 0.5
	judgment_sprite.scale = Vector2.ONE * ui_layout_config.battle_judgment_scale
	judgment_rest_position = judgment_sprite.position
	feedback_main.position = Vector2(viewport_size.x * 0.5 - 220.0, lane_bottom + judgment_height + 38.0)
	feedback_main.size = Vector2(440.0, 28.0)
	feedback_sub.position = Vector2(viewport_size.x * 0.5 - 260.0, lane_bottom + judgment_height + 68.0)
	feedback_sub.size = Vector2(520.0, 26.0)

func song_info_label_layout(left: float, top: float, width: float, height: float) -> void:
	# Album Flow gameplay keeps only song progress. Song title/artist/difficulty
	# belong to Song Launch and Result, not the persistent timing HUD.
	var progress_width: float = clampf(width, 280.0, 680.0)
	var progress_left: float = left + maxf(0.0, (width - progress_width) * 0.5)
	song_info_panel.position = Vector2(progress_left, top + 2.0)
	song_info_panel.size = Vector2(progress_width, 10.0)
	duration_bar.position = Vector2(0.0, 3.0)
	duration_bar.size = Vector2(progress_width, 3.0)
	song_title_label.position = Vector2.ZERO
	song_title_label.size = Vector2.ZERO
	bpm_label.position = Vector2.ZERO
	bpm_label.size = Vector2.ZERO
	difficulty_label.position = Vector2.ZERO
	difficulty_label.size = Vector2.ZERO
	duration_label.position = Vector2.ZERO
	duration_label.size = Vector2.ZERO

func _connect_screen_signal(screen: Object, signal_name: StringName, callback: Callable) -> void:
	if screen == null or not screen.has_signal(signal_name):
		push_error("Screen is missing signal: %s" % signal_name)
		return
	if not screen.is_connected(signal_name, callback):
		screen.connect(signal_name, callback)

func open_chart_editor() -> void:
	playtest_telemetry.abort_session("chart_editor")
	music.stop()
	SceneTransition.change_scene_quick("res://scenes/chart_editor.tscn")

func _connect_song_select_signals() -> void:
	var signal_map: Dictionary = {
		"play_requested": Callable(self, "_on_song_select_play_requested"),
		"practice_requested": Callable(self, "_on_song_select_practice_requested"),
		"replay_requested": Callable(self, "_on_song_select_replay_requested"),
		"back_requested": Callable(self, "_on_song_select_back_requested"),
		"chart_editor_requested": Callable(self, "open_chart_editor"),
		"import_charts_requested": Callable(self, "_on_import_charts_requested"),
		"refresh_requested": Callable(self, "_on_song_select_refresh_requested"),
	}
	for signal_name in signal_map.keys():
		var callback: Callable = signal_map[signal_name]
		if not level_select.has_signal(signal_name):
			push_error("SongSelect scene is missing signal: %s" % signal_name)
			continue
		if not level_select.is_connected(signal_name, callback):
			level_select.connect(signal_name, callback)

func sync_battle_layout() -> void:
	track.apply_layout()

func load_user_preferences() -> void:
	var master_value: float = UserSettingsScript.get_master_volume()
	var bg_value: float = UserSettingsScript.get_background_opacity()
	user_input_offset_ms = UserSettingsScript.get_input_offset_ms()
	user_audio_offset_ms = UserSettingsScript.get_audio_offset_ms()
	input_style = UserSettingsScript.get_input_style()
	effect_intensity = UserSettingsScript.get_effect_intensity() / 100.0
	UserSettingsScript.apply_master_volume(master_value)
	apply_background_opacity(bg_value)
	track.set_input_style(input_style)
	if track.has_method("set_effect_intensity_percent"):
		track.call("set_effect_intensity_percent", UserSettingsScript.get_effect_intensity())

func apply_timing_offsets(input_offset_ms: float, audio_offset_ms: float) -> void:
	user_input_offset_ms = RhythmTimingScript.clamp_offset_ms(input_offset_ms)
	user_audio_offset_ms = RhythmTimingScript.clamp_offset_ms(audio_offset_ms)
	update_timing_debug()

func apply_background_opacity(value: float) -> void:
	# Song artwork is blended directly over the game's base-dark colour. This
	# behaves as both opacity and dim control without adding a permanent black
	# overlay over the gameplay background.
	background_visual.modulate.a = clampf(value, 0.0, 100.0) / 100.0

func _apply_song_background_for_level(data: Dictionary) -> void:
	if background_visual == null or not background_visual.has_method("set_song_background"):
		return
	var background_path: String = str(data.get("background", ""))
	var song_id: String = str(data.get("song_id", data.get("id", "")))
	var loaded: bool = bool(background_visual.call("set_song_background", background_path, song_id))
	if not loaded and not background_path.is_empty():
		push_warning("Beat UP! gameplay background could not be loaded: %s" % background_path)
	apply_background_opacity(UserSettingsScript.get_background_opacity())

func show_pause_overlay() -> void:
	if SceneTransition.is_transitioning():
		return
	if level_select.visible or fight_over or result_overlay.visible:
		return
	_capture_pause_timing_snapshot()
	playtest_telemetry.record_pause()
	game_paused = true
	if skip_intro_button != null:
		skip_intro_button.visible = false
	pause_overlay.visible = true
	pause_overlay.z_index = 90
	pause_overlay.call("show_menu")
	pause_button.visible = false
	if music != null:
		music.stream_paused = true
	background_visual.set_process(false)

func resume_gameplay() -> void:
	auto_paused_for_focus_loss = false
	if not game_paused or fight_over:
		return
	pause_overlay.visible = false
	pause_button.visible = false
	# Unlike initial song launch, resume keeps a short 3/2/1 safety countdown so
	# hands can return to the controls without losing timing context.
	_start_resume_countdown()

func retry_gameplay() -> void:
	if SceneTransition.is_transitioning():
		return
	if _current_chart_identity().is_empty():
		return
	playtest_telemetry.abort_session("retry")
	var replay: Node = get_node_or_null("/root/ReplayManager")
	if replay != null:
		replay.call("abort_recording")
		replay.call("stop_playback")
	_reset_runtime_timing_state()
	game_paused = false
	if music != null:
		music.stream_paused = false
		music.stop()
	_transition_to_current_chart("RESTARTING CHART")

func exit_to_startup() -> void:
	game_paused = false
	if music != null:
		music.stop()
	_return_to_startup_menu()

func prepare_for_shell_exit(reason: String) -> void:
	auto_paused_for_focus_loss = false
	playtest_telemetry.abort_session(reason)
	var replay: Node = get_node_or_null("/root/ReplayManager")
	if replay != null:
		replay.call("abort_recording")
		replay.call("stop_playback")
	game_paused = false
	_cancel_gameplay_countdown()
	music_has_finished = false
	if music != null:
		music.stream_paused = false
		music.stop()
	background_visual.set_process(false)

func reset_after_shell_exit() -> void:
	# Compatibility entry point. Persistent-shell builds use the async version so
	# hidden gameplay cleanup can never hitch the visible Song Library.
	call_deferred("reset_after_shell_exit_async")

func reset_after_shell_exit_async() -> void:
	# v17.4.24.1: do NOT call show_level_select() here. That legacy path reloads
	# all charts and rebuilds a second SongSelect tree inside hidden gameplay,
	# causing the visible Song Library to freeze halfway through its reveal.
	fight_over = true
	game_paused = false
	_cancel_gameplay_countdown()
	music_has_finished = false
	if music != null:
		music.stream_paused = false
		music.stop()
	authored_direction_cache.clear()
	four_key_layout_cache.clear()
	runtime_chart_identity = ""
	chart_timeline.clear()
	stream_notes.clear()
	current_note_index = 0
	space_events.clear()
	current_space_index = 0
	_reset_feedback_visuals()
	# Detaching hundreds of note nodes is the only potentially heavy cleanup that
	# still remains. Slice it across frames while GameplayScreen is invisible.
	if track != null and track.has_method("clear_notes_batched"):
		await track.clear_notes_batched(96)
	elif track != null:
		track.clear_notes()

func show_level_select() -> void:
	playtest_telemetry.abort_session("song_library")
	fight_over = true
	game_paused = false
	_cancel_gameplay_countdown()
	music_has_finished = false
	if music != null:
		music.stream_paused = false
		music.stop()
	authored_direction_cache.clear()
	four_key_layout_cache.clear()
	runtime_chart_identity = ""
	track.clear_notes()
	chart_timeline.clear()
	stream_notes.clear()
	current_note_index = 0
	space_events.clear()
	current_space_index = 0
	_set_primary_screen(PrimaryScreen.SONG_SELECT)
	if music != null:
		music.stream_paused = false
	background_visual.set_process(true)
	_reset_feedback_visuals()
	levels = level_catalog.load_all(true)
	level_select.call("set_catalog", levels)
	level_select.call("set_best_stats_store", best_stats_store)
	if not selected_song_id.is_empty():
		level_select.call("set_selected_song", selected_song_id)
	level_select.call("set_random_mode", random_mode_enabled)
	selected_song_id = str(level_select.call("get_selected_song_id"))
	if level_select.has_method("focus_current_selection"):
		level_select.call_deferred("focus_current_selection")
	update_hud()

func _on_song_select_play_requested(song_id: String, difficulty_id: String, random_mode: bool) -> void:
	practice_mode_active = false
	practice_section_index = -1
	replay_requested_data.clear()
	replay_playback_active = false
	selected_song_id = song_id
	random_mode_enabled = random_mode
	# Input style can now be changed from the Song Library MODS panel, so refresh
	# it immediately before entering gameplay instead of relying on startup state.
	input_style = UserSettingsScript.get_input_style()
	track.set_input_style(input_style)
	var level_index: int = find_level_index(song_id, difficulty_id)
	if level_index >= 0:
		_transition_to_level(level_index)

func _on_song_select_practice_requested(song_id: String, difficulty_id: String, random_mode: bool, section_index: int) -> void:
	practice_mode_active = true
	practice_section_index = section_index
	replay_requested_data.clear()
	replay_playback_active = false
	selected_song_id = song_id
	random_mode_enabled = random_mode
	input_style = UserSettingsScript.get_input_style()
	track.set_input_style(input_style)
	var level_index: int = find_level_index(song_id, difficulty_id)
	if level_index >= 0:
		_transition_to_level(level_index, "PREPARING PRACTICE")

func _on_song_select_replay_requested(song_id: String, difficulty_id: String, random_mode: bool, replay_data: Dictionary) -> void:
	practice_mode_active = false
	practice_section_index = -1
	replay_requested_data = replay_data.duplicate(true)
	replay_playback_active = not replay_requested_data.is_empty()
	selected_song_id = song_id
	random_mode_enabled = random_mode
	input_style = UserSettingsScript.get_input_style()
	track.set_input_style(input_style)
	var level_index: int = find_level_index(song_id, difficulty_id)
	if level_index >= 0:
		_transition_to_level(level_index, "PREPARING REPLAY")

func _on_song_select_back_requested() -> void:
	_return_to_startup_menu()

func _return_to_startup_menu() -> void:
	if SceneTransition.is_transitioning():
		return
	playtest_telemetry.abort_session("main_menu")
	game_paused = false
	_cancel_gameplay_countdown()
	if music != null:
		music.stream_paused = false
		music.stop()
	get_tree().set_meta(RETURN_TO_MENU_META, true)
	get_tree().set_meta("beat_up_return_main_menu_focus", 0)
	var navigation: Node = get_node_or_null("/root/NavigationController")
	if navigation != null and navigation.has_method("request_main_menu"):
		navigation.call("request_main_menu", 0)
		return
	prepare_for_shell_exit("main_menu")
	SceneTransition.change_scene_quick("res://scenes/app_shell.tscn")

func _transition_to_level(level_index: int, _status: String = "PREPARING CHART") -> void:
	if SceneTransition.is_transitioning():
		return
	if level_index < 0 or level_index >= levels.size():
		return
	var raw_level: Variant = levels[level_index]
	if not (raw_level is Dictionary):
		return
	var selected_level: Dictionary = raw_level as Dictionary
	_transition_to_identity(
		str(selected_level.get("song_id", selected_level.get("id", ""))),
		str(selected_level.get("chart_difficulty", selected_level.get("difficulty", "normal"))).to_lower(),
		_status
	)

func _transition_to_identity(song_id: String, difficulty_id: String, _status: String = "PREPARING CHART") -> void:
	if SceneTransition.is_transitioning():
		return
	var preparation: Dictionary = prepare_launch_request({
		"song_id": song_id,
		"difficulty_id": difficulty_id,
		"random_mode": random_mode_enabled,
	}, true)
	_transition_to_prepared_request(preparation)

func _transition_to_prepared_request(preparation: Dictionary) -> void:
	if not bool(preparation.get("ok", false)):
		push_warning("Cannot play: %s" % str(preparation.get("error", "Chart resolution failed.")))
		if level_select.visible and level_select.has_method("show_playback_error"):
			level_select.call("show_playback_error", str(preparation.get("error", "CHART COULD NOT BE LOADED")))
		return
	var prepared_request: Dictionary = preparation.get("request", {}) as Dictionary
	var chart: Dictionary = preparation.get("chart", {}) as Dictionary
	var visual_payload: Dictionary = _build_gameplay_launch_payload_from_chart(chart)
	SceneTransition.transition_action_to_gameplay(
		_start_level_with_launch_motion.bind(prepared_request),
		visual_payload
	)

func _current_chart_identity() -> Dictionary:
	var song_id: String = str(level_data.get("song_id", level_data.get("id", selected_song_id)))
	var difficulty_id: String = str(level_data.get("chart_difficulty", level_data.get("difficulty", "normal"))).to_lower()
	if song_id.is_empty() or difficulty_id.is_empty():
		return {}
	return {"song_id": song_id, "difficulty_id": difficulty_id}

func prepare_retry_request(force_refresh: bool = true) -> Dictionary:
	var identity: Dictionary = _current_chart_identity()
	if identity.is_empty():
		return {"ok": false, "error": "No active chart identity is available."}
	return prepare_launch_request({
		"song_id": str(identity.get("song_id", "")),
		"difficulty_id": str(identity.get("difficulty_id", "normal")),
		"random_mode": random_mode_enabled,
	}, force_refresh)

func _transition_to_current_chart(_status: String = "RESTARTING CHART") -> void:
	if SceneTransition.is_transitioning():
		return
	# Retry resolves from the active chart identity and refreshes the catalog; it
	# never trusts current_level_index, which may have shifted after an edit.
	var preparation: Dictionary = prepare_retry_request(true)
	_transition_to_prepared_request(preparation)

func _start_level_with_launch_motion(prepared_request: Dictionary) -> void:
	var chart: Dictionary = prepared_request.get("_resolved_chart", {}) as Dictionary
	var loaded_stream: AudioStream = prepared_request.get("_resolved_audio_stream") as AudioStream
	_start_resolved_level(chart, loaded_stream)
	# If start_level failed it returns to Song Select. Do not fade gameplay layers
	# in over the error state. On a valid launch, match the first-launch choreography.
	if not level_select.visible:
		_prepare_gameplay_entry_motion()

func _build_gameplay_launch_payload(level_index: int) -> Dictionary:
	if level_index < 0 or level_index >= levels.size():
		return {}
	var raw_level: Variant = levels[level_index]
	if not (raw_level is Dictionary):
		return {}
	return _build_gameplay_launch_payload_from_chart(raw_level as Dictionary)

func _build_gameplay_launch_payload_from_chart(launch_level: Dictionary) -> Dictionary:
	var difficulty_text: String = str(launch_level.get("difficulty", launch_level.get("chart_difficulty", "NORMAL"))).to_upper()
	return {
		"title": str(launch_level.get("title", launch_level.get("song_id", "UNTITLED"))),
		"artist": str(launch_level.get("artist", "Unknown Artist")),
		"difficulty": difficulty_text,
		"bpm": float(launch_level.get("bpm", 0.0)),
		"star_rating": int(launch_level.get("star_rating", 0)),
		"background": str(launch_level.get("background", "")),
		"random_mode": random_mode_enabled,
	}

func _transition_to_song_library() -> void:
	if SceneTransition.is_transitioning():
		return
	var navigation: Node = get_node_or_null("/root/NavigationController")
	if navigation != null and navigation.has_method("request_song_library"):
		navigation.call("request_song_library", selected_song_id, false)
		return
	prepare_for_shell_exit("song_library")
	SceneTransition.transition_action_quick(show_level_select)

func _on_song_select_refresh_requested() -> void:
	levels = level_catalog.load_all(true)
	level_select.call("set_catalog", levels)
	level_select.call("set_best_stats_store", best_stats_store)

func _on_import_charts_requested(paths: PackedStringArray) -> void:
	var report: Dictionary = level_catalog.import_chart_files(paths)
	levels = level_catalog.load_all(true)
	level_select.call("set_catalog", levels)
	level_select.call("set_best_stats_store", best_stats_store)
	var imported_ids: Array = report.get("song_ids", [])
	if not imported_ids.is_empty():
		selected_song_id = str(imported_ids[0])
		level_select.call("set_selected_song", selected_song_id)
	if level_select.has_method("show_creator_status"):
		var imported_count: int = int(report.get("imported", 0))
		var failures: Array = report.get("failed", []) as Array
		var summary := "IMPORTED %d/%d CHARTS OR PACKS" % [imported_count, paths.size()]
		if not failures.is_empty():
			summary += " · %s" % "; ".join(failures)
		level_select.call("show_creator_status", summary, imported_count <= 0)

func load_best_stats_store() -> void:
	best_stats_store.clear()
	var load_result: Dictionary = ReliableJsonStoreScript.load_dictionary(BEST_STATS_SAVE_PATH)
	var loaded_data: Variant = load_result.get("data", {})
	if loaded_data is Dictionary:
		best_stats_store = loaded_data as Dictionary
	var migrated := ScoreIdentity.migrate_legacy(best_stats_store)
	migrated = ScoreIdentity.migrate_v185_score_scale(best_stats_store, levels, gameplay_config, result_config) or migrated
	if migrated:
		save_best_stats_store()

func _migrate_best_stats_accuracy_v168() -> bool:
	var changed := false
	for key: Variant in best_stats_store.keys():
		var raw: Variant = best_stats_store.get(key, {})
		if not (raw is Dictionary):
			continue
		var entry: Dictionary = raw as Dictionary
		if str(entry.get("accuracy_model", "")) == "weighted_v168":
			continue
		var perfect := int(entry.get("perfect", 0))
		var great := int(entry.get("great", 0))
		var good := int(entry.get("good", 0))
		var miss := int(entry.get("miss", 0))
		if perfect + great + good + miss <= 0:
			continue
		var migrated_accuracy := calculate_accuracy_from_counts(perfect, great, good, miss)
		entry["accuracy"] = migrated_accuracy
		entry["rank"] = get_accuracy_rank(migrated_accuracy)
		entry["accuracy_model"] = "weighted_v168"
		best_stats_store[key] = entry
		changed = true
	return changed

func _migrate_progression_v171() -> bool:
	var changed := false
	for key: Variant in best_stats_store.keys():
		var raw: Variant = best_stats_store.get(key, {})
		if not (raw is Dictionary):
			continue
		var entry: Dictionary = raw as Dictionary
		var entry_changed := false
		if not entry.has("cleared"):
			entry["cleared"] = int(entry.get("plays", 0)) > 0
			entry_changed = true
		# Legacy records did not persist SPACE misses. Do not
		# fabricate a Full Combo from incomplete information; the flag becomes
		# authoritative after the first v17.1 clear.
		if not entry.has("full_combo"):
			entry["full_combo"] = false
			entry_changed = true
		if not entry.has("best_accuracy"):
			entry["best_accuracy"] = float(entry.get("accuracy", 0.0))
			entry_changed = true
		if not entry.has("best_rank"):
			entry["best_rank"] = get_accuracy_rank(float(entry.get("best_accuracy", entry.get("accuracy", 0.0))))
			entry_changed = true
		if not entry.has("best_max_combo"):
			entry["best_max_combo"] = int(entry.get("max_combo", 0))
			entry_changed = true
		if not entry.has("progression_model"):
			entry["progression_model"] = "v171"
			entry_changed = true
		if entry_changed:
			best_stats_store[key] = entry
			changed = true
	return changed

func save_best_stats_store() -> void:
	if not ReliableJsonStoreScript.save_dictionary_atomic(BEST_STATS_SAVE_PATH, best_stats_store):
		push_error("Beat UP! progression: failed to persist best-level stats safely.")

func commit_best_stats(accuracy: float) -> bool:
	if run_session.committed:
		return false
	var song_id: String = str(level_data.get("song_id", level_data.get("id", "")))
	if song_id.is_empty(): return false
	if run_session.run_id.is_empty(): run_session.begin()
	var key: String = ScoreIdentity.key(level_data, input_style, random_mode_enabled)
	var previous: Dictionary = best_stats_store.get(key, {})
	run_session.previous_best = previous.duplicate(true)
	var run: Dictionary = _build_result_snapshot(accuracy, false)
	run["run_id"] = run_session.run_id
	run["telemetry_session_id"] = playtest_telemetry.get_active_session_id()
	run["completed_at"] = Time.get_unix_time_from_system()
	run["identity"] = ScoreIdentity.identity(level_data, input_style, random_mode_enabled)
	run["record_scope"] = "mode_chart_rules"
	run["run_full_combo"] = _expected_note_count() + _expected_space_count() > 0 and total_misses == 0 and space_misses == 0
	var merged: Dictionary = RunRecords.merge(previous, run)
	var entry: Dictionary = merged.entry
	entry["best_rank"] = get_accuracy_rank(float(entry.best_accuracy))
	best_stats_store[key] = entry
	if not ReliableJsonStoreScript.save_dictionary_atomic(BEST_STATS_SAVE_PATH, best_stats_store):
		if previous.is_empty(): best_stats_store.erase(key)
		else: best_stats_store[key] = previous
		run_session.save_error = true
		return false
	run_session.save_error = false
	run_session.committed = true
	best_stats_changed.emit(best_stats_store)
	level_select.call("set_best_stats_store", best_stats_store)
	return bool(merged.better)

func get_accuracy_rank(accuracy: float) -> String:
	return ScoreProcessor.rank_for_accuracy(accuracy, result_config)

func get_good_hits() -> int:
	return maxi(0, total_hits - perfect_hits - great_hits)

func calculate_accuracy() -> float:
	return calculate_accuracy_from_counts(perfect_hits, great_hits, get_good_hits(), total_misses)

func calculate_accuracy_from_counts(perfect: int, great: int, good: int, miss: int) -> float:
	return ScoreProcessor.accuracy(perfect, great, good, miss, result_config)

func get_song_representative(song_id: String) -> Dictionary:
	if song_id.is_empty():
		return {}
	for raw_level: Variant in levels:
		if not (raw_level is Dictionary):
			continue
		var data: Dictionary = raw_level
		var candidate_id: String = str(data.get("song_id", data.get("id", "")))
		if candidate_id == song_id:
			return data
	return {}

func find_level_index(song_id: String, difficulty_id: String) -> int:
	for i in range(levels.size()):
		var raw_level: Variant = levels[i]
		if not (raw_level is Dictionary):
			continue
		var data: Dictionary = raw_level
		if str(data.get("song_id", data.get("id", ""))) == song_id and str(data.get("chart_difficulty", data.get("difficulty", ""))).to_lower() == difficulty_id.to_lower():
			return i
	return -1

func start_selected_difficulty(difficulty_id: String) -> void:
	var level_index: int = find_level_index(selected_song_id, difficulty_id)
	if level_index >= 0:
		start_level(level_index)

func start_level(index: int) -> bool:
	if index < 0 or index >= levels.size():
		return false
	var raw_level: Variant = levels[index]
	if not (raw_level is Dictionary):
		return false
	var selected_level: Dictionary = raw_level as Dictionary
	var preparation: Dictionary = prepare_launch_request({
		"song_id": str(selected_level.get("song_id", selected_level.get("id", ""))),
		"difficulty_id": str(selected_level.get("chart_difficulty", selected_level.get("difficulty", "normal"))).to_lower(),
		"random_mode": random_mode_enabled,
	}, true)
	if not bool(preparation.get("ok", false)):
		push_warning("Cannot play: chart invalid or audio missing. Install the matching Audio Pack.")
		return false
	var prepared_request: Dictionary = preparation.get("request", {}) as Dictionary
	return _start_resolved_level(
		prepared_request.get("_resolved_chart", {}) as Dictionary,
		prepared_request.get("_resolved_audio_stream") as AudioStream
	)

func _start_resolved_level(launch_chart: Dictionary, loaded_stream: AudioStream) -> bool:
	if launch_chart.is_empty() or loaded_stream == null:
		return false
	if not RuntimeResourceAccessScript.audio_exists(str(launch_chart.get("audio", ""))) or not bool(preload("res://scripts/chart_integrity.gd").validate_structure(launch_chart).get("ok", false)):
		return false
	_capture_run_input_binding_snapshot()
	run_session.begin()
	game_paused = false
	if music != null:
		music.stream_paused = false
	selected_song_id = str(launch_chart.get("song_id", launch_chart.get("id", selected_song_id)))
	var launch_difficulty_id: String = str(launch_chart.get("chart_difficulty", launch_chart.get("difficulty", "normal"))).to_lower()
	current_level_index = find_level_index(selected_song_id, launch_difficulty_id)
	# The catalog winner is immutable source data for this run. All legacy
	# direction authoring, RANDOM state and 4K projection happen on this deep copy.
	level_data = launch_chart.duplicate(true)
	replay_playback_active = (not practice_mode_active) and (not replay_requested_data.is_empty())
	if not level_data.has("_source_chart_hash"):
		level_data["_source_chart_hash"] = ScoreIdentity.chart_hash(level_data)
	level_data["_rules_hash"] = ScoreIdentity.rules_hash(gameplay_config, result_config)
	# Old/imported charts may predate authored directions. Upgrade the full chart
	# once, using the same music-aware v15 choreography as newly generated charts,
	# so gameplay never falls back to a visible 8-key arithmetic loop.
	level_data = legacy_direction_author.author_legacy_directions(level_data)
	_configure_v18_session_mode()
	var chart_events: Variant = level_data.get("events", [])
	if not (chart_events is Array):
		push_error("Level has no events array")
		return false
	_prepare_runtime_direction_layouts(chart_events as Array)

	sync_battle_layout()
	track.clear_notes()
	var raw_space_events: Variant = level_data.get("space_events", [])
	if not (raw_space_events is Array):
		raw_space_events = []
	chart_timeline.load_events(chart_events as Array)
	space_events = load_space_events(raw_space_events as Array)
	stream_notes.clear()
	current_note_index = 0
	current_space_index = 0
	fight_time = 0.0
	_reset_runtime_timing_state()
	music_has_finished = false
	music_finished_clock_s = 0.0
	music_finished_song_time = 0.0
	combo = 0
	max_combo = 0
	score = 0
	score_digits.reset_value(0)
	total_hits = 0
	perfect_hits = 0
	great_hits = 0
	total_misses = 0
	reverse_hits = 0
	space_hits = 0
	space_perfects = 0
	space_misses = 0
	fight_over = false
	_cancel_gameplay_countdown()
	_reset_feedback_visuals()
	current_random_seed = 0
	if random_mode_enabled:
		if replay_playback_active:
			current_random_seed = int(replay_requested_data.get("random_seed", 0))
		if current_random_seed == 0:
			current_random_seed = int(Time.get_ticks_usec() & 0x7fffffff)
		arrow_rng.seed = current_random_seed
	_reset_runtime_direction_state()
	_apply_song_background_for_level(level_data)
	_set_primary_screen(PrimaryScreen.GAMEPLAY)
	if music != null:
		music.stream_paused = false
	background_visual.set_process(true)

	music.stream = loaded_stream
	_begin_v18_replay_session()
	if not practice_mode_active and not replay_playback_active:
		_begin_playtest_session()
	_arm_gameplay_start()
	update_hud()
	return true

func _configure_v18_session_mode() -> void:
	practice_section.clear()
	practice_start_s = 0.0
	practice_end_s = 0.0
	if not practice_mode_active:
		return
	var sections_value: Variant = level_data.get("sections", [])
	if not (sections_value is Array):
		practice_mode_active = false
		practice_section_index = -1
		return
	var sections: Array = sections_value as Array
	if practice_section_index < 0 or practice_section_index >= sections.size() or not (sections[practice_section_index] is Dictionary):
		practice_mode_active = false
		practice_section_index = -1
		return
	practice_section = (sections[practice_section_index] as Dictionary).duplicate(true)
	practice_start_s = maxf(0.0, float(practice_section.get("start", 0.0)))
	practice_end_s = maxf(practice_start_s + 1.0, float(practice_section.get("end", practice_start_s + 1.0)))
	var filtered_events: Array = []
	var events_value: Variant = level_data.get("events", [])
	if events_value is Array:
		for raw_event: Variant in events_value as Array:
			if not (raw_event is Dictionary):
				continue
			var event: Dictionary = raw_event as Dictionary
			var event_time: float = float(event.get("time", 0.0))
			if event_time >= practice_start_s and event_time <= practice_end_s:
				filtered_events.append(event.duplicate(true))
	level_data["events"] = filtered_events
	var filtered_space: Array = []
	var space_value: Variant = level_data.get("space_events", [])
	if space_value is Array:
		for raw_space: Variant in space_value as Array:
			var space_time: float = -1.0
			if raw_space is int or raw_space is float:
				space_time = float(raw_space)
			elif raw_space is Dictionary:
				space_time = float((raw_space as Dictionary).get("time", -1.0))
			if space_time >= practice_start_s and space_time <= practice_end_s:
				filtered_space.append(space_time)
	level_data["space_events"] = filtered_space

func _begin_v18_replay_session() -> void:
	var replay: Node = get_node_or_null("/root/ReplayManager")
	if replay == null:
		replay_playback_active = false
		return
	if practice_mode_active:
		replay.call("abort_recording")
		replay.call("stop_playback")
		replay_playback_active = false
		return
	if replay_playback_active:
		var started: bool = bool(replay.call("begin_playback", replay_requested_data, level_data, input_style, random_mode_enabled))
		if not started:
			push_warning("Beat UP! replay rejected because chart/rules identity no longer matches.")
			replay_playback_active = false
			replay_requested_data.clear()
			return
	else:
		replay.call("begin_recording", level_data, input_style, random_mode_enabled, current_random_seed)

func _arm_gameplay_start() -> void:
	# v17.4.37: initial gameplay uses the song itself as the lead-in. The old
	# READY / 3 / 2 / 1 overlay is intentionally not shown on chart launch.
	# Audio stays stopped only while the shared artwork handoff is covering the
	# gameplay screen, then starts as soon as that transition has completed.
	gameplay_preparing = true
	gameplay_prepare_remaining = 0.0
	countdown_displayed_second = -1
	resume_countdown_active = false
	fight_time = 0.0
	music_has_finished = false
	if music != null:
		music.stop()
		music.stream_paused = false
	_reset_runtime_timing_state()
	_hide_gameplay_countdown()
	_configure_skip_intro()

func _begin_gameplay_playback() -> void:
	if not gameplay_preparing:
		return
	gameplay_preparing = false
	var playback_start: float = maxf(0.0, practice_start_s - practice_lead_in_s) if practice_mode_active else 0.0
	fight_time = playback_start
	_reset_runtime_timing_state()
	if music != null:
		music.stream_paused = false
		music.play(playback_start)
	_refresh_skip_intro_visibility()

func _configure_skip_intro() -> void:
	first_playable_event_s = _get_first_playable_event_time()
	var lead_time: float = maxf(skip_intro_lead_time, get_travel_time() + 0.50)
	skip_intro_target_s = maxf(0.0, first_playable_event_s - lead_time)
	skip_intro_available = first_playable_event_s >= skip_intro_threshold and skip_intro_target_s > 0.50
	if skip_intro_button != null:
		skip_intro_button.visible = false

func _get_first_playable_event_time() -> float:
	var first_time: float = 1000000000.0
	var raw_events: Variant = level_data.get("events", [])
	if raw_events is Array:
		for raw_event: Variant in raw_events:
			if raw_event is Dictionary:
				var event_data: Dictionary = raw_event as Dictionary
				first_time = minf(first_time, float(event_data.get("time", first_time)))
	var raw_spaces: Variant = level_data.get("space_events", [])
	if raw_spaces is Array:
		for raw_space: Variant in raw_spaces:
			if raw_space is float or raw_space is int:
				first_time = minf(first_time, float(raw_space))
			elif raw_space is Dictionary:
				var space_data: Dictionary = raw_space as Dictionary
				first_time = minf(first_time, float(space_data.get("time", first_time)))
	return 0.0 if first_time >= 999999999.0 else maxf(0.0, first_time)

func _refresh_skip_intro_visibility() -> void:
	if skip_intro_button == null:
		return
	var can_show: bool = (
		skip_intro_available
		and not fight_over
		and not game_paused
		and not gameplay_preparing
		and not resume_countdown_active
		and fight_time < skip_intro_target_s - 0.10
	)
	skip_intro_button.visible = can_show

func _on_skip_intro_pressed() -> void:
	if not skip_intro_available or music == null or not music.playing:
		return
	if fight_time >= skip_intro_target_s - 0.10:
		_refresh_skip_intro_visibility()
		return
	music.seek(skip_intro_target_s)
	fight_time = skip_intro_target_s
	_reset_runtime_timing_state()
	skip_intro_available = false
	skip_intro_button.visible = false
	update_hud()

func _start_resume_countdown() -> void:
	resume_countdown_active = true
	gameplay_prepare_remaining = maxf(1.0, resume_countdown_duration)
	countdown_displayed_second = -1
	countdown_overlay.visible = true
	countdown_overlay.modulate = Color.WHITE
	countdown_status.text = "RESUME"
	countdown_mode.text = "GET READY"
	countdown_status.modulate = Color.WHITE
	countdown_mode.modulate = Color.WHITE
	countdown_stack.pivot_offset = countdown_stack.size * 0.5
	countdown_stack.scale = Vector2.ONE
	_update_resume_countdown_display(true)

func _update_resume_countdown(delta: float) -> void:
	if not resume_countdown_active:
		return
	gameplay_prepare_remaining = maxf(0.0, gameplay_prepare_remaining - maxf(0.0, delta))
	_update_resume_countdown_display(false)
	if gameplay_prepare_remaining <= 0.0:
		_finish_resume_countdown()

func _update_resume_countdown_display(force: bool) -> void:
	var shown_second: int = clampi(ceili(gameplay_prepare_remaining), 1, ceili(resume_countdown_duration))
	countdown_visual.set_countdown(gameplay_prepare_remaining, resume_countdown_duration)
	if not force and shown_second == countdown_displayed_second:
		return
	countdown_displayed_second = shown_second
	countdown_number.text = str(shown_second)
	countdown_number.add_theme_color_override("font_color", _countdown_step_color(shown_second))
	countdown_number.modulate = Color(1.0, 1.0, 1.0, 0.0)
	countdown_number.scale = Vector2.ONE * 1.26
	countdown_number.pivot_offset = countdown_number.size * 0.5
	countdown_visual.trigger_step()
	if countdown_tween != null:
		countdown_tween.kill()
	countdown_tween = create_tween()
	countdown_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	countdown_tween.set_parallel(true)
	countdown_tween.tween_property(countdown_number, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	countdown_tween.tween_property(countdown_number, "modulate:a", 1.0, 0.075).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _countdown_step_color(second: int) -> Color:
	match second:
		1:
			return MinimalThemeScript.PINK
		2:
			return MinimalThemeScript.GOLD
		_:
			return MinimalThemeScript.CYAN

func _finish_resume_countdown() -> void:
	if not resume_countdown_active:
		return
	resume_countdown_active = false
	gameplay_prepare_remaining = 0.0
	_hide_gameplay_countdown()
	game_paused = false
	pause_button.visible = not fight_over and not level_select.visible and not result_overlay.visible
	if music != null:
		music.stream_paused = false
	resume_timing_check_pending = pause_timing_snapshot_valid
	background_visual.set_process(true)
	_refresh_skip_intro_visibility()

func _hide_gameplay_countdown() -> void:
	if countdown_overlay != null:
		countdown_overlay.visible = false
		countdown_overlay.modulate = Color.WHITE
	if countdown_stack != null:
		countdown_stack.scale = Vector2.ONE
	if countdown_number != null:
		countdown_number.scale = Vector2.ONE
		countdown_number.modulate = Color.WHITE
		countdown_number.add_theme_font_size_override("font_size", 112)
	if countdown_status != null:
		countdown_status.modulate = Color.WHITE
	if countdown_mode != null:
		countdown_mode.modulate = Color.WHITE

func _cancel_gameplay_countdown() -> void:
	# Kept as the shared cancellation hook for existing gameplay exits/retries.
	# Initial launch no longer has a countdown; only pause -> resume uses it.
	gameplay_preparing = false
	resume_countdown_active = false
	gameplay_prepare_remaining = 0.0
	countdown_displayed_second = -1
	if countdown_tween != null:
		countdown_tween.kill()
		countdown_tween = null
	if countdown_reveal_tween != null:
		countdown_reveal_tween.kill()
		countdown_reveal_tween = null
	_hide_gameplay_countdown()
	if skip_intro_button != null:
		skip_intro_button.visible = false

func load_audio_stream(path: String) -> AudioStream:
	if path.is_empty():
		return null
	if path.begins_with("res://"):
		var imported_stream: AudioStream = load(path) as AudioStream
		if imported_stream != null:
			return imported_stream
	var filesystem_path: String = ProjectSettings.globalize_path(path) if path.begins_with("user://") else path
	if path.begins_with("res://"):
		filesystem_path = ProjectSettings.globalize_path(path)
	var extension: String = filesystem_path.get_extension().to_lower()
	match extension:
		"ogg": return AudioStreamOggVorbis.load_from_file(filesystem_path)
		"mp3": return AudioStreamMP3.load_from_file(filesystem_path)
		"wav": return AudioStreamWAV.load_from_file(filesystem_path)
	return null

func _process(delta: float) -> void:
	update_feedback(delta)
	update_judgment_popup(delta)
	if timing_debug_visible:
		update_timing_debug()
	if resume_countdown_active:
		_update_resume_countdown(delta)
		update_hud()
		return
	if game_paused or fight_over or level_select.visible:
		return
	if gameplay_preparing:
		# Keep audio stopped only while the artwork handoff is still covering the
		# gameplay screen. There is no initial READY/3/2/1 gate anymore.
		if not SceneTransition.is_transitioning():
			_begin_gameplay_playback()
		update_hud()
		return
	if resume_timing_check_pending:
		_check_resume_timing_continuity()
	fight_time = get_music_time()
	_refresh_skip_intro_visibility()
	if replay_playback_active:
		_dispatch_v18_replay_actions()
	var passive_judgment_time: float = RhythmTimingScript.get_input_judgment_time(fight_time, user_input_offset_ms)
	spawn_chart_notes()
	consume_late_notes(passive_judgment_time)
	consume_late_space_events(passive_judgment_time)
	track.update_note_positions(fight_time, get_travel_time(), get_current_note())
	update_space_prompt_visual(fight_time)
	update_hud()
	var input_tail_s: float = maxf(0.0, user_input_offset_ms / 1000.0)
	var finish_grace_s: float = maxf(gameplay_config.good_window, gameplay_config.space_good_window) + input_tail_s + 0.05
	if practice_mode_active:
		if fight_time >= practice_end_s + finish_grace_s:
			_complete_v18_practice_loop()
		return
	var duration: float = get_song_duration()
	if duration > 0.0 and fight_time >= duration + finish_grace_s:
		end_fight()

func update_feedback(delta: float) -> void:
	if feedback_timer <= 0.0:
		return
	feedback_timer = maxf(0.0, feedback_timer - delta)
	if feedback_timer <= 0.08:
		var fade: float = clampf(feedback_timer / 0.08, 0.0, 1.0)
		_set_feedback_alpha(fade)
	if feedback_timer <= 0.0:
		_reset_feedback_visuals()

func spawn_chart_notes() -> void:
	var targets: Array = chart_timeline.collect_upcoming(fight_time, get_travel_time())
	for event_data in targets:
		if event_data is Dictionary:
			spawn_chart_note(event_data)

func spawn_chart_note(event_data: Dictionary) -> void:
	var data := build_note_data(event_data)
	var note: RhythmNote = track.spawn_note(data)
	if note != null:
		stream_notes.append(note)

func build_note_data(event_data: Dictionary) -> Dictionary:
	# Chart timing and special-note placement are shared by both input styles.
	# With RANDOM disabled, 8K is always the exact authored chart and 4K is always
	# the exact precomputed projection of that authored chart. Runtime mode changes
	# never rewrite either layout.
	var note_type: String = str(event_data.get("type", "normal"))
	var runtime_index := int(event_data.get("_runtime_event_index", -1))
	var picked: Dictionary = {}
	if random_mode_enabled:
		picked = pick_runtime_direction()
	elif input_style == "4_arrow":
		var mapped_number := int(four_key_layout_cache.get(runtime_index, 0))
		if mapped_number in [2, 4, 6, 8]:
			picked = _four_direction_by_number(mapped_number)
		else:
			picked = _stable_four_direction_fallback(event_data, runtime_index)
	else:
		var authored_number := int(authored_direction_cache.get(runtime_index, event_data.get("direction", 0)))
		if authored_number in [1, 2, 3, 4, 6, 7, 8, 9]:
			picked = get_direction_by_number(authored_number)
		else:
			picked = pick_deterministic_fallback_direction()
	var expected: Dictionary = picked
	var displayed: Dictionary = picked
	if note_type == "reverse":
		# Reverse displays the opposite arrow while the expected input remains the
		# authored/remapped direction. This preserves the reading mechanic in 4K.
		displayed = get_direction_by_key(get_opposite_key(int(picked["key"])))
	var data: Dictionary = {
		"type": note_type,
		"key": int(expected["key"]),
		"display_key": int(displayed["key"]),
		"symbol": str(displayed["symbol"]),
		"numpad": str(displayed["numpad"]),
		"dx": float(displayed["dx"]),
		"dy": float(displayed["dy"]),
		"target": float(event_data.get("time", 0.0)) + get_chart_target_offset_seconds(),
		"travel_time": get_travel_time(),
		"runtime_event_index": runtime_index,
		"authored_direction": int(event_data.get("direction", 0)),
	}
	return data

func consume_late_notes(now: float) -> void:
	while not fight_over:
		var note: RhythmNote = get_current_note()
		if note == null:
			return
		if now <= note.target_time + gameplay_config.good_window:
			return
		register_miss("MISS", true)

func consume_late_space_events(now: float) -> void:
	while not fight_over:
		var target: float = get_current_space_time()
		if target < 0.0:
			return
		if now <= target + gameplay_config.space_good_window:
			return
		register_space_miss()
func _developer_shortcuts_available() -> bool:
	# Editor and debug exports keep iteration shortcuts; release exports do not.
	return OS.has_feature("editor") or OS.has_feature("debug")

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	# Transition handoffs own input while active. This prevents a key used
	# to confirm one screen from leaking into the next screen, and blocks retry/
	# pause/back races while a transition action is still switching state.
	if SceneTransition.is_transitioning():
		get_viewport().set_input_as_handled()
		return

	if _developer_shortcuts_available() and result_debug_shortcut_enabled and (key_event.keycode == KEY_F4 or key_event.physical_keycode == KEY_F4):
		show_result_debug_screen()
		get_viewport().set_input_as_handled()
		return

	if _developer_shortcuts_available() and (key_event.keycode == KEY_F3 or key_event.physical_keycode == KEY_F3):
		timing_debug_visible = not timing_debug_visible
		timing_debug_label.visible = timing_debug_visible
		update_timing_debug()
		get_viewport().set_input_as_handled()
		return

	if _developer_shortcuts_available() and (key_event.keycode == KEY_F2 or key_event.physical_keycode == KEY_F2):
		open_chart_editor()
		get_viewport().set_input_as_handled()
		return

	if resume_countdown_active:
		get_viewport().set_input_as_handled()
		return

	if pause_overlay.visible:
		return

	if level_select.visible:
		return

	if gameplay_preparing:
		var preparation_key := get_pressed_gameplay_key(key_event)
		if preparation_key != KEY_NONE:
			track.flash_input(preparation_key)
		if key_event.keycode == KEY_ESCAPE:
			show_pause_overlay()
		get_viewport().set_input_as_handled()
		return

	if fight_over:
		var result_navigation_ready := true
		if result_overlay.has_method("is_navigation_ready"):
			result_navigation_ready = bool(result_overlay.call("is_navigation_ready"))
		if not result_navigation_ready:
			get_viewport().set_input_as_handled()
			return
		if is_numpad_key(key_event, KEY_KP_5):
			_transition_to_current_chart("RESTARTING CHART")
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_ESCAPE:
			_transition_to_song_library()
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_ENTER or key_event.physical_keycode == KEY_ENTER:
			# Let the focused result action receive Enter. If focus is unavailable,
			# preserve the historical Enter-to-retry fallback.
			var focused_control := get_viewport().gui_get_focus_owner()
			if not (focused_control is Button):
				_transition_to_current_chart("RESTARTING CHART")
				get_viewport().set_input_as_handled()
		return

	if key_event.keycode == KEY_ESCAPE:
		show_pause_overlay()
		get_viewport().set_input_as_handled()
		return

	# During deterministic replay playback only navigation/pause input is accepted.
	# Gameplay actions are injected from the replay timeline below in _process().
	if replay_playback_active:
		get_viewport().set_input_as_handled()
		return

	if _event_matches_run_binding(key_event, "space"):
		get_viewport().set_input_as_handled()
		fight_time = get_music_time()
		_record_v18_replay_action("space", key_event, fight_time)
		_handle_v18_space_action(fight_time)
		return

	var pressed_key: int = get_pressed_gameplay_key(key_event)
	if pressed_key == KEY_NONE:
		return
	get_viewport().set_input_as_handled()
	fight_time = get_music_time()
	_record_v18_replay_action(_v18_replay_action_for_key(pressed_key), key_event, fight_time)
	_handle_v18_direction_action(pressed_key, fight_time)

func _v18_replay_action_for_key(keycode: int) -> String:
	match keycode:
		KEY_KP_1: return "dir_1"
		KEY_KP_2: return "dir_2"
		KEY_KP_3: return "dir_3"
		KEY_KP_4: return "dir_4"
		KEY_KP_6: return "dir_6"
		KEY_KP_7: return "dir_7"
		KEY_KP_8: return "dir_8"
		KEY_KP_9: return "dir_9"
		KEY_LEFT: return "dir_left"
		KEY_UP: return "dir_up"
		KEY_RIGHT: return "dir_right"
		KEY_DOWN: return "dir_down"
		_: return ""

func _v18_key_for_replay_action(action: String) -> int:
	match action:
		"dir_1": return KEY_KP_1
		"dir_2": return KEY_KP_2
		"dir_3": return KEY_KP_3
		"dir_4": return KEY_KP_4
		"dir_6": return KEY_KP_6
		"dir_7": return KEY_KP_7
		"dir_8": return KEY_KP_8
		"dir_9": return KEY_KP_9
		"dir_left": return KEY_LEFT
		"dir_up": return KEY_UP
		"dir_right": return KEY_RIGHT
		"dir_down": return KEY_DOWN
		_: return KEY_NONE

func _record_v18_replay_action(action: String, key_event: InputEventKey, song_time_s: float) -> void:
	if action.is_empty() or practice_mode_active or replay_playback_active:
		return
	var replay: Node = get_node_or_null("/root/ReplayManager")
	if replay == null:
		return
	var physical: int = int(key_event.physical_keycode)
	var logical: int = int(key_event.keycode)
	replay.call("record_action", song_time_s, action, physical if physical != KEY_NONE else logical)

func _dispatch_v18_replay_actions() -> void:
	var replay: Node = get_node_or_null("/root/ReplayManager")
	if replay == null or not replay_playback_active:
		return
	var due_value: Variant = replay.call("pop_due_actions", fight_time)
	if not (due_value is Array):
		return
	for raw_item: Variant in due_value as Array:
		if not (raw_item is Dictionary):
			continue
		var item: Dictionary = raw_item as Dictionary
		var action: String = str(item.get("action", ""))
		var action_time: float = float(item.get("time_ms", 0)) / 1000.0
		if action == "space":
			_handle_v18_space_action(action_time)
			continue
		var keycode: int = _v18_key_for_replay_action(action)
		if keycode != KEY_NONE:
			_handle_v18_direction_action(keycode, action_time)

func _handle_v18_space_action(raw_time_s: float) -> void:
	var space_input_time: float = RhythmTimingScript.get_input_judgment_time(raw_time_s, user_input_offset_ms)
	var space_target: float = get_current_space_time()
	if space_target >= 0.0:
		_record_timing_delta(raw_time_s, space_input_time, space_target)
	spawn_chart_notes()
	consume_late_notes(space_input_time)
	handle_space_prompt_input(space_input_time)

func _handle_v18_direction_action(pressed_key: int, raw_time_s: float) -> void:
	track.flash_input(pressed_key)
	if pressed_key == KEY_KP_5:
		return
	var input_time: float = RhythmTimingScript.get_input_judgment_time(raw_time_s, user_input_offset_ms)
	spawn_chart_notes()
	consume_late_notes(input_time)
	var current: RhythmNote = get_current_note()
	if current == null:
		return
	_record_timing_delta(raw_time_s, input_time, current.target_time)
	var current_offset: float = input_time - current.target_time
	if current_offset < -gameplay_config.good_window:
		show_feedback("EARLY", "Wait for the HIT marker.", theme_config.text_secondary, 0.12)
		return
	if current_offset > gameplay_config.good_window:
		consume_late_notes(input_time)
		current = get_current_note()
		if current == null:
			return
		current_offset = input_time - current.target_time
		if absf(current_offset) > gameplay_config.good_window:
			return
	if current.expected_key == pressed_key:
		register_hit(absf(current_offset), current, current_offset)
		return
	register_miss("WRONG INPUT", false, pressed_key, current_offset, true)

func _complete_v18_practice_loop() -> void:
	if not practice_mode_active or fight_over:
		return
	_reconcile_result_judgements()
	var accuracy: float = calculate_accuracy()
	var snapshot: Dictionary = _build_result_snapshot(accuracy, false)
	snapshot["session_mode"] = "practice"
	snapshot["practice_section_index"] = practice_section_index
	snapshot["practice_section_role"] = str(practice_section.get("role", practice_section.get("name", "section")))
	PracticeRecordsScript.record(level_data, input_style, random_mode_enabled, practice_section_index, practice_section, snapshot)
	practice_loop_count += 1
	show_feedback("PRACTICE %d" % practice_loop_count, "%.2f%% · looping section" % accuracy, theme_config.text_secondary, 0.55)
	_restart_v18_practice_loop()

func _restart_v18_practice_loop() -> void:
	track.clear_notes()
	stream_notes.clear()
	current_note_index = 0
	current_space_index = 0
	var loop_events: Variant = level_data.get("events", [])
	if loop_events is Array:
		chart_timeline.load_events(loop_events as Array)
	var loop_spaces: Variant = level_data.get("space_events", [])
	space_events = load_space_events(loop_spaces as Array if loop_spaces is Array else [])
	combo = 0
	max_combo = 0
	score = 0
	score_digits.reset_value(0)
	total_hits = 0
	perfect_hits = 0
	great_hits = 0
	total_misses = 0
	reverse_hits = 0
	space_hits = 0
	space_perfects = 0
	space_misses = 0
	_reset_feedback_visuals()
	var playback_start: float = maxf(0.0, practice_start_s - practice_lead_in_s)
	fight_time = playback_start
	_reset_runtime_timing_state()
	music_has_finished = false
	if music != null:
		music.stop()
		music.stream_paused = false
		music.play(playback_start)
	update_hud()

func load_space_events(raw_space_events: Array) -> Array[float]:
	var loaded: Array[float] = []
	for value in raw_space_events:
		if value is float or value is int:
			loaded.append(float(value) + get_chart_target_offset_seconds())
	loaded.sort()
	return loaded

func get_current_space_time() -> float:
	if current_space_index < 0 or current_space_index >= space_events.size():
		return -1.0
	return space_events[current_space_index]

func update_space_prompt_visual(now: float) -> void:
	var target: float = get_current_space_time()
	if target < 0.0:
		track.set_space_prompt(false, 0.0, false)
		return
	var time_until: float = target - now
	if time_until > gameplay_config.space_approach_time or time_until < -gameplay_config.space_good_window:
		track.set_space_prompt(false, 0.0, false)
		return
	var progress: float = 1.0 - clampf(time_until / maxf(0.001, gameplay_config.space_approach_time), 0.0, 1.0)
	var in_window: bool = absf(time_until) <= gameplay_config.space_good_window
	track.set_space_prompt(true, progress, in_window)

func advance_space_index() -> void:
	current_space_index += 1
func register_hit(distance: float, note: RhythmNote, signed_offset_s: float = 0.0) -> void:
	play_hit_sfx()
	var rating: String = ScoreProcessor.judgement(distance, gameplay_config.perfect_window, gameplay_config.great_window)
	var points: int = int(gameplay_config.get(rating.to_lower() + "_score"))
	if rating == "PERFECT": perfect_hits += 1
	elif rating == "GREAT": great_hits += 1

	var is_reverse: bool = note.note_type == "reverse"
	if is_reverse:
		points += gameplay_config.reverse_score_bonus
		reverse_hits += 1

	total_hits += 1
	combo += 1
	max_combo = maxi(max_combo, combo)
	var combo_multiplier: float = get_combo_multiplier(combo)
	var awarded_score: int = ScorePolicy.note_award(points, combo_multiplier, gameplay_config.score_scale_multiplier)
	score = ScorePolicy.accumulate(score, awarded_score)

	playtest_telemetry.record_note_judgement(
		note.runtime_event_index,
		note.target_time,
		note.note_type,
		note.authored_direction,
		_telemetry_input_label(note.expected_key),
		_telemetry_input_label(note.display_key),
		_telemetry_input_label(note.expected_key),
		rating,
		signed_offset_s * 1000.0,
		"",
		false,
		combo,
		score
	)

	mark_note_judged(note, true)

	show_judgment_popup(rating)
	track.play_hit_feedback(rating)

func register_miss(reason: String, automatic: bool, player_input_key: int = KEY_NONE, timing_error_s: float = 0.0, has_input_timing: bool = false) -> void:
	var note: RhythmNote = get_current_note()
	if note == null:
		return
	play_miss_sfx()
	total_misses += 1
	combo = 0
	var timing_error_ms: Variant = null
	if has_input_timing:
		timing_error_ms = timing_error_s * 1000.0
	playtest_telemetry.record_note_judgement(
		note.runtime_event_index,
		note.target_time,
		note.note_type,
		note.authored_direction,
		_telemetry_input_label(note.expected_key),
		_telemetry_input_label(note.display_key),
		_telemetry_input_label(player_input_key),
		"MISS",
		timing_error_ms,
		reason,
		automatic,
		combo,
		score
	)
	mark_current_note_judged()
	show_judgment_popup("MISS")
	track.play_hit_feedback("MISS")

func mark_current_note_judged() -> void:
	var note: RhythmNote = get_current_note()
	if note != null:
		mark_note_judged(note)

func mark_note_judged(note: RhythmNote, snap_to_target: bool = false) -> void:
	if note == null or not is_instance_valid(note):
		return
	if snap_to_target:
		note.mark_hit(track.hit_point.position.x, track.hit_point.position.y)
	else:
		note.mark_judged()
	advance_note_cursor()
	compact_note_queue()
	track.update_note_positions(fight_time, get_travel_time(), get_current_note())

func advance_note_cursor() -> void:
	while current_note_index < stream_notes.size():
		var candidate: Variant = stream_notes[current_note_index]
		if is_instance_valid(candidate):
			var note: RhythmNote = candidate as RhythmNote
			if note != null and not note.judged:
				break
		current_note_index += 1

func compact_note_queue() -> void:
	if current_note_index < 64:
		return
	stream_notes = stream_notes.slice(current_note_index)
	current_note_index = 0



func _on_music_finished() -> void:
	if fight_over or level_select.visible:
		return
	if get_song_duration() <= 0.0:
		end_fight()
		return
	# Keep a synthetic tail clock after the audio stream ends. Positive audio
	# and input offsets may intentionally place the final judgment window after
	# the physical stream endpoint, so ending immediately would cut it off.
	music_has_finished = true
	music_finished_clock_s = _monotonic_clock_s()
	var expected_compensated_end: float = maxf(0.0, get_song_duration() - user_audio_offset_ms / 1000.0)
	music_finished_song_time = maxf(fight_time, expected_compensated_end)

func end_fight() -> void:
	if fight_over:
		return
	fight_over = true
	game_paused = false
	pause_overlay.visible = false
	_cancel_gameplay_countdown()
	music_has_finished = false
	if music != null:
		music.stream_paused = false
		music.stop()
	SceneTransition.transition_action(_finalize_end_fight, "CALCULATING RESULTS", "BUILDING RUN SUMMARY")

func _finalize_end_fight() -> void:
	# Lock any unresolved authored events as misses before calculating or saving
	# the run. This guarantees Result, personal-best storage, and later beta
	# telemetry all start from the same complete judgement snapshot.
	_reconcile_result_judgements()
	_set_primary_screen(PrimaryScreen.RESULT)
	background_visual.set_process(false)
	var accuracy: float = calculate_accuracy()
	var is_new_best: bool = false
	if not replay_playback_active:
		is_new_best = commit_best_stats(accuracy)
	var result_snapshot: Dictionary = _build_result_snapshot(accuracy, is_new_best)
	result_snapshot["session_mode"] = "replay" if replay_playback_active else "normal"
	_report_runtime("result", "Gameplay run completed", {"song_id": selected_song_id, "difficulty": str(result_snapshot.get("difficulty_id", "")), "accuracy": accuracy, "score": score, "session_mode": str(result_snapshot.get("session_mode", "normal"))})
	var replay: Node = get_node_or_null("/root/ReplayManager")
	if replay_playback_active:
		if replay != null:
			replay.call("stop_playback")
	else:
		playtest_telemetry.complete_session(result_snapshot)
		if replay != null:
			replay.call("finish_recording", result_snapshot)
	result_overlay.call("set_result", result_snapshot)
	result_overlay.call("focus_default")
	update_hud()

func show_result_debug_screen() -> void:
	# Representative data for iterating on the screen without finishing a song.
	# This deliberately bypasses commit_best_stats(), so debug previews never
	# increment play counts or overwrite a personal best.
	if levels.is_empty():
		levels = level_catalog.load_all(true)
	if levels.is_empty():
		push_warning("Result debug shortcut needs at least one playable level")
		return

	var debug_level_index := current_level_index
	if debug_level_index < 0 or debug_level_index >= levels.size():
		debug_level_index = 0
	current_level_index = debug_level_index
	level_data = (levels[debug_level_index] as Dictionary).duplicate(true)
	selected_song_id = str(level_data.get("song_id", level_data.get("id", "debug-song")))
	random_mode_enabled = false

	# Build representative but internally consistent debug data from the actual
	# authored chart so the preview itself can be used to QA Result integrity.
	var debug_note_total: int = _expected_note_count()
	var debug_space_total: int = _expected_space_count()
	var debug_reverse_total: int = _count_reverse_notes()
	total_misses = mini(debug_note_total, maxi(1, int(round(float(debug_note_total) * 0.18)))) if debug_note_total > 0 else 0
	total_hits = maxi(0, debug_note_total - total_misses)
	perfect_hits = mini(total_hits, int(round(float(total_hits) * 0.58)))
	great_hits = mini(maxi(0, total_hits - perfect_hits), int(round(float(total_hits) * 0.24)))
	combo = 0
	max_combo = mini(total_hits, maxi(0, int(round(float(total_hits) * 0.42))))
	score = ScorePolicy.clamp_score(ScorePolicy.note_award(
		maxi(0, total_hits * 120 + perfect_hits * 35 + great_hits * 18),
		1.0,
		gameplay_config.score_scale_multiplier
	))
	space_misses = mini(1, debug_space_total)
	space_hits = maxi(0, debug_space_total - space_misses)
	space_perfects = mini(space_hits, maxi(0, int(round(float(space_hits) * 0.60))))
	reverse_hits = maxi(0, debug_reverse_total - mini(debug_reverse_total, maxi(1, int(round(float(debug_reverse_total) * 0.20))))) if debug_reverse_total > 0 else 0
	fight_time = get_song_duration()

	fight_over = true
	music_has_finished = false
	music.stop()
	track.clear_notes()
	chart_timeline.clear()
	stream_notes.clear()
	current_note_index = 0
	space_events.clear()
	current_space_index = 0
	_set_primary_screen(PrimaryScreen.RESULT)
	background_visual.set_process(false)
	_reset_feedback_visuals()

	var accuracy: float = calculate_accuracy()
	update_result_screen(accuracy, false)
	result_overlay.call("focus_default")
	update_hud()

func _set_primary_screen(screen: PrimaryScreen) -> void:
	level_select.visible = screen == PrimaryScreen.SONG_SELECT
	result_overlay.visible = screen == PrimaryScreen.RESULT
	_set_gameplay_layers_visible(screen == PrimaryScreen.GAMEPLAY)
	background_visual.visible = screen == PrimaryScreen.GAMEPLAY
	pause_overlay.visible = false
	pause_button.visible = screen == PrimaryScreen.GAMEPLAY
	if screen != PrimaryScreen.GAMEPLAY and skip_intro_button != null:
		skip_intro_button.visible = false
	game_paused = false
	if screen != PrimaryScreen.GAMEPLAY:
		_cancel_gameplay_countdown()

func _set_gameplay_layers_visible(layers_visible: bool) -> void:
	# Gameplay is a sibling of the screen overlays. Hiding the actual layers is
	# safer than assuming every menu backdrop stays fully opaque, and prevents
	# the receptor/track from leaking into Song Select or Result Screen.
	battle_layer.visible = layers_visible
	hud_layer.visible = layers_visible
	feedback_layer.visible = layers_visible

func _on_result_back_pressed() -> void:
	if SceneTransition.is_transitioning():
		return
	_transition_to_song_library()

func _on_result_replay_pressed() -> void:
	if SceneTransition.is_transitioning():
		return
	_transition_to_current_chart("RESTARTING CHART")

func format_result_number(value: int) -> String:
	var digits: String = str(maxi(0, value))
	var grouped: String = ""
	var count: int = 0
	for i in range(digits.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			grouped = "," + grouped
		grouped = digits.substr(i, 1) + grouped
		count += 1
	return grouped

func _expected_note_count() -> int:
	var raw_events: Variant = level_data.get("events", [])
	if not (raw_events is Array):
		return total_hits + total_misses
	var count: int = 0
	for raw_event: Variant in (raw_events as Array):
		if raw_event is Dictionary:
			count += 1
	return count

func _expected_space_count() -> int:
	var raw_space_events: Variant = level_data.get("space_events", [])
	if raw_space_events is Array:
		return (raw_space_events as Array).size()
	return space_hits + space_misses

func _reconcile_result_judgements() -> void:
	var expected_notes: int = _expected_note_count()
	var judged_notes: int = total_hits + total_misses
	if judged_notes < expected_notes:
		var unresolved_notes: int = expected_notes - judged_notes
		total_misses += unresolved_notes
		combo = 0
		push_warning("Beat UP! result reconciliation: %d unresolved note(s) recorded as MISS." % unresolved_notes)
	elif judged_notes > expected_notes and expected_notes > 0:
		push_warning("Beat UP! result reconciliation: judged note count exceeds authored note count (%d > %d)." % [judged_notes, expected_notes])

	var expected_spaces: int = _expected_space_count()
	var judged_spaces: int = space_hits + space_misses
	if judged_spaces < expected_spaces:
		var unresolved_spaces: int = expected_spaces - judged_spaces
		space_misses += unresolved_spaces
		push_warning("Beat UP! result reconciliation: %d unresolved SPACE event(s) recorded as MISS." % unresolved_spaces)
	elif judged_spaces > expected_spaces and expected_spaces > 0:
		push_warning("Beat UP! result reconciliation: judged SPACE count exceeds authored SPACE count (%d > %d)." % [judged_spaces, expected_spaces])

func _count_reverse_notes() -> int:
	var reverse_total: int = 0
	var raw_events: Variant = level_data.get("events", [])
	if raw_events is Array:
		for raw_event: Variant in (raw_events as Array):
			if raw_event is Dictionary and str((raw_event as Dictionary).get("type", "normal")).to_lower() == "reverse":
				reverse_total += 1
	return reverse_total

func _build_result_snapshot(accuracy: float, is_new_best: bool) -> Dictionary:
	var judged: int = total_hits + total_misses
	var good_hits: int = get_good_hits()
	var perfect_rate: float = 0.0
	if judged > 0:
		perfect_rate = float(perfect_hits) / float(judged) * 100.0
	var rank: String = get_accuracy_rank(accuracy)
	var bpm: int = int(round(float(level_data.get("bpm", 120.0))))
	var artist: String = str(level_data.get("artist", "Unknown Artist"))
	var difficulty: String = str(level_data.get("difficulty", "NORMAL"))
	var mode_text: String = "RANDOM" if random_mode_enabled else "AUTHORED"
	var input_mode_text: String = "4-ARROW" if input_style == "4_arrow" else "8-DIR"
	var stars: int = int(level_data.get("star_rating", 1))
	var expected_notes: int = _expected_note_count()
	var expected_spaces: int = _expected_space_count()
	var run_has_judgements: bool = expected_notes + expected_spaces > 0

	var rank_sub: String = result_config.clear_label if result_config != null else "CLEAR"
	if result_config != null:
		var full_combo: bool = (
			run_has_judgements
			and total_misses == 0
			and space_misses == 0
			and total_hits >= expected_notes
			and space_hits >= expected_spaces
		)
		if full_combo:
			rank_sub = result_config.full_combo_label
		elif accuracy >= result_config.excellent_accuracy:
			rank_sub = result_config.excellent_label
		elif accuracy >= result_config.great_clear_accuracy:
			rank_sub = result_config.great_clear_label

	var reverse_total: int = _count_reverse_notes()
	var safe_reverse_hits: int = mini(maxi(0, reverse_hits), reverse_total) if reverse_total > 0 else 0
	var reverse_misses: int = maxi(0, reverse_total - safe_reverse_hits)
	var safe_space_hits: int = mini(maxi(0, space_hits), expected_spaces) if expected_spaces > 0 else 0
	var safe_space_misses: int = maxi(0, expected_spaces - safe_space_hits)
	var chart_difficulty_id: String = str(level_data.get("chart_difficulty", difficulty)).to_lower()

	return {
		"song_id": selected_song_id,
		"title": str(level_data.get("title", "SONG")),
		"difficulty": difficulty,
		"input_style": input_style,
		"random_mode": random_mode_enabled,
		"run_duration_s": maxf(0.0, fight_time),
		"completion_state": "completed",
		"app_version": ScoreIdentity.app_version(),
		"score_identity": ScoreIdentity.identity(level_data, input_style, random_mode_enabled),
		"meta": "%s  •  %s  •  %s  •  %s  •  %d★  •  %d BPM" % [artist, difficulty, input_mode_text, mode_text, stars, bpm],
		"background": str(level_data.get("background", "")),
		"difficulty_id": chart_difficulty_id,
		"score": maxi(0, score),
		"score_text": format_result_number(score),
		"new_best": is_new_best,
		"run_id": run_session.run_id,
		"record_save_failed": run_session.save_error,
		"previous_best": {"score": run_session.previous_best.get("score", 0), "accuracy": run_session.previous_best.get("accuracy", 0.0)} if not run_session.previous_best.is_empty() else {},
		"accuracy": clampf(accuracy, 0.0, 100.0),
		"accuracy_text": "%.2f%%" % clampf(accuracy, 0.0, 100.0),
		"max_combo": maxi(0, max_combo),
		"combo_text": "%dx" % maxi(0, max_combo),
		"perfect_rate": perfect_rate,
		"perfect_rate_text": "%.2f%%" % perfect_rate,
		"perfect": maxi(0, perfect_hits),
		"great": maxi(0, great_hits),
		"good": maxi(0, good_hits),
		"miss": maxi(0, total_misses),
		"note_total": expected_notes,
		"space_hits": safe_space_hits,
		"space_misses": safe_space_misses,
		"space_total": expected_spaces,
		"space_text": "SPACE\n%d HIT · %d MISS" % [safe_space_hits, safe_space_misses],
		"reverse_hits": safe_reverse_hits,
		"reverse_total": reverse_total,
		"reverse_misses": reverse_misses,
		"reverse_text": "REVERSE\n%d" % safe_reverse_hits,
		"rank": rank,
		"rank_sub": rank_sub,
	}

func update_result_screen(accuracy: float, is_new_best: bool) -> void:
	result_overlay.call("set_result", _build_result_snapshot(accuracy, is_new_best))

func play_hit_sfx() -> void:
	if hit_sfx != null and hit_sfx.stream != null:
		hit_sfx.play()

func play_miss_sfx() -> void:
	if miss_sfx != null and miss_sfx.stream != null:
		miss_sfx.play()

func show_feedback(main_text: String, _sub_text: String, color: Color, duration: float, _combo_display: int = -1) -> void:
	# Reserved for infrequent system messages such as early-input hints.
	# Hit judgments intentionally do not call this function anymore.
	feedback_main.visible = true
	feedback_main.text = main_text
	feedback_main.add_theme_color_override("font_color", color)
	feedback_sub.visible = false
	feedback_timer = duration
	_set_feedback_alpha(1.0)

func _set_feedback_alpha(alpha: float) -> void:
	feedback_main.modulate.a = alpha

func _reset_feedback_visuals() -> void:
	feedback_timer = 0.0
	reset_judgment_popup()
	feedback_main.visible = false
	feedback_main.text = ""
	feedback_main.scale = Vector2.ONE
	feedback_main.modulate = Color.WHITE
	feedback_sub.visible = false
	feedback_sub.text = ""

func update_judgment_popup(delta: float) -> void:
	if judgment_timer <= 0.0:
		return
	judgment_timer = maxf(0.0, judgment_timer - delta)
	if judgment_timer <= 0.0 and judgment_popup_tween == null:
		reset_judgment_popup()

func show_judgment_popup(rating: String) -> void:
	if judgment_sprite == null:
		return
	if judgment_popup_tween != null:
		judgment_popup_tween.kill()
		judgment_popup_tween = null
	judgment_sprite.text = rating
	judgment_sprite.add_theme_color_override("font_color", _judgment_color(rating))
	judgment_sprite.visible = true
	judgment_sprite.modulate = Color.WHITE
	judgment_sprite.modulate.a = 0.0
	var target_scale: Vector2 = Vector2.ONE * ui_layout_config.battle_judgment_scale
	var fx_amount: float = clampf(effect_intensity, 0.0, 1.0)
	var pop_scale: Vector2 = target_scale.lerp(target_scale * judgment_pop_start_scale, fx_amount)
	judgment_sprite.scale = pop_scale
	judgment_sprite.position = judgment_rest_position + Vector2(0.0, judgment_enter_offset_y * fx_amount)
	judgment_timer = judgment_display_duration
	var hold_duration := maxf(
		0.0,
		judgment_display_duration - judgment_pop_in_duration - judgment_fade_out_duration
	)
	judgment_popup_tween = create_tween()
	judgment_popup_tween.set_parallel(true)
	judgment_popup_tween.tween_property(judgment_sprite, "position", judgment_rest_position, judgment_pop_in_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	judgment_popup_tween.tween_property(judgment_sprite, "scale", target_scale, judgment_pop_in_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	judgment_popup_tween.tween_property(judgment_sprite, "modulate:a", 1.0, judgment_pop_in_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	judgment_popup_tween.chain().tween_interval(hold_duration)
	judgment_popup_tween.chain().tween_property(judgment_sprite, "position", judgment_rest_position + Vector2(0.0, judgment_exit_offset_y * fx_amount), judgment_fade_out_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	judgment_popup_tween.parallel().tween_property(judgment_sprite, "modulate:a", 0.0, judgment_fade_out_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	judgment_popup_tween.parallel().tween_property(judgment_sprite, "scale", target_scale * 0.98, judgment_fade_out_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	judgment_popup_tween.chain().tween_callback(Callable(self, "_complete_judgment_popup"))

func _complete_judgment_popup() -> void:
	judgment_popup_tween = null
	reset_judgment_popup()

func reset_judgment_popup() -> void:
	judgment_timer = 0.0
	if judgment_popup_tween != null:
		judgment_popup_tween.kill()
		judgment_popup_tween = null
	judgment_sprite.visible = false
	judgment_sprite.text = ""
	judgment_sprite.position = judgment_rest_position
	judgment_sprite.scale = Vector2.ONE * ui_layout_config.battle_judgment_scale
	judgment_sprite.modulate = Color.WHITE

func _judgment_color(rating: String) -> Color:
	match rating:
		"PERFECT": return MinimalThemeScript.PINK
		"GREAT": return MinimalThemeScript.SUCCESS
		"GOOD": return MinimalThemeScript.CYAN
		"MISS": return MinimalThemeScript.DANGER
		_: return MinimalThemeScript.TEXT

func format_time_label(seconds: float) -> String:
	var total: int = maxi(0, int(floor(seconds)))
	var minutes: int = floori(float(total) / 60.0)
	var secs: int = total % 60
	return "%02d:%02d" % [minutes, secs]

func update_hud() -> void:
	var duration: float = get_song_duration()
	var hud_source: Dictionary = level_data
	if hud_source.is_empty() and not selected_song_id.is_empty():
		hud_source = get_song_representative(selected_song_id)

	combo_digits.set_value(combo)
	score_digits.set_value(score)
	combo_label.visible = combo > 0
	var judged: int = perfect_hits + great_hits + get_good_hits() + total_misses
	var live_accuracy: float = 100.0 if judged <= 0 else calculate_accuracy_from_counts(perfect_hits, great_hits, get_good_hits(), total_misses)
	accuracy_label.text = "%.2f%%" % live_accuracy

	song_title_label.text = str(hud_source.get("title", selected_song_id.to_upper() if not selected_song_id.is_empty() else "SONG"))
	bpm_label.text = "%d BPM" % int(round(float(hud_source.get("bpm", get_bpm()))))
	difficulty_label.text = str(hud_source.get("difficulty", hud_source.get("chart_difficulty", "NORMAL"))).to_upper()
	difficulty_label.text += "  ·  %s" % ("4K" if input_style == "4_arrow" else "8K")
	if random_mode_enabled:
		difficulty_label.text += "  ·  RND"
	if practice_mode_active:
		difficulty_label.text += "  ·  PRACTICE"
	elif replay_playback_active:
		difficulty_label.text += "  ·  REPLAY"
	duration_label.text = "%s / %s" % [
		format_time_label(fight_time),
		format_time_label(duration),
	]
	duration_bar.max_value = maxf(0.001, duration)
	duration_bar.value = clampf(fight_time, 0.0, duration)



func handle_space_prompt_input(input_time: float) -> void:
	var target: float = get_current_space_time()
	if target < 0.0:
		return
	var offset: float = input_time - target
	var distance: float = absf(offset)
	if distance <= gameplay_config.space_good_window:
		register_space_hit(distance, offset)
		return
	if offset < -gameplay_config.space_good_window:
		show_feedback("SPACE EARLY", "Hit Space as the approach ring closes.", theme_config.text_secondary, 0.16)
	else:
		consume_late_space_events(input_time)

func register_space_hit(distance: float, signed_offset_s: float = 0.0) -> void:
	var rating: String = ScoreProcessor.judgement(distance, gameplay_config.space_perfect_window, gameplay_config.space_great_window)

	space_hits += 1
	if rating == "PERFECT":
		space_perfects += 1
	var rating_multiplier: float = get_space_rating_multiplier(rating)
	var combo_multiplier: float = get_combo_multiplier(combo)
	var space_score: int = ScorePolicy.space_award(
		gameplay_config.space_base_score,
		combo_multiplier,
		rating_multiplier,
		gameplay_config.score_scale_multiplier
	)
	score = ScorePolicy.accumulate(score, space_score)
	var telemetry_space_index: int = current_space_index
	var telemetry_space_target: float = get_current_space_time()
	playtest_telemetry.record_space_judgement(
		telemetry_space_index,
		telemetry_space_target,
		rating,
		signed_offset_s * 1000.0,
		false,
		combo,
		score
	)
	advance_space_index()
	play_hit_sfx()
	show_judgment_popup(rating)
	track.play_hit_feedback(rating)

func register_space_miss() -> void:
	var telemetry_space_index: int = current_space_index
	var telemetry_space_target: float = get_current_space_time()
	play_miss_sfx()
	space_misses += 1
	playtest_telemetry.record_space_judgement(
		telemetry_space_index,
		telemetry_space_target,
		"MISS",
		null,
		true,
		combo,
		score
	)
	advance_space_index()
	show_judgment_popup("MISS")
	track.play_hit_feedback("MISS")

func get_combo_multiplier(combo_count: int) -> float:
	return gameplay_config.get_combo_multiplier(combo_count)

func get_space_rating_multiplier(rating: String) -> float:
	return gameplay_config.get_space_rating_multiplier(rating)


func _begin_playtest_session() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	playtest_telemetry.begin_session(
		level_data,
		input_style,
		random_mode_enabled,
		user_input_offset_ms,
		user_audio_offset_ms,
		get_chart_target_offset_seconds(),
		viewport_size
	)


func _telemetry_input_label(keycode: int) -> String:
	match keycode:
		KEY_KP_1: return "NUM1"
		KEY_KP_2: return "NUM2"
		KEY_KP_3: return "NUM3"
		KEY_KP_4: return "NUM4"
		KEY_KP_5: return "NUM5"
		KEY_KP_6: return "NUM6"
		KEY_KP_7: return "NUM7"
		KEY_KP_8: return "NUM8"
		KEY_KP_9: return "NUM9"
		KEY_LEFT: return "LEFT"
		KEY_RIGHT: return "RIGHT"
		KEY_UP: return "UP"
		KEY_DOWN: return "DOWN"
		KEY_SPACE: return "SPACE"
		_: return ""


func _exit_tree() -> void:
	if playtest_telemetry != null:
		playtest_telemetry.abort_session("application_exit")


func get_current_note() -> RhythmNote:
	advance_note_cursor()
	if current_note_index < 0 or current_note_index >= stream_notes.size():
		return null
	var candidate: Variant = stream_notes[current_note_index]
	if not is_instance_valid(candidate):
		return null
	return candidate as RhythmNote

func get_raw_music_time() -> float:
	if music_has_finished:
		return maxf(0.0, get_music_time() + user_audio_offset_ms / 1000.0)
	var sampled_raw_time := RhythmTimingScript.get_raw_audio_time(music, fight_time)
	var stable_raw_time := RhythmTimingScript.stabilize_monotonic_audio_time(
		sampled_raw_time,
		runtime_raw_music_time_s,
		runtime_audio_clock_initialized
	)
	runtime_raw_music_time_s = stable_raw_time
	runtime_audio_clock_initialized = true
	return stable_raw_time

func get_music_time() -> float:
	# Canonical gameplay clock. Notes, SPACE, progress, late-note consumption,
	# and judgment all use this exact song time. User audio compensation is
	# applied here once, rather than being scattered through gameplay code.
	if music_has_finished:
		var tail_elapsed_s: float = maxf(0.0, _monotonic_clock_s() - music_finished_clock_s)
		return maxf(0.0, music_finished_song_time + tail_elapsed_s)
	return RhythmTimingScript.get_gameplay_song_time_from_raw(get_raw_music_time(), user_audio_offset_ms)

func _reset_runtime_timing_state() -> void:
	runtime_raw_music_time_s = 0.0
	runtime_audio_clock_initialized = false
	pause_raw_music_snapshot_s = 0.0
	pause_timing_snapshot_valid = false
	resume_timing_check_pending = false
	last_resume_clock_delta_ms = 0.0

func _capture_pause_timing_snapshot() -> void:
	if music == null or not music.playing:
		pause_timing_snapshot_valid = false
		return
	pause_raw_music_snapshot_s = get_raw_music_time()
	pause_timing_snapshot_valid = true
	resume_timing_check_pending = false

func _check_resume_timing_continuity() -> void:
	resume_timing_check_pending = false
	if not pause_timing_snapshot_valid:
		return
	var resumed_raw_time := get_raw_music_time()
	last_resume_clock_delta_ms = (resumed_raw_time - pause_raw_music_snapshot_s) * 1000.0
	pause_timing_snapshot_valid = false
	if absf(last_resume_clock_delta_ms) > RhythmTimingScript.RESUME_WARNING_THRESHOLD_MS:
		push_warning("Beat UP! timing QA: pause/resume clock delta %.1f ms" % last_resume_clock_delta_ms)
	if timing_debug_visible:
		update_timing_debug()

func _monotonic_clock_s() -> float:
	return float(Time.get_ticks_usec()) / 1000000.0

func get_chart_target_offset_seconds() -> float:
	# Event timestamps in authored/generated JSON are already absolute song
	# times. beat_offset is analysis metadata and must not be applied again. A
	# chart may optionally provide chart_offset_ms for authored fine tuning.
	var authored_offset_ms: float = float(level_data.get("chart_offset_ms", 0.0))
	return (chart_sync_offset_ms + authored_offset_ms) / 1000.0

func _record_timing_delta(raw_song_time: float, compensated_input_time: float, target_time: float) -> void:
	last_raw_hit_delta_ms = (raw_song_time - target_time) * 1000.0
	last_compensated_hit_delta_ms = (compensated_input_time - target_time) * 1000.0
	if timing_debug_visible:
		update_timing_debug()

func update_timing_debug() -> void:
	if timing_debug_label == null:
		return
	timing_debug_label.visible = timing_debug_visible
	if not timing_debug_visible:
		return
	var raw_time: float = get_raw_music_time()
	var song_time: float = get_music_time()
	timing_debug_label.text = "TIMING DEBUG [F3]\nRAW %.3f  SONG %.3f\nINPUT %s  AUDIO %s\nLAST RAW %+0.1f ms  COMP %+0.1f ms\nRESUME %+0.1f ms" % [
		raw_time,
		song_time,
		RhythmTimingScript.format_offset_ms(user_input_offset_ms),
		RhythmTimingScript.format_offset_ms(user_audio_offset_ms),
		last_raw_hit_delta_ms,
		last_compensated_hit_delta_ms,
		last_resume_clock_delta_ms,
	]

func get_song_duration() -> float:
	# Runtime audio length is authoritative. Chart duration remains useful metadata,
	# but a stale JSON duration must never terminate a song early.
	if music != null and music.stream != null:
		var stream_length := float(music.stream.get_length())
		if stream_length > 0.0:
			return stream_length
	return float(level_data.get("duration", 0.0))

func get_bpm() -> float:
	return float(level_data.get("bpm", 120.0))


func get_travel_time() -> float:
	return gameplay_config.get_travel_time(get_bpm())

func _reset_runtime_direction_state() -> void:
	last_runtime_direction = -1
	repeated_runtime_direction = 0
	deterministic_direction_cursor = 0
	deterministic_direction_seed = compute_deterministic_direction_seed()
	deterministic_direction_history.clear()

func _prepare_runtime_direction_layouts(chart_events: Array) -> void:
	authored_direction_cache.clear()
	four_key_layout_cache.clear()
	runtime_chart_identity = "%s::%s" % [
		str(level_data.get("song_id", level_data.get("id", selected_song_id))),
		str(level_data.get("chart_difficulty", level_data.get("difficulty", "normal"))).to_lower(),
	]

	# Stamp a runtime-only stable index into the duplicated level_data. The source
	# JSON is never touched, and ChartTimeline preserves this field in its duplicate.
	for event_index in range(chart_events.size()):
		var raw_event: Variant = chart_events[event_index]
		if not (raw_event is Dictionary):
			continue
		var event_data := raw_event as Dictionary
		event_data["_runtime_event_index"] = event_index
		var authored_number := int(event_data.get("direction", 0))
		if authored_number not in [1, 2, 3, 4, 6, 7, 8, 9]:
			# Legacy authoring should already have repaired this, but keep a stable
			# fallback so malformed imported data still cannot mutate between plays.
			authored_number = _stable_authored_fallback_number(event_data, event_index)
		event_data["direction"] = authored_number
		authored_direction_cache[event_index] = authored_number

	# Precompute the 4K projection once from the authored 8K layout. This makes
	# 8K -> 4K -> 8K and Retry completely invariant while keeping 4K readable.
	var projection_history: Array[int] = []
	for event_index in range(chart_events.size()):
		if not authored_direction_cache.has(event_index):
			continue
		var event_data := chart_events[event_index] as Dictionary
		var authored_number := int(authored_direction_cache[event_index])
		var mapped_number := _project_authored_number_to_four_key(authored_number, event_data, event_index, projection_history)
		four_key_layout_cache[event_index] = mapped_number
		projection_history.append(mapped_number)
		if projection_history.size() > 12:
			projection_history.pop_front()

func _stable_authored_fallback_number(event_data: Dictionary, event_index: int) -> int:
	var valid := [1, 2, 3, 4, 6, 7, 8, 9]
	var stamp := int(round(float(event_data.get("time", 0.0)) * 1000.0))
	var direction_seed := _stable_runtime_hash(runtime_chart_identity) + stamp * 17 + event_index * 131
	return int(valid[posmod(direction_seed, valid.size())])

func _project_authored_number_to_four_key(authored_number: int, event_data: Dictionary, event_index: int, history: Array[int]) -> int:
	if authored_number in [2, 4, 6, 8]:
		return authored_number
	var options: Array[int] = []
	match authored_number:
		1: options = [4, 2]
		3: options = [6, 2]
		7: options = [4, 8]
		9: options = [6, 8]
		_: options = [8, 2]

	var stamp := int(round(float(event_data.get("time", 0.0)) * 1000.0))
	var base_seed := _stable_runtime_hash(runtime_chart_identity) + event_index * 977 + stamp * 13 + authored_number * 53
	var best_option := int(options[0])
	var best_score := -INF
	for option_value in options:
		var option := int(option_value)
		var noise_value := absf(sin(float(base_seed + option * 193) * 0.01337) * 43758.5453)
		var candidate_score := noise_value - floorf(noise_value)
		var n := history.size()
		if n >= 1 and history[n - 1] == option:
			candidate_score -= 3.0
		if n >= 2 and history[n - 2] == option:
			candidate_score -= 0.85
		if n >= 3 and history[n - 3] == option and history[n - 1] == option:
			candidate_score -= 1.4
		if candidate_score > best_score:
			best_score = candidate_score
			best_option = option
	return best_option

func _stable_four_direction_fallback(event_data: Dictionary, runtime_index: int) -> Dictionary:
	var authored_number := int(event_data.get("direction", 8))
	var empty_history: Array[int] = []
	var projected := _project_authored_number_to_four_key(authored_number, event_data, runtime_index, empty_history)
	return _four_direction_by_number(projected)

func _stable_runtime_hash(value: String) -> int:
	var result := 216613626
	for i in range(value.length()):
		result = posmod((result ^ value.unicode_at(i)) * 16777619, 2147483629)
	return result

func compute_deterministic_direction_seed() -> int:
	var source: String = "%s:%s" % [selected_song_id, str(level_data.get("chart_difficulty", level_data.get("difficulty", "normal"))).to_lower()]
	var seed_value: int = 17
	for i in range(source.length()):
		seed_value = posmod(seed_value * 31 + source.unicode_at(i), 2147483629)
	return seed_value

func pick_deterministic_fallback_direction() -> Dictionary:
	if DIRECTIONS.is_empty():
		return {}
	var best_index: int = 0
	var best_score: float = -999999.0
	for i in range(DIRECTIONS.size()):
		var direction: int = int(DIRECTIONS[i]["number"])
		var noise_value: float = absf(sin(float(deterministic_direction_seed + 1) * 0.000137 + float(deterministic_direction_cursor + 1) * 12.9898 + float(direction) * 78.233) * 43758.5453)
		var candidate_score: float = noise_value - floorf(noise_value)
		var recent_count: int = 0
		for history_index in range(maxi(0, deterministic_direction_history.size() - 12), deterministic_direction_history.size()):
			if deterministic_direction_history[history_index] == direction:
				recent_count += 1
		candidate_score -= float(recent_count) * 0.58
		var n: int = deterministic_direction_history.size()
		if n >= 1 and deterministic_direction_history[n - 1] == direction:
			candidate_score -= 1000.0
		if n >= 5 and deterministic_direction_history[n - 5] == deterministic_direction_history[n - 3] and deterministic_direction_history[n - 3] == deterministic_direction_history[n - 1] and deterministic_direction_history[n - 4] == deterministic_direction_history[n - 2] and direction == deterministic_direction_history[n - 4]:
			candidate_score -= 1000.0
		if n >= 7:
			var repeats_four: bool = true
			for offset in range(3):
				if deterministic_direction_history[n - 7 + offset] != deterministic_direction_history[n - 3 + offset]:
					repeats_four = false
					break
			if repeats_four and deterministic_direction_history[n - 4] == direction:
				candidate_score -= 1000.0
		if candidate_score > best_score:
			best_score = candidate_score
			best_index = i
	deterministic_direction_cursor += 1
	var picked: Dictionary = DIRECTIONS[best_index] as Dictionary
	deterministic_direction_history.append(int(picked["number"]))
	if deterministic_direction_history.size() > 24:
		deterministic_direction_history.pop_front()
	return picked

func pick_runtime_direction() -> Dictionary:
	# Keep arrows unpredictable between plays, but avoid ugly 3+ identical runs.
	var pool: Array = FOUR_DIRECTIONS if input_style == "4_arrow" else DIRECTIONS
	var index: int = arrow_rng.randi_range(0, pool.size() - 1)
	var number: int = int(pool[index]["number"])
	if number == last_runtime_direction and repeated_runtime_direction >= 1:
		var alternatives: Array[int] = []
		for i in range(pool.size()):
			if int(pool[i]["number"]) != last_runtime_direction:
				alternatives.append(i)
		index = alternatives[arrow_rng.randi_range(0, alternatives.size() - 1)]
		number = int(pool[index]["number"])

	if number == last_runtime_direction:
		repeated_runtime_direction += 1
	else:
		last_runtime_direction = number
		repeated_runtime_direction = 0
	return pool[index] as Dictionary

func get_direction_by_number(number: int) -> Dictionary:
	for direction in DIRECTIONS:
		if int(direction["number"]) == number:
			return direction
	return DIRECTIONS[6]

func get_direction_by_key(key: int) -> Dictionary:
	for direction in DIRECTIONS:
		if int(direction["key"]) == key:
			return direction
	for direction in FOUR_DIRECTIONS:
		if int(direction["key"]) == key:
			return direction
	if input_style == "4_arrow":
		return FOUR_DIRECTIONS[0] as Dictionary
	return DIRECTIONS[0] as Dictionary

# Stateful 4K remapping was removed in v17.4.5.2. 4K layouts are now
# precomputed by _prepare_runtime_direction_layouts() and remain invariant across
# mode switches, retries, and repeated plays while RANDOM is disabled.

func _four_direction_by_number(number: int) -> Dictionary:
	for direction in FOUR_DIRECTIONS:
		if int(direction["number"]) == number:
			return direction as Dictionary
	return FOUR_DIRECTIONS[1] as Dictionary

func get_opposite_key(key: int) -> int:
	match key:
		KEY_KP_1: return KEY_KP_9
		KEY_KP_2: return KEY_KP_8
		KEY_KP_3: return KEY_KP_7
		KEY_KP_4: return KEY_KP_6
		KEY_KP_6: return KEY_KP_4
		KEY_KP_7: return KEY_KP_3
		KEY_KP_8: return KEY_KP_2
		KEY_KP_9: return KEY_KP_1
		KEY_LEFT: return KEY_RIGHT
		KEY_RIGHT: return KEY_LEFT
		KEY_UP: return KEY_DOWN
		KEY_DOWN: return KEY_UP
	return KEY_NONE

func get_pressed_gameplay_key(event: InputEventKey) -> int:
	if input_style == "4_arrow":
		var four_map: Array[Dictionary] = [
			{"action": "4k_left", "key": KEY_LEFT},
			{"action": "4k_up", "key": KEY_UP},
			{"action": "4k_right", "key": KEY_RIGHT},
			{"action": "4k_down", "key": KEY_DOWN},
		]
		for row: Dictionary in four_map:
			if _event_matches_run_binding(event, str(row.get("action", ""))):
				return int(row.get("key", KEY_NONE))
		return KEY_NONE
	return get_pressed_numpad_key(event)

func get_pressed_numpad_key(event: InputEventKey) -> int:
	var eight_map: Array[Dictionary] = [
		{"action": "8k_1", "key": KEY_KP_1}, {"action": "8k_2", "key": KEY_KP_2},
		{"action": "8k_3", "key": KEY_KP_3}, {"action": "8k_4", "key": KEY_KP_4},
		{"action": "8k_6", "key": KEY_KP_6}, {"action": "8k_7", "key": KEY_KP_7},
		{"action": "8k_8", "key": KEY_KP_8}, {"action": "8k_9", "key": KEY_KP_9},
	]
	for row: Dictionary in eight_map:
		if _event_matches_run_binding(event, str(row.get("action", ""))):
			return int(row.get("key", KEY_NONE))
	return KEY_NONE

func _capture_run_input_binding_snapshot() -> void:
	var snapshot: Dictionary = UserSettingsScript.create_gameplay_input_snapshot()
	var bindings_value: Variant = snapshot.get("bindings", {})
	var bindings: Dictionary = bindings_value as Dictionary if bindings_value is Dictionary else {}
	run_input_binding_snapshot = {
		"input_style": str(snapshot.get("input_style", UserSettingsScript.DEFAULT_INPUT_STYLE)),
		"bindings": bindings.duplicate(true),
	}
	input_style = str(run_input_binding_snapshot.get("input_style", UserSettingsScript.DEFAULT_INPUT_STYLE))
	if track != null:
		track.set_input_style(input_style)

func get_run_input_binding_snapshot() -> Dictionary:
	return run_input_binding_snapshot.duplicate(true)

func _event_matches_run_binding(event: InputEventKey, action: String) -> bool:
	var bindings_value: Variant = run_input_binding_snapshot.get("bindings", {})
	if not (bindings_value is Dictionary):
		return false
	var expected: int = int((bindings_value as Dictionary).get(action, KEY_NONE))
	return expected != KEY_NONE and (event.keycode == expected or event.physical_keycode == expected)

func is_numpad_key(event: InputEventKey, expected_key: int) -> bool:
	return event.keycode == expected_key or event.physical_keycode == expected_key


# Gameplay is persistent inside AppShell. Launch data is applied by
# launch_from_app_shell(); these hooks only expose lifecycle state to the shell.
func shell_will_resume(_context: Dictionary) -> void:
	pass

func shell_did_resume(_context: Dictionary) -> void:
	pass

func shell_will_suspend(_context: Dictionary) -> void:
	pass

func shell_did_suspend(_context: Dictionary) -> void:
	pass

func _report_runtime(category: String, message: String, context: Dictionary = {}) -> void:
	var guard: Node = get_node_or_null("/root/RuntimeGuard")
	if guard != null and guard.has_method("report"):
		guard.call("report", category, message, context)
