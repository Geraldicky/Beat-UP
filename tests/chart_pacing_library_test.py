"""Full bundled pacing contract, Python 3.7; read-only fixtures."""
import copy
import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from chart_pacing_audit import audit
from chart_pacing_library import revise_group, REVISION, CAPS


class LibraryPacingTest(unittest.TestCase):
    def test_every_bundled_chart_has_safe_pacing(self):
        paths = sorted((ROOT / "charts").glob("*/*.json"))
        self.assertEqual(len(paths), 117)
        revised_count = 0
        for folder in sorted(set(p.parent for p in paths)):
            counts, rests = [], []
            for difficulty in ("normal", "hard", "master"):
                c = json.loads((folder / (difficulty + ".json")).read_text(encoding="utf-8"))
                meta = c["pacing_meta"]
                after = audit(c)
                self.assertEqual(meta["after"], after, folder.name)
                self.assertEqual(meta["before"]["duration"], c["duration"])
                counts.append(len(c["events"]))
                rests.append(meta["rest_intervals"])
                for start, end in meta["rest_intervals"]:
                    self.assertGreater(end - start, 3.0)
                    self.assertGreater(start, c["events"][0]["time"])
                    self.assertLess(end, c["events"][-1]["time"])
                    self.assertTrue(any(s["start"] <= start + 1e-5 and s["end"] >= end - 1e-5
                                        for s in c["sections"]))
                    self.assertFalse(any(start - 1e-6 <= t < end - 1e-6
                                         for t in [e["time"] for e in c["events"]] + c["space_events"]))
                if meta["revision"] == REVISION:
                    revised_count += 1
                    self.assertEqual(meta["before"]["bpm"], c["bpm"])
                    self.assertGreater(after["notes"], 0)
                    self.assertLess(after["notes"], meta["before"]["notes"])
                    self.assertLessEqual(meta["before"]["notes"] - after["notes"],
                                         int(meta["before"]["notes"] * CAPS[difficulty]))
                    for key in ("peak_half_second_inputs", "peak_one_second_inputs", "peak_five_second_inputs",
                                "fast_direction_changes_under_170ms", "arrows_within_250ms_of_space",
                                "longest_active_run_seconds"):
                        self.assertLessEqual(after[key], meta["before"][key], (folder.name, difficulty, key))
            self.assertEqual(counts, sorted(set(counts)))
            self.assertEqual(rests[0], rests[1])
            self.assertEqual(rests[1], rests[2])
        self.assertEqual(revised_count, 108)

    def test_existing_revisions_are_not_rebalanced(self):
        for song in ("bad_apple", "freedom_dive", "immortal_flame"):
            charts = [json.loads((ROOT / "charts" / song / (d + ".json")).read_text(encoding="utf-8"))
                      for d in ("normal", "hard", "master")]
            source = copy.deepcopy(charts)
            self.assertIs(revise_group(charts), charts)
            self.assertEqual(charts, source)
        charts[0].pop("pacing_meta")
        with self.assertRaises(ValueError):
            revise_group(charts)

    def test_recipe_preserves_authored_inputs_and_timing(self):
        charts = []
        for difficulty in ("normal", "hard", "master"):
            charts.append({"song_id": "synthetic_qa", "chart_difficulty": difficulty,
                           "bpm": 120, "beat_offset": 0, "duration": 150, "audio": "fixture.ogg",
                           "timing_grid": {"fixture": True}, "recommended": "fixture",
                           "sections": [{"role": "bridge", "energy": .1, "start": 60, "end": 68}],
                           "events": [{"time": i * .5, "direction": i % 8, "type": "normal"}
                                      for i in range(1, 280)], "space_events": [20, 62, 90]})
        source = copy.deepcopy(charts)
        result = revise_group(charts)
        self.assertEqual(charts, source)
        for old, new in zip(charts, result):
            self.assertEqual(old["events"][0], new["events"][0])
            self.assertEqual(old["events"][-1], new["events"][-1])
            self.assertTrue(all(e in old["events"] for e in new["events"]))
            self.assertTrue(all(t in old["space_events"] for t in new["space_events"]))
            for key in ("bpm", "beat_offset", "duration", "audio", "sections", "timing_grid"):
                self.assertEqual(old[key], new[key])


if __name__ == "__main__":
    unittest.main()
