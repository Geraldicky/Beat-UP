"""Pure offline retiming recipe; no file writes or runtime settings changes."""
import copy
import hashlib
import json
from chart_pacing_audit import audit


def retime(source, bpm=138.0, anchor=1.43):
    if "tempo_trial" in source:
        raise ValueError("Already retimed; refusing double application")
    if source.get("song_id") != "bad_apple":
        raise ValueError("This musical pilot is only for Bad Apple")
    chart = copy.deepcopy(source)
    previous_bpm = float(source["bpm"])
    previous_anchor = float(source["beat_offset"])
    duration = float(source["duration"])

    def target(time):
        return round(anchor + (float(time) - previous_anchor) * previous_bpm / bpm, 6)

    for event in chart["events"]:
        event["time"] = target(event["time"])
    chart["space_events"] = [target(t) for t in source["space_events"]]
    if any(t < 0 or t > duration for t in [e["time"] for e in chart["events"]] + chart["space_events"]):
        raise ValueError("Retiming would put inputs outside audio; no silent clipping")
    chart["bpm"] = bpm
    chart["beat_offset"] = anchor
    for section in chart.get("sections", []):
        section["start"] = max(0.0, min(duration, target(section["start"])))
        section["end"] = max(0.0, min(duration, target(section["end"])))
    pacing = chart["pacing_meta"]
    pacing["rest_intervals"] = [[target(a), target(b)] for a, b in pacing["rest_intervals"]]
    pacing["after"] = audit(chart)
    chart["timing_grid"] = dict(source.get("timing_grid", {}), mode="experimental_librosa_138_playtest",
                                bpm=bpm, beat_offset=anchor,
                                timestamp_policy="absolute_times_retimed_preserving_authored_beat_indices")
    for key in ["phase_refinement_ms", "phase_score"]:
        chart["timing_grid"].pop(key, None)
    chart["chart_design"]["timing_rule"] = "Experimental 138 BPM grid / 1.43s anchor; requires audible playtest, not verified mapping."
    chart["tempo_trial"] = {
        "revision": "bad_apple_138_playtest_2026_10_04", "status": "experimental_requires_playtest",
        "previous_bpm": previous_bpm, "previous_anchor_s": previous_anchor,
        "candidate_bpm": bpm, "candidate_anchor_s": anchor,
        "rationale": "Detected beat sequence fits about 137.995 BPM; first detected attack 1.428s rounded to 1.43s. Not musical ground truth.",
        "formula": "new_anchor + (old_time - old_anchor) * old_bpm / new_bpm",
        "previous_timing_grid": source.get("timing_grid", {}),
        "previous_chart_design": source.get("chart_design", {}),
        "source_inputs_sha256": hashlib.sha256(json.dumps([source["events"], source["space_events"]], sort_keys=True).encode()).hexdigest(),
        "previous_pacing_metrics": source["pacing_meta"]["after"],
        "arrow_count": len(source["events"]), "space_count": len(source["space_events"]),
    }
    return chart
