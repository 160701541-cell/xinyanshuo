# 《苍岚·人生世界》公开开发迁移与 P1 美术执行记录

> 2026-10-15 · 用户已决定停止依赖私有仓库的付费 Actions。**公开源码从零审核导入，不公开旧私库 Git 历史、不导出私人令牌、密钥、存档或不明授权资源。**
>
> 官网：`https://160701541-cell.github.io/xinyanshuo/`；最后经确认的线上内容包 `revision=167`。本文件的“已完成”仅指代码/资产制作，不等于游戏里已更新。

## 开发与发布新架构（最终目标）

本地工作目录（Godot 4.4.1 / Blender）→安全审查及离线验证→公开仓库 `xinyanshuo/game-source/` 的可公开源文件→公开仓库的**标准** GitHub Actions／必要时本地构建→原签名RSA的PCK或者同签名Android APK→原官网 `android-preview` 发布。先验证非签名QA产物，再进入受保护的签名步骤；如缺少原签名私钥/Android keystore，**停止正式发布**，不能生成冒充旧版本可升级的补丁。客户端更新URL和现有存档不改。

公开仓库标准 GitHub 托管runner的计算时间通常免费；但有工件存储、带宽、Pages、总资源和滥用规则等限制。不无限堆CI：只用ubuntu标准runner、按需执行、短期工件和构建缓存，不用大型付费runner。

### P0-迁移核查

| ID | 工作 | 当前 |
|---|---|---|
| M00 | 核对旧私有Actions卡在runner分配前；用户确认私库额度不足 | ✅ 原因明确（以用户账号提示为准） |
| M01 | 停止旧私有仓库定期轮询任务 | ✅ 已禁用相关自动检查 |
| M02 | 保留官网、签名包、APK、现有玩家资料 | ✅ 未改动 |
| M03 | 把A—H主线、P1状态和迁移风险公开记录到官网仓库 | ✅ 本文 |
| M04 | 盘点旧源的代码、Blender资产、授权文件、账号/密钥泄漏风险 | ⏳ 待逐文件安全审查 |
| M05 | 按允许公开的白名单迁移GDScript、Godot场景、原创贴图、测试（**不迁移私库历史**） | ⏳ 待完成 |
| M06 | 在公开可复现的源中构建Godot Android/签名PCK，检查库存/存档、实景截图 | ⏳ 待验证 |
| M07 | 重新配置原有RSA及APK签名凭据至**Secrets**（不是Git文件） | ⏳ 待核实密钥是否仍可用 |
| M08 | 首次官网正式rev >167、签名核验及玩家Android实际更新 | 🔴 未交付 |

## P1正式优先级：先让10米院落达到稳定的国风美术基础

**P1-A 建筑精修**：米白灰泥墙＋石砌墙基和封闭院墙、青灰起伏瓦和屋脊檐口、木梁柱、石径/苔痕/竹林；同一镜头远中近都可读。旧Godot真实截图目前不合格，严禁冒称完成。

**P1-B 材质库**：至少“白灰泥、青瓦、木梁、石阶、泥地、草、布料、金属”八套统一国风Albedo/Normal/Roughness，AO按需要打包；UV、色域、法线导出、LOD和纹理共享都要验。**先做好白墙与青瓦的第一对标准材质**，再扩其余材质。

**P1-F 人物**：一名可公开合法使用且带骨骼的工匠，拥有完整走/停/转身/搬运/施工动画；不得使用授权不明的人物模型。

**P1-C/G 光影**：正午、傍晚、夜晚的共同色板与阴影，适度泛光/环境遮蔽/远景雾，不以硬件光追为手机必选项。

**P1-H 性能（贯穿）**：低/均衡/高清/极致均可选，高档警示与必要时热降频保护，纹理/网格/粒子/LOD随档位分级。实际Android设备发热及帧率仍必须实测，桌面渲染不算。

### 必须附证据的验收状态

- ✅ **代码/原始资源存在**：可以写入开发进度，不能写入已发布更新日志。
- 🟡 **本地脚本/贴图测试通过**：证明结构符合检查，不能证明Godot或手机画质。
- 🟡 **Godot真实渲染截图**：需要用户/美术审视后才算美术通过。
- 🔴 **Android客户端实际收到新版资源**：目前尚无证据；仍显示正式#167。
- 🔴 **主流国风游戏画质**：尚未完成；第一张真实院落图未达到标准。

## 旧文档兼容

