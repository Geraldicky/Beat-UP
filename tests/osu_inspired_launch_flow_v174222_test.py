from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
BASE = Path('/mnt/data/Beat_UP_v17.4.22.1_UI_Cohesion_Parser_Hotfix')

def require(cond, msg):
    if not cond:
        raise AssertionError(msg)

project = (ROOT/'project.godot').read_text(encoding='utf-8')
startup = (ROOT/'scripts/startup.gd').read_text(encoding='utf-8')
startup_scene = (ROOT/'scenes/startup.tscn').read_text(encoding='utf-8')
transition = (ROOT/'scripts/scene_transition.gd').read_text(encoding='utf-8')
loading_scene = (ROOT/'scenes/scene_transition_layer.tscn').read_text(encoding='utf-8')
song_launch = (ROOT/'scripts/ui/song_launch_transition_visual.gd').read_text(encoding='utf-8')

require('config/version="17.4.23.1"' in project, 'project version')
require('WELCOME TO' in startup_scene, 'cold launch welcome stage')
require('SplashHaloOuter' in startup_scene and 'SplashHaloInner' in startup_scene, 'launch halo nodes')
require('_begin_main_menu_under_splash' in startup, 'continuous launch into menu')
require('await _cover(status' not in transition, 'legacy loading page is not used by change_scene')
require('await _cover(status, detail)' not in transition, 'legacy loading page is not used by transition_action')
require('progress_bar' not in song_launch, 'song launch has no progress bar')
require('status_label' not in song_launch, 'song launch has no loading copy')
require('QuickTransitionVisual' not in loading_scene, 'menu handoff must not expose a global ribbon visual')
require('[node name="TransitionVisual"' not in loading_scene and 'LoadingProgress' not in loading_scene, 'legacy loading UI removed')
require(not list(ROOT.rglob('*manifest*.json')), 'manifest json must not exist')

# JSON validity
for p in ROOT.rglob('*.json'):
    json.loads(p.read_text(encoding='utf-8'))

# All built-in charts remain byte-identical.
def hashes(base):
    return {p.relative_to(base).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in base.rglob('*.json')}
require(hashes(BASE/'charts') == hashes(ROOT/'charts'), 'built-in chart JSON changed')
print('v17.4.22.2 static launch-flow checks: PASS')
