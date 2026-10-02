# Release QA v17.5.0

Engine: Godot 4.6 stable Linux, headless. Source target metadata remains 4.7.

Executed `python tests/release_gate.py --godot /tmp/beatup-engine/Godot_v4.6-stable_linux.x86_64`: PASS.

- Five Python feature checks: complete 39-song audio, async Library, audio type hotfix, typography, Details/Ranking.
- Import/parser check: no script/parser errors.
- Records foundation: coherent best run vs aggregate, lower-score history, duplicate completion, persistence reload, legacy preservation, validation boundaries, mode/Random identity, duplicate import preservation, ZIP export.
- Actual AppShell integration: two completed simulated runs, immediate Library update, selected lower-score run, pre-commit result comparison, 4K/8K separation, telemetry and records in ZIP.
- Focus-loss auto-pause, frozen clock while paused, resume and audio-finished tail guard exercised through gameplay instance.
- Layout populated with large score: 1280x720, 1600x900, 1920x1080. Primary card/actions/library column fit viewport. Missing audio disables PLAY; empty search clears run picker.
- Clock helper sampled at 30/60/144 Hz to check monotonic behavior; these are synthetic samples, not hardware latency measurements.
- 117 chart JSON files, 39 song backgrounds, generator and all originally present music files verified byte-identical to latest uploaded project.

Known limits: ObjectDB shutdown warnings remain; the live scene test also reports two retained resources at exit, inherited from scene lifecycle. The runner explicitly reports these and tolerates only the retained-resources diagnostic; other engine/script errors fail the gate. No actual Windows build, screenshot rendering, or hardware audio/input latency test was performed.

Manual follow-up: play a full song on Windows, verify sound/input timing, select several ranking records, inspect long titles and dropdown keyboard focus, test upgrading with real older saves, export data and open ZIP. The delivered ZIP is the complete Godot source project, not an executable.
