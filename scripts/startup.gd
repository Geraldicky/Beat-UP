extends Control

const UserSettingsScript = preload("res://scripts/user_settings.gd")
const PlayerProfileScript = preload("res://scripts/player_profile.gd")
const RhythmTimingScript = preload("res://scripts/rhythm_timing.gd")
const ThemeConfigScript = preload("res://config/theme_config.gd")
const LayoutConfigScript = preload("res://config/ui_layout_config.gd")
const MinimalThemeScript = preload("res://scripts/ui/minimal_theme.gd")
const InteractionPolishScript = preload("res://scripts/ui/interaction_polish.gd")
const MainMenuControllerScript = preload("res://scripts/controllers/main_menu_controller.gd")
const MainMenuBackgroundControllerScript = preload("res://scripts/controllers/main_menu_background_controller.gd")
const NowPlayingControllerScript = preload("res://scripts/controllers/now_playing_controller.gd")
const RESULT_DEBUG_REQUEST_META := "numpad_blade_result_debug_requested"
const RETURN_TO_MENU_META := "beat_up_return_to_main_menu"
const RETURN_TO_MENU_FOCUS_META := "beat_up_return_main_menu_focus"
const BOOT_SPLASH_META := "beat_up_boot_splash_completed"

const MENU_ITEMS := [
	{"label": "PLAY", "title": "PLAY", "description": "Pick a song. Hit the beat."},
	{"label": "CHART STUDIO", "title": "CHART STUDIO", "description": "Import OGG + FLAC, generate charts, and edit the timeline."},
	{"label": "SETTINGS", "title": "SETTINGS", "description": "Display, input, audio, and timing."},
	{"label": "QUIT", "title": "EXIT", "description": "Close Beat UP!."},
	{"label": "HOW TO PLAY", "title": "HOW TO PLAY", "description": "Controls, timing, note rules, and practice."},
	{"label": "CALIBRATE", "title": "CALIBRATION", "description": "Sync input and audio timing."},
	{"label": "CREDITS", "title": "CREDITS", "description": "Project credits and acknowledgements."},
]

const MENU_BACKGROUND_CANDIDATES := [
	{"title": "Aleph-0", "artist": "LeaF", "audio": "res://music/imported/aleph_0.ogg"},
	{"title": "Aresene's Bazaar", "artist": "James Landino", "audio": "res://music/imported/aresenes_bazaar.ogg"},
	{"title": "Bad Apple!!", "artist": "Alstroemeria Records feat. nomico", "audio": "res://music/imported/bad_apple.ogg"},
	{"title": "Big Daddy", "artist": "USAO", "audio": "res://music/imported/big_daddy.ogg"},
	{"title": "Blue Zenith", "artist": "xi", "audio": "res://music/imported/blue_zenith.ogg"},
	{"title": "Beethoven Virus (Full Version)", "artist": "Diana Boncheva feat. BanYa", "audio": "res://music/imported/diana_boncheva_feat_banya_beethoven_virus_full_version.ogg"},
	{"title": "Exit This Earth's Atomosphere", "artist": "Camellia", "audio": "res://music/imported/exit_this_earths_atomosphere.ogg"},
	{"title": "FREEDOM DiVE↓", "artist": "xi", "audio": "res://music/imported/freedom_dive.ogg"},
	{"title": "Moonlight Sonata 3rd Movement (meganeko Remix)", "artist": "meganeko", "audio": "res://music/imported/moonlight_sonata_3rd_movement_meganeko_remix.ogg"},
	{"title": "Necrofantasia", "artist": "ZUN", "audio": "res://music/imported/necrofantasia.ogg"},
	{"title": "Night of Nights", "artist": "COOL&CREATE / beatMARIO", "audio": "res://music/imported/night_of_nights.ogg"},
	{"title": "Oshama Scramble!", "artist": "t+pazolite", "audio": "res://music/imported/oshama_scramble.ogg"},
	{"title": "Septette for the Dead Princess", "artist": "ZUN", "audio": "res://music/imported/septette_for_the_dead_princess.ogg"},
	{"title": "U.N. Owen Was Her? & Flowering Night (Koa Remix)", "artist": "Koa / ZUN", "audio": "res://music/imported/un_owen_was_her.ogg"},
]

const TUTORIAL_STEPS := [
	{
		"kicker": "INPUT",
		"title": "Match the direction.",
		"body": "Use 8K Numpad or the 4K Arrow fallback. Try the highlighted input on the practice lane.",
		"tip": "TRY IT · press a direction key",
	},
	{
		"kicker": "TIMING",
		"title": "Hit the diamond on beat.",
		"body": "Press when the note reaches the receptor. The lane immediately shows PERFECT, GREAT, GOOD, or MISS.",
		"tip": "TRY IT · follow the moving note",
	},
	{
		"kicker": "SPECIALS",
		"title": "Read color before shape.",
		"body": "Red Reverse means press the opposite direction. Gold means SPACE. Orange diagonals only appear in 8K.",
		"tip": "TRY IT · Reverse + SPACE",
	},
	{
		"kicker": "PRACTICE",
		"title": "Finish one short phrase.",
		"body": "Play a mixed training phrase with the same timing rules used in gameplay. No record is saved.",
		"tip": "CLEAR THE PHRASE · then start a song",
	},
]

@export var theme_config: ThemeConfigScript
@export var layout_config: LayoutConfigScript
@export_group("Splash Timing")
@export_range(0.1, 3.0, 0.05) var splash_reveal_duration: float = 0.72
@export_range(0.1, 5.0, 0.05) var splash_hold_duration: float = 1.15
@export_range(0.05, 2.0, 0.05) var splash_fade_duration: float = 0.52
@export_range(0.05, 2.0, 0.05) var menu_fade_duration: float = 0.28

@export_group("Debug")
@export var result_debug_shortcut_enabled := true

@export_group("First Run")
@export var auto_open_tutorial_on_first_release := true

@onready var background: ColorRect = %Background
@onready var menu_background: TextureRect = %MenuBackground
@onready var menu_dim: ColorRect = %MenuDim
@onready var background_info: VBoxContainer = %BackgroundInfo
@onready var background_kicker: Label = %BackgroundKicker
@onready var background_song: Label = %BackgroundSong
@onready var background_artist: Label = %BackgroundArtist
@onready var menu_version: Label = %MenuVersion
@onready var now_playing_card: Panel = %NowPlayingCard
@onready var now_playing_kicker: Label = %NowPlayingKicker
@onready var now_playing_title: Label = %NowPlayingTitle
@onready var now_playing_artist: Label = %NowPlayingArtist
@onready var track_progress_bar: ProgressBar = %TrackProgressBar
@onready var duration_value: Label = %DurationValue
@onready var prev_track_button: Button = %PrevTrackButton
@onready var play_pause_track_button: Button = %PlayPauseTrackButton
@onready var next_track_button: Button = %NextTrackButton
@onready var splash: Control = %Splash
@onready var main_menu: Control = %MainMenu
@onready var settings_menu: Control = %SettingsMenu
@onready var calibration_screen: Control = %CalibrationScreen
@onready var transition_overlay: ColorRect = %TransitionOverlay
@onready var menu_visual: Control = %MenuVisual
@onready var menu_bgm: MenuBGMController = %MenuBGM
@onready var orb_cluster: Control = %OrbCluster
@onready var orb_ring: Control = %OrbRing
@onready var orb_fill: Control = %OrbFill
@onready var main_logo: Label = %MainLogo
@onready var menu_stack: VBoxContainer = %MenuStack
@onready var utility_row: HBoxContainer = %UtilityRow
@onready var menu_title: Control = %MenuTitle
@onready var menu_rule: ColorRect = %MenuRule
@onready var main_footer: Label = %MainFooter
@onready var selection_index: Label = %SelectionIndex
@onready var selection_description: Label = %SelectionDescription
@onready var settings_dim: ColorRect = %SettingsDim
@onready var settings_panel: PanelContainer = %SettingsPanel
@onready var settings_vbox: VBoxContainer = %SettingsVBox
@onready var splash_black: ColorRect = $Splash/SplashBlack
@onready var splash_welcome: Label = %SplashWelcome
@onready var splash_glyphs: Label = %SplashGlyphs
@onready var splash_halo_outer: Control = %SplashHaloOuter
@onready var splash_halo_inner: Control = %SplashHaloInner
@onready var splash_logo_frame: Control = %SplashLogoFrame
@onready var splash_logo_window: Control = %SplashLogoWindow
@onready var splash_logo: Control = %SplashLogo
@onready var splash_wipe: ColorRect = %SplashWipe
@onready var settings_title: Label = %SettingsTitle
@onready var display_section_label: Label = %DisplaySectionLabel
@onready var audio_section_label: Label = %AudioSectionLabel
@onready var timing_section_label: Label = %TimingSectionLabel
@onready var display_settings_group: VBoxContainer = %DisplaySettingsGroup
@onready var audio_settings_group: VBoxContainer = %AudioSettingsGroup
@onready var timing_settings_group: VBoxContainer = %TimingSettingsGroup
@onready var display_tab: Button = %DisplayTab
@onready var audio_tab: Button = %AudioTab
@onready var timing_tab: Button = %TimingTab
@onready var resolution_label: Label = %ResolutionLabel
@onready var resolution_option = %ResolutionOption
@onready var window_mode_label: Label = %WindowModeLabel
@onready var window_mode_option = %WindowModeOption
@onready var vsync_label: Label = %VSyncLabel
@onready var vsync_option = %VSyncOption
@onready var input_style_label: Label = %InputStyleLabel
@onready var input_style_option = %InputStyleOption
@onready var display_hint: Label = %DisplayHint
@onready var master_label: Label = %MasterLabel
@onready var background_label: Label = %BackgroundLabel
@onready var input_offset_label: Label = %InputOffsetLabel
@onready var audio_offset_label: Label = %AudioOffsetLabel
@onready var settings_hint: Label = %SettingsHint
@onready var play_button: Button = %PlayButton
@onready var chart_studio_button: Button = %ChartStudioButton
@onready var settings_button: Button = %SettingsButton
@onready var exit_button: Button = %ExitButton
@onready var help_button: Button = %HelpButton
@onready var quick_calibration_button: Button = %QuickCalibrationButton
@onready var credits_button: Button = %CreditsButton
@onready var master_slider: HSlider = %MasterSlider
@onready var master_value: Label = %MasterValue
@onready var menu_sfx_toggle: CheckButton = %MenuSFXToggle
@onready var menu_sfx_slider: HSlider = %MenuSFXSlider
@onready var menu_sfx_value: Label = %MenuSFXValue
@onready var bg_opacity_slider: HSlider = %BackgroundOpacitySlider
@onready var background_value: Label = %BackgroundValue
@onready var input_offset_slider: HSlider = %InputOffsetSlider
@onready var audio_offset_slider: HSlider = %AudioOffsetSlider
@onready var input_offset_value: Label = %InputOffsetValue
@onready var audio_offset_value: Label = %AudioOffsetValue
@onready var calibration_button: Button = %CalibrationButton
@onready var reset_defaults_button: Button = %ResetDefaultsButton
@onready var back_button: Button = %BackButton
@onready var help_screen: Control = %HelpScreen
@onready var help_margin: MarginContainer = $HelpScreen/HelpMargin
@onready var help_body: HBoxContainer = $HelpScreen/HelpMargin/HelpVBox/HelpBody
@onready var tutorial_copy_panel: PanelContainer = $HelpScreen/HelpMargin/HelpVBox/HelpBody/TutorialCopyPanel
@onready var tutorial_visual_panel: PanelContainer = $HelpScreen/HelpMargin/HelpVBox/HelpBody/TutorialVisualPanel
@onready var tutorial_visual: HowToPlayVisual = $HelpScreen/HelpMargin/HelpVBox/HelpBody/TutorialVisualPanel/TutorialVisual
@onready var tutorial_kicker: Label = $HelpScreen/HelpMargin/HelpVBox/HelpBody/TutorialCopyPanel/TutorialCopy/TutorialKicker
@onready var tutorial_heading: Label = $HelpScreen/HelpMargin/HelpVBox/HelpBody/TutorialCopyPanel/TutorialCopy/TutorialHeading
@onready var tutorial_description: Label = $HelpScreen/HelpMargin/HelpVBox/HelpBody/TutorialCopyPanel/TutorialCopy/TutorialDescription
@onready var tutorial_input_style_block: PanelContainer = $HelpScreen/HelpMargin/HelpVBox/HelpBody/TutorialCopyPanel/TutorialCopy/InputStyleBlock
@onready var tutorial_input_style_label: Label = $HelpScreen/HelpMargin/HelpVBox/HelpBody/TutorialCopyPanel/TutorialCopy/InputStyleBlock/InputStyleVBox/InputStyleLabel
@onready var tutorial_numpad_button: Button = $HelpScreen/HelpMargin/HelpVBox/HelpBody/TutorialCopyPanel/TutorialCopy/InputStyleBlock/InputStyleVBox/InputStyleButtons/TutorialNumpadButton
@onready var tutorial_arrow_button: Button = $HelpScreen/HelpMargin/HelpVBox/HelpBody/TutorialCopyPanel/TutorialCopy/InputStyleBlock/InputStyleVBox/InputStyleButtons/TutorialArrowButton
@onready var tutorial_input_style_status: Label = $HelpScreen/HelpMargin/HelpVBox/HelpBody/TutorialCopyPanel/TutorialCopy/InputStyleBlock/InputStyleVBox/InputStyleStatus
@onready var tutorial_tip: Label = $HelpScreen/HelpMargin/HelpVBox/HelpBody/TutorialCopyPanel/TutorialCopy/TutorialTipPanel/TutorialTip
@onready var tutorial_eyebrow: Label = $HelpScreen/HelpMargin/HelpVBox/HelpHeader/HeaderCopy/Eyebrow
@onready var tutorial_step_dots: Label = $HelpScreen/HelpMargin/HelpVBox/HelpActions/TutorialStepDots
@onready var tutorial_controls_tab: Button = $HelpScreen/HelpMargin/HelpVBox/TutorialTabs/TutorialControlsTab
@onready var tutorial_timing_tab: Button = $HelpScreen/HelpMargin/HelpVBox/TutorialTabs/TutorialTimingTab
@onready var tutorial_notes_tab: Button = $HelpScreen/HelpMargin/HelpVBox/TutorialTabs/TutorialNotesTab
@onready var tutorial_practice_tab: Button = $HelpScreen/HelpMargin/HelpVBox/TutorialTabs/TutorialPracticeTab
@onready var tutorial_previous_button: Button = $HelpScreen/HelpMargin/HelpVBox/HelpActions/TutorialPreviousButton
@onready var credits_screen: Control = %CreditsScreen
@onready var credits_margin: MarginContainer = $CreditsScreen/CreditsMargin
@onready var credits_info_panel: PanelContainer = %CreditsInfoPanel
@onready var credits_visual_panel: PanelContainer = %CreditsVisualPanel
@onready var credits_title: Label = %CreditsTitle
@onready var credits_orbit: Control = %CreditsOrbit
@onready var credits_mark: Label = $CreditsScreen/CreditsMargin/CreditsVBox/CreditsBody/CreditsVisualPanel/CreditsVisual/CreditsMark
@onready var exit_dialog: Control = %ExitDialog
@onready var help_back_button: Button = $HelpScreen/HelpMargin/HelpVBox/HelpActions/HelpBackButton
@onready var tutorial_button: Button = $HelpScreen/HelpMargin/HelpVBox/HelpActions/TutorialButton
@onready var credits_back_button: Button = %CreditsBackButton
@onready var credits_version: Label = %CreditsVersion
@onready var exit_confirm_button: Button = %ExitConfirmButton
@onready var exit_cancel_button: Button = %ExitCancelButton
@onready var exit_dim: ColorRect = %Dim
@onready var exit_panel: PanelContainer = %Panel
@onready var exit_power_icon: BeatUpActionIcon = %PowerIcon

