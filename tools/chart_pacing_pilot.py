"""Offline, data-only pilot recipe. Never writes charts or touches user data.

Retained notes keep their authored time/type/direction. Rest candidates come
from existing section analysis, not an arbitrary periodic silence timer.
"""
import copy
import json
from pathlib import Path
from chart_pacing_audit import audit


# (section start, length in beats). All are within quieter authored sections.
RESTS = {
    "immortal_flame": [(148.565677, 8), (253.292950, 8)],
    "bad_apple": [(111.001715, 16), (220.716000, 16)],
    "freedom_dive": [(28.427600, 16), (84.587600, 16), (196.907600, 16)],
}
MIN_GAP = {"normal": 0.20, "hard": 0.15, "master": 0.10}
EXTRA_REMOVAL_BUDGET = {"normal": 0.12, "hard": 0.08, "master": 0.02}


def rebalance(source, rest_recipe=None, revision="pilot_2026_10_04", removal_cap=None):
    chart = copy.deepcopy(source)
    song = chart["song_id"]
    difficulty = chart["chart_difficulty"]
    beat = 60.0 / float(chart["bpm"])
    rests = [(start, round(start + beats * beat, 6)) for start, beats in
             (RESTS[song] if rest_recipe is None else rest_recipe)]
    inside = lambda time: any(a - 1e-6 <= time < b - 1e-6 for a, b in rests)
    spaces = [t for t in chart["space_events"] if not inside(float(t))]
    notes = [e for e in chart["events"] if not inside(float(e["time"]))]
    # SPACE is a separate required action: avoid almost simultaneous arrows.
    # This removes authored slots, never moves a timestamp or adds an input.
    protected = [source["events"][0], source["events"][-1]]
    cap = len(source["events"]) if removal_cap is None else int(len(source["events"]) * removal_cap)
    if len(source["events"]) - len(notes) > cap:
        raise ValueError("Rest recipe exceeds removal cap")
    for event in list(notes):
        if len(source["events"]) - len(notes) >= cap:
            break
        if event not in protected and any(abs(float(event["time"]) - t) < 0.20 for t in spaces):
            notes.remove(event)
    budget = int(len(source["events"]) * EXTRA_REMOVAL_BUDGET[difficulty])
    removed = 0
    offset = float(chart["beat_offset"])
    while removed < budget and len(source["events"]) - len(notes) < cap:
        candidates = []
        for i in range(1, len(notes) - 1):
            time = float(notes[i]["time"])
            if time - float(notes[i - 1]["time"]) >= MIN_GAP[difficulty] - 1e-6:
                continue
            # Prefer weaker subdivisions; full-beat anchors are retained.
            phase = (time - offset) / beat
            distance = abs(phase - round(phase))
            if distance > 0.1:
                candidates.append((distance, -time, i))
        if not candidates:
            break
        del notes[max(candidates)[2]]
        removed += 1
    chart["events"] = notes
    chart["space_events"] = spaces
    reverse_count = sum(e["type"] == "reverse" for e in notes)
    chart["recommended"] = chart["recommended"].replace(
        "{} notes".format(len(source["events"])), "{} notes".format(len(notes))).replace(
        "{} SPACE".format(len(source["space_events"])), "{} SPACE".format(len(spaces)))
    # Count fields only; historical generator diagnostics are kept as provenance.
    profile = chart.get("difficulty_profile", {})
    for key, value in [("note_count", len(notes)), ("reverse_count", reverse_count), ("space_count", len(spaces))]:
        if key in profile:
            profile[key] = value
    if "reverse" in chart.get("special_note_counts", {}):
        chart["special_note_counts"]["reverse"] = reverse_count
    chart["pacing_meta"] = {
        "revision": revision,
        "rest_intervals": [list(pair) for pair in rests],
        "before": audit(source),
        "after": audit(chart),
        "subdivision_notes_removed": removed,
        "historical_generator_metadata": "Describes original generation; pacing_meta.after describes this revision.",
    }
    return chart


if __name__ == "__main__":
    root = Path(__file__).resolve().parents[1]
    for song in RESTS:
        for difficulty in MIN_GAP:
            source = json.loads((root / "charts" / song / (difficulty + ".json")).read_text(encoding="utf-8"))
            if "pacing_meta" in source:
                raise SystemExit("Already revised: recipe must be applied to original charts, not twice")
            print(json.dumps(rebalance(source), ensure_ascii=False, indent="\t"))
