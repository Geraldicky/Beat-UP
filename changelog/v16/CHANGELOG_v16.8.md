# Beat UP! v16.8 — Gameplay Integrity & Chart Consistency

## Gameplay integrity
- Weighted accuracy: PERFECT 100%, GREAT 80%, GOOD 50%, MISS 0%.
- Rank thresholds recalibrated for weighted accuracy.
- Existing personal-best accuracy is migrated from stored PERFECT/GREAT/GOOD/MISS counts to the v16.8 weighted model.
- Gameplay duration now prefers the loaded audio stream length so stale JSON duration cannot end a song early.
- Judgment colors restored: PERFECT pink, GREAT green, GOOD cyan, MISS red.

## Charts
- Added structural ChartIntegrity validation to the catalog.
- Added data-driven 1–12★ estimator using average NPS, peak 1-second density, fast-gap pressure, difficulty tier, and special-note pressure.
- Normal: directional notes + SPACE.
- Hard: sparse deterministic Reverse notes.
- Master: sparse deterministic Reverse + Bomb notes.
- Ascend repaired from ~148.6s to the full ~226.8s bundled audio, including generated timing-aware tail events and SPACE accents.
- All bundled charts tagged with v16.8 integrity metadata; old generator revision is preserved where a chart was not fully regenerated.

## Generator
- Generator identity bumped to BUP-CG-01680 / 16.8.
- New generation now applies the sparse special-note pass after musical direction authoring.
- Generator validation accepts normal, reverse, and bomb notes.

## Engineering / release
- F2/F3/F4 development shortcuts are gated to editor/debug builds and do not activate in release builds.
- Obsolete `2_starting_over` zero-note regression expectation updated.
- Added `tests/gameplay_integrity_v168_test.gd`.
- Removed remaining user-facing `Numpad Blade` chart-file label and stale `UI SYSTEM 15.15` footer copy.
