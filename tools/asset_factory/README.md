> **2026-10-16 最高优先级规范更新：**《苍岚》新开发只上传公开仓库 `160701541-cell/xinyanshuo`；旧私库/旧项目开发基线已否决。统一执行 [CAC 工业化开发协议](../docs/CAC_PUBLIC_INDUSTRIAL_PIPELINE_V2.md)。新增或调整工序必须同步更新规范、开发日志和测试；冲突时以CAC协议为准。\n\n# 苍岚高清素材工业流水线 / Asset Factory

**2026-10-15 用户确认方案**：允许以风格一致的国风拼版为批量输入进行分格裁切；流程目标是大规模、可复现、可审核、可追溯的独立场景候选素材 + 对应图标。裁切候选不等于透明高清成品，不允许把拼图直接裁切结果宣称为通过质量门禁的游戏素材。

## 已上传的真正可执行源码

- `atlas_factory.py`：v5拼版20格裁切、512px图标候选、输入SHA256与候选清单，所有结果默认 `UNAPPROVED`，不会导入正式游戏。
- `atlas_layout.json`：对应示例海报的20格坐标，可按具体拼版模板调整。
- `make_jobs.py`：生成20种道具的多状态生图任务与初版制造关系草案。
- `industrial_pipeline.py`：连接已经运行的ComfyUI本地API；可选外部超分命令；无AI超分时标注LANCZOS_NOT_AI。生成结果仍需审核。
- 同目录早先提交的 `comfy_batch.py` / `approve_and_export.py` / `test_factory.py` 仅为占位索引，并非完整可执行源码；**不可视为已完成GitHub同步**。完整历史原型见聊天交付包 v1.2。后续要替换占位实现。

## 安装与运行

Python 3.10+，安装 Pillow：`python -m pip install Pillow`。

```sh
# 从拼版裁出20个未审核候选场景图、20个配套图标（必须提供原始拼版PNG）
python tools/asset_factory/atlas_factory.py --image YOUR_ATLAS.png --layout tools/asset_factory/atlas_layout.json --out ./candidate_output

# 对纯黑边缘可选尝试简单扣底（不能保证精确透明）
python tools/asset_factory/atlas_factory.py --image YOUR_ATLAS.png --layout tools/asset_factory/atlas_layout.json --out ./candidate_output --dark-cutout

# 生成20种物品、多状态AI生图任务，写到同目录
python tools/asset_factory/make_jobs.py
python tools/asset_factory/industrial_pipeline.py --dry-run
```

真实ComfyUI调用另需已启动的图像服务器及用户提供的API格式工作流：
```sh
python tools/asset_factory/industrial_pipeline.py --workflow YOUR_COMFY_API_WORKFLOW.json --url http://127.0.0.1:8188
```

脚本不自带AI模型、GPU、透明抠图精修器，不自动批准候选。必须人工复核拼版裁切是否有邻格、文字、黑底、透视不一、细节不足、边缘残留；符合要求后再单独完善审批/导出流程及Godot验证。

## 实际验证
会话环境执行 `atlas_factory.py` 输入已有拼版和本模板，返回 `Created 20 candidate sprites and icons; 0 approved`。**已通过命令行候选输出冒烟测试，未验证Godot，也未更新手机。**

## 推荐状态机
`GENERATED -> CROPPED_CANDIDATE -> BACKGROUND_CLEANUP -> TECH_QA -> VISUAL_REVIEW -> APPROVED_HASH_LOCKED -> GODOT_IMPORTED -> ENGINE_TESTED -> MOBILE_RELEASED`。

同名文件或缩略图不能证明已完成生产上线；每一阶段记录源输入、脚本版本、处理参数、输出哈希和复核人。


## CAC-0002 候选独立PNG机器审核（新工序）
裁切之后运行：

```sh
python tools/asset_factory/audit_candidates.py --input ./candidate_output
python -m unittest discover -s tools/asset_factory -p 'test_audit_candidates.py'
```

输出 `candidate_output/technical_qa.json`，缺失图、路径越界、伪批准、不透明整底、边缘触碰或分辨率不足时返回失败。它是保守的机器门禁：复杂影子、标签、残底、邻格、机位和风格不能自动认可，必须继续人工检查；任何通过项仍非正式可用素材，不能自动导入Godot。


## 新手村素材缺口订单生成（CAC-0003）
`python tools/asset_factory/starter_village_catalog.py` 生成 `tools/asset_factory/starter_village_demand.json` 规格清单，不生成图像。清单包含基础地形、建筑、建筑拆件、植被、道具、人物和装备，并显式要求角色8方向动作、建筑受损状态、开关门、点灭灯笼、树木四季；每个需求独立world PNG路径，图标同原型引用。运行 `python -m unittest discover -s tools/asset_factory -p 'test_starter_village_catalog.py'` 可进行回归核验。所有条目默认 SPEC_ONLY；不能将需求清单视为已经入库的素材。


## CAC-0004 从需求规格到真实模型待办队列
`python tools/asset_factory/starter_village_jobs.py --batch 2 --family terrain` 生成独立 `starter_village_jobs.json`；随后可用 `python tools/asset_factory/industrial_pipeline.py --jobs tools/asset_factory/starter_village_jobs.json --dry-run` 核查任务。没有真实ComfyUI工作流，不能实际生成PNG；真实推理需添加 `--workflow YOUR_COMFY_API_WORKFLOW.json --url http://127.0.0.1:8188`。该转换支持所有类别，每件携带来源需求ID、目标游戏图/图标路径与未批准状态；现有工厂的图像产物路径仍需后续审核导出映射，不能误认为自动入库。运行测试：`python -m unittest discover -s tools/asset_factory -p 'test_starter_village_jobs.py'`。


