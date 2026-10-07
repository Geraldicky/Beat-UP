"""Optional audio QA regression; use tools/requirements-audio-qa.txt env."""
import copy
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import numpy as np
import soundfile as sf
from chart_audio_audit import analyze_audio, click_track, nearest_deltas, phase_residual, report_chart, run, scan_shift


class AudioAuditTest(unittest.TestCase):
    def test_nearest_onset_sign_and_empty(self):
        np.testing.assert_allclose(nearest_deltas([1, 2, 3], [1.02, 1.98, 3.1]), [0.02, -0.02, 0.1])
        self.assertTrue(np.isnan(nearest_deltas([1], [])).all())

    def test_known_phase_shift(self):
        times = np.arange(0.5, 10, 0.5)
        envelope = np.zeros(1101)
        envelope[((times + 0.08) * 100).round().astype(int)] = 1
        self.assertAlmostEqual(scan_shift(times, envelope, 100, 1)["candidate_shift_ms"], 80)
        self.assertIsNone(scan_shift(times, np.zeros(1101), 100, 1)["candidate_shift_ms"])
        np.testing.assert_allclose(phase_residual([1.08, 1.58, 2.08], 120, 0), 0.08)

    def test_click_sample_positions_and_space_distinction(self):
        clicks = click_track(3000, 1000, [1], [2])
        self.assertEqual(len(clicks), 3000)
        self.assertEqual(np.count_nonzero(clicks[:1000]), 0)
        self.assertAlmostEqual(float(clicks[1000]), 0.32, places=6)
        self.assertAlmostEqual(float(clicks[2000]), 0.48, places=6)
        with self.assertRaises(ValueError):
            click_track(1000, 1000, [2], [])

    def test_report_keeps_absolute_times_and_source(self):
        chart = {"song_id": "qa", "chart_difficulty": "normal", "bpm": 120, "beat_offset": 0.7,
                 "chart_offset_ms": 25, "events": [{"time": 1.0}], "space_events": [2.0]}
        original = copy.deepcopy(chart)
        audio = (np.zeros(22050 * 4), np.ones(690), np.asarray([1.025, 2.025]), np.asarray([0.7, 1.2]), 120)
        report, arrows, spaces = report_chart(chart, audio)
        self.assertEqual(chart, original)
        self.assertAlmostEqual(arrows[0], 1.025)
        self.assertAlmostEqual(spaces[0], 2.025)
        self.assertEqual(report["nearest_onset_absolute_distance_ms_median"], 0)

    def test_existing_output_and_repository_output_refused(self):
        root = Path(__file__).resolve().parents[1]
        with self.assertRaises(ValueError):
            run(root, [], root / "qa-output-do-not-create", "ffmpeg")
        with tempfile.TemporaryDirectory() as directory:
            marker = Path(directory) / "real-settings-sentinel"
            marker.write_text("untouched", encoding="utf-8")
            with self.assertRaises(FileExistsError):
                run(root, [], Path(directory), "ffmpeg")
            self.assertEqual(marker.read_text(encoding="utf-8"), "untouched")

    def test_real_librosa_known_120_bpm_audio(self):
        # Synthetic metronome, not a real song. Locks decode duration and units
        # through actual ffmpeg + librosa rather than mocked detection arrays.
        sr = 22050
        times = np.arange(1.0, 19.5, 0.5)
        y = click_track(20 * sr, sr, times, [])
        with tempfile.TemporaryDirectory(prefix="beatup-audio-fixture-") as directory:
            source = Path(directory) / "metronome.wav"
            sf.write(str(source), y, sr, subtype="PCM_16")
            before = source.read_bytes()
            decoded, envelope, onsets, beats, tempo = analyze_audio(source, "ffmpeg")
            self.assertEqual(source.read_bytes(), before)
        self.assertEqual(len(decoded), len(y))
        self.assertLess(abs(tempo - 120), 2.0)
        self.assertGreater(len(beats), 30)
        self.assertLess(float(np.median(np.abs(nearest_deltas(times, onsets)))), 0.04)


if __name__ == "__main__":
    unittest.main()
