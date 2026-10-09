# Song Library identity and action-state polish

Beat UP! source of truth: Album Flow in `scripts/song_select.gd` owns the
release-facing three-column layout. This change leaves catalog/launch authority,
selection, preview and Practice section selection in their existing owners.

Selected title and artist share a fixed-height identity group. Short titles keep the display
size; longer ones fit down to a readable minimum before two-line ellipsis.
The tooltip retains the complete source title. Slot height does not depend on
title length, so metadata/configuration do not shift between selections. Artist
follows the actual title with a 6px gap, at a calmer 22px desktop / 18px compact size.

The list header groups TITLE / ARTIST because row artists are stacked beneath
titles, not stored in a separate visible column. Number/jacket/header spacing
and right-aligned BPM are scoped to Album Flow. Artist filtering is unchanged.

Practice is an available action, never an enabled gameplay modifier. It uses a
neutral normal surface and no selected marker. SELECT, UNAVAILABLE, disabled,
hover and keyboard-focus states remain supported. It still opens the same
section selector and submits the same logical launch request. It is placed above
Play as a compact secondary action, outside the Mods row. Mode is shown only in
the mode selector, not repeated in the BPM/duration metadata.

Empty records show one message and one short instruction. Accuracy/score/rank,
breakdown and combo are shown only when a corresponding record exists; no
persisted data or score identity changes. Row hover uses a faint neutral wash
and edge, distinct from selection's cyan rail. The Play SVG is rasterized at
96px rather than 24px for a crisp double diamond, with a thinner stroke.

Follow-up: BPM/duration now sits inside the identity group, directly below the
artist. Space for a two-line title remains below the complete group so the
configuration stays stable. Random is 56px desktop / 44px compact (its component
may enforce a larger intrinsic minimum for readable content). The existing list
separator is visible as the viewport boundary; partial rows while scrolling
remain normal, with no scroll snapping or input changes. BPM distance treatment
now retains 64–76% opacity; record timestamp and combo retain 72%. The rank SVG
uses a 128px source and a thin technical stroke, not an enlarged 24px raster.

## osu-reference mapping

- Relevant inspected files: `osu.Game/Screens/Select/SongSelect.cs` and
  `osu.Game.Tests/Visual/SongSelect/TestSceneSongSelectCurrentSelectionInvalidated.cs`
  at pin `b267e64503973cf8c1183e72c9b870240bb57883`.
- Flow: local visible selection precedes action-time authoritative selection.
- Ownership: SongSelect presents selection; committed beatmap/launch has its owner.
- Lifecycle: queued selection can be superseded; an action commits intended identity.
- Why: keep browsing responsive without launching stale data.
- Principle: presentation state is not authoritative launch state.
- osu-specific: carousel, WorkingBeatmap, Bindables and manager/DI topology.
- Beat UP! equivalent: SongSelect IDs → NavigationController/AppShell → LevelCatalog.
- Adaptation: change only title/header/action styling; no launch-flow changes.
- Do not copy: osu! layout, database, debounce or component hierarchy.
- Regressions: stable bounded title slot at desktop resolutions, Practice selector,
  unavailable actions, filters/selection, and authoritative launch contracts.

Existing Song Library regression now checks actual hierarchy and title-size
adaptation instead of requiring all titles to share a minimum 38px display size.
Application version remains 18.7.0.1. Gameplay polish in the existing worktree
belongs to the preceding task and is not redesigned here.
