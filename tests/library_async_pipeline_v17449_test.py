from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

app_shell = (ROOT / "scripts/app_shell.gd").read_text(encoding="utf-8")
song_library = (ROOT / "scripts/song_library.gd").read_text(encoding="utf-8")
song_select = (ROOT / "scripts/song_select.gd").read_text(encoding="utf-8")
visual = (ROOT / "scripts/ui/song_select_visual.gd").read_text(encoding="utf-8")
music = (ROOT / "scripts/music_session.gd").read_text(encoding="utf-8")
preview = (ROOT / "scripts/ui/song_preview_controller.gd").read_text(encoding="utf-8")
project = (ROOT / "project.godot").read_text(encoding="utf-8")

assert 'defer_library_resume: bool = route == ROUTE_SONG_LIBRARY' in app_shell
assert 'shell_prepare_resume' in app_shell and 'shell_prepare_resume' in song_library

setter = song_select.split('func set_selected_song(song_id: String) -> void:', 1)[1].split('\nfunc ', 1)[0]
assert '_apply_filters(false)' in setter  # fallback only
assert 'if filtered_song_ids.has(song_id):' in setter
assert '_refresh_song_rows(false)' in setter

assert 'load_threaded_request' in visual
assert 'var texture := load(path)' not in visual
assert 'preload_track' in music
assert 'is_track_ready' in music
assert 'load_threaded_request' in music
assert 'preload_track' in preview
assert 'is_track_ready' in preview

assert 'song_select.call("shell_did_resume", context)' in song_library
assert 'song_select.call("shell_will_suspend", context)' in song_library
print('v17.4.49 async-library static checks passed')
