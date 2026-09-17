# voice/ — 角色中文配音资产（36 条 · v2 重制 2026-09-17）

《月灯守夜》六单位战斗语音：`{unit}_{action}.ogg`，48 kHz / Ogg Vorbis q4 / loudnorm I=-12 LUFS。
v1 旧版 36 条已整目录归档：`../_archive-20260917/voice-v1/`；v2 同名覆盖，.gd 接线零改动。

## 来源与许可

- 生成工具：[edge-tts](https://github.com/rany2/edge-tts) v7.2.8（MIT 许可的开源 CLI/Python 库），调用微软 Edge 在线 TTS 服务（Microsoft Neural Voices 微软神经语音）产出音频。
- 台词全部为本项目原创（和风阴阳师风短句，详见 `docs/voice-design-20260917.md`）；合成音频按仓库根 MIT 许可随项目原创使用与分发。
- 未提取、未使用任何第三方游戏（含《阴阳师》）的音频素材。
- v1 生成：2026-09-17 01:41；v2 重制：2026-09-17 02:37。

## 声线表（v2 · 五男一女，六人不撞声）

| unit | 角色 | 定位 | edge-tts 声线 | 参数 |
|---|---|---|---|---|
| feiyu | 绯羽 | 玩家·男刀客·热血 | zh-CN-YunxiNeural | `--rate=+8% --pitch=+5Hz` |
| chengling | 澄铃 | 玩家·巫女治愈·温柔女 | zh-CN-XiaoxiaoNeural | 默认 |
| xuanren | 玄刃 | 玩家·冷峻剑士·低冷男 | zh-CN-YunjianNeural | `--rate=-5%` |
| zaiya | 灾鸦 | 敌方·黑焰咒师·阴冷男 | zh-CN-YunxiNeural | `--rate=-12% --pitch=-15Hz` |
| dengyan | 灯魇 | 敌方·提灯妖·沉稳怪男 | zh-CN-YunyangNeural | `--pitch=-10Hz` |
| huangshuo | 荒祟 | Boss·荒神·怪物声 | zh-CN-YunjianNeural | `--rate=-10%` + ffmpeg 降调 0.78 |

action：`entrance` / `cast` / `hurt` / `death` / `victory` / `defeat`。

> v2 勘误：绯羽为**男性刀客**（v1 误配女声 XiaoyiNeural）；荒祟变调由 0.62 减轻为 0.78（v1 听不清）。

## 生成与复现步骤（v2）

1. 环境确认：`pip show edge-tts`（本机 7.2.8）；声线核实：`edge-tts --list-voices | Select-String "Xiaoxiao|Yunjian|Yunyang|Yunxi"`。
2. 合成 MP3（24 kHz 单声道，edge-tts 默认输出）：

   ```
   edge-tts --voice zh-CN-YunxiNeural --rate=+8% --pitch=+5Hz --text "凤羽，贯穿！" --write-media feiyu_cast.mp3
   ```

   批量生成脚本（edge_tts 7.2.8 Python API，与 CLI 同一引擎同一产出，含每条重试 ≤2）：
   `C:\Users\Desktop\AppData\Local\Temp\opencode\voice-tmp-v2\gen_voices_v2.py`
3. 荒祟 6 条变调（v2 修正：v1 的 0.62 降调过重听不清，改为 **0.78**，低沉但字字可懂；注意 edge-tts 输出为 **24 kHz**，asetrate 按输入采样率折算）：

   ```
   asetrate=18720 (=24000×0.78) → aresample=48000 → atempo=1.08
   ```

   （净速 0.8424，时长 ×1.187）
4. 全部转 ogg 并响度归一（人声响度 I=-12，比音效轨略响）；荒祟变调并入同一条 -af 链：

   ```
   ffmpeg -i in.mp3 -c:a libvorbis -q:a 4 -af "loudnorm=I=-12:TP=-1.5:LRA=11" -ar 48000 {unit}_{action}.ogg
   ffmpeg -i huangshuo_x.mp3 -c:a libvorbis -q:a 4 -af "asetrate=18720,aresample=48000,atempo=1.08,loudnorm=I=-12:TP=-1.5:LRA=11" -ar 48000 huangshuo_x.ogg
   ```

## 验证记录（v2 · 2026-09-17 02:37）

- 36/36 文件同名覆盖重建，ffprobe 全量 `vorbis, 48000`，时长全部 >1.5 s（最短 1.87 s）。
- 荒祟重点抽查：`huangshuo_hurt.ogg` 2.66 s、`huangshuo_cast.ogg` 3.90 s（均在 2–4 s 清晰窗口）。
- 抽查 8 条：feiyu_entrance 2.808 / feiyu_cast 2.328 / chengling_cast 1.920 / xuanren_cast 2.448 / zaiya_cast 2.592 / dengyan_cast 1.872 / huangshuo_hurt 2.659 / huangshuo_cast 3.900。
- 合成 36/36 一次通过；转码 36/36 零失败。完整时长表见 `docs/voice-design-20260917.md` 第四节。
- 代码接线（.gd 播放逻辑）零改动：文件名不变，同名覆盖即生效。
