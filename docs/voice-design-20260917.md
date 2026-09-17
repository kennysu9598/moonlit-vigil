# 《月灯守夜》六角色中文配音设计表（2026-09-17）

> 产线：edge-tts 7.2.8（MIT 工具）+ 微软在线神经语音 → ffmpeg loudnorm/转码 → `assets/audio/voice/*.ogg`（36 文件）。
> 本文档为配音资产的可复现设计记录；播放接线（.gd）由后续代码任务完成。

## 一、角色声线表（5 个声线，经 `edge-tts --list-voices` 核实全部存在）

| unit | 角色 | 定位 | edge-tts 声线 | 声线特质（官方标注） |
|---|---|---|---|---|
| feiyu | 绯羽 | 玩家·凤羽弓手·年轻女 | zh-CN-XiaoyiNeural | Female / Lively |
| zaiya | 灾鸦 | 敌方·黑焰咒师·阴沉男 | zh-CN-YunjianNeural | Male / Passion |
| chengling | 澄铃 | 玩家·巫女治愈·温柔女 | zh-CN-XiaoxiaoNeural | Female / Warm |
| dengyan | 灯魇 | 敌方·提灯妖·沉稳怪男 | zh-CN-YunyangNeural | Male / Professional, Reliable |
| xuanren | 玄刃 | 玩家·冷峻剑士·低冷男 | zh-CN-YunxiNeural | Male / Lively, Sunshine（低语速短句呈现冷感） |
| huangshuo | 荒祟 | Boss·荒神·怪物声 | zh-CN-YunjianNeural + ffmpeg 降调 0.62 | 同灾鸦声线，靠变调区分 |

## 二、台词全文（每人 6 条，≤12 字，和风阴阳师风；原创）

| action | 绯羽 feiyu | 灾鸦 zaiya | 澄铃 chengling | 灯魇 dengyan | 玄刃 xuanren | 荒祟 huangshuo |
|---|---|---|---|---|---|---|
| entrance | 凤羽张弦，随我上阵！ | 黑焰苏醒，祭品何在？ | 神乐响起，愿佑诸君。 | 灯亮之处，皆是归途。 | 刀已出鞘，废话免了。 | 咕…嗷！荒野…苏醒！ |
| cast | 凤羽，贯穿！ | 黑炎，吞尽！ | 御灵，守护！ | 灯火，焚身！ | 斩鬼，一闪！ | 嗷嗷…荒威…灭世！ |
| hurt | 呃…箭袋还在！ | 哼…不痛不痒。 | 呀…铃铛掉了… | 嗯…灯影微晃。 | 切…失手了。 | 咕…嗷！ |
| death | 弓…落了… | 咒…反噬了… | 神乐…谢幕了… | 灯芯…燃尽了… | 败者…无话… | 嗷…呜…荒…崩… |
| victory | 一箭封喉，漂亮！ | 灰烬，是最好的祭品。 | 大家都平安，太好了。 | 此灯，长明不灭。 | 不过如此。 | 嗷嗷嗷！皆…为尘！ |
| defeat | 羽翼…折断了… | 黑焰…终究熄灭… | 灯火…不能熄… | 光…沉入夜色… | 刀…卷刃了… | 呜…荒…归寂… |

注：绯羽 cast、荒祟 hurt、澄铃 defeat 三条为派工卡给定的指定台词，原样采用。

## 三、生成命令与管线

### 1. 环境核实

```
pip show edge-tts                # 本机 7.2.8
edge-tts --list-voices | Select-String "Xiaoyi|Yunjian|Xiaoxiao|Yunyang|Yunxi"
```

### 2. 单条合成（CLI 等效命令；批量用同引擎 Python API，脚本 `C:\Users\Desktop\AppData\Local\Temp\opencode\voice-tmp\gen_voices.py`，每条失败重试 ≤2、并发 4）

```
edge-tts --voice zh-CN-XiaoyiNeural --text "凤羽，贯穿！" --write-media feiyu_cast.mp3
```

edge-tts 输出规格：MP3，24 000 Hz 单声道（实测 ffprobe 确认）。

### 3. 荒祟变调（仅 huangshuo 6 条）

**采样率修正记录**：派工卡原公式 `asetrate=48000*0.62` 按 48 kHz 输入设计；实测输入为 24 kHz，直接套用会反向升调 1.24×。按卡内"参数可微调一次"授权修正为：

```
ffmpeg -i huangshuo_cast.mp3 -af "asetrate=14880,aresample=48000,atempo=1.25" -q:a 4 huangshuo_cast_pitched.mp3
```

等效于降调 0.62（14880 = 24000 × 0.62）→ 重采样 48 kHz → 回速 1.25；净速 0.775，低沉怪物吼声，时长 ×1.29。

### 4. 归位转码（全部 36 条 → `assets/audio/voice/{unit}_{action}.ogg`）

```
ffmpeg -i in.mp3 -c:a libvorbis -q:a 4 -af "loudnorm=I=-12:TP=-1.5:LRA=11" -ar 48000 {unit}_{action}.ogg
```

响度 I=-12 LUFS（人声比既有音效轨略响），真峰值 -1.5 dBTP，48 kHz。

## 四、验证记录（2026-09-17 实测）

- **数量/大小**：36/36 文件在位，全部 >5 KB（15 213 B – 26 763 B）。
- **规格**：ffprobe 全量 36 条均 `vorbis, 48000`。
- **时长清单（秒）**：

| unit | entrance | cast | hurt | death | victory | defeat |
|---|---|---|---|---|---|---|
| feiyu | 2.81 | 2.23 | 2.21 | 1.97 | 2.57 | 2.42 |
| zaiya | 3.22 | 2.30 | 2.52 | 2.33 | 2.95 | 2.71 |
| chengling | 2.81 | 1.92 | 2.09 | 2.18 | 2.57 | 2.14 |
| dengyan | 2.54 | 1.87 | 1.94 | 1.99 | 2.09 | 2.06 |
| xuanren | 3.19 | 2.64 | 2.30 | 2.54 | 1.87 | 2.30 |
| huangshuo | 5.30 | 3.83 | 2.62 | 4.30 | 4.60 | 3.33 |

- **荒祟抽查**：`huangshuo_hurt.ogg` 2.62 s（原声 2.04 s × 1.29 ≈ 变调预期），时长合理；loudnorm 后无削波（TP=-1.5 上限）。
- **失败统计**：合成 0 条失败（36/36 一次通过，无触发重试）；转码 0 条失败。
- 许可声明：`assets/audio/voice/README.md` + 根目录 `ASSET_LICENSES.md`（voice 行）。

## 五、后续（不在本批范围）

- .gd 代码接线：按 `{unit}_{action}` 命名加载播放（登场/施法/受击/死亡/胜败触发点）。
- 可选调优：荒祟变调若需更哑可再叠 `asetempo`/EQ；澄铃可加 `--rate=-8%` 更柔（需重新生成并更新本表）。
