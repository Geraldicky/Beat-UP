from pathlib import Path
root=Path(__file__).resolve().parents[1]
app=(root/'scripts/app_shell.gd').read_text()
main=(root/'scripts/main.gd').read_text()
lib=(root/'scripts/song_library.gd').read_text()
track=(root/'scripts/track.gd').read_text()
project=(root/'project.godot').read_text()
segment=app.split('func show_song_library_from_gameplay',1)[1].split('func show_main_menu_from_gameplay',1)[0]
assert 'refresh_from_shell_deferred' not in segment
reset=main.split('func reset_after_shell_exit_async',1)[1].split('func show_level_select',1)[0]
assert '\n\tshow_level_select()' not in reset
assert 'clear_notes_batched' in reset
assert 'func clear_notes_batched' in track
assert 'current_song_id != selected_song_id' in lib
assert not list(root.rglob('*manifest*.json'))
print('v17.4.24.1 return-to-library stall static checks: PASS')
