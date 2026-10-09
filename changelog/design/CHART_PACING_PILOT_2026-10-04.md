# Chart pacing pilot — 2026-10-04

## Scope and Beat UP! source of truth

Nine charts only: Normal/Hard/Master for Immortal Flame (110 BPM), Bad Apple!!
(140 BPM), and FREEDOM DiVE (222.222222 BPM). This is a playtest pilot, not a
claim that the entire 39-song library is balanced. Master is slightly easier,
not harder. Version remains 18.7.0.1.

The read-only initial audit found 115/117 charts without an internal input-free
gap of at least three seconds. A SPACE input interrupts a rest just like an
arrow. Intro/outro silence is excluded from this metric.

Inspected owners:

- `charts/<song>/<difficulty>.json`: authored timestamps, separate SPACE inputs,
  section analysis, difficulty labels, generator provenance.
- `scripts/main.gd::_start_resolved_level` and gameplay update: directional
  scheduler and separate SPACE cursor; audio advances through empty intervals.
- `scripts/chart_timeline.gd::load_events/collect_upcoming`: deep-copy source,
  preempt spawn by captured visual travel time; no break manager is needed.
- `scripts/user_settings.gd`: maximum visual travel time is 2.6 seconds.
- `scripts/score_identity.gd`: authored input changes change chart identity;
  old records/replays are not reassigned to a newly simplified chart.
- `scripts/chart_integrity.gd`: structural validation remains unchanged.

No changes to gameplay code, scoring formulas, judgement windows, offsets,
audio duration, BPM, RANDOM, reverse mod, 4K projection, or note-speed behavior.
Retained directional notes preserve their original time, type and direction;
retained SPACE timestamps are unchanged. First/last directional inputs were
also checked against the original charts. Bundled audio was analyzed read-only.

## Recipe and measured result

`tools/chart_pacing_pilot.py::rebalance` is an offline, data-only recipe: it
returns a deep copy and never writes a file. Do not run it on an already revised
chart. `tools/chart_pacing_audit.py` can audit any chart or the entire library.

Rest candidates follow quieter sections in the existing analysis. Read-only
audio RMS measurements supported the contrast particularly for Immortal Flame
and FREEDOM DiVE; Bad Apple's compressed audio has much less RMS contrast.
These are candidates for human musical review, not verified silence in audio.

| Song | Explicit empty input intervals, seconds |
| --- | --- |
| Immortal Flame | 148.566–152.929; 253.293–257.657 |
| Bad Apple!! | 111.002–117.859; 220.716–227.573 |
| FREEDOM DiVE | 28.428–32.748; 84.588–88.908; 196.908–201.228 |

Actual gaps between retained inputs are slightly longer. Both input channels
are cleared. Every interval exceeds maximum note preempt plus a short clearance,
so there is a genuinely empty visible lane even at the slowest note speed;
incoming notes return before the next hit to provide reading time.

Outside rests, arrows less than 200 ms from SPACE are removed. Weak subdivisions
in overly tight sequences are thinned with a bounded extra removal budget:
Normal 12%, Hard 8%, Master 2% of original directional count. Full-beat anchors
are preserved by this thinning step. This is deletion only, not retiming or
regeneration. Difficulty labels and authored star ratings are unchanged pending
playtesting; existing catalog rating behavior still owns runtime presentation.

| Song | Normal notes | Hard notes | Master notes | Master reduction |
| --- | --- | --- | --- | --- |
| Immortal Flame | 392 → 372 | 575 → 517 | 712 → 681 | 4.4% |
| Bad Apple!! | 566 → 537 | 826 → 722 | 1015 → 968 | 4.6% |
| FREEDOM DiVE | 730 → 601 | 1016 → 872 | 1277 → 1184 | 7.3% |

One-second peak required inputs (arrows + SPACE), Normal/Hard/Master:
Immortal Flame 4/6/6 → 4/4/6; Bad Apple 6/8/9 → 5/6/8;
FREEDOM DiVE 7/8/9 → 6/7/8. Longest uninterrupted input section drops from
approximately 294/304/257 seconds to 142/108/108 seconds respectively.

Count-based recommendation/profile fields are refreshed. `pacing_meta` stores
before/after metrics and rest intervals. Historical generator diagnostics stay
as provenance, explicitly distinguished from current pacing metrics. No record
format migration or retrospective score conversion is performed.

## osu-reference lesson, not an architecture transplant

Studied the complete production
[BreakPeriod](https://github.com/ppy/osu/blob/b267e64503973cf8c1183e72c9b870240bb57883/osu.Game/Beatmaps/Timing/BreakPeriod.cs)
and behavioral
[CheckBreaksTest](https://github.com/ppy/osu/blob/b267e64503973cf8c1183e72c9b870240bb57883/osu.Game.Tests/Editing/Checks/CheckBreaksTest.cs).
The applicable principle is an input-free recovery interval with enough space
to clear preceding objects and preview the next phrase. Beat UP! implements it
as authored gaps, including SPACE, sized against its existing travel-time bound.
Do not copy osu's break constants, object model, health behavior, break overlays,
screen lifecycle, or scoring architecture. No runtime note suppression is added.

## Regression and manual review

`chart_pacing_pilot_test.py`: half-open peak windows, SPACE interrupting a rest,
recipe immutability/retained events, nine-chart metrics, valid section bounds,
both channels empty, slight Master nerf, non-increasing peaks, ordered counts.

`chart_pacing_timeline_test.gd`: production structural validator and scheduler,
empty interval at maximum preempt, correct resumption, no source mutation.
Both tests join the existing release gate without weakening its criteria.

Remaining debt: sustained sections still reach approximately 1.8–2.4 minutes;
do not arbitrarily erase a strong chorus just to achieve a fixed rest cadence.
Have beginners play Normal and experienced players play Master, at their chosen
note speed, especially re-entry after each break. Check that rests follow the
musical phrase and that the weakened subdivisions remain satisfying. Expand to
other songs only after this pilot is approved. No artificial score reward added.
