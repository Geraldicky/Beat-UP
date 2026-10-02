from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
project = (ROOT / "project.godot").read_text(encoding="utf-8")
select = (ROOT / "scripts/song_select.gd").read_text(encoding="utf-8")
preview = (ROOT / "scripts/ui/song_preview_controller.gd").read_text(encoding="utf-8")
visual = (ROOT / "scripts/ui/song_select_visual.gd").read_text(encoding="utf-8")
assert 'func _unhandled_input(event: InputEvent)' in select
assert 'NOW PLAYING' in select
assert 'func _publish_current_selection_state()' in select
assert 'restart_if_same' in (ROOT / "scripts/music_session.gd").read_text(encoding="utf-8")
assert 'session.call("play_track", audio_path, safe_start, metadata, false, false' in preview
assert 'delta / 0.30' in visual
print("v17.4.40 static Song Library checks passed")
