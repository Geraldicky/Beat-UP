from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
analyzer = (ROOT / "scripts" / "wav_auto_analyzer.gd").read_text(encoding="utf-8")
bridge = (ROOT / "tools" / "allin1_bridge.py").read_text(encoding="utf-8")
shell = (ROOT / "scripts" / "app_shell.gd").read_text(encoding="utf-8")
music_session = (ROOT / "scripts" / "music_session.gd").read_text(encoding="utf-8")
song_select = (ROOT / "scripts" / "song_select.gd").read_text(encoding="utf-8")

assert 'const CHART_GENERATOR_CODE := "BUP-CG-01871"' in analyzer
assert 'func finalize_generated_set' in analyzer
assert '"beat_grid_alignment"' in analyzer
assert '"shared_anchor_ratio"' in analyzer
assert '"max_notes_per_4_seconds"' in analyzer
assert 'four-second fatigue budget' in analyzer
assert 'def _quiet_inference_output' in bridge
assert 'with _quiet_inference_output()' in bridge
assert 'player.stream_paused = false' in music_session
assert 'Chart Studio drafts deliberately contain zero events' in song_select
assert 'not _chart_is_playable(data)' in song_select

print("Beat UP! v18.7.0 balanced generator reliability static QA: PASS")
