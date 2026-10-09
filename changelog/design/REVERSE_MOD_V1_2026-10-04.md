# Reverse mod first playable version

> Historical v1 contract. Optional-only Reverse supersedes authored-reverse
> preservation and OFF identity compatibility for authored-reverse charts.
> Current behavior: `NOTE_READABILITY_2026-10-04.md`.

Beat UP! source of truth: `main.gd::build_note_data` already displays the
opposite arrow for reverse while judging the original/remapped direction.
`register_hit` already awards authored reverse a bonus. The new mod reuses that
reading mechanic and renderer, but mod-added reverse does NOT receive that bonus.
Timing, combo multipliers, accuracy and authored reverse scoring stay unchanged.

Song Library offers OFF / 25 / 50 / 75 / 100 percent. This is a rounded fraction
of eligible `normal` events, not of all events (nor per-key input randomness).
Space and authored reverse are never rewritten. With fewer than four eligible
notes, rounding may produce the same layout at adjacent settings; their records
still remain separate. Selection is resident UI state, not a persisted setting.

Launch remains logical IDs -> AppShell -> force-refreshed LevelCatalog. The
resolved source retains its source hash/path/kind. Only the owned runtime deep
copy is transformed, after legacy direction authoring, before Practice slicing.
The pure `reverse_mod.gd` helper uses a separate seeded Fisher-Yates permutation
of normal event indices. Its seed depends on authored source hash and reverse_v1;
increasing percentages adds a nested subset. It never consumes RANDOM's RNG.
Projection remains based on authored directions. Reverse+Random Retry retains
the direction seed; OFF retains the old RANDOM Retry behavior.

ScoreIdentity adds reverse_percent/reverse_version only when nonzero; all OFF
keys and historical replays remain compatible. PBs, local runs, Practice and
replays use the same context. Replay identity validation includes the new fields;
recorded percentage drives replay launch. HUD and Results show REV percentage.
There is no multiplier in this version. No chart files or application version
were changed (18.7.0.1).

## osu-reference mapping

- Inspected: osu.Game/Rulesets/Mods/ModRandom.cs and
  osu.Game.Tests/Visual/Gameplay/TestSceneReplayPlayer.cs at
  b267e64503973cf8c1183e72c9b870240bb57883.
- Flow: a seeded mod participates in prepared gameplay; replay supplies its mods.
- Ownership: gameplay consumes committed run configuration, not live UI controls.
- Lifecycle: configuration is selected before player creation; replay restores it.
- Why: reproduce modified gameplay rather than replay a different layout.
- Principle: deterministic run transformation and explicit replay identity.
- osu-specific: IHasSeed, Bindables, DrawableRuleset and test player hierarchy.
- Beat UP! equivalent: prepared chart metadata, existing ReplayManager/ScoreIdentity.
- Adaptation: pure transformation helper and optional identity fields only.
- Do not copy: mod framework, DI, ruleset pipeline, osu! visual identity.
- Regressions: exact fractions, immutable source, OFF compatibility, PB separation,
  Retry/replay, 4K round-trip, authored bonus vs no mod bonus, responsive controls.

The guarded reverse suite runs in its own isolated user directory in release_gate.
Bundled chart/audio are read-only fixtures; all test records/settings/replays are
written only inside that isolated environment. No gate failure criteria weakened.
