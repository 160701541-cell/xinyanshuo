# 《苍岚》GPT-6 × DeepSeek DSH 双代理协作隔离协议
> 用户 2026-10-18 最新指定：用户主要在 DeepSeek DSH 端指挥；DeepSeek 优先负责美术/UI；GPT-6 负责 BUG、原引擎 QA、性能与存档。**严禁同一子项目并发修改**。本文件为 GPT-6 自己的独立 Draft PR 中的提案，不覆盖任何代理已在进行的工作；若用户/DSH 调整职责，以用户最新命令为准。

## 工作边界
| 负责方 | 所属工作 | 严禁的并发修改 |
|---|---|---|
| DeepSeek DSH | 国风主角/核心修士模型、绑定/动画、美术风格、宗门/古建筑资源、UV/PBR与贴图、特效、游戏HUD/UI外观 | GPT-6 不再主动替换/生成以上项目的素材、不改动其在编辑的文件 |
| GPT-6 | 玩家实际BUG、碰撞、飞行/镜头输入、存档读写事务、NPC/经济逻辑、自然刷新幂等、GPU/CPU性能分析、Godot4.4.1真Main/候选PCK严格QA | DeepSeek 不在GPT-6的小修复PR里重复改相同文件；共同功能修改前按下文交接 |
| 用户 | 审美、实际手游体验、玩法愿景与优先级最终决定 | 未经实机验收不可代替用户声称发布 |

## 并发防撞原则
1. 唯一正式GitHub：`160701541-cell/xinyanshuo`。目前正式 `main` Android OTA 仍应以 `android-preview/latest.json` 真实revision为准；`feat/rev208-green-kenney-saplings-vegetation` 是未发布的综合候选 Draft PR #14。
2. 每个代理必须各自建**独立分支和独立Draft PR**。GPT-6分支前缀 `gpt6/fix-` / `gpt6/qa-`；DeepSeek建议 `dsh/art-` / `dsh/ui-`（名称由DSH自己决定）。任何一方都不能直接push到别人的PR或`main`，不得force-push、自动合并。
3. 同一时间，同一Godot GDScript/场景若跨UI与逻辑（例如 `apk176_player_controller_rev187.gd` 既有UI又有操控），其文件**视为临时共享锁**：先分别开发独立模块，协商单人落地接线；未经协调不并发编辑原文件。
4. GPT-6仅处理其独立小范围问题，发PR说明更改哪些文件、完整测试和冲突风险；如发现DeepSeek也改相同文件，则该PR暂停，等待衔接后择一提交。每轮先检查所有协作分支HEAD和最近commit，以及本人的未关闭PR。
5. CI：每个PR增量QA；避免反复push到触发 `cancel-in-progress` 的公共重型QA分支。美术视觉验收由DeepSeek负责，GPT-6可独立为功能问题添加真实回归测试，不做互相覆盖的审美改稿。
6. **发布安全闸门**：保护原版APK176、实体ID、52旧树/20旧石、修士永久死亡、人口账本与原存档；自然树木/灵草/灵矿允许生境内自然生成与后续随机刷新，NPC背包增加必须真实劳动。rev208 P0视觉/原Main QA/Android实机30分钟任一未过，不合并、不生产RSA签名、不改官网。
7. 交付形式：`source commit + QA日志 + 原Main/PCK实际可运行证据 + 未完成事项`；用户优先在DSH端继续，GPT-6仅报告真实BUG修复或阻塞，无必要不反复打扰。

## GPT-6 本轮独立小项目
- **QA-RESOURCE-001**：`game-source/apk176-ota177-candidate/scripts/apk176_wild_tree_stone_birth_rev208.gd` 中自然生成后的原子保存一旦失败，当前 `_birth` 仍把未持久化的新树/石节点返回为“成功出生”，并留下经济/生态注册，造成手机重启后世界资源ID缺失及潜在反复采集；修复为**失败时完整事务回滚**。只动这一个非美术/非UI底层文件，辅以隔离QA；不接触DeepSeek的模型/UI项目。
- 改动暂存在 `gpt6/fix-rev208-world-resource-save-20261018`，如无实际Godot QA日志只标待验收，不能直接合并。
