extends SceneTree

func _initialize() -> void:
	var editor_script: Script = load("res://scripts/chart_editor.gd") as Script
	var analyzer_script: Script = load("res://scripts/wav_auto_analyzer.gd") as Script
	var shell_script: Script = load("res://scripts/app_shell.gd") as Script
	var startup_script: Script = load("res://scripts/startup.gd") as Script
	var timeline_script: Script = load("res://scripts/chart_timeline_view.gd") as Script
	var waveform_script: Script = load("res://scripts/chart_waveform_view.gd") as Script
	var dropdown_script: Script = load("res://scripts/ui/beat_dropdown.gd") as Script
	var picker_script: Script = load("res://scripts/ui/beat_file_picker.gd") as Script
	if editor_script == null or analyzer_script == null or shell_script == null or startup_script == null or timeline_script == null or waveform_script == null or dropdown_script == null or picker_script == null:
		push_error("V18.7 generator integration scripts failed to load.")
		quit(1)
		return
	print("V1870_GENERATOR_INTEGRATION: PASS")
	quit(0)
