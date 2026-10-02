# v17.4.22.1 QA — UI Cohesion Parser Hotfix

Static verification:
- `wave` is explicitly typed as `float`.
- `h` is explicitly typed as `float`.
- Waveform amplitude uses `absf(...)`.
- Runtime/project version strings updated to 17.4.22.1.
- All built-in chart JSON files are unchanged from v17.4.22.
- No `*manifest*.json` files are present.
- Godot runtime is unavailable in the build environment, so runtime parsing must still be confirmed in the editor.
