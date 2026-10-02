# Beat UP! — Album Flow Remake Master Specification

This document is the source of truth for the direct visual remake applied to the latest original Beat UP! project. The legacy project remains the functional authority; this remake replaces presentation without intentionally changing gameplay rules, scoring, timing, charts, persistence, records, replay or telemetry.

## 1. Product identity

The game remains **Beat UP!**. The remake uses the locked **Concept C — Album Flow** direction: calm, premium, atmospheric, music-first, artwork-driven, soft-editorial, minimal and lightweight.

## 2. Functional preservation contract

The following are frozen unless a future task explicitly changes them:

- 8-direction and 4-direction input behavior
- Space input behavior
- Reverse note behavior
- Random modifier behavior and deterministic seed handling
- PERFECT / GREAT / GOOD / MISS timing
- score, combo, accuracy and rank formulas
- BPM-derived note travel speed
- chart data and chart compatibility
- local records and ScoreIdentity behavior
- replay serialization
- playtest telemetry
- settings persistence
- navigation semantics
- audio continuity
- asynchronous loading and transition readiness

## 3. Gameplay identity

Gameplay remains landscape with one horizontal lane, one diamond hit zone on the left, and notes traveling from right to left. Diamond geometry is retained as the gameplay signature.

## 4. Diamond usage rule

Diamond geometry is reserved primarily for gameplay-linked identity: notes, hit zone, timing feedback and restrained contextual echoes. Generic menus must not turn every button or panel into a diamond.

## 5. Global palette

The remake uses the following visual tokens:

- Base background: `#0B0E14`
- Elevated background: `#131A24`
- Soft background: `#1B2430`
- Primary text: `#F4F6FB`
- Secondary text: `#C8D0DD`
- Muted text: `#8B96A8`
- Primary accent: `#A9B8FF`
- Light accent: `#D8E0FF`
- Warm accent: `#F2C8B0`
- Space: `#F5C96A`
- PERFECT: `#D3A4FF`
- GREAT: `#7DCE9E`
- GOOD: `#7DB4CE`
- MISS: `#B76C75`

## 6. Neutral-first color behavior

Most interface surfaces remain neutral. Accent is reserved for selection, primary interaction, progress and music context. Song artwork is expected to provide most of the emotional color outside gameplay.

## 7. Typography strategy

The remake reuses the deterministic fonts already shipped in the original project instead of introducing OS-dependent fonts:

- Poppins for functional UI/body text
- Space Grotesk for display/editorial headings
- IBM Plex Mono for scores, timing, BPM and other numeric/technical values

No new font files are required by this patch.

## 8. Spacing system

The shared spacing scale is `4 / 8 / 12 / 16 / 24 / 32 / 48 / 64 / 96`.

## 9. Radius system

Restrained radii are used for task surfaces and grouping. Gameplay diamonds remain sharp. The UI avoids making every element a rounded rectangle.

## 10. Surface hierarchy

- S0 — no visible surface
- S1 — interaction rail / subtle context surface
- S2 — genuine grouped content
- S3 — modal or focused task surface

Cards are not the default layout primitive.

## 11. Motion language

Motion is short and functional. The visual foundation uses approximately 120 ms micro motion, 180 ms selection motion and 240 ms screen motion, with Cubic/Quint/Expo easing. Bounce-heavy `TRANS_BACK` presentation was removed from major user-facing flows touched by this remake.

## 12. Main menu composition

The old center-emblem composition is replaced by an artwork-led editorial layout:

- fullscreen music artwork remains visible
- readability veil sits behind left-side navigation
- Beat UP! identity is top-left
- PLAY receives the strongest hierarchy
- navigation is text-first
- Now Playing becomes a slim bottom music rail
- old orb cluster and redundant technical labels are hidden
- one quiet diamond echo is allowed in the artwork field
- a lightweight music-reactive Flow Line replaces the old neon/equalizer spectacle

## 13. Main menu navigation

The existing destinations remain functional: PLAY, CHART STUDIO, HOW TO PLAY, CALIBRATION, SETTINGS, CREDITS and EXIT. No functional route was removed.

