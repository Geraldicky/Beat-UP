from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
THEME = (ROOT / "scripts/ui/minimal_theme.gd").read_text(encoding="utf-8")
SELECT = (ROOT / "scripts/song_select.gd").read_text(encoding="utf-8")
PROJECT = (ROOT / "project.godot").read_text(encoding="utf-8")

for rel in [
    "assets/fonts/SpaceGrotesk-Variable.ttf",
    "assets/fonts/Poppins-Regular.ttf",
    "assets/fonts/Poppins-Medium.ttf",
    "assets/fonts/Poppins-SemiBold.ttf",
    "assets/fonts/IBMPlexMono-Regular.ttf",
]:
    assert (ROOT / rel).exists(), rel

assert 'static func display_font() -> Font:' in THEME
assert 'SPACE_GROTESK_PATH' in THEME
assert 'static func numeric_font() -> Font:' in THEME
assert 'static func apply_numeric(' in THEME
assert 'MinimalThemeScript.display_font()' in SELECT
assert 'MinimalThemeScript.apply_numeric(value_label, 24' in SELECT
print("v17.4.51 typography static QA: PASS")
