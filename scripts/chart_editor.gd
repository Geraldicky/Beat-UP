extends Control

const MinimalThemeScript = preload("res://scripts/ui/minimal_theme.gd")
const InteractionPolishScript = preload("res://scripts/ui/interaction_polish.gd")
const LevelPackScript = preload("res://scripts/level_pack.gd")

var catalog_loader: LevelCatalog = LevelCatalog.new()

const NORMAL := Color("7db4ce")
const REVERSE := Color("d3a4ff")
const DANGER := Color("b76c75")
const SPACE := Color("f5c96a")
const GREEN := Color("7dce9e")
const MUTED := Color("8b96a8")

@onready var song_select = $TopBar/SongSelect
@onready var difficulty_select = $TopBar/DifficultySelect
@onready var load_button: Button = $TopBar/LoadButton
@onready var save_button: Button = $TopBar/SaveButton
@onready var back_button: Button = $TopBar/BackButton
@onready var undo_button: Button = $TopBar/UndoButton
@onready var redo_button: Button = $TopBar/RedoButton
@onready var song_title: Label = $Info/SongTitle
@onready var chart_info: Label = $Info/ChartInfo
@onready var dirty_label: Label = $Info/DirtyLabel
@onready var time_label: Label = $Transport/TimeLabel
@onready var play_button: Button = $Transport/PlayPause
@onready var snap_toggle: CheckButton = $Transport/SnapToggle
@onready var snap_select = $Transport/SnapSelect
@onready var timeline: ChartTimelineView = $TimelinePanel/Timeline
# Keep this inferred so a freshly patched project does not depend on Godot's
# global script-class cache being rebuilt before Chart Studio can compile.
@onready var waveform = $WaveformPanel/Waveform
@onready var status: Label = $Status
@onready var gameplay_path: LineEdit = $AutoPanel/GameplayPath
@onready var audio_path: LineEdit = $AutoPanel/WavPath
@onready var analysis_source_button: Button = $AutoPanel/AnalysisSource
@onready var import_song_button: Button = $AutoPanel/BrowseWav
@onready var bulk_import_button: Button = $AutoPanel/BrowseFolder
@onready var tempo_mode_select = $AutoPanel/TempoMode
@onready var tempo_bpm_input: LineEdit = $AutoPanel/TempoBpm
@onready var generate_all_button: Button = $AutoPanel/GenerateAll
@onready var generator_progress: ProgressBar = $AutoPanel/GeneratorProgress
@onready var generator_progress_text: Label = $AutoPanel/GeneratorProgressText
# Keep these references inferred.  The picker script is attached by the scene,
# and a global class annotation here can be resolved before Godot has rebuilt
# its script-class cache after a patch is installed.
@onready var song_file_dialog = $WavFileDialog
@onready var bulk_file_dialog = $BulkFolderDialog
@onready var analysis_source_dialog = $AnalysisSourceDialog
@onready var music: AudioStreamPlayer = $Music

var charts: Array[Dictionary] = []
var songs: Array[String] = []
var current_chart: Dictionary = {}
var current_path := ""
var editor_time := 0.0
var events: Array = []
var space_events: Array[float] = []
var dirty := false
var delete_radius := 0.16
var wav_analyzer: WavAutoAnalyzer = WavAutoAnalyzer.new()
var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []
const HISTORY_LIMIT := 80
const AUTOSAVE_ROOT := "user://chart_autosaves"
const AUTOSAVE_INTERVAL_MS := 8000
const ALLIN1_BRIDGE_PATH := "res://tools/allin1_bridge.py"
const CHART_STUDIO_POSTPROCESS_PATH := "res://tools/chart_studio_postprocess_v17421.py"
const ALLIN1_MODEL := "harmonix-all"
const ALLIN1_CPU_TIMEOUT_SECONDS := 15
const ALLIN1_TOTAL_TIMEOUT_SECONDS := 210
const IMPORTED_CHART_ROOT := "user://songs"
var _allin1_runner: Dictionary = {}
var _audio_runner: Dictionary = {}
var _selection_guard := false
var _analysis_source_overrides: Dictionary = {}
var _tempo_mode_overrides: Dictionary = {}
var _tempo_custom_bpm: Dictionary = {}
var _studio_initialized: bool = false
var _studio_initializing: bool = false
var _studio_suspended: bool = false
var _waveform_preview_busy: bool = false
var _last_autosave_ms: int = 0

func _developer_generator_enabled() -> bool:
	# Automatic chart generation is a developer tool. Player exports keep Chart
	# Studio and manual chart creation available, but never expose Generate All.
	return OS.has_feature("editor") or bool(ProjectSettings.get_setting("beat_up/creator_tools_enabled", false))

func _ready() -> void:
	MinimalThemeScript.apply_root(self)
	_apply_minimal_editor_theme()
	InteractionPolishScript.install_buttons([load_button, save_button, back_button, undo_button, redo_button, play_button, analysis_source_button, import_song_button, generate_all_button, $Tools/AddNormal, $Tools/AddReverse, $Tools/AddSpace, $Tools/DeleteNearest, $Tools/Reload])
	_populate_snap_select()
	_populate_tempo_mode_select()
	_connect_ui()
	_apply_focused_creator_ui()
	_apply_responsive_layout()
	_sync_timeline_grid()
	resized.connect(_apply_responsive_layout)
	_set_status("CHART STUDIO READY · choose OGG + FLAC/WAV to create a level", MUTED)
	if not _is_resident_chart_studio():
		call_deferred("_initialize_studio_async")

func _is_resident_chart_studio() -> bool:
	var parent_node: Node = get_parent()
	return parent_node != null and parent_node.name == "ChartStudioScreen"

func shell_prepare_resume(_context: Dictionary) -> void:
	visible = true

func shell_will_resume(_context: Dictionary) -> void:
	_studio_suspended = false

func shell_did_resume(_context: Dictionary) -> void:
	call_deferred("_initialize_studio_async")

func shell_will_suspend(_context: Dictionary) -> void:
	_studio_suspended = true
	_write_autosave()
	if music != null and music.playing:
		music.stream_paused = true

func _initialize_studio_async() -> void:
	if _studio_initialized or _studio_initializing:
		if music != null:
			music.stream_paused = false
		return
	_studio_initializing = true
	_set_status("PREPARING CHART STUDIO…", MUTED)
	await get_tree().process_frame
	_load_catalog()
	await get_tree().process_frame
	_populate_song_select()
	if not songs.is_empty():
		_selection_guard = true
		song_select.select(0)
		_selection_guard = false
		_refresh_difficulties()
		_update_selected_audio_path()
		_refresh_tempo_controls()
		_set_review_visible(false)
	_studio_initialized = true
	_studio_initializing = false
	if _developer_generator_enabled():
		_set_status("READY · OGG for playback · FLAC/WAV for developer generation", GREEN)
	else:
		_set_status("READY · import OGG, choose a difficulty, place notes, then SAVE", GREEN)

func _apply_focused_creator_ui() -> void:
	# Chart Studio remains player-facing for manual chart creation. Automatic
	# generation is exposed only while running in the editor or when the explicit
	# developer project flag is enabled.
	var developer_generator := _developer_generator_enabled()
	$TopAccent.visible = false
	$Header.text = "CHART STUDIO"
	$Hint.text = "SONG  →  GENERATE  →  REVIEW  →  SAVE" if developer_generator else "SONG  →  EDIT  →  REVIEW  →  SAVE"
	$Info.visible = false
	$Legend.visible = false
	$TopBar/LoadButton.visible = false
	$TopBar/UndoButton.visible = true
	$TopBar/RedoButton.visible = true
	$AutoPanel/AutoTitle.text = "CREATE LEVEL" if developer_generator else "CREATE CHART"
	$AutoPanel/GameplayLabel.text = "GAMEPLAY AUDIO  ·  .OGG"
	$AutoPanel/AnalysisLabel.text = "ANALYSIS SOURCE  ·  FLAC / WAV" if developer_generator else "WAVEFORM SOURCE  ·  FLAC / WAV"
	$AutoPanel/GenerateLabel.text = "GENERATOR" if developer_generator else "CHART BPM"
	import_song_button.text = "CHOOSE OGG"
	analysis_source_button.text = "CHOOSE AUDIO" if developer_generator else "CHOOSE WAVEFORM"
	generate_all_button.text = "GENERATE ALL"
	generate_all_button.visible = developer_generator
	tempo_mode_select.visible = developer_generator
	$AutoPanel/GeneratorProgress.visible = developer_generator
	$AutoPanel/GeneratorProgressText.visible = developer_generator
	bulk_import_button.visible = false
	gameplay_path.editable = false
	audio_path.editable = false
	$Tools.visible = false
	$Transport.visible = false
	$WaveformPanel.visible = false
	$TimelinePanel.visible = false
	if developer_generator:
		status.text = "Choose an OGG runtime track and a FLAC or PCM WAV analysis source."
	else:
		status.text = "Choose an OGG runtime track, then edit NORMAL / HARD / MASTER manually."

func _set_review_visible(value: bool) -> void:
	$Transport.visible = value
	$WaveformPanel.visible = value
	$TimelinePanel.visible = value
	$Tools.visible = value
	if value:
		$Hint.text = "REVIEW  ·  preview timing, adjust notes, then SAVE"
	else:
		$Hint.text = "SONG  →  GENERATE  →  REVIEW  →  SAVE" if _developer_generator_enabled() else "SONG  →  EDIT  →  REVIEW  →  SAVE"
	_apply_responsive_layout()


func _apply_minimal_editor_theme() -> void:
	$Background.color = MinimalThemeScript.BG
	$TopAccent.color = MinimalThemeScript.ACCENT
	$Header.add_theme_color_override("font_color", MinimalThemeScript.TEXT)
	$Header.add_theme_font_override("font", MinimalThemeScript.semibold_font())
	song_title.add_theme_font_override("font", MinimalThemeScript.semibold_font())
	$Hint.add_theme_color_override("font_color", MinimalThemeScript.MUTED)
	$TopBar.add_theme_stylebox_override("panel", MinimalThemeScript.surface_s1(0.74))
	$Info.add_theme_stylebox_override("panel", MinimalThemeScript.surface_s0())
	$Transport.add_theme_stylebox_override("panel", MinimalThemeScript.surface_s1(0.58))
	$WaveformPanel.add_theme_stylebox_override("panel", MinimalThemeScript.panel_style(Color(MinimalThemeScript.BG, 0.92), MinimalThemeScript.RADIUS_SM, Color(MinimalThemeScript.ACCENT, 0.14), 1, 0.0))
	$TimelinePanel.add_theme_stylebox_override("panel", MinimalThemeScript.panel_style(Color(MinimalThemeScript.BG, 0.94), MinimalThemeScript.RADIUS_SM, Color(MinimalThemeScript.BORDER, 0.44), 1, 0.0))
	$Tools.add_theme_stylebox_override("panel", MinimalThemeScript.surface_s1(0.56))
	$AutoPanel.add_theme_stylebox_override("panel", MinimalThemeScript.surface_s1(0.52))
	MinimalThemeScript.style_primary(save_button)
	MinimalThemeScript.style_secondary(generate_all_button, SPACE)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		generate_all_button.add_theme_color_override(color_name, SPACE)
	for button in [load_button, back_button, undo_button, redo_button, play_button, $Transport/Back5, $Transport/Back1, $Transport/Forward1, $Transport/Forward5, analysis_source_button, import_song_button, bulk_import_button]:
		MinimalThemeScript.style_secondary(button)
	_apply_compact_generator_control_theme()
	MinimalThemeScript.style_secondary($Tools/AddNormal, NORMAL)
	MinimalThemeScript.style_secondary($Tools/AddReverse, REVERSE)
	MinimalThemeScript.style_secondary($Tools/AddSpace, SPACE)
	MinimalThemeScript.style_secondary($Tools/DeleteNearest, DANGER)
	MinimalThemeScript.style_secondary($Tools/Reload, MUTED)
	_style_compact_primary(save_button)
	for button in [back_button, undo_button, redo_button, play_button, $Transport/Back5, $Transport/Back1, $Transport/Forward1, $Transport/Forward5]:
		_style_compact_button(button, NORMAL, false)
	_style_compact_button($Tools/AddNormal, NORMAL, false)
	_style_compact_button($Tools/AddReverse, REVERSE, false)
	_style_compact_button($Tools/AddSpace, SPACE, false)
	_style_compact_button($Tools/DeleteNearest, DANGER, false)
	_style_compact_button($Tools/Reload, MUTED, false)
	_style_compact_option(song_select, 13)
	_style_compact_option(difficulty_select, 13)
	_style_compact_option(snap_select, 12)
	MinimalThemeScript.apply_body($Hint, 12, MinimalThemeScript.MUTED)
	MinimalThemeScript.apply_mono(chart_info, 11, MinimalThemeScript.MUTED)
	MinimalThemeScript.apply_mono(status, 11, MinimalThemeScript.MUTED)
	MinimalThemeScript.apply_mono($Legend, 10, MinimalThemeScript.MUTED)
	MinimalThemeScript.apply_mono(generator_progress_text, 11, MinimalThemeScript.MUTED)
	MinimalThemeScript.apply_mono(time_label, 15, MinimalThemeScript.TEXT)
	tempo_bpm_input.add_theme_font_override("font", MinimalThemeScript.mono_font())
	tempo_bpm_input.add_theme_color_override("font_color", MinimalThemeScript.TEXT)
	tempo_bpm_input.add_theme_color_override("font_uneditable_color", MinimalThemeScript.MUTED)
	MinimalThemeScript.apply_mono(dirty_label, 12, GREEN)
	generator_progress.add_theme_stylebox_override("background", MinimalThemeScript.panel_style(MinimalThemeScript.BORDER, 2, MinimalThemeScript.BORDER, 0, 0.0))
	generator_progress.add_theme_stylebox_override("fill", MinimalThemeScript.panel_style(MinimalThemeScript.ACCENT, 2, MinimalThemeScript.ACCENT, 0, 0.0))
	_reset_generator_progress()
	generate_all_button.tooltip_text = "Developer-only: generate Normal, Hard and Master from the selected analysis source."
	analysis_source_button.tooltip_text = "Choose FLAC/WAV for generation and waveform analysis." if _developer_generator_enabled() else "Choose FLAC/WAV to build a waveform preview for manual charting."
	import_song_button.tooltip_text = "Choose the compact gameplay OGG."
	save_button.tooltip_text = "Save the active chart."