var splash_finished := false
var active_tween: Tween
var launch_menu_tween: Tween
var settings_tween: Tween
var in_transition := false
var resolution_values: Array[Vector2i] = []
var menu_buttons: Array[Button] = []
var tutorial_tabs: Array[Button] = []
var tutorial_step_index := 0
var tutorial_tween: Tween
var first_run_tutorial_pending := false
var tutorial_opened_from_first_run := false
var calibration_returns_to_settings := true
var exit_dialog_tween: Tween
var settings_tabs: Array[Button] = []
var settings_tab_index := 0
var v18_effect_intensity_slider: HSlider
var v18_effect_intensity_value: Label
var v18_binding_buttons: Dictionary = {}
var v18_binding_capture_action: String = ""
var v18_binding_hint: Label

# v17.4.35: Startup remains the composition root while focused controllers own
# Main Menu interaction, shared background state, and Now Playing presentation.
var main_menu_controller: RefCounted
var main_menu_background_controller: RefCounted
var now_playing_controller: RefCounted

func _sync_visible_version_labels() -> void:
	var version := str(ProjectSettings.get_setting("application/config/version", "DEV"))
	if credits_version != null:
		credits_version.text = "BEAT UP!  /  SYSTEM %s" % version
	if menu_version != null and not menu_version.text.is_empty():
		menu_version.text = "v%s" % version

