#!/usr/bin/env python3
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RATIOS = {"normal": 0.06, "hard": 0.12, "master": 0.17}
BIG_DADDY_HASHES = {
    "normal": "5de2d50ba52c96a3552a1597f06ee9f8672a1a802642b496580c56789d383038",
    "hard": "95f2c73165b4bfdec0e38be7984698361341db480feefdff836968da66b8d4e3",
    "master": "602053b5df2abead2c29e2704062e24e88cc2bac421af17f683929f6ab67ff87",
}

paths = sorted((ROOT / "charts").glob("*/*.json"))
assert len(paths) == 42, len(paths)

by_song = {}
for path in paths:
    data = json.loads(path.read_text(encoding="utf-8"))
    events = data["events"]
    assert events
    assert all(float(events[i]["time"]) < float(events[i + 1]["time"]) for i in range(len(events) - 1)), path
    assert all(e.get("type") in ("normal", "reverse") for e in events), path
    assert all(int(e.get("direction", 0)) in (1, 2, 3, 4, 6, 7, 8, 9) for e in events), path
    song = path.parent.name
    diff = str(data["chart_difficulty"]).lower()
    by_song.setdefault(song, {})[diff] = data

    if song == "big_daddy":
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        assert digest == BIG_DADDY_HASHES[diff], (diff, digest)
    else:
        std = data.get("library_standardization", {})
        assert std.get("version") == "17.4.19", path
        assert std.get("retained_timestamp_shift") is False, path
        assert std.get("retained_direction_changes") is False, path
        assert std.get("space_events_changed") is False, path
        expected_reverse = round(len(events) * RATIOS[diff])
        actual_reverse = sum(1 for e in events if e.get("type") == "reverse")
        assert actual_reverse == expected_reverse, (path, actual_reverse, expected_reverse)
        assert data.get("special_note_counts", {}).get("reverse") == actual_reverse, path
        assert data.get("difficulty_profile", {}).get("balance_version") == "v17.4.19", path
        assert data.get("generator_diagnostics", {}).get("version") == "17.4.19", path
        assert "Library standard v17.4.19" in data.get("recommended", ""), path

assert len(by_song) == 14
for song, diffs in by_song.items():
    assert set(diffs) == {"normal", "hard", "master"}, song
    counts = [len(diffs[d]["events"]) for d in ("normal", "hard", "master")]
    assert counts[0] < counts[1] < counts[2], (song, counts)
    stars = [int(diffs[d]["star_rating"]) for d in ("normal", "hard", "master")]
    assert stars[0] < stars[1] < stars[2], (song, stars)

assert 'const APP_VERSION := "17.4.23.1"' in (ROOT / "scripts/playtest_telemetry.gd").read_text(encoding="utf-8")
assert "SYSTEM 17.4.23.1" in (ROOT / "scenes/startup.tscn").read_text(encoding="utf-8")

print("v17.4.19 full-library chart standardization checks: PASS")
