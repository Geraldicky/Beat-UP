# Beat UP! v18.5.0.2 — Debugger Cleanup Hotfix

## Fixed

- Registered `CreditsVersion` as a scene-unique node so startup no longer
  reports a missing-node error.
- Removed the duplicate `RuntimeResourceAccess` identifier warning while
  preserving exported-PCK audio detection.
- Removed built-in and base-class shadowing for score, position, scale,
  visible, ready, snapped, seed, and related temporary values.
- Replaced ambiguous mixed-type ternaries with explicit typed branches.
- Added explicit enum casts for process mode, VSync, and WAV loop mode.
- Replaced unintended integer division with explicit floating-point math.
- Removed or marked intentionally unused parameters and local variables.

This patch is code-quality-only. It does not change chart data, score rules,
timing windows, note colors, backgrounds, or gameplay behavior.
