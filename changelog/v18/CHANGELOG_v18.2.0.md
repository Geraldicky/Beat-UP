# Beat UP! v18.2.0 — Unified Visual Polish Pass

## Scope
This is a presentation-focused update. Charts, song backgrounds and audio are not modified.

### Global Design System
- Added shared spacing, radius and motion tokens to the minimal UI theme.
- Tightened default panel/button density, disabled states and secondary/tertiary hierarchy.
- Added reusable micro-interaction helpers for static player-facing controls.

### Song Library
- Rebalanced the selected-chart / song-browser columns to a responsive 42/58 composition.
- Restored a clear SELECTED state so Now Playing and chart selection are never the same visual concept.
- Rebuilt DETAILS around useful chart metadata instead of repeated BPM/notes.
- Kept RANKING local-only; mod filtering remains beside the Ranking tab and redundant LOCAL/SCORE chips are removed.
- Restored compact Practice + Replay secondary actions beside the primary PLAY action.
- Removed import/refresh/export/developer utilities from the player-facing Song Library. Chart Studio remains the authoring surface.

### Gameplay
- Reduced HUD bulk and background obstruction while preserving note readability.
- Improved numeric hierarchy, judgement scale, responsive HUD margins and compact song context.
- Preserved automatic BPM-based scroll speed and all existing chart/gameplay rules.

### Pause / Result
- Compact pause composition with contextual hover/focus action labels.
- Reduced pause dimming so the current song remains visually present.
- Result cards use a lighter hierarchy; empty special-note information is hidden automatically.

### Settings / Calibration / How To Play
- Removed redundant in-panel Settings section headings where tabs already provide context.
- Calibration is more compact and APPLY remains disabled until a valid sample result exists.
- How To Play spacing and copy/visual balance are tightened for 720p through 1440p.

### Chart Studio
- Unified panels with the global design language, compact margins and consistent control motion.
- Kept generation/import functionality unchanged.

### Transitions / Microinteractions
- Resident route motion is shorter-distance and smoother.
- Added subtle hover/focus/press scale feedback to appropriate static controls without affecting timing-critical gameplay.

### Responsive / Performance QA
- Updated responsive HUD defaults and layout ratios.
- Performance reports now include route, preview-start and frame-spike budgets.
- Added a static visual-polish gate for versioning, hierarchy markers, duplicate top-level declarations and manifest safety.

### Beta Cleanup
- Player-facing Song Library no longer exposes import, refresh or telemetry export controls.
- No build manifest JSON is introduced.
