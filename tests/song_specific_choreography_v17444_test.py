from pathlib import Path
import itertools
import json
import math
from collections import Counter

ROOT = Path(__file__).resolve().parents[1]
CHART_ROOT = ROOT / "charts"
DIRECTIONS = (1, 2, 3, 4, 6, 7, 8, 9)
RING = (8, 9, 6, 3, 2, 1, 4, 7)
RING_POS = {d: i for i, d in enumerate(RING)}


def max_ring_run(sequence):
    if not sequence:
        return 0
    best = 1
    run = 1
    previous_step = 0
    for a, b in zip(sequence, sequence[1:]):
        raw = (RING_POS[b] - RING_POS[a]) % len(RING)
        step = 1 if raw == 1 else (-1 if raw == len(RING) - 1 else 0)
        if step and step == previous_step:
            run += 1
        elif step:
            run = 2
        else:
            run = 1
        previous_step = step
        best = max(best, run)
    return best


def has_adjacent_repeat(sequence, block_size):
    for end in range(block_size * 2, len(sequence) + 1):
        if sequence[end - block_size * 2:end - block_size] == sequence[end - block_size:end]:
            return True
    return False


def periodic_match(sequence, period):
    if len(sequence) <= period:
        return 0.0
    return sum(sequence[i] == sequence[i - period] for i in range(period, len(sequence))) / (len(sequence) - period)


def ngrams(sequence, size):
    return {tuple(sequence[i:i + size]) for i in range(len(sequence) - size + 1)}


project_text = (ROOT / "project.godot").read_text(encoding="utf-8")

chart_paths = sorted(CHART_ROOT.glob("*/*.json"))
assert len(chart_paths) == 117, len(chart_paths)
song_ids = sorted({path.parent.name for path in chart_paths})
assert len(song_ids) == 39, len(song_ids)

sequences = {}
fingerprints = {}
for path in chart_paths:
    data = json.loads(path.read_text(encoding="utf-8"))
    song_id = data["song_id"]
    difficulty = data["chart_difficulty"]
    events = data.get("events", [])
    sequence = [int(event["direction"]) for event in events]
    assert sequence, path
    assert set(sequence).issubset(DIRECTIONS), path
    assert data.get("direction_profile", {}).get("version") == "song_specific_choreography_v17444", path
    assert data["direction_profile"].get("template_motif_bank") is False, path
    assert data["direction_profile"].get("song_specific") is True, path
    assert data["direction_profile"].get("shared_song_dna_across_difficulties") is True, path
    assert data.get("generator_meta", {}).get("choreography_version") == "17.4.44", path
    assert data.get("difficulty_profile", {}).get("choreography_version") == "17.4.44", path
    assert max_ring_run(sequence) <= 3, path
    assert not any(has_adjacent_repeat(sequence, size) for size in range(2, 13)), path
    assert max(periodic_match(sequence, p) for p in range(2, 13)) < 0.34, path
    sequences[(song_id, difficulty)] = sequence
    fingerprints.setdefault(song_id, set()).add(data["direction_profile"]["rhythm_and_section_fingerprint"])

for song_id, values in fingerprints.items():
    assert len(values) == 1, (song_id, values)

# The exact old global orbit template must not survive in either reported problem song.
old_template = (7, 8, 9, 6, 3, 2, 1, 4)
for song_id in ("united_laos_remix", "at_the_speed_of_light"):
    for difficulty in ("normal", "hard", "master"):
        sequence = sequences[(song_id, difficulty)]
        assert old_template not in [tuple(sequence[i:i + 8]) for i in range(len(sequence) - 7)]

# Cross-song exact 6-note vocabulary overlap is bounded. This is a regression guard
# against reintroducing one shared template bank across the entire library.
max_cross_jaccard = 0.0
for difficulty in ("normal", "hard", "master"):
    for song_a, song_b in itertools.combinations(song_ids, 2):
        a = ngrams(sequences[(song_a, difficulty)], 6)
        b = ngrams(sequences[(song_b, difficulty)], 6)
        jaccard = len(a & b) / max(1, len(a | b))
        max_cross_jaccard = max(max_cross_jaccard, jaccard)
assert max_cross_jaccard < 0.06, max_cross_jaccard

assert not list(ROOT.rglob("*.flac")), "FLAC masters must remain external to distributable project"
assert not [p for p in ROOT.rglob("*.json") if "manifest" in p.name.lower()], "No manifest JSON files should exist"
print(f"v17.4.44 song-specific choreography checks passed; max cross-song 6-gram Jaccard={max_cross_jaccard:.4f}")
