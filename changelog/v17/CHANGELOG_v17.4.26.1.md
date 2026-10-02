# Beat UP! v17.4.26.1 — Main Menu Polish Hotfix

- Fixed parser/runtime error in `_apply_main_menu_live_pulse()` caused by calling the non-existent `_get_main_menu_button()` helper.
- The call now correctly uses the existing `_main_menu_button_for_index()` helper.
- No UI behavior from v17.4.26 was otherwise changed.
