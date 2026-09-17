# Changelog

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