## 14. Main menu interaction

Hover/focus uses modest translation, opacity and accent-rail changes. The hidden legacy orb is no longer animated unnecessarily, reducing background UI work.

## 15. Song Library composition

The Song Library remains selection-first and artwork-driven. The current 42/58 information/browser split is retained, but containment is reduced:

- selected song title remains the hierarchy anchor
- details use a light S1 surface instead of a heavy card
- ranking area stays mostly surface-free
- tab selection uses a thin accent line
- PLAY remains the strongest action
- secondary actions are quieter
- artwork continues to transition asynchronously

## 16. Missing artwork fallback

When a Song Library background is unavailable, the visual layer now renders a designed fallback using:

- neutral Album Flow tonal bands
- one large subtle diamond
- a Flow Line
- initials derived from the song id

A broken-image placeholder is never shown.

## 17. Song Launch transition

The existing selected-artwork handoff is preserved. The remake changes the transition treatment, not the loading contract:

- no normal loading percentage
- no mandatory spinner
- no mandatory realtime blur
- selected artwork remains meaningful context while gameplay prepares
- reveal motion uses restrained Quint/Cubic timing instead of overshoot-heavy presentation

## 18. Gameplay HUD

During active play, the persistent HUD is reduced to the timing-critical information:

- score
- combo
- accuracy
- song progress
- judgement

Song title, BPM, difficulty and duration labels are hidden after Song Launch establishes song identity.

## 19. Gameplay background

Song artwork remains background context, but the lane and notes maintain priority. The design avoids high-detail movement directly behind the timing lane.

## 20. Normal notes

Normal notes keep a sharp diamond silhouette with a clear directional internal mark. Their presentation is high-contrast but not neon-heavy.

## 21. Reverse notes

Reverse remains functionally unchanged. Visually, Reverse uses the exact same silhouette and internal directional mark as a Normal note. Its only obvious note-type distinction is the restrained red outer outline; do not add a secondary inner diamond or a different silhouette.

## 22. Space notes

Space keeps the same diamond outer silhouette but uses a warm gold inner diamond/core and no directional arrow, making it structurally distinct from normal directional notes.

## 23. Hit zone

The hit zone remains a fixed diamond landmark on the left, using an outer diamond, inner diamond and restrained halo language. Gameplay logic and hit coordinates are unchanged.

## 24. Judgement colors

PERFECT, GREAT, GOOD and MISS now use explicit semantic colors from `ThemeConfig`. The same semantics are propagated through gameplay feedback, Result and supporting visuals.

## 25. Gameplay lane

The lane palette is shifted from high-saturation legacy neon toward dark neutral/periwinkle Album Flow tones while retaining its existing geometry and timing behavior.

## 26. Pause screen

The pause overlay keeps gameplay visible underneath but removes the old sci-fi hexagonal action frames. Actions now use quiet icon-only regions, restrained scaling and no `TRANS_BACK` bounce. The Song List action uses the correct list icon instead of an exit-door glyph.

## 27. Pause settings

Quick Settings remains functional. Its task surface uses S3 containment while the main pause actions use a lighter S1 surface.

## 28. Result screen

The Result screen preserves the completed song’s artwork rather than replacing it with a technical grid. A left readability veil supports metrics while the right side keeps album context. Metric card density is reduced and hierarchy becomes primarily typographic.

## 29. Result hierarchy

Rank and key result values are allowed to breathe without equal-sized cards. Score receives a light S1 surface; accuracy, combo and perfect-rate remain mostly S0. Retry remains the primary action and return is tertiary.

## 30. Calibration

Calibration keeps its measurement logic and controls. Its presentation is moved to the Album Flow palette and restrained motion language. Timing semantics remain readable without returning to the old pink/cyan neon treatment.

## 31. How To Play

The existing tutorial functionality remains intact while its default scene colors are moved into the new palette. Direction, Reverse, Space and timing concepts remain visually distinct.

## 32. Settings