func _ready() -> void:
	if theme_config == null:
		theme_config = ThemeConfigScript.new()
	if layout_config == null:
		layout_config = LayoutConfigScript.new()
	MinimalThemeScript.apply_root(self)
	_sync_visible_version_labels()
	UserSettingsScript.initialize_storage()
	PlayerProfileScript.initialize_profile()
	var display_applied: bool = UserSettingsScript.apply_display_preferences()
	_setup_display_controls()
	_build_v18_settings_controls()
	menu_buttons = [play_button, chart_studio_button, settings_button, exit_button, help_button, quick_calibration_button, credits_button]
	tutorial_tabs = [tutorial_controls_tab, tutorial_timing_tab, tutorial_notes_tab, tutorial_practice_tab]
	settings_tabs = [display_tab, audio_tab, timing_tab]
	_setup_main_menu_controllers()
	for index in range(menu_buttons.size()):
		menu_buttons[index].text = str(MENU_ITEMS[index]["label"])
	_wire_menu_focus()
	_apply_layout_config()
	_apply_theme()
	_apply_main_menu_text_cleanup()
	# Keep the player-facing Settings screen compact: tabs already provide the section context.
	display_section_label.visible = false
	audio_section_label.visible = false
	timing_section_label.visible = false
	InteractionPolishScript.install_buttons([calibration_button, reset_defaults_button, back_button, credits_back_button, tutorial_button, tutorial_previous_button])
	_connect_global_song_state()
	_randomize_main_menu_background(true)
	_setup_launch_splash_style()
	if not resized.is_connected(_apply_layout_config):
		resized.connect(_apply_layout_config)
	main_menu.visible = false
	settings_menu.visible = false
	calibration_screen.visible = false
	help_screen.visible = false
	credits_screen.visible = false
	exit_dialog.visible = false
	splash.visible = _should_show_launch_splash() and not get_tree().has_meta(RETURN_TO_MENU_META)
	splash.modulate.a = 1.0
	transition_overlay.modulate.a = 0.0
	play_button.pressed.connect(_on_play_pressed)
	chart_studio_button.pressed.connect(_on_chart_studio_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	help_button.pressed.connect(_on_help_pressed)
	quick_calibration_button.pressed.connect(_on_quick_calibration_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	prev_track_button.pressed.connect(_on_prev_track_pressed)
	play_pause_track_button.pressed.connect(_on_play_pause_track_pressed)
	next_track_button.pressed.connect(_on_next_track_pressed)
	help_back_button.pressed.connect(_return_to_main_menu)
	tutorial_previous_button.pressed.connect(_on_tutorial_previous_pressed)
	tutorial_button.pressed.connect(_on_tutorial_next_pressed)
	tutorial_numpad_button.pressed.connect(_on_tutorial_input_style_selected.bind("8_direction"))
	tutorial_arrow_button.pressed.connect(_on_tutorial_input_style_selected.bind("4_arrow"))
	for tab_index in range(tutorial_tabs.size()):
		tutorial_tabs[tab_index].pressed.connect(_set_tutorial_step.bind(tab_index))
	if tutorial_visual.has_signal("practice_updated"):
		tutorial_visual.practice_updated.connect(_on_tutorial_practice_updated)
	if tutorial_visual.has_signal("practice_completed"):
		tutorial_visual.practice_completed.connect(_on_tutorial_practice_completed)
	credits_back_button.pressed.connect(_return_to_main_menu)
	exit_confirm_button.pressed.connect(_confirm_exit)
	exit_cancel_button.pressed.connect(_cancel_exit)
	back_button.pressed.connect(_on_back_pressed)
	calibration_button.pressed.connect(_on_calibration_pressed)
	reset_defaults_button.pressed.connect(_on_reset_defaults_pressed)
	master_slider.value_changed.connect(_on_master_volume_changed)
	menu_sfx_slider.value_changed.connect(_on_menu_sfx_volume_changed)
	menu_sfx_toggle.toggled.connect(_on_menu_sfx_toggled)
	bg_opacity_slider.value_changed.connect(_on_background_opacity_changed)
	input_offset_slider.value_changed.connect(_on_input_offset_changed)
	audio_offset_slider.value_changed.connect(_on_audio_offset_changed)
	resolution_option.item_selected.connect(_on_resolution_selected)
	window_mode_option.item_selected.connect(_on_window_mode_selected)
	vsync_option.item_selected.connect(_on_vsync_selected)
	input_style_option.item_selected.connect(_on_input_style_selected)
	for tab_index in range(settings_tabs.size()):
		settings_tabs[tab_index].pressed.connect(_set_settings_tab.bind(tab_index))
	for button in menu_buttons:
		button.focus_entered.connect(_on_menu_button_highlight.bind(button))
		button.mouse_entered.connect(_on_menu_button_highlight.bind(button))
		button.focus_exited.connect(_on_menu_button_unhighlight.bind(button))
		button.mouse_exited.connect(_on_menu_button_unhighlight.bind(button))
	if calibration_screen.has_signal("back_requested"):
		calibration_screen.connect("back_requested", Callable(self, "_on_calibration_back_requested"))
	if calibration_screen.has_signal("applied"):
		calibration_screen.connect("applied", Callable(self, "_on_calibration_applied"))
	_load_settings()
	_update_display_hint(display_applied)
	call_deferred("_refresh_pivots")
	# Automated first-run onboarding is release-only so editor/debug QA and UI
	# capture tests remain deterministic. A normal Beta export opens it once.
	first_run_tutorial_pending = auto_open_tutorial_on_first_release and not _developer_shortcuts_available() and not UserSettingsScript.has_seen_first_run_tutorial()
	var returning_to_menu := get_tree().has_meta(RETURN_TO_MENU_META)
	if get_tree().has_meta(RETURN_TO_MENU_FOCUS_META):
		_set_main_menu_focus_index(clampi(int(get_tree().get_meta(RETURN_TO_MENU_FOCUS_META)), 0, menu_buttons.size() - 1))
		get_tree().remove_meta(RETURN_TO_MENU_FOCUS_META)
	if returning_to_menu:
		first_run_tutorial_pending = false
		get_tree().remove_meta(RETURN_TO_MENU_META)

	# v17.4.21.4: launch-splash ownership lives in an autoload that survives
	# scene replacement. SceneTree metadata is retained only for compatibility;
	# it is no longer the source of truth. The autoload resets naturally only
	# when the application process exits.
	if returning_to_menu or not _should_show_launch_splash():
		_mark_launch_splash_seen()
		splash_finished = true
		splash.visible = false
		call_deferred("_show_main_menu_immediate")
	else:
		_run_splash()

func _get_app_session_state() -> Node:
	# Resolve the autoload through /root instead of relying on a parser-time
	# global identifier. This remains valid even when individual scripts are
	# parsed/reloaded before the editor has registered autoload globals.
	return get_node_or_null("/root/AppSessionState")

func _should_show_launch_splash() -> bool:
	var app_session_state: Node = _get_app_session_state()
	if app_session_state != null and app_session_state.has_method("should_show_launch_splash"):
		return bool(app_session_state.call("should_show_launch_splash"))
	# Safe fallback: during this process, SceneTree metadata still prevents a
	# second splash if the autoload is temporarily unavailable in the editor.
	return not get_tree().has_meta(BOOT_SPLASH_META)

func _mark_launch_splash_seen() -> void:
	var app_session_state: Node = _get_app_session_state()
	if app_session_state != null and app_session_state.has_method("mark_splash_seen"):
		app_session_state.call("mark_splash_seen")
	get_tree().set_meta(BOOT_SPLASH_META, true)

func _apply_main_menu_text_cleanup() -> void:
	# Album Flow: the menu is artwork-first with a restrained editorial wordmark.
	# Legacy orb/index/description elements remain in the scene for compatibility
	# but are intentionally not part of the v19 presentation.
	for node in [main_logo, selection_index, selection_description, orb_cluster, background_info, main_footer]:
		if node != null:
			node.visible = false
	if menu_title != null:
		menu_title.visible = true
		menu_title.set("show_text", true)
		menu_title.queue_redraw()
	if menu_version != null:
		menu_version.visible = true
	if menu_rule != null:
		menu_rule.visible = true
		menu_rule.color = Color(MinimalThemeScript.ACCENT, 0.56)

func _setup_main_menu_controllers() -> void:
	main_menu_background_controller = MainMenuBackgroundControllerScript.new()
	now_playing_controller = NowPlayingControllerScript.new()
	main_menu_controller = MainMenuControllerScript.new()

	main_menu_background_controller.call(
		"configure",
		self,
		menu_background,
		background_song,
		background_artist,
		menu_bgm,
		main_menu,
		MENU_BACKGROUND_CANDIDATES,
		Callable(self, "_update_now_playing_card")
	)
	now_playing_controller.call(
		"configure",
		self,
		now_playing_title,
		now_playing_artist,
		track_progress_bar,
		duration_value,
		prev_track_button,
		play_pause_track_button,
		next_track_button,
		menu_bgm,
		main_menu_background_controller
	)
	main_menu_controller.call(
		"configure",
		self,
		menu_buttons,
		MENU_ITEMS,
		main_menu,
		settings_menu,
		selection_index,
		main_logo,
		selection_description,
		orb_cluster,
		orb_ring,
		orb_fill,
		menu_visual,
		menu_rule,
		play_button
	)

func _update_now_playing_card() -> void:
	if now_playing_controller != null:
		now_playing_controller.call("update_card")

func _set_menu_background_by_index(index: int, force_animation: bool = false, autoplay: bool = true) -> void:
	if main_menu_background_controller != null:
		main_menu_background_controller.call("set_by_index", index, force_animation, autoplay)

func _cycle_menu_background(step: int) -> void:
	if main_menu_background_controller != null:
		main_menu_background_controller.call("cycle", step)

func _sync_main_menu_from_music_session() -> bool:
	return main_menu_background_controller != null and bool(main_menu_background_controller.call("sync_from_music_session"))

func _connect_global_song_state() -> void:
	if main_menu_background_controller != null:
		main_menu_background_controller.call("connect_global_state")

func _ensure_main_menu_music_ready(fade_duration: float = 0.18) -> bool:
	if main_menu_background_controller == null or not main_menu_background_controller.has_method("ensure_music_ready"):
		return false
	return bool(main_menu_background_controller.call("ensure_music_ready", fade_duration))

func _apply_global_background_state(state: Dictionary, animate: bool = false) -> bool:
	return main_menu_background_controller != null and bool(main_menu_background_controller.call("apply_global_state", state, animate))

func _apply_library_audio_handoff(handoff: Dictionary) -> bool:
	return main_menu_background_controller != null and bool(main_menu_background_controller.call("apply_library_audio_handoff", handoff))

func _set_menu_track_paused(paused: bool) -> void:
	if now_playing_controller != null:
		now_playing_controller.call("set_paused", paused)

func _on_prev_track_pressed() -> void:
	if in_transition:
		return
	_cycle_menu_background(-1)

func _on_next_track_pressed() -> void:
	if in_transition:
		return
	_cycle_menu_background(1)

func _on_play_pause_track_pressed() -> void:
	if in_transition or now_playing_controller == null:
		return
	now_playing_controller.call("toggle_pause")

func _process(delta: float) -> void:
	if now_playing_controller != null and main_menu.visible and not settings_menu.visible:
		now_playing_controller.call("update_progress")
	if main_menu_controller != null:
		var levels: PackedFloat32Array = menu_bgm.get_latest_levels() if menu_bgm != null else PackedFloat32Array()
		main_menu_controller.call("process_visual", delta, main_menu.visible and not settings_menu.visible, levels)

func _apply_main_menu_live_pulse(energy: float, delta: float) -> void:
	if main_menu_controller != null:
		main_menu_controller.call("apply_live_pulse", energy, delta)

func _current_menu_track_length() -> float:
	return float(now_playing_controller.call("get_track_length")) if now_playing_controller != null else 0.0

func _format_time(seconds: float) -> String:
	return str(now_playing_controller.call("format_time", seconds)) if now_playing_controller != null else "0:00"

func _update_now_playing_progress() -> void:
	if now_playing_controller != null:
		now_playing_controller.call("update_progress")

func _get_main_menu_focus_index() -> int:
	return int(main_menu_controller.call("get_focus_index")) if main_menu_controller != null else 0

func _set_main_menu_focus_index(index: int) -> void:
	if main_menu_controller != null:
		main_menu_controller.call("set_focus_index", index)

func _apply_layout_config() -> void:
	if not is_node_ready() or layout_config == null:
		return
	var viewport_size: Vector2 = size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return
	var reference_scale: float = minf(viewport_size.x / 1600.0, viewport_size.y / 900.0)
	var margin: float = clampf(viewport_size.x * 0.055, 42.0, 92.0)

	# Current-song artwork remains full-bleed atmosphere. The foreground anchor is
	# now exclusively Beat UP! branding, positioned left of the primary actions.
	var hero_radius: float = clampf(minf(viewport_size.x * 0.145, viewport_size.y * 0.25), 164.0, 270.0)
	var hero_center := Vector2(viewport_size.x * 0.36, viewport_size.y * 0.52)
	orb_cluster.visible = false
	orb_cluster.position = Vector2.ZERO
	orb_cluster.size = Vector2.ZERO
	orb_ring.visible = false
	orb_fill.visible = false
	main_logo.visible = false
	selection_index.visible = false

	# Wordmark is integrated into the rounded diamond panel drawn by MenuVisual.
	var title_width: float = hero_radius * 1.12
	var title_height: float = clampf(hero_radius * 0.34, 58.0, 92.0)
	menu_title.position = hero_center - Vector2(title_width * 0.5, title_height * 0.5)
	menu_title.size = Vector2(title_width, title_height)
	menu_title.pivot_offset = menu_title.size * 0.5

	# Four primary actions form a tight right-side column. Legacy utility actions
	# remain reachable as low-emphasis footer links below it.
	var rail_width: float = clampf(viewport_size.x * 0.19, 276.0, 348.0)
	var item_height: float = clampf(47.0 * reference_scale, float(MinimalThemeScript.MIN_ACTION_HEIGHT), 52.0)
	var play_height: float = clampf(64.0 * reference_scale, 58.0, 70.0)
	var item_gap: int = roundi(clampf(9.0 * reference_scale, 7.0, 11.0))
	var rail_x: float = clampf(viewport_size.x * 0.70, hero_center.x + hero_radius + 72.0, viewport_size.x - margin - rail_width)
	var rail_y: float = clampf(viewport_size.y * 0.32, 220.0, 350.0)
	var primary_buttons: Array[Button] = [play_button, chart_studio_button, settings_button, exit_button]
	var rail_height: float = play_height + item_height * 3.0 + float(item_gap) * 3.0
	menu_stack.custom_minimum_size = Vector2(rail_width, 0.0)
	menu_stack.size = Vector2(rail_width, rail_height)
	menu_stack.position = Vector2(rail_x, rail_y)
	menu_stack.add_theme_constant_override("separation", item_gap)
	for index in range(primary_buttons.size()):
		var button := primary_buttons[index]
		button.custom_minimum_size = Vector2(rail_width, play_height if index == 0 else item_height)
		_set_button_pivot(button)

	var utility_height := clampf(32.0 * reference_scale, 30.0, 34.0)
	utility_row.position = Vector2(rail_x, rail_y + rail_height + 24.0)
	utility_row.size = Vector2(rail_width, utility_height)
	utility_row.add_theme_constant_override("separation", 6)
	for button in [help_button, quick_calibration_button, credits_button]:
		button.custom_minimum_size = Vector2(0.0, utility_height)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_set_button_pivot(button)

	# A compact rotated marker carries focus without turning actions into cards.
	menu_rule.position = Vector2(rail_x - 17.0, rail_y + (play_height - 8.0) * 0.5)
	menu_rule.size = Vector2(8.0, 8.0)
	menu_rule.pivot_offset = menu_rule.size * 0.5
	menu_rule.rotation = PI * 0.25

	# Persistent MusicSession controls remain a top horizontal rail.
	var now_playing_height: float = clampf(68.0 * reference_scale, 62.0, 74.0)
	var now_playing_width: float = viewport_size.x - margin * 2.0
	now_playing_card.position = Vector2(margin, clampf(viewport_size.y * 0.038, 26.0, 42.0))
	now_playing_card.size = Vector2(now_playing_width, now_playing_height)
	now_playing_card.pivot_offset = now_playing_card.size * 0.5
	if track_progress_bar != null:
		track_progress_bar.custom_minimum_size = Vector2(clampf(now_playing_width * 0.31, 220.0, 520.0), 3.0)
	if duration_value != null:
		duration_value.custom_minimum_size = Vector2(112.0, 0.0)

	menu_version.position = Vector2(viewport_size.x - margin - 130.0, viewport_size.y - clampf(margin * 0.62, 30.0, 54.0))
	menu_version.size = Vector2(130.0, 24.0)
	menu_version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	selection_description.position = Vector2.ZERO
	selection_description.size = Vector2.ZERO
	background_info.position = Vector2.ZERO
	background_info.size = Vector2.ZERO
	main_footer.position = Vector2.ZERO
	main_footer.size = Vector2.ZERO

	var help_horizontal_margin: float = clampf(viewport_size.x * 0.038, 34.0, 56.0)
	var help_vertical_margin: float = clampf(viewport_size.y * 0.040, 24.0, 38.0)
	help_margin.offset_left = help_horizontal_margin
	help_margin.offset_right = -help_horizontal_margin
	help_margin.offset_top = help_vertical_margin
	help_margin.offset_bottom = -help_vertical_margin
	tutorial_copy_panel.custom_minimum_size.x = clampf(390.0 * reference_scale, 286.0, 420.0)
	tutorial_visual_panel.custom_minimum_size.x = clampf(560.0 * reference_scale, 360.0, 620.0)
	tutorial_heading.add_theme_font_size_override("font_size", roundi(clampf(38.0 * reference_scale, 24.0, 38.0)))
	tutorial_description.add_theme_font_size_override("font_size", roundi(clampf(16.0 * reference_scale, 13.0, 16.0)))
	for tab in tutorial_tabs:
		tab.custom_minimum_size.y = clampf(42.0 * reference_scale, 36.0, 42.0)
	settings_panel.custom_minimum_size = Vector2(clampf(viewport_size.x - 300.0, 720.0, 1040.0), clampf(viewport_size.y - 190.0, 520.0, 680.0))
	var credits_content_width: float = viewport_size.x - margin * 2.0
	credits_info_panel.custom_minimum_size.x = maxf(380.0, credits_content_width * 0.50)
	credits_visual_panel.custom_minimum_size.x = maxf(360.0, credits_content_width * 0.40)
	credits_margin.offset_left = margin
	credits_margin.offset_right = -margin
	call_deferred("_refresh_pivots")

func _set_button_pivot(button: Button) -> void:
	button.pivot_offset = Vector2(0.0, button.custom_minimum_size.y * 0.5)

func _wire_menu_focus() -> void:
	for index in range(menu_buttons.size()):
		var button := menu_buttons[index]
		var previous := menu_buttons[posmod(index - 1, menu_buttons.size())]
		var next := menu_buttons[(index + 1) % menu_buttons.size()]
		button.focus_neighbor_top = button.get_path_to(previous)
		button.focus_neighbor_bottom = button.get_path_to(next)

func _refresh_pivots() -> void:
	if orb_cluster != null:
		orb_cluster.pivot_offset = orb_cluster.size * 0.5
	if orb_ring != null:
		orb_ring.pivot_offset = orb_ring.size * 0.5
	if orb_fill != null:
		orb_fill.pivot_offset = orb_fill.size * 0.5
	if settings_panel != null:
		settings_panel.pivot_offset = settings_panel.size * 0.5
	if splash != null:
		splash.pivot_offset = splash.size * 0.5
	if menu_title != null:
		menu_title.pivot_offset = menu_title.size * 0.5
	if menu_background != null:
		menu_background.pivot_offset = menu_background.size * 0.5
	for button in menu_buttons:
		_set_button_pivot(button)

func _apply_theme() -> void:
	if theme_config == null:
		return
	for index in range(menu_buttons.size()):
		_style_main_menu_button(menu_buttons[index], index)
	main_footer.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.54))
	main_footer.add_theme_font_size_override("font_size", theme_config.caption_size)
	selection_description.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.66))
	main_footer.text = "ENTER"
	main_footer.visible = false
	main_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_footer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	main_footer.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.96))

	selection_description.add_theme_font_override("font", MinimalThemeScript.body_font())
	background_kicker.add_theme_font_override("font", MinimalThemeScript.mono_font())
	background_kicker.add_theme_font_size_override("font_size", 10)
	background_kicker.add_theme_color_override("font_color", Color(MinimalThemeScript.PINK, 0.82))
	background_song.add_theme_font_override("font", MinimalThemeScript.semibold_font())
	background_song.add_theme_font_size_override("font_size", 18)
	background_song.add_theme_color_override("font_color", MinimalThemeScript.TEXT)
	background_artist.add_theme_font_override("font", MinimalThemeScript.body_font())
	background_artist.add_theme_font_size_override("font_size", 12)
	background_artist.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.66))
	menu_version.add_theme_font_override("font", MinimalThemeScript.mono_font())
	menu_version.add_theme_font_size_override("font_size", 11)
	menu_version.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.54))
	menu_version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	now_playing_card.add_theme_stylebox_override("panel", MinimalThemeScript.panel_style(Color(MinimalThemeScript.BG, 0.62), 12, Color(MinimalThemeScript.ACCENT_LIGHT, 0.20), 1, 0.0))
	MinimalThemeScript.apply_mono(now_playing_kicker, 9, Color(MinimalThemeScript.ACCENT, 0.92))
	now_playing_kicker.add_theme_font_size_override("font_size", 9)
	now_playing_kicker.visible = true
	now_playing_kicker.text = "NOW PLAYING"
	MinimalThemeScript.apply_heading(now_playing_title, 16, MinimalThemeScript.TEXT)
	now_playing_title.add_theme_font_size_override("font_size", 16)
	now_playing_title.clip_text = true
	now_playing_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	now_playing_title.custom_minimum_size.x = 310.0
	MinimalThemeScript.apply_body(now_playing_artist, 11, Color(1.0, 1.0, 1.0, 0.72))
	now_playing_artist.add_theme_font_override("font", MinimalThemeScript.medium_font())
	now_playing_artist.clip_text = true
	now_playing_artist.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	now_playing_artist.custom_minimum_size.x = 132.0
	MinimalThemeScript.apply_mono(duration_value, 10, Color(1.0, 1.0, 1.0, 0.74))
	track_progress_bar.add_theme_stylebox_override("background", MinimalThemeScript.panel_style(Color(1.0, 1.0, 1.0, 0.14), 2, Color(1.0, 1.0, 1.0, 0.0), 0, 0.0))
	track_progress_bar.add_theme_stylebox_override("fill", MinimalThemeScript.panel_style(Color(MinimalThemeScript.ACCENT, 0.94), 2, Color(MinimalThemeScript.ACCENT, 0.0), 0, 0.0))
	for transport_button in [prev_track_button, play_pause_track_button, next_track_button]:
		transport_button.focus_mode = Control.FOCUS_ALL
		transport_button.flat = true
		transport_button.custom_minimum_size = Vector2(36.0, 36.0)
		transport_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		transport_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		transport_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		transport_button.add_theme_stylebox_override("focus", MinimalThemeScript.panel_style(Color(MinimalThemeScript.ACCENT, 0.10), 8, Color(MinimalThemeScript.ACCENT_LIGHT, 0.76), 1, 0.0))
		transport_button.add_theme_font_override("font", MinimalThemeScript.medium_font())
		transport_button.add_theme_font_size_override("font_size", 14)
		transport_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.78))
		transport_button.add_theme_color_override("font_hover_color", MinimalThemeScript.PINK)
		transport_button.add_theme_color_override("font_pressed_color", MinimalThemeScript.PINK)
		transport_button.add_theme_color_override("font_focus_color", MinimalThemeScript.PINK)
	for label in [settings_title, display_section_label, audio_section_label, timing_section_label, resolution_label, window_mode_label, vsync_label, input_style_label, master_label, background_label, input_offset_label, audio_offset_label]:
		label.add_theme_color_override("font_color", theme_config.text_primary)
	MinimalThemeScript.apply_heading(settings_title, settings_title.get_theme_font_size("font_size"), theme_config.text_primary)
	for section_label in [display_section_label, audio_section_label, timing_section_label]:
		section_label.add_theme_font_override("font", MinimalThemeScript.semibold_font())
	settings_hint.add_theme_color_override("font_color", theme_config.text_secondary)
	display_hint.add_theme_color_override("font_color", theme_config.text_secondary)
	input_offset_value.add_theme_color_override("font_color", theme_config.accent_secondary)
	audio_offset_value.add_theme_color_override("font_color", theme_config.space_accent)
	for value_label in [master_value, menu_sfx_value, background_value]:
		MinimalThemeScript.apply_mono(value_label, 14, MinimalThemeScript.CYAN)
	for option in [resolution_option, window_mode_option, vsync_option, input_style_option]:
		for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			option.add_theme_color_override(color_name, theme_config.text_primary)
		option.add_theme_font_size_override("font_size", theme_config.body_size)
	for button in [calibration_button, reset_defaults_button, back_button]:
		for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			button.add_theme_color_override(color_name, theme_config.text_primary)
		button.add_theme_font_size_override("font_size", theme_config.button_size)
	MinimalThemeScript.style_primary(tutorial_button)
	MinimalThemeScript.style_secondary(exit_cancel_button, MinimalThemeScript.CYAN)
	MinimalThemeScript.style_danger(exit_confirm_button)
	MinimalThemeScript.apply_mono(main_footer, 28, MinimalThemeScript.PINK)
	MinimalThemeScript.apply_mono(selection_index, 12, MinimalThemeScript.CYAN)
	main_logo.add_theme_font_override("font", MinimalThemeScript.semibold_font())
	main_logo.add_theme_font_size_override("font_size", 26)
	MinimalThemeScript.apply_mono(input_offset_value, 14, MinimalThemeScript.CYAN)
	MinimalThemeScript.apply_mono(audio_offset_value, 14, MinimalThemeScript.GOLD)
	MinimalThemeScript.apply_mono(tutorial_kicker, 11, MinimalThemeScript.PINK)
	MinimalThemeScript.apply_mono(tutorial_input_style_label, 10, MinimalThemeScript.MUTED)
	MinimalThemeScript.apply_mono(tutorial_input_style_status, 10, MinimalThemeScript.CYAN)
	MinimalThemeScript.apply_mono(tutorial_tip, 12, MinimalThemeScript.CYAN)
	MinimalThemeScript.apply_mono(tutorial_step_dots, 12, MinimalThemeScript.MUTED)
	tutorial_copy_panel.add_theme_stylebox_override("panel", MinimalThemeScript.panel_style(Color(MinimalThemeScript.SURFACE, 0.88), MinimalThemeScript.RADIUS_LG, Color(MinimalThemeScript.BORDER, 0.64), 1, 24.0))
	tutorial_input_style_block.add_theme_stylebox_override("panel", MinimalThemeScript.panel_style(Color(MinimalThemeScript.BG, 0.48), 10, Color(MinimalThemeScript.BORDER, 0.90), 1, 12.0))
	tutorial_visual_panel.add_theme_stylebox_override("panel", MinimalThemeScript.panel_style(Color(MinimalThemeScript.BG, 0.98), 14, MinimalThemeScript.BORDER, 1, 0.0))
	for tab in tutorial_tabs:
		tab.add_theme_font_override("font", MinimalThemeScript.medium_font())
		tab.add_theme_font_size_override("font_size", 11)
	MinimalThemeScript.apply_heading(tutorial_heading, tutorial_heading.get_theme_font_size("font_size"), MinimalThemeScript.TEXT)
	_refresh_tutorial_input_style_controls()
	_style_tutorial_tabs()
	settings_panel.add_theme_stylebox_override("panel", MinimalThemeScript.surface_s3(26.0))
	credits_info_panel.add_theme_stylebox_override("panel", MinimalThemeScript.surface_s2(30.0))
	credits_visual_panel.add_theme_stylebox_override("panel", MinimalThemeScript.panel_style(Color(MinimalThemeScript.BG, 0.90), MinimalThemeScript.RADIUS_LG, Color(MinimalThemeScript.ACCENT, 0.18), 1, 0.0))
	credits_title.add_theme_color_override("font_color", MinimalThemeScript.TEXT)
	credits_title.add_theme_font_override("font", MinimalThemeScript.semibold_font())
	credits_mark.add_theme_font_override("font", MinimalThemeScript.display_font())
	MinimalThemeScript.style_secondary(credits_back_button)
	for tab in settings_tabs:
		tab.add_theme_font_override("font", MinimalThemeScript.medium_font())
		tab.add_theme_font_size_override("font_size", 12)
	_style_settings_tabs()
	exit_panel.add_theme_stylebox_override("panel", MinimalThemeScript.surface_s3(22.0))

