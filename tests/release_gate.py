"""Focused release gate. Usage: python tests/release_gate.py --godot GODOT_PATH"""
from pathlib import Path
import argparse, os, subprocess, tempfile, sys
p = argparse.ArgumentParser()
p.add_argument('--godot', required=True)
a = p.parse_args()
root = Path(__file__).resolve().parents[1]
checks = [
    # This is the authoritative current-build contract. Historical versioned
    # tests below are retained only where they still protect a live invariant.
    'current_release_contract_test.py',
    'main_menu_transport_hotfix_test.py',
    'v18502_warning_cleanup_static_test.py',
    'v1850_release_static_test.py',
    'v1860_waveform_studio_static_test.py',
    'v1870_player_creator_static_test.py',
    'v1870_generator_reliability_static_test.py',
    'exported_audio_runtime_v18403_test.py',
    'full_audio_library_v17448_test.py',
    'library_async_pipeline_v17449_test.py',
    'music_session_variant_type_v174491_test.py',
    'typography_system_v17451_test.py',
    'song_library_release_static_test.py',
]
for name in checks:
    subprocess.run([sys.executable, str(root/'tests'/name)], check=True)
with tempfile.TemporaryDirectory(prefix='beatup-qa-') as directory:
    base = Path(directory)
    env = dict(os.environ, XDG_DATA_HOME=str(base/'import'), APPDATA=str(base/'import'))
    imported = subprocess.run([a.godot, '--headless', '--editor', '--path', str(root), '--import'], env=env, text=True, capture_output=True, timeout=240)
    import_output = imported.stdout + imported.stderr
    if imported.returncode or 'SCRIPT ERROR:' in import_output or 'ERROR:' in import_output or 'GDScript::reload:' in import_output or 'WARNING:' in import_output:
        print(imported.stdout, imported.stderr)
        raise SystemExit('Import/parser/warning check failed')
    runtime_tests = [
        'records_foundation_test.gd',
        'gameplay_input_binding_snapshot_test.gd',
        'app_shell_navigation_lifecycle_test.gd',
        'main_menu_standalone_fallback_test.gd',
        'phase4_ui_foundation_test.gd',
        'live_records_foundation_test.gd',
        'library_layout_foundation_test.gd',
        'v1870_level_pack_test.gd',
        'authoritative_launch_resolution_test.gd',
        'song_library_rhythm_redesign_test.gd',
        'song_library_osu_reference_contract_test.gd',
    ]
    for name in runtime_tests:
        isolated = base/name
        isolated.mkdir()
        env = dict(os.environ, XDG_DATA_HOME=str(isolated), APPDATA=str(isolated))
        if name == 'gameplay_input_binding_snapshot_test.gd':
            env['BEAT_UP_QA_SETTINGS_FIXTURE'] = 'gameplay-input-binding-snapshot'
        elif name == 'app_shell_navigation_lifecycle_test.gd':
            env['BEAT_UP_QA_NAVIGATION_LIFECYCLE'] = 'isolated'
        elif name == 'main_menu_standalone_fallback_test.gd':
            env['BEAT_UP_QA_STANDALONE_NAVIGATION'] = 'isolated'
        elif name == 'phase4_ui_foundation_test.gd':
            env['BEAT_UP_QA_PHASE4_UI'] = 'isolated'
        elif name in {'song_library_rhythm_redesign_test.gd', 'song_library_osu_reference_contract_test.gd'}:
            env['BEAT_UP_QA_SONG_LIBRARY'] = 'isolated'
        r = subprocess.run([a.godot, '--headless', '--path', str(root), '--script', 'res://tests/'+name], env=env, text=True, capture_output=True, timeout=120)
        print(r.stdout, r.stderr)
        # Existing scene teardown can emit a resource retention diagnostic.
        # All script errors and other engine errors remain fatal.
        errors = [line for line in (r.stdout+r.stderr).splitlines() if ('SCRIPT ERROR:' in line or line.startswith('ERROR:')) and 'resources still in use at exit' not in line]
        if r.returncode or errors or 'PASS' not in r.stdout:
            raise SystemExit('FAILED: '+name)
print('RELEASE GATE: PASS (see any printed shutdown warnings)')
