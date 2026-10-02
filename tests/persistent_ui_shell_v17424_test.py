from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
BASE = Path('/mnt/data/Beat_UP_v17.4.23.1_True_Seamless_Menu_Handoff')

def req(cond, msg):
    if not cond:
        raise AssertionError(msg)

project = (ROOT / 'project.godot').read_text(encoding='utf-8')
shell = (ROOT / 'scripts/app_shell.gd').read_text(encoding='utf-8')
shell_scene = (ROOT / 'scenes/app_shell.tscn').read_text(encoding='utf-8')
startup = (ROOT / 'scripts/startup.gd').read_text(encoding='utf-8')
library = (ROOT / 'scripts/song_library.gd').read_text(encoding='utf-8')
main = (ROOT / 'scripts/main.gd').read_text(encoding='utf-8')
telemetry = (ROOT / 'scripts/playtest_telemetry.gd').read_text(encoding='utf-8')

req('config/version="17.4.24"' in project, 'project version')
req('run/main_scene="res://scenes/app_shell.tscn"' in project, 'AppShell must be main scene')
req('StartupScreen' in shell_scene and 'SongLibraryScreen' in shell_scene and 'GameplayScreen' in shell_scene, 'persistent screen instances missing')
req('show_song_library' in shell and 'show_main_menu' in shell and 'launch_gameplay' in shell, 'shell navigation API missing')
req('app_shell.call("show_song_library")' in startup, 'Main Menu must route to persistent library')
req('app_shell.call("show_main_menu", 0)' in library, 'library back must route to persistent menu')
req('app_shell.call("launch_gameplay"' in library, 'library play must route to resident gameplay')
req('show_song_library_from_gameplay' in main, 'gameplay return must route to persistent library')
req('const APP_VERSION := "17.4.24"' in telemetry, 'telemetry version')

manifests = [p for p in ROOT.rglob('*.json') if 'manifest' in p.name.lower()]
req(not manifests, f'manifest JSON present: {manifests}')
req(not (ROOT / 'validation.txt').exists(), 'validation.txt must not exist')

# All JSON must parse.
for path in ROOT.rglob('*.json'):
    json.loads(path.read_text(encoding='utf-8'))

# Compare the complete built-in chart tree byte-for-byte with the previous version.
def chart_files(base: Path):
    return sorted((base / 'charts').rglob('*.json'))

cur = chart_files(ROOT)
old = chart_files(BASE)
req(len(cur) == 42 and len(old) == 42, f'expected 42 charts, got {len(cur)} / {len(old)}')
old_map = {p.relative_to(BASE / 'charts').as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in old}
cur_map = {p.relative_to(ROOT / 'charts').as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in cur}
req(cur_map == old_map, 'built-in charts changed')

print('v17.4.24 persistent UI shell static checks: PASS')