func _style_settings_tabs() -> void:
	for index in range(settings_tabs.size()):
		var tab := settings_tabs[index]
		var selected := index == settings_tab_index
		tab.button_pressed = selected
		var accent := MinimalThemeScript.ACCENT if selected else MinimalThemeScript.CYAN
		tab.add_theme_stylebox_override("normal", MinimalThemeScript.button_style(Color(MinimalThemeScript.BG, 0.32), Color(MinimalThemeScript.BORDER, 0.56), MinimalThemeScript.RADIUS_SM))
		tab.add_theme_stylebox_override("hover", MinimalThemeScript.button_style(Color(accent, 0.10), Color(accent, 0.66), MinimalThemeScript.RADIUS_SM))
		tab.add_theme_stylebox_override("pressed", MinimalThemeScript.button_style(Color(accent, 0.16), accent, MinimalThemeScript.RADIUS_SM))
		tab.add_theme_stylebox_override("focus", MinimalThemeScript.button_style(Color(accent, 0.10), Color(accent, 0.66), MinimalThemeScript.RADIUS_SM))
		tab.add_theme_color_override("font_color", MinimalThemeScript.TEXT if selected else MinimalThemeScript.MUTED)
		for color_name in ["font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			tab.add_theme_color_override(color_name, MinimalThemeScript.TEXT)

func _set_settings_tab(index: int) -> void:
	settings_tab_index = clampi(index, 0, settings_tabs.size() - 1)
	display_settings_group.visible = settings_tab_index == 0
	audio_settings_group.visible = settings_tab_index == 1
	timing_settings_group.visible = settings_tab_index == 2
	_style_settings_tabs()
	var groups: Array[Control] = [display_settings_group, audio_settings_group, timing_settings_group]
	var active_group := groups[settings_tab_index]
	active_group.modulate.a = 0.45
	var tween := create_tween()
	tween.tween_property(active_group, "modulate:a", 1.0, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _style_tutorial_tabs() -> void:
	for index in range(tutorial_tabs.size()):
		var tab := tutorial_tabs[index]
		var selected := index == tutorial_step_index
		var accent := MinimalThemeScript.ACCENT if selected else MinimalThemeScript.CYAN
		tab.button_pressed = selected
		tab.add_theme_stylebox_override("normal", MinimalThemeScript.button_style(Color(MinimalThemeScript.SURFACE, 0.78), Color(MinimalThemeScript.BORDER, 0.88), 8))
		tab.add_theme_stylebox_override("hover", MinimalThemeScript.button_style(Color(accent, 0.12), accent, 8))
		tab.add_theme_stylebox_override("pressed", MinimalThemeScript.button_style(Color(accent, 0.18), accent, 8))
		tab.add_theme_stylebox_override("focus", MinimalThemeScript.button_style(Color(accent, 0.12), accent, 8))
		tab.add_theme_color_override("font_color", MinimalThemeScript.TEXT if selected else MinimalThemeScript.MUTED)
		for color_name in ["font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			tab.add_theme_color_override(color_name, MinimalThemeScript.TEXT)

func _style_main_menu_button(button: Button, _index: int) -> void:
	var is_primary := button == play_button
	var is_exit := button == exit_button
	var is_utility := button == help_button or button == quick_calibration_button or button == credits_button
	var accent: Color = MinimalThemeScript.ACCENT_LIGHT if is_primary else MinimalThemeScript.ACCENT
	if is_exit:
		accent = MinimalThemeScript.DANGER

	button.add_theme_font_override("font", MinimalThemeScript.mono_font() if is_utility else MinimalThemeScript.medium_font())
	button.add_theme_font_size_override("font_size", 11 if is_utility else theme_config.button_size + (6 if is_primary else 1))
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT if not is_utility else HORIZONTAL_ALIGNMENT_CENTER

	var normal_style := StyleBoxFlat.new()
	var hover_style := StyleBoxFlat.new()
	var pressed_style := StyleBoxFlat.new()
	var focus_style := StyleBoxFlat.new()

	if is_primary:
		for style in [normal_style, hover_style, pressed_style, focus_style]:
			style.set_corner_radius_all(12)
			style.content_margin_left = 54.0
			style.content_margin_right = 46.0
			style.set_border_width_all(1)
		normal_style.bg_color = Color(MinimalThemeScript.BG, 0.78)
		normal_style.border_color = Color(MinimalThemeScript.ACCENT_LIGHT, 0.72)
		hover_style.bg_color = Color(MinimalThemeScript.BG, 0.88)
		hover_style.border_color = Color(MinimalThemeScript.ACCENT_LIGHT, 0.96)
		pressed_style.bg_color = Color(MinimalThemeScript.BG, 0.94)
		pressed_style.border_color = Color(MinimalThemeScript.ACCENT_LIGHT, 1.0)
		focus_style.bg_color = Color(MinimalThemeScript.BG, 0.88)
		focus_style.border_color = Color(MinimalThemeScript.ACCENT_LIGHT, 1.0)
		button.text = "PLAY"
	elif is_utility:
		for style in [normal_style, hover_style, pressed_style, focus_style]:
			style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
			style.set_border_width_all(0)
			style.content_margin_left = 8.0
			style.content_margin_right = 8.0
		hover_style.border_width_bottom = 1
		hover_style.border_color = Color(MinimalThemeScript.ACCENT_LIGHT, 0.52)
		pressed_style.border_width_bottom = 1
		pressed_style.border_color = Color(MinimalThemeScript.ACCENT_LIGHT, 0.78)
		focus_style.border_width_bottom = 1
		focus_style.border_color = Color(MinimalThemeScript.ACCENT_LIGHT, 0.78)
	else:
		# Secondary actions are text-first rails, not stacked cards.
		for style in [normal_style, hover_style, pressed_style, focus_style]:
			style.set_corner_radius_all(4)
			style.content_margin_left = 10.0
			style.content_margin_right = 42.0
			style.border_width_bottom = 1
		normal_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
		normal_style.border_color = Color(MinimalThemeScript.TEXT, 0.16)
		hover_style.bg_color = Color(MinimalThemeScript.BG, 0.14)
		hover_style.border_color = Color(accent, 0.72)
		hover_style.border_width_bottom = 1
		pressed_style.bg_color = Color(MinimalThemeScript.BG, 0.22)
		pressed_style.border_color = Color(accent, 0.84)
		pressed_style.border_width_bottom = 2
		focus_style.bg_color = Color(MinimalThemeScript.BG, 0.18)
		focus_style.border_color = Color(accent, 0.90)
		focus_style.border_width_bottom = 2

	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", focus_style)

	var normal_color := Color(MinimalThemeScript.TEXT, 0.98 if is_primary else (0.88 if is_utility else 0.92))
	if is_exit:
		normal_color = Color(MinimalThemeScript.TEXT, 0.86)
	button.add_theme_color_override("font_color", normal_color)
	button.add_theme_color_override("font_hover_color", MinimalThemeScript.DANGER if is_exit else MinimalThemeScript.TEXT)
	button.add_theme_color_override("font_pressed_color", MinimalThemeScript.DANGER if is_exit else MinimalThemeScript.TEXT)
	button.add_theme_color_override("font_focus_color", MinimalThemeScript.DANGER if is_exit else MinimalThemeScript.TEXT)
	button.add_theme_color_override("font_hover_pressed_color", MinimalThemeScript.DANGER if is_exit else MinimalThemeScript.TEXT)

	_ensure_main_menu_action_decorations(button, is_primary, is_utility)

func _ensure_main_menu_action_decorations(button: Button, is_primary: bool, is_utility: bool) -> void:
	var glyph := button.get_node_or_null("ActionGlyph") as Label
	var chevron := button.get_node_or_null("ActionChevron") as Label

	if is_utility:
		if glyph != null:
			glyph.visible = false
		if chevron != null:
			chevron.visible = false
		return

	if chevron == null:
		chevron = Label.new()
		chevron.name = "ActionChevron"
		chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(chevron)
	chevron.visible = true
	chevron.text = "›"
	chevron.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chevron.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chevron.anchor_left = 1.0
	chevron.anchor_right = 1.0
	chevron.anchor_top = 0.5
	chevron.anchor_bottom = 0.5
	chevron.offset_left = -34.0
	chevron.offset_right = -12.0
	chevron.offset_top = -14.0
	chevron.offset_bottom = 14.0
	chevron.add_theme_font_override("font", MinimalThemeScript.medium_font())
	chevron.add_theme_font_size_override("font_size", 22 if is_primary else 18)
	chevron.add_theme_color_override("font_color", Color(MinimalThemeScript.TEXT, 0.88 if is_primary else 0.70))

	if is_primary:
		if glyph == null:
			glyph = Label.new()
			glyph.name = "ActionGlyph"
			glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(glyph)
		glyph.visible = true
		glyph.text = "◆"
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.anchor_left = 0.0
		glyph.anchor_right = 0.0
		glyph.anchor_top = 0.5
		glyph.anchor_bottom = 0.5
		glyph.offset_left = 18.0
		glyph.offset_right = 38.0
		glyph.offset_top = -12.0
		glyph.offset_bottom = 12.0
		glyph.add_theme_font_override("font", MinimalThemeScript.medium_font())
		glyph.add_theme_font_size_override("font_size", 13)
		glyph.add_theme_color_override("font_color", Color(MinimalThemeScript.ACCENT_LIGHT, 0.98))
	elif glyph != null:
		glyph.visible = false

func _setup_display_controls() -> void:
	resolution_values.clear()
	resolution_option.clear()
	var screen_index: int = DisplayServer.window_get_current_screen()
	var screen_size: Vector2i = DisplayServer.screen_get_size(screen_index)
	var saved_resolution: Vector2i = UserSettingsScript.get_resolution()
	var candidates: Array[Vector2i] = [Vector2i(960, 540), Vector2i(1024, 576), Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)]
	if screen_size.x > 0 and screen_size.y > 0 and not candidates.has(screen_size):
		candidates.append(screen_size)
	if not candidates.has(saved_resolution):
		candidates.append(saved_resolution)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i):
		return a.x * a.y < b.x * b.y
	)
	for candidate in candidates:
		var fits_screen: bool = screen_size.x <= 0 or screen_size.y <= 0 or (candidate.x <= screen_size.x and candidate.y <= screen_size.y)
		if not fits_screen and candidate != saved_resolution:
			continue
		if resolution_values.has(candidate):
			continue
		resolution_values.append(candidate)
		resolution_option.add_item("%d × %d" % [candidate.x, candidate.y])
	window_mode_option.clear()
	window_mode_option.add_item("WINDOWED")
	window_mode_option.add_item("BORDERLESS")
	window_mode_option.add_item("FULLSCREEN")
	vsync_option.clear()
	vsync_option.add_item("ON")
	vsync_option.add_item("OFF")
	input_style_option.clear()
	input_style_option.add_item("8-DIRECTION (NUMPAD)")
	input_style_option.add_item("4-DIRECTION (ARROW KEYS)")

