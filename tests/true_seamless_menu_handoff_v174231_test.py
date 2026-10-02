from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def require(condition, message):
    if not condition:
        raise AssertionError(message)

project = (ROOT / 'project.godot').read_text(encoding='utf-8')
manager = (ROOT / 'scripts' / 'scene_transition.gd').read_text(encoding='utf-8')
layer = (ROOT / 'scenes' / 'scene_transition_layer.tscn').read_text(encoding='utf-8')

require('config/version="17.4.23.1"' in project, 'project version')
require('QuickTransitionVisual' not in layer, 'quick transition node must be removed')
require('beat_diamond_transition_visual.gd' not in layer, 'retired quick visual resource must be removed')
require(not (ROOT / 'scripts' / 'ui' / 'beat_diamond_transition_visual.gd').exists(), 'retired quick visual script must be absent')
require('_quick_cover' not in manager and '_quick_reveal' not in manager, 'old quick overlay helpers must be removed')
require('SEAMLESS MENU HANDOFF' in manager, 'seamless menu handoff path missing')
require('change_scene_to_gameplay' in manager and 'SongLaunchVisual' in layer, 'gameplay artwork continuity must remain')
require(not list(ROOT.rglob('*manifest*.json')), 'manifest JSON files are forbidden')
print('v17.4.23.1 true seamless menu handoff static checks: PASS')
