# v17.4.22.2 QA — osu!-Inspired Launch Flow

Static checks:
- project/profile/telemetry/startup version strings: 17.4.22.2
- legacy loading center hidden in `loading_transition.tscn`
- generic transition APIs no longer call `_cover()` / legacy loading UI
- Song Launch progress/status controls hidden; loader progress is internal only
- cold splash uses WELCOME -> glyphs -> expanding Beat UP! logo/diamond -> live menu reveal
- built-in chart JSON files unchanged from v17.4.22.1
- no `*manifest*.json` files

Runtime Godot verification is still required on the user's machine because the build environment does not include the Godot executable.
