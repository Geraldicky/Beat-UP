extends Control
const ScoreIdentity = preload("res://scripts/score_identity.gd")
const RuntimeResourceAccessScript = preload("res://scripts/runtime_resource_access.gd")

const ThemeConfigScript = preload("res://config/theme_config.gd")
const LayoutConfigScript = preload("res://config/ui_layout_config.gd")
const MinimalThemeScript = preload("res://scripts/ui/minimal_theme.gd")
const InteractionPolishScript = preload("res://scripts/ui/interaction_polish.gd")
const UserSettingsScript = preload("res://scripts/user_settings.gd")
const ProgressInsightsScript = preload("res://scripts/v18/progress_insights.gd")
const ProgressGraphScript = preload("res://scripts/v18/progress_graph.gd")
const AnimatedMarginScript = preload("res://scripts/ui/animated_margin_container.gd")
const SongBannerButtonScript = preload("res://scripts/ui/song_banner_button.gd")
const SongLibraryAmbientScript = preload("res://scripts/ui/song_library_ambient.gd")
const LevelPackScript = preload("res://scripts/level_pack.gd")
const SONG_BACKGROUND_ROOT := "res://assets/song_backgrounds"
const SONG_THUMBNAIL_ROOT := "res://assets/song_thumbnails"
const LIBRARY_ACCENT := Color("8ea8ff")
const LIBRARY_ACCENT_HOVER := Color("a6b9ff")

signal play_requested(song_id: String, difficulty_id: String, random_mode: bool)
signal practice_requested(song_id: String, difficulty_id: String, random_mode: bool, section_index: int)
signal replay_requested(song_id: String, difficulty_id: String, random_mode: bool, replay_data: Dictionary)
signal back_requested
signal chart_editor_requested
signal import_charts_requested(paths: PackedStringArray)
signal refresh_requested

@export var theme_config: ThemeConfigScript
@export var layout_config: LayoutConfigScript

@onready var main_margin: MarginContainer = %MainMargin
@onready var root_vbox: VBoxContainer = %RootVBox
@onready var header_row: HBoxContainer = %HeaderRow
@onready var filters: HBoxContainer = %Filters
@onready var body: HBoxContainer = %Body
@onready var info_panel: PanelContainer = %InfoPanel
@onready var info_vbox: VBoxContainer = %InfoVBox
@onready var wheel_column: VBoxContainer = %WheelColumn
@onready var library_panel: PanelContainer = %LibraryPanel
@onready var filters_panel: PanelContainer = %FiltersPanel
@onready var footer_panel: PanelContainer = %FooterPanel
@onready var footer: HBoxContainer = %Footer
@onready var title_label: Label = %TitleLabel
@onready var count_label: Label = %CountLabel
@onready var search_input: LineEdit = %SearchInput
@onready var artist_filter = %ArtistFilter
@onready var difficulty_filter = %DifficultyFilter
@onready var progress_filter = %ProgressFilter
@onready var sort_filter = %SortFilter
@onready var song_scroll: ScrollContainer = %SongScroll
@onready var song_list: VBoxContainer = %SongList
@onready var detail_title: Label = %DetailTitle
@onready var detail_meta: Label = %DetailMeta
@onready var detail_description: Label = %DetailDescription
@onready var detail_flavor: Label = %DetailFlavor
@onready var selection_index: Label = %SelectionIndex
@onready var mode_status: Label = %ModeStatus
@onready var song_visual: Control = %SongVisual
@onready var backdrop_visual: Control = %BackdropVisual
@onready var preview_player: SongPreviewController = %PreviewPlayer
@onready var hero_panel: PanelContainer = %HeroPanel
@onready var quick_stats: HBoxContainer = %QuickStats
@onready var bpm_value: Label = %BpmValue
@onready var duration_value: Label = %DurationValue
@onready var notes_value: Label = %NotesValue
@onready var rank_label: Label = %BestRank
@onready var best_stats_label: Label = %BestStats
@onready var best_card: PanelContainer = %PersonalBestCard
@onready var best_caption: Label = %BestCaption
@onready var best_subcaption: Label = %BestSubcaption
@onready var best_rank_caption: Label = %BestRankCaption
@onready var best_grid: GridContainer = %BestGrid
@onready var best_header: HBoxContainer = %BestHeader
@onready var progress_status: Label = %ProgressStatus
@onready var info_tabs: HBoxContainer = %InfoTabs
@onready var details_tab_button: Button = %DetailsTabButton
@onready var ranking_tab_button: Button = %RankingTabButton
@onready var ranking_context: Label = %RankingContext
@onready var details_panel: PanelContainer = %DetailsPanel
@onready var details_title: Label = %DetailsTitle
@onready var details_status: Label = %DetailsStatus
@onready var breakdown_grid: GridContainer = %BreakdownGrid
@onready var normal_notes_value: Label = %NormalNotesValue
@onready var reverse_notes_value: Label = %ReverseNotesValue
@onready var space_notes_value: Label = %SpaceNotesValue
@onready var details_footer: Label = %DetailsFooter
@onready var best_score_value: Label = %BestScoreValue
@onready var best_accuracy_value: Label = %BestAccuracyValue
@onready var best_combo_value: Label = %BestComboValue
@onready var best_plays_value: Label = %BestPlaysValue
@onready var action_row: HBoxContainer = %ActionRow
@onready var mods_button: Button = %ModsButton
@onready var mods_overlay: Control = %ModsOverlay
@onready var mods_dim: ColorRect = %ModsDim
@onready var mods_panel: PanelContainer = %ModsPanel
@onready var mods_title: Label = %ModsTitle
@onready var mods_subtitle: Label = %ModsSubtitle
@onready var mode_section: Label = %ModeSection
@onready var modifier_section: Label = %ModifierSection
@onready var mode_8_button: Button = %Mode8Button
@onready var mode_4_button: Button = %Mode4Button
@onready var random_mod_button: Button = %RandomModButton
@onready var mods_summary_label: Label = %ModsSummary
@onready var mods_close_button: Button = %ModsCloseButton
@onready var play_button: Button = %PlayButton
@onready var import_button: Button = %ImportButton
@onready var refresh_button: Button = %RefreshButton
@onready var editor_button: Button = %EditorButton
@onready var pack_export_button: Button = %PackExportButton
@onready var back_button: Button = %BackButton
@onready var import_hint: Label = %ImportHint
@onready var wheel_mode_label: Label = %WheelModeLabel
@onready var library_hint: Label = %LibraryHint
@onready var footer_status: Label = %FooterStatus
@onready var transition_overlay: ColorRect = %TransitionOverlay
# The custom picker is supplied by the scene.  Avoid depending on Godot's
# global script-class cache during the first project scan after patching.
@onready var import_dialog = %ImportDialog
@onready var now_playing_card: Panel = %NowPlayingCard
@onready var now_playing_kicker: Label = %NowPlayingKicker
@onready var now_playing_title: Label = %NowPlayingTitle
@onready var now_playing_artist: Label = %NowPlayingArtist
@onready var track_progress_bar: ProgressBar = %TrackProgressBar
@onready var now_playing_duration_value: Label = %NowPlayingDurationValue
@onready var prev_track_button: Button = %PrevTrackButton
@onready var play_pause_track_button: Button = %PlayPauseTrackButton
@onready var next_track_button: Button = %NextTrackButton

var levels: Array = []
var best_stats: Dictionary = {}
var song_ids: Array[String] = []
var filtered_song_ids: Array[String] = []
var selected_song_id := ""
var selected_difficulty := "normal"
var selected_artist_filter := "All Artists"
var selected_difficulty_filter := "All Difficulties"
var selected_progress_filter := "All Progress"
var selected_sort_mode := "BPM Asc"
var selected_search_query := ""
var random_mode_enabled := false
var song_buttons: Array[Button] = []
var song_groups: Array = []
var song_header_wrappers: Array = []
var song_difficulty_clips: Array = []
var song_difficulty_boxes: Array = []
var song_difficulty_rows: Array = []
var song_hovered: Dictionary = {}
var difficulty_hovered: Dictionary = {}
var selection_animation_generation := 0
var selection_motion_elapsed := 1.0
var intro_tween: Tween
var selection_tween: Tween
var scroll_tween: Tween
var transition_tween: Tween
var info_tween: Tween
var transitioning_out := false
var song_margin_velocity: Dictionary = {}
var difficulty_margin_velocity: Dictionary = {}
var scroll_target := -1.0
var applying_scroll_target := false
var detail_transition_generation := 0
var background_texture_cache: Dictionary = {}
var selected_info_tab: String = "ranking"
var run_picker: BeatDropdown
var record_rows: Array = []
var selected_record: int = 0
var record_context: String = ""
var export_button: Button
var v18_mode_row: HBoxContainer
var practice_button: Button
var replay_button: Button
var practice_popup
var rank_sort_button: Button
var rank_sort_mode: String = "score"
var progress_graph: Control
var progress_insight_label: Label
# v18.0.0.1: osu-inspired local ranking controls. Ranking scope is local only,
# while the mods filter is independent from the active gameplay mods.
var ranking_filter_row: HBoxContainer
var ranking_scope_label: Label
var ranking_mods_filter: BeatDropdown
var ranking_scroll: ScrollContainer
var ranking_list: VBoxContainer
var ranking_input_style: String = "8_direction"
var ranking_random_mode: bool = false
var details_modern_root: VBoxContainer
var details_field_labels: Dictionary = {}
var composition = preload("res://scripts/ui/library_composition.gd").new()
var details_notes_label: Label
var ranking_tab_tools: HBoxContainer
var ranking_mods_label: Label
var album_flow_showcase_row: HBoxContainer
var album_flow_center_column: VBoxContainer
var album_flow_sidebar: VBoxContainer
var album_flow_artwork_slot: HBoxContainer
var album_flow_artwork: TextureRect
var album_flow_detail_backdrop: TextureRect
var album_flow_detail_veil: ColorRect
var album_flow_ambient: Control
var album_flow_divider: ColorRect
var album_flow_bottom_panel: PanelContainer
var album_flow_play_row: HBoxContainer
var album_flow_difficulty_row: HBoxContainer
var album_flow_difficulty_caption: Label
var album_flow_best_card: PanelContainer
var album_flow_score_cluster: VBoxContainer
var album_flow_best_caption_value: Label
var album_flow_best_rank_value: Label
var album_flow_best_score_value: Label
var album_flow_best_combo_value: Label
var album_flow_best_accuracy_value: Label
var album_flow_modifier_row: HBoxContainer
var album_flow_random_button: Button
var album_flow_mode_row: HBoxContainer
var album_flow_mode_4_button: Button
var album_flow_mode_8_button: Button
var album_flow_sidebar_spacer: Control
var album_flow_detail_top_spacer: Control
var album_flow_header_spacer: Control
var album_flow_list_spacer: Control
var album_flow_filter_tabs: HBoxContainer
var album_flow_filter_button: Button
var album_flow_bpm_button: Button
var album_flow_record_panel: PanelContainer
var album_flow_record_breakdown_row: HBoxContainer
var album_flow_record_perfect_value: Label
var album_flow_record_great_value: Label
var album_flow_record_good_value: Label
var album_flow_record_miss_value: Label
var album_flow_list_header: HBoxContainer
var album_flow_meta_line: Label
var album_flow_prev_song_button: Button
var album_flow_next_song_button: Button
var album_flow_center_divider: ColorRect


func _ready() -> void:
	if theme_config == null:
		theme_config = ThemeConfigScript.new()
	if layout_config == null:
		layout_config = LayoutConfigScript.new()
	MinimalThemeScript.apply_root(self)
	search_input.text_changed.connect(_on_search_changed)
	artist_filter.item_selected.connect(_on_artist_filter_changed)
	difficulty_filter.item_selected.connect(_on_difficulty_filter_changed)
	progress_filter.item_selected.connect(_on_progress_filter_changed)
	sort_filter.item_selected.connect(_on_sort_filter_changed)
	details_tab_button.pressed.connect(_on_details_tab_pressed)
	ranking_tab_button.pressed.connect(_on_ranking_tab_pressed)
	play_button.pressed.connect(_play_selected_chart)
	mods_button.pressed.connect(_open_mods_panel)
	mods_close_button.pressed.connect(_close_mods_panel)
	mods_dim.gui_input.connect(_on_mods_dim_gui_input)
	mode_8_button.pressed.connect(_on_mode_8_selected)
	mode_4_button.pressed.connect(_on_mode_4_selected)
	random_mod_button.toggled.connect(_on_random_mod_toggled)
	import_button.pressed.connect(_open_import_dialog)
	refresh_button.pressed.connect(func(): refresh_requested.emit())
	editor_button.pressed.connect(_on_editor_pressed)
	pack_export_button.pressed.connect(_export_selected_level_pack)
	back_button.pressed.connect(_on_back_pressed)
	import_dialog.files_selected.connect(func(paths: PackedStringArray): import_charts_requested.emit(paths))
	_build_v18_details_controls()
	_build_record_controls()
	_build_v18_action_controls()
	_build_v18_progress_controls()
	composition.install(self)
	# Details stays available in the scene/source for creator work, but the
	# player-facing library exposes one unambiguous Ranking surface.
	details_tab_button.visible = false
	details_tab_button.disabled = true
	details_panel.visible = false
	# v18.7 makes local song creation a supported player feature. The legacy
	# creator_tools setting remains accepted for older project overrides.
	var creator_tools_available: bool = bool(ProjectSettings.get_setting("beat_up/player_creator_enabled", true)) or bool(ProjectSettings.get_setting("beat_up/creator_tools_enabled", true))
	import_button.visible = creator_tools_available
	editor_button.visible = creator_tools_available
	refresh_button.visible = creator_tools_available
	pack_export_button.visible = creator_tools_available
	_setup_home_style_now_playing()
	var song_scrollbar: VScrollBar = song_scroll.get_v_scroll_bar()
	if song_scrollbar != null and not song_scrollbar.value_changed.is_connected(_on_song_scroll_value_changed):
		song_scrollbar.value_changed.connect(_on_song_scroll_value_changed)
	_apply_layout_config()
	_apply_theme_config()
	composition.apply(self)
	InteractionPolishScript.install_buttons([back_button, mods_button, practice_button, replay_button, play_button, details_tab_button, ranking_tab_button, import_button, refresh_button, editor_button, pack_export_button])
	_set_info_tab(selected_info_tab, false)
	_sync_mods_panel(false)
	_rebuild_filters()
	_rebuild_song_list()
	_update_detail(false)
	transition_overlay.modulate.a = 0.0
	if not resized.is_connected(_apply_layout_config):
		resized.connect(_apply_layout_config)
	call_deferred("_animate_enter")

func _music_session() -> Node:
	return get_node_or_null("/root/MusicSession")

func _setup_home_style_now_playing() -> void:
	prev_track_button.pressed.connect(_on_now_playing_previous)
	play_pause_track_button.pressed.connect(_on_now_playing_play_pause)
	next_track_button.pressed.connect(_on_now_playing_next)
	var session: Node = _music_session()
	if session != null:
		var callback := Callable(self, "_on_now_playing_session_changed")
		if session.has_signal("track_changed") and not session.is_connected("track_changed", callback):
			session.connect("track_changed", callback)
		if session.has_signal("playback_state_changed") and not session.is_connected("playback_state_changed", callback):
			session.connect("playback_state_changed", callback)
	_update_home_style_now_playing_card()

func _layout_home_style_now_playing() -> void:
	var viewport_size: Vector2 = size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return
	var reference_scale: float = minf(viewport_size.x / 1440.0, viewport_size.y / 900.0)
	var now_playing_height: float = clampf(38.0 * reference_scale, 36.0, 42.0)
	now_playing_card.position = Vector2(0.0, 0.0)
	now_playing_card.size = Vector2(viewport_size.x, now_playing_height)
	now_playing_card.pivot_offset = Vector2(viewport_size.x * 0.5, now_playing_height * 0.5)
	track_progress_bar.custom_minimum_size = Vector2(clampf(viewport_size.x * 0.22, 260.0, 420.0), 4.0)
	now_playing_duration_value.custom_minimum_size = Vector2(96.0, 0.0)

func _on_now_playing_session_changed(_state: Dictionary) -> void:
	_update_home_style_now_playing_card()

func _update_home_style_now_playing_card() -> void:
	var session: Node = _music_session()
	var state: Dictionary = {}
	if session != null and session.has_method("get_state"):
		var value: Variant = session.call("get_state")
		if value is Dictionary:
			state = value as Dictionary
	if state.is_empty() or str(state.get("audio", "")).is_empty():
		now_playing_title.text = "NO TRACK"
		now_playing_artist.text = ""
	else:
		now_playing_title.text = str(state.get("title", "NO TRACK"))
		var artist: String = str(state.get("artist", "")).strip_edges()
		now_playing_artist.text = "— " + artist if not artist.is_empty() else ""
	var paused: bool = bool(state.get("paused", false))
	prev_track_button.text = ""
	play_pause_track_button.text = ""
	next_track_button.text = ""
	if prev_track_button.has_method("set_icon_mode"):
		prev_track_button.call("set_icon_mode", "previous")
	if play_pause_track_button.has_method("set_icon_mode"):
		play_pause_track_button.call("set_icon_mode", "play" if paused else "pause")
	if next_track_button.has_method("set_icon_mode"):
		next_track_button.call("set_icon_mode", "next")
	_update_home_style_now_playing_progress()

func _update_home_style_now_playing_progress() -> void:
	if track_progress_bar == null or now_playing_duration_value == null:
		return
	var session: Node = _music_session()
	if session == null:
		track_progress_bar.max_value = 1.0
		track_progress_bar.value = 0.0
		now_playing_duration_value.text = "0:00 / 0:00"
		return
	var length: float = float(session.call("get_duration")) if session.has_method("get_duration") else 0.0
	var playback_position: float = float(session.call("get_playback_position")) if session.has_method("get_playback_position") else 0.0
	playback_position = clampf(playback_position, 0.0, maxf(length, 0.0))
	track_progress_bar.max_value = maxf(length, 1.0)
	track_progress_bar.value = playback_position
	now_playing_duration_value.text = "%s / %s" % [_format_duration(playback_position), _format_duration(length)]

func _on_now_playing_previous() -> void:
	_cycle_now_playing_library(-1)

func _on_now_playing_next() -> void:
	_cycle_now_playing_library(1)

func _cycle_now_playing_library(step: int) -> void:
	if filtered_song_ids.is_empty() or transitioning_out:
		return
	var current_id: String = selected_song_id
	var session: Node = _music_session()
	if session != null and session.has_method("get_state"):
		var value: Variant = session.call("get_state")
		if value is Dictionary:
			var state: Dictionary = value as Dictionary
			var state_song_id: String = str(state.get("song_id", ""))
			if filtered_song_ids.has(state_song_id):
				current_id = state_song_id
	var index: int = filtered_song_ids.find(current_id)
	if index < 0:
		index = 0
	var next_index: int = posmod(index + step, filtered_song_ids.size())
	_select_song(filtered_song_ids[next_index])

func _on_now_playing_play_pause() -> void:
	if transitioning_out:
		return
	var session: Node = _music_session()
	if session == null:
		return
	var paused: bool = bool(session.call("is_paused")) if session.has_method("is_paused") else false
	if paused:
		if session.has_method("set_paused"):
			session.call("set_paused", false)
	elif session.has_method("is_playing") and bool(session.call("is_playing")):
		if session.has_method("set_paused"):
			session.call("set_paused", true)
	else:
		_start_selected_preview()
	_update_home_style_now_playing_card()

func _notification(what: int) -> void:
	if what != NOTIFICATION_VISIBILITY_CHANGED or not is_node_ready():
		return
	if is_visible_in_tree():
		transitioning_out = false
		transition_overlay.modulate.a = 0.0
		# AppShell already animates the resident screen. Re-running a staggered
		# animation across every song row here creates dozens of tweens exactly when
		# the route transition needs a clean frame budget.
		_unlock_navigation_controls(false)
	else:
		transitioning_out = false
		mods_overlay.visible = false
		# MusicSession is global. Hiding the resident Song Library must not stop
		# the selected song; Main Menu will keep using the same playback clock.

func _process(delta: float) -> void:
	_update_home_style_now_playing_progress()
	selection_motion_elapsed += delta

	# Wheel rows use damped spring motion instead of snapping to new margins.
	for index in range(song_header_wrappers.size()):
		var wrapper := song_header_wrappers[index] as MarginContainer
		var button := song_buttons[index] as Button
		var target := float(_song_row_base_margin(index))
		if bool(song_hovered.get(index, false)):
			target = maxf(0.0, target - 9.0)
		var current := float(wrapper.get("animated_margin_left"))
		var velocity := float(song_margin_velocity.get(index, 0.0))
		var state := _spring_step(current, target, velocity, delta, 185.0, 18.0)
		wrapper.call("set_margin_immediate", state.x)
		song_margin_velocity[index] = state.y
		button.scale = Vector2.ONE

	# Difficulty rows follow the selected song with a delayed cascade.
	for song_index in range(song_difficulty_rows.size()):
		var rows: Array = song_difficulty_rows[song_index]
		var is_selected := song_index < filtered_song_ids.size() and filtered_song_ids[song_index] == selected_song_id
		for difficulty_index in range(rows.size()):
			var row := rows[difficulty_index] as Dictionary
			var diff_wrapper := row["wrapper"] as MarginContainer
			var diff_button := row["button"] as Button
			var target := float(_difficulty_row_base_margin(difficulty_index))
			var reveal_delay := 0.055 + float(difficulty_index) * 0.045
			if is_selected and selection_motion_elapsed < reveal_delay:
				target += 34.0
			if bool(difficulty_hovered.get("%d_%d" % [song_index, difficulty_index], false)):
				target = maxf(0.0, target - 7.0)
			var key := "%d_%d" % [song_index, difficulty_index]
			var current := float(diff_wrapper.get("animated_margin_left"))
			var velocity := float(difficulty_margin_velocity.get(key, 0.0))
			var state := _spring_step(current, target, velocity, delta, 205.0, 19.5)
			diff_wrapper.call("set_margin_immediate", state.x)
			difficulty_margin_velocity[key] = state.y
			diff_button.scale = Vector2.ONE

	# Scroll target is continuously approached so rapid navigation naturally interrupts
	# the previous motion instead of restarting a chain of tweens.
	if scroll_target >= 0.0 and song_scroll != null:
		var current_scroll := float(song_scroll.scroll_vertical)
		var response := 1.0 - exp(-8.5 * delta)
		var next_scroll := lerpf(current_scroll, scroll_target, response)
		if absf(next_scroll - scroll_target) < 0.65:
			next_scroll = scroll_target
			scroll_target = -1.0
		applying_scroll_target = true
		song_scroll.scroll_vertical = int(round(next_scroll))
		applying_scroll_target = false

func _spring_step(current: float, target: float, velocity: float, delta: float, stiffness: float, damping: float) -> Vector2:
	var acceleration := (target - current) * stiffness
	velocity += acceleration * delta
	velocity *= exp(-damping * delta)
	current += velocity * delta
	if absf(target - current) < 0.04 and absf(velocity) < 0.04:
		current = target
		velocity = 0.0
	return Vector2(current, velocity)