func _apply_compact_generator_control_theme() -> void:
	for button in [analysis_source_button, import_song_button]:
		_style_compact_button(button, NORMAL, false)
	bulk_import_button.visible = false
	_style_compact_button(generate_all_button, SPACE, true)
	_style_compact_option(tempo_mode_select, 12)
	for edit in [gameplay_path, audio_path, tempo_bpm_input]:
		edit.add_theme_font_size_override("font_size", 12)
		edit.add_theme_stylebox_override("normal", _compact_control_style(Color(MinimalThemeScript.SURFACE, 0.92), MinimalThemeScript.BORDER))
		edit.add_theme_stylebox_override("focus", _compact_control_style(Color(MinimalThemeScript.SURFACE, 0.98), NORMAL))

func _style_compact_button(button: Button, accent: Color, emphasis: bool) -> void:
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_stylebox_override("normal", _compact_control_style(Color(accent, 0.10) if emphasis else Color(MinimalThemeScript.SURFACE, 0.88), Color(accent, 0.70) if emphasis else MinimalThemeScript.BORDER))
	button.add_theme_stylebox_override("hover", _compact_control_style(Color(accent, 0.16), accent))
	button.add_theme_stylebox_override("pressed", _compact_control_style(Color(accent, 0.24), accent))
	button.add_theme_stylebox_override("focus", _compact_control_style(Color(MinimalThemeScript.SURFACE, 0.96), accent))
	button.add_theme_stylebox_override("disabled", _compact_control_style(Color(MinimalThemeScript.SURFACE, 0.48), Color(MinimalThemeScript.BORDER, 0.42)))
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_name, accent if emphasis else MinimalThemeScript.TEXT)

func _style_compact_primary(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_stylebox_override("normal", _compact_control_style(MinimalThemeScript.PINK, MinimalThemeScript.PINK))
	button.add_theme_stylebox_override("hover", _compact_control_style(MinimalThemeScript.PINK.lightened(0.08), MinimalThemeScript.PINK.lightened(0.08)))
	button.add_theme_stylebox_override("pressed", _compact_control_style(MinimalThemeScript.PINK.darkened(0.12), MinimalThemeScript.PINK.darkened(0.12)))
	button.add_theme_stylebox_override("focus", _compact_control_style(MinimalThemeScript.PINK, MinimalThemeScript.TEXT))
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_name, MinimalThemeScript.BG)

func _style_compact_option(option: Button, font_size: int) -> void:
	option.add_theme_font_size_override("font_size", font_size)
	option.add_theme_stylebox_override("normal", _compact_control_style(Color(MinimalThemeScript.SURFACE_RAISED, 0.78), Color(MinimalThemeScript.BORDER, 0.92), true))
	option.add_theme_stylebox_override("hover", _compact_control_style(Color(NORMAL, 0.10), NORMAL, true))
	option.add_theme_stylebox_override("pressed", _compact_control_style(Color(NORMAL, 0.16), NORMAL, true))
	option.add_theme_stylebox_override("focus", _compact_control_style(Color(MinimalThemeScript.SURFACE_RAISED, 0.96), REVERSE, true))
	option.add_theme_stylebox_override("disabled", _compact_control_style(Color(MinimalThemeScript.SURFACE, 0.52), Color(MinimalThemeScript.BORDER, 0.42), true))

func _compact_control_style(fill: Color, border: Color, reserve_arrow: bool = false) -> StyleBoxFlat:
	var style := MinimalThemeScript.panel_style(fill, 8, border, 1, 0.0)
	style.content_margin_left = 10.0
	style.content_margin_right = 34.0 if reserve_arrow else 10.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style

func _apply_responsive_layout() -> void:
	var viewport_size := size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return
	var margin := clampf(viewport_size.x * 0.022, 22.0, 38.0)
	var content_width := viewport_size.x - margin * 2.0
	var compact_height := viewport_size.y < 760.0
	var compact_width := content_width < 1180.0
	var developer_generator := _developer_generator_enabled()
	var reviewing: bool = $TimelinePanel.visible
	var collapse_setup: bool = compact_height and reviewing

	$Header.position = Vector2(margin, 14.0 if compact_height else 18.0)
	$Header.size = Vector2(minf(560.0, content_width * 0.56), 40.0)
	$Hint.visible = not compact_height
	$Hint.position = Vector2(margin + 1.0, 56.0)
	$Hint.size = Vector2(content_width * 0.82, 24.0)

	# Gameplay OGG is always player-facing. FLAC/WAV remains available as an
	# optional waveform source; only developer mode exposes automatic generation.
	var setup_y := 58.0 if compact_height else 88.0
	var setup_height := 142.0 if compact_height else 168.0
	$AutoPanel.visible = not collapse_setup
	$AutoPanel.position = Vector2(margin, setup_y)
	$AutoPanel.size = Vector2(content_width, setup_height)
	$AutoPanel/AutoTitle.position = Vector2(16.0, 10.0)
	$AutoPanel/AutoTitle.size = Vector2(content_width * 0.48, 22.0)
	var progress_text_width := minf(430.0, maxf(260.0, content_width * 0.38))
	$AutoPanel/GeneratorProgressText.visible = developer_generator
	$AutoPanel/GeneratorProgressText.position = Vector2(content_width - progress_text_width - 16.0, 10.0)
	$AutoPanel/GeneratorProgressText.size = Vector2(progress_text_width, 22.0)

	var card_gap := 12.0
	var card_y := 42.0
	var card_height := 74.0 if compact_height else 82.0
	var card_width := (content_width - 32.0 - card_gap * 2.0) / 3.0
	var first_x := 16.0
	var second_x := first_x + card_width + card_gap
	var third_x := second_x + card_width + card_gap
	for card in [$AutoPanel/GameplayCard, $AutoPanel/AnalysisCard, $AutoPanel/GenerateCard]:
		card.position.y = card_y
		card.size = Vector2(card_width, card_height)
	$AutoPanel/GameplayCard.position.x = first_x
	$AutoPanel/AnalysisCard.position.x = second_x
	$AutoPanel/GenerateCard.position.x = third_x

	$AutoPanel/GameplayLabel.position = Vector2(first_x + 12.0, card_y + 8.0)
	$AutoPanel/GameplayLabel.size = Vector2(card_width - 24.0, 20.0)
	$AutoPanel/AnalysisLabel.position = Vector2(second_x + 12.0, card_y + 8.0)
	$AutoPanel/AnalysisLabel.size = Vector2(card_width - 24.0, 20.0)
	$AutoPanel/GenerateLabel.position = Vector2(third_x + 12.0, card_y + 8.0)
	$AutoPanel/GenerateLabel.size = Vector2(card_width - 24.0, 20.0)

	var input_y := card_y + 34.0
	var input_height := 36.0
	var button_width := clampf(card_width * 0.34, 104.0, 132.0)
	gameplay_path.position = Vector2(first_x + 12.0, input_y)
	gameplay_path.size = Vector2(maxf(110.0, card_width - button_width - 32.0), input_height)
	import_song_button.position = Vector2(first_x + card_width - button_width - 12.0, input_y)
	import_song_button.size = Vector2(button_width, input_height)
	analysis_source_button.text = "SELECT SOURCE" if developer_generator else "WAVEFORM"
	audio_path.position = Vector2(second_x + 12.0, input_y)
	audio_path.size = Vector2(maxf(110.0, card_width - button_width - 32.0), input_height)
	analysis_source_button.position = Vector2(second_x + card_width - button_width - 12.0, input_y)
	analysis_source_button.size = Vector2(button_width, input_height)

	var tempo_width := 92.0 if compact_width else 122.0
	var bpm_width := 58.0 if compact_width else 74.0
	var generate_gap := 6.0 if compact_width else 8.0
	if developer_generator:
		tempo_mode_select.visible = true
		generate_all_button.visible = true
		tempo_mode_select.position = Vector2(third_x + 12.0, input_y)
		tempo_mode_select.size = Vector2(tempo_width, input_height)
		tempo_bpm_input.position = Vector2(third_x + 12.0 + tempo_width + generate_gap, input_y)
		tempo_bpm_input.size = Vector2(bpm_width, input_height)
		generate_all_button.position = Vector2(third_x + 12.0 + tempo_width + generate_gap + bpm_width + generate_gap, input_y)
		generate_all_button.size = Vector2(maxf(100.0 if compact_width else 128.0, card_width - tempo_width - bpm_width - generate_gap * 2.0 - 24.0), input_height)
	else:
		tempo_mode_select.visible = false
		generate_all_button.visible = false
		tempo_bpm_input.position = Vector2(third_x + 12.0, input_y)
		tempo_bpm_input.size = Vector2(card_width - 24.0, input_height)
	bulk_import_button.visible = false
	$AutoPanel/GeneratorProgress.visible = developer_generator
	$AutoPanel/GeneratorProgress.position = Vector2(16.0, setup_height - 5.0)
	$AutoPanel/GeneratorProgress.size = Vector2(content_width - 32.0, 3.0)

	var top_y := (62.0 if collapse_setup else setup_y + setup_height + 12.0)
	var top_height := 92.0 if compact_width else 62.0
	$TopBar.position = Vector2(margin, top_y)
	$TopBar.size = Vector2(content_width, top_height)
	var inner := 14.0
	var gap := 10.0
	if compact_width:
		var song_width := clampf(content_width * 0.58, 300.0, 560.0)
		var difficulty_width := content_width - inner * 2.0 - gap - song_width
		song_select.position = Vector2(inner, 8.0)
		song_select.size = Vector2(song_width, 34.0)
		difficulty_select.position = Vector2(inner + song_width + gap, 8.0)
		difficulty_select.size = Vector2(difficulty_width, 34.0)
		var action_y := 49.0
		save_button.position = Vector2(inner, action_y)
		save_button.size = Vector2(150.0, 34.0)
		undo_button.position = Vector2(inner + 160.0, action_y)
		undo_button.size = Vector2(90.0, 34.0)
		redo_button.position = Vector2(inner + 260.0, action_y)
		redo_button.size = Vector2(90.0, 34.0)
		back_button.position = Vector2(content_width - inner - 150.0, action_y)
		back_button.size = Vector2(150.0, 34.0)
	else:
		var song_width := clampf(content_width * 0.30, 340.0, 450.0)
		song_select.position = Vector2(inner, 11.0)
		song_select.size = Vector2(song_width, 40.0)
		difficulty_select.position = Vector2(inner + song_width + gap, 11.0)
		difficulty_select.size = Vector2(190.0, 40.0)
		save_button.position = Vector2(inner + song_width + gap + 202.0, 11.0)
		save_button.size = Vector2(150.0, 40.0)
		back_button.position = Vector2(content_width - inner - 156.0, 11.0)
		back_button.size = Vector2(156.0, 40.0)
		redo_button.position = Vector2(back_button.position.x - gap - 96.0, 11.0)
		redo_button.size = Vector2(96.0, 40.0)
		undo_button.position = Vector2(redo_button.position.x - gap - 96.0, 11.0)
		undo_button.size = Vector2(96.0, 40.0)

	var info_y := top_y + top_height + 8.0
	$Info.visible = false
	$Info.position = Vector2(margin, info_y)
	$Info.size = Vector2(content_width, 52.0)
	song_title.position = Vector2(16.0, 5.0)
	song_title.size = Vector2(content_width - 220.0, 24.0)
	chart_info.position = Vector2(16.0, 29.0)
	chart_info.size = Vector2(content_width - 220.0, 18.0)
	dirty_label.position = Vector2(content_width - 186.0, 15.0)
	dirty_label.size = Vector2(168.0, 22.0)

	var waveform_y := top_y + top_height + 8.0
	var waveform_height := 58.0 if compact_height else 88.0
	$WaveformPanel.position = Vector2(margin, waveform_y)
	$WaveformPanel.size = Vector2(content_width, waveform_height)
	var transport_y := waveform_y + waveform_height + 8.0
	var transport_height := 54.0 if compact_height else 58.0
	$Transport.position = Vector2(margin, transport_y)
	$Transport.size = Vector2(content_width, transport_height)
	var transport_control_y := 8.0 if compact_height else 9.0
	for node in [$Transport/Back5, $Transport/Back1, play_button, $Transport/Forward1, $Transport/Forward5, snap_toggle, snap_select]:
		node.position.y = transport_control_y
		node.size.y = 38.0 if compact_height else 40.0
	$Transport/Back5.position.x = 14.0
	$Transport/Back5.size.x = 66.0
	$Transport/Back1.position.x = 88.0
	$Transport/Back1.size.x = 66.0
	play_button.position.x = 164.0
	play_button.size.x = 108.0
	$Transport/Forward1.position.x = 282.0
	$Transport/Forward1.size.x = 66.0
	$Transport/Forward5.position.x = 356.0
	$Transport/Forward5.size.x = 66.0
	snap_select.position.x = content_width - 144.0
	snap_select.size.x = 130.0
	snap_toggle.position.x = snap_select.position.x - 122.0
	snap_toggle.size.x = 110.0
	time_label.position = Vector2(446.0, transport_control_y)
	time_label.size = Vector2(maxf(150.0, snap_toggle.position.x - 462.0), 40.0)

	var timeline_y := transport_y + transport_height + 8.0
	var tools_height := 52.0 if compact_height else 58.0
	var status_height := 20.0
	var lower_gap := 8.0
	var legend_height := 0.0 if compact_height else 20.0
	var reserve := lower_gap + tools_height + 5.0 + status_height + (3.0 + legend_height if not compact_height else 0.0) + 10.0
	# Keep the editor lanes concise. A very tall timeline makes notes harder to
	# scan and pushes the waveform—the useful musical overview—out of focus.
	var available_timeline_height := viewport_size.y - timeline_y - reserve
	var timeline_height := clampf(available_timeline_height, 112.0 if compact_height else 150.0, 152.0 if compact_height else 210.0)
	$TimelinePanel.position = Vector2(margin, timeline_y)
	$TimelinePanel.size = Vector2(content_width, timeline_height)

	var tools_y := timeline_y + timeline_height + lower_gap
	$Tools.position = Vector2(margin, tools_y)
	$Tools.size = Vector2(content_width, tools_height)
	var tool_buttons: Array[Button] = [$Tools/AddNormal, $Tools/AddReverse, $Tools/AddSpace, $Tools/DeleteNearest, $Tools/Reload]
	var tool_y := 7.0 if compact_height else 8.0
	var tool_height := 38.0 if compact_height else 40.0
	var tool_gap := 8.0
	var tool_width := (content_width - 28.0 - tool_gap * 4.0) / 5.0
	for index in range(tool_buttons.size()):
		tool_buttons[index].position = Vector2(14.0 + float(index) * (tool_width + tool_gap), tool_y)
		tool_buttons[index].size = Vector2(tool_width, tool_height)

	var status_y := tools_y + tools_height + 5.0
	status.position = Vector2(margin + 4.0, status_y)
	status.size = Vector2(content_width - 8.0, status_height)
	$Legend.visible = not compact_height
	$Legend.position = Vector2(margin + 4.0, status_y + status_height + 3.0)
	$Legend.size = Vector2(content_width - 8.0, legend_height)

