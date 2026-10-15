# CAC 工序变更与开发日志

## 2026-10-16 / CAC-0001 / 政策基线升级
- 用户明确要求：公开仓库唯一上传目标，允许开源；旧项目开发基线否决；工业化裁切流水线为最高优先级；新增工序必须更新文档与测试。
- 已提交 `docs/CAC_PUBLIC_INDUSTRIAL_PIPELINE_V2.md`，并更新根 `README.md`、`tools/asset_factory/README.md`、`docs/CANGLAN_DEVELOPMENT_MANUFACTURING_STANDARD_V1.md` 的优先级入口。
- 实施状态：文档和治理规范 PASS；新增生成/裁切/透明QA/真实素材/Android 发布均无本轮新增通过证据，维持原状；尚未构建新APK。
- 迁移原则：旧私库只读参考，不向其提交新研发；旧存档、签名和可回滚版本不得销毁。
- 每次后续新增工序：在此文件追加变更ID、脚本路径、测试命令与结果、资源SHA、公开提交SHA、Godot/手机验收结果。


## 2026-10-16 / CAC-0002 / 独立PNG候选机器门禁
- 公开仓库新增 `tools/asset_factory/audit_candidates.py`（首次代码提交 `6423f9dcc509d6247dbf57ff15d6f3148897eb13`），测试 `tools/asset_factory/test_audit_candidates.py`（提交 `270f4319807178977695e947499a4080884ffba7`）。
- 检测：唯一ID、清单一致性、文件路径逃逸、RGBA与像素尺寸、透明像素/边缘截断、文件SHA256；机器审核失败返回非零，成功仅为TECH_ONLY_PASS。
- 执行命令：`python -m unittest discover -s tools/asset_factory -p 'test_audit_candidates.py'`；**当前仅已提交测试源码，未获得本轮运行器执行证据，测试状态PENDING；无真实拼版审核记录。**
- 视觉审批：BLOCKED；Godot导入：BLOCKED；Android构建及真机：BLOCKED；正式发布：BLOCKED。继续优先修复实际边缘/透明底再启动成批候选审核。


## 2026-10-16 / CAC-0003 / 新手村完整缺口需求树
- 新增 `tools/asset_factory/starter_village_catalog.py`，提交 `b2fa1a4f04a54b87735586e10099995ba21b6079`；新增 `tools/asset_factory/test_starter_village_catalog.py`，提交 `95e72f050f23bfab9ef0c7dc7b20d876396272cb`。
- 硬性覆盖7大类：地形、建筑、可拆建筑模块、植被、道具、角色、装备；扩充为独立多状态/8方向动作生产规格，按真实素材哈希和许可证等待回填。
- 本轮GitHub源码与规格已提交；自动测试运行证据PENDING，图像生成/扣底/导入/真机/Beta发布全部BLOCKED。后续实际生产必须先分批验证，不能拿SPEC_ONLY做完成计数。


## 2026-10-16 / CAC-0004 / 素材需求转ComfyUI队列
- `starter_village_jobs.py` 新增提交 `fd8a97955a183bf89de50d55a749adeaa02296e7`；`test_starter_village_jobs.py` 提交 `0ce74675948f44dcef9ca4303cb20d8c7a2ca59b`。
- 已完成公开仓库源码上传，任务可按family/batch分片并保留唯一ID及所有输出目标路径，默认未获审核批准；不覆盖原20件job列表。
- 测试源码已提交，但**本轮尚无实际执行通过证据**。无模型服务和API工作流，真实生图、人工审美批准、Godot接入、Android真机和补丁发布继续BLOCKED。


## 2026-10-16 / CAC-0005 / 实际候选透明清底与首个专属持续集成
- 新增 `tools/asset_factory/candidate_cutout.py`，提交 `fc574a415a64341721fe63f0b5234ca37370831c`；新增 `tools/asset_factory/test_candidate_cutout.py`，提交 `940b9731e9b1c4497bd1c5069e6f6956127cdd9b`。
- 新增 GitHub Actions `.github/workflows/canglan-asset-factory-qa.yml`，提交 `e37d095da1f273d9182bf1a8971cb63150f135fc`：运行asset_factory所有测试并核查2份任务dry-run不会冒充已生图。GitHub CI云端运行结果**未验证，状态PENDING**。
- 本地验证命令：`cd /mnt/data/canglan_factory_local && python -m unittest discover -p 'test_candidate_cutout.py' -v`。输出：`Ran 9 tests in 0.186s / OK`，为白/黑背景等**程序生成测试夹具**，不是国风游戏PNG验收。
- 增加保守纯色背景识别、连通域透明处理、图标同步裁切、双底视觉预览、原图/输出SHA256和可追溯候选清单；模糊边、图像细节和材质仍需人工审核。0件新的审核通过高清成品；Godot、Android、正式发布均继续BLOCKED。


