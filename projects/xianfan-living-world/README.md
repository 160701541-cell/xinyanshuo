# 《仙凡共生》 · 独立活世界地理原型 v0.6.0

> **硬隔离**：本项目仅借用公开仓库的独立 `xianfan/independent-living-county-v0.1` 分支。与《苍岚·人生世界》Godot主线、WorldBox MOD、签名OTA和官网正式游戏均无关联。本包的 Android applicationId 为 `com.xinyanshuo.xianfan.county`。

## 2026-10-24｜《仙凡·苍岚》统一世界观（仅设计，不代表游戏更新）

本分支新增了供独立AI文字战役和后续实现参考的原创世界观合同：

- [统一世界观与修仙体系 v1.0](docs/UNIFIED_WORLD_CANON_V1.md)：以本分支连续地理/凡俗王朝为底，参考《苍岚》社会生态与《凡人修仙传》修炼逻辑，明确凡界/灵境/灵界/仙界/幽冥、境界、灵根、经济、妖兽和NPC记忆规则。
- [机读世界观配置](data/unified_world_rules_v1.json)：版本化地理/境界/人口边界/剧情初始快照；**仅参考，不是当前运行的引擎参数**。
- [设计一致性测试](tests/unified_world_canon.test.mjs) 与 [本次整合日志](docs/UNIFIED_WORLD_INTEGRATION_LOG.md)。

**边界**：不改动《苍岚》main、Godot正式APK、WorldBox MOD或此前的仙凡原型存档。本分支13,680名局部NPC与另项目5,000人口不得叠加；上位世界、完整版NPC AI及战斗经济仍属未实现计划。此提交不是Android更新、不是小说原作的官方联动授权。

## 独立文字战役：公正主持与十轮记忆

- [系统级NPC性格与终生履历规则](systems/npc-life/README.md) 与 [所有正式登场NPC的持久档案](campaigns/first-life/npc_registry.json)：每个人物有稳定ID、性别、可复算的基础人格、带事件编号的经历；不随剧情压缩丢失。
- [野外草药真实生成/采集规则](data/medicinal_foraging_rules_v1.json) 与 [行动结算程序](tools/medicinal_foraging_turn.mjs)：由生态种子和材料节点决定收获，出售前不填虚构价格。


- [狩猎与小兽陷阱材料规则](data/hunting_rules_v1.json)、[真实制作判定程序](tools/hunting_engine.mjs)及[守恒回归测试](tests/hunting_engine.test.mjs)。仅实现可追溯的陷阱制作计算；没有猎物实例登记前，**不能直接捕获动物或凭空获得皮肉**。

- [P0数值权威协议](docs/GM_NUMERIC_AUTHORITY_V1.md)：所有数值必须由真实代码计算，有明确公式、初值和凭证；[整数与双向经济账本](tools/numeric_accounts.mjs)、[结算引擎](tools/numeric_engine.mjs)、[行动CLI](tools/turn_cli.mjs)、[数字回归测试](tests/numeric_engine.test.mjs)、[哈希校验HUD](tools/numeric_hud.mjs)。未知机制阻断，不临时生成数值。

- [GM-L0 游戏世界裁判协议](docs/GM_GAME_PROTOCOL.md)：玩家和NPC同规则、成功与敌对都必须有因果、追击必须合理止损。
- [GM自我迭代与质量审计 v1.0](docs/GM_CONTINUOUS_IMPROVEMENT_V1.md)：行动后检查、每十轮公平/记忆复盘，缺证据不写通过；实现见 [审计工具](tools/gm_quality_gate.mjs) 与 [回归测试](tests/gm_quality_gate.test.mjs)。
- [第一世公开存档](campaigns/first-life/README.md)：状态、原始事件账本、NPC公共记忆、分段完整状态与校验索引。
- [存档恢复与每十轮压缩工具](tools/restore_campaign.mjs)：只在玩家行动结算后运行，不会聊天外自动执行。

## 本轮方向修正（2026-10-21，用户手机反馈）

本游戏正式转为 **WorldBox式连续世界地图 + 地点建筑内部场景 + 社会模拟RPG**，不再是传统纯文字/MUD菜单，也不再做四张点击切换的假地图。

- 全部地图采用**单一米制世界坐标**：放大/缩小只改变摄像机视野，不改变玩家实际位置。修复“松林村放大回县城”。
- 允许同一个画布从街巷缩放到县境、省域与多国概览，不自动触发层级跳转；地图按钮只缩放，长按拖动地图。鼠标滚轮/手机双指手势围绕手势中心缩放。
- 玩家独立角色状态栏；地图中以**圆形头像实体**显示人物。重要NPC来源于实际13,680居民档案，少量近景NPC按照真实地图坐标移动（当前仍非全量自主AI）。
- 屋舍、城墙等构成碰撞障碍，县城四城门可通行。建筑点击先弹介绍与“前往”，必须走近门前才能进入室内；人无法穿墙。
- 无固定等级地图。地点、道路、地理、水系、国界、朝廷皇城、各国都城和修仙宗门使用统一坐标绘制；未开放地区明确标注为**地理占位**，不谎称已实现经济/人口/政权模拟。
- 普通人不显示可点击御剑操作。所有人物行动开始后持续推进世界时钟；停止行走不会退还已消耗的时间。
- 人口数据沿用 v0.5.1 的13,680人，无需重建旧存档。

## 本版本局限 / 尚未通过

- **不是整个天下米级实体化**。目前米制坐标已经统一，近景城墙、街道、建筑具碰撞几何；远景土地只提供示意地理和宏观标记。世界级逐米持久化应由**多层LOD + 按需生成/装载的空间分块**逐步拓展。
- 除几个示例岗位外，NPC仍是轻量定点目标/短程移动，不是全人口独立日程、真实家庭出行，也不包括现实级战争与皇城政务。
- 近景房屋仍是程序矢量建筑，**不是经过精美美术审验的完整建筑素材库**；用户认为过于简陋的问题尚未完全解决。
- Android测试包采用独立固定公开**测试签名**，仅适合原型覆盖安装，不能直接当作商业发行安全签名。
- Android真实手机观感、触控、存档迁移等必须由安装后截图和实际操作记录验收。

## 运行与构建

Web原型 `web/index.html`，纯浏览器 ES Modules；构建与覆盖安装由分支内 GitHub Actions (`.github/workflows/xianfan-county-android.yml`) 执行。既有Android WebView原型将 `web/` 目录作为APK assets。

本地测试：`node --test tests/*.test.mjs`。旧 v0.5.1 的拆分地图源码保留作基准，但正式客户端入口已切换为 `web/overworld-ui.js` / `web/overworld.js`。

**存档迁移说明**：schema2仍沿用，首次载入旧存档时按原 `player.place` 补入 `player.mapPos`；之后地图缩放绝不修改角色实体坐标。玩家居住地与视野中心分别保存在 `player.mapPos`、`mapCamera`。县城切到松林不会自动回城。完全新的世界种子仅由玩家点击“新局”后确认生成。
