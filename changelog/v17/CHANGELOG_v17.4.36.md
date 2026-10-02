# Beat UP! v17.4.36 — Gameplay Intro / READY Countdown Remake

## Countdown remake
- Rebuilt the gameplay READY / 3 / 2 / 1 presentation from scratch.
- Removed the previous nested filled-diamond countdown card.
- The countdown is now typography-first: large centered number, thin timing rails, four short diamond-language brackets, and three compact progress diamonds.
- Reduced the fullscreen dim so the selected song artwork/gameplay field remains visible behind the intro.
- READY is now a dedicated header instead of being replaced by the input-mode copy.
- Added a separate muted input-mode line (`8 KEY · NUMPAD` / `4 KEY · ARROW KEYS`).
- 3 / 2 / 1 retain the Beat UP! accent progression: cyan → gold → pink.
- Each step uses a faster, cleaner scale/opacity hit instead of the old heavy pop animation.

## Launch behavior
- Removed the literal `GO!` state. `1` is now the release cue and dissolves directly into active gameplay/music.
- Gameplay music still starts only when the countdown reaches zero.
- The countdown remains held while the shared artwork transition is still active, preserving the seamless Song Library → Gameplay handoff.
- Countdown cancellation/reset now restores all new label/animation state cleanly for retry and navigation.

## Scope
- No built-in chart data changed.
- No gameplay judgement windows, scoring, note timing, scroll-speed logic, or telemetry schema changed.
