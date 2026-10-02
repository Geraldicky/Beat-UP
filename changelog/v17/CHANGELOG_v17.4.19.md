# Beat UP! v17.4.19 — Full Library Chart Standardization

## Objective
Standardize the remaining 13 songs (39 charts) using the validated Big Daddy v17.4.18 NORMAL/HARD/MASTER progression as the library benchmark. Big Daddy itself is frozen byte-for-byte.

## Difficulty standard
- **NORMAL:** readability-first, short bursts, frequent recovery, low Reverse pressure.
- **HARD:** stable pressure with musical density escalation, but no sudden unreadable wall.
- **MASTER:** complexity + sustained pressure, including faster bursts and more Reverse, while breaking long microburst chains that can cause reading collapse.

## Full-library pass
The 39 non-Big-Daddy charts are regenerated from their existing deterministic lossless-analysis event pool. Retained note timestamps and directions are never moved. All SPACE events are preserved.

The standardizer adds:
- role-aware 0.5 s / 1 s / 3 s density budgets,
- sustained `<100 ms` and `<170 ms` chain guards,
- deterministic Reverse re-authoring onto safer accents,
- Reverse targets of approximately 6% NORMAL / 12% HARD / 17% MASTER,
- section/intensity escalation preservation.

## Result
Across the 39 standardized charts:
- NORMAL: 7,646 -> 7,588 notes (-58)
- HARD: 10,687 -> 10,469 notes (-218)
- MASTER: 13,564 -> 13,245 notes (-319)
- Total: 31,897 -> 31,302 notes (-595; ~1.9%)

This is a readability standardization pass, not a global nerf. Charts that already satisfied the benchmark receive little or no note removal; charts with sustained short-gap pressure receive more smoothing.

## Frozen benchmark
Big Daddy remains exactly as v17.4.18:
- NORMAL: 608 notes / 37 Reverse / 14 SPACE
- HARD: 820 notes / 101 Reverse / 17 SPACE
- MASTER: 974 notes / 163 Reverse / 20 SPACE

## Runtime scope
No gameplay timing windows, scoring, judgement logic, scroll-speed logic, visuals, result screen, settings, telemetry schema, or menu behavior were intentionally changed.