func _connect_ui() -> void:
	song_select.item_selected.connect(_on_song_changed)
	difficulty_select.item_selected.connect(_on_difficulty_changed)
	load_button.pressed.connect(load_selected_chart)
	save_button.pressed.connect(save_chart)
	undo_button.pressed.connect(undo_edit)
	redo_button.pressed.connect(redo_edit)
	back_button.pressed.connect(return_to_game)
	play_button.pressed.connect(toggle_play)
	$Transport/Back5.pressed.connect(func(): seek_relative(-5.0))
	$Transport/Back1.pressed.connect(func(): seek_relative(-1.0))
	$Transport/Forward1.pressed.connect(func(): seek_relative(1.0))
	$Transport/Forward5.pressed.connect(func(): seek_relative(5.0))
	$Tools/AddNormal.pressed.connect(func(): add_event("normal"))
	$Tools/AddReverse.pressed.connect(func(): add_event("reverse"))
	$Tools/AddSpace.pressed.connect(add_space_event)
	$Tools/DeleteNearest.pressed.connect(delete_nearest)
	$Tools/Reload.pressed.connect(load_selected_chart)
	analysis_source_button.pressed.connect(_browse_analysis_source)
	import_song_button.pressed.connect(_browse_song)
	bulk_import_button.pressed.connect(_browse_bulk_songs)
	tempo_mode_select.item_selected.connect(_on_tempo_mode_changed)
	snap_select.item_selected.connect(_on_snap_grid_changed)
	snap_toggle.toggled.connect(_on_snap_grid_changed)
	tempo_bpm_input.text_submitted.connect(_on_tempo_bpm_submitted)
	tempo_bpm_input.focus_exited.connect(_commit_tempo_bpm)
	generate_all_button.pressed.connect(_generate_all_difficulties)
	song_file_dialog.file_selected.connect(_on_song_file_selected)
	bulk_file_dialog.files_selected.connect(_on_bulk_files_selected)
	analysis_source_dialog.file_selected.connect(_on_analysis_source_selected)
	timeline.seek_requested.connect(seek_to)
	waveform.seek_requested.connect(seek_to)
	music.finished.connect(func(): play_button.text = "PLAY")

func _on_snap_grid_changed(_value: Variant = null) -> void:
	_sync_timeline_grid()

func _sync_timeline_grid() -> void:
	var subdivisions := 1
	if snap_toggle.button_pressed and snap_select.selected >= 0:
		subdivisions = maxi(1, int(snap_select.get_item_id(snap_select.selected)))
	timeline.set_grid_subdivisions(subdivisions, snap_toggle.button_pressed)

func _on_song_changed(_index: int) -> void:
	if _selection_guard:
		return
	_refresh_difficulties()
	_update_selected_audio_path()
	_refresh_tempo_controls()
	load_selected_chart()

func _on_difficulty_changed(_index: int) -> void:
	if not _selection_guard:
		load_selected_chart()

func _browse_song() -> void:
	song_file_dialog.popup_centered_ratio(0.88)

func _browse_bulk_songs() -> void:
	bulk_file_dialog.popup_centered_ratio(0.88)

func _browse_analysis_source() -> void:
	if song_select.selected < 0 or song_select.selected >= songs.size():
		_set_status("Select or import a song before choosing its waveform/analysis source.", DANGER)
		return
	analysis_source_dialog.popup_centered_ratio(0.88)

func _on_analysis_source_selected(path: String) -> void:
	if song_select.selected < 0 or song_select.selected >= songs.size():
		_set_status("Select a song first.", DANGER)
		return
	if path.is_empty() or not FileAccess.file_exists(path):
		_set_status("SOURCE FAILED: Audio file was not found.", DANGER)
		return
	if not _is_supported_analysis_source(path):
		_set_status("SOURCE FAILED: Choose a .flac or PCM .wav file.", DANGER)
		return
	var song_id: String = songs[song_select.selected]
	_analysis_source_overrides[song_id] = path
	_update_selected_audio_path()
	if current_chart.is_empty():
		_set_status("Audio source selected: %s. Load a chart to build its waveform." % path.get_file(), GREEN)
		return
	_set_status("Audio source: %s. Building waveform preview…" % path.get_file(), SPACE)
	_build_waveform_preview_from_source(path, song_id)

func _build_waveform_preview_from_source(source_path: String, song_id: String) -> void:
	if _waveform_preview_busy or current_chart.is_empty():
		return
	_waveform_preview_busy = true
	_set_generation_controls_enabled(false)
	var pcm_result: Dictionary = await _prepare_pcm_analysis(_filesystem_path(source_path), song_id)
	if not bool(pcm_result.get("ok", false)):
		_waveform_preview_busy = false
		_set_generation_controls_enabled(true)
		_set_status("WAVEFORM PREVIEW FAILED: %s" % str(pcm_result.get("error", "Could not decode FLAC.")), DANGER)
		return
	var local_wav_path := str(pcm_result.get("path", ""))
	var local_analysis: Dictionary = wav_analyzer.analyze_wav(local_wav_path)
	if bool(pcm_result.get("temporary", false)) and FileAccess.file_exists(local_wav_path):
		DirAccess.remove_absolute(local_wav_path)
	_waveform_preview_busy = false
	_set_generation_controls_enabled(true)
	if not bool(local_analysis.get("ok", false)):
		_set_status("WAVEFORM PREVIEW FAILED: %s" % str(local_analysis.get("error", "Could not analyze PCM.")), DANGER)
		return
	if song_select.selected < 0 or song_select.selected >= songs.size() or songs[song_select.selected] != song_id:
		return
	if str(current_chart.get("song_id", current_chart.get("id", ""))) != song_id:
		return
	var preview := _build_waveform_preview(local_analysis)
	if preview.is_empty():
		_set_status("WAVEFORM PREVIEW FAILED: No usable audio envelope was produced.", DANGER)
		return
	current_chart["editor_waveform"] = preview
	_mark_dirty("AUDIO WAVEFORM READY · save the chart to keep it")

func _on_song_file_selected(path: String) -> void:
	_set_status("Checking OGG codec and preparing gameplay audio...", SPACE)
	var result: Dictionary = await _import_song_file(path)
	if not bool(result.get("ok", false)):
		_set_status("IMPORT FAILED: %s" % str(result.get("error", "Unknown error")), DANGER)
		return
	_reload_after_import(str(result.get("song_id", "")))
	if bool(result.get("reused", false)):
		_set_status("This OGG is already imported. Reusing %s; no duplicate song was created." % str(result.get("song_id", "")), GREEN)
	else:
		if _developer_generator_enabled():
			_set_status("Imported %s → local custom songs/%s. Edit manually or use the developer generator." % [str(result.get("title", path.get_file())), str(result.get("song_id", ""))], GREEN)
		else:
			_set_status("Imported %s → local custom songs/%s. Blank NORMAL / HARD / MASTER drafts are ready for manual charting." % [str(result.get("title", path.get_file())), str(result.get("song_id", ""))], GREEN)

func _on_bulk_files_selected(paths: PackedStringArray) -> void:
	if paths.is_empty():
		return
	_set_generation_controls_enabled(false)
	var imported := 0
	var failed: PackedStringArray = PackedStringArray()
	var last_song_id := ""
	for path in paths:
		var result: Dictionary = await _import_song_file(path)
		if bool(result.get("ok", false)):
			imported += 1
			last_song_id = str(result.get("song_id", last_song_id))
		else:
			failed.append("%s: %s" % [path.get_file(), str(result.get("error", "failed"))])
	_set_generation_controls_enabled(true)
	if imported > 0:
		_reload_after_import(last_song_id)
	var summary := "Imported %d/%d songs. No charts were generated." % [imported, paths.size()]
	if not failed.is_empty():
		summary += " Failed: %s" % "; ".join(failed)
	_set_status(summary, GREEN if failed.is_empty() else SPACE)

func _set_generation_controls_enabled(enabled: bool) -> void:
	var developer_generator := _developer_generator_enabled()
	generate_all_button.disabled = not enabled or not developer_generator
	analysis_source_button.disabled = not enabled
	import_song_button.disabled = not enabled
	bulk_import_button.disabled = not enabled
	tempo_mode_select.disabled = not enabled or not developer_generator
	if developer_generator:
		tempo_bpm_input.editable = enabled and _selected_tempo_mode() == "custom"
	else:
		tempo_bpm_input.editable = enabled and not current_chart.is_empty()
	if enabled and developer_generator:
		generate_all_button.text = "GENERATE ALL"

func _reset_generator_progress() -> void:
	generator_progress.value = 0.0
	generator_progress_text.text = "READY  •  %s" % wav_analyzer.get_generator_code()

func _set_generator_progress(percent: float, phase: String, detail: String = "") -> void:
	var safe_percent: float = clampf(percent, 0.0, 100.0)
	generator_progress.value = safe_percent
	var suffix := "" if detail.is_empty() else "  •  %s" % detail
	generator_progress_text.text = "%3d%%  •  %s%s  •  %s" % [int(round(safe_percent)), phase, suffix, wav_analyzer.get_generator_code()]

func _chart_generator_code(chart: Dictionary) -> String:
	var meta_value: Variant = chart.get("generator_meta", {})
	if meta_value is Dictionary:
		var code: String = str((meta_value as Dictionary).get("code", ""))
		if not code.is_empty():
			return code
	var import_value: Variant = chart.get("import_meta", {})
	if import_value is Dictionary:
		var state := str((import_value as Dictionary).get("state", ""))
		if state == "manual_draft" or state == "imported_not_generated":
			return "MANUAL DRAFT"
		if state == "manual":
			return "MANUAL"
	return "LEGACY / UNSTAMPED"

func _generate_all_difficulties() -> void:
	if not _developer_generator_enabled():
		_set_status("Automatic chart generation is developer-only. Create this chart manually in the timeline editor.", DANGER)
		return
	if song_select.selected < 0 or song_select.selected >= songs.size():
		_set_status("Select a song first.", DANGER)
		return
	var source_path: String = _selected_audio_source()
	var source_filesystem_path: String = _filesystem_path(source_path)
	if source_filesystem_path.is_empty() or not FileAccess.file_exists(source_filesystem_path):
		_set_status("Select a .flac or PCM .wav analysis source for this song first.", DANGER)
		return
	if not _is_supported_analysis_source(source_filesystem_path):
		_set_status("The analysis source must be a .flac or PCM .wav file.", DANGER)
		return
	var song_id: String = songs[song_select.selected]
	var source_format: String = source_filesystem_path.get_extension().to_upper()
	_set_generation_controls_enabled(false)
	var gameplay_audio_path: String = _selected_gameplay_audio_source()
	var gameplay_audio_filesystem_path: String = _filesystem_path(gameplay_audio_path)
	if gameplay_audio_path.get_extension().to_lower() != "ogg" or gameplay_audio_filesystem_path.is_empty() or not FileAccess.file_exists(gameplay_audio_filesystem_path):
		_set_generation_controls_enabled(true)
		_set_status("Import a gameplay .ogg file for this song before generating charts.", DANGER)
		return
	if gameplay_audio_path.get_extension().to_lower() == "ogg" and FileAccess.file_exists(gameplay_audio_filesystem_path) and _detect_ogg_codec(gameplay_audio_filesystem_path) != "vorbis":
		_set_generator_progress(1.0, "REPAIR OGG", song_id)
		generate_all_button.text = "CONVERTING TO VORBIS..."
		_set_status("The imported OGG uses an unsupported codec. Converting gameplay audio to Ogg Vorbis...", SPACE)
		var repair_result: Dictionary = await _prepare_gameplay_ogg(gameplay_audio_filesystem_path, gameplay_audio_filesystem_path, song_id)
		if not bool(repair_result.get("ok", false)):
			_set_generator_progress(generator_progress.value, "ERROR", song_id)
			_set_generation_controls_enabled(true)
			_set_status("PLAYBACK AUDIO REPAIR FAILED: %s" % str(repair_result.get("error", "Unknown error")), DANGER)
			return
	_set_generator_progress(3.0, "PREPARE", song_id)
	generate_all_button.text = "PREPARING %s..." % source_format
	_set_status("Preparing lossless %s analysis for %s as deterministic PCM. Gameplay audio stays OGG." % [source_format, song_id], SPACE)
	await get_tree().process_frame

	# Normalize the selected FLAC source to deterministic PCM16 WAV for both analysis passes.
	# Gameplay audio remains the separately imported Ogg Vorbis file.
	var pcm_result: Dictionary = await _prepare_pcm_analysis(source_filesystem_path, song_id)
	if not bool(pcm_result.get("ok", false)):
		_set_generator_progress(generator_progress.value, "ERROR", song_id)
		_set_generation_controls_enabled(true)
		_set_status("AUDIO DECODE FAILED: %s" % str(pcm_result.get("error", "Unknown error")), DANGER)
		return
	var local_wav_path: String = str(pcm_result.get("path", ""))

	_set_generator_progress(9.0, "ALL-IN-ONE", song_id)
	generate_all_button.text = "ANALYZING..."
	_set_status("Analyzing %s from lossless FLAC normalized to PCM. Source: %s." % [song_id, source_format], SPACE)
	var allin1_result: Dictionary = await _run_allin1_analysis(local_wav_path, song_id, source_filesystem_path)
	if not bool(allin1_result.get("ok", false)):
		# v18.7 Quick Generate keeps creation available without the optional AI
		# environment. Local PCM analysis still supplies tempo, energy, sections,
		# directions, and difficulty shaping.
		_set_generator_progress(42.0, "QUICK GENERATE", song_id)
		_set_status("Advanced AI analysis is unavailable. Continuing with local Quick Generate.", SPACE)

	_set_generator_progress(48.0, "RHYTHM + CHART", song_id)
	generate_all_button.text = "GENERATING N / H / M..."
	var generated: Dictionary = await _generate_song_charts(song_id, local_wav_path, allin1_result, {"single": true}, source_path)
	if bool(pcm_result.get("temporary", false)) and FileAccess.file_exists(local_wav_path):
		DirAccess.remove_absolute(local_wav_path)
	if not bool(generated.get("ok", false)):
		_set_generator_progress(generator_progress.value, "ERROR", song_id)
		_set_generation_controls_enabled(true)
		_set_status("GENERATION FAILED: %s" % str(generated.get("error", "Unknown error")), DANGER)
		return

	_reload_after_generation(song_id)
	_set_generator_progress(100.0, "COMPLETE", song_id)
	_set_generation_controls_enabled(true)
	_set_status(_generation_summary("SELECTED SONG COMPLETE", generated), GREEN)