## CAC-0005 实际候选清底与双背景人工复核预览
适用于**边缘背景颜色大体一致、主体未触画布边界**的拼版裁切候选PNG。先使用原 `atlas_factory.py` 产出 `candidate_output`，再执行：

```sh
python tools/asset_factory/candidate_cutout.py --input ./candidate_output --out ./cleaned_output
python tools/asset_factory/audit_candidates.py --input ./cleaned_output
python -m unittest discover -s tools/asset_factory -p 'test_*.py' -v
```

每件独立输出 `scene_candidate.png`、`icon_candidate.png`、`visual_review_preview.png`（浅色与深色底检查），目录清单记录来源与图像SHA256及清底算法指标。拒绝复杂纹理、边框沾色、主体触边及不明确底色；拒绝项按 `BLOCKED` 留在清单中，**不自动通过**。二值边缘清底仍可能留下发丝/植被光晕或损失接近背景的细节，必须人工复核；技术审核通过也绝不自动上架游戏。地形铺片允许触碰边界，不适用该孤立精灵的边缘判据，应另建拼缝QA。本地合成图夹具9项测试通过，不等于正式高清美术通过。


## CAC-0006 已用真正图鉴完成第一次20格反证审计
独立审计脚本 `atlas_reality_audit.py` 从**真实拼版PNG**逐格裁切、检查异常alpha，默认不允许把图鉴中不透明但数值255以下的半透明背景当成真透明底。已人工确认图鉴需诊断性剥离alpha时，才可加 `--flatten-ambiguous-alpha`；它仅把现存RGB像素用于分析，**不是精细抠图**。不合格候选返回非零；5/20技术清底候选、15/20阻断，人工复核20/20未达到完整独立高清可用标准。详见 `docs/CAC_REAL_ATLAS_AUDIT_20261016.md`。本地测试 `python -m unittest discover -s tools/asset_factory -p 'test_*.py' -v` 中已单独运行新工序12项合成测试全部通过；仓库全测试和CI状态仍需独立核验。

## WorldX 真实出图 batch02（2026-10-16）
`canglan-worldx-props-batch02.yml` 使用已存在的 `SILICONFLOW_API_KEY` Secret，固定 WorldX 提交与原生 prompt loader，替换90度地图模板，顺序生成院门和石井两个1024原图候选。每件最多一次生成请求、失败不重试、已有完整产物跳过；记录提示词、模型、SHA、运行链接。`node --test tools/asset_factory/test_worldx_props_batch02.mjs` 无付费调用。这里只使用文本画风约束，没有把参考图传给模型，必须视觉比较。纯色原图不是透明成品；生成候选单独保存，未引用场景，不改发布清单；部分成功在 Actions Artifact 保存，不能盲目重跑付费批次。

## batch02 局部修补复现
`python tools/asset_factory/apply_ai_corner_repair.py --root game-source/apk176-ota177-candidate/hd2d/worldx-generated/batch02` 使用已完成的AI修补补片输出两张1024修补版，保留原图、来源和SHA。自动断言修补区域外逐像素一致；Actions自动保存修补版。此命令不重新调用模型，不处理主体背景分离。

## WorldX batch03
入口 `canglan-worldx-props-batch03.yml`：六件道具，固定WorldX上游版本，直接使用无依赖原生prompt loader，不再安装无关生成器依赖。每件一次、顺序调用、无重试；请求记录与所有成功候选保留，全部GENERATED_UNAPPROVED。`node --test tools/asset_factory/test_worldx_props_batch03.mjs` 检查订单与隔离约束。原生1024，不放大冒充高清；带字样后续需独立修补，带背景不自动批准。

## WorldX参考图probe01
工作流canglan-worldx-reference-probe01.yml运行单件厢房验证。脚本worldx_style_reference_probe01.mjs校验已有院落原图SHA并以data URL传入Kolors的image字段，固定seed，保留prompt/来源哈希/图像/请求记录。默认一次、不重试，参考作用仍待视觉比较。`node --test tools/asset_factory/test_worldx_style_reference_probe01.mjs`检查真实image字段与单请求规格。

## WorldX reference_extract02
入口canglan-worldx-reference-extract02.yml；worldx_reference_extract02.mjs仍使用WorldX原生prompt loader，但改由Qwen/Qwen-Image-Edit-2509对已确认原院落提取正房。一次调用，无重试；不使用该模型不支持的image_size，真实结果尺寸单独核验。`node --test tools/asset_factory/test_worldx_reference_extract02.mjs`验证模型、源图输入与接口参数约束。不是新批准画风，也不是透明/结构QA通过。

## 原画像素提取（零模型调用）
`python tools/asset_factory/extract_source_house.py --source game-source/apk176-ota177-candidate/hd2d/courtyard/main_house_v3_source.png --out OUTPUT`。
锁定原院落SHA，对正房可见部分加轮廓alpha，输出532×537原生PNG、浅深底预览与JSON。运行时自动验证保留RGB逐像素一致；不重绘、不放大。工作流canglan-source-pixel-extract.yml真实复现输出并提交。手工轮廓仍待细修，被遮挡结构未恢复，不自动批准。
