# Beat UP! — CHANGELOG v17.4.17

## Objective
Standardize **Big Daddy NORMAL / HARD / MASTER** around the validated v17.4.16 HARD chart.

## Difficulty identities
- **NORMAL — readability-first**: first-read friendly, frequent recovery, low Reverse pressure, no inherited HARD difficulty cliffs.
- **HARD — stable pressure**: v17.4.16 telemetry-rebalanced chart is kept unchanged and acts as the middle anchor.
- **MASTER — complexity + sustained pressure**: retains longer streams, higher Reverse density, and higher information load while smoothing ordinary-note slots already proven problematic in HARD.

## Big Daddy changes
### NORMAL
- Notes: **616 → 608**
- Reverse: **37 → 37**
- SPACE: **14 → 14**
- Removed 8 ordinary-note slots that overlap telemetry-confirmed HARD difficulty-cliff positions.

### HARD
- Notes: **820 → 820**
- Reverse: **101 → 101**
- SPACE: **17 → 17**
- **No chart changes** from validated v17.4.16.

### MASTER
- Notes: **1050 → 1037**
- Reverse: **189 → 189**
- SPACE: **20 → 20**
- Removed 13 ordinary-note slots overlapping telemetry-confirmed HARD difficulty-cliff positions.
- Sustained MASTER streams remain intentionally harder than HARD.

## Invariants
- No retained note timestamp was moved.
- No retained note direction was changed.
- All Reverse notes are preserved in NORMAL and MASTER.
- All SPACE events are preserved.
- All non-Big-Daddy charts remain unchanged.

## Reproducibility
Run:
`python tools/standardize_big_daddy_difficulties_v17417.py`
