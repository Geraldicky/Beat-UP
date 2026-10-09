"""Read-only chart/audio QA. Generates artifacts only in a NEW output directory.

Python 3.12 + requirements-audio-qa.txt + ffmpeg. Never edits a chart, game audio,
settings, or catalog. Audio onset/beat estimates are candidates, not ground truth.
Positive candidate shift means moving the chart later relative to source audio,
NOT a recommendation for Beat UP!'s user-offset controls.
"""
import argparse
import csv
import hashlib
import json
import math
import subprocess
from pathlib import Path

import librosa
import numpy as np
import soundfile as sf

SR = 22050
HOP = 128


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def nearest_deltas(times, targets):
    """target minus input, with no one-to-one or musical correspondence claim."""
    times = np.asarray(times, dtype=float)
    targets = np.asarray(targets, dtype=float)
    if not len(targets):
        return np.full(len(times), np.nan)
    right = np.clip(np.searchsorted(targets, times), 0, len(targets) - 1)
    left = np.maximum(right - 1, 0)
    choose_left = np.abs(targets[left] - times) <= np.abs(targets[right] - times)
    return targets[np.where(choose_left, left, right)] - times


def phase_residual(times, bpm, offset):
    beat = 60.0 / bpm
    return (np.asarray(times) - offset + beat / 2.0) % beat - beat / 2.0


def scan_shift(times, envelope, sample_rate=SR, hop=HOP):
    times = np.asarray(times, dtype=float)
    axis = np.arange(len(envelope)) * hop / sample_rate
    # Only compare inputs safely inside the analysis region for every shift.
    times = times[(times >= 0.25) & (times <= axis[-1] - 0.25)]
    shifts = np.linspace(-0.2, 0.2, 81)
    scores = np.asarray([np.mean(np.interp(times + s, axis, envelope)) if len(times) else 0.0 for s in shifts])
    if not len(times) or not np.any(envelope):
        return {"candidate_shift_ms": None, "score_at_zero": 0.0, "best_score": 0.0, "relative_gain": 0.0}
    best = int(np.argmax(scores))
    zero = float(scores[40])
    return {"candidate_shift_ms": round(float(shifts[best] * 1000), 1),
            "score_at_zero": round(zero, 5), "best_score": round(float(scores[best]), 5),
            "relative_gain": round(float(scores[best]) / max(zero, 1e-9) - 1.0, 4)}


def click_track(length, sample_rate, arrows, spaces):
    track = np.zeros(length, dtype=np.float32)
    for times, frequency, gain in [(arrows, 1600, 0.32), (spaces, 700, 0.48)]:
        count = int(sample_rate * 0.025)
        t = np.arange(count) / sample_rate
        click = gain * np.cos(2 * np.pi * frequency * t) * np.exp(-t * 180)
        for time in times:
            start = int(round(time * sample_rate))
            if start < 0 or start >= length:
                raise ValueError("Chart input outside decoded audio: {}".format(time))
            size = min(count, length - start)
            track[start:start + size] += click[:size]
    return track


