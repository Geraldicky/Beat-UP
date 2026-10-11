# Active Developer Tools

- `allin1_bridge.py` + installers — developer-only advanced chart-analysis bridge.
- `chart_studio_postprocess_v17421.py` — retained for historical Chart Studio regression tooling; the editor itself is retired.
- `chart_audio_audit.py` + `requirements-audio-qa.txt` — optional offline audio/chart QA, protected by `tests/chart_audio_audit_test.py`.
- `chart_pacing_audit.py`, `chart_pacing_pilot.py`, `chart_pacing_library.py` and `chart_tempo_trial.py` — offline chart analysis/planning, imported by current release-gate tests.
- `build_windows_beta.ps1` / `.bat` — Windows build helpers.
- `playtest_heatmap_analyzer/` — beta telemetry analysis.

Captured playtest sessions are local-only and are not included in the public checkout. Developer tools are excluded from player exports; run them from the source checkout.
