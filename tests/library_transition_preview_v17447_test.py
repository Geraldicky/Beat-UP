from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
select = (ROOT / "scripts/song_select.gd").read_text()
preview = (ROOT / "scripts/ui/song_preview_controller.gd").read_text()
session = (ROOT / "scripts/music_session.gd").read_text()
assert "SONG_THUMBNAIL_ROOT" in select
assert "func shell_did_resume" in select
assert "queue_chart_preview" in select
assert "section.get(\"role\", section.get(\"name\", \"\"))" in preview
assert "section_start - phrase_length" in preview
assert "pending_preview" in preview
assert "play_generation" in session
thumbs = list((ROOT / "assets/song_thumbnails").glob("*.png"))
backgrounds = list((ROOT / "assets/backgrounds").glob("background_*.png"))
assert len(thumbs) == len(backgrounds) == 39, (len(thumbs), len(backgrounds))
print("v17.4.47 static QA passed: 39 thumbnails, deferred preview, role-aware musical start, stale-crossfade guard")
