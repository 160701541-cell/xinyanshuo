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

## 2026-10-24｜GM-NUM-001 数值结算P0门禁

**用户要求**：所有属性、货币、交易、人口、战斗等数量必须真正由代码计算，禁止GM凭感觉随口添加。

**完成仓库提交**：`docs/GM_NUMERIC_AUTHORITY_V1.md`，`tools/numeric_accounts.mjs`，`tools/numeric_engine.mjs`，`tools/turn_cli.mjs`，`tests/numeric_engine.test.mjs`。GM-L0已增加数值最高优先级。存档恢复代码改为旧出生分段只在初始重建，真实回合状态优先并校验事件哈希。

**本地执行记录**：使用原始存档`/mnt/data/campaign_verify/game_state.json`，其状态SHA256是 `52eab54f38ed24b476c8495e1343bec82f6ead1bf8414a39c1cebd4cb0eb6ca5`，两条原始事件。等效结算源码的Node测试10/10通过，包含双向守恒、授权、时钟、恢复精力、非法参数、未知机制阻断、原始事件校验和不篡改状态。**仓库完整测试、CLI正式多文件提交、Android原型实测仍未运行验收**，不得报告全部完成。

**已知未实现**：经济账户建档NPC决策全链、购物与物价、经验成长、战斗伤害、行走地图、妖兽、跨日人口和资源模拟。没有公式时明确返回RULE_NOT_IMPLEMENTED/DAY_SIM_NOT_IMPLEMENTED，不生成具体数值。**本次未进行玩家行动，存档仍0回合，08:00**。

### GM-NUM-001 增补：只读可信HUD

新增 `tools/numeric_hud.mjs` 与 `tests/numeric_hud.test.mjs`。HUD在展示前复核完整事件哈希链和最终状态哈希，没有存档字段的力量/灵力等返回null（界面显示未建档），禁止AI随机补数。本地Node复现初始两条事件并运行了2个HUD测试，通过；正式仓库CI、完整游戏远端结算未验证。

## 2026-10-24｜HUNT-001 小兽捕猎/陷阱可行性审核

**用户询问**：在第一世石桥村能否捕猎或者制作陷阱。

**已核实**：第一世玩家实际背包仅粗布衣×1、布鞋×1，无工具与陷阱用材料，当前地图无已登记的野生动物实体或猎场。独立原型`web/content/beasts.js`虽有兽种模板，不等于本战役确认有动物。

**已提交**：新增`data/hunting_rules_v1.json`（明确陷阱材料、时间/精力规则和当前世界缺口）、`tools/hunting_engine.mjs`（材料可行性、真实库存扣除、精力消耗、工具入账）、`tests/hunting_engine.test.mjs`（6组回归场景）；数值内核`tools/numeric_engine.mjs`注册`craft_trap`，版本升至`number-authority-1.1.0`。

**现有结论**：图纸允许未来制作，但当前缺材料，`MATERIALS_MISSING`阻断；捕猎、陷阱部署与野生动物出没暂缺生态实体规则，不允许GM描述捕获成功。通过V8独立运行已提交模块的11个快速验证，仍待完整Node运行验证。

**存档**：本轮仅查询+系统开发；游戏仍08:00，玩家行动0回合、EV000002，不写任何玩家数值。

## 2026-10-24｜EV000003 完成首轮狩猎准备

真实执行`forest_trap_turn.mjs`已提交：调用妹妹并经确定性NPC决策获得同意；世界种子生成村外生态节点；两人采集带来源材料并扣节点库存；制作中间材料与简易小兽绳套；经足迹检定，在非人行路线部署`TRAP-SHIQIAO-0001`。第一世时钟08:00→10:19，精力100→80，钱12文不变，家庭账本不变。陷阱尚无捕获事件（抓获机制待后续开发），不得把捕猎准备冒充获得猎物。新增事件`EV000003`、实时`game_state.json`、NPC公开记忆和战役索引均已推送。再次读取仓库交叉核对时间、金额、库存、事件关系、根性保密、陷阱真实持久化等10项结果均一致。注意：独立快测和静态检查不等于完整Node端对移动、世界经济和陷阱触发的验收。

## 2026-10-24｜EV000004 寻药／NPC人生记录

**实际完成**：用户先询问妹妹性别、要求所有NPC持久人格、再提出寻找能卖钱的普通药草与灵植。权威存档确认孙成明（CFNPC00003）女，16岁，关系手足，现同玩家在村外。

为所有NPC通用的`tools/npc_identity.mjs`新增固定ID性别核对、出生档信息防漂移、世界种子确定性的六项基础气质参数、逐事件人生履历与公众可观察人格；`campaigns/first-life/npc_registry.json`真实保存已出场3人的档案，孙成明第1、2轮经历均以EV000003/EV000004作来源。通用机制见`systems/npc-life/README.md`。

新增`data/medicinal_foraging_rules_v1.json`、`tools/medicinal_foraging_turn.mjs`及`tests/medicinal_foraging_npc.test.mjs`；普通车前草、艾草等是按已有区域种子与固定生境决定存量（不按玩家意愿保证出现），未知根茎不擅采，稀有灵植并非到处都有。实际计算此次采得**鲜车前草×1**，真实扣自然节点1，时间10:19→11:14，精力80→73，个人铜钱12文不变，未询价也未出售。上轮陷阱不被自动判定成功。

完整新权威`game_state.json`、`events.jsonl`追加的EV000004、`npc_registry.json`、`story_memory_public.json`、`campaign_index.json`均已实际上传到仙凡独立分支。事先使用确定性SHA256计算预览和全事件链核对匹配，后续对这两个哈希进行交叉引用。旧出生数据、灵根承诺未改。

**质量范围**：本轮JS代码已做确定性状态计算及事件链校验；Node完整测试工作流结果尚未确认，商铺账户/具体收购报价及完整灵植识别与跨日生态仍未实现，不能宣称通过。

## 2026-10-25｜EV000010 河岸生境、放置鱼笼和后续捕获算法

根据用户确认，完成河岸参数表`data/freshwater_habitat_v1.json`、`tools/freshwater_fishing.mjs`和自动测试`tests/freshwater_fishing.test.mjs`。直接调用实际仓库源码结算第八回合，生成带水域归属、安全检查、稳定种子鱼群的世界实体，扣背包鱼笼一只、消耗18分钟/精力3点。已写入真实`game_state.json`、`events.jsonl`的EV000010、索引和公开记忆，索引状态sha和事件链sha一致。

后续`checkBasket`已编写可复算的120分钟生态时间门槛和单鱼群扣数捕获规则，尚未作为玩家已执行行动，不能报告捕获成功。Node完整测试结果尚未取得，不得标正式通过。
