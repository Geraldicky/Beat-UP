from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
NEW_IDS = ['miracle_sugite_yabai', 'ghost', 'eyes_half_closed', 'at_the_speed_of_light', 'sonic_blaster', 'tower_of_heaven', 'vagrant', 'highscore_nightcore', 'duplicity_shade', 'cycle_hit', 'cybernetic_maste_7', 'catastrophe', 'rockefeller_street_nightcore', 'crab_rave', 'immortal_flame', 'r4v3_b0y', 'space_invaders', 'everything_will_freeze', 'united_laos_remix', 'flamewall', 'the_pressure', 'sound_chimera', 'bubble_tea', 'cheatreal', 'bluenation']

project_text = (ROOT / "project.godot").read_text(encoding="utf-8")

all_charts = sorted((ROOT / "charts").glob("*/*.json"))
assert len(all_charts) == 117, len(all_charts)

for song_id in NEW_IDS:
    audio = ROOT / "music" / "imported" / f"{song_id}.ogg"
    assert audio.is_file() and audio.stat().st_size > 10000, audio
    for diff in ("normal", "hard", "master"):
        path = ROOT / "charts" / song_id / f"{diff}.json"
        assert path.is_file(), path
        data = json.loads(path.read_text(encoding="utf-8"))
        assert data["song_id"] == song_id
        assert data["chart_difficulty"] == diff
        assert data["audio"] == f"res://music/imported/{song_id}.ogg"
        assert data.get("analysis_source", "") == ""
        assert data.get("background", "") == ""
        assert data.get("generator_meta", {}).get("analysis_source_format") == "flac"
        assert data.get("generator_meta", {}).get("batch_version") == "17.4.43"
        events = data.get("events", [])
        assert events, path
        times = [float(e["time"]) for e in events]
        assert times == sorted(times), path
        assert times[0] >= 0.0 and times[-1] <= float(data["duration"]) + 0.01
        assert all(e.get("type") in ("normal", "reverse") for e in events)
        assert not any(e.get("type") == "bomb" for e in events)

assert not list(ROOT.rglob("*.flac")), "FLAC masters must remain external to the distributable project"
assert not [p for p in ROOT.rglob("*.json") if "manifest" in p.name.lower()], "No manifest JSON files should be added"
print("v17.4.43 new-song batch checks passed")