func _open_import_dialog() -> void:
	if layout_config == null:
		import_dialog.popup_centered()
		return
	import_dialog.popup_centered(Vector2i(layout_config.import_dialog_width, layout_config.import_dialog_height))

func _export_selected_level_pack() -> void:
	if selected_song_id.is_empty():
		show_creator_status("Select a custom song before exporting a level pack.", true)
		return
	var chart: Dictionary = _find_level(selected_song_id, selected_difficulty)
	var source_path: String = str(chart.get("_catalog_path", ""))
	if not source_path.begins_with("user://songs/"):
		show_creator_status("Built-in songs cannot be redistributed. Export is available for custom songs only.", true)
		return
	var export_root := "user://level_packs"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(export_root))
	var result: Dictionary = LevelPackScript.export_song(selected_song_id, export_root.path_join(selected_song_id + ".beatup-pack"), true)
	if not bool(result.get("ok", false)):
		show_creator_status("EXPORT FAILED · %s" % str(result.get("error", "Unknown error")), true)
		return
	show_creator_status("LEVEL PACK EXPORTED · %s · only share audio you have permission to distribute" % str(result.get("path", "")))

func show_creator_status(message: String, is_error: bool = false) -> void:
	footer_panel.visible = true
	footer_status.text = message
	footer_status.add_theme_color_override("font_color", MinimalThemeScript.DANGER if is_error else MinimalThemeScript.SUCCESS)

func _apply_layout_config() -> void:
	if not is_node_ready(): return
	_layout_home_style_now_playing()
	composition.apply(self)
	_refresh_song_rows(false)

func is_album_flow_library_layout_active() -> bool:
	return album_flow_showcase_row != null

func _install_album_flow_song_library_layout() -> void:
	if album_flow_showcase_row != null:
		return

	# Song Library uses the selected song art as a very quiet full-screen
	# atmosphere. The actual browsing/configuration surfaces stay crisp above it.
	now_playing_card.visible = false
	backdrop_visual.visible = true
	backdrop_visual.modulate = Color(1.0, 1.0, 1.0, 0.18)
	header_row.visible = true
	title_label.text = "S O N G   L I B R A R Y"
	count_label.text = "BEAT UP!"
	count_label.visible = false
	back_button.reparent(header_row)
	header_row.move_child(back_button, 0)
	back_button.text = "‹  BACK"
	back_button.visible = true
	var header_divider := ColorRect.new()
	header_divider.name = "LibraryHeaderDivider"
	header_divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_divider.custom_minimum_size = Vector2(1, 40)
	header_divider.color = Color(MinimalThemeScript.BORDER, 0.34)
	header_row.add_child(header_divider)
	header_row.move_child(header_divider, 1)
	var header_rule := HSeparator.new()
	header_rule.name = "LibraryHeaderRule"
	root_vbox.add_child(header_rule)
	root_vbox.move_child(header_rule, header_row.get_index() + 1)

	var info_header := info_vbox.get_node_or_null("InfoHeader") as Control
	if info_header != null:
		info_header.visible = false
	progress_status.visible = false
	info_tabs.visible = false
	details_panel.visible = false
	best_card.visible = false
	import_hint.visible = false
	footer_panel.visible = false
	if composition.stats != null:
		composition.stats.visible = false
	for legacy_control: Control in [info_tabs, details_panel, best_card, action_row, footer_panel]:
		legacy_control.visible = false

	selection_index.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	selection_index.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.move_child(wheel_column, 0)
	body.move_child(info_panel, 1)

	album_flow_divider = ColorRect.new()
	album_flow_divider.name = "LibraryColumnDivider"
	album_flow_divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	album_flow_divider.custom_minimum_size.x = 1.0
	album_flow_divider.size_flags_vertical = Control.SIZE_EXPAND_FILL
	album_flow_divider.color = Color(MinimalThemeScript.BORDER, 0.28)
	body.add_child(album_flow_divider)
	body.move_child(album_flow_divider, 1)
	body.move_child(info_panel, 2)

	# Secondary selected-song wash lives only behind the two detail columns.
	album_flow_detail_backdrop = TextureRect.new()
	album_flow_detail_backdrop.name = "SelectedSongBackdrop"
	album_flow_detail_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	album_flow_detail_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	album_flow_detail_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	album_flow_detail_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	album_flow_detail_backdrop.modulate = Color(1.0, 1.0, 1.0, 0.045)
	info_panel.add_child(album_flow_detail_backdrop)
	info_panel.move_child(album_flow_detail_backdrop, 0)

	album_flow_detail_veil = ColorRect.new()
	album_flow_detail_veil.name = "SelectedSongBackdropVeil"
	album_flow_detail_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	album_flow_detail_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Keep the compatibility node but remove the rectangular dark veil entirely.
	# The full-screen selected-song atmosphere already provides sufficient contrast.
	album_flow_detail_veil.color = Color(0.0, 0.0, 0.0, 0.0)
	album_flow_detail_veil.visible = false
	info_panel.add_child(album_flow_detail_veil)
	info_panel.move_child(album_flow_detail_veil, 1)

	album_flow_ambient = SongLibraryAmbientScript.new()
	album_flow_ambient.name = "SongLibraryAmbient"
	album_flow_ambient.mouse_filter = Control.MOUSE_FILTER_IGNORE
	album_flow_ambient.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	album_flow_ambient.visible = false
	info_panel.add_child(album_flow_ambient)
	info_panel.move_child(album_flow_ambient, 2)
	info_panel.move_child(info_vbox, 3)

	album_flow_detail_top_spacer = Control.new()
	album_flow_detail_top_spacer.name = "DetailTopSpacer"
	info_vbox.add_child(album_flow_detail_top_spacer)
	info_vbox.move_child(album_flow_detail_top_spacer, 0)

	# Detail area is explicitly split into artwork/performance and
	# identity/configuration columns: browse -> inspect -> configure -> play.
	album_flow_showcase_row = HBoxContainer.new()
	album_flow_showcase_row.name = "AlbumFlowShowcaseRow"
	album_flow_showcase_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	album_flow_showcase_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	album_flow_showcase_row.add_theme_constant_override("separation", 26)
	info_vbox.add_child(album_flow_showcase_row)
	info_vbox.move_child(album_flow_showcase_row, 1)

	album_flow_center_column = VBoxContainer.new()
	album_flow_center_column.name = "AlbumFlowCenterColumn"
	album_flow_center_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	album_flow_center_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	album_flow_center_column.add_theme_constant_override("separation", 14)
	album_flow_showcase_row.add_child(album_flow_center_column)

	album_flow_center_divider = ColorRect.new()
	album_flow_center_divider.name = "DetailColumnDivider"
	album_flow_center_divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	album_flow_center_divider.custom_minimum_size.x = 1.0
	album_flow_center_divider.size_flags_vertical = Control.SIZE_EXPAND_FILL
	album_flow_center_divider.color = Color(MinimalThemeScript.BORDER, 0.26)
	album_flow_showcase_row.add_child(album_flow_center_divider)

	album_flow_sidebar = VBoxContainer.new()
	album_flow_sidebar.name = "AlbumFlowSidebar"
	album_flow_sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	album_flow_sidebar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	album_flow_sidebar.add_theme_constant_override("separation", 12)
	album_flow_showcase_row.add_child(album_flow_sidebar)

	album_flow_artwork_slot = HBoxContainer.new()
	album_flow_artwork_slot.name = "AlbumFlowArtworkSlot"
	album_flow_artwork_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	album_flow_center_column.add_child(album_flow_artwork_slot)
	hero_panel.reparent(album_flow_artwork_slot)
	var artwork_right_spacer := Control.new()
	artwork_right_spacer.name = "ArtworkRightSpacer"
	artwork_right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	album_flow_artwork_slot.add_child(artwork_right_spacer)
	hero_panel.visible = true
	hero_panel.clip_contents = false
	song_visual.visible = false
	var hero_content := hero_panel.get_node("HeroContent") as Control
	var hero_overlay := hero_content.get_node("HeroOverlay") as Control
	hero_overlay.visible = false

	album_flow_artwork = TextureRect.new()
	album_flow_artwork.name = "AlbumArtwork"
	album_flow_artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	album_flow_artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	album_flow_artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	album_flow_artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var artwork_shader := Shader.new()
	artwork_shader.code = """
shader_type canvas_item;
uniform vec2 rect_size = vec2(500.0);
uniform float corner_radius = 5.0;
void fragment() {
	vec2 pixel = UV * rect_size;
	vec2 q = abs(pixel - rect_size * 0.5) - rect_size * 0.5 + vec2(corner_radius);
	float distance_to_edge = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - corner_radius;
	vec4 sampled = texture(TEXTURE, UV);
	sampled.a *= 1.0 - smoothstep(-1.0, 1.0, distance_to_edge);
	COLOR = sampled;
}
"""
	var artwork_material := ShaderMaterial.new()
	artwork_material.shader = artwork_shader
	album_flow_artwork.material = artwork_material
	hero_content.add_child(album_flow_artwork)
	hero_content.move_child(album_flow_artwork, 0)

	# Center-column Best Record block: section header, accuracy/score/rank,
	# then judgement breakdown, matching the approved reference hierarchy.
	album_flow_record_panel = PanelContainer.new()
	album_flow_record_panel.name = "AlbumFlowRecordPanel"
	album_flow_record_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	album_flow_center_column.add_child(album_flow_record_panel)
	var record_margin := MarginContainer.new()
	record_margin.add_theme_constant_override("margin_left", 4)
	record_margin.add_theme_constant_override("margin_right", 4)
	record_margin.add_theme_constant_override("margin_top", 10)
	record_margin.add_theme_constant_override("margin_bottom", 8)
	album_flow_record_panel.add_child(record_margin)

	album_flow_score_cluster = VBoxContainer.new()
	album_flow_score_cluster.name = "AlbumFlowScoreCluster"
	album_flow_score_cluster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	album_flow_score_cluster.add_theme_constant_override("separation", 8)
	record_margin.add_child(album_flow_score_cluster)

	var record_title_row := HBoxContainer.new()
	record_title_row.add_theme_constant_override("separation", 12)
	album_flow_score_cluster.add_child(record_title_row)
	album_flow_best_caption_value = Label.new()
	album_flow_best_caption_value.text = "BEST RECORD"
	album_flow_best_caption_value.set_meta("album_role", "caption")
	record_title_row.add_child(album_flow_best_caption_value)
	var record_title_rule := HSeparator.new()
	record_title_rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	record_title_rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	record_title_row.add_child(record_title_rule)
	album_flow_best_combo_value = Label.new()
	album_flow_best_combo_value.text = ""
	album_flow_best_combo_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	album_flow_best_combo_value.set_meta("album_role", "combo_value")
	record_title_row.add_child(album_flow_best_combo_value)

	var record_metrics := HBoxContainer.new()
	record_metrics.name = "AlbumFlowRecordMetrics"
	record_metrics.add_theme_constant_override("separation", 18)
	album_flow_score_cluster.add_child(record_metrics)

	var accuracy_stack := VBoxContainer.new()
	accuracy_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	accuracy_stack.add_theme_constant_override("separation", 2)
	record_metrics.add_child(accuracy_stack)
	var accuracy_caption := Label.new()
	accuracy_caption.text = "ACCURACY"
	accuracy_caption.set_meta("album_role", "metric_caption")
	accuracy_stack.add_child(accuracy_caption)
	album_flow_best_accuracy_value = Label.new()
	album_flow_best_accuracy_value.text = "—"
	album_flow_best_accuracy_value.set_meta("album_role", "accuracy_value")
	accuracy_stack.add_child(album_flow_best_accuracy_value)

	var metric_divider := VSeparator.new()
	metric_divider.custom_minimum_size.x = 1
	record_metrics.add_child(metric_divider)

	var score_stack := VBoxContainer.new()
	score_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_stack.add_theme_constant_override("separation", 2)
	record_metrics.add_child(score_stack)
	var score_caption := Label.new()
	score_caption.text = "SCORE"
	score_caption.set_meta("album_role", "metric_caption")
	score_stack.add_child(score_caption)
	album_flow_best_score_value = Label.new()
	album_flow_best_score_value.text = "NO RECORD"
	album_flow_best_score_value.set_meta("album_role", "score_value")
	score_stack.add_child(album_flow_best_score_value)

	album_flow_best_card = PanelContainer.new()
	album_flow_best_card.name = "AlbumFlowBestCard"
	album_flow_best_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	record_metrics.add_child(album_flow_best_card)
	var best_margin := MarginContainer.new()
	best_margin.add_theme_constant_override("margin_left", 10)
	best_margin.add_theme_constant_override("margin_right", 10)
	best_margin.add_theme_constant_override("margin_top", 4)
	best_margin.add_theme_constant_override("margin_bottom", 4)
	album_flow_best_card.add_child(best_margin)
	album_flow_best_rank_value = Label.new()
	album_flow_best_rank_value.text = ""
	album_flow_best_rank_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	album_flow_best_rank_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	album_flow_best_rank_value.set_meta("album_role", "rank")
	best_margin.add_child(album_flow_best_rank_value)

	var record_breakdown_rule := HSeparator.new()
	album_flow_score_cluster.add_child(record_breakdown_rule)
	album_flow_record_breakdown_row = HBoxContainer.new()
	album_flow_record_breakdown_row.name = "AlbumFlowJudgementBreakdown"
	album_flow_record_breakdown_row.add_theme_constant_override("separation", 1)
	album_flow_score_cluster.add_child(album_flow_record_breakdown_row)
	var judgement_defs: Array = [
		["PERFECT", MinimalThemeScript.CYAN],
		["GREAT", MinimalThemeScript.SUCCESS],
		["GOOD", MinimalThemeScript.GOLD],
		["MISS", MinimalThemeScript.DANGER],
	]
	for judgement_def: Array in judgement_defs:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.alignment = BoxContainer.ALIGNMENT_CENTER
		cell.add_theme_constant_override("separation", 1)
		album_flow_record_breakdown_row.add_child(cell)
		var caption := Label.new()
		caption.text = str(judgement_def[0])
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		MinimalThemeScript.apply_mono(caption, 9, Color(MinimalThemeScript.TEXT, 0.52))
		cell.add_child(caption)
		var value := Label.new()
		value.text = "0"
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var judgement_color: Color = judgement_def[1]
		MinimalThemeScript.apply_numeric(value, 20, judgement_color)
		cell.add_child(value)
		match str(judgement_def[0]):
			"PERFECT": album_flow_record_perfect_value = value
			"GREAT": album_flow_record_great_value = value
			"GOOD": album_flow_record_good_value = value
			"MISS": album_flow_record_miss_value = value

	# Right-side selected-song identity.
	# Right-side selected-song identity.
	var track_nav_row := HBoxContainer.new()
	track_nav_row.name = "AlbumFlowTrackNav"
	track_nav_row.add_theme_constant_override("separation", 6)
	album_flow_sidebar.add_child(track_nav_row)
	selection_index.reparent(track_nav_row)
	selection_index.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	album_flow_prev_song_button = Button.new()
	album_flow_prev_song_button.name = "PreviousSongButton"
	album_flow_prev_song_button.text = "‹"
	album_flow_prev_song_button.flat = true
	album_flow_prev_song_button.focus_mode = Control.FOCUS_NONE
	album_flow_prev_song_button.custom_minimum_size = Vector2(30, 30)
	album_flow_prev_song_button.pressed.connect(_select_song_relative.bind(-1))
	track_nav_row.add_child(album_flow_prev_song_button)
	album_flow_next_song_button = Button.new()
	album_flow_next_song_button.name = "NextSongButton"
	album_flow_next_song_button.text = "›"
	album_flow_next_song_button.flat = true
	album_flow_next_song_button.focus_mode = Control.FOCUS_NONE
	album_flow_next_song_button.custom_minimum_size = Vector2(30, 30)
	album_flow_next_song_button.pressed.connect(_select_song_relative.bind(1))
	track_nav_row.add_child(album_flow_next_song_button)

	detail_title.reparent(album_flow_sidebar)
	detail_meta.reparent(album_flow_sidebar)
	detail_flavor.visible = false
	detail_description.visible = false
	mode_status.reparent(album_flow_sidebar)

	album_flow_meta_line = Label.new()
	album_flow_meta_line.name = "AlbumFlowMetaLine"
	album_flow_meta_line.text = "— BPM   ·   —   ·   8K"
	album_flow_meta_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	album_flow_sidebar.add_child(album_flow_meta_line)

	var metadata_separator := HSeparator.new()
	metadata_separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	album_flow_sidebar.add_child(metadata_separator)

	quick_stats.reparent(album_flow_sidebar)
	quick_stats.visible = false
	var notes_caption_label := quick_stats.get_node_or_null("NotesCard/VBox/NotesCaption") as Label
	if notes_caption_label != null:
		notes_caption_label.text = "MODE"
	var duration_caption_label := quick_stats.get_node_or_null("DurationCard/VBox/DurationCaption") as Label
	if duration_caption_label != null:
		duration_caption_label.text = "DURATION"

	album_flow_difficulty_caption = Label.new()
	album_flow_difficulty_caption.text = "DIFFICULTY"
	album_flow_difficulty_caption.set_meta("album_role", "section_caption")
	album_flow_sidebar.add_child(album_flow_difficulty_caption)
	album_flow_difficulty_row = HBoxContainer.new()
	album_flow_difficulty_row.name = "AlbumFlowDifficultyRow"
	album_flow_difficulty_row.add_theme_constant_override("separation", 8)
	album_flow_sidebar.add_child(album_flow_difficulty_row)

	var mode_caption := Label.new()
	mode_caption.text = "MODE"
	mode_caption.set_meta("album_role", "section_caption")
	album_flow_sidebar.add_child(mode_caption)
	album_flow_mode_row = HBoxContainer.new()
	album_flow_mode_row.name = "AlbumFlowModeRow"
	album_flow_mode_row.add_theme_constant_override("separation", 8)
	album_flow_sidebar.add_child(album_flow_mode_row)
	album_flow_mode_4_button = Button.new()
	album_flow_mode_4_button.name = "InlineMode4Button"
	album_flow_mode_4_button.text = "4K"
	album_flow_mode_4_button.toggle_mode = true
	album_flow_mode_4_button.focus_mode = Control.FOCUS_ALL
	album_flow_mode_4_button.pressed.connect(_on_mode_4_selected)
	album_flow_mode_row.add_child(album_flow_mode_4_button)
	album_flow_mode_8_button = Button.new()
	album_flow_mode_8_button.name = "InlineMode8Button"
	album_flow_mode_8_button.text = "8K"
	album_flow_mode_8_button.toggle_mode = true
	album_flow_mode_8_button.focus_mode = Control.FOCUS_ALL
	album_flow_mode_8_button.pressed.connect(_on_mode_8_selected)
	album_flow_mode_row.add_child(album_flow_mode_8_button)

	var modifiers_caption := Label.new()
	modifiers_caption.text = "MODS"
	modifiers_caption.set_meta("album_role", "section_caption")
	album_flow_sidebar.add_child(modifiers_caption)
	album_flow_modifier_row = HBoxContainer.new()
	album_flow_modifier_row.add_theme_constant_override("separation", 8)
	album_flow_sidebar.add_child(album_flow_modifier_row)
	mods_button.visible = false
	album_flow_random_button = Button.new()
	album_flow_random_button.name = "InlineRandomButton"
	album_flow_random_button.text = "RANDOM"
	album_flow_random_button.toggle_mode = true
	album_flow_random_button.focus_mode = Control.FOCUS_ALL
	album_flow_random_button.toggled.connect(_on_random_mod_toggled)
	album_flow_modifier_row.add_child(album_flow_random_button)
	practice_button.reparent(album_flow_modifier_row)
	practice_button.text = "PRACTICE"
	practice_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	replay_button.visible = false
	action_row.visible = false

	album_flow_sidebar_spacer = Control.new()
	album_flow_sidebar_spacer.name = "SidebarActionSpacer"
	album_flow_sidebar_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	album_flow_sidebar.add_child(album_flow_sidebar_spacer)

	play_button.reparent(album_flow_sidebar)
	play_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_button.size_flags_vertical = Control.SIZE_SHRINK_END

	# Compatibility shell retained but hidden: the release composition no longer
	# uses a detached bottom difficulty/action dock.
	album_flow_bottom_panel = PanelContainer.new()
	album_flow_bottom_panel.name = "AlbumFlowBottomPanel"
	album_flow_bottom_panel.visible = false
	info_vbox.add_child(album_flow_bottom_panel)
	album_flow_play_row = HBoxContainer.new()
	album_flow_play_row.name = "AlbumFlowBottomActionBar"
	album_flow_bottom_panel.add_child(album_flow_play_row)

	_install_album_flow_filter_tabs()
	_refresh_album_flow_difficulty_row()
	_update_album_flow_modifier_state()

func _install_album_flow_filter_tabs() -> void:
	var library_box := song_scroll.get_parent() as VBoxContainer
	var toolbar := search_input.get_parent() as Control
	if toolbar != null:
		toolbar.visible = true
		toolbar.reparent(header_row)
		header_row.move_child(toolbar, 2)
		toolbar.size_flags_horizontal = Control.SIZE_FILL
		var toolbar_spacer := toolbar.get_node_or_null("LibraryToolbarSpacer") as Control
		if toolbar_spacer != null:
			toolbar_spacer.visible = false
		search_input.placeholder_text = "Search songs, artists, or tags..."
		search_input.visible = true

	filters_panel.visible = false
	progress_filter.visible = false
	sort_filter.visible = true
	if composition.filter_row != null:
		composition.filter_row.visible = false
	if composition.chips != null:
		composition.chips.visible = false

	var wheel_header := library_box.get_node_or_null("WheelHeader") as HBoxContainer
	if wheel_header != null:
		album_flow_list_header = wheel_header
		wheel_header.visible = true
		wheel_header.custom_minimum_size.y = 28
		var wheel_caption := wheel_header.get_node_or_null("WheelCaption") as Label
		if wheel_caption != null:
			wheel_caption.text = "#     TITLE"
			wheel_caption.custom_minimum_size.x = 252
			MinimalThemeScript.apply_mono(wheel_caption, 9, Color(MinimalThemeScript.TEXT, 0.48))
		var mode_header := wheel_header.get_node_or_null("WheelModeLabel") as Label
		if mode_header != null:
			mode_header.text = "ARTIST                    BPM"
			MinimalThemeScript.apply_mono(mode_header, 9, Color(MinimalThemeScript.TEXT, 0.48))
	library_hint.visible = false
	var separator := library_box.get_node_or_null("ListSeparator") as Control
	if separator != null:
		separator.visible = false

	album_flow_filter_tabs = HBoxContainer.new()
	album_flow_filter_tabs.name = "AlbumFlowFilterTabs"
	album_flow_filter_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	album_flow_filter_tabs.add_theme_constant_override("separation", 10)
	toolbar.add_child(album_flow_filter_tabs)

	# Keep the old aggregate filter object alive for compatibility, but the
	# primary header now exposes the two filters shown in the approved mockup.
	album_flow_filter_button = _album_flow_filter_button("⋯")
	album_flow_filter_button.name = "LibraryFilterButton"
	album_flow_filter_button.visible = true
	album_flow_filter_button.tooltip_text = "More filters"
	album_flow_filter_button.custom_minimum_size = Vector2(40, 40)
	album_flow_filter_button.set_meta("filter_kind", "filters")
	album_flow_filter_button.pressed.connect(_album_flow_toggle_filters)
	album_flow_filter_tabs.add_child(album_flow_filter_button)

	artist_filter.reparent(album_flow_filter_tabs)
	artist_filter.custom_minimum_size = Vector2(150, 40)
	difficulty_filter.reparent(album_flow_filter_tabs)
	difficulty_filter.custom_minimum_size = Vector2(164, 40)
	sort_filter.reparent(album_flow_filter_tabs)
	sort_filter.name = "LibrarySortDropdown"
	sort_filter.custom_minimum_size = Vector2(124, 40)
	album_flow_bpm_button = sort_filter

	if composition.filter_row != null:
		library_box.move_child(composition.filter_row, song_scroll.get_index())
	if composition.chips != null:
		library_box.move_child(composition.chips, song_scroll.get_index())

	album_flow_header_spacer = Control.new()
	album_flow_header_spacer.name = "AlbumFlowHeaderSpacer"
	album_flow_header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(album_flow_header_spacer)
	album_flow_list_spacer = Control.new()
	album_flow_list_spacer.name = "AlbumFlowListTopSpacer"
	album_flow_list_spacer.custom_minimum_size.y = 4
	library_box.add_child(album_flow_list_spacer)
	library_box.move_child(album_flow_list_spacer, song_scroll.get_index())