def analyze_audio(path, ffmpeg):
    result = subprocess.run([ffmpeg, "-v", "error", "-i", str(path), "-f", "f32le", "-ac", "1", "-ar", str(SR), "pipe:1"],
                            check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    y = np.frombuffer(result.stdout, dtype="<f4").copy()
    if not len(y) or not np.all(np.isfinite(y)):
        raise ValueError("Empty/nonfinite decoded audio")
    envelope = librosa.onset.onset_strength(y=y, sr=SR, hop_length=HOP)
    # Full-song normalization can let a loud intro mask later softer attacks.
    # Detect in overlapping 30s windows, using 1s context at each boundary.
    onset_frames = []
    window = int(round(30 * SR / HOP))
    context = int(round(SR / HOP))
    for start in range(0, len(envelope), window):
        end = min(start + window, len(envelope))
        left, right = max(0, start - context), min(len(envelope), end + context)
        found = librosa.onset.onset_detect(onset_envelope=envelope[left:right], sr=SR, hop_length=HOP,
                                          units="frames", backtrack=False, delta=0.03) + left
        onset_frames.extend(int(f) for f in found if start <= f < end)
    onsets = librosa.frames_to_time(np.asarray(sorted(set(onset_frames))), sr=SR, hop_length=HOP)
    tempo, beats = librosa.beat.beat_track(onset_envelope=envelope, sr=SR, hop_length=HOP, units="time")
    return y, envelope, onsets, beats, float(np.asarray(tempo).reshape(-1)[0])


def report_chart(chart, audio_data):
    y, envelope, onsets, beats, tempo = audio_data
    bpm = float(chart["bpm"])
    offset = float(chart.get("beat_offset", 0))
    fine_offset = float(chart.get("chart_offset_ms", 0)) / 1000.0
    # Production load_chart_events/load_space_events adds authored fine offset.
    arrows = np.asarray([float(e["time"]) + fine_offset for e in chart["events"]])
    spaces = np.asarray(chart.get("space_events", []), dtype=float) + fine_offset
    all_inputs = np.sort(np.concatenate([arrows, spaces]))
    grid = np.arange(offset, len(y) / SR, 60.0 / bpm)
    grid = grid[grid >= 0]
    local = []
    for start in range(0, int(math.ceil(len(y) / SR)), 30):
        end = min(start + 30, len(y) / SR)
        local_grid = grid[(grid >= start + 0.25) & (grid < end - 0.25)]
        if len(local_grid) < 8:
            continue
        local.append(dict(start_s=start, end_s=round(end, 3), **scan_shift(local_grid, envelope)))
    delta = nearest_deltas(all_inputs, onsets)
    phase = phase_residual(beats, bpm, offset)
    fitted_bpm = None
    if len(beats) >= 8:
        # Only a candidate: assumes the tracker's beat indexing is correct.
        period = float(np.polyfit(np.arange(len(beats)), beats, 1)[0])
        fitted_bpm = round(60.0 / period, 4) if period > 0 else None
    return {
        "song_id": chart["song_id"], "difficulty": chart["chart_difficulty"],
        "chart_bpm": bpm, "chart_beat_offset_s": offset, "chart_fine_offset_ms": fine_offset * 1000,
        "decoded_duration_s": round(len(y) / SR, 6), "chart_duration_s": chart.get("duration"),
        "automatic_bpm_unconstrained": round(tempo, 4), "detected_beats": len(beats), "detected_onsets": len(onsets),
        "detected_beat_sequence_fitted_bpm_NOT_authoritative": fitted_bpm,
        "detected_beat_coverage_s": [round(float(beats[0]), 3), round(float(beats[-1]), 3)] if len(beats) else [],
        "beat_grid_shift_probe": scan_shift(grid, envelope),
        "retained_inputs_shift_probe": scan_shift(all_inputs, envelope),
        "grid_shift_by_30s_window": local,
        "nearest_onset_absolute_distance_ms_median": round(float(np.median(np.abs(delta))) * 1000, 2) if len(onsets) else None,
        "inputs_with_detected_onset_within_50ms_fraction": round(float(np.mean(np.abs(delta) <= 0.05)), 4) if len(onsets) else None,
        "detected_beat_grid_phase_ms_median": round(float(np.median(phase)) * 1000, 2) if len(phase) else None,
        "limitations": [
            "Beat/onset estimates are not musical ground truth; tempo can be half/double time. Onsets use overlapping locally normalized 30s windows.",
            "Nearest onset is not necessarily the intended instrument/beat; distance is NOT a chart accuracy score.",
            "Onset envelope has analysis/signal attack bias; a small positive shift does not prove audible lateness.",
            "Window phase shifts are periodic/ambiguous and do not alone establish tempo drift.",
            "Decoded-file analysis does not measure Godot playback, hardware latency, user offsets, RANDOM, or reverse projection.",
            "No automatic correction is applied. Listening/playtest is required before changing source timestamps.",
        ],
    }, arrows, spaces


def write_plot(path, y, envelope, onsets, grid, arrows, spaces):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    # Repeatable excerpts across the song, not a selectively chosen good region.
    starts = [10, 90, 180, 270]
    fig, axes = plt.subplots(len(starts), 1, figsize=(16, 10))
    for ax, start in zip(axes, starts):
        end = min(start + 8, len(y) / SR)
        if end <= start:
            ax.set_visible(False)
            continue
        a, b = int(start * SR), int(end * SR)
        stride = 32
        ax.plot(np.arange(a, b, stride) / SR, y[a:b:stride], color="#929ba8", alpha=0.5, linewidth=0.5)
        for times, color, label, top in [(grid, "#68bf91", "Authored full-beat grid", 1),
                                       (onsets, "#c6aef0", "Detected onsets", 0.85),
                                       (arrows, "#48bdff", "Arrow inputs", 0.7),
                                       (spaces, "#eeb747", "SPACE inputs", 0.55)]:
            visible = times[(times >= start) & (times < end)]
            ax.vlines(visible, -top, top, color=color, alpha=0.8, linewidth=0.8, label=label)
        ax.set_xlim(start, end)
        ax.set_title("{}–{} s: source audio / grid / chart".format(start, end))
        ax.set_xlabel("Seconds (absolute audio time)")
    axes[0].legend(loc="upper right", fontsize=8)
    fig.tight_layout()
    fig.savefig(path, dpi=120)
    plt.close(fig)


def run(root, chart_paths, output, ffmpeg):
    root = root.resolve()
    output = output.resolve()
    # Output cannot sit in a source/content tree or overlap any source file.
    if root == output or root in output.parents:
        raise ValueError("Output must be outside repository, in a new QA directory")
    output.mkdir(parents=True, exist_ok=False)
    cache = {}
    summary = []
    seen = set()
    for chart_path in chart_paths:
        chart_path = chart_path.resolve()
        chart_hash = sha256(chart_path)
        chart = json.loads(chart_path.read_text(encoding="utf-8"))
        audio_name = chart["audio"]
        if not audio_name.startswith("res://"):
            raise ValueError("This pilot accepts bundled res:// audio only; no user content")
        audio_path = (root / audio_name[6:]).resolve()
        if root not in audio_path.parents:
            raise ValueError("Audio escapes repository")
        if audio_path not in cache:
            print("Analyzing {} with librosa {}".format(audio_path.name, librosa.__version__), flush=True)
            cache[audio_path] = (analyze_audio(audio_path, ffmpeg), sha256(audio_path))
        audio_data, audio_hash = cache[audio_path]
        report, arrows, spaces = report_chart(chart, audio_data)
        name = "{}_{}".format(chart["song_id"], chart["chart_difficulty"])
        if any(c not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-" for c in name):
            raise ValueError("Unsafe artifact identity")
        if name in seen:
            raise ValueError("Duplicate artifact identity; refusing overwrite")
        seen.add(name)
        report.update(chart_path=str(chart_path), chart_sha256=chart_hash,
                      audio_path=str(audio_path), audio_sha256=audio_hash,
                      librosa_version=librosa.__version__, sample_rate=SR, hop_samples=HOP)
        report["numpy_version"] = np.__version__
        report["soundfile_version"] = sf.__version__
        y, envelope, onsets, beats, tempo = audio_data
        clicks = click_track(len(y), SR, arrows, spaces)
        # Fixed headroom, no time shifting or truncation. Preserve sample count.
        sf.write(str(output / (name + "_preview.wav")), np.clip(y * 0.5 + clicks, -0.98, 0.98), SR, subtype="PCM_16")
        sf.write(str(output / (name + "_clicks.wav")), clicks, SR, subtype="PCM_16")
        with (output / (name + "_detected.csv")).open("w", newline="", encoding="utf-8") as handle:
            writer = csv.writer(handle)
            writer.writerow(["candidate_kind", "time_s"])
            for kind, times in [("onset", onsets), ("beat", beats)]:
                writer.writerows((kind, round(float(t), 6)) for t in times)
        with (output / (name + "_events.csv")).open("w", newline="", encoding="utf-8") as handle:
            writer = csv.writer(handle)
            writer.writerow(["channel", "time_s", "nearest_detected_onset_delta_ms_NOT_correctness"])
            for channel, times in [("arrow", arrows), ("space", spaces)]:
                for time, delta in zip(times, nearest_deltas(times, onsets)):
                    writer.writerow([channel, round(float(time), 6), round(float(delta * 1000), 3)])
        grid = np.arange(float(chart.get("beat_offset", 0)), len(y) / SR, 60 / float(chart["bpm"]))
        write_plot(output / (name + "_waveform.png"), y, envelope, onsets, grid, arrows, spaces)
        (output / (name + "_report.json")).write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        if sha256(chart_path) != chart_hash or sha256(audio_path) != audio_hash:
            raise RuntimeError("Source changed during audit")
        summary.append(report)
        print(name, report["beat_grid_shift_probe"], flush=True)
    (output / "summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print("Read-only QA artifacts: {}".format(output), flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("charts", type=Path, nargs="+")
    parser.add_argument("--output", type=Path, required=True, help="New directory OUTSIDE repository; existing paths refused")
    parser.add_argument("--ffmpeg", default="ffmpeg")
    args = parser.parse_args()
    run(Path(__file__).resolve().parents[1], args.charts, args.output, args.ffmpeg)


if __name__ == "__main__":
    main()
