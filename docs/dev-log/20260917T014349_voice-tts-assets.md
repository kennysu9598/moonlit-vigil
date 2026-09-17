# 20260917T014349 — 六角色中文配音资产（edge-tts 产线）

- **作者/agent**：worker（glm-general 施工席，GLM-5.3-Flash），派工卡：语音资产生成（只产音频+文档，不改 .gd）
- **时间**：2026-09-17T01:43（本地）

## 做了什么

为《月灯守夜》六单位（绯羽/灾鸦/澄铃/灯魇/玄刃/荒祟）生成战斗语音 36 条（entrance/cast/hurt/death/victory/defeat × 6）。

- 合成：edge-tts 7.2.8（5 声线：Xiaoyi/Yunjian/Yunjian(荒祟)/Xiaoxiao/Yunyang/Yunxi），36/36 一次通过，0 重试。
- 荒祟变调：ffmpeg `asetrate=14880,aresample=48000,atempo=1.25`（降调 0.62 + 回速 1.25）。**修正记录**：卡面公式按 48 kHz 输入写（`asetrate=48000*0.62`），实测 edge-tts 输出 24 kHz，直接套用会反向升调；按卡内"参数可微调一次"授权改用 14880=24000×0.62。
- 归位：全部转 `assets/audio/voice/{unit}_{action}.ogg`（libvorbis q4 + loudnorm I=-12:TP=-1.5:LRA=11 + 48 kHz），36/36。

## 改动文件

- 新增 `assets/audio/voice/*.ogg` × 36（15.2 KB–26.8 KB）
- 新增 `assets/audio/voice/README.md`（生成方式+许可声明）
- 追加 `ASSET_LICENSES.md` 一行（voice/*.ogg = 本项目 edge-tts 合成，Project MIT grant）
- 新增 `docs/voice-design-20260917.md`（台词全文+声线+命令行+复现步骤+验证记录）

## 检查与证据

- 36/36 文件 >5 KB；ffprobe 全量 36 条均 `vorbis, 48000`。
- 荒祟抽查 `huangshuo_hurt.ogg` 2.62 s（原声 2.04 s × 1.29 ≈ 变调预期），无炸哑。
- 时长全表见 `docs/voice-design-20260917.md` 第四节。
- 台词 ≤12 字原创；卡内指定三条（绯羽 cast/荒祟 hurt/澄铃 defeat）原样采用。

## 未验证 / 剩余工作

- 音色主观听感（Kenny 或独立审查席人耳复听）未做——本卡为机械产线+机械验证。
- .gd 播放接线归下一卡；接线时按 `{unit}_{action}` 命名加载。
- 若对荒祟怪物感不满意，可微调变调参数一次并更新设计表（复现命令已留）。