func _update_chart_stage_progress(context: Dictionary, song_id: String, stage: String, subprogress: float) -> void:
	if bool(context.get("single", false)):
		_set_generator_progress(48.0 + clampf(subprogress, 0.0, 1.0) * 50.0, stage, song_id)
		return
	var job_index: int = int(context.get("job_index", 1))
	var job_total: int = maxi(1, int(context.get("job_total", 1)))
	var fraction: float = (float(job_index - 1) + clampf(subprogress, 0.0, 1.0)) / float(job_total)
	_set_generator_progress(55.0 + fraction * 44.0, stage, "%d/%d  %s" % [job_index, job_total, song_id])

func _generate_song_charts(song_id: String, source_path: String, allin1_result: Dictionary, progress_context: Dictionary = {}, metadata_source_path: String = "") -> Dictionary:
	_update_chart_stage_progress(progress_context, song_id, "LOCAL ANALYSIS", 0.05)
	await get_tree().process_frame
	var local_analysis: Dictionary = await _run_local_wav_analysis(source_path, song_id, progress_context)
	if not bool(local_analysis.get("ok", false)):
		return {"ok": false, "error": "Local PCM analysis failed: %s" % str(local_analysis.get("error", "Unknown error"))}
	if not metadata_source_path.is_empty():
		# Keep local machine folders out of chart JSON. The source identity is
		# enough for diagnostics; actual analysis already used source_path above.
		local_analysis["source_wav"] = metadata_source_path if metadata_source_path.begins_with("res://") or metadata_source_path.begins_with("user://") else metadata_source_path.get_file()
		local_analysis["source_audio_name"] = metadata_source_path.get_file()
		local_analysis["source_audio_format"] = metadata_source_path.get_extension().to_lower()
	var resolved_request: Dictionary = allin1_result.duplicate(true)
	resolved_request["beat_up_tempo_mode"] = str(_tempo_mode_overrides.get(song_id, "auto"))
	resolved_request["beat_up_custom_bpm"] = float(_tempo_custom_bpm.get(song_id, 0.0))
	var analysis: Dictionary
	if bool(resolved_request.get("ok", false)):
		analysis = wav_analyzer.apply_allin1_analysis(local_analysis, resolved_request)
	else:
		analysis = local_analysis.duplicate(true)
		analysis["allin1_used"] = false
		analysis["structure_source"] = "local_pcm_quick_generate"
		analysis["analysis_model"] = "local_pcm_quick_generate_v187"
		analysis["tempo_raw_bpm"] = float(analysis.get("bpm", 0.0))
		analysis["tempo_multiplier"] = 1.0
		analysis["tempo_mode"] = "local_auto"
	if not bool(analysis.get("ok", false)):
		return {"ok": false, "error": "Hybrid analysis failed: %s" % str(analysis.get("error", "Unknown error"))}
	var waveform_preview := _build_waveform_preview(analysis)

	var generated_counts: PackedInt32Array = PackedInt32Array()
	var generated_spaces: PackedInt32Array = PackedInt32Array()
	var generated_difficulties: PackedStringArray = PackedStringArray()
	var staged_outputs: Array = []
	var difficulty_index := 0
	for difficulty_id in ["normal", "hard", "master"]:
		difficulty_index += 1
		_update_chart_stage_progress(progress_context, song_id, "GENERATE %s" % difficulty_id.to_upper(), 0.16 + float(difficulty_index - 1) * 0.20)
		await get_tree().process_frame
		var base_chart: Dictionary = _find_chart(song_id, difficulty_id)
		if base_chart.is_empty():
			continue
		var chart_path: String = str(base_chart.get("_path", ""))
		if chart_path.is_empty():
			continue
		var generated_chart: Dictionary = wav_analyzer.generate_chart(base_chart, analysis, difficulty_id)
		generated_chart.erase("_path")
		if not waveform_preview.is_empty():
			generated_chart["editor_waveform"] = waveform_preview.duplicate(true)
		var import_value: Variant = generated_chart.get("import_meta", {})
		if import_value is Dictionary:
			var import_meta: Dictionary = (import_value as Dictionary).duplicate(true)
			import_meta["state"] = "generated"
			import_meta["generated_at"] = Time.get_datetime_string_from_system()
			generated_chart["import_meta"] = import_meta
		var validation: Dictionary = wav_analyzer.validate_generated_chart(generated_chart)
		if not bool(validation.get("ok", false)):
			return {"ok": false, "error": "%s validation: %s" % [difficulty_id.to_upper(), str(validation.get("error", "Unknown error"))]}
		var event_values: Array = _as_array(generated_chart.get("events", []))
		var space_values: Array = _as_array(generated_chart.get("space_events", []))
		generated_counts.append(event_values.size())
		generated_spaces.append(space_values.size())
		generated_difficulties.append(difficulty_id)
		staged_outputs.append({"path": chart_path, "chart": generated_chart})

	if generated_difficulties.is_empty():
		return {"ok": false, "error": "No Normal/Hard/Master chart files exist for %s." % song_id}

	# Apply the same readability guard established by the v17.4.19 library pass.
	# The Python process is already a generator dependency (All-In-One), so this
	# safety pass can reuse it while keeping all retained timestamps/directions and
	# every SPACE event intact.
	_update_chart_stage_progress(progress_context, song_id, "READABILITY GUARD", 0.80)
	if bool(analysis.get("allin1_used", false)):
		var standardized: Dictionary = await _standardize_generated_outputs(staged_outputs, song_id)
		if not bool(standardized.get("ok", false)):
			return {"ok": false, "error": "Readability guard failed: %s" % str(standardized.get("error", "Unknown error"))}
		var standardized_outputs_value: Variant = standardized.get("outputs", staged_outputs)
		if standardized_outputs_value is Array:
			staged_outputs = standardized_outputs_value as Array

	# Final deterministic gate evaluates the complete N/H/M ladder together.
	# No chart reaches disk unless timing, fatigue budgets, direction flow, and
	# strict difficulty progression all agree.
	_update_chart_stage_progress(progress_context, song_id, "QUALITY GATE", 0.84)
	var chart_set: Array = []
	for raw_output in staged_outputs:
		if raw_output is Dictionary:
			chart_set.append((raw_output as Dictionary).get("chart", {}) as Dictionary)
	var quality_gate: Dictionary = wav_analyzer.finalize_generated_set(chart_set, analysis)
	if not bool(quality_gate.get("ok", false)):
		var quality_errors: Array = _as_array(quality_gate.get("errors", []))
		var quality_messages := PackedStringArray()
		for raw_error in quality_errors:
			quality_messages.append(str(raw_error))
		return {"ok": false, "error": "Generator quality gate rejected the chart set: %s" % "; ".join(quality_messages)}
	var quality_scores := PackedInt32Array()
	var quality_grades := PackedStringArray()
	var quality_reports: Dictionary = quality_gate.get("reports", {}) as Dictionary
	for quality_difficulty in ["normal", "hard", "master"]:
		var quality_report: Dictionary = quality_reports.get(quality_difficulty, {}) as Dictionary
		quality_scores.append(int(quality_report.get("score", 0)))
		quality_grades.append(str(quality_report.get("grade", "REVIEW")))
	generated_counts.clear()
	generated_spaces.clear()
	for raw_output in staged_outputs:
		if not (raw_output is Dictionary):
			continue
		var processed_chart: Dictionary = (raw_output as Dictionary).get("chart", {}) as Dictionary
		generated_counts.append(_as_array(processed_chart.get("events", [])).size())
		generated_spaces.append(_as_array(processed_chart.get("space_events", [])).size())

	# Validate all three difficulties before touching final song files. This
	# prevents a bad Master chart from leaving Normal/Hard half-updated.
	_update_chart_stage_progress(progress_context, song_id, "VALIDATE + SAVE", 0.88)
	await get_tree().process_frame
	for raw_output in staged_outputs:
		var staged: Dictionary = raw_output as Dictionary
		if not _write_chart_dictionary(str(staged.get("path", "")), staged.get("chart", {}) as Dictionary):
			return {"ok": false, "error": "Could not write %s" % str(staged.get("path", ""))}

	var sections: Array = _as_array(analysis.get("sections", []))
	var chorus_count := 0
	var form_roles: PackedStringArray = PackedStringArray()
	for raw_section in sections:
		if not (raw_section is Dictionary):
			continue
		var role: String = str((raw_section as Dictionary).get("role", "verse"))
		form_roles.append(role.to_upper())
		if role == "chorus":
			chorus_count += 1
	return {
		"ok": true,
		"song_id": song_id,
		"source_path": source_path,
		"bpm": float(analysis.get("bpm", 0.0)),
		"raw_bpm": float(analysis.get("tempo_raw_bpm", analysis.get("bpm", 0.0))),
		"tempo_multiplier": float(analysis.get("tempo_multiplier", 1.0)),
		"tempo_mode": str(analysis.get("tempo_mode", "auto")),
		"tempo_decision": str(analysis.get("tempo_decision", "")),
		"downbeats": _as_array(analysis.get("allin1_downbeats", [])).size(),
		"section_count": sections.size(),
		"chorus_count": chorus_count,
		"form": " > ".join(form_roles),
		"difficulties": generated_difficulties,
		"note_counts": generated_counts,
		"space_counts": generated_spaces,
		"quality_scores": quality_scores,
		"quality_grades": quality_grades,
		"generator_mode": "advanced_ai" if bool(analysis.get("allin1_used", false)) else "quick_local",
	}

func _build_waveform_preview(analysis: Dictionary) -> Dictionary:
	var energy := _as_array(analysis.get("energy", []))
	if energy.is_empty():
		return {}
	# Preserve enough temporal detail for the scrolling 12-second waveform lane.
	const TARGET_SAMPLES := 4096
	var bucket_size := maxi(1, ceili(float(energy.size()) / float(TARGET_SAMPLES)))
	var bucket_values: Array[float] = []
	var index := 0
	while index < energy.size():
		var end_index := mini(index + bucket_size, energy.size())
		var peak := 0.0
		var total := 0.0
		var count := 0
		for sample_index in range(index, end_index):
			var value := maxf(0.0, float(energy[sample_index]))
			peak = maxf(peak, value)
			total += value
			count += 1
		var average := total / float(maxi(1, count))
		bucket_values.append(peak * 0.72 + average * 0.28)
		index = end_index
	if bucket_values.is_empty():
		return {}
	var ordered := bucket_values.duplicate()
	ordered.sort()
	var reference_index := clampi(floori(float(ordered.size() - 1) * 0.96), 0, ordered.size() - 1)
	var reference_level := maxf(0.000001, ordered[reference_index])
	var normalized: Array[float] = []
	for value in bucket_values:
		# Square-root compression keeps quiet verses visible without flattening peaks.
		normalized.append(snappedf(sqrt(clampf(value / reference_level, 0.0, 1.0)), 0.001))
	return {
		"version": 2,
		"kind": "pcm_energy_envelope",
		"source": "PCM AUDIO WAVEFORM  ·  12 SEC WINDOW",
		"duration": snappedf(float(analysis.get("duration", 1.0)), 0.001),
		"peaks": normalized,
	}

func _standardize_generated_outputs(staged_outputs: Array, song_id: String) -> Dictionary:
	var script_path: String = _postprocess_filesystem_path()
	if script_path.is_empty() or not FileAccess.file_exists(script_path):
		return {"ok": false, "error": "Chart Studio readability tool is missing."}
	var bridge_path: String = _bridge_filesystem_path()
	var runner_result: Dictionary = await _resolve_audio_runner(bridge_path)
	if not bool(runner_result.get("ok", false)):
		return runner_result

	var staging_root: String = ProjectSettings.globalize_path("user://chart_studio_staging/%s_%d" % [song_id, Time.get_ticks_msec()])
	var mkdir_error: Error = DirAccess.make_dir_recursive_absolute(staging_root)
	if mkdir_error != OK and not DirAccess.dir_exists_absolute(staging_root):
		return {"ok": false, "error": "Could not create Chart Studio staging folder."}

	var staged_names: Array[String] = []
	for raw_output in staged_outputs:
		if not (raw_output is Dictionary):
			continue
		var staged: Dictionary = raw_output as Dictionary
		var chart: Dictionary = staged.get("chart", {}) as Dictionary
		var difficulty_id: String = str(chart.get("chart_difficulty", chart.get("difficulty", "normal"))).to_lower()
		var filename: String = "%s.json" % difficulty_id
		var stage_path: String = staging_root.path_join(filename)
		var file: FileAccess = FileAccess.open(stage_path, FileAccess.WRITE)
		if file == null:
			_remove_tree_absolute(staging_root)
			return {"ok": false, "error": "Could not stage %s for readability processing." % difficulty_id.to_upper()}
		file.store_string(JSON.stringify(chart, "\t", false))
		file.close()
		staged_names.append(filename)

	var report_path: String = staging_root.path_join("report.json")
	var args: PackedStringArray = _runner_args(_audio_runner, PackedStringArray([
		script_path,
		"--directory", staging_root,
		"--output", report_path,
	]))
	var process_result: Dictionary = await _run_process_async(str(_audio_runner.get("command", "")), args)
	if int(process_result.get("exit_code", -1)) != 0:
		var process_error: String = str(process_result.get("output", "Readability post-process failed.")).strip_edges()
		_remove_tree_absolute(staging_root)
		return {"ok": false, "error": process_error}

	var processed_by_difficulty: Dictionary = {}
	for filename in staged_names:
		var stage_path: String = staging_root.path_join(filename)
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(stage_path))
		if not (parsed is Dictionary):
			_remove_tree_absolute(staging_root)
			return {"ok": false, "error": "Readability tool returned invalid %s." % filename}
		var chart: Dictionary = parsed as Dictionary
		var validation: Dictionary = wav_analyzer.validate_generated_chart(chart)
		if not bool(validation.get("ok", false)):
			_remove_tree_absolute(staging_root)
			return {"ok": false, "error": "%s after readability guard: %s" % [filename, str(validation.get("error", "validation failed"))]}
		processed_by_difficulty[str(chart.get("chart_difficulty", chart.get("difficulty", "normal"))).to_lower()] = chart

	var outputs: Array = []
	for raw_output in staged_outputs:
		if not (raw_output is Dictionary):
			continue
		var staged: Dictionary = raw_output as Dictionary
		var original_chart: Dictionary = staged.get("chart", {}) as Dictionary
		var difficulty_id: String = str(original_chart.get("chart_difficulty", original_chart.get("difficulty", "normal"))).to_lower()
		if not processed_by_difficulty.has(difficulty_id):
			_remove_tree_absolute(staging_root)
			return {"ok": false, "error": "Readability tool omitted %s." % difficulty_id.to_upper()}
		outputs.append({"path": str(staged.get("path", "")), "chart": processed_by_difficulty[difficulty_id]})

	_remove_tree_absolute(staging_root)
	return {"ok": true, "outputs": outputs}

