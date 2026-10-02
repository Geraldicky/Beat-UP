from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASELINE = Path("/mnt/data/Beat_UP_v17.4.23_Zero_Loading_Screen_Seamless_Gameplay_Handoff")


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


project = (ROOT / "project.godot").read_text(encoding="utf-8")
startup_scene = (ROOT / "scenes/startup.tscn").read_text(encoding="utf-8")
startup = (ROOT / "scripts/startup.gd").read_text(encoding="utf-8")
telemetry = (ROOT / "scripts/playtest_telemetry.gd").read_text(encoding="utf-8")
profile = (ROOT / "scripts/player_profile.gd").read_text(encoding="utf-8")

require('config/version="17.4.23.1"' in project, "Project version must be 17.4.20")
require("SYSTEM 17.4.23.1" in startup_scene, "Startup build label must be 17.4.20")
require('const APP_VERSION := "17.4.23.1"' in telemetry, "Telemetry app version must be 17.4.20")
require("const SCHEMA_VERSION := 2" in telemetry, "Telemetry schema must be v2 for player_id")

require('const PROFILE_PATH := "user://player_data/profile.json"' in profile, "Local profile path missing")
require('"player_id"' in profile, "Local profile must persist player_id")
require('PlayerProfileScript.initialize_profile()' in startup, "Startup must initialize the local profile")
require('"player_id": player_id' in telemetry, "Session telemetry must contain player_id")
require('"player_id": str(_session.get("player_id", ""))' in telemetry, "Session index must contain player_id")
require("PlayerProfileScript.record_session(" in telemetry, "Finalized sessions must update local profile stats")

for forbidden in ('"player_name"', '"username"', '"display_name"', 'PLAYER NAME', 'CREATE PROFILE'):
    require(forbidden not in profile, f"Player profile must not contain {forbidden}")
    require(forbidden not in telemetry, f"Telemetry must not contain {forbidden}")

# Existing chart library is frozen for this persistence-only release.
current_charts = sorted((ROOT / "charts").glob("*/*.json"))
baseline_charts = sorted((BASELINE / "charts").glob("*/*.json"))
require(len(current_charts) == 42, f"Expected 42 charts, found {len(current_charts)}")
require([p.relative_to(ROOT / "charts") for p in current_charts] == [p.relative_to(BASELINE / "charts") for p in baseline_charts], "Chart paths changed")
for current in current_charts:
    rel = current.relative_to(ROOT)
    baseline = BASELINE / rel
    require(sha256(current) == sha256(baseline), f"Chart changed unexpectedly: {rel}")

# Gameplay controller and scoring/result implementation are intentionally unchanged.
for rel in (
    Path("scripts/main.gd"),
    Path("scripts/note.gd"),
    Path("scripts/result_screen.gd"),
    Path("scripts/rhythm_timing.gd"),
    Path("scripts/track.gd"),
):
    require(sha256(ROOT / rel) == sha256(BASELINE / rel), f"Gameplay file changed unexpectedly: {rel}")

print("v17.4.20 local player profile static QA: PASS")
