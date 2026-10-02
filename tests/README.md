# Tests

`release_gate.py` is the authoritative current-build gate.

Versioned tests outside that gate are regression/history checks and may assert older behavior.

Run locally with Godot 4.7:

```powershell
python tests/release_gate.py --godot "C:\path\to\Godot_v4.7-stable_win64.exe"
```
