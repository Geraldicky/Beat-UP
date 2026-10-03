# Song Library — locked fidelity and behavior contract

Branch: `ui/song-library-redesign`  
Lock date: 2026-10-03  
Application version remains `18.7.0.1`.

## Locked presentation

The player-facing Song Library uses a three-part Album Flow composition:

- left: dense song browser with official jacket thumbnails;
- center: selected artwork and Best Record;
- right: song identity, NORMAL/HARD/MASTER, 4K/8K, Random, Practice and Play.

The top bar exposes Back, Song Library title, Search, Artist, Difficulty and only
two sort modes: `BPM Asc` and `BPM Desc`. Historical release-facing Title,
Star Rating, Best Rank and Unplayed First sort modes are intentionally removed.

Static UI identity uses the canonical 12 SVG assets in `assets/ui/icons/`.
Selection color is state-driven; dynamic song metadata, record values and rank
letters remain data-driven text. Rank and Play use dedicated diamond frames.

Reusable release components live under:

```text
scenes/ui/song_library/
├── song_row.tscn
├── difficulty_card.tscn
├── mode_button.tscn
├── mod_button.tscn
├── record_panel.tscn
└── play_button.tscn
```

`song_select.gd` owns orchestration/state binding rather than rebuilding those
static hierarchies imperatively.

Fullscreen ambience is deliberately decoupled from song cover art. The 39 legacy
1600×900 Beat UP! backgrounds now live in `assets/backgrounds/` as neutral
`background_01.png` … `background_39.png` assets. `BackgroundSession` chooses
from that pool, while `assets/song_thumbnails/` remains the source for song rows
and the selected artwork panel.

## Locked behavior

- Local browsing updates `selected_song_id` / `selected_difficulty`.
- `SongSelectionState` receives committed visible metadata.
- Play emits logical identity, not a trusted cached chart dictionary.
- AppShell/gameplay force-resolves the authoritative chart through
  `LevelCatalog.resolve_playable(..., true)` at the launch boundary.
- Runtime gameplay deep-copies the resolved chart. 4K projection, Random state
  and runtime caches do not mutate source chart data.
- 4K/8K and Random update record/detail identity without rebuilding the resident
  song-row tree unless an active progress filter actually depends on record state.
- Preview switching remains debounced/preloaded through SongPreviewController
  and MusicSession.
- Missing/invalid audio disables Play/Practice and displays the unavailable state.
- Practice remains an action (`SELECT`), not a fictitious ON/OFF modifier.

## Motion contract

Micro-interactions use the global `MOTION_FAST/NORMAL/SLOW` tokens. Button
hover/focus/press motion cancels the previous tween before starting another, so
rapid pointer/keyboard changes converge rather than stack. Song-row navigation
continues to use its existing spring-based margin motion; route-level transitions
remain owned by AppShell/SceneTransition.

## Responsive contract

The canonical runtime suite checks 1280×720, 1600×900, 1920×1080 and 2560×1440.
The selected song must remain visible, header controls must not overlap, Best
Record must not overlap artwork, and the center inspection column must not
overlap the right configuration column.

## osu-reference engineering contract

Reference snapshot: `ppy/osu@b267e64503973cf8c1183e72c9b870240bb57883`.

The copied principle is not osu!'s class graph or visual identity. Beat UP! keeps
fast provisional selection and performs authoritative revalidation at the action
boundary:

```text
SongSelect logical identity
→ SongLibrary
→ NavigationController
→ AppShell
→ Gameplay.prepare_launch_request(..., true)
→ LevelCatalog.resolve_playable(..., true)
→ validation + authoritative source
→ deep runtime snapshot
→ Gameplay
```

The regression suite explicitly covers rapid selection → immediate Play and stale
resident Library metadata → edited chart on disk → Play resolving the new chart.
Do not introduce osu! Realm/Bindable/ScreenStack/ruleset architecture merely to
look more similar to osu!.

## Release QA

Authoritative Song Library tests:

- `tests/song_library_release_static_test.py`
- `tests/song_library_rhythm_redesign_test.gd`
- `tests/song_library_osu_reference_contract_test.gd`
- `tests/authoritative_launch_resolution_test.gd`

These are included in `tests/release_gate.py`. The release gate also performs a
strict Godot import/parser/warning pass.

Run:

```powershell
python tests/release_gate.py --godot "C:\\path\\to\\Godot_v4.7-stable_win64.exe"
```

A full PASS is only claimable after that command is run against the canonical
project including `music/imported`. This document records the locked code/test
contract; it does not claim that this chat environment executed Godot itself.
