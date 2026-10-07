"""Behavioral/data regression for the nine-chart pacing pilot; Python 3.7."""
import copy
import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from chart_pacing_audit import audit, peak_count
from chart_pacing_pilot import rebalance, RESTS


class PacingTest(unittest.TestCase):
    def test_windows_and_space_interrupts_rest(self):
        self.assertEqual(peak_count([0, 0.5, 1.0], 1.0), 2)
        chart = {"duration": 12, "events": [{"time": t, "direction": 4} for t in [1, 9]], "space_events": [3, 5, 7]}
        self.assertEqual(audit(chart)["rests"], [])
        chart["space_events"] = []
        self.assertEqual(audit(chart)["rests"], [[1.0, 9.0]])

    def test_recipe_does_not_mutate_or_retime_source(self):
        source = {"song_id": "immortal_flame", "chart_difficulty": "master", "bpm": 110,
                  "beat_offset": 0, "duration": 300, "recommended": "4 notes • 2 SPACE",
                  "events": [{"time": t, "direction": 4, "type": "normal"} for t in [10, 149, 154, 280]],
                  "space_events": [150, 290]}
        original = copy.deepcopy(source)
        revised = rebalance(source)
        self.assertEqual(source, original)
        self.assertNotIn(150, revised["space_events"])
        for event in revised["events"]:
            self.assertIn(event, source["events"])
        self.assertEqual(revised["events"][0], source["events"][0])
        self.assertEqual(revised["events"][-1], source["events"][-1])

    def test_pilot_contract(self):
        for song in RESTS:
            counts = []
            for difficulty in ["normal", "hard", "master"]:
                chart = json.loads((ROOT / "charts" / song / (difficulty + ".json")).read_text(encoding="utf-8"))
                meta = chart["pacing_meta"]
                before, after = meta["before"], audit(chart)
                self.assertEqual(meta["after"], after)
                counts.append(after["notes"])
                for key in ["peak_half_second_inputs", "peak_one_second_inputs", "peak_five_second_inputs", "fast_direction_changes_under_170ms"]:
                    self.assertLessEqual(after[key], before[key], (song, difficulty, key))
                self.assertLess(after["longest_active_run_seconds"], before["longest_active_run_seconds"])
                self.assertEqual(after["arrows_within_250ms_of_space"] <= before["arrows_within_250ms_of_space"], True)
                if difficulty == "master":
                    reduction = 1 - after["notes"] / float(before["notes"])
                    self.assertGreater(reduction, 0.03)
                    self.assertLess(reduction, 0.12, "Master must remain a slight nerf")
                for start, end in meta["rest_intervals"]:
                    self.assertGreater(end - start, 3.0)
                    self.assertTrue(any(float(s["start"]) <= start + 1e-5 and float(s["end"]) >= end - 1e-5 for s in chart["sections"]))
                    times = [float(e["time"]) for e in chart["events"]] + chart["space_events"]
                    self.assertFalse(any(start - 1e-6 <= t < end - 1e-6 for t in times))
                self.assertEqual(before["duration"], after["duration"])
            self.assertEqual(counts, sorted(counts))
            self.assertEqual(len(set(counts)), 3)


if __name__ == "__main__":
    unittest.main()