func _album_flow_filter_button(label_text: String) -> Button:
	var button := Button.new()
	button.text = label_text
	button.focus_mode = Control.FOCUS_ALL
	button.flat = true
	button.custom_minimum_size = Vector2(0, 28)
	button.add_theme_font_override("font", MinimalThemeScript.mono_font())
	button.add_theme_font_size_override("font_size", 11)
	return button

func _album_flow_reset_filters() -> void:
	selected_search_query = ""
	search_input.text = ""
	selected_artist_filter = "All Artists"
	selected_difficulty_filter = "All Difficulties"
	selected_progress_filter = "All Progress"
	artist_filter.select(0)
	difficulty_filter.select(0)
	progress_filter.select(0)
	if composition.filter_row != null:
		composition.filter_row.visible = false
	_apply_filters()

func _album_flow_show_filter(kind: String) -> void:
	if composition.filter_row == null:
		return
	composition.filter_row.visible = true
	artist_filter.visible = kind == "artist"
	difficulty_filter.visible = kind == "difficulty"
	progress_filter.visible = kind == "progress"

func _album_flow_toggle_filters() -> void:
	if composition.filter_row == null:
		return
	composition.filter_row.visible = not composition.filter_row.visible
	# Artist and difficulty live permanently in the top bar. Keep only the
	# secondary progress filter in this compact overflow row.
	artist_filter.visible = true
	difficulty_filter.visible = true
	progress_filter.visible = composition.filter_row.visible
	_apply_album_flow_filter_tab_style()

func _album_flow_toggle_bpm_sort() -> void:
	selected_sort_mode = "BPM Desc" if selected_sort_mode == "BPM Asc" else "BPM Asc"
	if album_flow_bpm_button != null:
		album_flow_bpm_button.text = "BPM ↓" if selected_sort_mode == "BPM Desc" else "BPM ↑"
	_apply_filters()

func _apply_album_flow_song_library_layout() -> void:
	if album_flow_showcase_row == null:
		return
	now_playing_card.visible = false
	backdrop_visual.visible = true
	backdrop_visual.modulate = Color(1.0, 1.0, 1.0, 0.27)
	header_row.visible = true
	for legacy_control: Control in [info_tabs, details_panel, best_card, action_row, footer_panel]:
		legacy_control.visible = false

	var compact: bool = size.x < 1550.0 or size.y < 840.0
	var layout_scale: float = clampf(minf(size.x / 1920.0, size.y / 1080.0), 0.66, 1.0)
	info_panel.add_theme_stylebox_override("panel", MinimalThemeScript.panel_style(Color(0, 0, 0, 0), 0, Color(0, 0, 0, 0), 0, 6.0 if compact else 12.0))
	main_margin.add_theme_constant_override("margin_left", 22 if compact else 30)
	main_margin.add_theme_constant_override("margin_right", 22 if compact else 30)
	main_margin.add_theme_constant_override("margin_top", 14 if compact else 18)
	main_margin.add_theme_constant_override("margin_bottom", 14 if compact else 22)
	root_vbox.add_theme_constant_override("separation", 12)
	header_row.custom_minimum_size.y = 46 if compact else 54
	back_button.custom_minimum_size = Vector2(92, 34)

	var title_block := title_label.get_parent() as Control
	if title_block != null:
		title_block.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		title_block.custom_minimum_size.x = 190 if compact else 235
	var library_toolbar := search_input.get_parent() as Control
	if library_toolbar != null:
		library_toolbar.custom_minimum_size.x = 520 if compact else 760

	if album_flow_detail_top_spacer != null:
		album_flow_detail_top_spacer.custom_minimum_size.y = 4 if compact else 8

	body.add_theme_constant_override("separation", 14 if compact else 18)
	wheel_column.custom_minimum_size.x = 0
	wheel_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wheel_column.size_flags_stretch_ratio = 0.35
	info_panel.custom_minimum_size.x = 0
	info_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_panel.size_flags_stretch_ratio = 0.65
	info_vbox.add_theme_constant_override("separation", 0)

	album_flow_showcase_row.add_theme_constant_override("separation", 18 if compact else 26)
	album_flow_center_column.size_flags_stretch_ratio = 0.56
	album_flow_sidebar.size_flags_stretch_ratio = 0.44
	album_flow_sidebar.custom_minimum_size.x = 300 if compact else 390
	album_flow_sidebar.add_theme_constant_override("separation", 8 if compact else 12)

	var artwork_size: float = clampf(minf(info_panel.size.x * 0.54, size.y * 0.54), 270.0, 535.0)
	album_flow_artwork_slot.custom_minimum_size = Vector2(artwork_size, artwork_size)
	hero_panel.custom_minimum_size = Vector2(artwork_size, artwork_size)
	if album_flow_artwork != null and album_flow_artwork.material is ShaderMaterial:
		(album_flow_artwork.material as ShaderMaterial).set_shader_parameter("rect_size", Vector2(artwork_size, artwork_size))
	hero_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	hero_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	album_flow_showcase_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	album_flow_showcase_row.custom_minimum_size.y = 0

	if album_flow_record_panel != null:
		album_flow_record_panel.custom_minimum_size.y = 148 if compact else 206
	if album_flow_best_card != null:
		album_flow_best_card.custom_minimum_size = Vector2(62 if compact else 82, 62 if compact else 82)
	if album_flow_score_cluster != null:
		album_flow_score_cluster.custom_minimum_size.y = 72 if compact else 96

	quick_stats.custom_minimum_size.y = 0
	for card_name in ["BpmCard", "DurationCard", "NotesCard"]:
		var quick_card := quick_stats.get_node_or_null(card_name) as Control
		if quick_card != null:
			quick_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for mode_button in [album_flow_mode_4_button, album_flow_mode_8_button]:
		mode_button.custom_minimum_size = Vector2(90, 42 if compact else 54)
		mode_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	album_flow_random_button.custom_minimum_size = Vector2(120, 44 if compact else 58)
	album_flow_random_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	practice_button.custom_minimum_size = Vector2(0, 44 if compact else 58)
	practice_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	play_button.custom_minimum_size = Vector2(0, clampf(82.0 * layout_scale, 62.0, 82.0))
	play_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_button.size_flags_vertical = Control.SIZE_SHRINK_END

	search_input.custom_minimum_size = Vector2(360 if compact else 500, 40)
	search_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if album_flow_list_header != null:
		album_flow_list_header.custom_minimum_size.y = 28
	_apply_album_flow_filter_tab_style()

