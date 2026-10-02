from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
editor = (ROOT / "scripts" / "chart_editor.gd").read_text(encoding="utf-8")
analyzer = (ROOT / "scripts" / "wav_auto_analyzer.gd").read_text(encoding="utf-8")
bridge = (ROOT / "tools" / "allin1_bridge.py").read_text(encoding="utf-8")
shell = (ROOT / "scripts" / "app_shell.gd").read_text(encoding="utf-8")
music_session = (ROOT / "scripts" / "music_session.gd").read_text(encoding="utf-8")
song_select = (ROOT / "scripts" / "song_select.gd").read_text(encoding="utf-8")

assert 'const CHART_GENERATOR_CODE := "BUP-CG-01870"' in analyzer
assert 'func finalize_generated_set' in analyzer
assert '"beat_grid_alignment"' in analyzer
assert '"shared_anchor_ratio"' in analyzer
assert '"max_notes_per_4_seconds"' in analyzer
assert 'four-second fatigue budget' in analyzer
assert '"QUALITY GATE"' in editor
assert 'wav_analyzer.finalize_generated_set' in editor
assert 'func _run_local_wav_analysis' in editor
assert 'Thread.new()' in editor
assert 'ALLIN1_CPU_TIMEOUT_SECONDS := 15' in editor
assert 'OS.create_process' in editor and 'OS.kill(process_id)' in editor
assert 'def _quiet_inference_output' in bridge
assert 'with _quiet_inference_output()' in bridge
assert 'func _pause_music_for_chart_studio' in shell
assert 'func _restore_music_after_chart_studio' in shell
assert 'session.call("set_paused", true)' in shell
assert 'player.stream_paused = false' in music_session
assert 'Chart Studio drafts deliberately contain zero events' in song_select
assert 'not _chart_is_playable(data)' in song_select
assert 'func _find_existing_import_for_source' in editor
assert 'existing_import["reused"] = true' in editor
assert '_remove_tree_absolute(chart_dir_absolute)' in editor

print("Beat UP! v18.7.0 balanced generator reliability static QA: PASS")
