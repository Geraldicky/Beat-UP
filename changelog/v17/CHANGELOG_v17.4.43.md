# Beat UP! v17.4.43 — 25-song FLAC chart batch

## New songs

Added 25 new songs to the built-in library, bringing the shipped catalog from 14 songs / 42 charts to 39 songs / 117 charts. Runtime playback uses the supplied OGG files; FLAC masters were used offline for chart analysis and are intentionally not bundled in the project archive.

Every new song ships with NORMAL, HARD, and MASTER charts. Generation used the existing lossless FLAC musicality pipeline plus the v17.4.5.4 burst-readability pass: onset evidence selects subdivisions, phrase energy controls density, Reverse remains difficulty-scaled, SPACE accents follow strong metric/onset locations, and short-window density guards remove weak overload notes before shipping.

## Timing / source handling

Verified or source-backed BPM values are used where available. Highscore (Nightcore) and Rockefeller Street (Nightcore) use phase-scanned source tempos from the supplied FLAC masters. Duplicity Shade, Cybernetic Maste.7, and Flamewall contain meaningful tempo variation; their charts still use absolute generated timestamps while the single BPM field remains a representative display/scroll tempo because the current Beat UP! chart schema exposes one BPM value per chart. Everything will freeze and Sound Chimera use the rhythm-game double-time pulse.

## Library integration

New gameplay audio is stored under `music/imported/` with stable song IDs so Song Library discovery works through the existing recursive chart scan. New songs intentionally ship without fabricated background artwork; Song Select falls back to its neutral visual treatment. `BackgroundSession` now clears the previous song background when the newly selected song has no background asset, preventing stale artwork from carrying over.

## Scope

No Bomb notes were added. No FLAC masters are bundled. No build/manifest JSON files were added. Existing 14 songs and their charts are unchanged.