func _apply_album_flow_filter_tab_style() -> void:
	if album_flow_filter_tabs == null:
		return
	for child in album_flow_filter_tabs.get_children():
		if not (child is Button):
			continue
		var button := child as Button
		var kind := str(button.get_meta("filter_kind", ""))
		if kind.is_empty():
			continue
		var active := false
		match kind:
			"all":
				active = selected_artist_filter == "All Artists" and selected_difficulty_filter == "All Difficulties" and selected_progress_filter == "All Progress"
			"artist":
				active = selected_artist_filter != "All Artists"
			"difficulty":
				active = selected_difficulty_filter != "All Difficulties"
			"progress":
				active = selected_progress_filter != "All Progress"
			"filters":
				active = composition.filter_row != null and composition.filter_row.visible
				button.text = "⋯"
		button.add_theme_color_override("font_color", MinimalThemeScript.TEXT if active else Color(MinimalThemeScript.TEXT, 0.56))
		button.add_theme_color_override("font_hover_color", MinimalThemeScript.TEXT)
		button.add_theme_color_override("font_pressed_color", MinimalThemeScript.ACCENT)
		for state in ["normal", "hover", "pressed", "focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0, 0, 0, 0)
			style.border_color = MinimalThemeScript.ACCENT
			style.border_width_bottom = 2 if active else 0
			style.content_margin_left = 2
			style.content_margin_right = 2
			button.add_theme_stylebox_override(state, style)

func _apply_album_flow_song_library_theme() -> void:
	if album_flow_showcase_row == null:
		return

	title_label.add_theme_font_override("font", MinimalThemeScript.mono_font())
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", MinimalThemeScript.TEXT)
	count_label.add_theme_font_override("font", MinimalThemeScript.mono_font())
	count_label.add_theme_font_size_override("font_size", 9)
	count_label.add_theme_color_override("font_color", Color(LIBRARY_ACCENT, 0.72))

	detail_title.add_theme_font_override("font", MinimalThemeScript.display_font())
	detail_title.add_theme_font_size_override("font_size", 32)
	detail_title.add_theme_color_override("font_color", MinimalThemeScript.TEXT)
	detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_title.max_lines_visible = 2
	detail_title.clip_text = false
	detail_title.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	detail_title.custom_minimum_size.y = 84
	detail_meta.add_theme_font_override("font", MinimalThemeScript.body_font())
	detail_meta.add_theme_font_size_override("font_size", 17)
	detail_meta.add_theme_color_override("font_color", Color(MinimalThemeScript.TEXT, 0.74))
	selection_index.add_theme_font_override("font", MinimalThemeScript.mono_font())
	selection_index.add_theme_font_size_override("font_size", 10)
	selection_index.add_theme_color_override("font_color", Color(MinimalThemeScript.TEXT, 0.56))
	mode_status.add_theme_font_override("font", MinimalThemeScript.mono_font())
	mode_status.add_theme_font_size_override("font_size", 9)
	if album_flow_meta_line != null:
		MinimalThemeScript.apply_mono(album_flow_meta_line, 11, Color(MinimalThemeScript.TEXT, 0.72))
	if album_flow_prev_song_button != null and album_flow_next_song_button != null:
		for nav_button in [album_flow_prev_song_button, album_flow_next_song_button]:
			nav_button.add_theme_font_override("font", MinimalThemeScript.display_font())
			nav_button.add_theme_font_size_override("font_size", 24)
			nav_button.add_theme_color_override("font_color", Color(MinimalThemeScript.TEXT, 0.68))
			nav_button.add_theme_color_override("font_hover_color", MinimalThemeScript.CYAN)
			nav_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
			nav_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
			nav_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
			nav_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	hero_panel.add_theme_stylebox_override("panel", MinimalThemeScript.panel_style(Color(0, 0, 0, 0), 2, Color(MinimalThemeScript.CYAN, 0.34), 1, 0.0))

	for card_name in ["BpmCard", "DurationCard", "NotesCard"]:
		var card := quick_stats.get_node_or_null(card_name) as PanelContainer
		if card != null:
			card.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	for caption_path in ["BpmCard/VBox/BpmCaption", "DurationCard/VBox/DurationCaption", "NotesCard/VBox/NotesCaption"]:
		var caption := quick_stats.get_node_or_null(caption_path) as Label
		if caption != null:
			caption.add_theme_font_override("font", MinimalThemeScript.mono_font())
			caption.add_theme_font_size_override("font_size", 9)
			caption.add_theme_color_override("font_color", Color(MinimalThemeScript.TEXT, 0.46))
	for value_label in [bpm_value, duration_value, notes_value]:
		value_label.add_theme_font_override("font", MinimalThemeScript.medium_font())
		value_label.add_theme_font_size_override("font_size", 14)
		value_label.add_theme_color_override("font_color", MinimalThemeScript.TEXT)

	for section_node in album_flow_sidebar.find_children("*", "Label", true, false):
		var section_label := section_node as Label
		if str(section_label.get_meta("album_role", "")) == "section_caption":
			MinimalThemeScript.apply_mono(section_label, 11, Color(MinimalThemeScript.TEXT, 0.72))

	if album_flow_record_panel != null:
		# Best Record should sit directly on the library composition. The previous
		# semi-opaque panel read as a large black overlay beneath the artwork.
		album_flow_record_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	if album_flow_best_card != null:
		var best_style := MinimalThemeScript.panel_style(Color(MinimalThemeScript.SURFACE_RAISED, 0.60), 6, Color(LIBRARY_ACCENT, 0.38), 1, 0.0)
		album_flow_best_card.add_theme_stylebox_override("panel", best_style)
		album_flow_best_rank_value.add_theme_font_override("font", MinimalThemeScript.display_font())
		album_flow_best_rank_value.add_theme_font_size_override("font_size", 46)
		album_flow_best_rank_value.add_theme_color_override("font_color", LIBRARY_ACCENT)

	if album_flow_score_cluster != null:
		for node in album_flow_score_cluster.find_children("*", "Label", true, false):
			var label := node as Label
			var role := str(label.get_meta("album_role", ""))
			match role:
				"metric_caption":
					label.add_theme_font_override("font", MinimalThemeScript.mono_font())
					label.add_theme_font_size_override("font_size", 9)
					label.add_theme_color_override("font_color", Color(MinimalThemeScript.TEXT, 0.50))
				"score_value":
					label.add_theme_font_override("font", MinimalThemeScript.semibold_font())
					label.add_theme_font_size_override("font_size", 27)
					label.add_theme_color_override("font_color", MinimalThemeScript.TEXT)
				"accuracy_value":
					label.add_theme_font_override("font", MinimalThemeScript.medium_font())
					label.add_theme_font_override("font", MinimalThemeScript.semibold_font())
					label.add_theme_font_size_override("font_size", 27)
					label.add_theme_color_override("font_color", MinimalThemeScript.TEXT)
				"combo_value":
					label.add_theme_font_override("font", MinimalThemeScript.mono_font())
					label.add_theme_font_size_override("font_size", 10)
					label.add_theme_color_override("font_color", Color(MinimalThemeScript.TEXT, 0.52))
				_:
					label.add_theme_font_override("font", MinimalThemeScript.mono_font())
					label.add_theme_font_size_override("font_size", 10)
					label.add_theme_color_override("font_color", Color(MinimalThemeScript.TEXT, 0.62))

	for header_filter in [artist_filter, difficulty_filter, sort_filter]:
		header_filter.add_theme_font_override("font", MinimalThemeScript.mono_font())
		header_filter.add_theme_font_size_override("font_size", 10)
		header_filter.add_theme_color_override("font_color", Color(MinimalThemeScript.TEXT, 0.78))
	_style_album_play_button()
	_style_album_secondary_chip(album_flow_random_button, random_mode_enabled, MinimalThemeScript.PINK)
	_style_album_secondary_chip(practice_button, false, LIBRARY_ACCENT)
	for mode_button in [album_flow_mode_4_button, album_flow_mode_8_button]:
		_style_album_segment_button(mode_button, mode_button.button_pressed)
	_apply_album_flow_filter_tab_style()

func _clear_album_flow_children(node: Node) -> void:
	if node == null:
		return
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _refresh_album_flow_difficulty_row() -> void:
	if album_flow_difficulty_row == null:
		return
	_clear_album_flow_children(album_flow_difficulty_row)
	if selected_song_id.is_empty():
		return
	var available_difficulties := _available_difficulties(selected_song_id)
	for diff_value in ["normal", "hard", "master"]:
		var diff: String = str(diff_value)
		var chart: Dictionary = _find_level(selected_song_id, diff)
		var available: bool = available_difficulties.has(diff) and not chart.is_empty()
		var chip := Button.new()
		chip.name = "%sDifficultyButton" % diff.capitalize()
		chip.text = ""
		chip.focus_mode = Control.FOCUS_ALL
		chip.disabled = not available
		chip.custom_minimum_size = Vector2(122, 64 if size.y < 820.0 else 82)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if available:
			chip.pressed.connect(_select_difficulty.bind(diff))
		var selected: bool = available and diff == selected_difficulty
		var accent: Color = _difficulty_color(diff)
		_style_album_difficulty_button(chip, selected, available, accent)
		var stack := VBoxContainer.new()
		stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		stack.alignment = BoxContainer.ALIGNMENT_CENTER
		stack.add_theme_constant_override("separation", -2)
		chip.add_child(stack)
		var level_label := Label.new()
		level_label.name = "DifficultyLevel"
		level_label.text = str(int(chart.get("star_rating", 1))) if available else "—"
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		MinimalThemeScript.apply_numeric(level_label, 26 if selected else 23, accent if selected else Color(MinimalThemeScript.TEXT, 0.84 if available else 0.22))
		stack.add_child(level_label)
		var name_label := Label.new()
		name_label.name = "DifficultyName"
		name_label.text = diff.to_upper()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		MinimalThemeScript.apply_mono(name_label, 9, accent if selected else Color(MinimalThemeScript.TEXT, 0.56 if available else 0.18))
		stack.add_child(name_label)
		var diamond := Label.new()
		diamond.name = "DifficultyDiamond"
		diamond.text = "◇" if selected else ""
		diamond.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		MinimalThemeScript.apply_mono(diamond, 8, accent if selected else Color(MinimalThemeScript.MUTED, 0.28 if available else 0.10))
		stack.add_child(diamond)
		stack.move_child(diamond, 0)
		album_flow_difficulty_row.add_child(chip)
		InteractionPolishScript.install_buttons([chip])
		if selected:
			chip.modulate.a = 0.74
			chip.scale = Vector2(0.96, 0.96)
			chip.pivot_offset = chip.custom_minimum_size * 0.5
			var select_tween := chip.create_tween().set_parallel(true)
			select_tween.tween_property(chip, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
			select_tween.tween_property(chip, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _refresh_album_flow_best_card(chart: Dictionary) -> void:
	if album_flow_best_card == null:
		return
	var entry: Dictionary = {}
	if not chart.is_empty():
		var key := ScoreIdentity.key(chart, UserSettingsScript.get_input_style(), random_mode_enabled)
		var raw: Variant = best_stats.get(key, {})
		if raw is Dictionary:
			entry = raw as Dictionary
	var has_record := not entry.is_empty() and int(entry.get("score", 0)) > 0
	album_flow_best_caption_value.text = "BEST RECORD"
	album_flow_best_rank_value.text = str(entry.get("best_rank", entry.get("rank", ""))) if has_record else ""
	album_flow_best_card.visible = has_record
	if album_flow_record_panel != null:
		album_flow_record_panel.custom_minimum_size.y = 204.0 if has_record else 116.0
	var score_value := int(entry.get("score", 0))
	album_flow_best_score_value.text = _format_album_flow_score(score_value) if has_record else "NO RECORD"
	var combo_value := int(entry.get("best_max_combo", entry.get("max_combo", 0)))
	var accuracy_value := float(entry.get("best_accuracy", entry.get("accuracy", 0.0)))
	album_flow_best_accuracy_value.text = ("%.2f%%" % accuracy_value) if has_record else "—"
	album_flow_best_combo_value.text = ("MAX COMBO  %d" % combo_value) if has_record and combo_value > 0 else "PLAY THIS CHART TO SET A SCORE"
	if album_flow_record_breakdown_row != null:
		album_flow_record_breakdown_row.visible = has_record
	if album_flow_record_perfect_value != null:
		album_flow_record_perfect_value.text = str(int(entry.get("perfect", 0)))
	if album_flow_record_great_value != null:
		album_flow_record_great_value.text = str(int(entry.get("great", 0)))
	if album_flow_record_good_value != null:
		album_flow_record_good_value.text = str(int(entry.get("good", 0)))
	if album_flow_record_miss_value != null:
		album_flow_record_miss_value.text = str(int(entry.get("miss", 0)))

func _format_album_flow_score(value: int) -> String:
	var digits := str(maxi(value, 0))
	var grouped := ""
	var count := 0
	for index in range(digits.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			grouped = "," + grouped
		grouped = digits.substr(index, 1) + grouped
		count += 1
	return grouped

func _update_album_flow_modifier_state() -> void:
	if album_flow_showcase_row == null:
		return
	mods_button.text = "4 KEY" if UserSettingsScript.get_input_style() == "4_arrow" else "8 KEY"
	var is_four := UserSettingsScript.get_input_style() == "4_arrow"
	if album_flow_mode_4_button != null:
		album_flow_mode_4_button.set_pressed_no_signal(is_four)
		_style_album_segment_button(album_flow_mode_4_button, is_four)
	if album_flow_mode_8_button != null:
		album_flow_mode_8_button.set_pressed_no_signal(not is_four)
		_style_album_segment_button(album_flow_mode_8_button, not is_four)
	if album_flow_random_button != null:
		album_flow_random_button.set_pressed_no_signal(random_mode_enabled)
		album_flow_random_button.text = "RANDOM · ON" if random_mode_enabled else "RANDOM · OFF"
		_style_album_secondary_chip(album_flow_random_button, random_mode_enabled, MinimalThemeScript.PINK)

func _apply_theme_config() -> void:
	if theme_config == null:
		return
	for node in find_children("*", "Label", true, false):
		var label: Label = node as Label
		if label != null:
			label.add_theme_color_override("font_color", theme_config.text_primary)
			label.add_theme_font_size_override("font_size", theme_config.body_size)
	# v17.4.51: distinct display/UI/numeric typography roles.
	title_label.add_theme_font_size_override("font_size", maxi(theme_config.title_size - 2, 26))
	title_label.add_theme_font_override("font", MinimalThemeScript.display_font())
	count_label.add_theme_color_override("font_color", theme_config.accent_primary)
	count_label.add_theme_font_size_override("font_size", max(theme_config.caption_size - 1, 10))
	detail_title.add_theme_font_size_override("font_size", theme_config.title_size + 8)
	detail_title.add_theme_font_override("font", MinimalThemeScript.display_font())
	detail_meta.add_theme_color_override("font_color", Color(MinimalThemeScript.TEXT, 0.64))
	detail_meta.add_theme_font_size_override("font_size", maxi(theme_config.body_size + 1, 15))
	detail_meta.add_theme_font_override("font", MinimalThemeScript.medium_font())
	detail_description.add_theme_color_override("font_color", MinimalThemeScript.CYAN)
	detail_description.add_theme_font_size_override("font_size", max(theme_config.body_size, 13))
	detail_description.add_theme_font_override("font", MinimalThemeScript.semibold_font())
	detail_flavor.add_theme_color_override("font_color", theme_config.text_primary)
	detail_flavor.add_theme_font_size_override("font_size", theme_config.caption_size)
	rank_label.add_theme_font_size_override("font_size", maxi(theme_config.title_size + 8, 38))
	rank_label.add_theme_color_override("font_color", theme_config.accent_primary)
	best_stats_label.add_theme_font_size_override("font_size", max(theme_config.caption_size, 11))
	progress_status.add_theme_font_size_override("font_size", theme_config.caption_size)
	progress_status.add_theme_color_override("font_color", theme_config.accent_primary)
	import_hint.add_theme_color_override("font_color", theme_config.text_secondary)
	import_hint.add_theme_font_size_override("font_size", theme_config.caption_size)
	wheel_mode_label.add_theme_color_override("font_color", Color(theme_config.text_secondary, 0.92))
	wheel_mode_label.add_theme_font_size_override("font_size", theme_config.caption_size)
	library_hint.add_theme_color_override("font_color", theme_config.text_secondary)
	library_hint.add_theme_font_size_override("font_size", theme_config.caption_size)
	footer_status.add_theme_color_override("font_color", theme_config.text_secondary)
	footer_status.add_theme_font_size_override("font_size", theme_config.caption_size)
	for button in [play_button, mods_button, import_button, refresh_button, editor_button, back_button, mode_8_button, mode_4_button, random_mod_button, mods_close_button, practice_button, replay_button, rank_sort_button]:
		if button != null:
			_style_button(button)
	_style_option_button(artist_filter)
	_style_option_button(difficulty_filter)
	_style_option_button(progress_filter)
	_style_option_button(sort_filter)
	_style_compact_option_button(artist_filter)
	_style_compact_option_button(difficulty_filter)
	_style_compact_option_button(progress_filter)
	_style_compact_option_button(sort_filter)
	if ranking_mods_filter != null:
		_style_compact_option_button(ranking_mods_filter)
	MinimalThemeScript.style_secondary(mods_button, MinimalThemeScript.CYAN)
	_style_mods_ui()
	MinimalThemeScript.style_secondary(back_button, MinimalThemeScript.CYAN)
	_style_action_back(back_button)
	if practice_button != null:
		MinimalThemeScript.style_secondary(practice_button, MinimalThemeScript.CYAN)
	if replay_button != null:
		MinimalThemeScript.style_secondary(replay_button, MinimalThemeScript.CYAN)
	if rank_sort_button != null:
		MinimalThemeScript.style_secondary(rank_sort_button, MinimalThemeScript.CYAN)
	search_input.add_theme_font_override("font", MinimalThemeScript.body_font())
	search_input.add_theme_font_size_override("font_size", 12)
	search_input.add_theme_color_override("font_color", MinimalThemeScript.TEXT)
	search_input.add_theme_color_override("font_placeholder_color", Color(MinimalThemeScript.MUTED, 0.72))
	search_input.add_theme_color_override("caret_color", MinimalThemeScript.CYAN)
	search_input.add_theme_color_override("selection_color", Color(MinimalThemeScript.CYAN, 0.26))
	# v17.2.3: hierarchy polish; selected-song side remains a transparent overlay.
	info_panel.add_theme_stylebox_override("panel", MinimalThemeScript.panel_style(Color(0, 0, 0, 0), 0, Color(0, 0, 0, 0), 0, 20.0))
	library_panel.add_theme_stylebox_override("panel", MinimalThemeScript.panel_style(Color(0, 0, 0, 0), 0, Color(0, 0, 0, 0), 0, 0.0))
	filters_panel.add_theme_stylebox_override("panel", MinimalThemeScript.panel_style(Color(0, 0, 0, 0), 0, Color(0, 0, 0, 0), 0, 0.0))
	footer_panel.add_theme_stylebox_override("panel", MinimalThemeScript.panel_style(Color(0, 0, 0, 0), 0, Color(0, 0, 0, 0), 0, 0.0))
	hero_panel.add_theme_stylebox_override("panel", MinimalThemeScript.panel_style(Color(0, 0, 0, 0), 0, Color(0, 0, 0, 0), 0, 0.0))
	now_playing_card.add_theme_stylebox_override("panel", MinimalThemeScript.panel_style(Color(0.035, 0.045, 0.065, 0.82), 0, Color(1.0, 1.0, 1.0, 0.05), 0, 0.0))
	MinimalThemeScript.apply_mono(now_playing_kicker, 9, Color(MinimalThemeScript.PINK, 0.95))
	now_playing_kicker.add_theme_font_size_override("font_size", 9)
	MinimalThemeScript.apply_heading(now_playing_title, 14, MinimalThemeScript.TEXT)
	now_playing_title.add_theme_font_size_override("font_size", 14)
	MinimalThemeScript.apply_body(now_playing_artist, 10, Color(1.0, 1.0, 1.0, 0.68))
	now_playing_artist.add_theme_font_override("font", MinimalThemeScript.medium_font())
	MinimalThemeScript.apply_mono(now_playing_duration_value, 10, Color(1.0, 1.0, 1.0, 0.74))
	track_progress_bar.add_theme_stylebox_override("background", MinimalThemeScript.panel_style(Color(1.0, 1.0, 1.0, 0.10), 2, Color(1.0, 1.0, 1.0, 0.0), 0, 0.0))
	track_progress_bar.add_theme_stylebox_override("fill", MinimalThemeScript.panel_style(Color(MinimalThemeScript.PINK, 0.92), 2, Color(MinimalThemeScript.PINK, 0.0), 0, 0.0))
	for transport_button in [prev_track_button, play_pause_track_button, next_track_button]:
		transport_button.focus_mode = Control.FOCUS_NONE
		transport_button.flat = true
		transport_button.custom_minimum_size = Vector2(36.0, 36.0)
		transport_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		transport_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		transport_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		transport_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		transport_button.add_theme_font_override("font", MinimalThemeScript.medium_font())
		transport_button.add_theme_font_size_override("font_size", 14)
		transport_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.78))
		transport_button.add_theme_color_override("font_hover_color", MinimalThemeScript.PINK)
		transport_button.add_theme_color_override("font_pressed_color", MinimalThemeScript.PINK)
		transport_button.add_theme_color_override("font_focus_color", MinimalThemeScript.PINK)
	best_card.add_theme_stylebox_override("panel", _personal_best_card_style(_difficulty_color(selected_difficulty)))
	details_panel.add_theme_stylebox_override("panel", _details_card_style(_difficulty_color(selected_difficulty)))
	if details_modern_root != null:
		var detail_card_accents: Array[Color] = [MinimalThemeScript.CYAN, MinimalThemeScript.GOLD, MinimalThemeScript.PINK]
		var modern_grid := details_modern_root.get_node_or_null("ModernDetailsGrid") as GridContainer
		if modern_grid != null:
			for idx in range(modern_grid.get_child_count()):
				var detail_card := modern_grid.get_child(idx)
				if detail_card is PanelContainer:
					(detail_card as PanelContainer).add_theme_stylebox_override("panel", _record_metric_style(detail_card_accents[idx % detail_card_accents.size()]))
		if details_modern_root.get_child_count() > 1 and details_modern_root.get_child(1) is PanelContainer:
			(details_modern_root.get_child(1) as PanelContainer).add_theme_stylebox_override("panel", _record_metric_style(MinimalThemeScript.CYAN))
	MinimalThemeScript.apply_heading(details_title, 15, MinimalThemeScript.TEXT)
	MinimalThemeScript.apply_mono(details_status, 11, MinimalThemeScript.SUCCESS)
	MinimalThemeScript.apply_mono(ranking_context, 10, Color(MinimalThemeScript.TEXT, 0.58))
	MinimalThemeScript.apply_body(details_footer, 11, Color(MinimalThemeScript.TEXT, 0.66))
	for button in [details_tab_button, ranking_tab_button]:
		button.add_theme_font_override("font", MinimalThemeScript.semibold_font())
		button.add_theme_font_size_override("font_size", 12)
	var quick_accents: Array[Color] = [MinimalThemeScript.CYAN, MinimalThemeScript.GOLD, MinimalThemeScript.PINK]
	for index in range(quick_stats.get_child_count()):
		var card := quick_stats.get_child(index)
		if card is PanelContainer:
			var quick_accent := quick_accents[index % quick_accents.size()]
			(card as PanelContainer).add_theme_stylebox_override("panel", _metric_card_style(quick_accent, false))
	var breakdown_accents: Array[Color] = [MinimalThemeScript.CYAN, MinimalThemeScript.PINK, MinimalThemeScript.GOLD]
	for index in range(breakdown_grid.get_child_count()):
		var breakdown_card := breakdown_grid.get_child(index)
		if breakdown_card is PanelContainer:
			var breakdown_accent := breakdown_accents[index % breakdown_accents.size()]
			(breakdown_card as PanelContainer).add_theme_stylebox_override("panel", _record_metric_style(breakdown_accent))
	var record_accents: Array[Color] = [MinimalThemeScript.PINK, MinimalThemeScript.CYAN, MinimalThemeScript.GOLD]
	for index in range(best_grid.get_child_count()):
		var card := best_grid.get_child(index)
		if card is PanelContainer:
			var record_accent := record_accents[index % record_accents.size()]
			(card as PanelContainer).add_theme_stylebox_override("panel", _record_metric_style(record_accent))
	MinimalThemeScript.style_primary(play_button)
	MinimalThemeScript.apply_mono(count_label, 12, MinimalThemeScript.PINK)
	MinimalThemeScript.apply_body(detail_meta, 15, Color(MinimalThemeScript.TEXT, 0.72))
	MinimalThemeScript.apply_body(detail_description, 13, MinimalThemeScript.CYAN)
	detail_description.add_theme_font_override("font", MinimalThemeScript.semibold_font())
	MinimalThemeScript.apply_mono(detail_flavor, 11, MinimalThemeScript.TEXT)
	MinimalThemeScript.apply_mono(selection_index, 11, MinimalThemeScript.MUTED)
	MinimalThemeScript.apply_mono(mode_status, 11, MinimalThemeScript.SUCCESS)
	for value_label in [bpm_value, duration_value, notes_value]:
		MinimalThemeScript.apply_numeric(value_label, 20, MinimalThemeScript.TEXT)
	for value_label in [normal_notes_value, reverse_notes_value, space_notes_value]:
		MinimalThemeScript.apply_numeric(value_label, 24, MinimalThemeScript.TEXT)
	for value_label in [best_score_value, best_accuracy_value, best_combo_value]:
		MinimalThemeScript.apply_numeric(value_label, 24, MinimalThemeScript.TEXT)
	MinimalThemeScript.apply_mono(best_plays_value, 12, MinimalThemeScript.MUTED)
	MinimalThemeScript.apply_body(best_stats_label, 12, Color(MinimalThemeScript.TEXT, 0.80))
	best_stats_label.add_theme_font_override("font", MinimalThemeScript.medium_font())
	for candidate in find_children("*Caption", "Label", true, false):
		MinimalThemeScript.apply_body(candidate as Label, 10, MinimalThemeScript.MUTED)
		(candidate as Label).add_theme_font_override("font", MinimalThemeScript.medium_font())
	MinimalThemeScript.apply_heading(best_caption, 15, MinimalThemeScript.TEXT)
	MinimalThemeScript.apply_body(best_subcaption, 10, Color(MinimalThemeScript.TEXT, 0.52))
	MinimalThemeScript.apply_body(best_rank_caption, 10, MinimalThemeScript.MUTED)
	rank_label.add_theme_font_override("font", MinimalThemeScript.display_font())
	MinimalThemeScript.apply_mono(wheel_mode_label, 11, MinimalThemeScript.MUTED)
	_style_search_input(search_input)
	_style_song_scrollbar()
	_apply_album_flow_song_library_theme()
	MinimalThemeScript.apply_mono(library_hint, 11, MinimalThemeScript.MUTED)
	MinimalThemeScript.apply_mono(footer_status, 11, MinimalThemeScript.MUTED)
	MinimalThemeScript.apply_mono(progress_status, 11, MinimalThemeScript.CYAN)

func _metric_card_style(accent: Color, record_card: bool) -> StyleBoxFlat:
	var fill_alpha := 0.15 if record_card else 0.10
	var border_alpha := 0.34 if record_card else 0.22
	var style := MinimalThemeScript.panel_style(Color(MinimalThemeScript.SURFACE, fill_alpha), 6, Color(accent, border_alpha), 1, 7.0)
	style.border_width_left = 2
	style.content_margin_left = 9.0
	style.content_margin_right = 9.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	return style

func _personal_best_card_style(accent: Color) -> StyleBoxFlat:
	var style := MinimalThemeScript.panel_style(Color(MinimalThemeScript.SURFACE, 0.26), 10, Color(accent, 0.52), 1, 12.0)
	style.border_width_left = 3
	style.content_margin_left = 0.0
	style.content_margin_right = 0.0
	style.content_margin_top = 0.0
	style.content_margin_bottom = 0.0
	return style

func _details_card_style(accent: Color) -> StyleBoxFlat:
	var style := MinimalThemeScript.panel_style(Color(MinimalThemeScript.SURFACE, 0.20), 8, Color(accent, 0.30), 1, 10.0)
	style.border_width_left = 2
	style.content_margin_left = 0.0
	style.content_margin_right = 0.0
	style.content_margin_top = 0.0
	style.content_margin_bottom = 0.0
	return style

func _info_tab_style(selected: bool, accent: Color) -> StyleBoxFlat:
	var fill := Color(accent, 0.20) if selected else Color(MinimalThemeScript.SURFACE, 0.05)
	var border := Color(accent, 0.74) if selected else Color(MinimalThemeScript.BORDER, 0.18)
	var style := MinimalThemeScript.panel_style(fill, 4, border, 0, 8.0)
	style.border_width_bottom = 2 if selected else 1
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style

func _refresh_info_tab_style() -> void:
	var accent := _difficulty_color(selected_difficulty)
	var details_selected := selected_info_tab == "details"
	var ranking_selected := selected_info_tab == "ranking"
	for state in ["normal", "hover", "pressed", "focus"]:
		details_tab_button.add_theme_stylebox_override(state, _info_tab_style(details_selected, accent))
		ranking_tab_button.add_theme_stylebox_override(state, _info_tab_style(ranking_selected, accent))
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		details_tab_button.add_theme_color_override(color_name, MinimalThemeScript.TEXT if details_selected else Color(MinimalThemeScript.TEXT, 0.66))
		ranking_tab_button.add_theme_color_override(color_name, MinimalThemeScript.TEXT if ranking_selected else Color(MinimalThemeScript.TEXT, 0.66))

	composition.apply(self)

func _set_info_tab(_tab_id: String, animate: bool = true) -> void:
	# Retain the Details implementation but redirect every legacy call to the
	# secondary ranking surface. Album Flow keeps both legacy panels hidden.
	selected_info_tab = "ranking"
	details_panel.visible = false
	best_card.visible = not is_album_flow_library_layout_active()
	ranking_context.visible = false
	if ranking_tab_tools != null:
		ranking_tab_tools.visible = true
	_refresh_info_tab_style()
	var active: Control = best_card if best_card.visible else null
	if animate and active != null and active.visible:
		active.modulate.a = 0.45
		var tween := create_tween()
		tween.tween_property(active, "modulate:a", 1.0, 0.14).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

func _on_details_tab_pressed() -> void:
	_set_info_tab("ranking")

func _on_ranking_tab_pressed() -> void:
	_set_info_tab("ranking")

func _record_metric_style(accent: Color) -> StyleBoxFlat:
	var style := MinimalThemeScript.panel_style(Color(accent, 0.055), 6, Color(accent, 0.12), 1, 6.0)
	style.border_width_left = 0
	style.border_width_right = 0
	style.border_width_top = 0
	style.border_width_bottom = 0
	style.content_margin_left = 9.0
	style.content_margin_right = 9.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	return style


func _style_button(button: Button) -> void:
	if theme_config == null:
		return
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(color_name, theme_config.text_primary)
	var disabled_color: Color = theme_config.text_secondary
	disabled_color.a = theme_config.muted_alpha
	button.add_theme_color_override("font_disabled_color", disabled_color)
	button.add_theme_font_size_override("font_size", theme_config.button_size)

func _style_option_button(button: Button) -> void:
	if theme_config == null:
		return
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_name, theme_config.text_primary)
	button.add_theme_font_size_override("font_size", theme_config.body_size)

func _style_song_button(button: Button, _accent: Color = MinimalThemeScript.CYAN) -> void:
	if theme_config == null:
		return
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(color_name, theme_config.text_primary)
	button.add_theme_font_size_override("font_size", max(theme_config.body_size - 1, 12))
	button.add_theme_font_override("font", MinimalThemeScript.medium_font())
	button.add_theme_stylebox_override("normal", _transparent_row_style(6.0, 18.0, 18.0, 6.0, 6.0))
	button.add_theme_stylebox_override("pressed", _transparent_row_style(6.0, 18.0, 18.0, 6.0, 6.0))
	button.add_theme_stylebox_override("hover", _transparent_row_style(6.0, 18.0, 18.0, 6.0, 6.0))
	button.add_theme_stylebox_override("focus", _transparent_row_style(6.0, 18.0, 18.0, 6.0, 6.0))
	button.flat = true

func _song_row_style(fill: Color, border: Color, selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_corner_radius_all(5)
	style.set_border_width_all(0)
	if selected:
		style.border_width_left = 4
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	return style

func _transparent_row_style(radius: float, left: float, right: float, top: float, bottom: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(0, 0, 0, 0)
	style.set_corner_radius_all(int(radius))
	style.set_border_width_all(0)
	style.content_margin_left = left
	style.content_margin_right = right
	style.content_margin_top = top
	style.content_margin_bottom = bottom
	return style

func _style_search_input(input: LineEdit) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(MinimalThemeScript.SURFACE, 0.22)
	normal.border_color = Color(MinimalThemeScript.BORDER, 0.14)
	normal.set_corner_radius_all(8)
	normal.set_border_width_all(1)
	normal.content_margin_left = 14.0
	normal.content_margin_right = 14.0
	normal.content_margin_top = 6.0
	normal.content_margin_bottom = 6.0
	var focus := normal.duplicate()
	focus.bg_color = Color(MinimalThemeScript.SURFACE, 0.34)
	focus.border_color = Color(MinimalThemeScript.CYAN, 0.64)
	var read_only := normal.duplicate()
	read_only.bg_color = Color(MinimalThemeScript.SURFACE, 0.34)
	read_only.border_color = Color(MinimalThemeScript.BORDER, 0.10)
	input.add_theme_stylebox_override("normal", normal)
	input.add_theme_stylebox_override("focus", focus)
	input.add_theme_stylebox_override("read_only", read_only)
	input.add_theme_stylebox_override("hover", focus)
	input.add_theme_font_size_override("font_size", 12)

func _style_compact_option_button(button: Button) -> void:
	var normal := MinimalThemeScript.button_style(Color(MinimalThemeScript.SURFACE, 0.22), Color(MinimalThemeScript.BORDER, 0.10), 8)
	var hover := MinimalThemeScript.button_style(Color(MinimalThemeScript.CYAN, 0.08), Color(MinimalThemeScript.CYAN, 0.48), 8)
	var pressed := MinimalThemeScript.button_style(Color(MinimalThemeScript.CYAN, 0.12), MinimalThemeScript.CYAN, 8)
	var focus := MinimalThemeScript.button_style(Color(MinimalThemeScript.SURFACE, 0.36), MinimalThemeScript.PINK, 8)
	for style in [normal, hover, pressed, focus]:
		style.content_margin_left = 14.0
		style.content_margin_right = 38.0
		style.content_margin_top = 5.0
		style.content_margin_bottom = 5.0
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_font_size_override("font_size", 12)


func _style_action_back(button: Button) -> void:
	var normal := MinimalThemeScript.button_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0)
	var hover := MinimalThemeScript.button_style(Color(MinimalThemeScript.ACCENT, 0.07), Color(0, 0, 0, 0), 0)
	var pressed := MinimalThemeScript.button_style(Color(MinimalThemeScript.ACCENT, 0.12), Color(0, 0, 0, 0), 0)
	var focus := hover.duplicate()
	for style in [normal, hover, pressed, focus]:
		style.content_margin_left = 4.0
		style.content_margin_right = 8.0
		style.content_margin_top = 3.0
		style.content_margin_bottom = 3.0
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_font_size_override("font_size", 10)
	button.add_theme_color_override("font_color", Color(MinimalThemeScript.TEXT, 0.90))
	button.add_theme_color_override("font_hover_color", MinimalThemeScript.TEXT)

func _style_random_toggle(button: Button) -> void:
	var normal := MinimalThemeScript.button_style(Color(MinimalThemeScript.SURFACE, 0.10), Color(MinimalThemeScript.BORDER, 0.10), 7)
	var hover := MinimalThemeScript.button_style(Color(MinimalThemeScript.CYAN, 0.06), Color(MinimalThemeScript.CYAN, 0.28), 7)
	var pressed := MinimalThemeScript.button_style(Color(MinimalThemeScript.CYAN, 0.13), Color(MinimalThemeScript.CYAN, 0.62), 7)
	var focus := MinimalThemeScript.button_style(Color(MinimalThemeScript.SURFACE, 0.16), Color(MinimalThemeScript.PINK, 0.54), 7)
	for style in [normal, hover, pressed, focus]:
		style.content_margin_left = 10.0
		style.content_margin_right = 10.0
		style.content_margin_top = 4.0
		style.content_margin_bottom = 4.0
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_font_size_override("font_size", 10)
	button.add_theme_color_override("font_color", Color(MinimalThemeScript.MUTED, 0.90))
	button.add_theme_color_override("font_hover_color", MinimalThemeScript.TEXT)
	button.add_theme_color_override("font_pressed_color", MinimalThemeScript.CYAN)
	button.add_theme_color_override("font_focus_color", MinimalThemeScript.TEXT)

func _style_mods_ui() -> void:
	mods_panel.add_theme_stylebox_override("panel", MinimalThemeScript.panel_style(Color(MinimalThemeScript.SURFACE, 0.992), 12, Color(MinimalThemeScript.CYAN, 0.36), 1, 0.0))
	MinimalThemeScript.apply_heading(mods_title, 22, MinimalThemeScript.TEXT)
	MinimalThemeScript.apply_body(mods_subtitle, 12, Color(MinimalThemeScript.MUTED, 0.92))
	MinimalThemeScript.apply_mono(mode_section, 10, MinimalThemeScript.CYAN)
	MinimalThemeScript.apply_mono(modifier_section, 10, MinimalThemeScript.PINK)
	MinimalThemeScript.apply_mono(mods_summary_label, 11, MinimalThemeScript.MUTED)
	MinimalThemeScript.style_secondary(mods_close_button, MinimalThemeScript.CYAN)
	mods_close_button.add_theme_font_size_override("font_size", 18)
	for button in [mode_8_button, mode_4_button, random_mod_button]:
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 12)

func _style_mod_option(button: Button, active: bool, accent: Color) -> void:
	var normal_fill := Color(accent, 0.17) if active else Color(MinimalThemeScript.SURFACE_RAISED, 0.54)
	var normal_border := Color(accent, 0.92) if active else Color(MinimalThemeScript.BORDER, 0.76)
	var hover_fill := Color(accent, 0.22 if active else 0.10)
	var pressed_fill := Color(accent, 0.28)
	var normal := MinimalThemeScript.button_style(normal_fill, normal_border, 10)
	var hover := MinimalThemeScript.button_style(hover_fill, accent, 10)
	var pressed := MinimalThemeScript.button_style(pressed_fill, accent, 10)
	var focus := MinimalThemeScript.button_style(normal_fill, MinimalThemeScript.TEXT if active else accent, 10)
	for box in [normal, hover, pressed, focus]:
		box.content_margin_left = 12.0
		box.content_margin_right = 12.0
		box.content_margin_top = 7.0
		box.content_margin_bottom = 7.0
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", MinimalThemeScript.TEXT if active else Color(MinimalThemeScript.TEXT, 0.70))
	button.add_theme_color_override("font_hover_color", MinimalThemeScript.TEXT)
	button.add_theme_color_override("font_pressed_color", MinimalThemeScript.TEXT)
	button.add_theme_color_override("font_focus_color", MinimalThemeScript.TEXT)

func _style_album_segment_button(button: Button, active: bool) -> void:
	var accent := MinimalThemeScript.CYAN
	var normal := MinimalThemeScript.button_style(Color(MinimalThemeScript.BG, 0.38), Color(MinimalThemeScript.BORDER, 0.24), 4)
	var hover := MinimalThemeScript.button_style(Color(accent, 0.08), Color(accent, 0.58), 4)
	var pressed := MinimalThemeScript.button_style(Color(accent, 0.13), Color(accent, 0.92), 4)
	var focus := hover
	if active:
		normal = MinimalThemeScript.button_style(Color(accent, 0.11), Color(accent, 0.96), 4)
		hover = MinimalThemeScript.button_style(Color(accent, 0.15), accent, 4)
		pressed = hover
		focus = hover
	for style in [normal, hover, pressed, focus]:
		style.content_margin_left = 12.0
		style.content_margin_right = 12.0
		style.content_margin_top = 9.0
		style.content_margin_bottom = 9.0
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_font_override("font", MinimalThemeScript.semibold_font())
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", MinimalThemeScript.TEXT if active else Color(MinimalThemeScript.TEXT, 0.62))
	button.add_theme_color_override("font_hover_color", MinimalThemeScript.TEXT)
	button.add_theme_color_override("font_pressed_color", MinimalThemeScript.TEXT)
	button.add_theme_color_override("font_focus_color", MinimalThemeScript.TEXT)

func _style_album_secondary_chip(button: Button, active: bool, accent: Color) -> void:
	var normal := MinimalThemeScript.button_style(Color(MinimalThemeScript.BG, 0.34), Color(MinimalThemeScript.BORDER, 0.24), 4)
	var hover := MinimalThemeScript.button_style(Color(accent, 0.08), Color(accent, 0.56), 4)
	var pressed := MinimalThemeScript.button_style(Color(accent, 0.13), Color(accent, 0.82), 4)
	if active:
		normal = MinimalThemeScript.button_style(Color(accent, 0.11), Color(accent, 0.88), 4)
	for style in [normal, hover, pressed]:
		style.content_margin_left = 10.0
		style.content_margin_right = 10.0
		style.content_margin_top = 8.0
		style.content_margin_bottom = 8.0
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_font_override("font", MinimalThemeScript.mono_font())
	button.add_theme_font_size_override("font_size", 10)
	button.add_theme_color_override("font_color", accent if active else Color(MinimalThemeScript.TEXT, 0.68))
	button.add_theme_color_override("font_hover_color", MinimalThemeScript.TEXT)
	button.add_theme_color_override("font_pressed_color", MinimalThemeScript.TEXT)

func _style_album_difficulty_button(button: Button, selected: bool, available: bool, accent: Color) -> void:
	var normal := MinimalThemeScript.button_style(
		Color(accent, 0.10) if selected else Color(MinimalThemeScript.BG, 0.32),
		Color(accent, 0.90) if selected else Color(MinimalThemeScript.BORDER, 0.22 if available else 0.08),
		4
	)
	var hover := MinimalThemeScript.button_style(Color(accent, 0.09), Color(accent, 0.64), 4)
	var pressed := MinimalThemeScript.button_style(Color(accent, 0.16), Color(accent, 0.92), 4)
	for style in [normal, hover, pressed]:
		style.content_margin_left = 8.0
		style.content_margin_right = 8.0
		style.content_margin_top = 7.0
		style.content_margin_bottom = 7.0
	for pair in [["normal", normal], ["hover", hover], ["pressed", pressed], ["focus", hover], ["disabled", normal]]:
		button.add_theme_stylebox_override(pair[0], pair[1])
	button.modulate.a = 1.0 if available else 0.38

func _set_album_flow_play_text(label_text: String) -> void:
	if play_button == null:
		return
	play_button.text = "◇     PLAY     →" if label_text == "PLAY" else label_text

func _select_song_relative(delta: int) -> void:
	if filtered_song_ids.is_empty():
		return
	var current_index := filtered_song_ids.find(selected_song_id)
	if current_index < 0:
		current_index = 0
	current_index = wrapi(current_index + delta, 0, filtered_song_ids.size())
	_select_song(filtered_song_ids[current_index])

func _style_album_play_button() -> void:
	if not play_button.disabled:
		_set_album_flow_play_text("PLAY")
	var normal := MinimalThemeScript.button_style(Color(MinimalThemeScript.BG, 0.84), Color(MinimalThemeScript.CYAN, 0.82), 5)
	var hover := MinimalThemeScript.button_style(Color(MinimalThemeScript.SURFACE_RAISED, 0.90), MinimalThemeScript.CYAN, 5)
	var pressed := MinimalThemeScript.button_style(Color(MinimalThemeScript.CYAN, 0.16), MinimalThemeScript.CYAN, 5)
	var disabled := MinimalThemeScript.button_style(Color(MinimalThemeScript.SURFACE, 0.20), Color(MinimalThemeScript.BORDER, 0.10), 5)
	for style in [normal, hover, pressed, disabled]:
		style.content_margin_left = 22.0
		style.content_margin_right = 22.0
	play_button.add_theme_stylebox_override("normal", normal)
	play_button.add_theme_stylebox_override("hover", hover)
	play_button.add_theme_stylebox_override("pressed", pressed)
	play_button.add_theme_stylebox_override("focus", hover)
	play_button.add_theme_stylebox_override("disabled", disabled)
	play_button.add_theme_font_override("font", MinimalThemeScript.display_font())
	play_button.add_theme_font_size_override("font_size", 23)
	play_button.add_theme_color_override("font_color", MinimalThemeScript.TEXT)
	play_button.add_theme_color_override("font_hover_color", MinimalThemeScript.TEXT)
	play_button.add_theme_color_override("font_pressed_color", MinimalThemeScript.TEXT)
	play_button.add_theme_color_override("font_disabled_color", Color(MinimalThemeScript.MUTED, 0.42))

func _style_song_scrollbar() -> void:
	var bar := song_scroll.get_v_scroll_bar()
	if bar == null:
		return
	bar.custom_minimum_size.x = 2.0
	bar.add_theme_constant_override("minimum_grab_length", 30)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(MinimalThemeScript.BG, 0.0)
	track.set_corner_radius_all(1)
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color(MinimalThemeScript.MUTED, 0.20)
	grabber.set_corner_radius_all(1)
	var grabber_hover := grabber.duplicate()
	grabber_hover.bg_color = Color(MinimalThemeScript.CYAN, 0.40)
	var grabber_pressed := grabber.duplicate()
	grabber_pressed.bg_color = Color(MinimalThemeScript.CYAN, 0.58)
	bar.add_theme_stylebox_override("scroll", track)
	bar.add_theme_stylebox_override("scroll_focus", track)
	bar.add_theme_stylebox_override("grabber", grabber)
	bar.add_theme_stylebox_override("grabber_highlight", grabber_hover)
	bar.add_theme_stylebox_override("grabber_pressed", grabber_pressed)

func _animate_enter() -> void:
	if not is_visible_in_tree():
		return
	transitioning_out = false
	_unlock_navigation_controls()
	if intro_tween != null:
		intro_tween.kill()
	info_panel.modulate.a = 0.0
	wheel_column.modulate.a = 0.0
	footer_panel.modulate.a = 0.0
	header_row.modulate.a = 0.0
	info_panel.scale = Vector2.ONE
	wheel_column.scale = Vector2.ONE
	footer_panel.scale = Vector2.ONE
	intro_tween = create_tween()
	intro_tween.set_parallel(true)
	intro_tween.tween_property(header_row, "modulate:a", 1.0, 0.14)
	intro_tween.tween_property(info_panel, "modulate:a", 1.0, 0.24).set_delay(0.02)
	intro_tween.tween_property(wheel_column, "modulate:a", 1.0, 0.28).set_delay(0.04)
	intro_tween.tween_property(footer_panel, "modulate:a", 1.0, 0.14).set_delay(0.06)
	# Song rows stay resident and visible. The shell provides the route motion;
	# avoid allocating one tween per row on every reveal.
	for group_value in song_groups:
		var group := group_value as Control
		if group != null:
			group.modulate.a = 1.0
	call_deferred("_center_selected_row", false)
	call_deferred("focus_current_selection")

func _open_mods_panel() -> void:
	if transitioning_out:
		return
	_sync_mods_panel(false)
	mods_overlay.visible = true
	mods_overlay.modulate.a = 0.0
	mods_panel.scale = Vector2(0.97, 0.97)
	mods_panel.pivot_offset = mods_panel.size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(mods_overlay, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(mods_panel, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	if UserSettingsScript.get_input_style() == "4_arrow":
		mode_4_button.grab_focus()
	else:
		mode_8_button.grab_focus()

func _close_mods_panel() -> void:
	if not mods_overlay.visible:
		return
	mods_overlay.visible = false
	call_deferred("focus_current_selection")

func _on_mods_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_close_mods_panel()

func _on_mode_8_selected() -> void:
	# Input mode is an identity component of score lookup, but not a cached chart
	# object. Re-resolve song/difficulty by ID on every switch so metadata and
	# records can never be left pointing at the previous mode's state.
	UserSettingsScript.set_input_style("8_direction")
	_sync_mods_panel(true)

func _on_mode_4_selected() -> void:
	# See _on_mode_8_selected: _sync_mods_panel rebuilds the filtered selection,
	# then _update_detail obtains a fresh chart dictionary from the catalog.
	UserSettingsScript.set_input_style("4_arrow")
	_sync_mods_panel(true)

func _on_random_mod_toggled(enabled: bool) -> void:
	random_mode_enabled = enabled
	_sync_mods_panel(true)

func _sync_mods_panel(refresh_detail: bool = true) -> void:
	if not is_node_ready():
		return
	var is_four := UserSettingsScript.get_input_style() == "4_arrow"
	mode_8_button.set_pressed_no_signal(not is_four)
	mode_4_button.set_pressed_no_signal(is_four)
	random_mod_button.set_pressed_no_signal(random_mode_enabled)
	_style_mod_option(mode_8_button, not is_four, MinimalThemeScript.CYAN)
	_style_mod_option(mode_4_button, is_four, MinimalThemeScript.CYAN)
	_style_mod_option(random_mod_button, random_mode_enabled, MinimalThemeScript.PINK)
	var mode_short := "4K" if is_four else "8K"
	mods_button.text = "MODS · %s%s" % [mode_short, " + RND" if random_mode_enabled else ""]
	mods_summary_label.text = "%s  ·  RANDOM %s" % [mode_short, "ON" if random_mode_enabled else "OFF"]
	mods_summary_label.visible = true
	_update_album_flow_modifier_state()
	if refresh_detail:
		_apply_filters()

func set_random_mode(enabled: bool) -> void:
	random_mode_enabled = enabled
	if is_node_ready():
		_sync_mods_panel(false)
	_update_detail(false)

func get_random_mode() -> bool:
	return random_mode_enabled

func set_catalog(new_levels: Array) -> void:
	levels = new_levels
	_rebuild_song_ids()
	# v17.4.35: SongSelectionState is canonical while the app is running. This
	# keeps the Library on the same song/difficulty chosen from Main Menu instead
	# of letting an older persisted Library selection win on first entry.
	var restored_global: bool = _restore_selection_from_global_state()
	if not restored_global and selected_song_id.is_empty():
		var remembered_song_id: String = UserSettingsScript.get_last_library_song_id()
		if not remembered_song_id.is_empty() and song_ids.has(remembered_song_id):
			selected_song_id = remembered_song_id
			selected_difficulty = UserSettingsScript.get_last_library_difficulty()
	_rebuild_filters()
	_apply_filters(false)

func set_best_stats_store(store: Dictionary) -> void:
	best_stats = store
	if not is_node_ready():
		return
	# Most record updates do not change which rows exist. Rebuilding the whole
	# browser for 39 songs / 117 charts was a major source of route-entry stalls.
	# Only filters/sorts whose result depends on progress require a reconstruction.
	var progress_sensitive: bool = selected_progress_filter != "All Progress" or selected_sort_mode in ["Best Rank", "Unplayed First"]
	if progress_sensitive:
		_apply_filters(false)
	else:
		_refresh_song_rows(false)
		_update_detail(false)

func set_selected_song(song_id: String) -> void:
	if song_id.is_empty() or not song_ids.has(song_id):
		return
	var selection_changed: bool = selected_song_id != song_id
	selected_song_id = song_id
	var global_state: Dictionary = _global_selection_state()
	if str(global_state.get("song_id", "")) == song_id:
		var global_difficulty: String = str(global_state.get("difficulty_id", "")).to_lower()
		if not global_difficulty.is_empty() and _available_difficulties(song_id).has(global_difficulty):
			selected_difficulty = global_difficulty
	_ensure_difficulty_valid()

	# Selection is state, not a filter operation. If the row already exists, keep
	# all persistent controls alive and only update their selected state/detail.
	if filtered_song_ids.has(song_id):
		_refresh_song_rows(false)
		if selection_changed:
			_update_detail(false)
		call_deferred("_center_selected_row", false)
		return

	# The requested song may be excluded by an active user filter. In that uncommon
	# case retain legacy filter semantics and rebuild once.
	_apply_filters(false)

func get_selected_song_id() -> String:
	return selected_song_id

func get_selected_difficulty() -> String:
	return selected_difficulty

func get_audio_handoff() -> Dictionary:
	if selected_song_id.is_empty() or preview_player == null or not preview_player.has_method("get_audio_handoff_state"):
		return {}
	var handoff_value: Variant = preview_player.call("get_audio_handoff_state")
	if not (handoff_value is Dictionary):
		return {}
	var handoff: Dictionary = (handoff_value as Dictionary).duplicate(true)
	if handoff.is_empty():
		return {}
	var rep: Dictionary = _representative(selected_song_id)
	var chart: Dictionary = _find_level(selected_song_id, selected_difficulty)
	handoff["song_id"] = selected_song_id
	handoff["difficulty_id"] = selected_difficulty
	handoff["title"] = str(rep.get("title", chart.get("title", selected_song_id.replace("_", " "))))
	handoff["artist"] = _display_artist(rep)
	handoff["background"] = str(rep.get("background", chart.get("background", "")))
	if float(handoff.get("duration", 0.0)) <= 0.0:
		handoff["duration"] = float(chart.get("duration", rep.get("duration", 0.0)))
	return handoff

func remember_current_selection() -> void:
	if selected_song_id.is_empty():
		return
	UserSettingsScript.remember_library_selection(selected_song_id, selected_difficulty)

func focus_current_selection() -> void:
	# Song Library uses a deliberate global arrow-key navigation model rather
	# than Godot's geometric Control focus. Keep row selection visual, but
	# release stale focus from Result/Search/MODS so arrows and Enter keep their
	# documented meaning after every screen transition.
	if not is_visible_in_tree() or transitioning_out or mods_overlay.visible:
		return
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	if focus_owner != null:
		focus_owner.release_focus()

func _rebuild_song_ids() -> void:
	song_ids.clear()
	for raw_level in levels:
		if not (raw_level is Dictionary):
			continue
		var data: Dictionary = raw_level
		# Chart Studio drafts deliberately contain zero events until generation
		# succeeds. They belong in the editor, never in the playable song library.
		if not _chart_is_playable(data) or not RuntimeResourceAccessScript.audio_exists(str(data.get("audio", ""))):
			continue
		var song_id: String = str(data.get("song_id", data.get("id", "")))
		if not song_id.is_empty() and not song_ids.has(song_id):
			song_ids.append(song_id)
	song_ids.sort_custom(func(a: String, b: String):
		return str(_representative(a).get("title", a)).naturalnocasecmp_to(str(_representative(b).get("title", b))) < 0
	)

func _rebuild_filters() -> void:
	if artist_filter == null or difficulty_filter == null:
		return
	var artists: Array[String] = []
	for song_id in song_ids:
		var artist: String = _display_artist(_representative(song_id))
		if not artist.is_empty() and not artists.has(artist):
			artists.append(artist)
	artists.sort()
	artist_filter.clear()
	artist_filter.add_item("All Artists")
	for artist in artists:
		artist_filter.add_item(artist)
	_select_option_text(artist_filter, selected_artist_filter)
	difficulty_filter.clear()
	for filter_label in ["All Difficulties", "Normal", "Hard", "Master"]:
		difficulty_filter.add_item(filter_label)
	_select_option_text(difficulty_filter, selected_difficulty_filter)
	progress_filter.clear()
	for filter_label in ["All Progress", "Unplayed", "Cleared", "Full Combo"]:
		progress_filter.add_item(filter_label)
	_select_option_text(progress_filter, selected_progress_filter)
	sort_filter.clear()
	for sort_label in ["BPM Asc", "BPM Desc", "Title A–Z", "Star Rating", "Best Rank", "Unplayed First"]:
		sort_filter.add_item(sort_label)
	_select_option_text(sort_filter, selected_sort_mode)
	_sync_album_flow_header_filter_labels()

func _sync_album_flow_header_filter_labels() -> void:
	if artist_filter != null:
		artist_filter.text = selected_artist_filter.to_upper()
	if difficulty_filter != null:
		difficulty_filter.text = selected_difficulty_filter.to_upper()
	if sort_filter != null:
		sort_filter.text = selected_sort_mode.to_upper()

func _select_option_text(button, target: String) -> void:
	for i in range(button.get_item_count()):
		if button.get_item_text(i) == target:
			button.select(i)
			return
	if button.get_item_count() > 0:
		button.select(0)

func _on_artist_filter_changed(index: int) -> void:
	selected_artist_filter = artist_filter.get_item_text(index)
	_apply_filters()

func _on_difficulty_filter_changed(index: int) -> void:
	selected_difficulty_filter = difficulty_filter.get_item_text(index)
	var requested: String = selected_difficulty_filter.to_lower()
	if requested != "all difficulties":
		selected_difficulty = requested
	_apply_filters()

func _on_progress_filter_changed(index: int) -> void:
	selected_progress_filter = progress_filter.get_item_text(index)
	_apply_filters()

func _on_sort_filter_changed(index: int) -> void:
	selected_sort_mode = sort_filter.get_item_text(index)
	_apply_filters()

func _on_search_changed(value: String) -> void:
	selected_search_query = value.strip_edges().to_lower()
	_apply_filters(false)

func _apply_filters(animated: bool = true) -> void:
	filtered_song_ids.clear()
	for song_id in song_ids:
		var rep: Dictionary = _representative(song_id)
		var artist_ok: bool = selected_artist_filter == "All Artists" or _display_artist(rep) == selected_artist_filter
		var searchable := "%s %s %s" % [
			str(rep.get("title", song_id)),
			str(rep.get("artist", "Unknown Artist")),
			song_id.replace("_", " "),
		]
		var search_ok: bool = selected_search_query.is_empty() or searchable.to_lower().contains(selected_search_query)
		var difficulty_ok: bool = true
		if selected_difficulty_filter != "All Difficulties":
			difficulty_ok = not _find_level(song_id, selected_difficulty_filter.to_lower()).is_empty()
		var progress_ok := _song_matches_progress_filter(song_id)
		if artist_ok and difficulty_ok and search_ok and progress_ok:
			filtered_song_ids.append(song_id)
	_sort_filtered_song_ids()
	if filtered_song_ids.is_empty():
		selected_song_id = ""
	elif not filtered_song_ids.has(selected_song_id):
		selected_song_id = _preferred_initial_song()
	_ensure_difficulty_valid()
	_rebuild_song_list()
	_update_detail(animated)
	_sync_album_flow_header_filter_labels()

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _rebuild_song_list() -> void:
	if song_list == null:
		return
	_clear_children(song_list)
	song_buttons.clear()
	song_groups.clear()
	song_header_wrappers.clear()
	song_difficulty_clips.clear()
	song_difficulty_boxes.clear()
	song_difficulty_rows.clear()
	_kill_row_tweens()
	if not filtered_song_ids.is_empty():
		var list_top_space := Control.new()
		list_top_space.name = "ListTopSpace"
		list_top_space.custom_minimum_size.y = 8.0
		song_list.add_child(list_top_space)
	if filtered_song_ids.is_empty():
		var empty_label := Label.new()
		empty_label.name = "EmptyLibraryState"
		empty_label.custom_minimum_size.y = 180.0
		empty_label.text = "NO MATCHING SONGS\nTry another search or filter."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 15)
		empty_label.add_theme_color_override("font_color", MinimalThemeScript.MUTED)
		song_list.add_child(empty_label)
	for index in range(filtered_song_ids.size()):
		var song_id: String = filtered_song_ids[index]
		var rep: Dictionary = _representative(song_id)
		var background_texture := _song_banner_texture(song_id, str(rep.get("background", "")))
		var group := VBoxContainer.new()
		group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		group.add_theme_constant_override("separation", 0)
		song_list.add_child(group)

		var header_wrapper := AnimatedMarginScript.new() as MarginContainer
		header_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header_wrapper.call("set_margin_immediate", _song_row_base_margin(index))
		group.add_child(header_wrapper)

		var button := SongBannerButtonScript.new() as Button
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.button_pressed = song_id == selected_song_id
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = ""
		# Metadata is already visible inside the card. A native hover tooltip only
		# duplicates it and obscures neighbouring rows.
		button.tooltip_text = ""
		button.theme = song_list.theme
		button.call("configure", background_texture, LIBRARY_ACCENT, "compact_song")
		_style_song_button(button, LIBRARY_ACCENT)
		_populate_song_header_button(button, index, rep, song_id)
		button.pressed.connect(_select_song.bind(song_id))
		button.mouse_entered.connect(_on_song_row_hover.bind(index, true))
		button.mouse_exited.connect(_on_song_row_hover.bind(index, false))
		header_wrapper.add_child(button)

		var difficulty_clip := Control.new()
		difficulty_clip.clip_contents = true
		difficulty_clip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		difficulty_clip.custom_minimum_size.y = 0.0
		group.add_child(difficulty_clip)

		var difficulty_box := VBoxContainer.new()
		difficulty_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		difficulty_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		difficulty_box.add_theme_constant_override("separation", 2)
		difficulty_clip.add_child(difficulty_box)
		var group_difficulty_rows: Array = []
		var available := _available_difficulties(song_id)
		for difficulty_index in range(available.size()):
			var diff: String = available[difficulty_index]
			var chart := _find_level(song_id, diff)
			var diff_wrapper := AnimatedMarginScript.new() as MarginContainer
			diff_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			diff_wrapper.call("set_margin_immediate", _difficulty_row_base_margin(difficulty_index))
			difficulty_box.add_child(diff_wrapper)
			var diff_button := SongBannerButtonScript.new() as Button
			diff_button.toggle_mode = true
			diff_button.focus_mode = Control.FOCUS_NONE
			diff_button.set_pressed_no_signal(song_id == selected_song_id and diff == selected_difficulty)
			diff_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			diff_button.text = ""
			diff_button.custom_minimum_size.y = 36.0
			diff_button.theme = song_list.theme
			diff_button.call("configure", background_texture, _difficulty_color(diff), "difficulty")
			_style_song_difficulty_button(diff_button, diff)
			_populate_difficulty_button(diff_button, chart, diff)
			diff_button.pressed.connect(_select_song_difficulty.bind(song_id, diff))
			diff_button.mouse_entered.connect(_on_difficulty_row_hover.bind(index, difficulty_index, true))
			diff_button.mouse_exited.connect(_on_difficulty_row_hover.bind(index, difficulty_index, false))
			diff_wrapper.add_child(diff_button)
			group_difficulty_rows.append({"wrapper": diff_wrapper, "button": diff_button, "difficulty": diff})
		difficulty_box.custom_minimum_size.y = _difficulty_stack_height(group_difficulty_rows)

		song_groups.append(group)
		song_header_wrappers.append(header_wrapper)
		song_difficulty_clips.append(difficulty_clip)
		song_difficulty_boxes.append(difficulty_box)
		song_difficulty_rows.append(group_difficulty_rows)
		song_buttons.append(button)
	var totals := _completion_totals()
	count_label.text = "SONG LIBRARY"
	wheel_mode_label.text = "ARTIST                    BPM" if is_album_flow_library_layout_active() else "%d TRACK%s" % [song_ids.size(), "" if song_ids.size() == 1 else "S"]
	library_hint.text = "%d VISIBLE  ·  %d CLEARED" % [filtered_song_ids.size(), totals[0]]
	_refresh_song_rows(false)
	call_deferred("_center_selected_row", false)

func _populate_song_header_button(button: Button, index: int, rep: Dictionary, song_id: String) -> void:
	var content := MarginContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("margin_left", 8)
	content.add_theme_constant_override("margin_right", 12)
	content.add_theme_constant_override("margin_top", 6)
	content.add_theme_constant_override("margin_bottom", 6)
	button.add_child(content)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	content.add_child(row)

	var index_label := Label.new()
	index_label.name = "SongIndex"
	index_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	index_label.text = "%02d" % (index + 1)
	index_label.custom_minimum_size.x = 30
	index_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	MinimalThemeScript.apply_mono(index_label, 10, Color(MinimalThemeScript.TEXT, 0.52))
	row.add_child(index_label)

	var marker := Label.new()
	marker.name = "SongMarker"
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.text = ""
	marker.custom_minimum_size.x = 16
	marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MinimalThemeScript.apply_mono(marker, 9, Color(LIBRARY_ACCENT, 0.70))
	row.add_child(marker)

	var thumb := TextureRect.new()
	thumb.name = "SongJacket"
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb.custom_minimum_size = Vector2(44, 44)
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	thumb.texture = _song_banner_texture(song_id, str(rep.get("background", "")))
	row.add_child(thumb)

	var title := Label.new()
	title.name = "SongTitle"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = str(rep.get("title", "SONG"))
	title.add_theme_font_override("font", MinimalThemeScript.semibold_font())
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1, 1, 1, 0.96))
	title.set_meta("base_alpha", 0.96)
	title.set_meta("label_role", "song_title")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(title)

	var artist := Label.new()
	artist.name = "SongArtist"
	artist.mouse_filter = Control.MOUSE_FILTER_IGNORE
	artist.text = _display_artist(rep)
	artist.custom_minimum_size.x = 118
	artist.add_theme_font_override("font", MinimalThemeScript.body_font())
	artist.add_theme_font_size_override("font_size", 10)
	artist.add_theme_color_override("font_color", Color(1, 1, 1, 0.58))
	artist.set_meta("base_alpha", 0.58)
	artist.set_meta("label_role", "song_subtitle")
	artist.clip_text = true
	artist.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(artist)

	var bpm_label := Label.new()
	bpm_label.name = "SongBpm"
	bpm_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bpm_label.text = str(int(round(float(rep.get("bpm", 0.0)))))
	bpm_label.custom_minimum_size.x = 52
	bpm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bpm_label.add_theme_font_override("font", MinimalThemeScript.mono_font())
	bpm_label.add_theme_font_size_override("font_size", 10)
	bpm_label.add_theme_color_override("font_color", Color(MinimalThemeScript.TEXT, 0.68))
	bpm_label.set_meta("base_alpha", 0.68)
	bpm_label.set_meta("label_role", "song_level")
	row.add_child(bpm_label)

