"""Historical gate slot now protects the explicitly retired Studio package."""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
for path in ["scripts/chart_editor.gd", "scenes/chart_editor.tscn",
             "scripts/chart_timeline_view.gd", "scripts/chart_waveform_view.gd"]:
    assert not (root / path).exists(), "Retired Chart Studio returned: " + path
for path in ["scripts/startup.gd", "scripts/song_library.gd", "scripts/main.gd",
             "scripts/app_shell.gd", "scripts/navigation_controller.gd",
             "scripts/scene_transition.gd"]:
    source = (root / path).read_text(encoding="utf-8")
    assert "res://scenes/chart_editor.tscn" not in source, path
    assert "request_chart_studio" not in source, path
assert (root / "scripts/level_pack.gd").exists()
catalog = (root / "scripts/level_catalog.gd").read_text(encoding="utf-8")
assert "user://chart_exports" in catalog
assert "resolve_playable" in catalog
print("Chart Studio retirement / preserved import and resolution QA: PASS")
