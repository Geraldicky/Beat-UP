from pathlib import Path

root = Path(__file__).resolve().parents[1]
editor = (root / "scripts/chart_editor.gd").read_text(encoding="utf-8")
waveform = (root / "scripts/chart_waveform_view.gd").read_text(encoding="utf-8")
scene = (root / "scenes/chart_editor.tscn").read_text(encoding="utf-8")
project = (root / "project.godot").read_text(encoding="utf-8")
export = (root / "export_presets.cfg").read_text(encoding="utf-8")
startup = (root / "scenes/startup.tscn").read_text(encoding="utf-8")

assert any(('config/version="%s"' % version) in project for version in ["18.6.0", "18.7.0", "18.7.0.1"])
assert any(('application/product_version="%s"' % version) in export for version in ["18.6.0", "18.7.0", "18.7.0.1"])
assert any(('SYSTEM %s' % version) in startup for version in ["18.6.0", "18.7.0", "18.7.0.1"])
assert 'res://scripts/chart_waveform_view.gd' in scene
assert '[node name="WaveformPanel" type="Panel" parent="."]' in scene
assert '[node name="Waveform" type="Control" parent="WaveformPanel"]' in scene
assert 'signal seek_requested(time_seconds: float)' in waveform
assert 'func set_waveform(' in waveform
assert 'func _draw_waveform()' in waveform
assert 'draw_colored_polygon(full_shape' in waveform
assert 'func _closed_wave_shape(' in waveform
assert 'Color(WAVE_HOT, 0.82)' in waveform
assert 'func _draw_song_bounds()' in waveform
assert 'func _visible_start()' in waveform
assert 'func _time_at_x(x: float)' in waveform
assert 'var sample_time := visible_start + ratio * window_seconds' in waveform
assert 'var progress := "%s  /  %s"' not in waveform
assert 'seek_requested.emit' in waveform
assert 'waveform.seek_requested.connect(seek_to)' in editor
assert 'generated_chart["editor_waveform"]' in editor
assert 'func _build_waveform_preview(' in editor
assert 'func _build_waveform_preview_from_source(' in editor
assert '_build_waveform_preview_from_source(path, song_id)' in editor
assert 'current_chart["editor_waveform"] = preview' in editor
assert 'const TARGET_SAMPLES := 4096' in editor
assert 'var reviewing: bool = $TimelinePanel.visible' in editor
assert 'var collapse_setup: bool = compact_height and reviewing' in editor
assert 'var timeline_height := clampf(' in editor
assert '$AutoPanel.visible = not collapse_setup' in editor
assert 'current_chart.get("editor_waveform", {})' in editor
assert 'waveform.set_time(editor_time)' in editor
assert 'var waveform: ChartWaveformView' not in editor

print("Beat UP! v18.6.0 waveform Chart Studio static QA: PASS")
