from pathlib import Path
root = Path(__file__).resolve().parents[1]
script = (root / 'scripts' / 'ui' / 'library_composition.gd').read_text(encoding='utf-8')
project = (root / 'project.godot').read_text(encoding='utf-8')
assert 'config/version="18.1.2.2"' in project
for token in [
    'LibraryNowPlayingCard',
    'NOW PLAYING',
    'LibraryNowPlayingProgress',
    'func refresh_now_playing(s) -> void:',
    'func _toggle_now_playing(s) -> void:',
    'func _step_song(s, direction: int) -> void:',
    'TransportIconButton.new()',
]:
    assert token in script, token
print('v18.1.2.2 Now Playing static checks passed.')
