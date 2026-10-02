# Project Structure

Canonical layout after the 20 September 2026 project-hygiene pass.

Runtime source: `assets/`, `audio/`, `charts/`, `config/`, `music/`, `scenes/`, `scripts/`, plus root `main.tscn`.

Development source:
- `tests/` — current release gate and regression tests.
- `qa/` — current QA; historical QA under `qa/archive/v17/` and `qa/archive/v18/`.
- `tools/` — only current developer/build/analysis tooling.
- `changelog/` — grouped into `v16/`, `v17/`, `v18/`, and `design/`.
- `docs/` — current documentation.

Do not keep editor caches, Python caches, temporary UV environments, `.bak` files, generated builds, or per-patch backup trees in canonical source.

Built-in playable audio belongs in `music/imported/`; Main Menu music belongs in `music/menu/`.

Automatic chart generation remains developer-only. Player builds retain manual chart creation/editing, waveform tools, save/export, and playtest.
