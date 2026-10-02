from pathlib import Path
import hashlib

ROOT = Path(__file__).resolve().parents[1]
project = (ROOT / 'project.godot').read_text(encoding='utf-8')
startup = (ROOT / 'scripts/startup.gd').read_text(encoding='utf-8')
startup_scene = (ROOT / 'scenes/startup.tscn').read_text(encoding='utf-8')
shell = (ROOT / 'scripts/app_shell.gd').read_text(encoding='utf-8')
shell_scene = (ROOT / 'scenes/app_shell.tscn').read_text(encoding='utf-8')
editor = (ROOT / 'scripts/chart_editor.gd').read_text(encoding='utf-8')
select = (ROOT / 'scripts/song_select.gd').read_text(encoding='utf-8')
select_scene = (ROOT / 'scenes/song_select.tscn').read_text(encoding='utf-8')
cal = (ROOT / 'scripts/calibration_screen.gd').read_text(encoding='utf-8')
how_scene = (ROOT / 'scenes/how_to_play_screen.tscn').read_text(encoding='utf-8')
main = (ROOT / 'scripts/main.gd').read_text(encoding='utf-8')
icons = (ROOT / 'scripts/ui/action_icon.gd').read_text(encoding='utf-8')
ranking = (ROOT / 'scripts/ui/library_composition.gd').read_text(encoding='utf-8')
logo = (ROOT / 'scripts/ui/main_menu_logo.gd').read_text(encoding='utf-8')

assert 'config/version="18.3.0"' in project
assert 'environment/defaults/default_clear_color=Color(0.012, 0.014, 0.020, 1)' in project
assert 'BootSurface' in shell_scene
assert '_set_splash_logo_reveal' in startup
assert 'tween_method(Callable(self, "_set_splash_logo_reveal")' in startup
assert 'show_text = false' in startup_scene
assert '[node name="TopAccent"' in startup_scene and 'visible = false' in startup_scene
assert '[node name="TopAccent"' in select_scene and 'visible = false' in select_scene
assert 'custom_minimum_size = Vector2(500, 286)' in select_scene
assert '8K  ·  NUMPAD' in select_scene and '4K  ·  ARROWS' in select_scene
assert 'RANDOM   ·   shuffle directions' in select_scene
assert 'row_button.custom_minimum_size.y = 68' in ranking
assert 'mode_text += " · RND"' in ranking
assert 'stats_width: float = clampf(viewport_size.x * 0.155' in main
assert 'Sliders communicate "settings" more clearly' in icons
assert 'ROUTE_CHART_STUDIO' in shell
assert 'ResourceLoader.load_threaded_request(CHART_STUDIO_SCENE_PATH' in shell
assert 'SONG  →  GENERATE  →  REVIEW  →  SAVE' in editor
assert 'CHOOSE OGG' in editor and 'CHOOSE FLAC' in editor
assert 'Thread.new()' in editor
assert 'STEP 1 / 2  ·  LISTEN + TAP' in cal
assert 'STEP 2 / 2  ·  REVIEW + APPLY' in cal
assert 'text = "LEARN BEAT UP!"' in how_scene
assert 'text = "CANCEL"' in startup_scene and 'text = "EXIT"' in startup_scene
assert 'show_text: bool = true' in logo
assert 'const Theme =' not in (ROOT / 'scripts/ui/interaction_polish.gd').read_text(encoding='utf-8')

# No accidental manifest JSON should exist.
assert not list(ROOT.rglob('*manifest*.json'))
print('Beat UP! v18.3.0 presentation/architecture static gate passed.')
