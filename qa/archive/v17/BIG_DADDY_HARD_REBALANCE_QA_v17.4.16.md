# Beat UP! v17.4.16 — Big Daddy HARD Rebalance QA

## Static checks
- Big Daddy HARD has 820 directional notes.
- Reverse count remains 101.
- SPACE count remains 17.
- All retained event timestamps stay in ascending order.
- No retained direction is modified.
- All other 41 chart JSON files must remain byte-identical to v17.4.15.

## Playtest validation
Use the same settings as the pre-rebalance runs:
- 8-direction input
- Random OFF
- same calibration / offsets

Recommended validation:
1. Play Big Daddy HARD 3–5 times.
2. Load the new telemetry into the Heatmap Analyzer.
3. Compare these windows first:
   - 01:03–01:06
   - 01:15–01:21
   - 02:33–02:36
   - 02:45–02:49
   - 02:57–03:00
   - 03:30–03:34
   - 03:45–03:48
4. Success criteria:
   - repeated red clusters should reduce,
   - chart should still feel HARD,
   - no new collapse hotspot should appear immediately after a thinned burst,
   - Reverse performance should remain stable.
