"""Read-only authored-chart pacing audit (Python 3.7+, no game dependencies).

Windows are half-open. Rest/continuous-run metrics include SPACE; a directional
gap with a Space hit inside it is not a rest. Intro/outro silence is excluded.
"""
import argparse
import json
from pathlib import Path


def peak_count(times, seconds):
    left = 0
    peak = 0
    for right, time in enumerate(times):
        while left <= right and time - times[left] >= seconds - 1e-7:
            left += 1
        peak = max(peak, right - left + 1)
    return peak


def audit(chart, rest_seconds=3.0):
    events = chart.get("events", [])
    arrows = sorted(float(e["time"]) for e in events)
    spaces = sorted(float(t) for t in chart.get("space_events", []))
    times = sorted(arrows + spaces)
    gaps = [(a, b) for a, b in zip(times, times[1:]) if b - a >= rest_seconds]
    longest = 0.0
    if times:
        start = times[0]
        for a, b in gaps:
            longest = max(longest, a - start)
            start = b
        longest = max(longest, times[-1] - start)
    transitions = [(a, b) for a, b in zip(events, events[1:])
                   if float(b["time"]) - float(a["time"]) < 0.17
                   and int(a["direction"]) != int(b["direction"])]
    near_space = sum(1 for event in events if any(
        abs(float(event["time"]) - t) < 0.25 for t in spaces))
    return {
        "song_id": chart.get("song_id", chart.get("id")),
        "difficulty": chart.get("chart_difficulty"),
        "bpm": chart.get("bpm"), "duration": chart.get("duration"),
        "notes": len(events), "spaces": len(spaces),
        "average_inputs_per_second": round(len(times) / max(1.0, float(chart.get("duration", 0))), 3),
        "peak_half_second_inputs": peak_count(times, 0.5),
        "peak_one_second_inputs": peak_count(times, 1.0),
        "peak_five_second_inputs": peak_count(times, 5.0),
        "fast_direction_changes_under_170ms": len(transitions),
        "arrows_within_250ms_of_space": near_space,
        "rest_threshold_seconds": rest_seconds,
        "rests": [[round(a, 6), round(b, 6)] for a, b in gaps],
        "longest_active_run_seconds": round(longest, 3),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", type=Path)
    args = parser.parse_args()
    paths = args.paths or sorted((Path(__file__).resolve().parents[1] / "charts").glob("*/*.json"))
    for path in paths:
        chart = json.loads(path.read_text(encoding="utf-8"))
        print(json.dumps(dict(audit(chart), path=path.as_posix()), ensure_ascii=True))


if __name__ == "__main__":
    main()
