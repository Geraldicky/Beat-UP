# Beat UP! v18.6.0 — Waveform Chart Studio

## Added

- Functional full-song audio waveform overview in Chart Studio.
- Click-and-drag waveform seeking with hover timestamps.
- Current-time playhead and highlighted 12-second timeline viewport.
- Compact PCM energy-envelope metadata embedded into newly generated charts.
- Automatic waveform preview generation after selecting a FLAC source, including for legacy charts.

## Changed

- Relayouted Chart Studio so the waveform sits between chart selection and transport controls.
- Compact-height review mode collapses the generator panel to preserve editing space.
- Waveform data is normalized and downsampled to 640 values; no WAV or FLAC payload is embedded.

## Compatibility

- Existing charts remain valid; selecting their FLAC source builds a preview that can be persisted with SAVE CHART.
- Chart events, SPACE events, BPM, beat offset, scoring, and gameplay behavior are unchanged.
- No build manifest JSON is included.
