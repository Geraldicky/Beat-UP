# v17.4.23.1 QA — True Seamless Menu Handoff

Static expectations:
- Project version is 17.4.23.1.
- `scene_transition_layer.tscn` contains no QuickTransitionVisual node.
- `beat_diamond_transition_visual.gd` is absent.
- `change_scene_quick()` resolves the destination while the source scene remains visible, then swaps without any transition overlay.
- `transition_action_quick()` performs no global overlay animation.
- Song launch artwork continuity remains available for gameplay entry.
- No `*manifest*.json` files exist.
- Built-in chart JSON files are unchanged from v17.4.23.
