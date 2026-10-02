# v17.4.21.5 QA — Transition Input Lock

Static checks:
- SceneTransition consumes key/mouse/joypad button events while `transitioning == true`.
- Startup consumes input while `in_transition` or SceneTransition is busy.
- SongSelect `_transition_out()` does not lock controls if SceneTransition is already busy.
- SongSelect ESC handling is suppressed during an inbound transition.
- No `*manifest*.json` files exist.
- Built-in charts are unchanged from v17.4.21.4.

Runtime regression to verify locally:
1. Main Menu -> PLAY.
2. Spam ESC during Beat Diamond cover, scene swap, and reveal.
3. Song Library must finish opening and remain fully interactive.
4. ESC after reveal must return normally to Main Menu.
5. Repeat with Chart Studio and rapid mouse/controller inputs.
