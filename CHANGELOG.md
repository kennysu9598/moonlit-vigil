# Changelog

## v0.6.0 — 2026-09-17 · 十八招式与全维度听视觉

- 十八招专属特效：新增 `skill_vfx.gd` 招式库，六名单位（绯羽红刀 / 澄铃青白 / 玄刃蓝剑 / 灾鸦黑焰 / 灯魇灯火 / 荒祟紫黑）× 3 技能逐招设计：T1 0.60 秒、T2 0.86 秒、T3 大招 2.80 秒铺场（法阵读条 + 全屏闪 + 暗角 + 顿帧），敌方三招附带地面预警圈。
- 护盾可视化双通道：血条盾格按施盾者系配色，角色描边 glow shader 在盾零时自动隐藏，破盾触发爆散。
- Boss 蓄力预警三合一：地面法阵 + 暗角聚焦 + HUD 读条「可被打断」。
- 动作分层增强：普攻 / 中技 / 奥义预备幅 0.06 / 0.09 / 0.14 秒分层，加入方向性击退、dash 残影与死亡倒地常驻。
- 配音 v2：绯羽修正为男声（YunxiNeural），荒祟变调 0.62 → 0.78 修正可懂度，五男一女六声线互不撞声。
- 战斗音效 v2：12 件音效全部替换为厚重 RPG 音效（低频实测比选，替掉街机玩具感）。
- 音乐 v2：战斗曲重制为 112 BPM 太鼓 / 二胡 / 古筝（AI-music 产线 ACE-Step，-16 LUFS），新增标题曲 `title_theme` 并接线标题界面。
- 新增测试 `tests/test_vfx.gd`（18 招构造 + 护盾 + 预警），七项测试全绿。
- 录屏验收：75 秒实机录像 + 9 帧抽帧亲审通过。

## v0.5.0 — 2026-09-17 · 全线声音与战斗手感

- 音频重构：新增 `AudioMgr` 全局音频管理（autoload），Music / SFX 独立总线、8 路音效池、BGM 0.8 秒交叉淡入淡出、总线级静音。
- 三曲制 BGM：战斗、胜利、败北三首乐曲，由本项目 AI-music 产线（ACE-Step 1.5，MIT 模型）生成，替换原单首战斗曲（旧曲归档保留，CC0）。
- 36 条角色配音：6 名单位 × 6 种情境（登场 / 施法 / 受击 / 死亡 / 胜利 / 败北），edge-tts 中文神经语音合成，首领角色变调区分，已接入对应演出节点。
- 演出手感：出手预备动作、命中顿帧、受击抖动闪白、待机呼吸、伤害飘字弹出、暴击数字弹跳。
- 战斗深度：行动顺序按速度派生（数据驱动），首领半血进入狂暴并加速插队。
- CI：GitHub Actions 新增 headless 四项自动测试（战斗逻辑、自动策略、音频、配音）。
- 新增 7 枚 CC0 音效：吟唱、蓄力、打断等战斗提示音。

## v0.4.0 — first public prototype

- Complete single 3v3 encounter, shared energy, statuses, heals/shields, boss interruption, result and replay.
- Auto battle, 1×/2×/3× speed, CC0 orchestral battle music.
- High-detail phoenix atlas wingbeat and articulated painted dragon motion.
- VFX battlefield bounds and readable names/health bars.
- Lower-quality old effects disabled; additional hero/enemy principal VFX remain on the roadmap.
- Source, asset licenses, tests, contribution and AI handoff documentation published together.
