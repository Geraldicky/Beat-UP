# Beat UP! UI/UX polish — 2026-10-06

Scope: existing `ui/song-library-redesign` worktree, version 18.7.0.1. This is a polish pass, not a gameplay rebalance or a navigation rewrite. Pre-existing uncommitted chart, asset, scene and retirement changes were preserved.

## 1. UX defects

- Main Menu transport now fits 1280×720 as well as 1600×900 and 1920×1080; minimum widths no longer force controls outside the rail.
- Settings Back/Reset are in a persistent footer outside the scrolling settings body.
- Empty library searches hide stale artwork, record and difficulty presentation, disable Play, and provide a working Clear Search & Filters recovery action.
- Note Speed has a modal scrim and returns keyboard focus to its trigger on dismissal. Its explanatory copy distinguishes travel time from chart difficulty.
- Quick Settings fits 720p and shows live percentage values alongside volume/background sliders.
- Resizing paused gameplay reprojects frozen note positions using the last visual-time snapshot, without advancing the clock or changing judgement targets.
- Long selected-song titles reserve their actual shaped line height. A regression checks that the second line is visible, not merely present in the text layout.

## 2. Visual consistency

Dark, restrained modal/dropdown surfaces use the existing style helpers rather than a new theme engine. Difficulty/mod captions have more legible sizes/contrast. Rank semantic colors are consolidated in the existing MinimalTheme and shared by Library and Results. Exit confirmation has a restrained destructive accent.

## 3. Typography and content

Transport text, important utility controls and gameplay metadata/time were enlarged. The gameplay time region reserves enough width at 720p; the existing containment assertion caught and prevented clipping. Search no longer promises unsupported tag search. Credits identify the actual bundled font families and menu music sources.

Typography skill application was scoped to native Godot size/hierarchy/measure checks; this is not a claim of a full web typography or accessibility conformance audit.

## 4. Screen refinement

Main Menu transport, Library empty/long-title states, Settings footer, Note Speed, Quick Settings, gameplay frozen layout, Results score comparison and Mods alignment, tutorial note/receptor colors, calibration instructions and Credits were refined. Results comparison/save-status copy sits directly below the score; save failures retain an explicit error color. Tutorial Reverse instructions describe the opt-in mod and opposite direction without changing gameplay.

## 5. Assets and motion

Existing vector controls, fonts and rank glyph assets were reused; no unrelated bitmap assets were regenerated. SS receives a wider optical allocation. Credits use the Beat UP! diamond rather than the unrelated orbit motif. The countdown numeral fades during its final 350 ms to expose the frozen approach notes; the three-second resume deadline is unchanged. Hidden Main Menu/tutorial/dropdown work uses tree visibility where relevant, avoiding resident-child visibility mistakes.

The osu-reference skill and relevant local references informed ownership/readability/responsiveness principles only. Upstream osu implementation comparison for this pass: **Unverified**; no osu source/assets or component architecture were imported. Beat UP! remains authoritative. Motion-design guidance influenced restrained reveal/fade and visibility behavior.

## 6. Verification and handoff

- New `tests/ui_polish_test.gd`: isolated headless and graphical runs PASS. Checks transport containment, sticky settings actions, empty-search recovery, long-title visible lines, rank palette, modal scrim/focus, live slider values and frozen-note relayout.
- Full release gate includes the new test without removing existing suites or weakening their assertions. Strict import/parser/warning validation is part of that gate.
- Final command: `python tests/release_gate.py --godot "C:\Users\USER\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe"`. Exit 0, final output `RELEASE GATE: PASS (see any printed shutdown warnings)`. Navigation lifecycle, authoritative launch resolution, input-binding snapshot, Records, loading, Library and Results suites all PASS. No import/parser warnings were introduced.
- Actual Godot OpenGL captures cover startup, transport, all Settings tabs, tutorial, Credits, calibration, exit, Library modes/empty state/Note Speed, loading, gameplay, pause/countdown and Results. Responsive captures include 1280×720, 1600×900 and 1920×1080. Results captures use deterministic fixtures, not a claim of a human-completed run.
- Capture directory: `C:/Users/USER/AppData/Local/Temp/beatup-ui-polish-2026-10-06`. `geometry.json` records control rectangles/text. `library_long_title.png` is the final title-wrap capture.
- Short local graphical frame probe, 180 frames per state at 1920×1080 / RTX 5060: Main Menu mean 5.00 ms, p95 5.05 ms; Library mean 4.99 ms, p95 5.05 ms; Blue Zenith Master/200 BPM mean 4.99 ms, p95 5.04 ms. These are a paced local frame sample, not a GPU benchmark, worst-case chart soak or minimum-hardware guarantee.

Remaining review: human playtest for readability during dense sequences, fatigue, countdown comfort, keyboard/mouse preference and actual audio latency. Extremely long metadata at compact sizes still needs representative content review. Existing shutdown ObjectDB/resource-retention diagnostics remain visible; they were not suppressed. This work does not establish a subjective “10/10”.

## Files changed in this pass

- `scripts/startup.gd`, `scenes/startup.tscn`
- `scripts/song_select.gd`, `scripts/track.gd`, `scripts/main.gd`
- `scripts/pause_menu.gd`, `scripts/calibration_screen.gd`, `scripts/result_screen.gd`
- `scripts/ui/note_speed_dialog.gd`, `scripts/ui/beat_dropdown.gd`
- `scripts/ui/minimal_theme.gd`, `scripts/ui/result_rank_meter.gd`, `scripts/ui/how_to_play_visual.gd`
- `scripts/ui/song_library/difficulty_card.gd`, `scripts/ui/song_library/mod_button.gd`
- `tests/ui_polish_test.gd`, its Godot UID, `tests/release_gate.py`
- this document

Gameplay timing/scoring/input/chart data, MusicSession behavior, authoritative Play resolution, navigation transaction ownership and application version were not changed by this pass.