func _select_resolution_value(value: Vector2i) -> void:
	var index: int = resolution_values.find(value)
	if index < 0:
		resolution_values.append(value)
		resolution_option.add_item("%d × %d" % [value.x, value.y])
		index = resolution_values.size() - 1
	resolution_option.select(index)

func _select_window_mode_value(mode: String) -> void:
	match mode:
		"borderless": window_mode_option.select(1)
		"fullscreen": window_mode_option.select(2)
		_: window_mode_option.select(0)

func _selected_window_mode() -> String:
	match window_mode_option.selected:
		1: return "borderless"
		2: return "fullscreen"
		_: return "windowed"

func _selected_resolution() -> Vector2i:
	var index: int = resolution_option.selected
	if index < 0 or index >= resolution_values.size():
		return UserSettingsScript.DEFAULT_RESOLUTION
	return resolution_values[index]

func _apply_display_from_controls() -> void:
	var mode: String = _selected_window_mode()
	resolution_option.disabled = mode != "windowed"
	var applied: bool = UserSettingsScript.set_display_settings(_selected_resolution(), mode, vsync_option.selected == 0)
	_update_display_hint(applied)
	if applied:
		await get_tree().process_frame
		_apply_layout_config()
		_update_display_hint(true)

func _update_display_hint(_applied: bool) -> void:
	if display_hint == null:
		return
	display_hint.visible = false
	display_hint.text = ""
	display_hint.remove_theme_color_override("font_color")

func _on_resolution_selected(_index: int) -> void:
	_apply_display_from_controls()

func _on_input_style_selected(index: int) -> void:
	UserSettingsScript.set_input_style("4_arrow" if index == 1 else "8_direction")
	_refresh_tutorial_input_style_controls()
	if tutorial_visual != null:
		tutorial_visual.queue_redraw()

func _on_window_mode_selected(_index: int) -> void:
	_apply_display_from_controls()

func _on_vsync_selected(_index: int) -> void:
	_apply_display_from_controls()

func _setup_launch_splash_style() -> void:
	var mono_font := MinimalThemeScript.mono_font()
	if mono_font != null:
		splash_welcome.add_theme_font_override("font", mono_font)
		splash_glyphs.add_theme_font_override("font", mono_font)
	splash_welcome.add_theme_color_override("font_color", Color(MinimalThemeScript.TEXT, 0.72))
	splash_glyphs.add_theme_color_override("font_color", Color(MinimalThemeScript.TEXT, 0.92))

func _run_splash() -> void:
	# v18.3: single-mark boot. No welcome copy, no glyph prelude, no halo stage.
	# The Beat UP! wordmark is revealed left→right, held briefly, then erased
	# right→left before the Main Menu appears.
	await get_tree().process_frame
	if splash_finished:
		return
	_refresh_pivots()
	splash.visible = true
	splash.modulate.a = 1.0
	splash_black.modulate.a = 1.0
	splash_welcome.visible = false
	splash_glyphs.visible = false
	splash_halo_outer.visible = false
	splash_halo_inner.visible = false
	splash_wipe.visible = false
	splash_logo_frame.scale = Vector2.ONE
	splash_logo_window.modulate.a = 1.0
	splash_logo_window.position = Vector2.ZERO
	_set_splash_logo_reveal(0.0)
	if active_tween != null:
		active_tween.kill()
	active_tween = create_tween()
	active_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	active_tween.tween_method(Callable(self, "_set_splash_logo_reveal"), 0.0, splash_logo_frame.size.x, 0.58).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	active_tween.tween_interval(0.44)
	active_tween.tween_method(Callable(self, "_set_splash_logo_reveal"), splash_logo_frame.size.x, 0.0, 0.42).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	active_tween.tween_callback(Callable(self, "_begin_main_menu_under_splash"))
	active_tween.tween_interval(0.06)
	active_tween.tween_callback(Callable(self, "_finish_launch_flow"))

func _set_splash_logo_reveal(width: float) -> void:
	if splash_logo_frame == null or splash_logo_window == null:
		return
	var reveal_width: float = clampf(width, 0.0, splash_logo_frame.size.x)
	splash_logo_window.position = Vector2.ZERO
	splash_logo_window.size = Vector2(reveal_width, splash_logo_frame.size.y)

func _launch_logo_stage() -> void:

	if splash_finished:
		return
	var logo_tween := create_tween()
	logo_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	logo_tween.set_parallel(true)
	logo_tween.tween_property(splash_halo_outer, "modulate:a", 1.0, 0.20).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	logo_tween.tween_property(splash_halo_outer, "scale", Vector2.ONE, 0.50).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	logo_tween.tween_property(splash_halo_inner, "modulate:a", 1.0, 0.18).set_delay(0.06)
	logo_tween.tween_property(splash_halo_inner, "scale", Vector2.ONE, 0.44).set_delay(0.04).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	logo_tween.tween_property(splash_logo_window, "modulate:a", 1.0, 0.18).set_delay(0.10).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	logo_tween.tween_property(splash_logo_frame, "scale", Vector2.ONE, 0.42).set_delay(0.06).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