func _album_flow_song_level(song_id: String) -> int:
	var diffs := _available_difficulties(song_id)
	if diffs.is_empty():
		return 0
	var preferred := "master" if diffs.has("master") else diffs[diffs.size() - 1]
	var chart := _find_level(song_id, preferred)
	return int(chart.get("star_rating", 1))

func _apply_song_header_text_emphasis(button: Button, is_selected: bool, distance: int) -> void:
	var proximity := clampf(1.0 - float(distance) / 5.0, 0.0, 1.0)
	for node in button.find_children("*", "Label", true, false):
		var label := node as Label
		if label == null:
			continue
		var base_alpha := float(label.get_meta("base_alpha")) if label.has_meta("base_alpha") else 0.92
		var role := str(label.get_meta("label_role")) if label.has_meta("label_role") else ""
		var alpha := base_alpha
		if not is_selected:
			match role:
				"song_title":
					alpha = clampf(base_alpha * lerpf(0.86, 0.94, proximity), 0.80, 0.98)
				"song_subtitle":
					alpha = clampf(base_alpha * lerpf(0.78, 0.86, proximity), 0.70, 0.90)
				_:
					alpha = clampf(base_alpha * lerpf(0.48, 0.66, proximity), 0.32, 0.64)
		label.add_theme_color_override("font_color", Color(1, 1, 1, alpha))
		var shadow_alpha := 0.78 if is_selected else clampf(0.54 + proximity * 0.08, 0.46, 0.64)
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, shadow_alpha))

