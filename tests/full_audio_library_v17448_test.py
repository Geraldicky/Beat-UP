from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
CHARTS = ROOT / "charts"

missing = []
seen = set()
for normal in sorted(CHARTS.glob("*/normal.json")):
    data = json.loads(normal.read_text(encoding="utf-8"))
    audio = data.get("audio", "")
    if not audio.startswith("res://"):
        missing.append((data.get("song_id"), audio, "invalid path"))
        continue
    local = ROOT / audio[len("res://"):]
    if not local.is_file():
        missing.append((data.get("song_id"), audio, "missing file"))
    seen.add(data.get("song_id"))

assert len(seen) == 39, f"Expected 39 songs, got {len(seen)}"
assert not missing, f"Missing audio: {missing}"
print("PASS: 39/39 song audio references resolve")
