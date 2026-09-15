# Testing and evidence

Tested engine: Godot 4.7.2 Standard, Compatibility renderer. Start by importing all assets:

```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --script res://tests/test_combat.gd
godot --headless --path . --script res://tests/test_auto.gd
godot --headless --path . --script res://tests/test_art_fx.gd
```

Expected current results: combat failures=0 over 100 seeds; auto failures=0 over 100 seeds; art mesh/freeze/reset/expiry tests PASS. Engine errors must also be checked; a process exit code alone is insufficient.

For real windowed motion evidence (writes under Godot user data):

```sh
godot --path . res://tests/art_gallery.tscn -- --autoexit
```

The gallery is a diagnostic, not a gameplay acceptance test. Inspect full-size sequential frames for silhouette changes, anatomy, clipping and HUD occlusion. Numerical anchor agreement does not guarantee a natural animation.

## Manual acceptance

Run `godot --path . -- --autoexit` or the Windows package. Play from the title through a result. Exercise ordinary attacks, both creature ultimates, target selection, charge interruption, healing/shields, manual/auto and 1/2/3× speed. Press R to replay. Check that hits/energy are applied once and old effects disappear.

The pre-publication Windows session finished in 31 actions / 8 rounds: 9 manually selected player actions, then 13 auto-selected player actions plus enemy actions. Replay and speed switching were observed through native UI. This is an AI-operated real-window test, not a human certification or a fully manual playthrough. A later auto-off input was interrupted by user activity and was not counted as verified. No claim of formal audio listening approval is made.

## Packaging

`python tools/package_windows.py --godot path/to/Godot_windows.exe` builds a timestamped portable runtime+PCK zip using the installed Godot GUI executable. Use the GUI exe (without `_console`) so the package opens a game window. This prototype packaging route needs no export templates. Use matching standard export templates for a conventional release build.
