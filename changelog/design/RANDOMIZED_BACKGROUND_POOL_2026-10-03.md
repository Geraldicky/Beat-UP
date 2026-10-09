# Randomized presentation background pool — 2026-10-03

Branch: `ui/song-library-redesign`  
Application version remains `18.7.0.1`.

The previous song-named 1600×900 backgrounds are now presentation assets rather
than per-song artwork. All 39 files were renamed to:

```text
assets/backgrounds/background_01.png
…
assets/backgrounds/background_39.png
```

Main Menu, Song Library ambience, gameplay and result presentation now consume
the shared randomized `BackgroundSession` pool. Song cover art remains confined
to the Song Library jacket/thumbnail surfaces under `assets/song_thumbnails/`.

This prevents low-resolution cover art from being stretched to fullscreen 16:9.
Main Menu music identity is also decoupled from its visual background:
Previous/Next still changes the track, while the background is chosen
independently from the ambient pool.

The legacy `background` field inside built-in chart JSON is tolerated as
historical metadata, but release-facing presentation no longer relies on
`assets/song_backgrounds/<song_id>.png`.