func _populate_difficulty_button(button: Button, chart: Dictionary, diff: String) -> void:
	var content := MarginContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("margin_left", 14)
	content.add_theme_constant_override("margin_right", 14)
	content.add_theme_constant_override("margin_top", 4)
	content.add_theme_constant_override("margin_bottom", 4)
	button.add_child(content)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", 14)
	content.add_child(row)

	var events: Variant = chart.get("events", [])
	var notes: int = (events as Array).size() if events is Array else 0
	var label_text: String = str(chart.get("difficulty", diff.to_upper())).to_upper()
	var stars: int = int(chart.get("star_rating", 1))
	var song_id: String = str(chart.get("song_id", selected_song_id))
	var progress: Dictionary = _progress_entry(song_id, diff)
	var progress_text: String = _progress_short_label(progress)

	var entries: Array = [
		[label_text, 0.98, 88],
		["%d★" % stars, 0.94, 48],
		[("%d NOTES" % notes) if notes > 0 else "— NOTES", 0.88, 96]
	]
	# Do not print UNPLAYED/REC on every row. Only surface actual player progress.
	if progress_text != "UNPLAYED":
		entries.append([progress_text, 0.90, 0])

	for pair: Variant in entries:
		var txt: String = str((pair as Array)[0])
		if txt.is_empty():
			continue
		var item := Label.new()
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.text = txt
		item.add_theme_font_override("font", MinimalThemeScript.mono_font())
		item.add_theme_font_size_override("font_size", 12)
		item.custom_minimum_size.x = float((pair as Array)[2])
		item.add_theme_color_override("font_color", Color(1, 1, 1, float((pair as Array)[1])))
		item.set_meta("base_alpha", float((pair as Array)[1]))
		item.set_meta("label_role", "difficulty_item")
		item.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.72))
		item.add_theme_constant_override("shadow_offset_x", 1)
		item.add_theme_constant_override("shadow_offset_y", 1)
		row.add_child(item)

func _difficulty_row_text(chart: Dictionary, diff: String) -> String:
	var events: Variant = chart.get("events", [])
	var notes: int = (events as Array).size() if events is Array else 0
	var label: String = str(chart.get("difficulty", diff.to_upper())).to_upper()
	var stars: int = int(chart.get("star_rating", 1))
	if notes <= 0:
		return "%s   %d★   —" % [label, stars]
	var song_id: String = str(chart.get("song_id", selected_song_id))
	var progress: Dictionary = _progress_entry(song_id, diff)
	var status: String = _progress_short_label(progress)
	return "%s   %d★   %d%s" % [label, stars, notes, "   " + status if status != "UNPLAYED" else ""]

func _style_song_difficulty_button(button: Button, _difficulty_id: String) -> void:
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_name, MinimalThemeScript.TEXT)
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_font_override("font", MinimalThemeScript.mono_font())
	button.add_theme_stylebox_override("normal", _transparent_row_style(7.0, 14.0, 14.0, 5.0, 5.0))
	button.add_theme_stylebox_override("hover", _transparent_row_style(7.0, 14.0, 14.0, 5.0, 5.0))
	button.add_theme_stylebox_override("pressed", _transparent_row_style(7.0, 14.0, 14.0, 5.0, 5.0))
	button.add_theme_stylebox_override("focus", _transparent_row_style(7.0, 14.0, 14.0, 5.0, 5.0))
	button.flat = true

