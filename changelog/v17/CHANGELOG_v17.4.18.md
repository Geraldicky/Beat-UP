# Beat UP! v17.4.18 — Big Daddy MASTER Telemetry Rebalance Pass 2

## Objective
Rebalance **Big Daddy MASTER only** after the first completed v17.4.17 MASTER playtest showed a clear readability/reaction collapse pattern rather than uniform skill pressure.

## Telemetry basis
The source run finished at **67.43% accuracy**, **277 directional MISS**, **168 max combo**, rank **C**, with **79 Reverse MISS** and **0 SPACE MISS**. The strongest failure windows were concentrated around 39–42s, 57–60s, 63–69s, 72–81s, 159–180s, 201–210s, 213–219s, 222–228s, and 246–249s.

The problem was not global timing calibration. The run contained long stable sections, including a 30-second section with no directional MISS, followed by localized chains where dense <=160 ms streams and Reverse pressure caused repeated WRONG INPUT / automatic MISS cascades.

## Chart changes
- Big Daddy MASTER directional notes: **1037 → 974**
- Reverse: **189 → 163**
- SPACE: **20 → 20**
- NORMAL: unchanged from v17.4.17
- HARD: unchanged from v17.4.17 / validated v17.4.16 anchor
- Retained timestamps: unchanged
- Retained directions: unchanged
- No timing-window, scroll-speed, judgement, gameplay visual, result-screen, or settings changes

## Balancing policy
This pass removes 63 telemetry-confirmed failure slots only. It prioritizes micro-recovery inside sustained <=160 ms pressure strings while deliberately preserving enough 79 ms burst language for MASTER to remain clearly above HARD.

The target is not to make MASTER easy. The target is to replace unreadable collapse walls with difficult but parseable pressure: higher average density than HARD, substantially more Reverse usage, denser half-second bursts, and less recovery, without repeated 10–13 MISS chains caused by reaction/readability overload.

## Validation
Static checks verify 974 directional notes, 163 Reverse, 20 SPACE, strict timing order, valid directions/types, retained-event identity, NORMAL/HARD byte identity, and no changes to the other 39 charts. Godot runtime is not available in the build sandbox, so runtime playtest must still be performed locally.
