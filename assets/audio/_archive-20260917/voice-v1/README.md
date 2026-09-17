# voice/ — 角色中文配音资产（36 条）

《月灯守夜》六单位战斗语音：`{unit}_{action}.ogg`，48 kHz / Ogg Vorbis q4 / loudnorm I=-12 LUFS。

## 来源与许可

- 生成工具：[edge-tts](https://github.com/rany2/edge-tts) v7.2.8（MIT 许可的开源 CLI/Python 库），调用微软 Edge 在线 TTS 服务（Microsoft Neural Voices 微软神经语音）产出音频。
- 台词全部为本项目原创（和风阴阳师风短句，详见 `docs/voice-design-20260917.md`）；合成音频按仓库根 MIT 许可随项目原创使用与分发。
- 未提取、未使用任何第三方游戏（含《阴阳师》）的音频素材。
- 生成日期：2026-09-17。

## 声线表

| unit | 角色 | 定位 | edge-tts 声线 |
|---|---|---|---|
| feiyu | 绯羽 | 玩家·凤羽弓手·年轻女 | zh-CN-XiaoyiNeural |
| zaiya | 灾鸦 | 敌方·黑焰咒师·阴沉男 | zh-CN-YunjianNeural |
| chengling | 澄铃 | 玩家·巫女治愈·温柔女 | zh-CN-XiaoxiaoNeural |
| dengyan | 灯魇 | 敌方·提灯妖·沉稳怪男 | zh-CN-YunyangNeural |
| xuanren | 玄刃 | 玩家·冷峻剑士·低冷男 | zh-CN-YunxiNeural |
| huangshuo | 荒祟 | Boss·荒神·怪物声 | zh-CN-YunjianNeural + ffmpeg 降调变调 |

action：`entrance` / `cast` / `hurt` / `death` / `victory` / `defeat`。

## 生成与复现步骤

1. 环境确认：`pip show edge-tts`（本机 7.2.8）；声线核实：`edge-tts --list-voices | Select-String "Xiaoyi|Yunjian|Xiaoxiao|Yunyang|Yunxi"`。
2. 合成 MP3（24 kHz 单声道，edge-tts 默认输出）：

   ```
   edge-tts --voice zh-CN-XiaoyiNeural --text "凤羽，贯穿！" --write-media feiyu_cast.mp3
   ```

   批量生成脚本（edge_tts 7.2.8 Python API，与 CLI 同一引擎同一产出，含每条重试 ≤2）：
   `C:\Users\Desktop\AppData\Local\Temp\opencode\voice-tmp\gen_voices.py`
3. 荒祟 6 条降调变调。注意：edge-tts 实际输出 **24 kHz**（非 48 kHz），卡面公式 `asetrate=48000*0.62` 直接套用会反向升调，已按实际采样率修正为 `14880 = 24000 × 0.62`：

   ```
   ffmpeg -i huangshuo_cast.mp3 -af "asetrate=14880,aresample=48000,atempo=1.25" -q:a 4 huangshuo_cast_pitched.mp3
   ```

   （降调 0.62 + 回速 1.25，净速 0.775，怪物低吼感；时长约为原声 1.29 倍）
4. 全部转 ogg 并响度归一（人声响度 I=-12，比音效轨略响）：

   ```
   ffmpeg -i in.mp3 -c:a libvorbis -q:a 4 -af "loudnorm=I=-12:TP=-1.5:LRA=11" -ar 48000 {unit}_{action}.ogg
   ```

## 验证记录（2026-09-17）

- 36/36 文件在位，全部 >5 KB（15.2 KB–26.8 KB）。
- ffprobe 全量核对：36/36 均为 `vorbis, 48000`。
- 荒祟抽查 `huangshuo_hurt.ogg` 2.62 s（原声 2.04 s × 1.29），变调后时长合理、无炸哑。
- 代码接线（.gd 播放逻辑）不在本批产物范围，由后续任务完成。
