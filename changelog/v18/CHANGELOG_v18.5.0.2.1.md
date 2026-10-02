# Beat UP! v18.5.0.2.1 — Cleanup Parser Hotfix

## Fixed

- Restored the missing indentation in the deterministic 4-key direction
  scoring branch in `main.gd`.
- Restored the live `arrangement_intensity` variable used by legacy generator
  candidate scoring.
- Kept the actually unused arrangement value in SPACE generation explicitly
  marked as unused.

No gameplay values, charts, score rules, note colors, or UI layout changed.
