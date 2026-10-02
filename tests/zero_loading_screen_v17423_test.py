from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
BASE = Path('/mnt/data/Beat_UP_v17.4.22.3_Consistent_Gameplay_Launch_Transition')

def require(cond, msg):
    if not cond:
        raise AssertionError(msg)

project = (ROOT / 'project.godot').read_text(encoding='utf-8')
transition = (ROOT / 'scripts/scene_transition.gd').read_text(encoding='utf-8')
layer = (ROOT / 'scenes/scene_transition_layer.tscn').read_text(encoding='utf-8')
handoff = (ROOT / 'scripts/ui/song_launch_transition_visual.gd').read_text(encoding='utf-8')

require('config/version="17.4.23.1"' in project, 'project version')
require('SceneTransition="*res://scenes/scene_transition_layer.tscn"' in project, 'new transition autoload')
require(not (ROOT / 'scenes/loading_transition.tscn').exists(), 'legacy loading scene must be removed')
require('[node name="TransitionVisual"' not in layer, 'legacy transition visual node must not exist')
require('LoadingProgress' not in layer and 'PercentageLabel' not in layer and 'StatusLabel' not in layer, 'loading UI must not exist')
require('PREPARING CHART' not in layer and 'LOADING' not in layer, 'loading copy must not exist')
require('change_scene_to_gameplay' in transition and 'transition_action_to_gameplay' in transition, 'gameplay handoff APIs')
require('preload_scene(scene_path)' in transition, 'gameplay scene request starts before handoff wait')
require('await song_launch_visual.animate_cover()' in transition, 'seamless cover')
require('await song_launch_visual.animate_reveal()' in transition, 'seamless reveal')
require('progress_bar' not in handoff and 'status_label' not in handoff, 'handoff cannot render loader UI')
require('Loader progress is intentionally invisible' in handoff, 'invisible loader state documented')
require(not list(ROOT.rglob('*manifest*.json')), 'manifest json must not exist')

for p in ROOT.rglob('*.json'):
    json.loads(p.read_text(encoding='utf-8'))

if BASE.exists():
    base = sorted((BASE / 'charts').rglob('*.json'))
    now = sorted((ROOT / 'charts').rglob('*.json'))
    require(len(base) == len(now) == 42, 'expected 42 charts')
    base_hash = {p.relative_to(BASE/'charts').as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in base}
    now_hash = {p.relative_to(ROOT/'charts').as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in now}
    require(base_hash == now_hash, 'built-in charts changed')

print('v17.4.23 zero-loading-screen static checks: PASS')
