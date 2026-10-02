# Beat UP! — Album Flow High-Fidelity Mockup Report

## Deliverables

All review frames are 1920×1080, 16:9, and supplied as editable SVG plus PNG.

1. `01_main_menu` — Album Flow — Main Menu
2. `02_song_library` — Album Flow — Song Library
3. `03_song_launch` — Album Flow — Song Launch
4. `04_gameplay` — Album Flow — Gameplay
5. `05_pause` — Album Flow — Pause
6. `06_result` — Album Flow — Result
7. `07_settings` — Album Flow — Settings
8. `08_calibration` — Album Flow — Calibration
9. `09_how_to_play` — Album Flow — How To Play
10. `10_credits` — Album Flow — Credits
11. `11_chart_studio` — Album Flow — Chart Studio

The set also includes three design-system boards—`00_design_system`, `00b_component_states`, and `00c_gameplay_creator_components`—plus `contact-sheet.png`. Responsive review renders for Song Library and Settings are included at 1600×900 and 1366×768.

## Revision pass

The eight review priorities have been applied:

1. Song Launch hierarchy and difficulty/readiness layout were rebuilt to remove collisions.
2. Gameplay notes now carry unambiguous directional arrow glyphs; Reverse keeps the Normal silhouette and adds only a red outline.
3. The gameplay hit zone is a high-contrast white diamond with a visible halo on the left side of the single horizontal lane.
4. Pause preserves a clearly recognizable frozen gameplay state behind the modal.
5. Chart Studio now exposes all eight directions and numpad mapping for manual player-facing chart authoring.
6. Song Library rows use real project thumbnails; Immortal Flame uses its real bundled background because no matching thumbnail exists.
7. Component/state documentation is completed across the three design-system boards.
8. Metadata typography uses a scale-aware 14 px reference size, resolving to approximately 10 px at 1366×768 while retaining hierarchy and legibility.

## Design tokens

### Color

- Background base `#0B0E14`
- Surface `#131A24`
- Raised surface `#1B2430`
- Default border `#344052`
- Primary text `#F4F6FB`
- Muted text `#8B96A8`
- Primary accent `#A9B8FF`
- Accent light `#D8E0FF`
- Warm neutral `#F2C8B0`
- Perfect / lilac `#D3A4FF`
- Good / cyan `#7DB4CE`
- Danger `#B76C75`
- Great / success `#7DCE9E`
- Normal note `#5697FF`
- Diagonal note `#FFA65C`
- Reverse outline `#FF5A64`
- Space note `#F5C96A`

### Typography

- Display: Space Grotesk, 34–64 px; rank display 144 px and above
- UI and body: Poppins, 13–20 px
- Metadata and metrics: IBM Plex Mono, 11–40 px
- All typefaces are bundled project assets and embedded in the SVG deliverables.

### Spacing, radii, effects

- Spacing scale: 4, 8, 12, 16, 24, 32, 48, 64, 96
- Radii: 8 small, 12 panel, 16 artwork, 18 large
- Focus: 2 px periwinkle halo with 4 px offset
- Artwork: 16 px radius, subtle border, restrained drop shadow; never used as a giant Song Library background

## Reusable components

- Button: Primary / Secondary / Danger; Default / Hover / Pressed / Focus / Disabled
- Text navigation: Default / Hover / Pressed / Focus / Selected / Disabled
- Compact Song Row: Default / Hover / Selected / Focus
- Difficulty selector: Normal / Hard / Master with selected state
- Modifier selector: inactive / active, with name and current value
- Metric: label + mono numeric value
- Artwork treatment: square image, 16 px radius, border and shadow
- Progress bar: track + semantic fill
- Control mode selector: 8-key and 4-key
- Key binding tile, slider, toggle-style row, and dropdown-style row
- Diamond notes: Normal, Diagonal, Reverse outline, Space
- Judgement label: Perfect, Great, Good, Miss
- Waveform, beat grid, timeline note, and playhead

## Responsive behavior

- The 16:9 composition uses a 1920×1080 reference grid and scales cleanly to 1600×900 and 1366×768.
- Structural zones stay proportional; the three-zone Song Library remains left list / center artwork / right details.
- At implementation time, use scale-aware typography with a 10 px metadata floor at 1366×768 and preserve 44 px minimum action height.
- Responsive review images verify the two densest screens at both requested target sizes.

## Assumptions

- Space Invaders is the featured/selected song because the project contains complete chart metadata and usable artwork for it: Teminite & MDK, 128 BPM, 5:48, Master 10★.
- Result values are representative mock data because no canonical saved result snapshot was provided.
- Credits use explicit “approval pending” placeholders rather than inventing contributor names.
- The Main Menu “featured track” choice is editorial and can be changed without altering the layout.
- Figma foundations and the first three core component families remain in the existing Figma file; the complete review set is delivered locally because the live Figma write connector became unavailable during continuation.

## Conflicts resolved in favor of the canonical documentation

- Older Main Menu material used fullscreen artwork; the new frame uses large square artwork with a separate featured-track panel.
- Older Song Library/runtime material used banner-era/full-art treatments; the new frame uses compact rows, square center artwork, and a right details zone.
- Existing Chart Studio scene copy exposes generation-oriented controls; the player-facing frame contains manual authoring only and no automatic generation controls.
- Older changelog/runtime references include Bomb; Bomb is absent from every frame and component.
- Older gameplay colors used paler notes; the mockups use the stronger canonical semantic colors.
- Existing Settings/Result layouts are denser; the new frames use calmer hierarchy and stronger negative space.

## Owner approval before implementation

- Confirm the featured Main Menu track.
- Confirm final contributor names and credit ordering.
- Confirm music licensing/attribution copy for the Credits screen.
- Confirm whether result rank thresholds and representative score values should be replaced with a specific captured run.
- Review and approve the mockup set before any Godot implementation begins.

## Figma work-in-progress

- Existing file: https://www.figma.com/design/gwMeSCeiQzFQDZy0U1tdcy
- Completed there before connector loss: token collections, typography/effects, foundations documentation, Button, Navigation Item, and Song Row component families.
