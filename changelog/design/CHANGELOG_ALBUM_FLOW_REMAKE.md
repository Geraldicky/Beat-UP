# Beat UP! — Album Flow Visual Remake

## Presentation

- Rebuilt the global visual language around the Album Flow direction.
- Replaced the legacy saturated/neon UI palette with neutral navy surfaces, editorial light typography and restrained periwinkle accents.
- Added explicit PERFECT/GREAT/GOOD/MISS semantic colors.
- Added shared S0/S1/S2/S3 surface helpers and spacing/motion tokens.
- Reworked Main Menu into artwork-first left-rail composition with a slim Now Playing bar.
- Removed the old main-menu orb from the active composition and stopped unnecessary hidden-orb animation work.
- Added a lightweight music-reactive Flow Line and restrained artwork-field diamond echo.
- Flattened Song Library detail/ranking treatment and added a designed missing-art fallback.
- Simplified gameplay HUD to score/combo/accuracy/progress/judgement.
- Reworked Normal/Reverse/Space note presentation around the locked diamond language.
- Updated hit-zone/lane/judgement colors.
- Removed hexagonal sci-fi frames from Pause actions and softened pause motion.
- Reworked Result backdrop to preserve song artwork and reduced metric-card density.
- Removed mandatory Song Launch realtime blur and overshoot-heavy reveal motion.
- Recolored Calibration, tutorial defaults and Chart Studio into the new visual system.
- Replaced major user-facing `TRANS_BACK` presentation motion with restrained Quint/Cubic transitions.

## Functional preservation

- No intentional changes to timing windows, scoring, accuracy, combo, Reverse logic, Space logic, Random behavior, BPM scroll formula, chart data, save identity, records, replay or telemetry.
- Existing v18.7 creator/generator flow remains available in this direct-original remake.

## Validation

- Current v18.7/v18.6/v18.5 static release checks used for this patch pass.
- Production `res://` dependency scan passes.
- Runtime Godot verification is still required on the user's machine because no Godot executable is available in the patch-generation environment.