func _postprocess_filesystem_path() -> String:
	return _materialize_python_tool(CHART_STUDIO_POSTPROCESS_PATH, "chart_studio_postprocess_v17421.py")

func _remove_tree_absolute(path: String) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var entry: String = dir.get_next()
		if entry.is_empty():
			break
		if entry == "." or entry == "..":
			continue
		var child: String = path.path_join(entry)
		if dir.current_is_dir():
			_remove_tree_absolute(child)
		else:
			DirAccess.remove_absolute(child)
	dir.list_dir_end()
	DirAccess.remove_absolute(path)

func _generation_summary(prefix: String, result: Dictionary) -> String:
	var note_counts: PackedInt32Array = result.get("note_counts", PackedInt32Array()) as PackedInt32Array
	var space_counts: PackedInt32Array = result.get("space_counts", PackedInt32Array()) as PackedInt32Array
	var count_text := ""
	if note_counts.size() >= 3 and space_counts.size() >= 3:
		count_text = "notes %d/%d/%d • SPACE %d/%d/%d" % [note_counts[0], note_counts[1], note_counts[2], space_counts[0], space_counts[1], space_counts[2]]
	var tempo_text := "%.2f BPM" % float(result.get("bpm", 0.0))
	var raw_bpm: float = float(result.get("raw_bpm", result.get("bpm", 0.0)))
	var multiplier: float = float(result.get("tempo_multiplier", 1.0))
	if absf(multiplier - 1.0) > 0.01:
		tempo_text = "%.2f → %.2f BPM (%s)" % [raw_bpm, float(result.get("bpm", 0.0)), _tempo_multiplier_label(multiplier)]
	var quality_scores: PackedInt32Array = result.get("quality_scores", PackedInt32Array()) as PackedInt32Array
	var quality_grades: PackedStringArray = result.get("quality_grades", PackedStringArray()) as PackedStringArray
	var quality_text := ""
	if quality_scores.size() >= 3 and quality_grades.size() >= 3:
		quality_text = " • QUALITY %s/%s/%s %d/%d/%d" % [quality_grades[0], quality_grades[1], quality_grades[2], quality_scores[0], quality_scores[1], quality_scores[2]]
	return "%s • %s • %d parts / %d chorus • %s • %s%s" % [
		prefix,
		tempo_text,
		int(result.get("section_count", 0)),
		int(result.get("chorus_count", 0)),
		str(result.get("form", "")),
		count_text,
		quality_text,
	]

func _reload_after_generation(song_id: String) -> void:
	_load_catalog()
	_selection_guard = true
	_populate_song_select()
	var restored_index: int = songs.find(song_id)
	if restored_index >= 0:
		song_select.select(restored_index)
	_selection_guard = false
	_refresh_difficulties()
	_update_selected_audio_path()
	_refresh_tempo_controls()
	load_selected_chart()

func _prepare_pcm_analysis(source_path: String, song_id: String) -> Dictionary:
	if not _is_supported_analysis_source(source_path):
		return {"ok": false, "error": "Chart generation requires a .flac or PCM .wav analysis source."}
	if source_path.get_extension().to_lower() == "wav":
		return {"ok": true, "path": source_path, "temporary": false, "mode": "direct_pcm"}
	var bridge_path: String = _bridge_filesystem_path()
	var runner_result: Dictionary = await _resolve_audio_runner(bridge_path)
	if not bool(runner_result.get("ok", false)):
		return runner_result
	var cache_dir: String = ProjectSettings.globalize_path("user://chart_analysis_cache")
	var mkdir_error: Error = DirAccess.make_dir_recursive_absolute(cache_dir)
	if mkdir_error != OK and not DirAccess.dir_exists_absolute(cache_dir):
		return {"ok": false, "error": "Could not create the local analysis cache."}
	var output_path: String = cache_dir.path_join("%s_%d.wav" % [song_id, Time.get_ticks_msec()])
	var args: PackedStringArray = _runner_args(_audio_runner, PackedStringArray([
		bridge_path,
		"--decode-wav", source_path,
		"--wav-output", output_path,
	]))
	var process_result: Dictionary = await _run_process_async(str(_audio_runner.get("command", "")), args)
	if int(process_result.get("exit_code", -1)) != 0 or not FileAccess.file_exists(output_path):
		if FileAccess.file_exists(output_path):
			DirAccess.remove_absolute(output_path)
		return {"ok": false, "error": str(process_result.get("output", "Could not normalize audio to PCM WAV.")).strip_edges()}
	return {"ok": true, "path": output_path, "temporary": true}

func _is_supported_analysis_source(path: String) -> bool:
	return path.get_extension().to_lower() in ["flac", "wav"]

func _import_song_file(source_path: String) -> Dictionary:
	if source_path.is_empty() or not FileAccess.file_exists(source_path):
		return {"ok": false, "error": "Audio file was not found."}
	if source_path.get_extension().to_lower() != "ogg":
		return {"ok": false, "error": "Gameplay audio must be an .ogg file."}
	var base_id: String = _sanitize_song_id(source_path.get_file().get_basename())
	if base_id.is_empty():
		base_id = "new_song"
	var existing_import: Dictionary = _find_existing_import_for_source(source_path, base_id)
	if not existing_import.is_empty():
		# Re-select the existing draft/generated song instead of publishing another
		# suffixed copy every time the same OGG is chosen after a failed attempt.
		existing_import["ok"] = true
		existing_import["reused"] = true
		return existing_import
	var song_id: String = _unique_import_song_id(base_id)
	var title: String = source_path.get_file().get_basename().replace("_", " ").replace("-", " ").strip_edges().to_upper()
	var chart_dir_resource: String = IMPORTED_CHART_ROOT.path_join(song_id)
	var chart_dir_absolute: String = ProjectSettings.globalize_path(chart_dir_resource)
	var chart_mkdir: Error = DirAccess.make_dir_recursive_absolute(chart_dir_absolute)
	if chart_mkdir != OK and not DirAccess.dir_exists_absolute(chart_dir_absolute):
		return {"ok": false, "error": "Could not create the local custom-song folder."}
	var destination_resource: String = chart_dir_resource.path_join("%s.ogg" % song_id)
	var destination_absolute: String = ProjectSettings.globalize_path(destination_resource)
	var source_codec: String = _detect_ogg_codec(source_path)
	var playback_result: Dictionary = await _prepare_gameplay_ogg(source_path, destination_absolute, song_id)
	if not bool(playback_result.get("ok", false)):
		_remove_tree_absolute(chart_dir_absolute)
		return playback_result
	var duration: float = _audio_file_duration(destination_absolute)
	if duration <= 1.0:
		_remove_tree_absolute(chart_dir_absolute)
		return {"ok": false, "error": "The imported OGG could not be decoded as Ogg Vorbis."}
	var seed_value: int = abs(song_id.hash()) % 100000
	for difficulty_id in ["normal", "hard", "master"]:
		var star_rating := 3 if difficulty_id == "normal" else (6 if difficulty_id == "hard" else 9)
		var base_chart := {
			"id": "%s_%s" % [song_id, difficulty_id],
			"song_id": song_id,
			"title": title,
			"artist": "Unknown Artist",
			"difficulty": difficulty_id.to_upper(),
			"chart_difficulty": difficulty_id,
			"star_rating": star_rating,
			"audio": destination_resource,
			"analysis_source": "",
			"bpm": 120.0,
			"beat_offset": 0.0,
			"duration": duration,
			"seed": seed_value,
			"recommended": "%s • %d★ • manual chart draft" % [difficulty_id.to_upper(), star_rating],
			"events": [],
			"space_events": [],
			"runtime_directions": false,
			"authored_directions": true,
			"import_meta": {
				"source_name": source_path.get_file(),
				"source_codec": source_codec,
				"gameplay_codec": "vorbis",
				"codec_normalized": source_codec != "vorbis",
				"storage": "user://songs",
				"imported_at": Time.get_datetime_string_from_system(),
				"state": "manual_draft",
			},
		}
		var chart_path: String = chart_dir_resource.path_join("%s.json" % difficulty_id)
		if not _write_chart_dictionary(chart_path, base_chart):
			_remove_tree_absolute(chart_dir_absolute)
			return {"ok": false, "error": "Could not create %s." % chart_path}
	return {"ok": true, "song_id": song_id, "title": title, "audio": destination_resource, "source_codec": source_codec, "gameplay_codec": "vorbis"}

func _find_existing_import_for_source(source_path: String, base_id: String) -> Dictionary:
	var source_name: String = source_path.get_file()
	var seen: Dictionary = {}
	for chart in charts:
		var song_id: String = str(chart.get("song_id", chart.get("id", "")))
		if song_id.is_empty() or seen.has(song_id):
			continue
		seen[song_id] = true
		var import_value: Variant = chart.get("import_meta", {})
		if not (import_value is Dictionary):
			continue
		var import_meta: Dictionary = import_value as Dictionary
		var imported_name: String = str(import_meta.get("source_name", ""))
		if imported_name != source_name and song_id != base_id:
			continue
		var audio_resource: String = str(chart.get("audio", ""))
		var audio_filesystem: String = _filesystem_path(audio_resource)
		if audio_resource.is_empty() or not FileAccess.file_exists(audio_filesystem):
			continue
		return {
			"song_id": song_id,
			"title": str(chart.get("title", source_path.get_file().get_basename().to_upper())),
			"audio": audio_resource,
			"source_codec": str(import_meta.get("source_codec", _detect_ogg_codec(audio_filesystem))),
			"gameplay_codec": str(import_meta.get("gameplay_codec", "vorbis")),
		}
	return {}

func _selected_gameplay_audio_source() -> String:
	var representative: Dictionary = _find_any_chart_for_song(_selected_song_id())
	return str(representative.get("audio", ""))

func _prepare_gameplay_ogg(source_path: String, destination_path: String, song_id: String) -> Dictionary:
	var codec: String = _detect_ogg_codec(source_path)
	if codec == "vorbis":
		if source_path == destination_path:
			return {"ok": true, "codec": "vorbis", "converted": false}
		var direct_copy_result: Dictionary = _copy_binary_file(source_path, destination_path)
		if bool(direct_copy_result.get("ok", false)):
			direct_copy_result["codec"] = "vorbis"
			direct_copy_result["converted"] = false
		return direct_copy_result

	var bridge_path: String = _bridge_filesystem_path()
	var runner_result: Dictionary = await _resolve_audio_runner(bridge_path)
	if not bool(runner_result.get("ok", false)):
		return {"ok": false, "error": "This OGG uses %s audio and must be converted to Vorbis. %s" % [codec.to_upper(), str(runner_result.get("error", "Python audio tools are unavailable."))]}
	var temporary_path := "%s.vorbis_%s_%d.ogg" % [destination_path, song_id, Time.get_ticks_msec()]
	var args: PackedStringArray = _runner_args(_audio_runner, PackedStringArray([
		bridge_path,
		"--transcode-vorbis", source_path,
		"--ogg-output", temporary_path,
	]))
	var process_result: Dictionary = await _run_process_async(str(_audio_runner.get("command", "")), args)
	if int(process_result.get("exit_code", -1)) != 0 or not FileAccess.file_exists(temporary_path):
		if FileAccess.file_exists(temporary_path):
			DirAccess.remove_absolute(temporary_path)
		return {"ok": false, "error": str(process_result.get("output", "Could not convert OGG to Vorbis.")).strip_edges()}
	if _detect_ogg_codec(temporary_path) != "vorbis":
		DirAccess.remove_absolute(temporary_path)
		return {"ok": false, "error": "Audio conversion finished but did not produce an Ogg Vorbis stream."}
	var copy_result: Dictionary = _copy_binary_file(temporary_path, destination_path)
	DirAccess.remove_absolute(temporary_path)
	if not bool(copy_result.get("ok", false)):
		return copy_result
	return {"ok": true, "codec": "vorbis", "source_codec": codec, "converted": true}

func _detect_ogg_codec(path: String) -> String:
	if path.is_empty() or not FileAccess.file_exists(path):
		return "missing"
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "unreadable"
	var bytes: PackedByteArray = file.get_buffer(mini(file.get_length(), 131072))
	file.close()
	if _bytes_contain_ascii(bytes, "OpusHead"):
		return "opus"
	if _bytes_contain_ascii(bytes, "vorbis"):
		return "vorbis"
	return "unknown"

func _bytes_contain_ascii(bytes: PackedByteArray, token: String) -> bool:
	var target: PackedByteArray = token.to_ascii_buffer()
	if target.is_empty() or bytes.size() < target.size():
		return false
	for start in range(bytes.size() - target.size() + 1):
		var matches := true
		for offset in range(target.size()):
			if bytes[start + offset] != target[offset]:
				matches = false
				break
		if matches:
			return true
	return false

