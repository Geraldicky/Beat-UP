from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
project = (ROOT / "project.godot").read_text(encoding="utf-8")
export = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
startup = (ROOT / "scenes/startup.tscn").read_text(encoding="utf-8")
note = (ROOT / "scripts/note.gd").read_text(encoding="utf-8")
gameplay = (ROOT / "config/gameplay_config.gd").read_text(encoding="utf-8")
result = (ROOT / "config/result_config.gd").read_text(encoding="utf-8")
policy = (ROOT / "scripts/score_policy.gd").read_text(encoding="utf-8")

# Current build identity.
assert 'config/version="18.7.0.1"' in project
assert 'application/file_version="18.7.0.1"' in export
assert 'application/product_version="18.7.0.1"' in export
assert 'SYSTEM 18.7.0.1' in startup

# Chart Studio is retired; chart import/export and persisted sources survive.
assert not (ROOT / "scripts/chart_editor.gd").exists()
assert not (ROOT / "scenes/chart_editor.tscn").exists()
assert 'run/main_scene="res://scenes/boot.tscn"' in project
assert 'creator_tools_enabled=false' in project

# Reverse presentation contract: identical Normal geometry, red outline only.
assert 'Reverse intentionally keeps the exact Normal-note geometry' in note
assert 'if note_type == "reverse":' in note
assert 'Color("ff5a64")' in note
assert 'Normal and Reverse intentionally share the same fill and silhouette.' in note

# Frozen gameplay contracts from the canonical remake plan.
for token in [
    'perfect_window: float = 0.035',
    'great_window: float = 0.060',
    'good_window: float = 0.090',
    'space_perfect_window: float = 0.060',
    'space_great_window: float = 0.110',
    'space_good_window: float = 0.170',
]:
    assert token in gameplay
for token in [
    'perfect_accuracy_weight: float = 1.00',
    'great_accuracy_weight: float = 0.80',
    'good_accuracy_weight: float = 0.50',
    'miss_accuracy_weight: float = 0.00',
    'ss_accuracy: float = 98.5',
    's_accuracy: float = 95.0',
    'a_accuracy: float = 88.0',
    'b_accuracy: float = 78.0',
    'c_accuracy: float = 65.0',
]:
    assert token in result
assert 'const MAX_DISPLAY_SCORE := 9_999_999' in policy

# Release hygiene.
assert not list(ROOT.rglob("build_manifest.json"))
assert not list(ROOT.rglob("validation.txt"))
assert not [p for p in ROOT.rglob("manifest.json") if "patch_backups" not in p.parts]

print("Beat UP! v18.7.0.1 current release contract QA: PASS")
