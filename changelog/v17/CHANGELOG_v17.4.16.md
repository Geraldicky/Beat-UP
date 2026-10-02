# Beat UP! — CHANGELOG v17.4.16

## Objective
First telemetry-driven chart rebalance using repeated player data.

## Scope
Only `charts/big_daddy/hard.json` is changed.

## Big Daddy HARD
- Notes: **839 → 820** (`-19`, about `-2.3%`).
- Reverse notes: **101 → 101** (unchanged).
- SPACE events: **17 → 17** (unchanged).
- Star rating: **8★** (unchanged).
- Retained note timestamps are not moved.
- Retained note directions are not changed.
- No Reverse note is removed by this pass.

## Why these notes were removed
Five completed Big Daddy HARD runs showed repeated player-collapse clusters rather than uniform difficulty. The pass targets overloaded slots around:
- ~01:05
- ~01:15–01:21
- ~02:34
- ~02:47–02:49
- ~02:58–02:59
- ~03:31–03:34
- ~03:45–03:48

The goal is to reduce abrupt information-density cliffs while preserving HARD pressure and musical structure.

## Validation requirement
This is a first rebalance candidate, not a final chart. Re-play Big Daddy HARD several times and compare telemetry against the five pre-rebalance runs before applying the same policy to other charts.
