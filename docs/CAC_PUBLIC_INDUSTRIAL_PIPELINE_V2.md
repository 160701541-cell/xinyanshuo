# CAC — 《苍岚》最高优先级工业化开发与公开仓库协议 v2.0
> 生效：2026-10-16。用户明确批准。规范性优先级：本文件 > 其他旧开发计划、旧素材工厂说明及旧项目流程；但不降低安全、版权、QA、存档、签名门禁。状态：**已批准的开发协议，不代表所有工序已实现。**

## 1. 唯一正式发布与上传目的地
- **只向公开仓库 `160701541-cell/xinyanshuo` 上传《苍岚》后续代码、流水线、文档、可公开素材和构建产物**。允许开源，不以私库作为新研发主线、提交目标或发布依赖。
- 原私库 `160701541-cell/canglan-world` 及其旧分支、旧原型、旧流水线均标记 **LEGACY / REJECTED FOR NEW DEVELOPMENT**。仅允许作为历史参考与迁移来源，**不得在私库继续提交新成果**。旧成果不因本协议自动变成合格素材。
- 不把私有凭据、密钥、签名证书、用户存档、个人信息、未获授权的素材上传公开仓库。开源许可与第三方素材授权需另行核实；“可以开源”不等于默认有权公开第三方内容。
- 公开仓库尚缺少的正式游戏模块必须经过可追溯迁移、兼容回归与公开QA，不能把私库存在当作公开仓库已集成。

## 2. CAC 工业化流水线（强制唯一开发主流程）
**规格卡/需求ID → 源素材/拼版生成 → 模板与坐标校验 → 独立裁切候选 → 去背景/边缘精修 → 高清母版及同源图标 → 多状态一致性 → 机器QA → 人工审美QA → 哈希锁定批准 → 公共仓库提交 → Godot真实导入/场景测试 → Android真机/性能与存档回归 → 安全签名发布 → 官网/开发日志同步**。

- 用户已批准**高品质拼版→批量裁切**作为工业化输入；不强制每件都单独调用AI生图。裁切后的每个文件必须独立、无邻格、无标题/边框、正确透明、足够原生分辨率，不能用普通插值冒充真实高清。
- 统一ID、类别、状态、图标、来源、许可证、母版哈希、裁切框、算法版本、审核人、Godot引用路径。失败状态不允许被后续工序静默覆盖。
- 质量不合格则退回对应工序；不得以增加素材数量、漂亮的展示拼版、模拟预览或自动评分代替实际视觉审查。
- 先完成20类物品垂直批次；自动化扩展到100/1000/全量之前，必须取得实际样本的视觉批准与游戏验收证据。
- 每新增/修改**任何开发工序、工具、资产格式、验收门禁、发布流程**，同一提交批次必须更新本文件、`tools/asset_factory/README.md`、实际工作日志/状态清单与相应自动测试；缺文档更新则该变更为未完成。

## 3. 旧项目否决规则
- 旧版方案、重复原型、私库专属脚本、仅提供压缩包而无公开仓库可追溯提交的成果，不再作为正式项目的开发基线；标记 SUPERSEDED，不得再用其“已完成”状态做新版本依据。
- **否决旧开发基线 ≠ 删除用户已有手机存档或破坏可运行版本**。迁移期间只读保存旧版本作为兼容和回滚参考；不得自行销毁用户资产、签名证书或可恢复发布物。
- 所有新增工作均以公开仓库 `main` 上本协议为权威入口；如采用PR分支，最终合并到公开仓库且通过门禁。

## 4. 证据和禁止性声明
分开记录：SPEC / GENERATED / CROPPED / CLEANED / TECH_QA / VISUAL_APPROVED / PUBLIC_COMMITTED / GODOT_TESTED / ANDROID_TESTED / RELEASED。每项必须附真实SHA、时间、执行命令/日志、批准者；无证据填 BLOCKED。**拼版生成或裁切 ≠ 20张合格独立高清素材；GitHub提交 ≠ 已进入手机游戏。**

