# Beat UP! v17.4.14 — Beta Telemetry QA

## Goal

Verify that playtest telemetry captures a complete and analyzable local timeline without affecting rhythm timing.

## 1. Completed run

1. Launch a normal chart.
2. Intentionally create at least one PERFECT, GREAT, GOOD, and MISS.
3. Hit and miss at least one SPACE cue if available.
4. Finish the song.
5. Inspect `user://playtest_data/session_index.json`.
6. Open the newest file under `user://playtest_data/sessions/`.

Pass criteria:
- status is `completed`;
- song/difficulty/input style are correct;
- result totals match the Result Screen;
- event timestamps follow the song timeline;
- every authored note/SPACE event has exactly one judgement entry;
- `integrity.complete_event_coverage` is true.

## 2. Timing error sign

Intentionally press one note early and one late while still inside the hit window.

Pass criteria:
- early input has negative `timing_error_ms`;
- late input has positive `timing_error_ms`;
- automatic MISS has `timing_error_ms: null`.

## 3. Reverse note

Hit one Reverse note correctly.

Pass criteria:
- `note_type` is `reverse`;
- `displayed_input` is the visible direction;
- `expected_input` is the opposite/correct gameplay input;
- `player_input` matches `expected_input`.

## 4. Wrong input

Press the wrong direction while a note is inside the judgement window.

Pass criteria:
- judgement is MISS;
- `automatic` is false;
- `reason` is `WRONG INPUT`;
- `player_input` contains the wrong key used.

## 5. Retry abort

1. Start a song.
2. Hit several notes.
3. Pause and choose Retry.

Pass criteria:
- first session is saved as `aborted` with `abort_reason: retry`;
- it contains only events judged before Retry;
- the restarted attempt gets a different session id.

## 6. Song Library abort

Return to Song Library mid-song.

Pass criteria:
- session is saved as `aborted`;
- no unplayed future notes are fabricated as MISS.

## 7. Pause count

Pause/resume multiple times and finish.

Pass criteria:
- `pause_count` matches the number of pause openings.

## 8. No gameplay regression

Confirm:
- no parser/runtime error;
- perceived timing is unchanged;
- no hitch occurs on ordinary note judgements;
- chart, lane, note colours, hit zone, background, and Result Screen remain identical to v17.4.13.

## 9. Data location

No network connection should be required. All v17.4.14 telemetry must remain under `user://playtest_data/`.