Settings remains embedded in the startup flow and keeps existing persistence behavior. It now uses the common Album Flow theme, S3 task containment and neutral-first control styling.

## 33. Credits

Credits uses a quieter grouped S2 information surface with a restrained artwork/visual field rather than a collection of bright bordered cards.

## 34. Chart Studio

Chart Studio remains fully functional in the original latest project. This patch does not delete editor, waveform, save, undo/redo, audio import, playtest or generation functionality. Its visual hierarchy is flattened into S0/S1 surfaces and its cyan/pink/gold legacy palette is mapped into the new semantic palette.

## 35. Chart Studio waveform/timeline

Waveform and timeline retain the existing implementation. Their containers use lower-contrast borders and dark neutral backgrounds so the actual waveform, timing grid and notes receive visual priority.

## 36. Generic UI icons

Generic pause/utility icons no longer need geometric sci-fi frames. Diamond emphasis is reserved for gameplay identity.

## 37. Loading policy

Normal navigation should not show an unnecessary black loader, spinner or progress indicator. Existing threaded loading and readiness polling are preserved.

## 38. Audio continuity

Menu/song preview continuity remains owned by the existing MusicSession/background/session architecture. The remake must not create competing audio owners.

## 39. Mouse-first interaction

Menu navigation remains mouse-first, with visible focus behavior preserved for keyboard-accessible controls, dialogs, settings and remapping.

## 40. Responsive target

The canonical composition remains 1920×1080, while existing responsive layout code continues to support 1280×720, 1366×768 and 2560×1440-class layouts.

## 41. Performance rule

The remake introduces no mandatory fullscreen blur, giant animated textures, particle field or heavy shader stack. Custom visuals rely mainly on Control drawing and inexpensive tweens.

## 42. Runtime blur policy

Song Launch no longer requires realtime blur as part of the baseline transition. Artwork + scrim + motion provide continuity without making blur a performance requirement.

## 43. Legacy theme compatibility

`scripts/ui/minimal_theme.gd` keeps the old public API/class name so existing screens can inherit the remake without forcing a large functional refactor.

## 44. Legacy visual aliases

Compatibility aliases (`PINK`, `CYAN`, `GOLD`) remain available to old scripts, but their values now map to the Album Flow semantic palette. New generic UI code should prefer `ACCENT`, `ACCENT_LIGHT`, `TEXT`, `MUTED`, `DANGER` and `SUCCESS`.

## 45. Save compatibility

No save identity, record schema or settings key was intentionally changed by this visual patch.

## 46. Replay and telemetry compatibility

Replay and playtest telemetry scripts are not modified by this remake. Existing deterministic replay and analytics pipelines remain the authority.

## 47. Chart compatibility

No shipped chart JSON is modified by the visual remake.

## 48. Generator compatibility

Chart Studio remains player-facing for manual chart creation, waveform/timeline editing, BPM editing, save/export, and playtest workflows. Automatic chart generation remains in the codebase as a developer-only tool and is hidden/guarded in normal player builds through `beat_up/creator_tools_enabled=false`.

## 49. Validation performed in this environment

The following current static checks passed after the remake changes:

- `tests/v1870_generator_reliability_static_test.py`
- `tests/v1870_player_creator_static_test.py`
- `tests/v1860_waveform_studio_static_test.py`
- `tests/v18502_warning_cleanup_static_test.py`
- `tests/v1850_release_static_test.py`
- `tests/library_async_pipeline_v17449_test.py`
- `tests/music_session_variant_type_v174491_test.py`
- production `res://` resource-path static scan

A Godot executable is not available in the current sandbox, so the patch cannot be runtime-launched here. Open/run the overlaid project in Godot 4.7.x for final visual/runtime verification.

## 50. Changed presentation scope

The patch touches the major presentation path across Home, Song Library, Song Launch, Gameplay, Pause, Result, Calibration, How To Play, Settings defaults, Chart Studio, core theme resources and supporting visual primitives. Gameplay/domain systems are intentionally left intact wherever possible.