func _copy_binary_file(source_path: String, destination_path: String) -> Dictionary:
	var input: FileAccess = FileAccess.open(source_path, FileAccess.READ)
	if input == null:
		return {"ok": false, "error": "Could not read %s." % source_path.get_file()}
	var output: FileAccess = FileAccess.open(destination_path, FileAccess.WRITE)
	if output == null:
		input.close()
		return {"ok": false, "error": "Could not write to the project music folder."}
	var copy_chunk_size := 1024 * 1024
	while input.get_position() < input.get_length():
		var remaining: int = input.get_length() - input.get_position()
		output.store_buffer(input.get_buffer(mini(copy_chunk_size, remaining)))
	input.close()
	output.close()
	return {"ok": true}

func _audio_file_duration(filesystem_path: String) -> float:
	var stream: AudioStreamOggVorbis = AudioStreamOggVorbis.load_from_file(filesystem_path)
	if stream == null:
		return 1.0
	return maxf(1.0, stream.get_length())

func _sanitize_song_id(value: String) -> String:
	var output := ""
	var last_separator := false
	for character in value.to_lower():
		var code: int = character.unicode_at(0)
		var is_alnum: bool = (code >= 97 and code <= 122) or (code >= 48 and code <= 57)
		if is_alnum:
			output += character
			last_separator = false
		elif not last_separator and not output.is_empty():
			output += "_"
			last_separator = true
	return output.trim_suffix("_")

func _unique_import_song_id(base_id: String) -> String:
	var candidate := base_id
	var suffix := 2
	while songs.has(candidate) or DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(IMPORTED_CHART_ROOT.path_join(candidate))):
		candidate = "%s_%d" % [base_id, suffix]
		suffix += 1
	return candidate

func _reload_after_import(song_id: String) -> void:
	_load_catalog()
	_selection_guard = true
	_populate_song_select()
	var index: int = songs.find(song_id)
	if index >= 0:
		song_select.select(index)
	_selection_guard = false
	_refresh_difficulties()
	_update_selected_audio_path()
	_refresh_tempo_controls()
	load_selected_chart()

func _selected_audio_source() -> String:
	if song_select.selected < 0 or song_select.selected >= songs.size():
		return ""
	var song_id: String = songs[song_select.selected]
	var override_path: String = str(_analysis_source_overrides.get(song_id, ""))
	if not override_path.is_empty():
		if FileAccess.file_exists(_filesystem_path(override_path)) and _is_supported_analysis_source(override_path):
			return override_path
		_analysis_source_overrides.erase(song_id)
	return ""

func _find_any_chart_for_song(song_id: String) -> Dictionary:
	for data in charts:
		if str(data.get("song_id", data.get("id", ""))) == song_id:
			return data
	return {}

func _update_selected_audio_path() -> void:
	var gameplay_source: String = _selected_gameplay_audio_source()
	var gameplay_filesystem: String = _filesystem_path(gameplay_source)
	gameplay_path.text = gameplay_source if not gameplay_source.is_empty() else "No OGG imported"
	gameplay_path.tooltip_text = "Gameplay audio: %s" % gameplay_filesystem
	var selected_path: String = _selected_audio_source()
	audio_path.text = selected_path if not selected_path.is_empty() else "No FLAC/WAV selected"
	var source_display := _filesystem_path(selected_path) if not selected_path.is_empty() else "not selected"
	if _developer_generator_enabled():
		audio_path.tooltip_text = "Developer analysis source: %s\nFLAC/WAV can feed waveform analysis and automatic chart generation. Gameplay remains OGG." % source_display
	else:
		audio_path.tooltip_text = "Waveform source: %s\nFLAC/WAV is used only to build the editor waveform. Gameplay remains OGG." % source_display

