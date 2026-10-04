from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]

project = (ROOT / "project.godot").read_text(encoding="utf-8")
export = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
gameplay_config = (ROOT / "config/gameplay_config.gd").read_text(encoding="utf-8")
gameplay_resource = (ROOT / "config/gameplay_config.tres").read_text(encoding="utf-8")
main = (ROOT / "scripts/main.gd").read_text(encoding="utf-8")
policy = (ROOT / "scripts/score_policy.gd").read_text(encoding="utf-8")
identity = (ROOT / "scripts/score_identity.gd").read_text(encoding="utf-8")
select = (ROOT / "scripts/song_select.gd").read_text(encoding="utf-8")
select_scene = (ROOT / "scenes/song_select.tscn").read_text(encoding="utf-8")
song_row = (ROOT / "scripts" / "ui" / "song_library" / "song_row.gd").read_text(encoding="utf-8")
runtime_access = (ROOT / "scripts/runtime_resource_access.gd").read_text(encoding="utf-8")

assert any(('config/version="%s"' % version) in project for version in ["18.5.0", "18.5.0.1", "18.5.0.2", "18.5.0.2.1", "18.5.0.2.2", "18.6.0", "18.7.0", "18.7.0.1"])
assert any(('application/product_version="%s"' % version) in export for version in ["18.5.0", "18.5.0.1", "18.5.0.2", "18.5.0.2.1", "18.5.0.2.2", "18.6.0", "18.7.0", "18.7.0.1"])
assert 'player_creator_enabled=true' in project
assert 'creator_tools_enabled=false' in project

assert 'score_scale_multiplier: float = 13.0' in gameplay_config
assert 'score_scale_multiplier = 13.0' in gameplay_resource
assert 'ScorePolicy.note_award' in main
assert 'ScorePolicy.space_award' in main
assert 'ScorePolicy.accumulate' in main
# Score/accuracy row separation is exercised at every desktop resolution by
# phase4_ui_foundation_test.gd; do not pin the retired compact HUD coordinates.
layout_qa = (ROOT / 'tests/phase4_ui_foundation_test.gd').read_text(encoding='utf-8')
assert 'not score.get_global_rect().intersects(accuracy.get_global_rect())' in layout_qa
assert 'const MAX_DISPLAY_SCORE := 9_999_999' in policy
assert 'class_name' not in policy
assert 'const RULES_VERSION := "beatup_rules_v2"' in identity
assert '"score_scale_multiplier"' in identity
assert 'migrate_v185_score_scale' in identity
assert 'score_scale_migration' in identity
assert 'migrate_v185_score_scale(best_stats_store, levels' in main

# Across all 117 authored charts, an ideal run sits in the requested 1–9
# million band. Reverse and SPACE rewards are included in this estimate.
estimated_fcs = []
for path in ROOT.glob("charts/*/*.json"):
    chart = json.loads(path.read_text(encoding="utf-8"))
    score = 0.0
    events = chart.get("events", [])
    for combo, event in enumerate(events, 1):
        multiplier = 1.0
        for threshold, candidate in zip([10, 25, 50, 100, 200], [1.25, 1.5, 2.0, 2.5, 3.0]):
            if combo >= threshold:
                multiplier = candidate
        base = 120 + (35 if event.get("type") == "reverse" else 0)
        score += round(base * multiplier * 13.0)
    final_combo_multiplier = 3.0 if len(events) >= 200 else multiplier
    score += sum(round(250 * final_combo_multiplier * 1.2 * 13.0) for _ in chart.get("space_events", []))
    estimated_fcs.append(int(score))
assert min(estimated_fcs) >= 1_000_000
assert max(estimated_fcs) <= 9_999_999

assert 'var selected_info_tab: String = "ranking"' in select
assert 'details_tab_button.visible = false' in select
assert 'details_panel.visible = false' in select
# Song-row presentation moved into the reusable SongRow component. Preserve
# the v18.5 invariant (no redundant full-title tooltip) at the current owner.
assert 'header_button.tooltip_text = ""' in song_row
assert 'header_button.tooltip_text = title' not in song_row
assert 'button.tooltip_text = str(rep.get("title"' not in select
assert 'RuntimeResourceAccessScript.audio_exists' in select
assert 'RuntimeResourceAccessScript.audio_exists' in main
assert 'ResourceLoader.exists(path)' in runtime_access
assert 'FileAccess.file_exists(str(chart.get("audio", "")))' not in select
assert 'FileAccess.file_exists(str(launch_chart.get("audio", "")))' not in main
assert '[node name="DetailsTabButton"' in select_scene
details_node = select_scene.split('[node name="DetailsTabButton"', 1)[1].split("[node ", 1)[0]
assert 'visible = false' in details_node
assert 'name="DetailsPanel"' in select_scene  # hidden, retained rather than deleted

assert len(list(ROOT.glob("charts/*/*.json"))) == 117
# Generic fullscreen ambience is independent of song jackets/thumbnails.
expected_backgrounds = {"background_{:02d}.png".format(index) for index in range(1, 40)}
assert {p.name for p in (ROOT / "assets/backgrounds").glob("*.png")} == expected_backgrounds
assert not list(ROOT.rglob("*manifest*.json"))

print("Beat UP! v18.5.0 static release checks: PASS")
