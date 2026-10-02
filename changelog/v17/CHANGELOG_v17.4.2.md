# Beat UP! v17.4.2 — 14-Song FLAC Library Reset

## Summary
Temporarily resets the Song Library to the 14 FLAC masters supplied for the next chart-quality pass.

## Library
The active library is now limited to these 14 songs:
1. Aresene's Bazaar — James Landino
2. Bad Apple!! — Alstroemeria Records feat. nomico
3. Moonlight Sonata 3rd Movement (meganeko Remix) — meganeko
4. Blue Zenith — xi
5. Exit This Earth's Atomosphere — Camellia
6. Beethoven Virus (Full Version) — Diana Boncheva feat. BanYa
7. Septette for the Dead Princess — ZUN
8. FREEDOM DiVE↓ — xi
9. Aleph-0 — LeaF
10. Night of Nights — COOL&CREATE / beatMARIO
11. Big Daddy — USAO
12. Necrofantasia — ZUN
13. U.N. Owen Was Her? & Flowering Night (Koa Remix) — Koa / ZUN
14. Oshama Scramble! — t+pazolite

Total active standard charts: 42 (14 songs × Normal/Hard/Master).

## Audio
- Replaced `music/imported/` with fresh Ogg Vorbis gameplay files converted from the supplied lossless FLAC masters.
- Cleaned filenames to project-safe snake_case names.
- FLAC masters are used as analysis sources but are not bundled into the game ZIP to avoid adding ~500 MB of duplicate lossless audio.
- Added `tools/flac_library_14_manifest.json` as the clean source/title/artist/BPM manifest.

## Charts
- Preserved event timing and SPACE timing byte-for-data-equivalent for 11 songs whose new FLAC masters match the previous audio sources.
- Regenerated all three difficulties for `Septette for the Dead Princess` because the supplied master is the full 4:29 source instead of the previous short source.
- Regenerated all three difficulties for `U.N. Owen Was Her? & Flowering Night (Koa Remix)` because the supplied master has a different/full duration.
- Added new Normal/Hard/Master charts for `Big Daddy`.
- New charts use lossless-FLAC onset scoring on a verified BPM grid.
- Reverse remains the only special directional note at approximately 6% / 12% / 18% for Normal / Hard / Master.
- Bomb remains fully removed.

## Assets / Metadata
- Added a dedicated `Big Daddy` song background and accent color.
- Removed unused song backgrounds and imported music from the temporary 25-song library.
- Corrected the Koa remix title/artist metadata.
- Corrected Aresene's Bazaar display punctuation.

## Unchanged systems
- 8 KEY / 4 KEY MODS panel behavior remains unchanged.
- Random MOD remains unchanged.
- Song Library sorting/filter UI remains unchanged.
- Gameplay judgement and scoring logic remain unchanged.

## Packaging
- Version bumped to 17.4.2.
- Changelogs remain under `changelog/`.
- No `VALIDATION*.txt` files are included.
