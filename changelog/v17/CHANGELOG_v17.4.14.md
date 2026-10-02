# Beat UP! v17.4.14 — Beta Telemetry Foundation

## Objective

Start collecting trustworthy local playtest data before Beta 1 chart rebalancing. This release records where each player run produces PERFECT, GREAT, GOOD, and MISS judgements without changing chart content or gameplay timing.

## Local-only telemetry

Telemetry is stored only on the player's machine under:

`user://playtest_data/`

No backend, network upload, account system, or cloud synchronization is introduced in v17.4.14.

## Session structure

Each attempt produces one JSON file in:

`user://playtest_data/sessions/<session_id>.json`

A lightweight index is maintained at:

`user://playtest_data/session_index.json`

Completed sessions include:
- app/schema version;
- song id/title/artist;
- difficulty;
- BPM and star rating;
- 4K/8K input style;
- Random mod state;
- Input Offset and Audio Offset;
- viewport resolution;
- pause count;
- final score, accuracy, max combo, rank;
- PERFECT/GREAT/GOOD/MISS totals;
- SPACE and Reverse totals;
- one event row for every authored note/SPACE event.

## Per-event data

Arrow-note judgements record:
- authored event index;
- target timestamp in milliseconds;
- note type (`normal` / `reverse`);
- expected input;
- displayed input;
- actual player input when applicable;
- judgement;
- actual input timestamp and signed timing error for real input judgements;
- automatic/manual miss reason;
- combo and score after the judgement.

SPACE judgements use the same timeline model with their own stable event index.

Automatic misses intentionally store `timing_error_ms: null` because no player keypress exists to measure against the target.

## Reliability / performance

Judgements are buffered in memory during active gameplay. Session JSON is written only after a run completes or is aborted, so file I/O is not added to the rhythm-critical input loop.

Session files and the index use the v17.4.13 atomic JSON persistence helper.

Completed runs reconcile any unresolved authored event as a synthetic MISS so a session has complete event coverage. Aborted runs do not fabricate future misses; they preserve only judgements that actually occurred before the abort.

## Abort tracking

Runs are preserved with `status: aborted` when interrupted by:
- Retry;
- Song Library return;
- Main Menu return;
- Chart Editor transition;
- application exit;
- a newer run superseding an unexpected stale active session.

## Explicitly deferred

v17.4.14 does not add:
- player name/profile UI;
- login/register;
- backend upload;
- telemetry export button;
- analytics dashboard;
- heatmap visualization;
- chart rebalancing.

Those remain later Beta objectives.

## Regression guarantees

- No chart JSON changed.
- No BPM or note timestamp changed.
- No judgement window changed.
- No scoring formula changed.
- No lane/note/hit-zone presentation changed.
- No background implementation changed.
- No Result Screen visual behavior changed.
