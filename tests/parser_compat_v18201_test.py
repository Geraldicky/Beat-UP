from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
interaction = (ROOT/'scripts/ui/interaction_polish.gd').read_text(encoding='utf-8')
perf = (ROOT/'scripts/v18/performance_monitor.gd').read_text(encoding='utf-8')
cal = (ROOT/'scripts/calibration_screen.gd').read_text(encoding='utf-8')
select = (ROOT/'scripts/song_select.gd').read_text(encoding='utf-8')
score_identity = (ROOT/'scripts/score_identity.gd').read_text(encoding='utf-8')
now_playing = (ROOT/'scripts/controllers/now_playing_controller.gd').read_text(encoding='utf-8')
how_to = (ROOT/'scripts/ui/how_to_play_visual.gd').read_text(encoding='utf-8')
project = (ROOT/'project.godot').read_text(encoding='utf-8')
assert 'config/version="18.2.0.1"' in project
assert 'const Theme =' not in interaction
assert 'const VisualTheme =' in interaction
assert 'func begin_span(name:' not in perf
assert 'func end_span(name:' not in perf
assert 'var keys: Array[int] =' not in cal
assert 'for key in emitted_beat_times_s.keys()' not in cal
assert 'func _short_generator_name(name:' not in select
assert 'func _short_source_name(name:' not in select
assert 'for key: Variant in keys:' not in score_identity
assert 'total_seconds / 60' not in now_playing
assert 'index / columns' not in how_to
print('v18.2.0.1 parser/warning compatibility static checks passed.')
