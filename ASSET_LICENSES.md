# Assets, sources and licenses

The root MIT license covers project-authored code, documentation, procedural ambience and project-created AI-assisted artwork to the extent the project holds rights in them. It does not replace third-party licenses below. The assets do not include extracted Onmyoji game content. Onmyoji is a creative reference only; there is no affiliation or endorsement.

| Files | Creator / source | License |
|---|---|---|
| `assets/art/shrine.png`, `heroes.png`, `enemies_v2.png` | Project-created artwork using Codex's built-in image generation; environment and original character atlases | Project MIT grant |
| `assets/vfx_art/*.png` | Project-created phoenix, four-pose phoenix atlas and dragon, AI-generated and integrated as 2D animation | Project MIT grant |
| `assets/audio/moon_ambience_loop.wav` | Project-authored procedural sine-wave ambience, no external recordings | Project MIT grant |
| `assets/audio/ui_*.ogg` | [Kenney Interface Sounds](https://kenney.nl/assets/interface-sounds) | CC0-1.0 |
| `assets/audio/impact_heavy.ogg`, `impact_slash.ogg` | [Kenney RPG Audio](https://kenney.nl/assets/rpg-audio) (`Audio/metalPot3.ogg`, `Audio/knifeSlice2.ogg`), converted to Ogg Vorbis q4 (loudnorm, 48 kHz); 2026-09-17 v0.6.0 battle-SFX redo, previous arcade hits archived under `assets/audio/_archive-20260917/sfx-v1/` | CC0-1.0 |
| `assets/audio/_archive-20260917/battle_theme-emma.ogg` | [Determined Pursuit (epic orchestra loop)](https://opengameart.org/content/determined-pursuit-epic-orchestra-loop) — Emma_MA; converted WAV to Ogg Vorbis; archived 2026-09-17, replaced by the three-track BGM system below (file kept, not deleted) | CC0-1.0 |
| `assets/audio/battle_theme.ogg`, `win_theme.ogg`, `lose_theme.ogg` | 本项目 AI-music 产线，ACE-Step 1.5（MIT 模型）生成，项目原创（source masters: AI-music/30_Demo/2026-09-17-battle-bgm-v1 A-夜战-v1 / B-凯旋-v1 / C-败北-v1, 320k MP3, converted to Ogg Vorbis q5；2026-09-17 battle-bgm-v2: battle_theme 重制自 AI-music/30_Demo/20260917-battle-bgm-v2, 旧 v1 归档 `assets/audio/_archive-20260917/battle_theme-v1.ogg`） | Project MIT grant |
| `assets/audio/title_theme.ogg` | 本项目 AI-music 产线，ACE-Step 1.5（MIT 模型）生成，项目原创（source master: AI-music/30_Demo/20260917-battle-bgm-v2 title_900_nocot, 320k MP3, converted to Ogg Vorbis q5, 48 kHz; 尚未接入 main.gd） | Project MIT grant |
| `assets/audio/hit.ogg`, `heal.ogg`, `shield.ogg`, `impact_magic.ogg`, `cast_fire.ogg`, `cast_heal.ogg`, `cast_shield.ogg`, `cast_stun.ogg`, `charge_start.ogg`, `charge_interrupt.ogg`, `hit_poison.ogg` | [RPG Sound Pack](https://opengameart.org/content/rpg-sound-pack) — artisticdude; converted WAV to Ogg Vorbis q4 (loudnorm, 48 kHz); 2026-09-17 v0.6.0 battle-SFX redo (heavier low-end selection measured by ffmpeg lowpass volumedetect); member mapping in `assets/licenses/OGA-RPG-SoundPack-CC0.txt` | CC0-1.0 |
| `assets/audio/voice/*.ogg` | 本项目 edge-tts 合成（微软神经语音 zh-CN-* Neural 声线 + 原创台词），项目原创使用；生成方式与复现步骤见 `assets/audio/voice/README.md` 和 `docs/voice-design-20260917.md` | Project MIT grant |
| `assets/fonts/cjk.ttf` | [Noto Sans SC / Google Fonts](https://github.com/google/fonts/tree/main/ofl/notosanssc), unmodified variable font; font metadata retained | SIL OFL-1.1 |
| Godot runtime in Windows download only | [Godot Engine](https://godotengine.org/license/) | MIT + bundled dependency notices |

Full applicable notices are under `assets/licenses/`; file-level audio hashes and source archive filenames are in the three manifests there. Original license notices must travel with redistributed fonts/runtime. Generated artwork is not mislabelled as a third-party CC0 download.

AI generation is part of the disclosed creation process; these assets are not claimed to be hand-drawn, sculpted 3D models, or game-extracted reference material. No MiniMax video is used by the current build.
