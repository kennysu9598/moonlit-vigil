# 《月灯守夜》六角色中文配音设计表（2026-09-17 · v2 重制）

> 产线：edge-tts 7.2.8（MIT 工具）+ 微软在线神经语音 → ffmpeg 变调/loudnorm/转码 → `assets/audio/voice/*.ogg`（36 文件）。
> 本文档为配音资产的可复现设计记录。**v2 重制不改文件名、不改 .gd 接线**——36 条 `{unit}_{action}.ogg` 同名覆盖，此前 voice-wiring 接线零改动直接生效。
> v1 旧版 36 条已整目录归档：`assets/audio/_archive-20260917/voice-v1/`。

## 〇、v2 变更记录（2026-09-17 重制，Kenny 三条反馈 → 三项修正）

1. **绯羽勘误（男声）**：绯羽是**男性刀客（红衣白发）**。v1 设计表误标"凤羽弓手·年轻女"并配女声 zh-CN-XiaoyiNeural。v2 改配男声 zh-CN-YunxiNeural（`--rate=+8% --pitch=+5Hz`，热血少侠感）。台词按派工卡沿用原文不改。
2. **荒祟变调修正（v1 听不清）**：v1 降调 0.62 + atempo 1.25 变调过重，字音糊成吼声。v2 减轻为**降调 0.78 + atempo 1.08**，低沉怪物声但字字可懂。
3. **男女声分明（六人不撞声）**：五男（绯羽/玄刃/灾鸦/灯魇/荒祟）+ 一女（澄铃）。v1 五声线混用导致玄刃/灾鸦同名异声线混乱、绯羽性别错配；v2 重新分配。

v1 → v2 声线对照：

| unit | v1 声线 | v2 声线 |
|---|---|---|
| feiyu | zh-CN-XiaoyiNeural（女声，误配） | zh-CN-YunxiNeural +8% / +5Hz（男声） |
| chengling | zh-CN-XiaoxiaoNeural | 不变（默认参数） |
| xuanren | zh-CN-YunxiNeural | zh-CN-YunjianNeural -5% |
| zaiya | zh-CN-YunjianNeural | zh-CN-YunxiNeural -12% / -15Hz |
| dengyan | zh-CN-YunyangNeural | 不变（新增 --pitch=-10Hz） |
| huangshuo | zh-CN-YunjianNeural + 降调 0.62 | zh-CN-YunjianNeural -10% + 降调 0.78 |

（v1 时长表与抽查记录随 v1 产物归档，不在此保留。）

## 一、角色声线表（v2 · 六人六声线，经 `edge-tts --list-voices` 核实全部存在）

| unit | 角色 | 定位 | edge-tts 声线 | 参数 | 声线特质（官方标注） |
|---|---|---|---|---|---|
| feiyu | 绯羽 | 玩家·男刀客·热血 | zh-CN-YunxiNeural | `--rate=+8% --pitch=+5Hz` | Male / Lively, Sunshine |
| chengling | 澄铃 | 玩家·巫女治愈·温柔女 | zh-CN-XiaoxiaoNeural | 默认 | Female / Warm |
| xuanren | 玄刃 | 玩家·冷峻剑士·低冷男 | zh-CN-YunjianNeural | `--rate=-5%` | Male / Passion |
| zaiya | 灾鸦 | 敌方·黑焰咒师·阴冷男 | zh-CN-YunxiNeural | `--rate=-12% --pitch=-15Hz` | Male / Lively, Sunshine（压速+降调呈阴冷） |
| dengyan | 灯魇 | 敌方·提灯妖·沉稳怪男 | zh-CN-YunyangNeural | `--pitch=-10Hz` | Male / Professional, Reliable |
| huangshuo | 荒祟 | Boss·荒神·怪物声 | zh-CN-YunjianNeural | `--rate=-10%` + ffmpeg 降调 0.78 | 同玄刃声线，靠 -10% 语速与 0.78 变调区分 |

## 二、台词全文（每人 6 条，≤12 字，和风阴阳师风；原创；v2 沿用不改）

| action | 绯羽 feiyu | 灾鸦 zaiya | 澄铃 chengling | 灯魇 dengyan | 玄刃 xuanren | 荒祟 huangshuo |
|---|---|---|---|---|---|---|
| entrance | 凤羽张弦，随我上阵！ | 黑焰苏醒，祭品何在？ | 神乐响起，愿佑诸君。 | 灯亮之处，皆是归途。 | 刀已出鞘，废话免了。 | 咕…嗷！荒野…苏醒！ |
| cast | 凤羽，贯穿！ | 黑炎，吞尽！ | 御灵，守护！ | 灯火，焚身！ | 斩鬼，一闪！ | 嗷嗷…荒威…灭世！ |
| hurt | 呃…箭袋还在！ | 哼…不痛不痒。 | 呀…铃铛掉了… | 嗯…灯影微晃。 | 切…失手了。 | 咕…嗷！ |
| death | 弓…落了… | 咒…反噬了… | 神乐…谢幕了… | 灯芯…燃尽了… | 败者…无话… | 嗷…呜…荒…崩… |
| victory | 一箭封喉，漂亮！ | 灰烬，是最好的祭品。 | 大家都平安，太好了。 | 此灯，长明不灭。 | 不过如此。 | 嗷嗷嗷！皆…为尘！ |
| defeat | 羽翼…折断了… | 黑焰…终究熄灭… | 灯火…不能熄… | 光…沉入夜色… | 刀…卷刃了… | 呜…荒…归寂… |

