from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")

project = read("project.godot")
startup_scene = read("scenes/startup.tscn")
main = read("scripts/main.gd")
song_select = read("scripts/song_select.gd")
identity = read("scripts/score_identity.gd")
analyzer = read("scripts/wav_auto_analyzer.gd")

assert any(('config/version="%s"' % version) in project for version in ["18.5.0.2", "18.5.0.2.1", "18.5.0.2.2", "18.6.0", "18.7.0", "18.7.0.1"])
credits = startup_scene.split('[node name="CreditsVersion"', 1)[1].split('[node ', 1)[0]
assert 'unique_name_in_owner = true' in credits
assert 'const RuntimeResourceAccess =' not in main
assert 'const RuntimeResourceAccess =' not in song_select
assert 'func _set_gameplay_layers_visible(visible:' not in main
assert 'for key: Variant in value.keys()' not in identity
assert 'func _deterministic_noise_v15(seed:' not in analyzer
assert 'func _two_finger_noise_v12(seed:' not in analyzer
assert 'peak_beats / PHRASE_BEATS' not in analyzer
assert 'calm_beats / PHRASE_BEATS' not in analyzer
assert '\n\t\t\t\tcandidate_score -= 1000.0\n' in main
assert 'var arrangement_intensity: float = float(phrase.get("arrangement_intensity", 0.5))\n\t\tfor beat_index in range(start_index, mini(end_index, beat_times.size() - 1))' in analyzer
assert 'var _arrangement_intensity:' not in analyzer
assert not list(ROOT.rglob("*manifest*.json"))

print("Beat UP! v18.5.0.2 warning-cleanup checks: PASS")