历史 `docs/ART_MASTER_EXECUTION_CHECKLIST.md` 在旧私有仓库，其P0/G0状态是历史记录；从用户新的迁移决策开始，以**本公开文件作为公开执行主线**，后续仅在实际执行后勾选。原官网`data/updates.json`只保留真正签名发布的版本。为节约额度，GitHub基础的文件存储/Pages用于发布静态官网与构建产物，正式游戏测试优先本地验证。

## 下个实际任务

**P1-B01**先生成青灰瓦、素白灰泥原始颜色/法线/粗糙度材质；离线检查图像尺寸、无透明缺像素、贴图接缝/法线长度、几张资源复用与SHA256；确认能够安全公开后再迁到 `game-source/`，正式Godot导入/Android实测另记。随后完成P1-A的闭合白墙与瓦脊实物结构、制作人形动作。

## 2026-10-15 本轮实际代码增量（公开仓库）

- **P1-B01 开始编码，非仅规划**：新增 `game-source/tools/generate_materials.py`，纯 Python 标准库可重复生成青灰瓦与米白灰泥两套 256×256 的 RGB Albedo、切线空间Normal、Roughness PNG，共 6 张；附 SHA256 manifest。纹理属于原创**程序美术试样**，不是专业贴图终版。
- 新增 `game-source/tools/test_materials.py`，本地真实运行 `python test_materials.py -v`：**1 test，OK**，覆盖PNG像素头、zlib解码、CRC、尺寸、图片载荷、法线存在、SHA256与重复导出一致性。另运行脚本实际生成6张PNG及manifest；这些生成二进制尚未提交官网，不能宣称Godot已导入或游戏已更新。
- GitHub源码提交：`12d3381ed901791df1aef7446b23524e7eea4e2e`（生成器）、`6e2229cce43144355a4d06516a752d877dd63fe8`（测试）。仅向**现有公开官网仓库**添加两个原创脚本；旧私有主仓库仍为private，未对其做visibility变更或全量迁移。
- **安全/发布边界**：未复制私有仓库源码/历史/令牌/密钥/玩家存档；未触碰Android签名、现有APK/PCK/公开feed；旧仓库Actions尚未从GitHub设置层禁用；无法以此次结果声称停止了私人Actions费用。正式M04～M08仍未完成。
- **下一验收**：在公开构建目录生成纹理并逐项做Godot 4.4.1真实导入/同机位画面；对私有源码作逐文件公开许可审计以后，才能迁移游戏本体并配置公开CI。明确区分源码S=通过、离线T=通过、Godot T=未验、发布R=未完成、Android D=未验证、美术A=未通过。

## 2026-10-15 本轮“先把可打包的打包”实际执行

