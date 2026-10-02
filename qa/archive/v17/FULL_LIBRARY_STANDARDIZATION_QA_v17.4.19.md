# v17.4.19 Full Library Standardization QA

Static QA scope for the Beta chart-library pass.

## Verified
- 42 chart JSON files load successfully: 14 songs x 3 difficulties.
- 39 non-Big-Daddy charts carry v17.4.19 standardization metadata.
- Big Daddy NORMAL/HARD/MASTER SHA-256 hashes are byte-identical to v17.4.18.
- For every song, note-count progression remains NORMAL < HARD < MASTER.
- For every song, star progression remains NORMAL < HARD < MASTER.
- Retained non-Big-Daddy events keep their original timestamp + direction pair.
- Every original SPACE event is preserved.
- Reverse counts are difficulty-scaled to ~6% / ~12% / ~17% for standardized charts.
- Event arrays remain strictly time-sorted and directions remain valid 8-direction numpad values.
- Application/project telemetry version is 17.4.19.
- Big Daddy benchmark is not regenerated.

## Standardization behavior
The pass prefers retaining primary/half-beat accents, SPACE-paired accents, and high-energy chorus/climax notes. Lower-priority subdivisions are removed first when a local readability budget is exceeded. MASTER remains intentionally more permissive than HARD and NORMAL.

## Runtime validation required
Godot is not installed in the build environment. Runtime playtesting/export validation must be performed locally. Recommended first validation set: one low/medium BPM song, one high BPM song, and one very high BPM song on all three difficulties before freezing the Beta 1 chart library.
