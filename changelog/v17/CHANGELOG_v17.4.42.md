# Beat UP! v17.4.42 — Live Song Library records

## Fixed

Personal bests now appear when returning from Results to the resident Song Library, without restarting the game. Completed plays also update the play count when the score is below the existing best. Updates remain available when returning through Main Menu.

## Cause and implementation

Gameplay and AppShell's Song Library have separate SongSelect instances and separate loaded record dictionaries. Previously commit_best_stats updated only Gameplay's internal LevelSelect, while the resident library returned with refresh_data=false and retained its startup snapshot.

Gameplay now emits best_stats_changed after committing results. AppShell connects this event to the resident Song Library. The library snapshots the data immediately and applies pending changes in shell_will_resume, before the screen reveal. A visible library applies the update immediately. The refresh uses existing catalog data and does not rescan chart/audio files. Mode/chart/rules identities and existing save files remain compatible with v17.4.41.

## Validation

- Reproduced stale records with an automated AppShell integration test on v17.4.41 (6 failed assertions).
- Godot 4.6 Linux headless editor import completed without script errors.
- Big Daddy HARD 8K automated result completion, Result Back, and visible best-score lookup: PASS.
- Second lower-score attempt, Main Menu detour, best preservation and updated play count: PASS.
- 4K/8K switching remains isolated: PASS.
- Existing score identity/migration/telemetry regression suite: PASS.

Tests use simulated completion values through actual game result/navigation code; this is not a manual Windows playtest. Engine shutdown still reports the ObjectDB/resource cleanup warnings observed in v17.4.41.

## Install

Extract the full project into a new folder and open project.godot. Keep existing Beat UP! user data: records saved in v17.4.41 remain usable. Source and assets are included; this is not a Windows executable.

This release focuses on the reported live-record refresh bug. The broader clock/judgement/scoring refactor proposed in the roadmap is deferred. Charts, chart generator, gameplay timing and score formulas are unchanged. No JSON build manifests are added.
