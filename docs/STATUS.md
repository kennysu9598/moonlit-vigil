# Current status · v0.5.0

Standalone Godot 2D 3v3 battle with shared energy, statuses, healing/shields, boss charge/interrupt/enrage, victory/defeat and replay. Auto battle and 1×/2×/3× speed exist. v0.5.0 adds a full audio stack: an `AudioMgr` autoload with Music/SFX buses, an 8-slot SFX pool, 0.8 s BGM crossfade and bus-level mute; three-track BGM (battle/victory/defeat, ACE-Step generated, MIT-licensed model); 36 edge-tts voice lines (6 units × 6 situations, boss pitch-shifted) wired to entrance/cast/hurt/death/outcome moments. Game feel: anticipation poses, hit-stop, hurt shake/flash, idle breathing, floating damage popups and critical-hit bounce. Turn order is now speed-derived (data-driven) and the boss ramps its insertion speed at half health.

Enabled principal creature VFX: phoenix ultimate and dragon ultimate. Their artwork and local-motion frames were independently inspected. Other older principal VFX and geometric ground cracks are disabled for visual quality; the game's skill logic remains available. Environment color/clouds and impact response remain enabled.

Known limitations: few character poses; four-key-pose phoenix; single-sided painted dragon mesh; only one encounter; Chinese UI; Windows-only packaged validation; no formal human audio review（v0.5.0 已做机械响度对齐 + headless 逻辑验证，真人听审仍待）. The included headless tests prove mechanics, not aesthetics.

Automated headless tests (also run in CI via GitHub Actions): `tests/test_combat.gd`, `tests/test_auto.gd`, `tests/test_audio.gd`, `tests/test_voice.gd`.

This public checkout omits rejected 3D GLBs, old Unity/Godot 3D experiments, internal handoffs, personal paths and editor caches. They are not required to run the 2D game.
