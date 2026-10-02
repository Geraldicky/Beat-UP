from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[1]
BASE = Path('/mnt/data/Beat_UP_v17.4.23_Zero_Loading_Screen_Seamless_Gameplay_Handoff')

def req(cond, msg):
    if not cond:
        raise AssertionError(msg)

def sha(path):
    h=hashlib.sha256()
    with open(path,'rb') as f:
        for chunk in iter(lambda:f.read(1024*1024), b''):
            h.update(chunk)
    return h.hexdigest()

project=(ROOT/'project.godot').read_text(encoding='utf-8')
startup=(ROOT/'scripts/startup.gd').read_text(encoding='utf-8')
startup_scene=(ROOT/'scenes/startup.tscn').read_text(encoding='utf-8')
editor=(ROOT/'scripts/chart_editor.gd').read_text(encoding='utf-8')
editor_scene=(ROOT/'scenes/chart_editor.tscn').read_text(encoding='utf-8')
catalog=(ROOT/'scripts/level_catalog.gd').read_text(encoding='utf-8')
telemetry=(ROOT/'scripts/playtest_telemetry.gd').read_text(encoding='utf-8')
profile=(ROOT/'scripts/player_profile.gd').read_text(encoding='utf-8')

req('config/version="17.4.23.1"' in project, 'project version')
req('SYSTEM 17.4.23.1' in startup_scene, 'startup build label')
req('const APP_VERSION := "17.4.23.1"' in telemetry, 'telemetry version')
req('const APP_VERSION := "17.4.23.1"' in profile, 'profile version')
req('CHART STUDIO' in startup and 'ChartStudioButton' in startup_scene, 'main-menu Chart Studio access')
req('res://scenes/chart_editor.tscn' in startup, 'main-menu scene transition')
req('text = "CHART STUDIO"' in editor_scene, 'new editor heading')
req('GAMEPLAY AUDIO  ·  .OGG' in editor_scene, 'OGG workflow card')
req('ANALYSIS SOURCE  ·  .FLAC' in editor_scene, 'FLAC workflow card')
req('*.flac ; FLAC Lossless Audio' in editor_scene, 'FLAC-only picker')
req('*.ogg ; OGG Audio' in editor_scene, 'OGG picker')
req('return path.get_extension().to_lower() == "flac"' in editor, 'FLAC-only analysis validation')
req('const IMPORTED_CHART_ROOT := "user://songs"' in editor, 'custom songs stored in user data')
req('"storage": "user://songs"' in editor, 'custom chart storage metadata')
req('"user://songs"' in catalog, 'catalog scans custom songs')
req('GENERATE 3 CHARTS' in editor_scene and 'GENERATING N / H / M' in editor, 'three-difficulty generation')
req('CHART_STUDIO_POSTPROCESS_PATH' in editor and 'READABILITY GUARD' in editor, 'generated charts use the validated readability guard')
req('chart_studio_postprocess_v17421.py' in editor, 'postprocess tool is wired')
req('include_filter="tools/*.py"' in (ROOT/'export_presets.cfg').read_text(encoding='utf-8'), 'python tools included in export')
req('beat_up_return_to_main_menu' in editor, 'editor returns to main menu')
req('No FLAC selected' in editor_scene and 'No OGG imported' in editor_scene, 'explicit dual-source UI')

# Every direct $NodePath reference in chart_editor.gd must exist in the scene.
paths=set()
for line in editor_scene.splitlines():
    if line.startswith('[node name='):
        name=re.search(r'name="([^"]+)"', line).group(1)
        pm=re.search(r'parent="([^"]*)"', line)
        parent=pm.group(1) if pm else ''
        paths.add(name if parent in ('', '.') else parent+'/'+name)
refs=set(re.findall(r'\$([A-Za-z0-9_/]+)', editor))
missing=sorted(refs-paths)
req(not missing, f'missing chart editor nodes: {missing}')

# Chart standardization must not change in this UI/tooling release.
current=sorted((ROOT/'charts').glob('*/*.json'))
base=sorted((BASE/'charts').glob('*/*.json'))
req(len(current)==42 and len(base)==42, '42 built-in charts expected')
cur_map={p.relative_to(ROOT/'charts').as_posix():sha(p) for p in current}
base_map={p.relative_to(BASE/'charts').as_posix():sha(p) for p in base}
req(cur_map==base_map, 'built-in charts must remain byte-identical to v17.4.20')
for p in current:
    json.loads(p.read_text(encoding='utf-8'))
req(not any(p.name=='validation.txt' for p in ROOT.rglob('*')), 'validation.txt must not be shipped')

print('v17.4.21 Chart Studio static QA: PASS')
