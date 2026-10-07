"""Offline full-library pacing plan; Python 3.7. Outputs patches, never writes.

Existing pacing revisions (including the tempo playtest) are skipped. Section
energy/roles are historical generator estimates, not verified audio annotations.
"""
import argparse
import difflib
import json
from pathlib import Path
from chart_pacing_pilot import rebalance

ROOT = Path(__file__).resolve().parents[1]
REVISION = "library_2026_10_05"
CAPS = {"normal": 0.25, "hard": 0.20, "master": 0.10}


def plan_rests(charts):
    reference = charts[0]
    beat = 60.0 / float(reference["bpm"])
    beats = 8 if 8 * beat > 3.25 else 16
    length = beats * beat
    first = max(c["events"][0]["time"] for c in charts)
    last = min(c["events"][-1]["time"] for c in charts)
    candidates = []
    for section in reference["sections"]:
        role = section["role"]
        if role not in ("bridge", "interlude", "verse"):
            continue
        start = float(section["start"])
        # Candidate starts stay on the existing section beat grid.
        while start + length <= float(section["end"]) + 1e-6:
            if start > first + 15 and start + length < last - 1:
                candidates.append((role == "verse", float(section["energy"]), round(start, 6)))
            start += 16 * beat
    selected = []
    target = max(1, min(4, int(float(reference["duration"]) / 90)))
    for _, _, start in sorted(candidates):
        if any(abs(start - old) < 40 for old, _ in selected):
            continue
        proposed = selected + [(start, beats)]
        # Leave a little budget for collision/subdivision relief on Master.
        if any(sum(any(a - 1e-6 <= e["time"] < a + b * beat - 1e-6
                       for a, b in proposed) for e in c["events"])
               > int(len(c["events"]) * 0.08) for c in charts):
            continue
        selected = proposed
        if len(selected) == target:
            break
    if not selected:
        raise ValueError("No safe section-derived rest: " + reference["song_id"])
    return sorted(selected)


def revise_group(charts):
    if any("pacing_meta" in c for c in charts):
        if not all("pacing_meta" in c for c in charts):
            raise ValueError("Mixed pacing revisions in song group")
        return charts
    rests = plan_rests(charts)
    revised = [rebalance(c, rests, REVISION, CAPS[c["chart_difficulty"]]) for c in charts]
    for source, chart in zip(charts, revised):
        assert chart["events"][0] == source["events"][0]
        assert chart["events"][-1] == source["events"][-1]
        assert all(e in source["events"] for e in chart["events"])
        assert all(t in source["space_events"] for t in chart["space_events"])
        for key in ("bpm", "beat_offset", "duration", "audio", "sections", "timing_grid"):
            assert chart[key] == source[key], key
        for key in ("peak_half_second_inputs", "peak_one_second_inputs", "peak_five_second_inputs",
                    "fast_direction_changes_under_170ms", "arrows_within_250ms_of_space"):
            assert chart["pacing_meta"]["after"][key] <= chart["pacing_meta"]["before"][key], key
    return revised


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--patch-song")
    args = parser.parse_args()
    for folder in sorted((ROOT / "charts").iterdir()):
        if not folder.is_dir() or (args.patch_song and folder.name != args.patch_song):
            continue
        paths = [folder / (d + ".json") for d in ("normal", "hard", "master")]
        originals = [p.read_text(encoding="utf-8") for p in paths]
        charts = [json.loads(s) for s in originals]
        revised = revise_group(charts)
        if revised is charts:
            continue
        if args.patch_song:
            print("*** Begin Patch")
            for path, original, chart in zip(paths, originals, revised):
                updated = json.dumps(chart, ensure_ascii=False, indent="\t") + "\n"
                diff = list(difflib.unified_diff(original.splitlines(), updated.splitlines(), n=3))
                if diff:
                    print("*** Update File: " + path.relative_to(ROOT).as_posix())
                    for line in diff[2:]:
                        print("@@" if line.startswith("@@") else line)
            print("*** End Patch")
        else:
            print(json.dumps({"song": folder.name, "rests": revised[0]["pacing_meta"]["rest_intervals"],
                              "notes_before": [len(c["events"]) for c in charts],
                              "notes_after": [len(c["events"]) for c in revised]}))


if __name__ == "__main__":
    main()
