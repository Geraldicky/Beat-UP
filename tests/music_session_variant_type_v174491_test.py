from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = (root / "scripts" / "music_session.gd").read_text(encoding="utf-8")
project = (root / "project.godot").read_text(encoding="utf-8")

assert 'var evict_path: String = str(audio_cache_order.pop_front())' in source
assert 'var evict_path := audio_cache_order.pop_front()' not in source
print("v17.4.49.1 Variant inference hotfix static checks passed")
