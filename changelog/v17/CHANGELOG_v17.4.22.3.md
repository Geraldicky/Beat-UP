# Beat UP! v17.4.22.3 — Consistent Gameplay Launch Transition

- Fixed the osu!-inspired artwork launch transition appearing only on the first Song Library → Gameplay launch.
- Every later gameplay entry now uses the same song artwork continuity overlay, including:
  - selecting another song after returning from Results,
  - Retry from Results,
  - Retry from Pause,
  - any in-main Song Select → Gameplay launch.
- Gameplay launch no longer falls back to the generic/legacy loading transition after the first song.
- Preserved the selected song artwork, title, artist, difficulty, BPM, star rating, and Random status on every launch.
- Reused the same gameplay HUD/lane entrance motion after every launch.
- No chart, scoring, timing, telemetry schema, or gameplay balance changes.
- No manifest JSON files are created or included.
