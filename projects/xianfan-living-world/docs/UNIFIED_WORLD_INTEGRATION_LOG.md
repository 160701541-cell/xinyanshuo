# 《仙凡·苍岚》世界观整合日志

## 2026-10-24｜XIANFAN-CANON-001
**请求**：基于公开仓库整合《仙凡共生》《苍岚·人生世界》并参考《凡人修仙传》结构，为独立文字AI战役提供统一世界观和可追溯规则。

**已检查的真实代码/文档**：
- 仙凡独立分支的 README.md、web/core.js、web/overworld.js、web/overworld-ui.js、web/worldmap.js、web/cultivation.js、web/dao.js、web/karma.js、web/engine.js。
- 苍岚 main 的 docs/CULTIVATION_GAMEPLAY_SYSTEM_V1.md、docs/REV207_LIVING_WORLD_50000KM2_MECHANICS_20261018.md、docs/DEVELOPMENT_EXECUTION_RULES.md、docs/GAME_ENGINEERING_MASTER.md。
- 非官方《凡人修仙传》境界整理和原著章节解说（来源链接见统一世界观第15节），只引用抽象修炼结构，不复制受保护原文。

**本次真实输出**：
1. docs/UNIFIED_WORLD_CANON_V1.md——世界观、地理锚点、凡俗国家、修真社会、武道、妖兽、境界、资源物品树、NPC、剧情记忆、初始战役快照与冲突优先级。
2. data/unified_world_rules_v1.json——机读的来源边界、人口口径、地理锚点、境界、家族开场、兼容缺口及状态标记。
3. tests/unified_world_canon.test.mjs——参考配置的静态完整性与边界回归检查。
4. README.md——增加上述文档索引入口，声明SPEC_ONLY。

**已识别但未改代码问题**：
- 13,680仙凡本地人口 vs 5,000苍岚Godot人口不得相加。
- 灵根抽样实现不一致：web/core.js 与 web/cultivation.js。
- 国家标记与ID别名未全量统一：web/overworld.js 与 web/dao.js。
- web/karma.js直接生成战利品违背库存守恒要求。
- NPC全量自主日程、灵界/仙界/地府可玩图、人物跨项目存档不存在；本次不虚报为完成。

**验证/发布状态**：JSON结构、唯一地点ID、境界次序、隐藏灵根、存档不混用等为可由静态测试验证的设计基线；未修改Android客户端源码、NPC模拟器、Godot主线，未构建APK、未做手机实机测试；**没有发布游戏更新**。

**下一步工程（非已完成）**：先修复人物/灵根根性统一与族谱保密；迁移道德/国家别名；把真实物品ID/所有权库存接入战斗掉落；再对接交互剧情结算，逐项编写迁移测试和实机验收。

## 2026-10-24｜GM-QA-001 持续自我迭代制度

**触发**：玩家要求主持人每轮发现并改善问题，且十轮压缩关键剧情同时复盘公平性与逻辑。

**实际改动**：新增 `docs/GM_CONTINUOUS_IMPROVEMENT_V1.md`（逐轮检查、每十轮复盘、不得私改过去已结算事件），`tools/gm_quality_gate.mjs`（8类证据检查），`tests/gm_quality_gate.test.mjs`（回归用例）；更新 `docs/GM_GAME_PROTOCOL.md` 和 `tools/restore_campaign.mjs`：运行checkpoint指令时同时安排GM评审。

**实际验证**：从公开分支读取质量检查函数，在独立JS执行环境中执行9个快速案例，合理动作、金钱来源/支出、倒退时间、无限追击、主角特权、NPC全知、旁白越界与缺失证据检查均符合预期。**尚未执行仓库完整Node自动测试，未生成十轮实际评审**（战役仍为0回合），不能称全部通过。

**运行边界**：无离线常驻GM自动运行，不通过仓库公开隐藏剧情。对规则平衡改动需事先版本化并保留原始存档；不对玩家自动创造事件。