func _filesystem_path(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return ProjectSettings.globalize_path(path)
	return path

func _allin1_cache_path(source_path: String, song_id: String) -> String:
	var cache_dir: String = ProjectSettings.globalize_path("user://allin1_analysis")
	if not DirAccess.dir_exists_absolute(cache_dir):
		DirAccess.make_dir_recursive_absolute(cache_dir)
	return cache_dir.path_join("analysis_%d.json" % abs((song_id + "|" + source_path).hash()))

func _save_cached_allin1(source_path: String, song_id: String, analysis: Dictionary) -> void:
	if source_path.is_empty() or song_id.is_empty():
		return
	var payload: Dictionary = analysis.duplicate(true)
	payload["_source_modified"] = FileAccess.get_modified_time(source_path)
	var file: FileAccess = FileAccess.open(_allin1_cache_path(source_path, song_id), FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(payload, "\t", false))
	file.close()

func _load_cached_allin1(source_path: String, song_id: String) -> Dictionary:
	var path: String = _allin1_cache_path(source_path, song_id)
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return {}
	var cached: Dictionary = parsed as Dictionary
	if not bool(cached.get("ok", false)) or int(cached.get("_source_modified", -1)) != int(FileAccess.get_modified_time(source_path)):
		return {}
	cached.erase("_source_modified")
	return cached

func _run_allin1_analysis(source_path: String, song_id: String, cache_source_path: String = "") -> Dictionary:
	var cache_identity: String = cache_source_path if not cache_source_path.is_empty() else source_path
	var cached: Dictionary = _load_cached_allin1(cache_identity, song_id)
	if not cached.is_empty():
		_set_generator_progress(42.0, "ANALYSIS CACHE", song_id)
		return cached
	var bridge_path: String = _bridge_filesystem_path()
	if not FileAccess.file_exists(bridge_path):
		return {"ok": false, "error": "Missing tools/allin1_bridge.py in the project."}
	var runner_result: Dictionary = await _resolve_allin1_runner(bridge_path)
	if not bool(runner_result.get("ok", false)):
		return runner_result
	var cache_dir: String = ProjectSettings.globalize_path("user://allin1_analysis")
	if not DirAccess.dir_exists_absolute(cache_dir):
		var mkdir_error: Error = DirAccess.make_dir_recursive_absolute(cache_dir)
		if mkdir_error != OK:
			return {"ok": false, "error": "Could not create All-In-One cache directory."}
	var output_path: String = _allin1_cache_path(cache_identity, song_id)
	var progress_path: String = ProjectSettings.globalize_path("user://allin1_analysis/progress_%d.json" % abs((song_id + cache_identity).hash()))
	# Never let an old failed result masquerade as the current process output.
	if FileAccess.file_exists(output_path):
		DirAccess.remove_absolute(output_path)
	if FileAccess.file_exists(progress_path):
		DirAccess.remove_absolute(progress_path)
	var args: PackedStringArray = _runner_args(_allin1_runner, PackedStringArray([
		bridge_path,
		"--analyze", source_path,
		"--output", output_path,
		"--progress", progress_path,
		"--device", "auto",
		"--model", ALLIN1_MODEL,
	]))
	var process_result: Dictionary = await _run_process_with_progress(str(_allin1_runner.get("command", "")), args, progress_path, song_id)
	if FileAccess.file_exists(progress_path):
		DirAccess.remove_absolute(progress_path)
	if bool(process_result.get("timed_out", false)):
		return {"ok": false, "error": str(process_result.get("output", "Advanced analysis timed out."))}
	if int(process_result.get("exit_code", -1)) != 0:
		var detail: String = _read_allin1_error_file(output_path)
		if detail.is_empty():
			detail = str(process_result.get("output", "All-In-One process failed."))
		return {"ok": false, "error": detail.strip_edges()}
	if not FileAccess.file_exists(output_path):
		return {"ok": false, "error": "All-In-One finished but did not produce analysis JSON."}
	var file: FileAccess = FileAccess.open(output_path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Could not read All-In-One analysis JSON."}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		return {"ok": false, "error": "All-In-One bridge output is not valid JSON."}
	var result: Dictionary = parsed as Dictionary
	if not bool(result.get("ok", false)):
		return {"ok": false, "error": str(result.get("error", "All-In-One analysis failed."))}
	_save_cached_allin1(cache_identity, song_id, result)
	return result

func _bridge_filesystem_path() -> String:
	return _materialize_python_tool(ALLIN1_BRIDGE_PATH, "allin1_bridge.py")

func _materialize_python_tool(resource_path: String, filename: String) -> String:
	# External Python cannot execute scripts that only exist inside an exported
	# PCK. Materialize bundled tools into user:// for editor/export parity.
	var bundled_text: String = FileAccess.get_file_as_string(resource_path)
	if bundled_text.is_empty():
		var direct_path: String = ProjectSettings.globalize_path(resource_path)
		return direct_path if FileAccess.file_exists(direct_path) else ""
	var tools_dir: String = ProjectSettings.globalize_path("user://chart_studio_tools")
	var mkdir_error: Error = DirAccess.make_dir_recursive_absolute(tools_dir)
	if mkdir_error != OK and not DirAccess.dir_exists_absolute(tools_dir):
		return ""
	var output_path: String = tools_dir.path_join(filename)
	var current_text: String = FileAccess.get_file_as_string(output_path) if FileAccess.file_exists(output_path) else ""
	if current_text != bundled_text:
		var output: FileAccess = FileAccess.open(output_path, FileAccess.WRITE)
		if output == null:
			return ""
		output.store_string(bundled_text)
		output.close()
	return output_path

func _resolve_audio_runner(bridge_path: String) -> Dictionary:
	if not _audio_runner.is_empty():
		return {"ok": true}
	if not _allin1_runner.is_empty():
		_audio_runner = _allin1_runner.duplicate(true)
		return {"ok": true}
	var candidates: Array = []
	if OS.get_name() == "Windows":
		candidates.append({"command": "py", "prefix": PackedStringArray(["-3"])})
		candidates.append({"command": "python", "prefix": PackedStringArray()})
		candidates.append({"command": "python3", "prefix": PackedStringArray()})
	else:
		candidates.append({"command": "python3", "prefix": PackedStringArray()})
		candidates.append({"command": "python", "prefix": PackedStringArray()})
	var probe_errors: PackedStringArray = PackedStringArray()
	for raw_candidate in candidates:
		var candidate: Dictionary = raw_candidate as Dictionary
		var args: PackedStringArray = _runner_args(candidate, PackedStringArray([bridge_path, "--probe-audio"]))
		var process_result: Dictionary = await _run_process_async(str(candidate.get("command", "")), args)
		if int(process_result.get("exit_code", -1)) == 0:
			_audio_runner = candidate.duplicate(true)
			return {"ok": true}
		var output: String = str(process_result.get("output", "")).strip_edges()
		if not output.is_empty():
			probe_errors.append(output.get_slice("\n", 0))
	return {
		"ok": false,
		"error": "Ogg Vorbis conversion is unavailable. Run tools/install_allin1_windows.bat, then try again. %s" % " | ".join(probe_errors),
	}

func _resolve_allin1_runner(bridge_path: String) -> Dictionary:
	if not _allin1_runner.is_empty():
		return {"ok": true}
	var candidates: Array = []
	if OS.get_name() == "Windows":
		candidates.append({"command": "py", "prefix": PackedStringArray(["-3"])})
		candidates.append({"command": "python", "prefix": PackedStringArray()})
		candidates.append({"command": "python3", "prefix": PackedStringArray()})
	else:
		candidates.append({"command": "python3", "prefix": PackedStringArray()})
		candidates.append({"command": "python", "prefix": PackedStringArray()})
	var probe_errors: PackedStringArray = PackedStringArray()
	for raw_candidate in candidates:
		var candidate: Dictionary = raw_candidate as Dictionary
		var args: PackedStringArray = _runner_args(candidate, PackedStringArray([bridge_path, "--probe"]))
		var process_result: Dictionary = await _run_process_async(str(candidate.get("command", "")), args)
		if int(process_result.get("exit_code", -1)) == 0:
			_allin1_runner = candidate.duplicate(true)
			return {"ok": true}
		var output: String = str(process_result.get("output", "")).strip_edges()
		if not output.is_empty():
			probe_errors.append(output.get_slice("\n", 0))
	var setup_file: String = "tools/install_allin1_windows.bat" if OS.get_name() == "Windows" else "tools/install_allin1_linux_macos.sh"
	return {
		"ok": false,
		"error": "All-In-One-Infer is not available in any detected Python. Run %s, then run analysis again. Requires Python 3.9+. %s" % [setup_file, " | ".join(probe_errors)],
	}

func _runner_args(runner: Dictionary, tail: PackedStringArray) -> PackedStringArray:
	var args: PackedStringArray = PackedStringArray()
	var prefix_value: Variant = runner.get("prefix", PackedStringArray())
	if prefix_value is PackedStringArray:
		var prefix: PackedStringArray = prefix_value as PackedStringArray
		for value in prefix:
			args.append(value)
	for value in tail:
		args.append(value)
	return args

func _run_process_async(command: String, args: PackedStringArray) -> Dictionary:
	if command.is_empty():
		return {"exit_code": -1, "output": "Missing executable command."}
	var thread: Thread = Thread.new()
	var start_error: Error = thread.start(_execute_process_worker.bind(command, args))
	if start_error != OK:
		return {"exit_code": -1, "output": "Could not start external analysis thread."}
	while thread.is_alive():
		await get_tree().process_frame
	var result: Variant = thread.wait_to_finish()
	if result is Dictionary:
		return result as Dictionary
	return {"exit_code": -1, "output": "External analysis returned no result."}

func _run_process_with_progress(command: String, args: PackedStringArray, progress_path: String, song_id: String) -> Dictionary:
	if command.is_empty():
		return {"exit_code": -1, "output": "Missing executable command."}
	# The bridge writes its result/progress to files, so a managed child process
	# is safer than a blocking OS.execute thread: it can be timed out and killed.
	var process_id: int = OS.create_process(command, args, false)
	if process_id <= 0:
		return {"exit_code": -1, "output": "Could not start advanced analysis process."}
	var last_update := 0
	var started_ms: int = Time.get_ticks_msec()
	var last_device: String = ""
	while OS.is_process_running(process_id):
		var now: int = Time.get_ticks_msec()
		if now - last_update >= 250:
			last_update = now
			var live: Variant = JSON.parse_string(FileAccess.get_file_as_string(progress_path)) if FileAccess.file_exists(progress_path) else null
			if live is Dictionary:
				var phase: String = str((live as Dictionary).get("phase", "ANALYZING"))
				var detail: String = str((live as Dictionary).get("detail", song_id))
				var elapsed: int = maxi(0, int((live as Dictionary).get("elapsed_seconds", 0)))
				last_device = str((live as Dictionary).get("device", last_device)).to_lower()
				var budget: int = ALLIN1_CPU_TIMEOUT_SECONDS if last_device == "cpu" else ALLIN1_TOTAL_TIMEOUT_SECONDS
				var live_percent: float = minf(41.0, 9.0 + 31.0 * float(elapsed) / float(maxi(1, budget)))
				_set_generator_progress(live_percent, phase, "%s • %ds" % [detail, elapsed])
				_set_status("%s • %s • %ds/%ds" % [phase, detail, elapsed, budget], SPACE)
		var wall_elapsed: int = int((now - started_ms) / 1000)
		var timeout_seconds: int = ALLIN1_CPU_TIMEOUT_SECONDS if last_device == "cpu" else ALLIN1_TOTAL_TIMEOUT_SECONDS
		if wall_elapsed >= timeout_seconds:
			OS.kill(process_id)
			return {
				"exit_code": -1,
				"timed_out": true,
				"output": "Advanced analysis exceeded %ds on %s; switched to the local balanced generator." % [timeout_seconds, (last_device.to_upper() if not last_device.is_empty() else "UNKNOWN DEVICE")],
			}
		await get_tree().process_frame
	return {"exit_code": 0, "output": ""}

func _run_local_wav_analysis(source_path: String, song_id: String, progress_context: Dictionary) -> Dictionary:
	var thread := Thread.new()
	var start_error: Error = thread.start(_analyze_wav_worker.bind(source_path))
	if start_error != OK:
		return {"ok": false, "error": "Could not start local audio analysis."}
	var started_ms: int = Time.get_ticks_msec()
	while thread.is_alive():
		var elapsed: int = int((Time.get_ticks_msec() - started_ms) / 1000)
		_update_chart_stage_progress(progress_context, song_id, "LOCAL BEAT ANALYSIS", minf(0.15, 0.05 + float(elapsed) * 0.008))
		await get_tree().process_frame
	var result: Variant = thread.wait_to_finish()
	if result is Dictionary:
		return result as Dictionary
	return {"ok": false, "error": "Local audio analysis returned no result."}

func _analyze_wav_worker(source_path: String) -> Dictionary:
	var analyzer := WavAutoAnalyzer.new()
	return analyzer.analyze_wav(source_path)

func _execute_process_worker(command: String, args: PackedStringArray) -> Dictionary:
	var output: Array = []
	var exit_code: int = OS.execute(command, args, output, true, false)
	var lines: PackedStringArray = PackedStringArray()
	for raw_line in output:
		lines.append(str(raw_line))
	return {"exit_code": exit_code, "output": "\n".join(lines)}

func _read_allin1_error_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		return str((parsed as Dictionary).get("error", ""))
	return ""

func _as_array(value: Variant) -> Array:
	if value is Array:
		return value as Array
	return []

func _write_chart_dictionary(resource_path: String, data: Dictionary) -> bool:
	var output_path: String = ProjectSettings.globalize_path(resource_path)
	var file: FileAccess = FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t", false))
	file.close()
	return true

func _load_catalog() -> void:
	charts.clear()
	songs.clear()
	for raw_data in catalog_loader.load_all(true):
		if not (raw_data is Dictionary):
			continue
		var data: Dictionary = (raw_data as Dictionary).duplicate(true)
		data["_path"] = str(data.get("_catalog_path", ""))
		charts.append(data)
		var song_id := str(data.get("song_id", data.get("id", "")))
		if not song_id.is_empty() and not songs.has(song_id):
			songs.append(song_id)
	songs.sort()

func _populate_song_select() -> void:
	song_select.clear()
	for song_id in songs:
		var representative := _find_chart(song_id, "normal")
		var title: String = str(representative.get("title", song_id)).to_upper()
		var artist: String = str(representative.get("artist", "")).strip_edges()
		var label: String = title if artist.is_empty() or artist == "Unknown Artist" else "%s  —  %s" % [title, artist]
		song_select.add_item(label)
		song_select.set_item_metadata(song_select.item_count - 1, song_id)

func _populate_snap_select() -> void:
	snap_select.clear()
	snap_select.add_item("1/4", 1)
	snap_select.add_item("1/8", 2)
	snap_select.add_item("1/16", 4)
	snap_select.select(1)

func _populate_tempo_mode_select() -> void:
	tempo_mode_select.clear()
	var labels := ["AUTO", "½×", "1×", "2×", "CUSTOM"]
	var values := ["auto", "half", "original", "double", "custom"]
	for i in range(labels.size()):
		tempo_mode_select.add_item(labels[i])
		tempo_mode_select.set_item_metadata(i, values[i])
	tempo_mode_select.select(0)
	tempo_mode_select.tooltip_text = "Developer generator tempo mode. AUTO resolves half/double BPM from audio."
	tempo_bpm_input.tooltip_text = "Chart BPM (40–300). Player builds edit the active chart directly; developer mode can use generator tempo modes."

func _selected_song_id() -> String:
	if song_select.selected < 0 or song_select.selected >= songs.size():
		return ""
	return songs[song_select.selected]

func _selected_tempo_mode() -> String:
	if tempo_mode_select.selected >= 0:
		return str(tempo_mode_select.get_item_metadata(tempo_mode_select.selected))
	return "auto"

func _refresh_tempo_controls() -> void:
	var song_id := _selected_song_id()
	if not _developer_generator_enabled():
		var source_chart: Dictionary = current_chart if not current_chart.is_empty() and str(current_chart.get("song_id", current_chart.get("id", ""))) == song_id else _find_any_chart_for_song(song_id)
		var display_bpm: float = clampf(float(source_chart.get("bpm", 120.0)), 40.0, 300.0) if not source_chart.is_empty() else 120.0
		tempo_bpm_input.text = "%.2f" % display_bpm
		tempo_bpm_input.editable = not current_chart.is_empty()
		tempo_bpm_input.modulate = Color.WHITE if tempo_bpm_input.editable else Color(1.0, 1.0, 1.0, 0.62)
		return
	var mode: String = str(_tempo_mode_overrides.get(song_id, "auto"))
	for i in range(tempo_mode_select.item_count):
		if str(tempo_mode_select.get_item_metadata(i)) == mode:
			tempo_mode_select.select(i)
			break
	var representative: Dictionary = _find_any_chart_for_song(song_id)
	var display_bpm: float = float(_tempo_custom_bpm.get(song_id, representative.get("bpm", 120.0)))
	tempo_bpm_input.text = "%.2f" % display_bpm
	tempo_bpm_input.editable = mode == "custom"
	tempo_bpm_input.modulate = Color.WHITE if tempo_bpm_input.editable else Color(1.0, 1.0, 1.0, 0.62)

func _on_tempo_mode_changed(_index: int) -> void:
	if not _developer_generator_enabled():
		return
	var song_id := _selected_song_id()
	if song_id.is_empty():
		return
	var mode := _selected_tempo_mode()
	_tempo_mode_overrides[song_id] = mode
	if mode == "custom" and not _tempo_custom_bpm.has(song_id):
		var representative: Dictionary = _find_any_chart_for_song(song_id)
		_tempo_custom_bpm[song_id] = clampf(float(representative.get("bpm", 120.0)), 40.0, 300.0)
	_refresh_tempo_controls()
	_set_status("Tempo mode: %s. Generate the selected song to apply it to all three levels." % tempo_mode_select.get_item_text(tempo_mode_select.selected), SPACE)

func _on_tempo_bpm_submitted(_value: String) -> void:
	_commit_tempo_bpm()
	tempo_bpm_input.release_focus()

func _commit_tempo_bpm() -> void:
	var value_text := tempo_bpm_input.text.strip_edges()
	if not value_text.is_valid_float():
		_refresh_tempo_controls()
		_set_status("BPM must be a number from 40 to 300.", DANGER)
		return
	var bpm := clampf(value_text.to_float(), 40.0, 300.0)
	if not _developer_generator_enabled():
		if current_chart.is_empty():
			_set_status("Load a chart before changing BPM.", DANGER)
			return
		current_chart["bpm"] = bpm
		tempo_bpm_input.text = "%.2f" % bpm
		_sync_timeline_grid()
		_mark_dirty("Chart BPM set to %.2f" % bpm)
		return
	if _selected_tempo_mode() != "custom":
		return
	var song_id := _selected_song_id()
	if song_id.is_empty():
		return
	_tempo_custom_bpm[song_id] = bpm
	tempo_bpm_input.text = "%.2f" % bpm
	_set_status("Custom tempo set to %.2f BPM. Generate the selected song to rebuild its chart grid." % bpm, GREEN)

func _tempo_multiplier_label(multiplier: float) -> String:
	if absf(multiplier - 2.0) <= 0.05:
		return "2×"
	if absf(multiplier - 0.5) <= 0.05:
		return "½×"
	return "%.2f×" % multiplier

func _refresh_difficulties() -> void:
	_selection_guard = true
	difficulty_select.clear()
	if song_select.selected < 0 or song_select.selected >= songs.size():
		_selection_guard = false
		return
	var song_id := songs[song_select.selected]
	for diff in ["normal", "hard", "master"]:
		var chart := _find_chart(song_id, diff)
		if chart.is_empty():
			continue
		difficulty_select.add_item("%s  %d★" % [str(chart.get("difficulty", diff)).to_upper(), int(chart.get("star_rating", 1))])
		difficulty_select.set_item_metadata(difficulty_select.item_count - 1, diff)
	if difficulty_select.item_count > 0:
		difficulty_select.select(0)
	_selection_guard = false

func _find_chart(song_id: String, difficulty_id: String) -> Dictionary:
	for data in charts:
		if str(data.get("song_id", data.get("id", ""))) == song_id and str(data.get("chart_difficulty", "")).to_lower() == difficulty_id:
			return data
	return {}

func load_selected_chart() -> void:
	_set_review_visible(true)
	if song_select.selected < 0 or difficulty_select.selected < 0:
		return
	var song_id := songs[song_select.selected]
	var difficulty_id := str(difficulty_select.get_item_metadata(difficulty_select.selected))
	var catalog_entry := _find_chart(song_id, difficulty_id)
	if catalog_entry.is_empty():
		return
	current_path = str(catalog_entry.get("_path", ""))
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(current_path))
	if not (parsed is Dictionary):
		_set_status("Could not parse %s" % current_path, DANGER)
		return
	current_chart = parsed
	events = current_chart.get("events", []).duplicate(true)
	space_events.clear()
	for value in current_chart.get("space_events", []):
		if value is float or value is int:
			space_events.append(float(value))
	_sort_data()
	dirty = false
	editor_time = 0.0
	var recovered_autosave: bool = _restore_autosave_if_available()
	undo_stack.clear()
	redo_stack.clear()
	_update_history_buttons()
	_load_audio()
	_refresh_view()
	_refresh_tempo_controls()
	if recovered_autosave:
		_set_status("RECOVERED AUTOSAVE · review and SAVE CHART to keep it", SPACE)
	else:
		_set_status("%s chart ready. Click the timeline to seek." % str(current_chart.get("difficulty", "CHART")).capitalize(), GREEN)

func _load_audio() -> void:
	music.stop()
	var chart_audio_path := str(current_chart.get("audio", ""))
	var stream = _load_audio_stream(chart_audio_path)
	if stream == null:
		_set_status("Missing audio: %s" % chart_audio_path, DANGER)
		return
	music.stream = stream
	music.play(0.0)
	music.stream_paused = true
	play_button.text = "PLAY"

func _load_audio_stream(path: String) -> AudioStream:
	if path.is_empty():
		return null
	if path.begins_with("res://"):
		var imported_stream: AudioStream = load(path) as AudioStream
		if imported_stream != null:
			return imported_stream
	var filesystem_path := ProjectSettings.globalize_path(path) if path.begins_with("user://") else path
	if path.begins_with("res://"):
		filesystem_path = ProjectSettings.globalize_path(path)
	match filesystem_path.get_extension().to_lower():
		"ogg": return AudioStreamOggVorbis.load_from_file(filesystem_path)
		"mp3": return AudioStreamMP3.load_from_file(filesystem_path)
		"wav": return AudioStreamWAV.load_from_file(filesystem_path)
	return null

func _process(_delta: float) -> void:
	if music.playing and not music.stream_paused:
		editor_time = _music_time()
		if editor_time >= float(current_chart.get("duration", 0.0)):
			music.stream_paused = true
			play_button.text = "PLAY"
	if dirty and Time.get_ticks_msec() - _last_autosave_ms >= AUTOSAVE_INTERVAL_MS:
		_write_autosave()
	_refresh_time_only()

func _music_time() -> float:
	if music == null or not music.playing:
		return editor_time
	return clampf(music.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency(), 0.0, float(current_chart.get("duration", 0.0)))

func toggle_play() -> void:
	if music.stream == null:
		return
	if not music.playing:
		music.play(editor_time)
		music.stream_paused = false
		play_button.text = "PAUSE"
		return
	music.stream_paused = not music.stream_paused
	play_button.text = "PLAY" if music.stream_paused else "PAUSE"

func seek_relative(amount: float) -> void:
	seek_to(editor_time + amount)

func seek_to(value: float) -> void:
	var duration := float(current_chart.get("duration", 0.0))
	editor_time = clampf(value, 0.0, duration)
	if music.playing:
		music.seek(editor_time)
	_refresh_time_only()

func add_event(kind: String) -> void:
	if current_chart.is_empty():
		return
	var t: float = _snap_time(_edit_time())
	_push_undo_snapshot()
	_remove_at_time(t, 0.018, true, true)
	events.append({"time": t, "type": kind, "manual": true})
	_sort_data()
	_mark_dirty("Added %s @ %.3f" % [kind.to_upper(), t])

func add_space_event() -> void:
	if current_chart.is_empty():
		return
	var t: float = _snap_time(_edit_time())
	_push_undo_snapshot()
	_remove_at_time(t, 0.018, true, true)
	space_events.append(t)
	_sort_data()
	_mark_dirty("Added SPACE @ %.3f" % t)

func delete_nearest() -> void:
	if current_chart.is_empty():
		return
	var t := _edit_time()
	var best_kind := ""
	var best_index := -1
	var best_distance := INF
	for i in range(events.size()):
		var raw = events[i]
		if not (raw is Dictionary):
			continue
		var d := absf(float(raw.get("time", 0.0)) - t)
		if d < best_distance:
			best_distance = d
			best_index = i
			best_kind = "event"
	for i in range(space_events.size()):
		var d := absf(space_events[i] - t)
		if d < best_distance:
			best_distance = d
			best_index = i
			best_kind = "space"
	var threshold := maxf(delete_radius, _snap_step() * 0.48)
	if best_index < 0 or best_distance > threshold:
		_set_status("Nothing close enough to delete", MUTED)
		return
	_push_undo_snapshot()
	if best_kind == "space":
		space_events.remove_at(best_index)
	else:
		events.remove_at(best_index)
	_mark_dirty("Deleted nearest event")

func _remove_at_time(t: float, epsilon: float, remove_notes: bool, remove_space: bool) -> void:
	if remove_notes:
		for i in range(events.size() - 1, -1, -1):
			var raw = events[i]
			if raw is Dictionary and absf(float(raw.get("time", 0.0)) - t) <= epsilon:
				events.remove_at(i)
	if remove_space:
		for i in range(space_events.size() - 1, -1, -1):
			if absf(space_events[i] - t) <= epsilon:
				space_events.remove_at(i)

func _snap_time(t: float) -> float:
	if not snap_toggle.button_pressed:
		return snappedf(t, 0.001)
	var offset: float = float(current_chart.get("beat_offset", 0.0))
	var step: float = _snap_step()
	var result: float = offset + roundf((t - offset) / step) * step
	return snappedf(maxf(0.0, result), 0.000001)

func _snap_step() -> float:
	var bpm := maxf(1.0, float(current_chart.get("bpm", 120.0)))
	var subdivisions := 2
	if snap_select.selected >= 0:
		subdivisions = int(snap_select.get_item_id(snap_select.selected))
	return (60.0 / bpm) / maxf(1.0, float(subdivisions))

func _edit_time() -> float:
	return _music_time() if music.playing and not music.stream_paused else editor_time

func _sort_data() -> void:
	events.sort_custom(_event_sort)
	space_events.sort()

func _event_sort(a: Dictionary, b: Dictionary) -> bool:
	return float(a.get("time", 0.0)) < float(b.get("time", 0.0))

func _mark_dirty(message: String) -> void:
	dirty = true
	_update_history_buttons()
	_refresh_view()
	_set_status(message + "  •  UNSAVED", SPACE)

func _autosave_path() -> String:
	if current_chart.is_empty():
		return ""
	var song_id: String = LevelPackScript.sanitize_id(str(current_chart.get("song_id", current_chart.get("id", "song"))))
	var difficulty_id: String = LevelPackScript.sanitize_id(str(current_chart.get("chart_difficulty", current_chart.get("difficulty", "chart"))).to_lower())
	if song_id.is_empty() or difficulty_id.is_empty():
		return ""
	return "%s/%s_%s.json" % [AUTOSAVE_ROOT, song_id, difficulty_id]

func _write_autosave() -> bool:
	if not dirty or current_chart.is_empty():
		return false
	var path: String = _autosave_path()
	if path.is_empty():
		return false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(AUTOSAVE_ROOT))
	_fill_missing_authored_directions()
	var chart: Dictionary = current_chart.duplicate(true)
	chart["events"] = events.duplicate(true)
	chart["space_events"] = space_events.duplicate()
	var payload: Dictionary = {
		"schema_version": 1,
		"app_version": str(ProjectSettings.get_setting("application/config/version", "unknown")),
		"saved_unix": int(Time.get_unix_time_from_system()),
		"source_path": current_path,
		"editor_time": editor_time,
		"chart": chart,
	}
	var saved: bool = preload("res://scripts/reliable_json_store.gd").save_dictionary_atomic(path, payload)
	if saved:
		_last_autosave_ms = Time.get_ticks_msec()
	return saved