func _difficulty_row_style(fill: Color, border: Color, _accent: Color, selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_corner_radius_all(7)
	style.set_border_width_all(1)
	style.border_width_left = 0 if not selected else 3
	style.content_margin_left = 12.0
	style.content_margin_right = 14.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	return style

func _select_song_difficulty(song_id: String, difficulty_id: String) -> void:
	if selected_song_id != song_id:
		selected_song_id = song_id
	selected_difficulty = difficulty_id
	_refresh_song_rows(true)
	_queue_detail_transition()
	call_deferred("_center_selected_row", true)

func _song_chart_summary(song_id: String) -> String:
	var available := _available_difficulties(song_id)
	var playable_count := 0
	var cleared_count := 0
	var fc_count := 0
	for diff in available:
		if _chart_is_playable(_find_level(song_id, diff)):
			playable_count += 1
		var progress := _progress_entry(song_id, diff)
		if bool(progress.get("cleared", false)):
			cleared_count += 1
		if bool(progress.get("full_combo", false)):
			fc_count += 1
	if playable_count <= 0:
		return "NOT GENERATED"
	var summary := "%d/%d CLEAR" % [cleared_count, available.size()]
	if fc_count > 0:
		summary += "  ·  %d FC" % fc_count
	return summary

func _display_artist(rep: Dictionary) -> String:
	var artist := str(rep.get("artist", "")).strip_edges()
	if artist.is_empty() or artist.to_lower() in ["unknown", "unknown artist", "n/a", "none"]:
		return ""
	return artist

func _song_accent(song_id: String) -> Color:
	match song_id:
		"2_starting_over": return Color("53c6ff")
		"3_bow_for_me": return Color("ef67b8")
		"5_flying_temple": return Color("54dcc7")
		"aresenes_bazaar": return Color("e5aa62")
		"ascend": return Color("6daeff")
		"bad_apple": return Color("dc5b85")
		"can_can_audition": return Color("f1ac63")
		"diana_boncheva_feat_banya_beethoven_virus_full_version": return Color("8f83ff")
		"freedom_dive": return Color("58d4ff")
		"megalovania": return Color("ef7077")
		"orpheus_can_can": return Color("f0c470")
		"the_lab": return Color("66e8bf")
		"vessel": return Color("7caeff")
		"death_by_glamour": return Color("f06fc8")
		"battle_against_a_true_hero": return Color("84a9ff")
		"moonlight_sonata_3rd_movement_meganeko_remix": return Color("9baef9")
		"blue_zenith": return Color("5fd7ff")
		"exit_this_earths_atomosphere": return Color("ff65bf")
		"septette_for_the_dead_princess": return Color("d35b83")
		"aleph_0": return Color("ac79ff")
		"night_of_nights": return Color("e27ada")
		"spider_dance": return Color("d468c9")
		"un_owen_was_her": return Color("ff6e78")
		"necrofantasia": return Color("64c5b5")
		"oshama_scramble": return Color("ffba6c")
		"big_daddy": return Color("ff8a5b")
		_:
			return MinimalThemeScript.CYAN

func _select_song(song_id: String) -> void:
	if selected_song_id == song_id:
		_refresh_song_rows(true)
		return
	selected_song_id = song_id
	_ensure_difficulty_valid()
	_refresh_song_rows(true)
	_queue_detail_transition()
	call_deferred("_center_selected_row", true)

func _refresh_song_rows(animated: bool) -> void:
	if layout_config == null or song_buttons.is_empty():
		return
	selection_animation_generation += 1
	selection_motion_elapsed = 0.0 if animated else 1.0
	var generation := selection_animation_generation
	if selection_tween != null:
		selection_tween.kill()
		selection_tween = null
	if animated:
		selection_tween = create_tween()
		selection_tween.set_parallel(true)

	var selected_index := filtered_song_ids.find(selected_song_id)
	for i in range(song_buttons.size()):
		var button: Button = song_buttons[i]
		var is_selected: bool = i < filtered_song_ids.size() and filtered_song_ids[i] == selected_song_id
		button.set_pressed_no_signal(is_selected)
		button.queue_redraw()
		var target_height := 70.0 if is_selected else 58.0
		var distance: int = absi(i - selected_index) if selected_index >= 0 else 4
		var art_emphasis := 1.0 if is_selected else clampf(0.88 - float(distance) * 0.065, 0.54, 0.82)
		button.modulate.a = 1.0
		button.call("set_visual_emphasis", art_emphasis)
		button.add_theme_font_size_override("font_size", theme_config.body_size - 1 if is_selected else theme_config.body_size - 2)
		_apply_song_header_text_emphasis(button, is_selected, distance)
		var marker := button.find_child("SongMarker", true, false) as Label
		if marker != null:
			marker.text = "◆" if is_selected else ""
			marker.add_theme_color_override("font_color", Color(LIBRARY_ACCENT, 0.96 if is_selected else 0.18))
		var index_label := button.find_child("SongIndex", true, false) as Label
		if index_label != null:
			index_label.add_theme_color_override("font_color", Color(LIBRARY_ACCENT, 0.92) if is_selected else Color(MinimalThemeScript.TEXT, 0.46))
		var jacket := button.find_child("SongJacket", true, false) as TextureRect
		if jacket != null:
			jacket.custom_minimum_size = Vector2(52, 52) if is_selected else Vector2(44, 44)
		var row_title := button.find_child("SongTitle", true, false) as Label
		if row_title != null:
			row_title.add_theme_font_size_override("font_size", 15 if is_selected else 13)
			row_title.custom_minimum_size.y = 22 if is_selected else 18
			row_title.max_lines_visible = 1
			row_title.autowrap_mode = TextServer.AUTOWRAP_OFF
		var row_artist := button.find_child("SongArtist", true, false) as Label
		if row_artist != null:
			row_artist.add_theme_font_size_override("font_size", 11 if is_selected else 10)
			row_artist.custom_minimum_size.y = 18 if is_selected else 14
		for indicator_node in button.find_children("*Indicator", "Label", true, false):
			var indicator := indicator_node as Label
			var diff_id := str(indicator.get_meta("difficulty_id", ""))
			var indicator_available := bool(indicator.get_meta("available", false))
			var indicator_selected := is_selected and indicator_available and diff_id == selected_difficulty
			var indicator_alpha := 1.0 if indicator_selected else (0.68 if indicator_available else 0.10)
			indicator.add_theme_color_override("font_color", Color(LIBRARY_ACCENT, indicator_alpha))
			indicator.add_theme_font_size_override("font_size", 10 if indicator_selected else 8)

		var header_wrapper := song_header_wrappers[i] as MarginContainer
		var header_margin := _song_row_base_margin(i)
		header_wrapper.add_theme_constant_override("margin_right", 0)
		var difficulty_clip := song_difficulty_clips[i] as Control
		var difficulty_box := song_difficulty_boxes[i] as VBoxContainer
		var difficulty_rows: Array = song_difficulty_rows[i]
		var stack_height := _difficulty_stack_height(difficulty_rows)
		difficulty_clip.visible = false

		for difficulty_index in range(difficulty_rows.size()):
			var row: Dictionary = difficulty_rows[difficulty_index]
			var diff_button := row["button"] as Button
			var diff_wrapper := row["wrapper"] as MarginContainer
			var diff_id := str(row["difficulty"])
			diff_button.set_pressed_no_signal(is_selected and diff_id == selected_difficulty)
			diff_button.queue_redraw()
			var diff_margin := _difficulty_row_base_margin(difficulty_index)
			if animated and is_selected:
				diff_wrapper.call("set_margin_immediate", diff_margin + 36)
				difficulty_margin_velocity["%d_%d" % [i, difficulty_index]] = 0.0
			if animated:
				var delay := 0.055 + float(difficulty_index) * 0.045 if is_selected else 0.0
				selection_tween.tween_property(diff_button, "modulate:a", 1.0 if is_selected else 0.0, 0.18).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			else:
				diff_wrapper.call("set_margin_immediate", diff_margin)
				diff_button.modulate.a = 1.0 if is_selected else 0.0

		if animated:
			selection_tween.tween_property(button, "custom_minimum_size", Vector2(0.0, target_height), 0.24).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
			selection_tween.tween_property(difficulty_clip, "custom_minimum_size:y", 0.0, 0.18).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
			selection_tween.tween_property(difficulty_box, "modulate:a", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			button.custom_minimum_size = Vector2(0.0, target_height)
			button.modulate.a = 1.0
			button.scale = Vector2.ONE
			header_wrapper.call("set_margin_immediate", header_margin)
			song_margin_velocity[i] = 0.0
			difficulty_clip.custom_minimum_size.y = 0.0
			difficulty_clip.visible = false
			difficulty_box.modulate.a = 0.0

	if animated and selection_tween != null:
		selection_tween.chain().tween_callback(_finish_song_selection_animation.bind(generation))

func _finish_song_selection_animation(generation: int) -> void:
	if generation != selection_animation_generation:
		return
	for index in range(song_difficulty_clips.size()):
		(song_difficulty_clips[index] as Control).visible = false
	selection_tween = null

func _difficulty_stack_height(rows: Array) -> float:
	if rows.is_empty():
		return 0.0
	return float(rows.size()) * 36.0 + float(maxi(0, rows.size() - 1)) * 2.0

func _song_row_base_margin(_index: int) -> int:
	return 0

func _difficulty_row_base_margin(_index: int) -> int:
	return _carousel_width_margin() + 12

func _carousel_width_margin() -> int:
	if wheel_column == null:
		return 0
	return maxi(0, roundi(wheel_column.size.x - 940.0))

func _on_song_scroll_value_changed(_value: float) -> void:
	if not applying_scroll_target:
		scroll_target = -1.0

func _on_song_row_hover(index: int, hovered: bool) -> void:
	if index < 0 or index >= song_header_wrappers.size():
		return
	song_hovered[index] = hovered

func _on_difficulty_row_hover(song_index: int, difficulty_index: int, hovered: bool) -> void:
	if song_index < 0 or song_index >= song_difficulty_rows.size():
		return
	var rows: Array = song_difficulty_rows[song_index]
	if difficulty_index < 0 or difficulty_index >= rows.size():
		return
	difficulty_hovered["%d_%d" % [song_index, difficulty_index]] = hovered

func _kill_row_tweens() -> void:
	song_hovered.clear()
	difficulty_hovered.clear()
	song_margin_velocity.clear()
	difficulty_margin_velocity.clear()
	scroll_target = -1.0

func _center_selected_row(animated: bool = true) -> void:
	await get_tree().process_frame
	var index: int = filtered_song_ids.find(selected_song_id)
	if index < 0 or index >= song_buttons.size():
		return
	var group := song_groups[index] as Control
	var desired := group.position.y + group.size.y * 0.5 - song_scroll.size.y * 0.58
	var bar: VScrollBar = song_scroll.get_v_scroll_bar()
	var max_scroll := maxf(0.0, bar.max_value - bar.page)
	var target := clampf(desired, 0.0, max_scroll)
	if animated:
		if scroll_tween != null and scroll_tween.is_valid():
			scroll_tween.kill()
			scroll_tween = null
		scroll_target = target
	else:
		scroll_target = -1.0
		applying_scroll_target = true
		song_scroll.scroll_vertical = int(round(target))
		applying_scroll_target = false

func _ensure_difficulty_valid() -> void:
	if selected_song_id.is_empty():
		return
	var available: Array[String] = _available_difficulties(selected_song_id)
	if available.is_empty():
		selected_difficulty = "normal"
		return
	if selected_difficulty_filter != "All Difficulties":
		var filtered_diff: String = selected_difficulty_filter.to_lower()
		if available.has(filtered_diff):
			selected_difficulty = filtered_diff
			return
	if not available.has(selected_difficulty):
		selected_difficulty = available[0]

func _preferred_initial_song() -> String:
	for song_id in filtered_song_ids:
		for difficulty_id in _available_difficulties(song_id):
			if _chart_is_playable(_find_level(song_id, difficulty_id)):
				return song_id
	return filtered_song_ids[0] if not filtered_song_ids.is_empty() else ""

func _update_detail(animated: bool = true) -> void:
	if animated:
		_pulse_info()
	if selected_song_id.is_empty():
		if album_flow_artwork != null:
			album_flow_artwork.texture = null
			album_flow_artwork.visible = false
		if album_flow_detail_backdrop != null:
			album_flow_detail_backdrop.texture = null
			album_flow_detail_backdrop.visible = false
		song_visual.visible = false
		run_picker.clear()
		run_picker.disabled = true
		detail_title.text = "NO SONGS FOUND"
		detail_meta.visible = false
		detail_meta.text = ""
		detail_description.text = "SELECT ANOTHER FILTER OR IMPORT CHART JSON FILES"
		detail_flavor.text = ""
		if album_flow_meta_line != null:
			album_flow_meta_line.text = ""
		selection_index.text = "TRACK 00 / 00"
		mode_status.visible = false
		mode_status.text = ""
		mode_status.add_theme_color_override("font_color", MinimalThemeScript.MUTED)
		bpm_value.text = "—"
		duration_value.text = "—"
		notes_value.text = "—"
		normal_notes_value.text = "—"
		reverse_notes_value.text = "—"
		space_notes_value.text = "—"
		details_status.text = "WAITING"
		details_status.add_theme_color_override("font_color", MinimalThemeScript.MUTED)
		details_footer.text = ""
		for field_key: Variant in details_field_labels.keys():
			(details_field_labels[field_key] as Label).text = "—"
		if details_notes_label != null:
			details_notes_label.text = "Select another filter or import chart JSON files."
		ranking_context.text = ""
		rank_label.text = "—"
		best_score_value.text = "—"
		best_accuracy_value.text = "—"
		best_combo_value.text = "—"
		best_plays_value.text = "—"
		best_stats_label.text = "NO PERSONAL BEST"
		progress_status.text = "NO PROGRESSION DATA"
		best_grid.visible = false
		rank_label.visible = false
		play_button.disabled = true
		_set_album_flow_play_text("NO PLAYABLE CHART")
		footer_status.text = ""
		footer_status.add_theme_color_override("font_color", MinimalThemeScript.MUTED)
		preview_player.stop_immediately()
		composition.refresh(self)
		return
	var rep: Dictionary = _representative(selected_song_id)
	var chart: Dictionary = _find_level(selected_song_id, selected_difficulty)
	var selected_index := filtered_song_ids.find(selected_song_id)
	var bpm := int(round(float(rep.get("bpm", 120.0))))
	var stars := int(chart.get("star_rating", 1))
	detail_title.text = str(rep.get("title", "SONG"))
	var artist_text := _display_artist(rep)
	var events_value: Variant = chart.get("events", [])
	var note_count: int = 0
	if events_value is Array:
		note_count = (events_value as Array).size()
	var duration: float = float(chart.get("duration", rep.get("duration", 0.0)))
	var mode_label: String = "RANDOM" if random_mode_enabled else ""
	var difficulty_label := str(chart.get("difficulty", selected_difficulty.to_upper())).to_upper()
	var chart_playable := _chart_is_playable(chart) and RuntimeResourceAccessScript.audio_exists(str(chart.get("audio", "")))
	selection_index.text = "TRACK %02d / %02d" % [selected_index + 1, filtered_song_ids.size()]
	mode_status.visible = not chart_playable
	mode_status.text = "" if chart_playable else "CHART OR AUDIO MISSING"
	mode_status.add_theme_color_override("font_color", MinimalThemeScript.GOLD)
	var artist_known := not artist_text.is_empty() and artist_text.to_lower() != "unknown artist"
	detail_meta.text = artist_text if artist_known else ""
	detail_meta.visible = artist_known
	var input_mode_label := "4-ARROW" if UserSettingsScript.get_input_style() == "4_arrow" else "8-DIR"
	detail_description.text = "%s  ·  %d★%s" % [difficulty_label, stars, "  ·  RANDOM" if not mode_label.is_empty() else ""]
	detail_description.add_theme_color_override("font_color", _difficulty_color(selected_difficulty))
	best_card.add_theme_stylebox_override("panel", _personal_best_card_style(_difficulty_color(selected_difficulty)))
	details_panel.add_theme_stylebox_override("panel", _details_card_style(_difficulty_color(selected_difficulty)))
	if details_modern_root != null:
		var detail_card_accents: Array[Color] = [MinimalThemeScript.CYAN, MinimalThemeScript.GOLD, MinimalThemeScript.PINK]
		var modern_grid := details_modern_root.get_node_or_null("ModernDetailsGrid") as GridContainer
		if modern_grid != null:
			for idx in range(modern_grid.get_child_count()):
				var detail_card := modern_grid.get_child(idx)
				if detail_card is PanelContainer:
					(detail_card as PanelContainer).add_theme_stylebox_override("panel", _record_metric_style(detail_card_accents[idx % detail_card_accents.size()]))
		if details_modern_root.get_child_count() > 1 and details_modern_root.get_child(1) is PanelContainer:
			(details_modern_root.get_child(1) as PanelContainer).add_theme_stylebox_override("panel", _record_metric_style(MinimalThemeScript.CYAN))
	_refresh_info_tab_style()
	var standard_progress := _progress_entry(selected_song_id, selected_difficulty)
	var recommendation := _recommended_difficulty(selected_song_id)
	var flavor_source: String = str(rep.get("summary", rep.get("flavor", rep.get("description", "")))).strip_edges()
	detail_flavor.text = flavor_source
	detail_flavor.visible = not flavor_source.is_empty()
	progress_status.text = ""
	progress_status.visible = false
	bpm_value.text = str(bpm)
	duration_value.text = _format_duration(duration)
	notes_value.text = "4 KEY" if UserSettingsScript.get_input_style() == "4_arrow" else "8 KEY"
	if album_flow_meta_line != null:
		album_flow_meta_line.text = "%d BPM   ·   %s   ·   %s" % [bpm, _format_duration(duration), "4K" if UserSettingsScript.get_input_style() == "4_arrow" else "8K"]
	_update_chart_breakdown(chart, events_value, input_mode_label, stars, recommendation, standard_progress, chart_playable)
	ranking_context.text = ""
	ranking_context.visible = false
	var background_path: String = str(rep.get("background", chart.get("background", "")))
	_publish_selection_state(rep, chart, artist_text, background_path)
	background_path = _get_global_background_path(background_path)
	if album_flow_artwork != null:
		var selected_texture := _song_banner_texture(selected_song_id, background_path)
		album_flow_artwork.texture = selected_texture
		album_flow_artwork.visible = album_flow_artwork.texture != null
		song_visual.visible = album_flow_artwork.texture == null
		if album_flow_detail_backdrop != null:
			album_flow_detail_backdrop.texture = selected_texture
			album_flow_detail_backdrop.visible = selected_texture != null
	song_visual.call("set_song", selected_song_id, selected_difficulty, background_path)
	backdrop_visual.call("set_song", selected_song_id, selected_difficulty, background_path)
	if is_visible_in_tree():
		if preview_player.has_method("queue_chart_preview"):
			preview_player.call("queue_chart_preview", chart, 0.14)
		else:
			preview_player.play_chart_preview(chart)
	_update_best_stats()
	_refresh_album_flow_difficulty_row()
	_refresh_album_flow_best_card(chart)
	_update_album_flow_modifier_state()
	play_button.disabled = not chart_playable
	_set_album_flow_play_text("PLAY" if chart_playable else ("AUDIO MISSING" if not RuntimeResourceAccessScript.audio_exists(str(chart.get("audio", ""))) else "INVALID CHART"))
	if practice_button != null:
		var sections_value_v18: Variant = chart.get("sections", [])
		practice_button.disabled = (not chart_playable) or not (sections_value_v18 is Array) or (sections_value_v18 as Array).is_empty()
	if replay_button != null:
		var replay_manager_v18: Node = get_node_or_null("/root/ReplayManager")
		replay_button.disabled = not chart_playable or replay_manager_v18 == null or not bool(replay_manager_v18.call("has_latest", chart, UserSettingsScript.get_input_style(), random_mode_enabled))
	composition.refresh(self)
	footer_status.text = ""
	footer_status.add_theme_color_override("font_color", MinimalThemeScript.MUTED)

func _start_selected_preview() -> void:
	if not is_visible_in_tree() or selected_song_id.is_empty():
		return
	var chart := _find_level(selected_song_id, selected_difficulty)
	if chart.is_empty():
		preview_player.stop_immediately()
		composition.refresh(self)
		return
	if preview_player.has_method("queue_chart_preview"):
		preview_player.call("queue_chart_preview", chart, 0.06)
	else:
		preview_player.play_chart_preview(chart)

# AppShell calls this only after the slide/fade route animation is complete.
# Starting the preview here keeps synchronous audio/resource work out of the
# transition frame, which prevents the ~1s hitch seen when entering Library.
func shell_did_resume(_context: Dictionary) -> void:
	call_deferred("_start_selected_preview")

func shell_will_suspend(_context: Dictionary) -> void:
	if preview_player != null and preview_player.has_method("cancel_pending_preview"):
		preview_player.call("cancel_pending_preview")

func _queue_detail_transition() -> void:
	detail_transition_generation += 1
	var generation := detail_transition_generation
	if info_tween != null and info_tween.is_valid():
		info_tween.kill()
	info_tween = create_tween()
	info_tween.tween_property(info_panel, "modulate:a", 0.42, 0.075).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	info_tween.tween_callback(_apply_detail_transition.bind(generation))
	info_tween.tween_interval(0.025)
	info_tween.tween_property(info_panel, "modulate:a", 1.0, 0.19).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

func _apply_detail_transition(generation: int) -> void:
	if generation != detail_transition_generation:
		return
	_update_detail(false)

func _pulse_info() -> void:
	var tween := create_tween()
	info_panel.modulate.a = 0.78
	tween.tween_property(info_panel, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

func _select_difficulty(difficulty_id: String) -> void:
	selected_difficulty = difficulty_id
	_refresh_song_rows(true)
	_queue_detail_transition()

func _difficulty_color(difficulty_id: String) -> Color:
	match difficulty_id.to_lower():
		"master": return MinimalThemeScript.PINK
		"hard": return MinimalThemeScript.GOLD
		_: return MinimalThemeScript.CYAN

func _update_chart_breakdown(
	chart: Dictionary,
	events_value: Variant,
	input_mode_label: String,
	stars: int,
	_recommendation: String,
	_progress: Dictionary,
	_chart_playable: bool
) -> void:
	var reverse_count: int = 0
	if events_value is Array:
		for raw_event: Variant in (events_value as Array):
			if raw_event is Dictionary and str((raw_event as Dictionary).get("type", "normal")).to_lower() == "reverse":
				reverse_count += 1
	if reverse_count <= 0:
		var raw_special_counts: Variant = chart.get("special_note_counts", {})
		if raw_special_counts is Dictionary:
			reverse_count = maxi(0, int((raw_special_counts as Dictionary).get("reverse", 0)))
	var space_count: int = 0
	var raw_space_events: Variant = chart.get("space_events", [])
	if raw_space_events is Array:
		space_count = (raw_space_events as Array).size()
	var sections_count: int = 0
	var sections_value: Variant = chart.get("sections", [])
	if sections_value is Array:
		sections_count = (sections_value as Array).size()
	var import_meta: Dictionary = chart.get("import_meta", {}) as Dictionary
	var generator_meta: Dictionary = chart.get("generator_meta", {}) as Dictionary
	var source_provenance: Dictionary = chart.get("source_provenance", {}) as Dictionary
	var creator_text := _short_generator_name(str(generator_meta.get("generated_by", "Beat UP!")))
	var source_text := _short_source_name(str(import_meta.get("analysis_master_name", import_meta.get("source_name", "Local audio"))))
	if source_text.is_empty() and source_provenance.has("youtube_id"):
		source_text = "YT · %s" % str(source_provenance.get("youtube_id", ""))
	var submitted_text := _format_iso_date_short(str(import_meta.get("generated_at", "")))
	var input_short := input_mode_label.replace("-ARROW", "K").replace("-DIR", "K")
	var specials_text := "REV %d · SPACE %d" % [reverse_count, space_count]
	var sections_text := "%d section%s" % [sections_count, "" if sections_count == 1 else "s"]
	var format_text := str(import_meta.get("analysis_master_format", "")).to_upper()
	if format_text.is_empty():
		format_text = "LOCAL"
	var notes_text := "%s · %d★ · %s · %s" % [str(chart.get("difficulty", selected_difficulty.to_upper())).to_upper(), stars, ("READY" if _chart_playable else "CHECK CHART / AUDIO"), format_text]
	if details_field_labels.has("creator"):
		(details_field_labels["creator"] as Label).text = creator_text
	if details_field_labels.has("source"):
		(details_field_labels["source"] as Label).text = source_text
	if details_field_labels.has("submitted"):
		(details_field_labels["submitted"] as Label).text = submitted_text
	if details_field_labels.has("input"):
		(details_field_labels["input"] as Label).text = "%s%s" % [input_short, " · RANDOM" if random_mode_enabled else ""]
	if details_field_labels.has("specials"):
		(details_field_labels["specials"] as Label).text = specials_text
	if details_field_labels.has("sections"):
		(details_field_labels["sections"] as Label).text = sections_text
	if details_notes_label != null:
		details_notes_label.text = notes_text

	# Maintain compatibility with legacy references, but keep them hidden from the UI.
	normal_notes_value.text = ""
	reverse_notes_value.text = str(reverse_count)
	space_notes_value.text = str(space_count)
	details_title.text = "DETAILS"
	details_status.text = input_short
	details_status.add_theme_color_override("font_color", _difficulty_color(selected_difficulty))
	details_footer.text = notes_text
	breakdown_grid.visible = false

func _short_generator_name(source_name: String) -> String:
	if source_name.is_empty():
		return "Beat UP!"
	return source_name.replace("Beat UP! ", "").replace(" generator", "")

func _short_source_name(source_name: String) -> String:
	var result := source_name.get_file()
	result = result.trim_suffix(".ogg").trim_suffix(".flac").trim_suffix(".mp3")
	result = result.replace("_", " ")
	if result.length() > 34:
		result = result.substr(0, 31) + "..."
	return result if not result.is_empty() else "Local audio"

func _format_iso_date_short(value: String) -> String:
	if value.is_empty():
		return "Unknown"
	var date_text := value
	if "T" in date_text:
		date_text = date_text.split("T")[0]
	return date_text

func _build_v18_details_controls() -> void:
	var details_margin: MarginContainer = details_panel.get_node("DetailsMargin") as MarginContainer
	var legacy: Control = details_margin.get_node("DetailsVBox") as Control
	if legacy != null:
		legacy.visible = false
	details_panel.custom_minimum_size = Vector2(520, 236)
	details_modern_root = VBoxContainer.new()
	details_modern_root.name = "ModernDetailsVBox"
	details_modern_root.add_theme_constant_override("separation", 12)
	details_margin.add_child(details_modern_root)

	var grid := GridContainer.new()
	grid.name = "ModernDetailsGrid"
	grid.columns = 3
	grid.custom_minimum_size = Vector2(488, 150)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	details_modern_root.add_child(grid)

	for pair in [
		["creator", "CREATOR"],
		["source", "SOURCE"],
		["submitted", "SUBMITTED"],
		["input", "INPUT"],
		["specials", "SPECIALS"],
		["sections", "SECTIONS"]
	]:
		var key: String = str(pair[0])
		var caption: String = str(pair[1])
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(156, 68)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(card)
		var inner := MarginContainer.new()
		inner.add_theme_constant_override("margin_left", 12)
		inner.add_theme_constant_override("margin_top", 10)
		inner.add_theme_constant_override("margin_right", 12)
		inner.add_theme_constant_override("margin_bottom", 9)
		card.add_child(inner)
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)
		inner.add_child(vbox)
		var cap := Label.new()
		cap.text = caption
		MinimalThemeScript.apply_mono(cap, 10, Color(MinimalThemeScript.MUTED, 0.92))
		vbox.add_child(cap)
		var value := Label.new()
		value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		value.custom_minimum_size = Vector2(0, 28)
		MinimalThemeScript.apply_body(value, 13, MinimalThemeScript.TEXT)
		vbox.add_child(value)
		details_field_labels[key] = value

	var notes_card := PanelContainer.new()
	notes_card.custom_minimum_size = Vector2(488, 56)
	details_modern_root.add_child(notes_card)
	var notes_margin := MarginContainer.new()
	notes_margin.add_theme_constant_override("margin_left", 12)
	notes_margin.add_theme_constant_override("margin_top", 10)
	notes_margin.add_theme_constant_override("margin_right", 12)
	notes_margin.add_theme_constant_override("margin_bottom", 10)
	notes_card.add_child(notes_margin)
	var notes_vbox := VBoxContainer.new()
	notes_vbox.add_theme_constant_override("separation", 2)
	notes_margin.add_child(notes_vbox)
	var notes_caption := Label.new()
	notes_caption.text = "CHART NOTES"
	MinimalThemeScript.apply_mono(notes_caption, 10, Color(MinimalThemeScript.CYAN, 0.92))
	notes_vbox.add_child(notes_caption)
	details_notes_label = Label.new()
	details_notes_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	MinimalThemeScript.apply_body(details_notes_label, 12, Color(MinimalThemeScript.TEXT, 0.88))
	notes_vbox.add_child(details_notes_label)


func _build_record_controls() -> void:
	# Keep the legacy picker object alive for compatibility with older helper paths,
	# but rebuild the visible ranking UI to be cleaner and local-only.
	run_picker = preload("res://scripts/ui/beat_dropdown.gd").new()
	run_picker.name = "RunPicker"
	run_picker.visible = false
	best_card.add_child(run_picker)

	best_header.visible = false
	best_grid.visible = false
	best_stats_label.visible = false
	rank_label.visible = false
	best_card.custom_minimum_size = Vector2(520, 236)
	var box: VBoxContainer = best_card.get_node("BestCardMargin/BestCardVBox") as VBoxContainer

	ranking_tab_tools = HBoxContainer.new()
	ranking_tab_tools.name = "RankingTabTools"
	ranking_tab_tools.visible = false
	ranking_tab_tools.add_theme_constant_override("separation", 6)
	info_tabs.add_child(ranking_tab_tools)
	info_tabs.move_child(ranking_tab_tools, info_tabs.get_node("InfoTabsSpacer").get_index())

	rank_sort_button = Button.new()
	rank_sort_button.name = "RankingSortButton"
	rank_sort_button.text = "SORT: SCORE" if rank_sort_mode == "score" else "SORT: NEWEST"
	rank_sort_button.tooltip_text = "Sort local runs by top score or latest date. Current: score"
	rank_sort_button.custom_minimum_size = Vector2(84, 28)
	MinimalThemeScript.style_secondary(rank_sort_button)
	rank_sort_button.pressed.connect(_toggle_v18_rank_sort)
	ranking_tab_tools.add_child(rank_sort_button)

	ranking_mods_label = Label.new()
	ranking_mods_label.text = "SELECTED MODS"
	ranking_mods_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	MinimalThemeScript.apply_mono(ranking_mods_label, 10, Color(MinimalThemeScript.MUTED, 0.88))
	ranking_tab_tools.add_child(ranking_mods_label)

	ranking_mods_filter = preload("res://scripts/ui/beat_dropdown.gd").new()
	ranking_mods_filter.name = "RankingModsFilter"
	ranking_mods_filter.custom_minimum_size = Vector2(150, 28)
	ranking_mods_filter.add_item("8K")
	ranking_mods_filter.add_item("8K + RANDOM")
	ranking_mods_filter.add_item("4K")
	ranking_mods_filter.add_item("4K + RANDOM")
	ranking_mods_filter.item_selected.connect(_on_ranking_mod_filter_selected)
	ranking_tab_tools.add_child(ranking_mods_filter)
	ranking_tab_tools.move_child(rank_sort_button, ranking_tab_tools.get_child_count() - 1)

	ranking_scroll = ScrollContainer.new()
	ranking_scroll.name = "LocalRankingScroll"
	ranking_scroll.custom_minimum_size = Vector2(0, 192)
	ranking_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ranking_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ranking_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	box.add_child(ranking_scroll)

	ranking_list = VBoxContainer.new()
	ranking_list.name = "LocalRankingList"
	ranking_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ranking_list.add_theme_constant_override("separation", 6)
	ranking_scroll.add_child(ranking_list)

	ranking_input_style = UserSettingsScript.get_input_style()
	ranking_random_mode = random_mode_enabled
	_sync_ranking_mod_filter_selection()

	# Export stays available through diagnostics/beta tooling; it no longer occupies
	# Song Library hierarchy.
	export_button = Button.new()
	export_button.name = "ExportPlaytest"
	export_button.visible = false
	add_child(export_button)

func _build_v18_action_controls() -> void:
	# Integrate Practice / Replay into the bottom action row so the library keeps one clean control band.
	v18_mode_row = null
	action_row.add_theme_constant_override("separation", 8)
	play_button.custom_minimum_size = Vector2(220, 44)
	play_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	practice_button = Button.new()
	practice_button.name = "PracticeButton"
	practice_button.text = "PRACTICE"
	practice_button.tooltip_text = "Loop one authored musical section. Practice results never change normal records."
	practice_button.custom_minimum_size = Vector2(118, 34)
	MinimalThemeScript.style_secondary(practice_button)
	practice_button.pressed.connect(_open_v18_practice_menu)
	action_row.add_child(practice_button)
	action_row.move_child(practice_button, play_button.get_index())

	replay_button = Button.new()
	replay_button.name = "ReplayButton"
	replay_button.text = "REPLAY"
	replay_button.tooltip_text = "Play the latest deterministic local replay for this chart and ruleset."
	replay_button.custom_minimum_size = Vector2(106, 34)
	MinimalThemeScript.style_secondary(replay_button)
	replay_button.pressed.connect(_play_v18_latest_replay)
	action_row.add_child(replay_button)
	action_row.move_child(replay_button, play_button.get_index())

	practice_popup = preload("res://scripts/ui/beat_context_menu.gd").new()
	practice_popup.name = "PracticeSectionMenu"
	practice_popup.id_pressed.connect(_launch_v18_practice_section)
	add_child(practice_popup)


func _build_v18_progress_controls() -> void:
	# Progress history and weak-section analytics remain available in the data layer,
	# but were removed from Song Details to avoid competing with core chart information.
	progress_graph = null
	progress_insight_label = null

func _selected_v18_chart() -> Dictionary:
	return _find_level(selected_song_id, selected_difficulty)

func _open_v18_practice_menu() -> void:
	var chart: Dictionary = _selected_v18_chart()
	if chart.is_empty():
		return
	practice_popup.clear()
	var sections_value: Variant = chart.get("sections", [])
	if not (sections_value is Array) or (sections_value as Array).is_empty():
		practice_popup.add_item("NO AUTHORED SECTIONS", -1)
		practice_popup.set_item_disabled(0, true)
	else:
		var sections: Array = sections_value as Array
		for i: int in range(sections.size()):
			if not (sections[i] is Dictionary):
				continue
			var section: Dictionary = sections[i] as Dictionary
			var role: String = str(section.get("role", section.get("name", "section"))).replace("_", " ").to_upper()
			var start_s: float = float(section.get("start", 0.0))
			var end_s: float = float(section.get("end", start_s))
			practice_popup.add_item("%s  ·  %s–%s" % [role, _format_duration(start_s), _format_duration(end_s)], i)
	practice_popup.popup_near(practice_button, true)

func _launch_v18_practice_section(section_index: int) -> void:
	if section_index < 0 or selected_song_id.is_empty():
		return
	_transition_out(func(): practice_requested.emit(selected_song_id, selected_difficulty, random_mode_enabled, section_index), false)

func _play_v18_latest_replay() -> void:
	var chart: Dictionary = _selected_v18_chart()
	if chart.is_empty():
		return
	var replay_manager: Node = get_node_or_null("/root/ReplayManager")
	if replay_manager == null:
		return
	var replay_value: Variant = replay_manager.call("load_latest", chart, UserSettingsScript.get_input_style(), random_mode_enabled)
	if not (replay_value is Dictionary) or (replay_value as Dictionary).is_empty():
		return
	var replay_data: Dictionary = (replay_value as Dictionary).duplicate(true)
	_transition_out(func(): replay_requested.emit(selected_song_id, selected_difficulty, random_mode_enabled, replay_data), false)

func _toggle_v18_rank_sort() -> void:
	rank_sort_mode = "date" if rank_sort_mode == "score" else "score"
	if rank_sort_button != null:
		rank_sort_button.text = "SORT: SCORE" if rank_sort_mode == "score" else "SORT: NEWEST"
		rank_sort_button.tooltip_text = "Sort local runs by top score or latest date. Current: %s" % rank_sort_mode
	selected_record = 0
	_update_best_stats()

func _sort_v18_records_by_date(rows: Array) -> Array:
	var sorted_rows: Array = rows.duplicate(true)
	sorted_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("completed_at", 0)) > float(b.get("completed_at", 0))
	)
	return sorted_rows

