# Beat UP! v17.4.41 — Score and playtest identity

- Personal best records now separate 4-key / 8-key and authored / Random modes.
- Chart gameplay content receives a SHA-256 identity at catalog load; changes to events, SPACE events, BPM, duration, audio reference or authored timing offset start a separate record scope. Cosmetic title/background changes do not reset records.
- Scoring identity includes an explicit rules version and fingerprint of timing windows, scoring values, combo multipliers, accuracy weights and rank thresholds. Future changes to gameplay algorithms must increment RULES_VERSION in scripts/score_identity.gd.
- Source chart identity survives runtime legacy direction preparation and temporary event indices.
- Existing records are retained under their original keys and marked legacy with unknown mode/revision. Their values are not recalculated or assigned to 4K/8K. Song Library shows LEGACY RECORD KEPT when applicable; current-mode records begin independently.
- Library personal bests, progression labels, filters and recommendations read the current mode/mod/chart/rules scope.
- Telemetry schema is now 3, with score_identity; telemetry, profile and result snapshots read the application version from project.godot.
- Windows preset adds the runnable flag for editor compatibility.
- Chart files, generator, timing windows and score formulas are unchanged.

## Use

Extract this complete project into a new folder and import project.godot in Godot. Keep the existing Beat UP! user data; do not delete saves. Legacy migration is automatic. This package contains source and assets, not a Windows executable.

## Validation

Godot 4.6 stable Linux headless: editor import and score_identity_v17441_test.gd executed. The regression test exercises actual gameplay commits, save/reload, library mode switching, Random isolation, chart/config changes and telemetry metadata. App Shell startup smoke tested. Headless shutdown reports ObjectDB/resource cleanup warnings; interactive Windows/audio-latency playtesting remains required. Project's existing Godot 4.7 feature declaration is preserved.

No JSON build manifests are generated. JSON chart/save/telemetry formats remain necessary game data.
