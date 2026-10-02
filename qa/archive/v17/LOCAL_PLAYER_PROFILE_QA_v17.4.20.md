# v17.4.20 Local Player Profile QA

## Static verification
- Project/build label updated to v17.4.20.
- `scripts/player_profile.gd` creates `user://player_data/profile.json` automatically.
- Player ID format is `P-XXXXXXXX` using random bytes.
- No player name, username, email, password, hostname, IP, MAC, serial, or OS-user field is stored.
- Profile persistence uses `ReliableJsonStore.save_dictionary_atomic`, including backup recovery.
- Telemetry schema is v2 and new session JSON contains top-level `player_id`.
- New session-index rows contain `player_id`.
- Completed and aborted finalized sessions update anonymous local profile counters.
- Existing telemetry is not destructively migrated or backfilled.
- All 42 chart files are SHA-256 byte-identical to v17.4.19.
- Core gameplay controller, note logic, result logic, timing logic, and track logic are byte-identical to v17.4.19.
- Static test `tests/local_player_profile_v17420_test.py` passes.

## Expected first-launch behavior
No new screen appears. Startup silently creates the profile before the main menu becomes interactive. The generated anonymous player ID remains stable across restarts until `profile.json` is intentionally deleted/reset.

## Runtime validation required
Godot is not installed in the build environment, so runtime execution was not performed here. Local validation should confirm:
1. First launch creates `player_data/profile.json`.
2. Relaunch keeps the same `player_id`.
3. Playing a song writes the same `player_id` into the new telemetry session and index row.
4. Completed/aborted counters increment once per finalized session.
5. Corrupting the primary profile while leaving `.bak` valid recovers the backup.
