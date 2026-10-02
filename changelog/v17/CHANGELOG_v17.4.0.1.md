# Beat UP! v17.4.0.1 — Main Scene Startup Hotfix

## Fixed
- Hardened the new 4-Arrow direction remapping code so its array values are explicitly converted to typed integers/dictionaries instead of relying on Variant inference.
- Reworked the v17.4 Reverse generator selection loop to use explicit types and a simpler deterministic candidate pass.
- Added a defensive initial screen state so the raw gameplay lane/HUD cannot leak through while the Main controller initializes.
- The intended flow after pressing **PLAY** on the Main Menu is restored to **Song Library** first; gameplay only becomes visible after selecting a song/chart.

## Preserved
- Reverse targets remain approximately 6% Normal / 12% Hard / 18% Master.
- Bomb remains fully removed.
- 8-Direction and 4-Arrow input styles remain available.
- All 75 chart JSON files are byte-identical to v17.4.
- All 25 song backgrounds and all audio files are unchanged.

## Packaging
- Version bumped to `17.4.0.1`.
- Changelog remains under `changelog/`.
- No `VALIDATION*.txt` files are included.
