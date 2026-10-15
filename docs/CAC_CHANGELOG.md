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
