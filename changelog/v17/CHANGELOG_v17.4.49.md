# Beat UP! v17.4.49 — Resident Library Async Pipeline

## Goal
Remove the visible hitch when navigating Main Menu → Song Library and keep song-card browsing responsive while artwork/audio assets are prepared.

## Changes
- Song Library lifecycle work is deferred until the AppShell route tween has completed; pre-transition work is now constant-time.
- `set_selected_song()` no longer runs the filter/rebuild pipeline when the requested song already exists in the current browser result.
- Best-stat updates no longer rebuild 39 song groups / 117 difficulty rows unless the active progress filter or sort actually depends on those records.
- Removed the per-song staggered entrance tween from resident-screen visibility changes. AppShell owns the route motion.
- Full-size song backgrounds use Godot threaded resource loading instead of synchronous `load()` from the selection path.
- Song preview OGGs are prefetched through `MusicSession` on a loader thread and committed only when ready.
- Added a small LRU-style audio stream cache for recent preview tracks.
- Song Library now forwards resume/suspend lifecycle events to its SongSelect child, so preview start occurs after route reveal and pending preview work is cancelled on exit.

## Unchanged
- All 117 chart JSON files and their choreography/timing are unchanged from v17.4.48.
- v17.4.46 background set is unchanged.
- v17.4.47 preview-section selection logic is unchanged.
- The 25-song v17.4.48 Audio Pack remains byte-for-byte reusable.
