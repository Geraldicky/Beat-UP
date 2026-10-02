from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
scene_transition = (ROOT / "scripts/scene_transition.gd").read_text(encoding="utf-8")
startup = (ROOT / "scripts/startup.gd").read_text(encoding="utf-8")
song_select = (ROOT / "scripts/song_select.gd").read_text(encoding="utf-8")

assert "func _input(event: InputEvent) -> void:" in scene_transition
assert "if not transitioning:" in scene_transition
assert "get_viewport().set_input_as_handled()" in scene_transition
assert "if in_transition or SceneTransition.is_transitioning():" in startup
assert "if transitioning_out or SceneTransition.is_transitioning():" in song_select
assert "if SceneTransition.is_transitioning():" in song_select
assert not list(ROOT.rglob("*manifest*.json"))
print("PASS: transition input lock static checks")