func _update_v18_progress(_chart: Dictionary, _entry: Dictionary) -> void:
	# Intentionally not rendered in Song Library after the v18.0.0.1 simplification pass.
	pass

func _update_best_stats() -> void:
	_sync_ranking_filter_to_active_mods()
	if selected_song_id.is_empty():
		record_rows = []
		_render_local_ranking()
		return
	var chart: Dictionary = _find_level(selected_song_id, selected_difficulty)
	if chart.is_empty():
		record_rows = []
		_render_local_ranking()
		return
	var key: String = ScoreIdentity.key(chart, ranking_input_style, ranking_random_mode)
	record_context = key
	var entry_value: Variant = best_stats.get(key, {})
	var entry: Dictionary = entry_value as Dictionary if entry_value is Dictionary else {}
	record_rows = preload("res://scripts/run_records.gd").ranked(entry)
	if rank_sort_mode == "date":
		record_rows = _sort_v18_records_by_date(record_rows)
	_render_local_ranking()

func _ranking_mod_index(input_style: String, random_enabled: bool) -> int:
	if input_style == "4_arrow":
		return 3 if random_enabled else 2
	return 1 if random_enabled else 0

func _sync_ranking_mod_filter_selection() -> void:
	if ranking_mods_filter == null:
		return
	ranking_mods_filter.select(_ranking_mod_index(ranking_input_style, ranking_random_mode))

func _on_ranking_mod_filter_selected(index: int) -> void:
	match index:
		1:
			ranking_input_style = "8_direction"
			ranking_random_mode = true
		2:
			ranking_input_style = "4_arrow"
			ranking_random_mode = false
		3:
			ranking_input_style = "4_arrow"
			ranking_random_mode = true
		_:
			ranking_input_style = "8_direction"
			ranking_random_mode = false
	_update_best_stats()

func _sync_ranking_filter_to_active_mods() -> void:
	ranking_input_style = UserSettingsScript.get_input_style()
	ranking_random_mode = random_mode_enabled
	_sync_ranking_mod_filter_selection()

func _ranking_row_style(index: int) -> StyleBoxFlat:
	var accent: Color = _difficulty_color(selected_difficulty)
	var fill: Color = Color(MinimalThemeScript.SURFACE, 0.58 if index == 0 else 0.34)
	var border: Color = Color(accent, 0.62 if index == 0 else 0.14)
	var style := MinimalThemeScript.panel_style(fill, 6, border, 1 if index == 0 else 0, 7.0)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style

func _render_local_ranking() -> void:
	composition.render_ranking(self)

func _display_record() -> void:

	# Compatibility entry point used by older callbacks.
	_render_local_ranking()

func _rank_display_color(rank: String) -> Color:
	match rank.to_upper():
		"SS", "S": return MinimalThemeScript.PINK
		"A": return MinimalThemeScript.GOLD
		"B": return MinimalThemeScript.CYAN
		"C": return MinimalThemeScript.SUCCESS
		_: return MinimalThemeScript.MUTED

func _progress_entry(song_id: String, difficulty_id: String) -> Dictionary:
	if song_id.is_empty() or difficulty_id.is_empty():
		return {}
	var chart: Dictionary = _find_level(song_id, difficulty_id)
	if chart.is_empty():
		return {}
	var key := ScoreIdentity.key(chart, UserSettingsScript.get_input_style(), random_mode_enabled)
	var raw: Variant = best_stats.get(key, {})
	return raw as Dictionary if raw is Dictionary else {}

func _progress_short_label(entry: Dictionary) -> String:
	if entry.is_empty() or not bool(entry.get("cleared", false)):
		return "UNPLAYED"
	var accuracy := float(entry.get("best_accuracy", entry.get("accuracy", 0.0)))
	var rank := str(entry.get("best_rank", entry.get("rank", "D")))
	if bool(entry.get("full_combo", false)):
		return "FC · %s · %.2f%%" % [rank, accuracy]
	return "CLEAR · %s · %.2f%%" % [rank, accuracy]

func _progress_long_label(entry: Dictionary) -> String:
	if entry.is_empty() or not bool(entry.get("cleared", false)):
		return "UNPLAYED"
	var accuracy := float(entry.get("best_accuracy", entry.get("accuracy", 0.0)))
	var rank := str(entry.get("best_rank", entry.get("rank", "D")))
	return "%s · BEST %s %.2f%%" % ["FULL COMBO" if bool(entry.get("full_combo", false)) else "CLEARED", rank, accuracy]

func _song_matches_progress_filter(song_id: String) -> bool:
	if selected_progress_filter == "All Progress":
		return true
	var difficulties: Array[String] = []
	if selected_difficulty_filter != "All Difficulties":
		var requested := selected_difficulty_filter.to_lower()
		if _available_difficulties(song_id).has(requested):
			difficulties.append(requested)
	else:
		difficulties = _available_difficulties(song_id)
	for diff in difficulties:
		var entry := _progress_entry(song_id, diff)
		var cleared := bool(entry.get("cleared", false))
		var full_combo := bool(entry.get("full_combo", false))
		match selected_progress_filter:
			"Unplayed":
				if not cleared:
					return true
			"Cleared":
				if cleared:
					return true
			"Full Combo":
				if full_combo:
					return true
	return false

func _sort_filtered_song_ids() -> void:
	filtered_song_ids.sort_custom(func(a: String, b: String) -> bool:
		match selected_sort_mode:
			"BPM Asc":
				var a_bpm := float(_representative(a).get("bpm", 0.0))
				var b_bpm := float(_representative(b).get("bpm", 0.0))
				if not is_equal_approx(a_bpm, b_bpm):
					return a_bpm < b_bpm
			"BPM Desc":
				var a_bpm := float(_representative(a).get("bpm", 0.0))
				var b_bpm := float(_representative(b).get("bpm", 0.0))
				if not is_equal_approx(a_bpm, b_bpm):
					return a_bpm > b_bpm
			"Star Rating":
				var a_star := _song_sort_star(a)
				var b_star := _song_sort_star(b)
				if a_star != b_star:
					return a_star < b_star
			"Best Rank":
				var a_record := _song_sort_record(a)
				var b_record := _song_sort_record(b)
				if float(a_record[0]) != float(b_record[0]):
					return float(a_record[0]) > float(b_record[0])
				if float(a_record[1]) != float(b_record[1]):
					return float(a_record[1]) > float(b_record[1])
			"Unplayed First":
				var a_played := _song_played_count(a)
				var b_played := _song_played_count(b)
				if a_played != b_played:
					return a_played < b_played
		var a_title := str(_representative(a).get("title", a))
		var b_title := str(_representative(b).get("title", b))
		return a_title.naturalnocasecmp_to(b_title) < 0
	)

func _sort_difficulties_for_song(song_id: String) -> Array[String]:
	if selected_difficulty_filter != "All Difficulties":
		var requested := selected_difficulty_filter.to_lower()
		if _available_difficulties(song_id).has(requested):
			var single: Array[String] = [requested]
			return single
	return _available_difficulties(song_id)

func _song_sort_star(song_id: String) -> int:
	var value := 999
	for diff in _sort_difficulties_for_song(song_id):
		value = mini(value, int(_find_level(song_id, diff).get("star_rating", 999)))
	return value

func _song_sort_record(song_id: String) -> Array:
	var best_rank_value := -1
	var best_accuracy := -1.0
	for diff in _sort_difficulties_for_song(song_id):
		var entry := _progress_entry(song_id, diff)
		if not bool(entry.get("cleared", false)):
			continue
		var rank_value := _rank_sort_value(str(entry.get("best_rank", entry.get("rank", "D"))))
		var accuracy := float(entry.get("best_accuracy", entry.get("accuracy", 0.0)))
		if rank_value > best_rank_value or (rank_value == best_rank_value and accuracy > best_accuracy):
			best_rank_value = rank_value
			best_accuracy = accuracy
	return [best_rank_value, best_accuracy]

func _rank_sort_value(rank: String) -> int:
	match rank.to_upper():
		"SS": return 6
		"S": return 5
		"A": return 4
		"B": return 3
		"C": return 2
		"D": return 1
		_: return 0

func _song_played_count(song_id: String) -> int:
	var count := 0
	for diff in _sort_difficulties_for_song(song_id):
		if bool(_progress_entry(song_id, diff).get("cleared", false)):
			count += 1
	return count

func _completion_totals() -> Array:
	var total := 0
	var cleared := 0
	var full_combo := 0
	for raw_level in levels:
		if not (raw_level is Dictionary):
			continue
		var chart: Dictionary = raw_level
		if not _chart_is_playable(chart):
			continue
		var song_id := str(chart.get("song_id", chart.get("id", "")))
		var diff := str(chart.get("chart_difficulty", chart.get("difficulty", "normal"))).to_lower()
		total += 1
		var entry := _progress_entry(song_id, diff)
		if bool(entry.get("cleared", false)):
			cleared += 1
		if bool(entry.get("full_combo", false)):
			full_combo += 1
	return [cleared, total, full_combo]

func _recommended_difficulty(song_id: String) -> String:
	var available := _available_difficulties(song_id)
	if available.is_empty():
		return "normal"
	var recommendation := available[0]
	for index in range(available.size()):
		var diff := available[index]
		var entry := _progress_entry(song_id, diff)
		if entry.is_empty() or not bool(entry.get("cleared", false)):
			return diff
		recommendation = diff
		var accuracy := float(entry.get("best_accuracy", entry.get("accuracy", 0.0)))
		if accuracy < 90.0:
			return diff
		if index + 1 < available.size():
			recommendation = available[index + 1]
	return recommendation

func _format_number(value: int) -> String:
	var digits := str(maxi(0, value))
	var grouped := ""
	var count := 0
	for index in range(digits.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			grouped = "," + grouped
		grouped = digits.substr(index, 1) + grouped
		count += 1
	return grouped

func _song_banner_texture(song_id: String, explicit_path: String = "") -> Texture2D:
	# Library rows never need a full 1600x900 background. Loading all full-size
	# textures synchronously made route entry and list rebuilds unnecessarily
	# expensive. Prefer a dedicated 384x216 thumbnail and only fall back to the
	# full asset if no thumbnail exists.
	var cache_key := "thumb:" + song_id
	if background_texture_cache.has(cache_key):
		return background_texture_cache[cache_key] as Texture2D
	var candidates: Array[String] = []
	var safe_id := song_id.to_lower().replace(" ", "_")
	for extension in ["png", "webp", "jpg", "jpeg"]:
		candidates.append("%s/%s.%s" % [SONG_THUMBNAIL_ROOT, safe_id, extension])
	if not explicit_path.is_empty():
		candidates.append(explicit_path)
	for extension in ["png", "webp", "jpg", "jpeg"]:
		candidates.append("%s/%s.%s" % [SONG_BACKGROUND_ROOT, safe_id, extension])
	for path in candidates:
		if ResourceLoader.exists(path):
			var texture := load(path)
			if texture is Texture2D:
				background_texture_cache[cache_key] = texture
				return texture
	background_texture_cache[cache_key] = null
	return null

func _play_selected_chart() -> void:
	if selected_song_id.is_empty() or not _chart_is_playable(_find_level(selected_song_id, selected_difficulty)) or not RuntimeResourceAccessScript.audio_exists(str(_find_level(selected_song_id, selected_difficulty).get("audio", ""))):
		return
	_transition_out(func(): play_requested.emit(selected_song_id, selected_difficulty, random_mode_enabled), false)

func _lock_navigation_controls() -> void:
	var navigation_buttons: Array[Button] = [play_button, back_button, mods_button, import_button, refresh_button, editor_button, pack_export_button]
	if practice_button != null: navigation_buttons.append(practice_button)
	if replay_button != null: navigation_buttons.append(replay_button)
	for button in navigation_buttons:
		button.disabled = true
	search_input.editable = false
	artist_filter.disabled = true
	difficulty_filter.disabled = true
	progress_filter.disabled = true
	sort_filter.disabled = true

func _unlock_navigation_controls(refresh_detail: bool = true) -> void:
	back_button.disabled = false
	mods_button.disabled = false
	import_button.disabled = false
	refresh_button.disabled = false
	editor_button.disabled = false
	pack_export_button.disabled = false
	search_input.editable = true
	artist_filter.disabled = false
	difficulty_filter.disabled = false
	progress_filter.disabled = false
	sort_filter.disabled = false
	if refresh_detail:
		_apply_filters()

func show_playback_error(message: String) -> void:
	transitioning_out = false
	transition_overlay.modulate.a = 0.0
	info_panel.scale = Vector2.ONE
	wheel_column.scale = Vector2.ONE
	footer_panel.modulate.a = 1.0
	_unlock_navigation_controls(false)
	play_button.disabled = true
	_set_album_flow_play_text("AUDIO UNAVAILABLE")
	mode_status.visible = true
	mode_status.text = "AUDIO ERROR"
	mode_status.add_theme_color_override("font_color", MinimalThemeScript.DANGER)
	footer_status.text = message
	footer_status.add_theme_color_override("font_color", MinimalThemeScript.DANGER)

func _on_back_pressed() -> void:
	_transition_out(func(): back_requested.emit(), true)

func _on_editor_pressed() -> void:
	_transition_out(func(): chart_editor_requested.emit(), false)

func _transition_out(action: Callable, preserve_music: bool = false) -> void:
	# v17.4.21.5: an inbound seamless handoff still counts as an active
	# scene transition. Ignore navigation requests until it is fully finished;
	# most importantly, never lock this screen before a request that the global
	# transition manager would reject as busy.
	if transitioning_out or SceneTransition.is_transitioning():
		return
	transitioning_out = true
	remember_current_selection()
	mods_overlay.visible = false
	search_input.release_focus()
	_lock_navigation_controls()
	if not preserve_music:
		preview_player.fade_out(0.10, true)
	# Page navigation is now owned by SceneTransition. Do not stack the old
	# 220 ms Song Library fade in front of another scene fade.
	action.call()

func _global_selection_state() -> Dictionary:
	var selection_state: Node = _get_song_selection_state()
	if selection_state != null and selection_state.has_method("get_state"):
		var value: Variant = selection_state.call("get_state")
		if value is Dictionary:
			return (value as Dictionary).duplicate(true)
	return {}

func _restore_selection_from_global_state() -> bool:
	var global_state: Dictionary = _global_selection_state()
	var global_song_id: String = str(global_state.get("song_id", ""))
	if global_song_id.is_empty() or not song_ids.has(global_song_id):
		return false
	selected_song_id = global_song_id
	var global_difficulty: String = str(global_state.get("difficulty_id", "")).to_lower()
	if not global_difficulty.is_empty() and _available_difficulties(global_song_id).has(global_difficulty):
		selected_difficulty = global_difficulty
	else:
		_ensure_difficulty_valid()
	return true

func _get_song_selection_state() -> Node:
	return get_node_or_null("/root/SongSelectionState")

func _get_background_session() -> Node:
	return get_node_or_null("/root/BackgroundSession")

func _get_global_background_path(fallback: String = "") -> String:
	var background_session: Node = _get_background_session()
	if background_session != null and background_session.has_method("get_background_path"):
		var path: String = str(background_session.call("get_background_path"))
		if not path.is_empty():
			return path
	return fallback

func _publish_selection_state(rep: Dictionary, chart: Dictionary, artist_text: String, background_path: String) -> void:
	var selection_state: Node = _get_song_selection_state()
	if selection_state == null or not selection_state.has_method("set_selection"):
		return
	var metadata: Dictionary = {
		"title": str(rep.get("title", chart.get("title", selected_song_id.replace("_", " ")))),
		"artist": artist_text,
		"background": background_path,
		"audio": str(chart.get("audio", rep.get("audio", ""))),
		"duration": float(chart.get("duration", rep.get("duration", 0.0))),
		"bpm": float(chart.get("bpm", rep.get("bpm", 0.0))),
		"difficulty": str(chart.get("difficulty", selected_difficulty.to_upper())).to_upper(),
		"star_rating": int(chart.get("star_rating", 0)),
		"source": "song_library",
	}
	selection_state.call("set_selection", selected_song_id, selected_difficulty, metadata)

func _representative(song_id: String) -> Dictionary:
	var fallback: Dictionary = {}
	for raw_level in levels:
		if raw_level is Dictionary:
			var data: Dictionary = raw_level
			if str(data.get("song_id", data.get("id", ""))) == song_id:
				if fallback.is_empty():
					fallback = data
				if _chart_is_playable(data) and RuntimeResourceAccessScript.audio_exists(str(data.get("audio", ""))):
					return data
	return fallback

func _find_level(song_id: String, difficulty_id: String) -> Dictionary:
	for raw_level in levels:
		if not (raw_level is Dictionary):
			continue
		var data: Dictionary = raw_level
		if str(data.get("song_id", data.get("id", ""))) == song_id and str(data.get("chart_difficulty", data.get("difficulty", ""))).to_lower() == difficulty_id.to_lower():
			return data
	return {}

func _available_difficulties(song_id: String) -> Array[String]:
	var result: Array[String] = []
	for raw_level in levels:
		if not (raw_level is Dictionary):
			continue
		var data: Dictionary = raw_level
		if str(data.get("song_id", data.get("id", ""))) != song_id:
			continue
		if not _chart_is_playable(data) or not RuntimeResourceAccessScript.audio_exists(str(data.get("audio", ""))):
			continue
		var diff: String = str(data.get("chart_difficulty", data.get("difficulty", "normal"))).to_lower()
		if not result.has(diff):
			result.append(diff)
	var difficulty_order: Array[String] = ["normal", "hard", "master"]
	result.sort_custom(func(a: String, b: String):
		var ai: int = difficulty_order.find(a)
		var bi: int = difficulty_order.find(b)
		if ai < 0:
			ai = 999
		if bi < 0:
			bi = 999
		return ai < bi
	)
	return result

func _chart_is_playable(chart: Dictionary) -> bool:
	if chart.is_empty() or str(chart.get("audio", "")).is_empty():
		return false
	var integrity_value: Variant = chart.get("_integrity", {})
	if integrity_value is Dictionary and not bool((integrity_value as Dictionary).get("playable", true)):
		return false
	var events: Variant = chart.get("events", [])
	return events is Array and not (events as Array).is_empty()

func _format_duration(seconds: float) -> String:
	var total: int = maxi(0, int(round(seconds)))
	return "%d:%02d" % [floori(float(total) / 60.0), total % 60]

func _unhandled_key_input(event: InputEvent) -> void:
	if SceneTransition.is_transitioning():
		if event is InputEventKey:
			get_viewport().set_input_as_handled()
		return
	if not is_visible_in_tree() or transitioning_out or not (event is InputEventKey):
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.keycode == KEY_ESCAPE:
		if mods_overlay.visible:
			_close_mods_panel()
			get_viewport().set_input_as_handled()
			return
		if search_input.has_focus():
			if not search_input.text.is_empty():
				search_input.clear()
			search_input.release_focus()
			call_deferred("focus_current_selection")
			get_viewport().set_input_as_handled()
			return
		_on_back_pressed()
		get_viewport().set_input_as_handled()
		return
	if mods_overlay.visible:
		return
	if search_input.has_focus():
		if key.keycode == KEY_ENTER or key.physical_keycode == KEY_ENTER or key.keycode == KEY_DOWN:
			search_input.release_focus()
			call_deferred("focus_current_selection")
			get_viewport().set_input_as_handled()
		return
	if (key.keycode == KEY_F and key.ctrl_pressed) or key.keycode == KEY_SLASH:
		search_input.grab_focus()
		search_input.select_all()
		get_viewport().set_input_as_handled()
		return
	if key.keycode == KEY_ENTER or key.physical_keycode == KEY_ENTER or key.keycode == KEY_KP_5:
		_play_selected_chart()
		get_viewport().set_input_as_handled()
		return
	if key.keycode == KEY_F1:
		_open_mods_panel()
		get_viewport().set_input_as_handled()
		return
	if key.keycode == KEY_LEFT or key.keycode == KEY_RIGHT:
		var available := _available_difficulties(selected_song_id)
		if available.is_empty():
			return
		var difficulty_index := available.find(selected_difficulty)
		if difficulty_index < 0:
			difficulty_index = 0
		difficulty_index = wrapi(difficulty_index + (-1 if key.keycode == KEY_LEFT else 1), 0, available.size())
		_select_difficulty(available[difficulty_index])
		get_viewport().set_input_as_handled()
		return
	var diff := ""
	if key.keycode == KEY_N or key.physical_keycode == KEY_N:
		diff = "normal"
	if key.keycode == KEY_H or key.physical_keycode == KEY_H:
		diff = "hard"
	if key.keycode == KEY_M or key.physical_keycode == KEY_M:
		diff = "master"
	if not diff.is_empty() and _available_difficulties(selected_song_id).has(diff):
		_select_difficulty(diff)
		get_viewport().set_input_as_handled()
		return
	if key.keycode == KEY_UP or key.keycode == KEY_DOWN:
		if filtered_song_ids.is_empty():
			return
		var current_index: int = filtered_song_ids.find(selected_song_id)
		if current_index < 0:
			current_index = 0
		current_index = wrapi(current_index + (-1 if key.keycode == KEY_UP else 1), 0, filtered_song_ids.size())
		_select_song(filtered_song_ids[current_index])
		get_viewport().set_input_as_handled()
