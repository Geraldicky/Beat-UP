# Song Library fidelity pass

Branch: `ui/song-library-redesign`. Baseline: `05f3980`.
Application version remains `18.7.0.1`.

## Presentation scope

- `scripts/song_select.gd`: existing dynamic three-column composition, toolbar,
  local matte outline states, density, typography, record hierarchy and semantic
  theme roles. No catalog, launch, scoring, timing or persistence changes.
- `scripts/ui/song_banner_button.gd`: only the compact Song Library row variant
  loses its layered bloom/heavy selection fill.
- `scripts/ui/library_vector_icon.gd` (and Godot UID): static vector shuffle,
  target, information, diamond, arrow and polygon rank rendering.
- `tests/song_library_rhythm_redesign_test.gd`: updated visual contracts and
  expanded behavioral/resolution checks.

At 1080p rows are 72 px with 58 px jackets; selection no longer changes row
height. Difficulty/mode/mod/Play heights are 76/60/78/104 px. Toolbar radius is
2 px, with explicit keyboard focus borders. The whole-screen artwork contribution
is 7%, the detail wash 2%. Most glow is removed rather than replaced with another
effect pipeline. Global theme tokens and other screens are unchanged.

Selected title is semibold and displayed uppercase without rewriting song data.
Very long titles use two lines with ellipsis and the existing full-title tooltip.
Score/accuracy are 32–36 px at 1080p (smaller at the compact breakpoint). SS is
scaled to fit the diamond. Stored `completed_at` is displayed only when present;
legacy entries do not get invented dates. MAX COMBO remains visible below the
judgements. PERFECT pink, GREAT green, GOOD cyan and MISS red retain Beat UP!'s
existing semantic palette through generic theme reapplication.

Practice still opens the section selector and reads SELECT, never a fictitious
ON state. Artist filtering remains ALL ARTISTS; no genre data is fabricated.

## QA

Godot 4.7.1; Python 3.14 for the focused release gate. All runtime launches use
separate temporary APPDATA and XDG_DATA_HOME directories.

- Song Library fidelity suite: PASS headless and rendered OpenGL compatibility.
  Behavioral checks include search, artist/difficulty filters, both BPM sorts,
  rapid selection/preview, previous/next, difficulty rebuild, 4K/8K, Random,
  keyboard focus, Practice popup, records/date/empty state, missing audio and
  recovery. Theme reapplication preserves semantic colors and vector markers.
- Actual viewport layout assertions and screenshots: 1280×720, 1600×900,
  1920×1080; nine-digit score, SS rank, selected-row visibility, toolbar ordering,
  record/artwork separation and available primary actions.
- Import/parser/warning validation: PASS, including the release gate's strict
  import stage. No new parser/runtime errors in the fidelity suite.
- Library layout foundation, Phase 4 UI foundation, gameplay binding snapshot,
  AppShell navigation lifecycle and standalone menu fallback: PASS.
- Authoritative launch-resolution assertions: PASS; existing shutdown scene
  resource errors also reproduce on the untouched baseline.
- Focused release gate: BLOCKED at `live_records_foundation_test.gd` with its
  existing two assertions (visible PB and selected historical run metrics).
  Both failures reproduced on the detached untouched baseline.
- Older `song_library_redesign_test.gd`, `song_library_polish_test.gd` and
  `song_library_compact_v1711_test.gd` remain incompatible with the pre-existing
  Album Flow hierarchy (missing legacy options/nodes); they error and time out
  on the baseline as well. They were not rewritten or weakened.
- Existing TextServer/CanvasItem/ObjectDB teardown diagnostics reproduce on the
  baseline fidelity test. They are not reported as a clean all-tests-green gate.

The fidelity test refuses fixture setup without
`BEAT_UP_QA_SONG_LIBRARY=isolated`. Use that marker **only together with fresh
temporary APPDATA/XDG_DATA_HOME**; it is not an alternative to data isolation.
Run `--script res://tests/song_library_rhythm_redesign_test.gd` headless for
assertions, or without `--headless` and with `-- capture` for screenshots.
Captures go to the isolated `user://`, not the repository.

## osu-reference research trace

Inspected reference at `ppy/osu@b267e64503973cf8c1183e72c9b870240bb57883`:

- [BeatmapCarousel](https://github.com/ppy/osu/blob/b267e64503973cf8c1183e72c9b870240bb57883/osu.Game/Screens/Select/BeatmapCarousel.cs)
- [TestSceneSongSelectCurrentSelectionInvalidated](https://github.com/ppy/osu/blob/b267e64503973cf8c1183e72c9b870240bb57883/osu.Game.Tests/Visual/SongSelect/TestSceneSongSelectCurrentSelectionInvalidated.cs)

Flow/ownership: the carousel requests selection; authoritative beatmap state is
not owned by individual drawn panels. Filtering and model invalidation rebuild
the visible representations. Lifecycle: panels are materialized/pooled, and
selection must still correspond to the surviving model after filtering/deletion
or ruleset changes. The tests assert both selected model and visible selection.
This solves stale visual selection after a view rebuild.

Reusable principle: test state agreement after rebuilding/restyling, not only a
static screenshot. Beat UP!'s equivalents are SongSelect's existing callbacks,
LevelCatalog, SongSelectionState and resident AppShell/MusicSession. Those
owners/lifecycles are unchanged; this pass scopes presentation roles and tests
to their existing controls. Do NOT copy osu!'s Bindables, Realm, pooling graph,
ScreenStack, rulesets or visual identity. No osu! code/assets were copied.

## Remaining visual limitations

The repository supplies mostly abstract background/thumbnail artwork, not the
illustrated album covers in the mockup. No external or invented covers were
added. Missing artwork uses the neutral surface rather than large procedural
geometry. Final artistic approval should use the rendered game at 1080p with
the user's own real song artwork and normal display scaling.
