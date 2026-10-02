from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
project = (ROOT / 'project.godot').read_text(encoding='utf-8')
song_select = (ROOT / 'scripts/song_select.gd').read_text(encoding='utf-8')
main = (ROOT / 'scripts/main.gd').read_text(encoding='utf-8')
helper = (ROOT / 'scripts/runtime_resource_access.gd').read_text(encoding='utf-8')
assert any(('config/version="%s"' % version) in project for version in ['18.4.0.3', '18.5.0', '18.5.0.1', '18.5.0.2', '18.5.0.2.1', '18.5.0.2.2', '18.6.0', '18.7.0', '18.7.0.1'])
assert 'ResourceLoader.exists(path)' in helper
assert 'RuntimeResourceAccessScript.audio_exists' in song_select
assert 'RuntimeResourceAccessScript.audio_exists' in main
assert 'FileAccess.file_exists(str(chart.get("audio", "")))' not in song_select
assert 'FileAccess.file_exists(str(launch_chart.get("audio", "")))' not in main
print('v18.4.0.3 exported audio compatibility checks passed.')