- 在公开仓库新增 `.github/workflows/p1-materials-package.yml`（提交 `83bf477488c9fc0d79164a1acadf3e39890d360c`）。自动运行PNG生成器及测试、校验6个PNG的SHA256、生成 `canglan-p1-materials-UNAPPROVED.zip` 并上传3天有效的构建工件，不使用**私有**Actions额度。
- 公开Actions实际触发：[run #38641955771](https://github.com/160701541-cell/xinyanshuo/actions/runs/38641955771)，首次检查状态 **in_progress**，截至记录时尚没有绿灯或可领取工件证据。
- 此处只打包可安全公开的P1素材试验；正式手机尚不能安装。因为公开仓库缺完整已审计Godot工程与原RSA热更新签名，不能把这种zip伪装成可签名PCK。没有更改旧官网`latest.json`（167）、旧APK（176）或者客户端存档；P0/G0原有院落仍待真正游戏整合和客户端验收。
- 迁移任务M05、M06、M07仍阻塞正式发布；禁止把此次公开素材QA写为“游戏已更新”。

## 2026-10-15 游戏内测试前：真实公开发行包完整性门禁

- 用户要求只交付已具备验证证据的功能、先整合测试再手机验收。现有完整游戏仍由私库`canglan-world`的Godot主工程维护；公开`xinyanshuo/game-source`目前**不是可独立构建的原游戏**。不能把独立材质ZIP作为签名PCK安装。
- **已通过**：公开P1材质ZIP构建 [#38641955771](https://github.com/160701541-cell/xinyanshuo/actions/runs/38641955771) 最终`success`，产物`canglan-p1-materials-UNAPPROVED`存在，大小133114字节。仅证明原始PNG生成/离线验收合格，不等于美术和手机集成。
- **已执行**：新增公开真实发行包完整性CI工作流`.github/workflows/verify-official-game-release.yml`；读取`base-latest.json`和`latest.json`，计算已发布73MB APK与PCK167真实字节SHA256、长度，检查APK ZIP结构；拒绝对新版发布作虚假成功声明。工作流提交`dbcb12128c5149d24820ae3950ce75f5fc0c368c`，检查执行 [#38642647667](https://github.com/160701541-cell/xinyanshuo/actions/runs/38642647667)，记录时仍在运行。
- **立即可供用户测试的最后签名APK**：`v0.2.0-dev.176`、`code1176`；[GitHub Releases备用下载](https://github.com/160701541-cell/xinyanshuo/releases/download/canglan-v0.2.0-dev.176/Canglan-AncientWorld-v0.2.0-dev.176-Stable-Signed-ARM64.apk)。资源更新渠道`revision167`。这个下载不会包含本轮的白墙/青瓦P1新增代码。
- **正式新热更新门禁**：以APK176为基线，候选资源revision须至少**177**（且高于实际安装版本），保持原RSA签名；必须先原Godot主场景导入、主世界实体与存档回归、PCK资源索引验证、签名检查、官网字节核验，最后手机更新。未经这个流程不修改`latest.json`；当前并无可以诚实宣布的rev177。
- 现有私库Actions无runner步骤且公开仓库缺已审计原项目/签名Secret，阻断正式新版本。本轮没有重启私有付费Actions，也没有生成冒名新安装包。仅实际核查最后可安装基包和建立真实包验收工作流。

## 2026-10-15 QA独立硬门禁执行结果

- 已真实修改生成器（93dc977）：周期连续材质代替色块式噪声，明确贴图颜色空间和法线约定；不称成品。
- 独立审计器（ecae2b3）直接检查PNG字节、CRC、zlib像素、哈希、尺寸、色板、平铺接缝、法线向量、粗糙度和白名单；不靠生成器自己给自己打分。
- 变异回归测试（4a27e6c）共12项，包含故意篡改后能真正阻断的平面贴图、法线翻转、PNG损坏、接缝、路径绕过及伪造批准。
- [真实公开QA构建#38643860617](https://github.com/160701541-cell/xinyanshuo/actions/runs/38643860617) PASS；job 116125782923实际日志显示12 tests OK，PNG独立审计与工件上传PASS。这里只代表技术QA。
- [执行规范](ENGINEERING_QA_RELEASE_POLICY.md)已入库；[人工视觉复审](P1_MATERIAL_ART_REVIEW_20261015.md)主动将现有材质列为ART FAIL（青瓦仍像柔和条带，白墙过于平滑，欠真实构件/近景细节）。技术通过绝不代替Godot实景、Android和人工审美。
- 本轮未新发APK/PCK，当前手机版本仍以APK176及PCK167为公开基线；原游戏迁移、主世界集成、RSA签名和手机负载仍BLOCKED。

## 2026-10-15 新增真正的开发质量生产系统（已运行，不是概念口号）

- **生产前标准已落地**：`docs/CANGLAN_DEVELOPMENT_MANUFACTURING_STANDARD_V1.md`，要求任何新物体/功能从第一天先有玩家使用场景、物理/美术工艺、原料/实体产权、操作响应、视觉近景、性能和失败恢复的**规格合同**；结案仍需独立审核。
- **可执行数据调教器**：`game-source/tools/tune_data.py` + `data/tuning/engineering_contract.v1.json`，有不可削弱的硬指标：碰撞/输入冲突、库存/旧档/无授权解锁等逻辑事故为0；Android 15分钟稳态门禁；视觉真实Godot截图。脚本只根据有证据的超标指标给出小步候选参数，不自动改动玩家游戏、更不能自动认定审美通过。
- **逐物品生产合同引擎**：`game-source/tools/production_contracts.py` 动态检查当前24类物品每一个的九道制作门禁：设计、合法原始美术、物理账务、Godot导入、真实审美、触摸操作、Android性能、旧档兼容与签名发布。自动产出JSON缺口报告；目前全部24个都尚未具备完整游戏发布证据，**阻止宣称已完成**。
- **首个真实物料/制造超图**：`game-source/data/craft/material_graph.v1.json` 有24类物品、14条多输入多输出工序、6项研究和4份图纸；覆盖黏土→淘泥→青砖/青瓦、石灰→灰泥、木梁→青瓦屋面、砖灰→白墙模块。由`craft_graph.py`校验总质量守恒（简化g计价模型、非真实化学计量）、无天然材料凭空造出、无循环增殖、解锁/工坊/库存合法性。实验程序`evaluate_experiment`只创建**研究候选**，不改现有`WorldState`，不会送免费材料或图纸。与原`physical_material_registry.gd`中原木40kg、结构梁20kg规格对齐，新梁ID不静默覆盖旧物品。
- **真正的引擎解析**：新增只读Godot 4.4.1 GDScript目录桥接器`game-source/godot3d/scripts/crafting/craft_catalog_reader.gd`，并用隔离微工程验证资源图谱查询、研究/图纸门禁、物料预算；**不是原主游戏UI/工单完成**。
- **最终公开真实QA结果**：[GitHub Actions #38646840315](https://github.com/160701541-cell/xinyanshuo/actions/runs/38646840315)结论**success**：原料工艺图17项、数据调教16项、单品生产合同8项，合计41项真实Python测试全部通过；另有实际Godot 4.4.1无渲染器隔离图谱脚本运行PASS。对应机器可读报告及Godot运行日志已上传GitHub工件，报告仍显式`release_approved=false`。早期CI曾抓到脚本语法错误及错误的物料反例质量，已修正后重新全部通过；不删测试求绿灯。
- **严禁混淆阶段**：S/U（公共架构+真实自动测试）通过；独立Godot数据只读I=部分通过；原游戏`WorldState`工单与实际图纸界面、玩家研发解锁、国漫美术与Android设备验证/正式签名R **均未完成**。官网正式基包仍APK176、热更新#167。用户手机此刻不会出现“新物品树”。后续按一个墙段的真实资源→原料加工→图纸研究→施工工人→可视化→存档完整闭环才可标注正式游戏通过。

## 2026-10-15 — 用户休息前续研：原游戏真实工艺谱入口候选

- 在公开仓库新增 `game-source/godot3d/scripts/crafting/craft_codex_panel.gd`（commit `4f2a509`）：真正Godot4.4.1 Control UI，支持24类物品搜索、按原料/半成品/组件过滤、生产/用途配方和研究/图纸/工坊/库存缺口，默认纯只读，不可免费解锁或制造。
- 在私有游戏仓库**隔离分支** `feat/craft-codex-20261015`（未合并main）真实写入同源资源图谱、只读Reader、可交互UI，并向原 Godot `scripts/main.gd`「工具/更多」菜单增添工艺谱按钮。打开和关闭调用已有HUD触摸取消入口，并仅从原始`WorldState.inventories[player_entity_id]`读取库存；默认知识为空防旧档获得免费配方。对应新增入口提交`c11b5d7`，交接`docs/CRAFT_CODEX_WORK_HANDOFF_20261015.md`。
- **严禁混淆状态**：这是原游戏**源码候选入口**，未在Work分支最新主场景验证、未通过旧档字节/Android/人眼验收、未包含在正式签名PCK，**用户手机仍看不到**。
- **实际CI**：公开`game-source/godot-craft-smoke/tests/interactive_codex_smoke.gd`加入查询/筛选/解锁显示/关闭测试。第一次[#38648567503](https://github.com/160701541-cell/xinyanshuo/actions/runs/38648567503)失败是测试脚本把`Panel`作为常量名遮挡Godot内置Panel，已经修复；第二次[#38648754706](https://github.com/160701541-cell/xinyanshuo/actions/runs/38648754706)失败是测试误以为“青瓦”只会命中瓦片一条，实际还应命中“青瓦屋面模块”，已经严格保留真实搜索逻辑并修正反例。第三次[#38648915175](https://github.com/160701541-cell/xinyanshuo/actions/runs/38648915175)等待最终真实报告；不能提前标PASS。
- **付费Actions治理**：曾暂建私库draft PR#18用于Work交接，但PR触发旧有私人`pull_request`与`pull_request_target`工作流失败和消耗资源。**已立即关闭PR#18**、保留私有候选代码分支，停止PR触发；后续只在公开仓库跑隔离QA，不能再打开私人PR或推送触发旧Actions，直至迁移成功。
- **开发方式**：真实代码/失败测试/恢复验证/工作日志均记录，绝不删测试求绿灯；下一步优先让隔离Godot UI跑通，再将按钮差异无冲突地移入Work最新世界，以用户实际手机为最终标准。
