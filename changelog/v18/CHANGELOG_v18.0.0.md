# Beat UP! v18.0.0 — Major Beta Systems Pass

## Stability
- Preserves the atomic primary/backup save flow and v17 save compatibility.
- Settings schema upgraded to v3 without discarding older values.
- New v18 stores (Practice, Replay, Performance) use atomic JSON persistence.

## UI / UX
- Global keyboard focus pass for ordinary controls and automatic button tooltips.
- Song Library Ranking supports Score / Date ordering.
- Details can display recent accuracy history and weak-section telemetry.
- Existing resident-screen/async Song Library architecture is retained.

## Gameplay / Controls
- Rebindable 8K, 4K and SPACE gameplay controls.
- Effect Intensity setting scales visual feedback only.
- Reverse note outline readability increased without changing the mechanic.
- Pause/resume timing path remains the existing calibrated implementation.

## Practice
- PRACTICE action exposes authored musical sections.
- Selected section loops with a short lead-in.
- Practice results are stored separately and never alter normal records.

## Replay
- Normal runs record semantic inputs plus chart/rules identity and Random seed.
- REPLAY plays the latest compatible run deterministically.
- Replay playback never commits a personal best or normal telemetry run.

## Progress / Diagnostics
- Recent accuracy graph.
- Weak-section summary from completed playtest telemetry.
- Startup/route/preview/frame-spike/memory performance instrumentation.
- Playtest export includes v18 diagnostic files when present.

## Beta distribution
- Added Windows beta build helper and beta testing guide.

## Content integrity
- v18 does not intentionally modify chart JSON, OGG audio, or song background assets from v17.5.0.
