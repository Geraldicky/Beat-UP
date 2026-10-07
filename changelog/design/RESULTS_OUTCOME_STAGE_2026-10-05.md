# Results: outcome stage

Supersedes the previous hero/table layout. Three deliberately different zones
replace the top song banner, horizontal stat cards and full-width breakdown:

- Left song dossier: a large square jacket, wrapped song title, artist and
  run context. Cover art remains a local square, never fullscreen ambience.
- Center outcome: generated rank glyph above CLEAR, score and PB/save status;
  compact centered accuracy/combo/% PERFECT below. No progress rails.
- Right performance: four vertically paired semantic judgement/count rows,
  followed by vertically stacked SPACE and REVERSE hit/total/miss summaries.
- Bottom: centered Song Library / Retry actions and centered keyboard hints.
  TRACK COMPLETE is a quiet top rail, not a song banner. Personal Best belongs
  directly beneath score with its existing score/accuracy delta.

Actual scene nodes are reparented, not overlaid with a duplicate presentation.
Unique metric identities and finalized values/reveal sound/transaction owner
are retained. Artist/run metadata is separated at the first existing bullet
for presentation only; 8-DIR/4-ARROW display as 8K/4K, internal AUTHORED is
omitted, and active Random/Reverse remain visible. The finalized snapshot
retains its original contents.
Song titles wrap up to three lines. Missing art hides the entire jacket area.
Follow-up polish reduces the rank area to 250 design pixels and reserves 72
scaled pixels before actions to raise the composition without moving controls
by independent coordinates. Accuracy uses 40px versus 28px supporting values.
Each special-note row hides independently when its total is zero, avoiding
REVERSE 0/0 while retaining SPACE. Personal Best uses a centered natural-width
badge instead of a detached top-right badge or full-width card.
Caption refinement hides the CLEAR/CALCULATING presentation throughout the
existing reveal, retaining its internal state without affecting rank/audio.
FINAL RANK and SCORE captions use scaled 20px semibold type. Regression checks
the hidden state both before and after calculation and the stronger captions.

Motion-design principles retain purposeful short opacity reveals; the song
dossier participates in the existing cancellable Results reveal. No new
motion manager or layout animation. Header/score/count sound timing and input
unlock timing unchanged. No scoring, records, chart, gameplay, MusicSession,
navigation, settings or application-version changes (18.7.0.1).

Scoped files: scenes/result_screen.tscn, scripts/result_screen.gd,
tests/result_redesign_test.gd, tests/ui_capture.gd, this note. Capture test
paths/non-overlap expectations follow the new score owner instead of retaining
dummy legacy nodes. Behavioral value/SFX/action assertions remain intact.

Real OpenGL Results renders at 1280x720, 1600x900 and 1920x1080: PASS.
1080p and 720p inspected. Tests assert three-zone containment, vertical
judgement order, score beneath rank, no legacy dashboard rails, semantic
colors, metadata visibility, missing artwork, long titles, all six rank
sprites, PB/save state, immutable finalized snapshot and one-action locking.
Capture directory: C:\Users\USER\AppData\Local\Temp\beatup-fresh-results-final-d5w8vkf1.
Follow-up polished captures: C:\Users\USER\AppData\Local\Temp\beatup-results-refined-xq2vi_bi.
The regression also checks score-local PB containment, stronger accuracy type,
player-facing metadata without snapshot mutation, and independent special-row
visibility across successive 4K/8K and Reverse results.

Final verification: strict Godot import/parser/warning validation PASS;
Results layout suite PASS, action/SFX reveal suite PASS, model suite PASS,
git diff --check PASS; full release gate exited 0 with RELEASE GATE: PASS
(see any printed shutdown warnings). Existing resource-retention shutdown
diagnostics remain visible, and gate criteria were not weakened.

The older `ui_capture.gd -- result` harness was also exercised. Its new node
paths resolved and no Results layout overlap was reported, but it emitted
existing gameplay hit/miss sound expectations and synthetic end-fight fixture
accuracy/rank failures after production reconciliation added unresolved notes
as MISS. These are not claimed as PASS and were not fixed in this visual task.
The isolated Results scene suite verifies count-derived values independently
and passes; the authoritative runtime release gate also passes.
