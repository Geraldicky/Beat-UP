# Beat UP! v18.4.0.3 — Exported Audio Detection Hotfix

- Fixed exported Windows builds incorrectly showing `AUDIO MISSING` for bundled OGG tracks.
- Replaced gameplay gating based on `FileAccess.file_exists(res://...)` with export-aware `ResourceLoader.exists(...)` checks.
- Added `RuntimeResourceAccess` helper so packaged `res://` assets and filesystem/user assets are checked correctly.
- Song preview behavior is unchanged; gameplay now uses the same export-compatible resource semantics.
- No chart, audio, artwork, scoring, or gameplay-authoring data changed.
