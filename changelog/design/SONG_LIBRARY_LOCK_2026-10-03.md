# Song Library Redesign Lock — 2026-10-03

Branch: `ui/song-library-redesign`  
Application version remains `18.7.0.1`.

This milestone closes the current Song Library redesign pass. Main Menu and Song
Library can now be treated as locked player-facing screens until a regression,
accessibility issue, or explicitly approved redesign requires reopening them.

## Interaction and motion

- Applied the shared micro-motion system to Play, Practice, 4K, 8K, Random and
  other release-facing action buttons.
- Superseded hover/focus/press tweens are killed before a new micro-tween starts.
- Difficulty/selection motion now uses the shared FAST/NORMAL/SLOW timing tokens
  instead of independent magic durations.
- Existing spring-based song-row navigation remains the owner of carousel motion.

## Performance

- 4K/8K and Random changes no longer rebuild all resident Song Row scenes during
  the normal `All Progress` view.
- Those state changes now refresh row presentation and selected detail/record
  binding in place.
- A full filter/list rebuild remains intentional when an active progress filter
  depends on the current score identity.
- Existing thumbnail cache, SVG texture cache, preview preload and stale-generation
  guards remain in place.

## Cleanup

Removed dead Album Flow compatibility scaffolding from the production controller:

- hidden overflow/ellipsis filter button;
- detached hidden bottom difficulty/action dock;
- invisible detail veil;
- unused abstract Song Library ambient node;
- obsolete Album Flow filter helper callbacks;
- obsolete component-content compatibility entry points.

The canonical reusable component scenes remain the owner of static Song Library
UI structure.

## QA and release gate

- Added `song_library_release_static_test.py`.
- Added the canonical Song Library fidelity/runtime suite to `release_gate.py`.
- Added the osu-reference launch/invalidation contract test to the release gate.
- Runtime coverage includes 1280×720, 1600×900, 1920×1080 and 2560×1440.
- Regression coverage locks rapid selection → immediate Play, editor/disk
  invalidation → authoritative Play, 4K/8K, Random, search/filter/sort,
  Practice, Best Record, missing audio and canonical SVG usage.
- Historical stale Song Library tests were rewritten against the current Album
  Flow contract rather than left coupled to removed v17 UI nodes.

## Lock contract

Do not casually reintroduce:

- hardcoded per-song presentation identity;
- extra release-facing sort modes beyond BPM Asc/Desc;
- raw chart dictionaries as the Play authority;
- duplicated persistent audio owners;
- hidden compatibility UI solely to preserve obsolete tests;
- imperative reconstruction of the six reusable Song Library components.

Full release-gate execution still must be performed locally with Godot 4.7 and
the canonical `music/imported` library before claiming a shipping build PASS.