## 2026-10-16 / CAC-0006 / 真实图集首次可追溯反证审计
- 新增 `tools/asset_factory/atlas_reality_audit.py` 提交 `b8647dd4165d6d2cb6f8dca4962c73d4a05e4ad6`，配套测试 `tools/asset_factory/test_atlas_reality_audit.py` 提交 `9ab0bcc5f42510737a4801e2c843e01b1f0f3e17`。
- 读取用户历史素材库真实1536×1024图鉴，来源SHA256 `4e98eae746f1bb0e217e364292a47ba012ebc40c81f0b0a18d19c8513a027f5d`；源码对应本地运行20格：**5张清底候选、15张阻断；经视觉复核合格高清独立PNG仍为0**，所有裁切原生短边145px，且图鉴含文字/多物件状态。
- 复核JSON SHA256 `94808454449490f65e428edda29ddd44afd23c57fe63bd792a6096384e8b724d`；本轮实际候选ZIP已在当前聊天作为文件交付，未导入Godot/Android。GitHub文档 `docs/CAC_REAL_ATLAS_AUDIT_20261016.md` 提交 `968f11c6d8d89db19d23e7ed6a86140fb071980b`。
- 本地源图审计执行结果为拒绝未完成项的预期非0退出码；本地12项合成测试PASS，云端CI运行尚未确认。今后必须先得到**单件/单状态/高原生分辨率/正确透明**的母版，才扩大生产与接入。

## 2026-10-16 / CAC-0007 / 4图鉴与80隔离候选的真实公开上传
- 正式公开库 `main` 上传4张已生成的图鉴JPG预览（提交 `49320befe8759765dc4af1ab1f18fbfd7b23a8a2`），不是无损高清母版。
- 将对应4个ZIP候选包上传公开仓库 `art-source/hd2d/batch-20261016/quarantine/`（提交 `9a222516e31738788f6c2b30aeedc3c20bc750a8`），包含共80个裁切候选PNG和清单；隔离目录不会自动作为运行时素材。
- 新增 `tools/asset_factory/cac_zip_qa.py`（提交 `4cdf7f48a3e20f2dd87241e7a6a3299ec90e73d0`）及回归测试 `test_cac_zip_qa.py`（提交 `e5ddeeb6d2b36061c1a8543eacdef7da92e1416d`）。
- 实际源候选自检发现80/80原生尺寸低于512px，78/80存在可见像素接触画布边界，80/80的PNG为P色板模式而非规定的RGBA格式；哈希完整性检查通过不代表视觉批准。生产级通过0件，Godot接入0件，手机更新0件。
- 以上是已经上传仓库的文件；GitHub Actions线上执行结果未验证，不应宣布CI PASS。下步优先独立高分辨率生图、严格去背景与逐件视觉审查。

## 2026-10-16 / CAC-0008 / 隔离素材入库严格门禁
- 新增 `tools/asset_factory/cac_0008_intake.py`，提交 `a431b54f0d7c63a335b683e2f1b364a4c1138595`。逐个扫描ZIP内真实PNG，检查原生尺寸、原生RGBA、透明像素、边缘触碰，计算SHA256并生成逐件JSON；拒绝ZIP路径穿越及重复路径，任何不合格返回非零退出码。
- 命令示例：`python tools/asset_factory/cac_0008_intake.py --input path/to/01.zip path/to/02.zip --out qa/cac_0008.json`。本轮已提交源码，但**未取得该程序实际运行或新增美术母版的证据**，不得宣称已修复80件素材。正式素材通过数仍0；游戏接入/手机更新BLOCKED。

## 2026-10-16 / CAC-0009 / 首批20件真实候选实际规范化
- 上传 `tools/asset_factory/cac_0009_normalize.py`，提交 `d0174172e2308d41761f05e5d85c232dc63444d4`。本地对真实 `01_village_props.zip` 实际运行，生成20张RGBA PNG及逐件SHA256、原始/输出尺寸、触边记录，打包 `Canglan_CAC0009_20_normalized_candidates.zip` 在当前聊天交付。
- 实际运行结果：20件处理完成，19件原始可见像素触边；补透明边框**不等于修复原始裁断**，没有提高原生细节，视觉批准仍0、Godot导入0、手机更新0。此批只能留在隔离候选库，不得发布为合格素材。
