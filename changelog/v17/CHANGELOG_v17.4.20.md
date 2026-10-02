# Beat UP! v17.4.20 — Local Player Profile & Save Data Foundation

## Objective
Add a persistent local player identity for Beta playtest telemetry without accounts, cloud services, login, email, passwords, or player-name input.

## Local profile
A profile is created automatically and silently at first launch:

`user://player_data/profile.json`

The profile stores:
- a random stable anonymous `player_id` in the form `P-XXXXXXXX`,
- creation timestamp,
- last finalized session metadata,
- completed/aborted session counts,
- total finalized session time.

The profile uses the existing atomic JSON + backup recovery helper. The ID is random and is not derived from OS username, hostname, IP address, MAC address, hardware serial, or other device identifiers.

## Telemetry integration
Telemetry schema is bumped from v1 to v2. New sessions include top-level `player_id`, and new `session_index.json` entries also include `player_id`.

Existing v1 session JSON files are not rewritten or backfilled. Old telemetry remains valid and can coexist with new v2 sessions.

When a session is successfully finalized to disk, the local profile updates its aggregate session counters. If profile-stat persistence fails, the telemetry session itself remains saved.

## No player name
There is intentionally:
- no player-name field,
- no username,
- no first-launch naming prompt,
- no account screen,
- no authentication,
- no network dependency.

## Frozen gameplay scope
No chart, gameplay timing, judgement, scoring, scroll-speed, note visuals, result logic, settings behavior, or chart-generation behavior is intentionally changed in this release. All 42 chart JSON files are byte-identical to v17.4.19.
