# v17.4.40 Song Library Finalization QA

Runtime focus for Godot testing:

1. Hold/tap Up and Down rapidly across many songs. Visual selection should move immediately; audio/background should settle on the final card rather than rapidly restarting every intermediate track.
2. Use Page Up/Page Down, Home/End, then Enter. Gameplay must launch the card currently visible as selected.
3. Select a song, change NORMAL/HARD/MASTER repeatedly. The same audio track must continue without seeking/restarting.
4. Type quickly in Search. The list should update after the short debounce without stale results.
5. Combine search + artist + difficulty + progress + sort; RESET should restore all defaults.
6. Select a new song and immediately press Back. Main Menu must continue that selected song and artwork.
7. Check 1280x720-ish, 1440x900-ish and wide desktop layouts for toolbar clipping and Info/Library balance.
8. Verify no duplicate audio and no preview looping regression.

Static release safeguards: 42 built-in chart JSON files must remain byte-identical to v17.4.37; no manifest JSON or validation.txt is permitted.
