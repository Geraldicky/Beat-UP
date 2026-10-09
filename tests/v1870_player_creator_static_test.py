from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
project = (ROOT / "project.godot").read_text(encoding="utf-8")
export = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
startup = (ROOT / "scenes/startup.tscn").read_text(encoding="utf-8")
tutorial = (ROOT / "scenes/how_to_play_screen.tscn").read_text(encoding="utf-8")
calibration = (ROOT / "scenes/calibration_screen.tscn").read_text(encoding="utf-8")
result_scene = (ROOT / "scenes/result_screen.tscn").read_text(encoding="utf-8")
result_script = (ROOT / "scripts/result_screen.gd").read_text(encoding="utf-8")
select = (ROOT / "scripts/song_select.gd").read_text(encoding="utf-8")
select_scene = (ROOT / "scenes/song_select.tscn").read_text(encoding="utf-8")
catalog = (ROOT / "scripts/level_catalog.gd").read_text(encoding="utf-8")
level_pack = (ROOT / "scripts/level_pack.gd").read_text(encoding="utf-8")
records = (ROOT / "scripts/run_records.gd").read_text(encoding="utf-8")
telemetry = (ROOT / "scripts/playtest_telemetry.gd").read_text(encoding="utf-8")
build = (ROOT / "tools/build_windows_beta.ps1").read_text(encoding="utf-8")

assert 'config/version="18.7.0.1"' in project
assert 'application/product_version="18.7.0.1"' in export
assert 'SYSTEM 18.7.0.1' in startup
assert 'player_creator_enabled=true' in project
assert 'creator_tools_enabled=false' in project
assert 'patch_backups/*' in export and 'tests/*' in export
assert 'PackExportButton' in select_scene
assert '*.beatup-pack' in select_scene
assert 'LevelPackScript.export_song' in select
assert 'MinimalThemeScript.GREEN' not in select
assert 'MinimalThemeScript.SUCCESS' in select
assert 'mode_status.text = "READY"' not in select
assert 'MENU SFX VOLUME' not in startup
assert 'TutorialStepCounter' not in tutorial
assert 'Listen to the pulse, then tap in time.' not in calibration
# The redesigned Results heading expresses completed-run context; typography
# is spaced intentionally, rather than retaining a dummy legacy RESULTS label.
assert 'text = "R E S U L T"' in result_scene
assert 'text = "F I N A L   R A N K"' in result_scene
assert 'text = "FINAL SCORE"' not in result_scene
assert '"RUN COMPLETE"' not in result_script
assert 'LevelPackScript.import_pack' in catalog
assert 'const FORMAT_ID := "beatup-level-pack"' in level_pack
assert 'func import_pack' in level_pack and 'func export_song' in level_pack
assert 'Unsafe archive path' in level_pack
assert 'MAX_ARCHIVE_BYTES' in level_pack and 'MAX_AUDIO_BYTES' in level_pack
assert 'Duplicate archive entry' in level_pack
assert '.install_%s_%d' in level_pack
assert 'MAX_RUN_HISTORY := 100' in records
assert 'MAX_INDEXED_SESSIONS := 250' in telemetry
assert '18.0.0' not in build and '18.7.0.1' not in build
assert '$version = $Matches[1]' in build

print("Beat UP! v18.7.0.1 player/manual creator static QA: PASS")
