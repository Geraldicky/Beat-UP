# Beat UP! v17.4.21.4 — AppSessionState Parser + Manifest Cleanup

- Fixed the Godot parser error `Identifier "AppSessionState" not declared in the current scope`.
- `startup.gd` now resolves the process-lifetime session autoload through `/root/AppSessionState` at runtime instead of using a parser-time global identifier.
- Song Library, gameplay, and Chart Studio no longer reference the autoload identifier directly; they only set return-to-menu metadata and let `startup.gd` own splash state.
- Launch splash behavior remains: once per real application process, never again on scene returns during that run.
- Removed every `*manifest*.json` file from the project.
- The legacy FLAC song metadata file was migrated from `flac_library_14_manifest.json` to `flac_library_14_catalog.json`, and the two legacy generation scripts were updated accordingly.
- Build manifests are no longer generated for Beat UP! builds.
- No chart/gameplay balancing changes.
