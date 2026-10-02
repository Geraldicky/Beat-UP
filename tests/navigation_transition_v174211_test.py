from pathlib import Path
import hashlib, json

ROOT = Path(__file__).resolve().parents[1]
BASE = Path('/mnt/data/Beat_UP_v17.4.21')

def req(cond, msg):
    if not cond:
        raise AssertionError(msg)

project = (ROOT/'project.godot').read_text()
startup = (ROOT/'scripts/startup.gd').read_text()
transition = (ROOT/'scripts/scene_transition.gd').read_text()
main = (ROOT/'scripts/main.gd').read_text()
editor = (ROOT/'scripts/chart_editor.gd').read_text()
telemetry = (ROOT/'scripts/playtest_telemetry.gd').read_text()
profile = (ROOT/'scripts/player_profile.gd').read_text()
startup_scene = (ROOT/'scenes/startup.tscn').read_text()

req('config/version="17.4.23.1"' in project, 'project version')
req('SYSTEM 17.4.23.1' in startup_scene, 'startup build label')
req('const APP_VERSION := "17.4.23.1"' in telemetry, 'telemetry version')
req('const APP_VERSION := "17.4.23.1"' in profile, 'profile version')

req('func change_scene_quick(scene_path: String)' in transition, 'quick scene API')
req('func transition_action_quick(action: Callable)' in transition, 'quick action API')
req('_quick_cover' not in transition and '_quick_reveal' not in transition, 'menu handoff must not use overlay cover/reveal')
req('SEAMLESS MENU HANDOFF' in transition, 'overlay-free menu handoff')

req('SceneTransition.change_scene_quick(path)' in startup, 'startup lightweight nav')
req('tween.tween_property(transition_overlay' not in startup.split('func _transition_to_scene',1)[1].split('\nfunc ',1)[0], 'old double transition removed')
req('SceneTransition.change_scene_quick("res://scenes/chart_editor.tscn")' in main, 'library to studio quick')
req('SceneTransition.change_scene_quick("res://scenes/startup.tscn")' in main, 'library to menu quick')
req('SceneTransition.transition_action_quick(show_level_select)' in main, 'return to library quick')
req('SceneTransition.change_scene_quick("res://scenes/startup.tscn")' in editor, 'studio to menu quick')

# Gameplay entry uses persistent song-artwork continuity; generic loading UI is retired.
req('SceneTransition.transition_action_to_gameplay(' in main, 'gameplay uses song-artwork handoff')

# Chart library must remain untouched.
charts = sorted((ROOT/'charts').glob('*/*.json'))
req(len(charts) == 42, f'expected 42 charts, got {len(charts)}')
for p in charts:
    json.loads(p.read_text())
    if BASE.exists():
        rel = p.relative_to(ROOT)
        b = BASE/rel
        req(b.exists(), f'baseline missing {rel}')
        req(hashlib.sha256(p.read_bytes()).digest() == hashlib.sha256(b.read_bytes()).digest(), f'chart changed: {rel}')

req(not (ROOT/'validation.txt').exists(), 'validation.txt must not exist')
print('v17.4.21.1 navigation transition static QA: PASS')
