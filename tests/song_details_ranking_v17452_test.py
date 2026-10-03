from pathlib import Path
import hashlib, json, glob, os

ROOT = Path(__file__).resolve().parents[1]
project = (ROOT / 'project.godot').read_text(encoding='utf-8')
scene = (ROOT / 'scenes/song_select.tscn').read_text(encoding='utf-8')
script = (ROOT / 'scripts/song_select.gd').read_text(encoding='utf-8')

for token in [
    'name="InfoTabs"',
    'name="DetailsTabButton"',
    'name="RankingTabButton"',
    'name="RankingContext"',
    'name="DetailsPanel"',
    'name="BreakdownGrid"',
    'name="NormalNotesValue"',
    'name="ReverseNotesValue"',
    'name="SpaceNotesValue"',
]:
    assert token in scene, token

for token in [
    'var selected_info_tab: String = "ranking"',
    'func _set_info_tab(',
    'func _update_chart_breakdown(',
    'LOCAL RECORD',
    'ranking_context.text = "LOCAL  ·  SCORE',
    'details_tab_button.pressed.connect(_on_details_tab_pressed)',
    'ranking_tab_button.pressed.connect(_on_ranking_tab_pressed)',
]:
    assert token in script, token

# User explicitly requested no manifest/build manifest files in Beat UP! builds.
for p in ROOT.rglob('*.json'):
    low = p.name.lower()
    assert 'manifest' not in low, p

# Full library still exists.
assert len(list((ROOT / 'charts').glob('*/*.json'))) == 117
assert len(list((ROOT / 'assets/backgrounds').glob('background_*.png'))) == 39

print('v17.4.52 song details/ranking static QA: PASS')
