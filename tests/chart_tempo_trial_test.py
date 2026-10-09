"""Behavior/data checks for experimental Bad Apple grid, Python 3.7."""
import copy
import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from chart_tempo_trial import retime


class TempoTrialTest(unittest.TestCase):
    def test_recipe_keeps_source_and_beat_indices(self):
        source = {"song_id": "bad_apple", "bpm": 140, "beat_offset": 1.287429, "duration": 324,
                  "events": [{"time": 10, "type": "reverse", "direction": 7}], "space_events": [11],
                  "pacing_meta": {"after": {}, "rest_intervals": [[20, 27]]}, "chart_design": {}}
        original = copy.deepcopy(source)
        result = retime(source)
        self.assertEqual(source, original)
        self.assertAlmostEqual((result["events"][0]["time"] - 1.43) * 138 / 60, (10 - 1.287429) * 140 / 60, places=5)
        self.assertEqual(result["events"][0]["direction"], 7)
        self.assertEqual(result["events"][0]["type"], "reverse")
        self.assertEqual(result["duration"], 324)
        with self.assertRaises(ValueError):
            retime(result)
        source["events"][0]["time"] = 323
        with self.assertRaises(ValueError):
            retime(source)

    def test_shipped_trial(self):
        for difficulty in ["normal", "hard", "master"]:
            chart = json.loads((ROOT / "charts/bad_apple" / (difficulty + ".json")).read_text(encoding="utf-8"))
            trial = chart["tempo_trial"]
            self.assertEqual(chart["bpm"], 138)
            self.assertEqual(chart["beat_offset"], 1.43)
            self.assertEqual(len(chart["events"]), trial["arrow_count"])
            self.assertEqual(len(chart["space_events"]), trial["space_count"])
            self.assertEqual(chart["duration"], 324.115782)
            for times in [[e["time"] for e in chart["events"]], chart["space_events"]]:
                self.assertEqual(times, sorted(set(times)))
                self.assertTrue(all(0 <= t <= chart["duration"] for t in times))
                # Preserve authored quarter-beat positions, not free onset snapping.
                for time in times:
                    phase = (time - chart["beat_offset"]) * chart["bpm"] / 60 * 4
                    self.assertAlmostEqual(phase, round(phase), places=4)


if __name__ == "__main__":
    unittest.main()