## 5. 当前实施状态（2026-10-16）
- 公开仓库已存在 `tools/asset_factory/atlas_factory.py`、`atlas_layout.json`、`industrial_pipeline.py`、`make_jobs.py` 和相应说明，已有候选裁切流程。
- 本协议完成后，旧私库不再接受新的《苍岚》开发上传。公开仓库的现有质量/签名安全门禁仍然生效。
- **未声称**已生成全量高质量透明PNG、完成批量视觉审核、实际Godot导入或更新手机。下一步先让候选裁切输出通过实际独立PNG边缘QA，再推进同源图标、公开仓库批次提交和真机验证。


## 6. CAC-0002 候选透明边缘机器审核（2026-10-16）
- 新增 `tools/asset_factory/audit_candidates.py`：读取候选清单，核验唯一ID、候选状态、相对路径安全、文件存在、RGBA PNG、最小像素尺寸、透明通道、边缘触碰、SHA256，输出 `technical_qa.json` 并在不合格时返回非零退出码。
- `TECH_ONLY_PASS` 仅代表候选基础技术检查通过；无法证明没有残底、邻格、文字、透视错误及风格不统一，仍必须人工视觉审核；始终保持 `production_approved_count=0`。
- 回归用例 `tools/asset_factory/test_audit_candidates.py` 涵盖正常候选、纯不透明、触边、路径逃逸和伪造批准；真实拼版/模型/Godot/Android仍须单独留证。


## 7. CAC-0003 新手村缺口补齐：完整需求树（2026-10-16）
- 新增 `tools/asset_factory/starter_village_catalog.py`，将地形/建筑/建筑拆件/植被/生活道具/NPC/装备纳入统一稳定原型ID与具体状态/动作方向的任务图。独立世界PNG与同原型背包图标各有明确目标路径；门开关、灯笼亮灭、树木四季、建筑受损和8方向角色动作均列入。
- 新增 `test_starter_village_catalog.py` 约束ID唯一性、类别覆盖、状态一致性，以及所有新条目保持 `SPEC_ONLY` 未批准，防止规格冒充交付素材。
- 执行方式：`python tools/asset_factory/starter_village_catalog.py`；`python -m unittest discover -s tools/asset_factory -p 'test_starter_village_catalog.py'`。**尚未取得本轮运行日志，测试PENDING**。
- 此步骤只补齐需求/产线输入数据结构，**没有生成任何PNG、人物动画、Godot场景或Android补丁**；所有视觉/导入/实机门禁继续BLOCKED。必须以真实素材、运行报告和真机证据逐级放行。


## 8. CAC-0004 需求树接入批量生成队列（2026-10-16）
- 新增 `tools/asset_factory/starter_village_jobs.py`，把 `starter_village_catalog.py` 中的每一状态/角色方向需求转换为现有 `industrial_pipeline.py` 接受的 ComfyUI job 结构，独立写入 `starter_village_jobs.json`，不覆盖既有 `jobs.json`。
- 新增 `test_starter_village_jobs.py` 测试队列覆盖、批次过滤、状态和未批准保护。命令：`python tools/asset_factory/starter_village_jobs.py --batch 2 --family terrain`；`python tools/asset_factory/industrial_pipeline.py --jobs tools/asset_factory/starter_village_jobs.json --dry-run`。只有安装并实际运行本地ComfyUI模型/API工作流后才能真正出图。
- 新增步骤均保留 `PENDING_GENERATION / UNAPPROVED`。当前没有执行证据或GPU模型工作流，图像产量仍是零（本工序）；不能将生成队列声称为合格素材。


