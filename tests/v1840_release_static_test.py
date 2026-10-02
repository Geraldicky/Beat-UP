from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

project = (ROOT / "project.godot").read_text(encoding="utf-8")
startup = (ROOT / "scripts/startup.gd").read_text(encoding="utf-8")
startup_scene = (ROOT / "scenes/startup.tscn").read_text(encoding="utf-8")
select = (ROOT / "scripts/song_select.gd").read_text(encoding="utf-8")
select_scene = (ROOT / "scenes/song_select.tscn").read_text(encoding="utf-8")
editor = (ROOT / "scripts/chart_editor.gd").read_text(encoding="utf-8")
editor_scene = (ROOT / "scenes/chart_editor.tscn").read_text(encoding="utf-8")
picker = (ROOT / "scripts/ui/beat_file_picker.gd").read_text(encoding="utf-8")
dropdown = (ROOT / "scripts/ui/beat_dropdown.gd").read_text(encoding="utf-8")
context_menu = (ROOT / "scripts/ui/beat_context_menu.gd").read_text(encoding="utf-8")
message_dialog = (ROOT / "scripts/ui/beat_message_dialog.gd").read_text(encoding="utf-8")
composition = (ROOT / "scripts/ui/library_composition.gd").read_text(encoding="utf-8")
note = (ROOT / "scripts/note.gd").read_text(encoding="utf-8")
theme = (ROOT / "config/theme_config.tres").read_text(encoding="utf-8")
export = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")

assert any(('config/version="%s"' % version) in project for version in ["18.4.0.2", "18.5.0", "18.5.0.1", "18.5.0.2", "18.5.0.2.1", "18.5.0.2.2", "18.6.0", "18.7.0", "18.7.0.1"])
assert '_sync_visible_version_labels()' in startup
assert 'ProjectSettings.get_setting("application/config/version"' in startup
assert 'SYSTEM 17.4.25' not in startup_scene

assert 'class_name BeatDropdown' in dropdown
assert 'type="OptionButton"' not in select_scene + editor_scene + startup_scene
assert 'PopupMenu.new()' not in select + editor
assert 'preload("res://scripts/ui/beat_context_menu.gd").new()' in select
assert 'popup_near(practice_button, true)' in select
assert 'AcceptDialog.new()' not in select + composition
assert 'class_name BeatMessageDialog' in message_dialog
assert 'beat_message_dialog.gd' in composition

assert 'class_name BeatFilePicker' in picker
assert 'signal file_selected(path: String)' in picker
assert 'signal files_selected(paths: PackedStringArray)' in picker
assert 'type="FileDialog"' not in select_scene + editor_scene
assert 'beat_file_picker.gd' in select_scene and 'beat_file_picker.gd' in editor_scene
assert 'var import_dialog = %ImportDialog' in select
assert 'var song_file_dialog = $WavFileDialog' in editor
assert ': BeatFilePicker' not in select + editor
assert ': BeatContextMenu' not in select + editor

assert 'note_fill_color = Color(' in theme
assert 'return theme_config.text_primary' in note
assert 'debug/export_console_wrapper=0' in export
assert any(('application/product_version="%s"' % version) in export for version in ["18.4.0.2", "18.5.0", "18.5.0.1", "18.5.0.2", "18.5.0.2.1", "18.5.0.2.2", "18.6.0", "18.7.0", "18.7.0.1"])

assert not list(ROOT.rglob("*manifest*.json"))
print("Beat UP! v18.4 compatibility checks: PASS")