func _restore_autosave_if_available() -> bool:
	var path: String = _autosave_path()
	if path.is_empty() or not FileAccess.file_exists(path):
		return false
	var loaded: Dictionary = preload("res://scripts/reliable_json_store.gd").load_dictionary(path)
	var payload_value: Variant = loaded.get("data", {})
	if not (payload_value is Dictionary):
		return false
	var payload: Dictionary = payload_value as Dictionary
	if str(payload.get("source_path", "")) != current_path:
		return false
	var chart_value: Variant = payload.get("chart", {})
	if not (chart_value is Dictionary):
		return false
	var recovered: Dictionary = (chart_value as Dictionary).duplicate(true)
	var validation: Dictionary = preload("res://scripts/chart_integrity.gd").validate_structure(recovered)
	if not bool(validation.get("ok", false)):
		return false
	current_chart = recovered
	events = current_chart.get("events", []).duplicate(true)
	space_events.clear()
	for value: Variant in current_chart.get("space_events", []):
		if value is int or value is float:
			space_events.append(float(value))
	editor_time = clampf(float(payload.get("editor_time", 0.0)), 0.0, float(current_chart.get("duration", 0.0)))
	dirty = true
	_sort_data()
	_last_autosave_ms = Time.get_ticks_msec()
	return true

func _discard_autosave() -> void:
	var path: String = _autosave_path()
	for candidate: String in [path, path + ".bak", path + ".tmp", path + ".corrupt"]:
		if not candidate.is_empty() and FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))

func _refresh_view() -> void:
	var title := str(current_chart.get("title", "CHART"))
	var diff := str(current_chart.get("difficulty", ""))
	var stars := int(current_chart.get("star_rating", 1))
	song_title.text = title
	chart_info.text = "%s  %d★   •   %d BPM   •   %d notes   •   %d beat strikes" % [diff, stars, int(round(float(current_chart.get("bpm", 120.0)))), events.size(), space_events.size()]
	dirty_label.text = "UNSAVED" if dirty else "SAVED"
	dirty_label.add_theme_color_override("font_color", SPACE if dirty else GREEN)
	var duration := float(current_chart.get("duration", 1.0))
	timeline.set_chart(events, space_events, float(current_chart.get("bpm", 120.0)), float(current_chart.get("beat_offset", 0.0)), duration)
	waveform.set_view_window(timeline.window_seconds, timeline.playhead_ratio)
	var waveform_value: Variant = current_chart.get("editor_waveform", {})
	if waveform_value is Dictionary:
		var waveform_data := waveform_value as Dictionary
		waveform.set_waveform(waveform_data.get("peaks", []), duration, str(waveform_data.get("source", "PCM AUDIO WAVEFORM  ·  12 SEC WINDOW")))
	else:
		waveform.clear_waveform(duration)
	_refresh_time_only()

func _refresh_time_only() -> void:
	var duration := float(current_chart.get("duration", 0.0))
	time_label.text = "%s / %s" % [_format_time(editor_time), _format_time(duration)]
	timeline.set_time(editor_time)
	waveform.set_time(editor_time)

func _format_time(seconds: float) -> String:
	var total_ms := maxi(0, int(round(seconds * 1000.0)))
	var minutes := floori(float(total_ms) / 60000.0)
	var secs := floori(float(total_ms) / 1000.0) % 60
	var millis := total_ms % 1000
	return "%02d:%02d.%03d" % [minutes, secs, millis]

func save_chart() -> void:
	if current_chart.is_empty() or current_path.is_empty():
		return
	_sort_data()
	_fill_missing_authored_directions()
	current_chart["events"] = events
	current_chart["runtime_directions"] = false
	current_chart["authored_directions"] = true
	current_chart["space_events"] = space_events
	current_chart["special_note_counts"] = {
		"reverse": _count_kind("reverse"),
	}
	var profile_value: Variant = current_chart.get("difficulty_profile", {})
	var profile: Dictionary = {}
	if profile_value is Dictionary:
		profile = (profile_value as Dictionary).duplicate(true)
	profile["note_count"] = events.size()
	profile["reverse_count"] = _count_kind("reverse")
	profile["space_count"] = space_events.size()
	profile["authored_direction_patterns"] = true
	current_chart["difficulty_profile"] = profile
	current_chart["recommended"] = "%s • %d★ • %d notes • %d Beat Strikes" % [
		str(current_chart.get("difficulty", "CHART")), int(current_chart.get("star_rating", 1)), events.size(), space_events.size()
	]
	var import_value: Variant = current_chart.get("import_meta", {})
	if import_value is Dictionary:
		var import_meta: Dictionary = (import_value as Dictionary).duplicate(true)
		var import_state := str(import_meta.get("state", ""))
		if import_state == "manual_draft" or import_state == "imported_not_generated":
			import_meta["state"] = "manual"
			import_meta["manual_saved_at"] = Time.get_datetime_string_from_system()
			current_chart["import_meta"] = import_meta
	var json_text := JSON.stringify(current_chart, "\t", false)
	# First try the real project file. This succeeds when running the project from
	# the Godot editor / unpacked project. Exported PCK builds are read-only, so
	# they transparently fall back to user://chart_exports/.
	var output_path := ProjectSettings.globalize_path(current_path)
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://chart_exports"))
		output_path = ProjectSettings.globalize_path("user://chart_exports/%s_%s.json" % [str(current_chart.get("song_id", "song")), str(current_chart.get("chart_difficulty", "chart"))])
		file = FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		_set_status("SAVE FAILED: %s" % output_path, DANGER)
		return
	file.store_string(json_text)
	file.flush()
	file.close()
	dirty = false
	_discard_autosave()
	undo_stack.clear()
	redo_stack.clear()
	_update_history_buttons()
	_refresh_view()
	_set_status("Chart saved • %s" % output_path.get_file(), GREEN)

func _push_undo_snapshot() -> void:
	undo_stack.append(_make_snapshot())
	if undo_stack.size() > HISTORY_LIMIT:
		undo_stack.pop_front()
	redo_stack.clear()
	_update_history_buttons()

func _make_snapshot() -> Dictionary:
	return {
		"events": events.duplicate(true),
		"space_events": space_events.duplicate(),
		"editor_time": editor_time,
		"dirty": dirty,
	}

func _restore_snapshot(snapshot: Dictionary) -> void:
	events = (snapshot.get("events", []) as Array).duplicate(true)
	space_events.clear()
	for value in snapshot.get("space_events", []):
		space_events.append(float(value))
	editor_time = float(snapshot.get("editor_time", editor_time))
	dirty = bool(snapshot.get("dirty", true))
	_sort_data()
	if music.playing:
		music.seek(editor_time)
	_refresh_view()

func undo_edit() -> void:
	if undo_stack.is_empty():
		_set_status("Nothing to undo.", MUTED)
		return
	redo_stack.append(_make_snapshot())
	_restore_snapshot(undo_stack.pop_back())
	_update_history_buttons()
	_set_status("Undo complete.  •  %d step%s remaining" % [undo_stack.size(), "" if undo_stack.size() == 1 else "s"], NORMAL)

func redo_edit() -> void:
	if redo_stack.is_empty():
		_set_status("Nothing to redo.", MUTED)
		return
	undo_stack.append(_make_snapshot())
	_restore_snapshot(redo_stack.pop_back())
	_update_history_buttons()
	_set_status("Redo complete.", NORMAL)

func _update_history_buttons() -> void:
	if undo_button == null or redo_button == null:
		return
	undo_button.disabled = undo_stack.is_empty()
	redo_button.disabled = redo_stack.is_empty()

func _fill_missing_authored_directions() -> void:
	var motif: Array[int] = [1, 2, 3, 6, 9, 8, 7, 4]
	var bpm: float = maxf(1.0, float(current_chart.get("bpm", 120.0)))
	var beat: float = 60.0 / bpm
	var offset: float = float(current_chart.get("beat_offset", 0.0))
	var last_direction: int = -1
	for i in range(events.size()):
		var raw_event: Variant = events[i]
		if not (raw_event is Dictionary):
			continue
		var event: Dictionary = raw_event as Dictionary
		var existing: int = int(event.get("direction", 0))
		if existing in [1, 2, 3, 4, 6, 7, 8, 9]:
			last_direction = existing
			continue
		var time: float = float(event.get("time", 0.0))
		var beat_index: int = maxi(0, int(roundf((time - offset) / beat)))
		var phrase_index: int = floori(float(beat_index) / 16.0)
		var motif_index: int = posmod(i + phrase_index * 3, motif.size())
		var direction: int = motif[motif_index]
		if direction == last_direction:
			motif_index = posmod(motif_index + 1, motif.size())
			direction = motif[motif_index]
		event["direction"] = direction
		last_direction = direction

func _count_kind(kind: String) -> int:
	var count := 0
	for raw in events:
		if raw is Dictionary and str(raw.get("type", "normal")) == kind:
			count += 1
	return count

func _set_status(message: String, color: Color) -> void:
	status.text = message
	status.add_theme_color_override("font_color", color)

func return_to_game() -> void:
	if music != null:
		music.stop()
	var navigation: Node = get_node_or_null("/root/NavigationController")
	if navigation != null and navigation.has_method("request_main_menu"):
		navigation.call("request_main_menu", 1)
		return
	get_tree().set_meta("beat_up_return_to_main_menu", true)
	get_tree().set_meta("beat_up_return_main_menu_focus", 1)
	SceneTransition.change_scene_quick("res://scenes/app_shell.tscn")

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.ctrl_pressed and key_event.keycode == KEY_Z:
		if key_event.shift_pressed:
			redo_edit()
		else:
			undo_edit()
		get_viewport().set_input_as_handled()
		return
	if key_event.ctrl_pressed and key_event.keycode == KEY_Y:
		redo_edit()
		get_viewport().set_input_as_handled()
		return
	match key_event.keycode:
		KEY_SPACE:
			toggle_play()
			get_viewport().set_input_as_handled()
		KEY_N:
			add_event("normal")
			get_viewport().set_input_as_handled()
		KEY_R:
			add_event("reverse")
			get_viewport().set_input_as_handled()
		KEY_S:
			if key_event.ctrl_pressed:
				save_chart()
			else:
				add_space_event()
			get_viewport().set_input_as_handled()
		KEY_DELETE, KEY_BACKSPACE:
			delete_nearest()
			get_viewport().set_input_as_handled()
		KEY_LEFT:
			seek_relative(-1.0)
			get_viewport().set_input_as_handled()
		KEY_RIGHT:
			seek_relative(1.0)
			get_viewport().set_input_as_handled()
		KEY_ESCAPE, KEY_F2:
			return_to_game()
			get_viewport().set_input_as_handled()
