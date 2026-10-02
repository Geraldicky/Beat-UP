from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
project = (ROOT / 'project.godot').read_text(encoding='utf-8')
scene = (ROOT / 'scenes' / 'song_select.tscn').read_text(encoding='utf-8')
script = (ROOT / 'scripts' / 'song_select.gd').read_text(encoding='utf-8')
composition = (ROOT / 'scripts' / 'ui' / 'library_composition.gd').read_text(encoding='utf-8')
assert 'config/version="18.1.2.3"' in project
assert '[node name="NowPlayingCard" type="Panel" parent="."]' in scene
assert 'theme_override_constants/margin_left = 28' in scene
assert 'theme_override_constants/separation = 18' in scene
assert 'transport_icon_button.gd' in scene
assert 'now_playing_card.position = Vector2(0.0, 0.0)' in script
assert 'clampf(38.0 * reference_scale, 36.0, 42.0)' in script
assert 'Color(0.035, 0.045, 0.065, 0.82)' in script
assert 'base_margin + now_playing_height + 8' in composition
print('v18.1.2.3 Home-style Now Playing checks passed.')