注：绯羽 cast、荒祟 hurt、澄铃 defeat 三条为派工卡给定的指定台词，原样采用。绯羽台词中"凤羽张弦""一箭封喉"为 v1 文案遗留意象，v2 按卡**只改声线不改文案**。

## 三、生成命令与管线（v2）

### 1. 环境核实

```
pip show edge-tts                # 本机 7.2.8
edge-tts --list-voices | Select-String "Xiaoxiao|Yunjian|Yunyang|Yunxi"
```

### 2. 单条合成（CLI 等效命令；批量用同引擎 Python API，脚本 `C:\Users\Desktop\AppData\Local\Temp\opencode\voice-tmp-v2\gen_voices_v2.py`，每条失败重试 ≤2、并发 4）

```
edge-tts --voice zh-CN-YunxiNeural --rate=+8% --pitch=+5Hz --text "凤羽，贯穿！" --write-media feiyu_cast.mp3
```

edge-tts 输出规格：MP3，24 000 Hz 单声道（实测 ffprobe 确认）。

### 3. 荒祟变调（v2 修正版；仅 huangshuo 6 条，v2 已并入第 4 步转码链）

**v2 公式（卡内写死）**：`asetrate=18720`（= 24000 × 0.78）→ `aresample=48000` → `atempo=1.08`。

- 净速 0.78 × 1.08 = 0.8424，时长 ×1.187。
- **修正记录**：v1 用 0.62 + atempo 1.25（净速 0.775，时长 ×1.29），降调过重导致台词糊成吼声听不清；v2 减轻为 0.78，实测 hurt/cast 两条均落 2–4 s 清晰窗口。

### 4. 归位转码（全部 36 条 → `assets/audio/voice/{unit}_{action}.ogg`）

普通 30 条：

```
ffmpeg -i in.mp3 -c:a libvorbis -q:a 4 -af "loudnorm=I=-12:TP=-1.5:LRA=11" -ar 48000 {unit}_{action}.ogg
```

荒祟 6 条（变调并入同一条 -af 链）：

```
ffmpeg -i huangshuo_{action}.mp3 -c:a libvorbis -q:a 4 -af "asetrate=18720,aresample=48000,atempo=1.08,loudnorm=I=-12:TP=-1.5:LRA=11" -ar 48000 huangshuo_{action}.ogg
```

响度 I=-12 LUFS（人声比既有音效轨略响），真峰值 -1.5 dBTP，48 kHz。

## 四、验证记录（v2 · 2026-09-17 02:37 实测）

- **数量/规格**：36/36 文件同名覆盖重建，ffprobe 全量 `vorbis, 48000`；时长全部 >1.5 s（最短 1.87 s）。
- **时长清单（秒，v2 实测）**：

| unit | entrance | cast | hurt | death | victory | defeat |
|---|---|---|---|---|---|---|
| feiyu | 2.81 | 2.33 | 2.57 | 1.90 | 2.47 | 2.50 |
| chengling | 2.81 | 1.92 | 2.09 | 2.18 | 2.57 | 2.14 |
| xuanren | 3.12 | 2.45 | 2.47 | 2.40 | 1.87 | 2.40 |
| zaiya | 3.39 | 2.59 | 2.93 | 2.64 | 3.43 | 3.39 |
| dengyan | 2.54 | 1.87 | 1.94 | 1.99 | 2.09 | 2.06 |
| huangshuo | 5.40 | 3.90 | 2.66 | 4.40 | 4.70 | 3.40 |

- **荒祟重点抽查（2–4 s 清晰窗口）**：`huangshuo_hurt.ogg` 2.66 s ✓、`huangshuo_cast.ogg` 3.90 s ✓。变调后时长 = 原声 ×1.1（rate -10%）×1.187（0.78 降调+1.08 回速），实测与公式吻合（hurt 实测 2.66 s ≈ 2.04×1.1×1.187 = 2.66 s）。
- **抽查 8 条 ffprobe 行**：feiyu_entrance 2.808 / feiyu_cast 2.328 / chengling_cast 1.920 / xuanren_cast 2.448 / zaiya_cast 2.592 / dengyan_cast 1.872 / huangshuo_hurt 2.659 / huangshuo_cast 3.900（均 vorbis, 48000）。
- **失败统计**：合成 36/36 一次通过（0 条触发重试）；转码 36/36 零失败。
- 许可声明不变：`assets/audio/voice/README.md` + 根目录 `ASSET_LICENSES.md`（voice 行）。
- 真人听感终审（绯羽男声辨识、荒祟清晰度）留验收段 L2/L3 完成，本节仅记录机械指标。

## 五、后续（不在本批范围）

- .gd 接线零改动（文件名不变，同名覆盖即生效）。
- 可选调优：荒祟如需更哑可再降变调或叠 EQ；澄铃可加 `--rate=-8%` 更柔——均需重新生成并更新本表。