func _begin_main_menu_under_splash() -> void:
	if splash_finished:
		return
	# Reveal the destination behind the launch logo so there is no black cut.
	settings_menu.visible = false
	calibration_screen.visible = false
	help_screen.visible = false
	credits_screen.visible = false
	exit_dialog.visible = false
	main_menu.visible = true
	menu_background.modulate = Color.WHITE
	menu_background.scale = Vector2.ONE
	_ensure_main_menu_music_ready(0.24)
	_update_now_playing_card()
	_refresh_pivots()
	var restored_button: Button = _main_menu_button_for_index(_get_main_menu_focus_index())
	_update_menu_selection(restored_button)
	menu_visual.modulate.a = 0.0
	orb_cluster.modulate.a = 0.0
	orb_cluster.scale = Vector2.ONE * 0.88
	now_playing_card.modulate.a = 0.0
	now_playing_card.scale = Vector2(0.96, 0.96)
	selection_description.modulate.a = 0.0
	menu_title.modulate.a = 0.0
	menu_title.scale = Vector2(0.96, 1.0)
	menu_rule.modulate.a = 0.0
	main_footer.modulate.a = 0.0
	for button in menu_buttons:
		button.disabled = true
		button.modulate.a = 0.0
		button.scale = Vector2(0.94, 1.0)
	if launch_menu_tween != null:
		launch_menu_tween.kill()
	launch_menu_tween = create_tween()
	launch_menu_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	launch_menu_tween.set_parallel(true)
	launch_menu_tween.tween_property(menu_visual, "modulate:a", 1.0, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	launch_menu_tween.tween_property(orb_cluster, "modulate:a", 1.0, 0.30).set_delay(0.06)
	launch_menu_tween.tween_property(orb_cluster, "scale", Vector2.ONE, 0.38).set_delay(0.04).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	launch_menu_tween.tween_property(now_playing_card, "modulate:a", 1.0, 0.24).set_delay(0.04)
	launch_menu_tween.tween_property(now_playing_card, "scale", Vector2.ONE, 0.28).set_delay(0.04).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	launch_menu_tween.tween_property(menu_title, "modulate:a", 1.0, 0.24).set_delay(0.08)
	launch_menu_tween.tween_property(menu_title, "scale", Vector2.ONE, 0.30).set_delay(0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	launch_menu_tween.tween_property(menu_rule, "modulate:a", 1.0, 0.22).set_delay(0.15)
	launch_menu_tween.tween_property(selection_description, "modulate:a", 0.0, 0.01).set_delay(0.0)
	launch_menu_tween.tween_property(main_footer, "modulate:a", 0.0, 0.01).set_delay(0.0)
	for i in range(menu_buttons.size()):
		var button: Button = menu_buttons[i]
		launch_menu_tween.tween_property(button, "modulate:a", 1.0, 0.20).set_delay(0.13 + float(i) * 0.035)
		launch_menu_tween.tween_property(button, "scale", Vector2.ONE, 0.26).set_delay(0.13 + float(i) * 0.035).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

func _finish_launch_flow() -> void:
	if splash_finished:
		return
	splash_finished = true
	_mark_launch_splash_seen()
	splash.visible = false
	splash_black.modulate.a = 1.0
	for button in menu_buttons:
		button.disabled = false
	call_deferred("_after_main_menu_reveal")

func _finish_splash() -> void:
	# Retained as a compatibility hook for old scene/test calls.
	_finish_launch_flow()

func _randomize_main_menu_background(force: bool = false) -> void:
	if main_menu_background_controller != null:
		main_menu_background_controller.call("randomize", force)

func _animate_main_menu_background_visit() -> void:
	if main_menu_background_controller != null:
		main_menu_background_controller.call("animate_visit")

func _show_main_menu_immediate(preserve_music_state: bool = false) -> void:
	if not is_visible_in_tree():
		return
	splash.visible = false
	settings_menu.visible = false
	calibration_screen.visible = false
	help_screen.visible = false
	credits_screen.visible = false
	exit_dialog.visible = false
	main_menu.visible = true
	if not preserve_music_state:
		_ensure_main_menu_music_ready(0.18)
	_update_now_playing_card()
	_refresh_pivots()
	var restored_button: Button = _main_menu_button_for_index(_get_main_menu_focus_index())
	_update_menu_selection(restored_button)
	menu_visual.modulate.a = 1.0
	orb_cluster.modulate.a = 1.0
	orb_cluster.scale = Vector2.ONE
	now_playing_card.modulate.a = 1.0
	now_playing_card.scale = Vector2.ONE
	selection_description.modulate.a = 0.0
	background_info.modulate.a = 0.0
	menu_version.modulate.a = 0.0
	menu_title.modulate.a = 1.0
	menu_title.scale = Vector2.ONE
	menu_rule.modulate.a = 1.0
	main_footer.modulate.a = 1.0
	for button in menu_buttons:
		button.disabled = false
		button.modulate.a = 1.0
		button.scale = Vector2.ONE
	call_deferred("_after_main_menu_reveal")

func _show_main_menu() -> void:
	var session_state: Dictionary = menu_bgm.get_music_state()
	var session_source: String = str(session_state.get("source", ""))
	if session_source == "song_library":
		_sync_main_menu_from_music_session()
	else:
		_randomize_main_menu_background(false)
	splash.visible = false
	settings_menu.visible = false
	calibration_screen.visible = false
	help_screen.visible = false
	credits_screen.visible = false
	exit_dialog.visible = false
	main_menu.visible = true
	_animate_main_menu_background_visit()
	if session_source != "song_library":
		menu_bgm.set_music_paused(false)
	_ensure_main_menu_music_ready(0.18)
	_update_now_playing_card()
	_refresh_pivots()
	var restored_button: Button = _main_menu_button_for_index(_get_main_menu_focus_index())
	_update_menu_selection(restored_button)
	menu_visual.modulate.a = 0.0
	orb_cluster.modulate.a = 0.0
	orb_cluster.scale = Vector2.ONE * 0.82
	now_playing_card.modulate.a = 0.0
	now_playing_card.scale = Vector2(0.96, 0.96)
	selection_description.modulate.a = 0.0
	background_info.modulate.a = 0.0
	menu_version.modulate.a = 0.0
	menu_title.scale = Vector2(0.96, 1.0)
	for item in [menu_title, menu_rule, main_footer]:
		item.modulate.a = 0.0
	for button in menu_buttons:
		button.modulate.a = 0.0
		button.scale = Vector2(0.92, 1.0)
	if active_tween != null:
		active_tween.kill()
	active_tween = create_tween()
	active_tween.set_parallel(true)
	active_tween.tween_property(menu_visual, "modulate:a", 1.0, 0.30)
	active_tween.tween_property(orb_cluster, "modulate:a", 1.0, 0.34)
	active_tween.tween_property(orb_cluster, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(now_playing_card, "modulate:a", 1.0, 0.24).set_delay(0.04)
	active_tween.tween_property(now_playing_card, "scale", Vector2.ONE, 0.28).set_delay(0.04).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(selection_description, "modulate:a", 0.0, 0.01).set_delay(0.0)
	active_tween.tween_property(background_info, "modulate:a", 0.0, 0.01).set_delay(0.0)
	active_tween.tween_property(menu_version, "modulate:a", 0.0, 0.01).set_delay(0.0)
	active_tween.tween_property(menu_title, "modulate:a", 1.0, 0.24).set_delay(0.06)
	active_tween.tween_property(menu_title, "scale", Vector2.ONE, 0.30).set_delay(0.06).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(menu_rule, "modulate:a", 1.0, 0.22).set_delay(0.16)
	active_tween.tween_property(main_footer, "modulate:a", 1.0, 0.22).set_delay(0.20)
	for i in range(menu_buttons.size()):
		var button: Button = menu_buttons[i]
		active_tween.tween_property(button, "modulate:a", 1.0, 0.22).set_delay(0.14 + float(i) * 0.045)
		active_tween.tween_property(button, "scale", Vector2.ONE, 0.26).set_delay(0.14 + float(i) * 0.045).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	active_tween.chain().tween_callback(Callable(self, "_after_main_menu_reveal"))

func _after_main_menu_reveal() -> void:
	if not is_visible_in_tree() or in_transition:
		return
	if first_run_tutorial_pending:
		first_run_tutorial_pending = false
		_open_tutorial(true)
		return
	_focus_default_menu_button()

func _focus_default_menu_button() -> void:
	if main_menu_controller != null:
		main_menu_controller.call("focus_default")

func _main_menu_button_for_index(index: int) -> Button:
	if main_menu_controller != null:
		return main_menu_controller.call("button_for_index", index) as Button
	return play_button

func _remember_main_menu_focus(button: Button) -> void:
	if main_menu_controller != null:
		main_menu_controller.call("remember_focus", button)

func _update_menu_selection(button: Button) -> void:
	if main_menu_controller != null:
		main_menu_controller.call("update_selection", button)

func _on_menu_button_highlight(button: Button) -> void:
	if main_menu_controller != null:
		main_menu_controller.call("highlight", button, in_transition)

func _on_menu_button_unhighlight(button: Button) -> void:
	if main_menu_controller != null:
		main_menu_controller.call("unhighlight", button)

func _show_settings() -> void:
	settings_menu.visible = true
	_set_settings_tab(settings_tab_index)
	_refresh_pivots()
	settings_dim.modulate.a = 0.0
	settings_panel.modulate.a = 0.0
	settings_panel.scale = Vector2.ONE * 0.94
	if settings_tween != null:
		settings_tween.kill()
	settings_tween = create_tween()
	settings_tween.set_parallel(true)
	settings_tween.tween_property(settings_dim, "modulate:a", 1.0, menu_fade_duration)
	settings_tween.tween_property(settings_panel, "modulate:a", 1.0, menu_fade_duration)
	settings_tween.tween_property(settings_panel, "scale", Vector2.ONE, menu_fade_duration).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	settings_tween.tween_property(orb_cluster, "scale", Vector2.ONE * 0.96, menu_fade_duration)
	settings_tabs[settings_tab_index].grab_focus()

func _hide_settings() -> void:
	if not settings_menu.visible:
		return
	if settings_tween != null:
		settings_tween.kill()
	settings_tween = create_tween()
	settings_tween.set_parallel(true)
	settings_tween.tween_property(settings_dim, "modulate:a", 0.0, menu_fade_duration * 0.75)
	settings_tween.tween_property(settings_panel, "modulate:a", 0.0, menu_fade_duration * 0.75)
	settings_tween.tween_property(settings_panel, "scale", Vector2.ONE * 0.95, menu_fade_duration * 0.75)
	settings_tween.tween_property(orb_cluster, "scale", Vector2.ONE, menu_fade_duration * 0.75)
	await settings_tween.finished
	settings_menu.visible = false

func _show_calibration() -> void:
	menu_bgm.fade_out(0.20)
	await _hide_settings()
	calibration_screen.call("open")

func _developer_shortcuts_available() -> bool:
	return OS.has_feature("editor") or OS.has_feature("debug")

func _input(event: InputEvent) -> void:
	# v17.4.21.5: do not let ESC / keyboard input race an active scene
	# transition. The transition manager also blocks globally; this local guard
	# keeps Startup atomic even if input dispatch order changes.
	if in_transition or SceneTransition.is_transitioning():
		if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
			get_viewport().set_input_as_handled()
		return
	if _developer_shortcuts_available() and result_debug_shortcut_enabled and event is InputEventKey:
		var debug_key: InputEventKey = event as InputEventKey
		if debug_key.pressed and not debug_key.echo and (debug_key.keycode == KEY_F4 or debug_key.physical_keycode == KEY_F4):
			get_tree().set_meta(RESULT_DEBUG_REQUEST_META, true)
			get_viewport().set_input_as_handled()
			SceneTransition.change_scene("res://main.tscn", "PREPARING RESULTS")
			return

	if splash.visible:
		return
	if calibration_screen.visible:
		return
	if exit_dialog.visible and event is InputEventKey:
		var exit_key: InputEventKey = event as InputEventKey
		if exit_key.pressed and not exit_key.echo and exit_key.keycode == KEY_ESCAPE:
			_cancel_exit()
			get_viewport().set_input_as_handled()
		return
	if help_screen.visible and event is InputEventKey:
		var tutorial_key: InputEventKey = event as InputEventKey
		if tutorial_key.pressed and not tutorial_key.echo:
			if tutorial_key.keycode == KEY_ESCAPE:
				_return_to_main_menu()
				get_viewport().set_input_as_handled()
				return
			# In 4-Direction mode, arrow keys are gameplay inputs and must reach the
			# tutorial visual. Only use Left/Right as page shortcuts in 8-Direction
			# Numpad mode, where they cannot conflict with note input.
			var arrow_input_mode := UserSettingsScript.get_input_style() == "4_arrow"
			if not arrow_input_mode and tutorial_key.keycode == KEY_LEFT:
				_on_tutorial_previous_pressed()
				get_viewport().set_input_as_handled()
				return
			if not arrow_input_mode and tutorial_key.keycode == KEY_RIGHT and tutorial_step_index < TUTORIAL_STEPS.size() - 1:
				_set_tutorial_step(tutorial_step_index + 1)
				get_viewport().set_input_as_handled()
				return
			if tutorial_visual.handle_input(event):
				get_viewport().set_input_as_handled()
				return
		return
	if credits_screen.visible and event is InputEventKey:
		var credits_key: InputEventKey = event as InputEventKey
		if credits_key.pressed and not credits_key.echo and credits_key.keycode == KEY_ESCAPE:
			_return_to_main_menu()
			get_viewport().set_input_as_handled()
		return
	if settings_menu.visible and event is InputEventKey and not v18_binding_capture_action.is_empty():
		var capture_key: InputEventKey = event as InputEventKey
		if capture_key.pressed and not capture_key.echo:
			_handle_v18_binding_capture(capture_key)
			get_viewport().set_input_as_handled()
		return
	if settings_menu.visible and event is InputEventKey:
		var settings_key: InputEventKey = event as InputEventKey
		if settings_key.pressed and not settings_key.echo and settings_key.keycode == KEY_ESCAPE:
			_on_back_pressed()
			get_viewport().set_input_as_handled()
		return
	if main_menu.visible and event is InputEventKey:
		var menu_key: InputEventKey = event as InputEventKey
		if menu_key.pressed and not menu_key.echo and (menu_key.keycode == KEY_KP_5 or menu_key.physical_keycode == KEY_KP_5):
			_on_play_pressed()
			get_viewport().set_input_as_handled()
		elif menu_key.pressed and not menu_key.echo and menu_key.keycode == KEY_ESCAPE:
			_on_exit_pressed()
			get_viewport().set_input_as_handled()

func _on_play_pressed() -> void:
	_remember_main_menu_focus(play_button)
	# v17.4.21.1 revision 2: browsing songs no longer boots the complete
	# gameplay scene. The lightweight Song Library loads first; gameplay is only
	# instantiated after PLAY SONG.
	_transition_to_scene("res://scenes/song_library.tscn")

func _on_chart_studio_pressed() -> void:
	_remember_main_menu_focus(chart_studio_button)
	_transition_to_scene("res://scenes/chart_editor.tscn", "OPENING CHART STUDIO")

func _on_settings_pressed() -> void:
	_remember_main_menu_focus(settings_button)
	_show_settings()

func _on_quick_calibration_pressed() -> void:
	if in_transition:
		return
	_remember_main_menu_focus(quick_calibration_button)
	calibration_returns_to_settings = false
	menu_bgm.fade_out(0.20)
	main_menu.visible = false
	calibration_screen.call("open")

func _on_help_pressed() -> void:
	_remember_main_menu_focus(help_button)
	_open_tutorial(false)

func _open_tutorial(from_first_run: bool) -> void:
	if from_first_run:
		_set_main_menu_focus_index(0)
	main_menu.visible = false
	help_screen.visible = true
	help_screen.modulate.a = 0.0
	tutorial_opened_from_first_run = from_first_run
	# Opening the tutorial is enough to suppress repeat auto-opening. The player
	# can still revisit HOW TO PLAY from the Main Menu at any time.
	UserSettingsScript.mark_first_run_tutorial_seen()
	tutorial_eyebrow.text = "FIRST RUN TRAINING" if from_first_run else "TRAINING"
	help_back_button.text = "Skip tutorial" if from_first_run else "← Back"
	_set_tutorial_step(0, false)
	_refresh_tutorial_input_style_controls()
	if tutorial_tween != null:
		tutorial_tween.kill()
	tutorial_tween = create_tween()
	tutorial_tween.tween_property(help_screen, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tutorial_button.grab_focus()

func _on_tutorial_input_style_selected(style: String) -> void:
	UserSettingsScript.set_input_style(style)
	input_style_option.select(1 if style == "4_arrow" else 0)
	_refresh_tutorial_input_style_controls()
	if tutorial_visual != null:
		if tutorial_visual.get_step() == TUTORIAL_STEPS.size() - 1:
			tutorial_visual.reset_practice()
		tutorial_visual.queue_redraw()

func _refresh_tutorial_input_style_controls() -> void:
	if tutorial_numpad_button == null or tutorial_arrow_button == null:
		return
	var style := UserSettingsScript.get_input_style()
	var numpad_selected := style == "8_direction"
	tutorial_numpad_button.button_pressed = numpad_selected
	tutorial_arrow_button.button_pressed = not numpad_selected
	tutorial_input_style_status.text = "CURRENT · 8-DIRECTION NUMPAD · RECOMMENDED" if numpad_selected else "CURRENT · 4-DIRECTION ARROWS · FALLBACK"
	_apply_tutorial_input_button_style(tutorial_numpad_button, numpad_selected)
	_apply_tutorial_input_button_style(tutorial_arrow_button, not numpad_selected)

func _apply_tutorial_input_button_style(button: Button, selected: bool) -> void:
	var accent: Color = MinimalThemeScript.PINK if selected else MinimalThemeScript.CYAN
	var normal_fill_alpha: float = 0.16 if selected else 0.05
	var normal_border: Color = accent if selected else MinimalThemeScript.BORDER
	button.add_theme_stylebox_override("normal", MinimalThemeScript.button_style(Color(accent, normal_fill_alpha), normal_border, 7))
	button.add_theme_stylebox_override("hover", MinimalThemeScript.button_style(Color(accent, 0.14), accent, 7))
	button.add_theme_stylebox_override("pressed", MinimalThemeScript.button_style(Color(accent, 0.20), accent, 7))
	button.add_theme_stylebox_override("focus", MinimalThemeScript.button_style(Color(accent, 0.10), Color(accent, 0.66), MinimalThemeScript.RADIUS_SM))
	button.add_theme_color_override("font_color", MinimalThemeScript.TEXT if selected else MinimalThemeScript.MUTED)
	for color_name in ["font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(color_name, MinimalThemeScript.TEXT)

func _tutorial_practice_tip() -> String:
	return "PRACTICE · Read each cue. Red = opposite direction. Gold = Space."

func _set_tutorial_step(index: int, animate := true) -> void:
	tutorial_step_index = clampi(index, 0, TUTORIAL_STEPS.size() - 1)
	var step_data: Dictionary = TUTORIAL_STEPS[tutorial_step_index]
	tutorial_kicker.text = str(step_data["kicker"])
	tutorial_heading.text = str(step_data["title"])
	tutorial_description.text = str(step_data["body"])
	tutorial_tip.text = str(step_data["tip"])
	var dot_parts: PackedStringArray = []
	for dot_index in range(TUTORIAL_STEPS.size()):
		dot_parts.append("●" if dot_index == tutorial_step_index else "○")
	tutorial_step_dots.text = "  ".join(dot_parts)
	tutorial_previous_button.disabled = tutorial_step_index == 0
	tutorial_button.text = "Next →" if tutorial_step_index < TUTORIAL_STEPS.size() - 1 else "Restart practice"
	tutorial_input_style_block.visible = tutorial_step_index == 0
	tutorial_visual.set_step(tutorial_step_index)
	_refresh_tutorial_input_style_controls()
	_style_tutorial_tabs()
	if not animate:
		tutorial_copy_panel.modulate.a = 1.0
		tutorial_visual_panel.modulate.a = 1.0
		return
	if tutorial_tween != null:
		tutorial_tween.kill()
	tutorial_copy_panel.modulate.a = 0.52
	tutorial_visual_panel.modulate.a = 0.52
	tutorial_tween = create_tween()
	tutorial_tween.set_parallel(true)
	tutorial_tween.tween_property(tutorial_copy_panel, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tutorial_tween.tween_property(tutorial_visual_panel, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_tutorial_previous_pressed() -> void:
	if tutorial_step_index > 0:
		_set_tutorial_step(tutorial_step_index - 1)

func _on_tutorial_next_pressed() -> void:
	if tutorial_step_index < TUTORIAL_STEPS.size() - 1:
		_set_tutorial_step(tutorial_step_index + 1)
		return
	var progress := tutorial_visual.get_practice_progress()
	if bool(progress.get("finished", false)):
		_on_play_pressed()
	else:
		tutorial_visual.reset_practice()
		tutorial_tip.text = _tutorial_practice_tip()

func _on_tutorial_practice_updated(hits: int, total: int, judgement: String) -> void:
	if tutorial_step_index != TUTORIAL_STEPS.size() - 1:
		return
	tutorial_tip.text = "PRACTICE · %02d / %02d HITS · %s · RED=OPPOSITE · GOLD=SPACE" % [hits, total, judgement]
	if not bool(tutorial_visual.get_practice_progress().get("finished", false)):
		tutorial_button.text = "Restart practice"

func _on_tutorial_practice_completed(hits: int, total: int) -> void:
	if tutorial_step_index != TUTORIAL_STEPS.size() - 1:
		return
	tutorial_tip.text = "COMPLETE · %02d / %02d HITS · READY FOR A SONG" % [hits, total]
	tutorial_button.text = "Play a song →"
	tutorial_button.grab_focus()

func _on_credits_pressed() -> void:
	_remember_main_menu_focus(credits_button)
	main_menu.visible = false
	credits_screen.visible = true
	credits_screen.modulate.a = 0.0
	credits_info_panel.modulate.a = 0.0
	credits_visual_panel.modulate.a = 0.0
	credits_orbit.rotation = -0.08
	var tween := create_tween().set_parallel(true)
	tween.tween_property(credits_screen, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(credits_info_panel, "modulate:a", 1.0, 0.28).set_delay(0.03)
	tween.tween_property(credits_visual_panel, "modulate:a", 1.0, 0.32).set_delay(0.07)
	tween.tween_property(credits_orbit, "rotation", 0.0, 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	credits_back_button.grab_focus()

func _return_to_main_menu() -> void:
	_show_main_menu()

func _on_exit_pressed() -> void:
	if in_transition:
		return
	_remember_main_menu_focus(exit_button)
	if exit_dialog_tween != null:
		exit_dialog_tween.kill()
	exit_dialog.visible = true
	exit_dim.modulate.a = 0.0
	exit_panel.modulate.a = 0.0
	exit_panel.scale = Vector2.ONE * 0.94
	exit_panel.pivot_offset = exit_panel.size * 0.5
	exit_power_icon.modulate.a = 0.0
	exit_power_icon.scale = Vector2.ONE * 0.78
	exit_power_icon.set_active(true)
	exit_dialog_tween = create_tween().set_parallel(true)
	exit_dialog_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	exit_dialog_tween.tween_property(exit_dim, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	exit_dialog_tween.tween_property(exit_panel, "modulate:a", 1.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	exit_dialog_tween.tween_property(exit_panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	exit_dialog_tween.tween_property(exit_power_icon, "modulate:a", 1.0, 0.18).set_delay(0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	exit_dialog_tween.tween_property(exit_power_icon, "scale", Vector2.ONE, 0.28).set_delay(0.02).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	exit_dialog_tween.finished.connect(exit_cancel_button.grab_focus)

func _cancel_exit() -> void:
	if not exit_dialog.visible:
		return
	if exit_dialog_tween != null:
		exit_dialog_tween.kill()
	exit_dialog_tween = create_tween().set_parallel(true)
	exit_dialog_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	exit_dialog_tween.tween_property(exit_dim, "modulate:a", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	exit_dialog_tween.tween_property(exit_panel, "modulate:a", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	exit_dialog_tween.tween_property(exit_panel, "scale", Vector2.ONE * 0.96, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	exit_dialog_tween.tween_property(exit_power_icon, "modulate:a", 0.0, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	exit_dialog_tween.chain().tween_callback(_finish_cancel_exit)

func _finish_cancel_exit() -> void:
	exit_dialog.visible = false
	exit_power_icon.set_active(false)
	exit_power_icon.modulate.a = 1.0
	exit_power_icon.scale = Vector2.ONE
	_remember_main_menu_focus(exit_button)
	exit_button.grab_focus()
	_update_menu_selection(exit_button)

func _confirm_exit() -> void:
	if in_transition:
		return
	in_transition = true
	menu_bgm.fade_out(0.18)
	var tween := create_tween()
	tween.tween_property(transition_overlay, "modulate:a", 1.0, 0.18)
	await tween.finished
	get_tree().quit()

func _on_back_pressed() -> void:
	_save_settings()
	await _hide_settings()
	_remember_main_menu_focus(settings_button)
	settings_button.grab_focus()
	_update_menu_selection(settings_button)

func _on_calibration_pressed() -> void:
	calibration_returns_to_settings = true
	_show_calibration()

func _on_calibration_back_requested() -> void:
	_load_settings()
	calibration_screen.call("close")
	menu_bgm.start_menu_music(0.32)
	if calibration_returns_to_settings:
		_remember_main_menu_focus(settings_button)
		_show_settings()
		call_deferred("_focus_calibration_return")
	else:
		_remember_main_menu_focus(quick_calibration_button)
		_show_main_menu()

func _focus_calibration_return() -> void:
	if settings_menu.visible and calibration_button.visible and not calibration_button.disabled:
		calibration_button.grab_focus()

func _on_calibration_applied(_input_offset_ms: float, _audio_offset_ms: float) -> void:
	_load_settings()

func _on_master_volume_changed(value: float) -> void:
	UserSettingsScript.set_master_volume(value)
	master_value.text = "%d%%" % roundi(value)

func _on_menu_sfx_volume_changed(value: float) -> void:
	UserSettingsScript.set_menu_sfx_volume(value)
	menu_sfx_value.text = "%d%%" % roundi(value)

func _on_menu_sfx_toggled(enabled: bool) -> void:
	UserSettingsScript.set_menu_sfx_enabled(enabled)
	menu_sfx_slider.editable = enabled
	menu_sfx_value.modulate.a = 1.0 if enabled else 0.38

func _on_background_opacity_changed(value: float) -> void:
	UserSettingsScript.set_background_opacity(value)
	background_value.text = "%d%%" % roundi(value)

func _on_input_offset_changed(value: float) -> void:
	UserSettingsScript.set_input_offset_ms(value)
	_update_timing_labels()

func _on_audio_offset_changed(value: float) -> void:
	UserSettingsScript.set_audio_offset_ms(value)
	_update_timing_labels()

func _build_v18_settings_controls() -> void:
	if timing_settings_group == null or v18_effect_intensity_slider != null:
		return
	var separator := HSeparator.new()
	separator.custom_minimum_size = Vector2(0.0, 8.0)
	timing_settings_group.add_child(separator)

	var effects_title := Label.new()
	effects_title.text = "GAMEPLAY FEEDBACK"
	effects_title.tooltip_text = "Adjust visual hit-feedback intensity. Timing windows and scoring are never changed."
	MinimalThemeScript.apply_mono(effects_title, 11, MinimalThemeScript.CYAN)
	timing_settings_group.add_child(effects_title)

	var effects_row := HBoxContainer.new()
	effects_row.add_theme_constant_override("separation", 12)
	timing_settings_group.add_child(effects_row)
	var effects_label := Label.new()
	effects_label.text = "Effect Intensity"
	effects_label.custom_minimum_size = Vector2(180.0, 0.0)
	effects_label.tooltip_text = "Scales hit burst, pulse, and receptor animation. Judgement text remains readable at 0%."
	effects_row.add_child(effects_label)
	v18_effect_intensity_slider = HSlider.new()
	v18_effect_intensity_slider.min_value = 0.0
	v18_effect_intensity_slider.max_value = 100.0
	v18_effect_intensity_slider.step = 5.0
	v18_effect_intensity_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v18_effect_intensity_slider.tooltip_text = effects_label.tooltip_text
	v18_effect_intensity_slider.value_changed.connect(_on_v18_effect_intensity_changed)
	effects_row.add_child(v18_effect_intensity_slider)
	v18_effect_intensity_value = Label.new()
	v18_effect_intensity_value.custom_minimum_size = Vector2(58.0, 0.0)
	v18_effect_intensity_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	effects_row.add_child(v18_effect_intensity_value)

	var controls_title := Label.new()
	controls_title.text = "CUSTOM GAMEPLAY KEYS"
	controls_title.tooltip_text = "Click a binding, then press a new key. Duplicate gameplay keys are rejected."
	MinimalThemeScript.apply_mono(controls_title, 11, MinimalThemeScript.CYAN)
	timing_settings_group.add_child(controls_title)
	v18_binding_hint = Label.new()
	v18_binding_hint.text = "Bindings are shared by gameplay, Practice, and Replay validation."
	v18_binding_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v18_binding_hint.add_theme_color_override("font_color", MinimalThemeScript.MUTED)
	timing_settings_group.add_child(v18_binding_hint)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 6)
	timing_settings_group.add_child(grid)
	var binding_rows: Array[Dictionary] = [
		{"action": "8k_1", "label": "Numpad 1"},
		{"action": "8k_2", "label": "Numpad 2"},
		{"action": "8k_3", "label": "Numpad 3"},
		{"action": "8k_4", "label": "Numpad 4"},
		{"action": "8k_6", "label": "Numpad 6"},
		{"action": "8k_7", "label": "Numpad 7"},
		{"action": "8k_8", "label": "Numpad 8"},
		{"action": "8k_9", "label": "Numpad 9"},
		{"action": "4k_left", "label": "Left"},
		{"action": "4k_up", "label": "Up"},
		{"action": "4k_right", "label": "Right"},
		{"action": "4k_down", "label": "Down"},
		{"action": "space", "label": "SPACE"},
	]
	for row: Dictionary in binding_rows:
		var action: String = str(row.get("action", ""))
		var label := Label.new()
		label.text = str(row.get("label", action))
		grid.add_child(label)
		var button := Button.new()
		button.custom_minimum_size = Vector2(180.0, 32.0)
		button.tooltip_text = "Click, then press the key you want to assign."
		button.pressed.connect(_begin_v18_binding_capture.bind(action))
		grid.add_child(button)
		v18_binding_buttons[action] = button

	var reset_bindings := Button.new()
	reset_bindings.text = "RESET KEY BINDINGS"
	reset_bindings.tooltip_text = "Restore default Numpad, Arrow, and Space controls."
	reset_bindings.pressed.connect(_reset_v18_bindings)
	timing_settings_group.add_child(reset_bindings)

func _on_v18_effect_intensity_changed(value: float) -> void:
	UserSettingsScript.set_effect_intensity(value)
	if v18_effect_intensity_value != null:
		v18_effect_intensity_value.text = "%d%%" % roundi(value)

func _begin_v18_binding_capture(action: String) -> void:
	v18_binding_capture_action = action
	var button: Button = v18_binding_buttons.get(action) as Button
	if button != null:
		button.text = "PRESS A KEY…"
	if v18_binding_hint != null:
		v18_binding_hint.text = "Press a key for %s · ESC cancels." % action.to_upper()

func _handle_v18_binding_capture(event: InputEventKey) -> void:
	var action: String = v18_binding_capture_action
	v18_binding_capture_action = ""
	if event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
		_refresh_v18_binding_buttons()
		if v18_binding_hint != null:
			v18_binding_hint.text = "Binding change cancelled."
		return
	var keycode: int = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
	if not UserSettingsScript.set_gameplay_binding(action, keycode):
		if v18_binding_hint != null:
			v18_binding_hint.text = "That key is already used by another gameplay action."
	else:
		if v18_binding_hint != null:
			v18_binding_hint.text = "%s → %s" % [action.to_upper(), UserSettingsScript.gameplay_binding_label(action)]
	_refresh_v18_binding_buttons()

func _refresh_v18_binding_buttons() -> void:
	for action_value: Variant in v18_binding_buttons.keys():
		var action: String = str(action_value)
		var button: Button = v18_binding_buttons[action] as Button
		if button != null:
			button.text = UserSettingsScript.gameplay_binding_label(action)

func _reset_v18_bindings() -> void:
	UserSettingsScript.reset_gameplay_bindings()
	v18_binding_capture_action = ""
	_refresh_v18_binding_buttons()
	if v18_binding_hint != null:
		v18_binding_hint.text = "Default gameplay bindings restored."

func _load_settings() -> void:
	var master_volume := UserSettingsScript.get_master_volume()
	var sfx_value := UserSettingsScript.get_menu_sfx_volume()
	var sfx_enabled := UserSettingsScript.get_menu_sfx_enabled()
	var bg_value := UserSettingsScript.get_background_opacity()
	var effect_value: float = UserSettingsScript.get_effect_intensity()
	var input_value := UserSettingsScript.get_input_offset_ms()
	var audio_value := UserSettingsScript.get_audio_offset_ms()
	var resolution_value: Vector2i = UserSettingsScript.get_resolution()
	var window_mode_value: String = UserSettingsScript.get_window_mode()
	var vsync_value: bool = UserSettingsScript.get_vsync_enabled()
	var input_style_value: String = UserSettingsScript.get_input_style()
	_select_resolution_value(resolution_value)
	_select_window_mode_value(window_mode_value)
	vsync_option.select(0 if vsync_value else 1)
	input_style_option.select(1 if input_style_value == "4_arrow" else 0)
	resolution_option.disabled = window_mode_value != "windowed"
	master_slider.set_value_no_signal(master_volume)
	menu_sfx_slider.set_value_no_signal(sfx_value)
	menu_sfx_toggle.set_pressed_no_signal(sfx_enabled)
	menu_sfx_slider.editable = sfx_enabled
	bg_opacity_slider.set_value_no_signal(bg_value)
	if v18_effect_intensity_slider != null:
		v18_effect_intensity_slider.set_value_no_signal(effect_value)
	if v18_effect_intensity_value != null:
		v18_effect_intensity_value.text = "%d%%" % roundi(effect_value)
	_refresh_v18_binding_buttons()
	input_offset_slider.set_value_no_signal(input_value)
	audio_offset_slider.set_value_no_signal(audio_value)
	UserSettingsScript.apply_master_volume(master_volume)
	master_value.text = "%d%%" % roundi(master_volume)
	menu_sfx_value.text = "%d%%" % roundi(sfx_value)
	menu_sfx_value.modulate.a = 1.0 if sfx_enabled else 0.38
	background_value.text = "%d%%" % roundi(bg_value)
	_update_timing_labels()

func _update_timing_labels() -> void:
	input_offset_value.text = RhythmTimingScript.format_offset_ms(input_offset_slider.value)
	audio_offset_value.text = RhythmTimingScript.format_offset_ms(audio_offset_slider.value)

func _save_settings() -> void:
	UserSettingsScript.save_all(master_slider.value, bg_opacity_slider.value, menu_sfx_slider.value, menu_sfx_toggle.button_pressed)

func _on_reset_defaults_pressed() -> void:
	UserSettingsScript.reset_all()
	_setup_display_controls()
	_load_settings()
	_update_display_hint(not UserSettingsScript.is_game_embedded())
	if MenuSFX != null:
		MenuSFX.play_select()

func _transition_to_scene(path: String, _loading_label: String = "LOADING SONG LIBRARY") -> void:
	if in_transition or SceneTransition.is_transitioning():
		return
	in_transition = true
	for button in menu_buttons:
		button.disabled = true
	# Main Menu -> Song Library now shares one MusicSession. Do not pre-fade the
	# track; Song Library will either keep the same clock or crossfade only when
	# the selected card points at a different song.
	if path == "res://scenes/song_library.tscn":
		var navigation: Node = _resident_navigation_controller()
		if navigation != null and navigation.has_method("request_song_library"):
			var result: Variant = await navigation.call("request_song_library")
			_release_navigation_lock_after_result(result)
			return
	if path == "res://scenes/chart_editor.tscn":
		var chart_navigation: Node = _resident_navigation_controller()
		if chart_navigation != null and chart_navigation.has_method("request_chart_studio"):
			var result: Variant = await chart_navigation.call("request_chart_studio")
			_release_navigation_lock_after_result(result)
			return
	menu_bgm.fade_out(0.12)
	SceneTransition.change_scene_quick(path)

func _resident_navigation_controller() -> Node:
	var navigation: Node = get_node_or_null("/root/NavigationController")
	if _has_registered_app_shell(navigation):
		return navigation
	return null

func _has_registered_app_shell(navigation: Node) -> bool:
	return navigation != null and navigation.has_method("has_registered_shell") and bool(navigation.call("has_registered_shell"))

func _release_navigation_lock_after_result(result: Variant) -> void:
	if result is Dictionary and str((result as Dictionary).get("outcome", "failure")) == "success":
		return
	in_transition = false
	for button in menu_buttons:
		button.disabled = false
	call_deferred("_focus_default_menu_button")

func activate_from_shell(focus_index: int = 0, audio_handoff: Dictionary = {}, preserve_music_state: bool = false) -> void:
	_cancel_pending_main_menu_reveal()
	_set_main_menu_focus_index(clampi(focus_index, 0, maxi(0, menu_buttons.size() - 1)))
	if not preserve_music_state:
		var resumed_library_audio: bool = _sync_main_menu_from_music_session()
		if not resumed_library_audio:
			resumed_library_audio = _apply_library_audio_handoff(audio_handoff)
		if not resumed_library_audio:
			_randomize_main_menu_background(false)
	if get_tree().has_meta(RETURN_TO_MENU_META):
		get_tree().remove_meta(RETURN_TO_MENU_META)
	if get_tree().has_meta(RETURN_TO_MENU_FOCUS_META):
		get_tree().remove_meta(RETURN_TO_MENU_FOCUS_META)
	in_transition = false
	for button in menu_buttons:
		button.disabled = false
	_show_main_menu_immediate(preserve_music_state)

func _cancel_pending_main_menu_reveal() -> void:
	# Boot/reveal tweens process even while the resident screen is suspended.
	# Retire their callbacks before they can resume music or steal route focus.
	if active_tween != null:
		active_tween.kill()
		active_tween = null
	if launch_menu_tween != null:
		launch_menu_tween.kill()
		launch_menu_tween = null
	splash_finished = true
	_mark_launch_splash_seen()
	splash.visible = false


# AppShell lifecycle hooks. Main Menu activation remains centralized here, while
# the shell owns route transitions and input locking.
func shell_will_resume(context: Dictionary) -> void:
	var focus_index: int = int(context.get("focus_index", _get_main_menu_focus_index()))
	activate_from_shell(focus_index, {}, bool(context.get("preserve_music_state", false)))

func shell_did_resume(_context: Dictionary) -> void:
	call_deferred("_focus_default_menu_button")

func shell_will_suspend(_context: Dictionary) -> void:
	_cancel_pending_main_menu_reveal()
	in_transition = true

func shell_did_suspend(_context: Dictionary) -> void:
	in_transition = false
