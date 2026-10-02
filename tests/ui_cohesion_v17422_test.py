from pathlib import Path
import hashlib

ROOT = Path(__file__).resolve().parents[1]
BASE = Path('/mnt/data/Beat_UP_v17.4.21.5_Transition_Input_Lock_Hotfix')

def require(condition, message):
    if not condition:
        raise AssertionError(message)

project = (ROOT / 'project.godot').read_text(encoding='utf-8')
require('config/version="17.4.23.1"' in project, 'project version')

library = (ROOT / 'scripts/song_library.gd').read_text(encoding='utf-8')
require('change_scene_to_gameplay("res://main.tscn", visual_payload)' in library, 'seamless gameplay launch')

transition = (ROOT / 'scripts/scene_transition.gd').read_text(encoding='utf-8')
require('func change_scene_to_gameplay' in transition, 'gameplay transition API')
require('SongLaunchTransitionVisual' in transition, 'song launch visual wired')

main = (ROOT / 'scripts/main.gd').read_text(encoding='utf-8')
require('func is_gameplay_transition_ready()' in main, 'gameplay readiness handshake')
require('_prepare_gameplay_entry_motion()' in main, 'gameplay UI entrance motion')

scene = (ROOT / 'scenes/scene_transition_layer.tscn').read_text(encoding='utf-8')
require('SongLaunchVisual' in scene and 'SongLaunchArtwork' in scene, 'continuity overlay scene')

startup = (ROOT / 'scenes/startup.tscn').read_text(encoding='utf-8')
require('SYSTEM 17.4.23.1' in startup, 'startup version label')
require('shape = "diamond"' in startup, 'main menu diamond motif')

manifest_json = list(ROOT.rglob('*manifest*.json'))
require(not manifest_json, f'manifest JSON remains: {manifest_json}')

if BASE.exists():
    base_charts = sorted((BASE / 'charts').rglob('*.json'))
    new_charts = sorted((ROOT / 'charts').rglob('*.json'))
    require(len(base_charts) == len(new_charts) == 42, 'expected 42 built-in charts')
    by_rel = {p.relative_to(BASE / 'charts'): p for p in base_charts}
    for p in new_charts:
        rel = p.relative_to(ROOT / 'charts')
        require(rel in by_rel, f'new chart path {rel}')
        require(hashlib.sha256(p.read_bytes()).digest() == hashlib.sha256(by_rel[rel].read_bytes()).digest(), f'chart changed: {rel}')

print('v17.4.22 static UI cohesion checks: PASS')