## 9. CAC-0005 真实候选图清底工序与CI（2026-10-16）
- 新增 `tools/asset_factory/candidate_cutout.py`：对实际传入的拼版裁切PNG进行保守清底；**只处理边缘均匀纯色背景**，拒绝四角明显不一致、主体触边、前景不明/背景占比异常的输入，已有透明通道原样保留；不使用插值伪装原生高清，也不冒充精细发丝/树叶抠图。
- 工序保留输入manifest、原始图、SHA256追踪；在独立输出目录形成 `scene_candidate.png`、512图标候选、浅色/深色双底视觉预览、`candidate_manifest.json`，所有输出标记 `UNAPPROVED` 并要求人工检查光晕、透视、邻格、结构等。若源候选含伪造批准标记则拒绝。
- 新增 `test_candidate_cutout.py` 覆盖白/黑背景、alpha保真、彩色背景不一致、空图拒绝、完整清单到实际PNG、路径越界、覆盖保护和伪审核，共9项。本地容器已执行此新模块的9项单元测试，全部PASS；**仅合成测试夹具，并非真实《苍岚》美术样张通过**。
- 新增 `.github/workflows/canglan-asset-factory-qa.yml`，GitHub推送时运行整个asset_factory的unittest并生成2个真实任务的dry-run QA记录；云端结果需要单独确认。未接ComfyUI模型服务、未新增批准图像、未Godot真机场景集成。


## 10. CAC-0006 真实源图反证审计（2026-10-16）
- 新增 `tools/asset_factory/atlas_reality_audit.py` 与 `test_atlas_reality_audit.py`，用真实源图、图集坐标和严格alpha判定，生成独立未批准裁切候选以及可追溯审计JSON。伪alpha需要显式 `--flatten-ambiguous-alpha`，不能悄悄把RGBA当真透明。
- 实际取得用户历史《苍岚》1536×1024素材图鉴作为本地输入，并复现20格裁切：5件仅能产生透明候选，15件因背景/裁断风险阻断；真人/模型视觉核对20件均仍含多状态、文字或低原生分辨率等问题。**0件获生产批准**。
- 完整证据见 `docs/CAC_REAL_ATLAS_AUDIT_20261016.md`，已在当前会话交付ZIP；源图仍在用户历史素材库，不自动上传未批准图片到公开仓库。
- 本地联合单元测试12/12 PASS，GitHub CI尚无实际运行结果；Godot及手机发布均未通过。

## WorldX batch02 有界生成工序
新增两件顺序候选（院门、石井），固定WorldX上游提交，通过原生prompt loader与现有Kolors接口生成1024原图；每件一次请求，无自动生成重试。技术门禁校验真实图像、分辨率和SHA；全部保持GENERATED_UNAPPROVED。文本约束不等于参考图条件锁定，无自动审美批准、清底、Godot引用和手机发布。失败时保留Artifact，重跑前先恢复已完成产物以免重复付费。相应入口、回归测试见asset_factory README。

## 用户授权的局部AI修补工序
脚本清除指定字样区域→内置AI局部补画→仅合成经审核的局部补片→范围外逐像素一致断言→原图与修补版分别保留→SHA报告。文本清除不得抹去来源记录，也不改变未批准素材的主体隔离/透明QA状态。

## 用户授权 batch03 六件候选扩充
仅扩大候选生产到6件，不扩大正式批准数量。所有请求写预先记录、顺序且最多6次、无自动重试；失败停止并保留Artifact。规格测试、真实尺寸/SHA检查和人工视觉QA分别留证。文本加强主体隔离不等于已经解决隔离缺陷；未审核产物不得自动导入正式场景。

## 真实参考图传参验证门禁
用户明确以原院落画风固定生产。新probe01核对源图SHA，在WorldX原生prompt loader适配请求中加入image实际图像数据，仅一次候选。元数据必须区分reference_image_sent和reference_effectiveness；传参成功不是风格一致证明。未视觉批准不能扩量或进入正式场景。

## WorldX源图编辑提取调整
extract02允许在原WorldX流水线中对源图做单次图像编辑提取；本工序模型明确记录Qwen/Qwen-Image-Edit-2509，不冒充Kolors。原院落仍为画风基准；不能以替换模型改变美术方向。锁定源图SHA、记录编辑参数、分别审核笔触一致/完整轮廓/被遮挡缺失/alpha，HTTP成功不等于成品批准。
