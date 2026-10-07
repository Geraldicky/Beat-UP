# Resume countdown numerals

Generated with the built-in image-generation tool on 2026-10-05, for Beat UP!'s pause/resume presentation. No external game artwork is used.

- `resume_3.png`, `resume_2.png`, `resume_1.png`: original generated PNGs, with genuine alpha transparency.
- `GameplayCountdownVisual` preloads these assets and exposes read-only atlas regions. The source PNGs are not modified at runtime.
- Atlas regions use measured alpha >= 50% silhouette bounds with six source pixels of safety padding, rather than including faint generated noise near the canvas edges. Label-to-number and number-to-progress gaps are both 12 canvas pixels.
- The default three-second resume remains owned by `main.gd`. Neither the sprites nor their animation determines when gameplay/audio resumes.
- Optional exported countdown durations above three seconds retain a text fallback for 4/5; 3/2/1 always use these assets.

## Generation prompt

One built-in generation call per numeral, using the following prompt with `{n}` replaced by `3`, `2`, and `1`:

> Use case: logo-brand. Asset type: production transparent PNG countdown numeral sprite for Beat UP!, a minimal premium dark rhythm game. Create exactly one large Arabic numeral "{n}", centered on a square transparent canvas. The numeral is bold upright geometric sans, condensed but very readable, with slightly chamfered angular corners recalling a diamond motif. Matte pearl white face, a very thin cool cyan edge and subtle dark graphite extrusion only 2-3 pixels, front-facing flat graphic, no perspective. Keep shape clean and restrained, not neon or sci-fi. Numeral occupies 70% canvas height, centered bounding box with generous padding all around. This is one of a matched 3,2,1 countdown set: identical weight, scale, palette and treatment. Text verbatim: "{n}" only. No background, no plate, no diamond frame, no rings, no particles, no extra text, no shadow cloud, no watermark. Genuine alpha transparency required.

Motion: immediate numeral visibility, at most 4% scale settle over 120 ms (quartic ease-out), respecting the existing effect-intensity setting. Progress follows the owner's remaining time linearly; no independent visual clock or exit delay is added.
