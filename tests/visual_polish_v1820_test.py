from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
project = (ROOT / "project.godot").read_text(encoding="utf-8")
assert 'config/version="18.2.0"' in project

library = (ROOT / "scripts/ui/library_composition.gd").read_text(encoding="utf-8")
assert 'info_caption.text = "SELECTED"' in library
assert 's.info_panel.size_flags_stretch_ratio = 0.42' in library
assert 's.wheel_column.size_flags_stretch_ratio = 0.58' in library
assert 's.ranking_mods_label.visible = true' in library
assert 'dev_button.visible = false' in library
assert 'EXPORT PLAYTEST' not in library

pause = (ROOT / "scripts/pause_menu.gd").read_text(encoding="utf-8")
assert 'PauseActionHint' in pause
result = (ROOT / "scripts/result_screen.gd").read_text(encoding="utf-8")
assert 'special_panel.visible = _space_total_target > 0 or _reverse_total_target > 0' in result
calibration = (ROOT / "scripts/calibration_screen.gd").read_text(encoding="utf-8")
assert 'apply_button.disabled = true' in calibration

# Prevent the parser issue previously caused by duplicate @onready/top-level variables.
for rel in [
    "scripts/song_select.gd", "scripts/pause_menu.gd", "scripts/result_screen.gd",
    "scripts/calibration_screen.gd", "scripts/chart_editor.gd", "scripts/main.gd"
]:
    text = (ROOT / rel).read_text(encoding="utf-8")
    names = []
    for line in text.splitlines():
        if line.startswith("@onready var ") or line.startswith("var "):
            m = re.match(r"(?:@onready\s+)?var\s+([A-Za-z_][A-Za-z0-9_]*)", line)
            if m:
                names.append(m.group(1))
    duplicates = sorted({n for n in names if names.count(n) > 1})
    assert not duplicates, f"duplicate top-level vars in {rel}: {duplicates}"

# Standing project rule: no build manifest JSON.
manifest_json = [p for p in ROOT.rglob("*.json") if "manifest" in p.name.lower()]
assert not manifest_json, manifest_json
assert len(list((ROOT / "charts").rglob("*.json"))) == 117
assert len(list((ROOT / "assets/backgrounds").glob("background_*.png"))) == 39
print("v18.2.0 visual polish static gate: PASS")
