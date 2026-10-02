from pathlib import Path

note = Path('scripts/note.gd').read_text(encoding='utf-8')
now = Path('scripts/controllers/now_playing_controller.gd').read_text(encoding='utf-8')
bg = Path('scripts/controllers/main_menu_background_controller.gd').read_text(encoding='utf-8')
music = Path('scripts/music_session.gd').read_text(encoding='utf-8')
theme_gd = Path('config/theme_config.gd').read_text(encoding='utf-8')
theme_tres = Path('config/theme_config.tres').read_text(encoding='utf-8')

# Reverse note: exact Normal geometry. Only outline color differs.
reverse_draw_region = note.split('func _draw() -> void:', 1)[1].split('func get_arrow_color()', 1)[0]
assert 'if note_type == "reverse"' not in reverse_draw_region, 'Reverse still has shape-specific drawing'
assert 'if note_type == "space"' in reverse_draw_region
assert 'return theme_config.reverse_note_outline' in note
assert 'Color("ff5a64")' in theme_gd
assert 'reverse_note_outline = Color(1, 0.352941, 0.392157, 1)' in theme_tres

# Pause/resume: resume an existing stream directly, no cold-start via is_music_playing.
set_paused = now.split('func set_paused(paused: bool) -> void:', 1)[1].split('func toggle_pause()', 1)[0]
assert 'get_current_stream' in set_paused
assert 'menu_bgm.call("is_music_playing")' not in set_paused
assert 'menu_bgm.call("set_music_paused", false)' in set_paused

# MusicSession keeps the playback clock while paused and resumes cached position.
assert 'var last_known_position: float = 0.0' in music
assert 'if player.stream_paused:\n\t\treturn maxf(last_known_position, 0.0)' in music
assert 'player.play(last_known_position)' in music

# Previous/Next: switching transaction must not immediately call start_menu_music,
# because that kills the fade tween before _begin_track swaps streams.
apply_audio = bg.split('func _apply_background_audio(candidate: Dictionary, autoplay: bool = true) -> void:', 1)[1].split('func _publish_candidate_selection', 1)[0]
assert 'play_menu_track' in apply_audio
assert 'menu_bgm.call("start_menu_music"' not in apply_audio

# Syncing a paused MusicSession must preserve pause state.
sync = bg.split('func sync_from_music_session() -> bool:', 1)[1].split('func apply_library_audio_handoff', 1)[0]
assert 'var was_paused' in sync
assert 'if not was_paused' in sync

print('main_menu_transport_hotfix_test: PASS')
