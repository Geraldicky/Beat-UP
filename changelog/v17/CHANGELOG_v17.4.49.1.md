# Beat UP! v17.4.49.1 — Variant Type Hotfix

## Fixed
- Fixed a GDScript compile error in `scripts/music_session.gd` when warnings are treated as errors.
- `Array.pop_front()` returns `Variant`, so the audio-cache eviction path is now explicitly converted to `String`.
- No chart, background, timing, song metadata, or gameplay behavior was changed.
- v17.4.49 resident Song Library / async media pipeline remains intact.

## Code change
```gdscript
# Before
var evict_path := audio_cache_order.pop_front()

# After
var evict_path: String = str(audio_cache_order.pop_front())
```
