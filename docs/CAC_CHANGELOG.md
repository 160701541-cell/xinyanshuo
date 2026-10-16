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

## 2026-10-16 / CAC-0010 / 独立母版任务生成框架
- 提交 `tools/asset_factory/cac_0010_independent_jobs.py` (`cd94acbf13f3b321cc881883b2fa44e7ec46e846`) 和 `cac_0010_seed_catalog.json` (`15b7032c8dfbcd672a21fe7ecb66f8b117215400`)；将桃树8态、民居5态、灯笼3态、水井3态拆成19个独立待生成任务。
- 生产约束：每件单独构图、12%安全边距、原生1024×1024母版、统一3/4视角和光照、状态唯一ID；任务默认PENDING_GENERATION/approved=false、最多3次尝试。示例：`python tools/asset_factory/cac_0010_independent_jobs.py --catalog tools/asset_factory/cac_0010_seed_catalog.json --out /tmp/cac0010_jobs.json`。
- **本轮实际完成源码与种子目录上传；尚未连接生成服务，未实际生图或运行测试，0件新母版、0件视觉批准、0件游戏集成。**

## CAC-0012 · 官网素材图集站内查看（2026-10-16）
- 实际提交：`65d91e783cc68beefc2ebd1ae61e1fc6e0fbafe5`。
- `hd2d-production-board.html` 接入四组已有候选图集的同页切换和放大/横向滚动检查，提供原图直达；手机无需在多个独立图片标签间跳转。
- 状态：**网页功能已提交，尚未进行浏览器实机验收**。候选图集未通过独立PNG/裁切/分辨率QA，正式合格素材依然为0；此次未新增游戏贴图，也未修改APK。

## CAC-0013 · 统一公开仓库 / Godot HD2D（2026-10-16）
- **唯一后续开发目标仓库**：`160701541-cell/xinyanshuo`，main；停止将新开发修改、自动构建触发或任何后续交付写入私人仓库。
- 在公开仓库创建 Godot 4.4 HD2D 独立工程 `game-source/hd2d-world/`：`project.godot`、`scenes/village.tscn`、`scripts/village.gd`。它通过官网已有图集绘制交互式候选村落场景，能移动镜头、缩放、切换昼夜；历史图集尚未通过正式QA。提交：`8711de0`、`d29e0cf`、`c46eb47`。
- **边界**：公开仓库的此 Godot 子工程不等于已安装旧APK的完整源码，未发布签名APK/PCK；当前无法声明手机游戏已收到该场景。不得修改原有正式签名更新清单或假冒安卓发布成功。
- 实际下一步：只在本公开仓库完善独立 PNG、场景和 CI，确认可公开构建的签名渠道，再交付可安装的 APK。

## CAC-0014 · 仅公开仓库 Godot HD2D 安卓现场验收包（2026-10-16）
- 开发仓库：仅 `160701541-cell/xinyanshuo`；独立 Godot 4.4.1 项目 `game-source/hd2d-world/`。没有改动私人旧工程或既有 `android-preview/latest.json`。
- 真实验收：公共 Godot 场景运行、Camera2D/状态HUD/缩放测试和已上传候选图集 HTTPS 检测 **PASS**，Godot QA run `38815270438`。该验收不是 Android 真机或正式素材画质验收。
- Android CI：`.github/workflows/canglan-public-hd2d-android.yml`，固定官方 Godot 4.4.1 + Android ARM64 debug 导出，独立包名 `com.xinyanshuo.canglan.hd2dqa`，原生导出和ZIP完整性检查通过；run `38815560663` **SUCCESS**，发布操作 **SUCCESS**。
- 实际可下载公开预发布：`https://github.com/160701541-cell/xinyanshuo/releases/tag/hd2d-qa-fadcbae76718`；APK 26964157 bytes；SHA256 `30484fe914935f916a54e5e49bad382b649bace5d1fe7f79674091cf5cb4cc27`。
- 官网 `index.html` 新增单独“HD2D安卓测试版”入口，不混同正式《苍岚》APK。用户**不能用该测试包覆盖原有游戏**，因为它使用独立包名/CI临时调试签名；不改变原版存档及官方OTA。
- **未完成且不能宣称完成**：10月16日聊天生成的青楼、宗门大殿、草房小院、城门等高清PNG尚未实际上传到此公开仓库；场景仍采用4x5历史候选图集，非高质量独立正式素材；安卓真机美术与性能尚未验收。

## CAC-0015 · 可无缝衔接的石砖路进入公开Godot场景（2026-10-16）
- 新增独立生成器 `game-source/hd2d-world/scripts/stone_road.gd`：256×256 RGBA8、64×32错缝石砖、保证首尾两边像素一致；无需 CDN 或图鉴贴图就能在Godot中产生可复用道路材质。
- 真实场景 `game-source/hd2d-world/scripts/village.gd`：组合14块256像素的连续石砖路段，替换旧单色矩形道路；仍使用历史候选图集显示其他物件，没有伪称用户刚生成的建筑已全部接入。
- 新增QA断言：纹理边缘一致、尺寸正确、场景中14块实例存在，手机镜头和HUD仍保留。公开 Godot 4.4.1 自动测试 run `38816588352` = **SUCCESS**，提交 `cfd7efea`、`75d93d49`、`d6881344`。
- Android自动构建与独立测试版预发布 run `38816588402` 已触发，**记录时仍处于队列**。其完成且通过导出后才能宣传新版APK。此更新不能直接作为原游戏签名OTA补丁。

## CAC-0015 交付补记 · 安卓下载已发布
- 本轮最终独立 Android ARM64 QA APK 成功：Godot 场景入口、14块可重复石砖纹理、镜头缩放/HD2D候选图集显示。
- 实际通过 `Godot 4.4.1` 场景 QA run `38816761122`、真实 APK 导出及 GitHub Release run `38816761077`，均 **SUCCESS**。Android export preset 已设置 `permissions/internet=true`；因尚无真机日志，不代表联网素材在所有手机上已得到现场验证。
- 新测试版标签 `hd2d-qa-a447e5712645`，官网首页下载入口已指向新版本。发布页：`https://github.com/160701541-cell/xinyanshuo/releases/tag/hd2d-qa-a447e5712645`。
- 仍为 CI 临时调试签名和独立 Android 包名；与原游戏不同，不是原 APK 的 OTA 补丁。每次重新签名后的独立测试APK也可能无法直接覆盖上个独立版本。
- **不可夸大**：这轮重点是原生无缝铺地纹理，不是用户所发高清建筑母图集成；青楼、宗门大殿、草房小院等仍未成功上传为独立 PNG。程序化石砖外观也需要用户在手机验收，不等于达到高清绘制素材的最终美术标准。

## CAC-0016 · 原手机APK的正式热更新阻塞已由真实签名验收确认（2026-10-16）
- 用户要求唯一开发发布仓库：`160701541-cell/xinyanshuo`。这一阶段不发布任何独立APK冒充原游戏更新。
- 新增 `tools/ota_release_gate.py` 和 `tools/test_ota_release_gate.py`，对应 `.github/workflows/canglan-original-apk-ota-gate.yml`；在**公开仓库**运行真实 RSA 签名验收、原APK的包名检查、版本码兼容、PCK文件SHA/体积/格式和补丁的HTTPS固定路径检查。
- GitHub Actions run `38817753685`：原游戏公钥能成功核验当前 `latest.json` 的旧版签名：**PASS**；原游戏基础版 `versionCode=1176`，更新清单 `revision=167`，对这版原APK应当发布的后续补丁必须至少 **revision=177**。不能直接把 `rev168`~`176` 当作可用热更新推送。
- 运行 `38817871503` 加入真实篡改拒绝回归：签名、SHA、发布URL修改应拒绝（日志与最终状态以Actions为准）。
- **P0实质阻塞**：公开仓库没有完整旧版APK已导出的所有脚本/主场景可编辑版本，不能确认新HD2D场景可在原游戏中显示；缺少公开Actions中可验证的原RSA私钥签名通道。私钥不能上传/提交到GitHub源代码；仅能通过合法密钥存储/机密配置进行签名。
- 因此 **没有** 发布任何伪造 `rev177` PCK，也没有修改正式 `android-preview/latest.json`。后续需在公开仓库提供经过授权的原场景对接层和原签名能力，随后创建可视补丁、运行 APK176 真实覆盖回归，再发布签名 PCK；任何缺项必须阻断发布。

## CAC-0017 · 原APK176主场景PCK替换打通（2026-10-16）
- **只操作公开仓库** `160701541-cell/xinyanshuo`。本轮没有再发布独立APK，也未修改原正式更新清单。
- 下载/校验公开仓库内真实 APK176（sha256固定）并检查原安装包中编译脚本，确认根场景资源 `assets/scenes/main.tscn.remap`、旧主游戏脚本 `assets/scripts/main.gdc`（158404字节）与 `assets/scripts/main.gd.remap` 同时存在。真实 APK176 审计 run `38818638902`、`38818751480` 成功。
- `game-source/apk176-ota177-candidate/` 新增 **不是独立App** 的场景替换资源：覆盖旧 `res://scenes/main.tscn.remap`，新增 `main_hd2d_ota177.tscn`，保留旧 `res://scripts/main.gd` 主游戏入口，增加能切换返回旧世界的 CanvasLayer HD2D 场景以及候选图集。
- `logic-qa/tools/build_apk176_hd2d_overlay.gd` 将 **四个真实资源** 制成 GitHub Actions 构建的完整 Godot PCK；审计校验压缩包索引、源图 SHA、路径与MD5。真实旧APK `.gdc`、`.gd.remap` 均临时从已签名 APK 解压进入 QA 环境，测试加载**客户端原规范场景路径 `res://scenes/main.tscn`**，而非仅检查候选新场景。run `38819379300` **SUCCESS**。早期 run `38819105401` 亦成功，但最终以更严格路径校验为准。
- GitHub Artifact：`NOT-FOR-PHONE-HD2D-ORIGINAL-APK176-CANDIDATE-` 开头的 QA PCK 与日志。**这是 unsigned candidate；不是可供手机安装的签名补丁**。
- 原RSA密钥状况经 Actions 机密配置探测 `38819279400` 明确：已检查四个候选 Actions Secret 名称，配置数量 **0**，与 APK 原公钥匹配的签名能力 **FALSE**。这不是签名算法失败，而是当前公开仓库没有配置可用的**原密钥**，不能伪造。正式 `android-preview/latest.json` 仍保持 `rev167`；合法下一版最低 `rev177`。
- **仍未完成**：原安装包的Android实机运行验证；高清青楼、客栈、宗门大殿、草房小院独立PNG替换（当前PCK仍使用公开旧候选图集）；RSA原私钥的安全注入与最终签名PCK发布。未达成前禁止宣传游戏手机已更新。

## CAC-0018 · WorldX真图像已直接写入原版《苍岚》公开游戏素材目录（2026-10-16）
- 本次不是只写规划：新增可执行 `tools/asset_factory/worldx_godot_bridge.py` 及正式 Actions 工序 `.github/workflows/canglan-worldx-apk176-content.yml`。从 WorldX 官方MIT源库真实样例 `library/worlds/**/map/*.png` 导入地图图像并转换为Godot读取的PNG，禁止将角色sheet混成地图纹理，记录每图来源、尺寸、SHA256；没有调用AI生成接口，不冒称新AI作品。
- **实际写入公开仓库源文件**：`game-source/apk176-ota177-candidate/hd2d/worldx/worldx_000.png`（1,196,876字节）、`worldx_001.png`（954,094字节），以及 `manifest.json`、`UPSTREAM_LICENSE_AND_PROVENANCE.txt`。上游地图真实可用PNG只有2张，不能虚称已产出8张。WorldX复用入口增加到原游戏HD2D覆盖层 `scripts/hd2d_original_overlay_ota177.gd`。
- 原版 APK176 PCK打包器已支持上述WorldX图和原游戏HD2D覆盖层，最终生成**7条**资源内容（若2张图均正常导入；以每次CI索引实测为准）；Godot PCK索引通过。实际WorldX任务 `38822623646` 在GitHub生成并把两张图真实推送到 `main`，不能把仅上传Actions Artifact当作发布。
- **QA反证阻塞**：从真实 APK176 导出 `main.gdc` 与 `main.scn` 后，Godot的最小CI夹具因缺少原游戏全局类注册，打印 `CanglanValleyAtmosphere`、`CanglanGameHUD`、`WorldState` 等脚本Parse Error；因此 **不能判定原游戏完整启动成功**。已将 WorldX QA 改为解析出错即失败，并修复传统PCK QA过去的假绿色；这些失败是已发现缺口而非可交付实机版本。
- **手机交付状态：未发布**。正式更新订阅仍为rev167。后续必须解决原导出主场景执行与正式发布通道，再把独立高清楼宇而非旧JPG图鉴导入后发布新版正式APK/PCK。

## CAC-0019 · WorldX MIT实际地图/NPC/交互/寻路内容导入原版《苍岚》（2026-10-16）
- 工作仓库**仅**公开 `160701541-cell/xinyanshuo`；官方样例来源 `YGYOOO/WorldX` MIT，承认上游样例美术并保留来源哈希，不冒充原创AI画作。
- 真实游戏工程目录 `game-source/apk176-ota177-candidate/hd2d/worldx/` 已推送两张 WorldX 地图图像（流程已提高到2048px最大长边）、六张完整NPC逐帧动画 spritesheet 和 `npcs/npcs.json`（6列×5行，每NPC至少三方向行走）；中国历史样例人物包括王掌柜、李半仙，第二地图是西方奇幻示例，不得冒充中国风高清成品。
- 新增地图交互区域 `zones_000/001.json`：来自 WorldX 原始 `06-elements-scaled.json`、`06-regions-scaled.json`，按实际贴图分辨率重投影。每场景3个真实命名交互点；覆盖层新增点击选择区域、交互按钮展示和真实NPC名字/描述；尚不写入游戏库存和存档，不能谎称已经实现经营效果。
- 新增 `tools/asset_factory/worldx_nav_import.py` 处理 WorldX 实际 `05-walkable-grid.json`，压缩344×192网格为86×48，固定 `0=可通行,1=不可通行`。两场景分别有2043/1474个可行走网格。与NPC控制器寻路接入，限制人物只在真实道路网格上选点/游荡，不再穿墙直线横移。
- 已有WorldX独立内容Godot QA成功实证：`PASS_WORLDX_REAL_GAME_ASSETS maps=2 NPCs=6 walk_frames=36 clickable_hotspots=3`（之前包含交互点测试）；本轮进一步新增导航碰撞点验证，待CI结果；**完整原APK主场景QA仍受导出class_name全局注册缺失阻断，正式APK/热更新没有发布。**
- 构建脚本 `logic-qa/tools/build_apk176_hd2d_overlay.gd` 合并场景脚本、地图、6NPC、商铺热点、寻路网格至原版内容PCK候选，并由 `tools/verify_hd2d_overlay_pck.py` 以官方PCK索引核对MD5/路径。Actions资产工厂新增全流程；启用单一并发组，防止多轮同时提交同一公开仓库，所有成品必须经真实资源验证，不将红色QA伪称手机已更新。

### CAC-0019 实际最新验收增量（CI run 38825337850）
- 已确证`worldx_000.png`、`worldx_001.png`转换后为 **2048×1143**，已更新原游戏公开仓库内真实PNG及哈希来源清单（上一轮1024×572已被新版本替换）。
- GitHub Actions生产的**原版APK176场景PCK候选共19个实际资源**，包含2张HD地图、6张人物动画表、2个商铺交互JSON、2个实际通行网格JSON、NPC元数据与原版场景资源；索引SHA/MD5检查通过。
- Godot 4.4.1实测 `PASS_WORLDX_REAL_GAME_ASSETS maps=2 NPCs=6 walk_frames=36 clickable_hotspots=3`。同时验证NPC出生位置必须在WorldX通行网格、且地图/商铺控件运行。
- **总体CI保持失败而不是假绿**：完整原导出APK `main.gdc` 在最小原二进制fixture仍然缺少真实Godot全局类注册（例如`WorldState`）；因此尚无法宣布安装包可安全热更新，也没有发布`latest.json`。


## CAC-0020 · 原《苍岚》正房：室外 → 室内 → 原位返回，真实 Godot/PCK 功能样板（2026-10-16）

**交付形式**：直接修改唯一游戏仓库的 `game-source/apk176-ota177-candidate`，不是独立HTML、另一个APK或空规划；原安装版尚未收到此更新。

1. **真实游戏逻辑**：新增 `scripts/hd2d_house_portal.gd`。建筑固定 ID 为 `CL-HOUSE-0001`；在原 APK176 场景继承层 `scripts/hd2d_original_overlay_ota177.gd` 内挂载户外建筑及“进入正房”按钮；切入独立室内 Control 场景，提供“离开正房·返回院落”；重复进入/退出有幂等保护，外部返回坐标恢复，原世界不会因室内切换而卸载或重置存档。室内时停止覆盖层外景拖动输入。
2. **真实素材入仓**：CI `Canglan WorldX Kolors - One Real House Interior + Exterior Art Intake` 成功运行 `38875341735`，从第三批原始 WorldX/Kolors Artifacts 按 SHA256 `44d116addb17c5aa5a1f6c7edc85d44132fefdc0eb52ae422b63cc0b71060e3f` 完整恢复室外原图；WorldX 官方模板加载器 + 硅基流动 Kolors 实际生成 `main_house_interior.png`（1024×1024；SHA256 `7f0cfb7886284ad9627b5c411ca4fc1b372f294545508db0bfd0e6008ab0887e`）。两个真实 PNG 已永久提交进 `hd2d/courtyard/`，并留有 `SOURCE_MANIFEST.json`。**图片仍属候选，美术审查未批准；室外原图实际上包含整个院落，室内图仍有檐顶，不得冒充独立建筑或多视角3D资源。**
3. **Godot 4.4.1 真引擎 QA**：`logic-qa/tools/verify_house_portal_content.gd` 在打包的实际 Godot 资源 PCK 上实例化室外/室内节点，测试进入、返回、坐标恢复、重复操作、切回原世界及两张真实图片解码。成功 CI `38875604448` 输出 `PASS_CANGLAN_HOUSE_PORTAL_ENTER_EXIT_RESET_GUARD building=CL-HOUSE-0001 transitions=2 exterior_art=true interior_art=true`。此为**引擎无屏幕自动QA**，不是手机实机截图。
4. **PCK**：修改 `logic-qa/tools/build_apk176_hd2d_overlay.gd`、`tools/verify_hd2d_overlay_pck.py`；正式候选索引允许控制脚本及且仅两张建筑图像。本次只是 UNSIGNED QA PCK，禁止宣称用户手机 APK176 已安装新版内容。
5. **仍阻塞**：原 APK176 编译主场景在CI复原夹具缺少原 GDScript 全局类注册（`WorldState` 等），完整旧 APK 主场景 QA `38875604439` 总体为失败；当前 GitHub 无对应手机旧应用 OTA RSA 私钥，不能合法发布签名热更。即使建筑进出组件 QA 通过，不能当作整个原游戏可更新的证明。
6. **下一步**：保留这次实际可运行的组件逻辑，优先修复旧APK夹具的真实类注册/正式签名通道；同时视觉 QA/建筑单体清底、室内家具互动需独立完成。第一、第二、第三人称镜头尚未实装。

**开发节奏**：本轮按用户允许的稳定并行流程推进：功能模块、Godot 引擎QA、WorldX 实际图片生成三条独立工作线，确有实际资源和测试证据；没有重复盲目生成同一张院落。
## WorldX props batch02 · 新素材生成入口（2026-10-16）
- 当前仓库已有真实V3正房与室内原图；本轮沿用WorldX prompt loader + Kolors，新增院门、石井两件独立候选的有界批次。
- 新增脚本、付费次数上限与画风提示词回归测试、公开Actions工作流；实际模型调用留在仓库Secret所在的Actions环境，每件仅一次，失败停止，最多两次。
- 本地测试和云端运行状态分别记录：本地Node测试1/1通过，脚本语法检查通过；云端生成待运行。生成PNG、视觉审查、透明精修、Godot接入、手机更新均尚未完成，不以新工作流提交冒充素材产出。
- 候选不引用到场景，不修改正式更新清单；原图、提示词、SHA、固定上游commit与run URL可追溯。模型只接收文本，不能声称已锁定参考图。

## WorldX batch02 · 实际运行与视觉拒绝记录（2026-10-16）
- Actions `38875940357` SUCCESS，原图提交 `65a8a35`，院门和石井均实际生成1024×1024 PNG，提示词和SHA已保存。两件各调用一次，没有重试。
- 视觉检查：两张都带有大面积院景、植被和右下角“AI生成”字样；未遵守单件纯色背景要求。两件均REJECTED_AS_INDEPENDENT_SPRITE，正式批准0件，不自动清底或接入游戏。
- 扩量停止：首先解决主体隔离/背景约束；文本约束不能保证参考图条件一致，不能通过无限生成碰运气。未发布手机更新。原始图保持不修改，审查见批次visual_review.json。

## batch02 局部字样修补（2026-10-16）
- 用户要求脚本清除右下角AI字样后进行AI修补。已实际使用内置图像编辑工具分别修复院门与石井；保留模型来源，不冒称人工原创。
- 为避免整图重绘改变原建筑，以脚本仅合成右下角141×56局部补片；原始1024×1024 PNG保持不变，另存repaired版本。两件本地像素差分均确认范围外逐像素一致。
- 原图、AI修补补片、可重跑脚本和SHA报告留存；公开Actions复现处理不调用付费模型。未完成主体独立/透明清底，不等于独立素材批准或手机更新。


## CAC-0021 · 修复原安装包APK176的真正主场景QA阻塞（2026-10-16）

- **根因已定位并修复**：早前APK176入口脚本缺少 `CanglanValleyAtmosphere`、`WorldState` 等全局类不是“旧APK代码坏了”，而是我们错误搭建的QA夹具没有从**原已签名APK176**提取 `assets/.godot/global_script_class_cache.cfg`。专项诊断真实读取APK并证实类缓存4377字节，含缺失类和对应原GDScript路径；GitHub run `38876281621` SUCCESS。**全部来自原APK，未注入虚假的同名替代类**。
- 类缓存恢复后进一步发现原天气脚本真实 `res://shaders/atmosphere/...` preload缺失。CI依照APK原始ZIP资源路径恢复 **全部真实 `assets/shaders/**`**，不伪造shader、不改动原游戏的GDScript。
- 修复原始两条CI：`.github/workflows/canglan-worldx-apk176-content.yml` 和 `.github/workflows/canglan-apk176-hd2d-overlay.yml`。**两条测试均已由红转绿**：
  - WorldX+原APK完整版候选 PCK：run `38876521634` **SUCCESS**，源自真实APK的 `main.gdc` 与类缓存加载 `res://scenes/main.tscn` 成功；PCK索引22条；2张WorldX地形、6套NPC动画、真实室外/室内PNG、正房进出行为均经过Godot资源和实例验证；单独组件测试输出 `PASS_CANGLAN_HOUSE_PORTAL_ENTER_EXIT_RESET_GUARD ... exterior_art=true interior_art=true`。
  - 原APK HD2D入口的较小候选包：run `38876552557` **SUCCESS**，PCK资源7项，原版编译 `main.gdc` + `main.scn` 可装载；未检出脚本解析或编译错误。
- **状态边界必须清楚**：目前完成的是原导出主场景的 `PackedScene` **成功装载验证**，以及正房进出组件实例化自动化验证。**尚未在Android手机上加载、未完成原游戏整场景实例化运行验收，也没有推送正式热更。**
- **真正的发布阻塞仍在**：用于给用户已安装APK176发布revision≥177的原始RSA签名私钥未通过仓库现有检查；只有与APK内公钥匹配的原私钥才能发布可信热更。不可拿新的私钥签名冒充正式补丁；APK覆盖安装还必须满足原Android证书和包名。
- 后续次序：1）真实原APK场景实例化 + 图像验收；2）恢复同一原RSA签名能力；3）构建并发布可被已安装客户端认证的rev177内容，手机实际测试，更新官网与下载/更新日志。

## WorldX batch03 六件道具（2026-10-16）
用户要求继续批量生成。本轮新增炼丹炉、炼器台、晾药架、集市摊位、木推车、落地灯笼六件候选订单。沿用WorldX原生prompt loader与Kolors，每件一次，顺序执行，最多六次请求，失败停止，不自动重试。缩短提示词并强化空白背景，文本控制仍非机器参考图锁定。生成前写请求记录，未完成请求需要检查Artifact后人工恢复，防止重复付费。Node规格回归1/1、脚本语法检查本地PASS；模型产物与视觉QA待云端实际运行。


### CAC-0021增补 · 原 APK176 完整实例化QA严格反证（2026-10-16）

- 新增 `logic-qa/apk176-export-fixture/verify_original_main_live_house.gd` 与独立CI `.github/workflows/canglan-apk176-main-live-house.yml`；恢复原Android APK176导出区**455个真实资源（43,459,834字节）**到临时夹具（保留QA项目入口配置），将真实WorldX室外/室内图和同游戏脚本写入同一候选PCK。run `38876960537` 完成且**严格 FAIL**。
- Godot检测到：`res://addons/terrain_3d/terrain.gdextension` 在Linux导出夹具中缺少兼容的原生扩展，随后 `Terrain3D native library missing` 和部分原游戏场景脚本空节点错误；同时观察到6名WorldX NPC及正房交互节点确已加入游戏主树。
- 这与前述**原游戏PackedScene可成功装载**是两种不同层级测试：`PackedScene`装载PASS ≠ 主场景完整实例化/每个底层3D引擎功能PASS。**不推测Linux缺失自动等于手机Android缺失**；需要验证原版Android GDExtension发布物或兼容Linux测试插件，不得用假的Node替代原生Terrain3D以制造绿色结果。
- 纠正测试输出：将易误导的打印改为 `OBSERVED_APK176_MAIN_INSTANCE_WITH_PORTAL_AND_IMAGES_PENDING_ENGINE_ERROR_AUDIT`，只有所有引擎错误检查清零后CI才打印最终 `PASS_APK176_ACTUAL_MAIN_INSTANTIATED_NO_ENGINE_ERRORS_WITH_REAL_HOUSE`。
- **当前真实状态**：组件功能QA绿色，原APK main资源装载QA绿色，完整原游戏实例化QA红色，永久签名密钥无可用证据，手机原版更新仍未发布。

## WorldX真实参考图试样probe01（2026-10-16）
纠正batch03画风偏离：不再用纯文本冒充参考图控制。保持WorldX+Kolors，将已有院落原图以base64写入真实image请求字段，SHA锁为44d116addb17c5aa5a1f6c7edc85d44132fefdc0eb52ae422b63cc0b71060e3f。只做一张厢房候选、一次生成请求、无重试，模型是否真正有效利用参考图仍必须视觉比对。原图不改，正式发布清单不改。本地Node测试1/1 PASS、脚本语法检查PASS；云端出图待运行。API依据https://docs.siliconflow.cn/docs/api/images-generations-post ，不把HTTP成功等同于画风达标。

## WorldX extract02 配置调整（2026-10-16）
用户要求实际修改。保留WorldX模板加载与公开工厂，只将本工序后端改为图像编辑模型Qwen/Qwen-Image-Edit-2509，从已认可院落原图提取正房，禁止重新设计画风。源SHA锁定、单次编辑、无重试。按官方接口去掉编辑模型不支持的image_size，使用cfg=4，30步。本地规格测试1/1、语法检查PASS。实际画面、同源风格和遮挡缺失仍待云端出图视觉检查，不宣称已解决。

## 画风修正实测：编辑模型与原像素提取（2026-10-16）
- WorldX原图编辑extract02真实运行38879539515 SUCCESS；使用Qwen图像编辑模型，但结果仍为线描重绘，画风不通过，不扩量。
- 随后实际实现extract_source_house.py：从已认可WorldX/Kolors院落直接提取正房可见像素，只添加alpha、不重画、不放大；本地输出532×537 RGBA，自动逐像素确认保留区RGB与源图完全一致。提供浅深底预览和原图SHA/轮廓坐标，零模型调用。
- 这是可见部分候选：轮廓仍为手工近似、细边需修、背面/遮挡部分未补全，不能称为高清完整独立成品。没有Godot/手机发布。新云端工序负责复现并提交真实PNG。

## 正房原像素alpha轮廓edge04（2026-10-16）
根据源图右上飞檐局部放大核对，重新逐段描绘弧形边缘，去除上一版飞檐上方的背景色块、收紧右侧邻屋碎片与台基草地，补回上一版裁短檐尖。真实本地输出523×553 RGBA，保留RGB逐像素一致断言PASS，无模型调用、无放大。深浅底预览均输出；仍是可见结构候选，细部边界、遮挡缺失与游戏验证未获生产批准。后续只能把原生尺寸当原生尺寸，不可声称为1024高清单件。新工作流复现并保存PNG与坐标。

### 2026-10-16 开发节奏与可靠交互增量（持续 QA）
- **用户明确修正工作节奏**：GitHub Actions 同一构建最多每120秒检查一次，其余时间应推进不依赖该构建的实际游戏开发；能稳定并行的任务不必串行等待。对应硬规则更新 `docs/DEVELOPMENT_EXECUTION_RULES.md`。
- 原始APK176 HD2D候选场景的`返回原世界`曾隐藏背景和建筑，却**保留全部HD2D菜单按钮继续挡住原版3D世界的触摸**。已修改 `scripts/hd2d_original_overlay_ota177.gd`：返回原世界后仅保留`重新打开HD2D`按钮，其他HD2D控件全部隐藏；重新打开时恢复。原版`verify_original_main_live_house.gd` 加强测试，确保触控交互不会被不可见菜单截走。
- WorldX NPC 原先始终使用`nav_000.json`，切换到第二个 WorldX 地图区后仍沿用第一张图的碰撞网格。现为 `scripts/hd2d_worldx_npcs.gd` 添加真实地图导航切换：从`nav_000/001.json`逐条验证行/列及0/1语义，验证成功后原子替换地图，重新安排NPC到可行走格子。非法地图不会破坏已有导航；覆盖`verify_worldx_npc_content.gd`增加换图、走位、非法索引回滚和返回旧地图验证。**由于这批NPC像素风与选定国风存在明显冲突，正式HD2D场景仍保持`SHOW_LEGACY_QA_ASSETS=false`，功能准备好不代表允许放出不统一画风。**
- 原版已确认为有效的资源修复仍保留：原APK真实GDScript注册缓存与着色器，Terrain3D插件经 Android ELF SHA-256 完全一致验证后恢复同版本Linux QA插件。Godot 原版场景测试上轮为绿色；最新代码变更必须待本轮CI另行验证。
- **当前仍未完成**：原装APK176可信OTA签名缺原版RSA私钥；虽有rev177真实资源PCK和严格运行QA，也不可发布为手机自动更新。美术视觉不一致、实体遮挡与真第一/第三人称场景移动仍需逐批解决。

## 2026-10-16 · 正式手机APK176资源rev177签名交付链实际接入（严格阻塞可见）

- 用户要求将已通过Godot原版主场景QA的高清WorldX建筑/室内资源**更新进目前已安装的原《苍岚》**，不是另发独立测试APK。新增可信发布脚本 `tools/publish_original_rev177_ota.py` 与Actions `.github/workflows/canglan-original-apk176-ota177-publish.yml`，在当前公开仓库上自动预检、读取固定QA来源 `38882131496` 的原游戏20MB PCK，验证原APK包标识/版本、rev167现有签名、rev177兼容范围、整场景Godot无报错、资源SHA；随后仅用**原APK公钥匹配的RSA私钥**生成签名rev177 JSON，将真实PCK+签名manifest一起提交到官网 `android-preview/`。没有原私钥时**禁止提交**，绝不生成假更新。
- 该签名发布工序实际启动，运行 `38883233952` 因 `BLOCKED_ORIGINAL_RSA_PRIVATE_KEY_NOT_CONFIGURED_OR_NOT_MATCHED` 拒绝发布（首次仅检查四个通用别名），说明之前说的“构建完成即可更新手机”确实不成立。
- **恢复重要历史线索**：原私有签名工程 `160701541-cell/canglan-world` 的 `.github/workflows/godot-3d-android.yml`、`xinyanshuo-p0-rescue.yml` 使用**真实别名 `CANGLAN_PCK_SIGNING_KEY_B64`**，且旧流程曾用 `CANGLAN_SITE_PUBLISH_TOKEN` 推送签名资源。只读核验旧工作流，未读取、输出或复制旧密钥、未在私有仓库开发/发布。将这一真实原始别名加入公开仓库的签名候选名单和两个工作流的Secrets读取；仍以原APK内的不可变RSA公钥DER逐字节匹配为必要条件。无论名称相同与否，密钥匹配失败就拒绝发布。
- 现仍需核验新别名在**公开**仓库是否确有可用Secret；GitHub不同仓库的Secret默认互不共享，不得假定私有仓库有密钥就代表公开仓库有。
- 若新公仓没有匹配密钥，后续需要用户批准**仅使用原私有仓库现成签名服务完成一次rev177签名**，或由用户将真正原RSA私钥安全地放进公开仓库的Actions Secrets（不要在聊天或源码传私钥）。不得自行换一把新RSA、换APK调试签名、卸载旧游戏或冒充手机已热更。
- **正式更新状态**：仍以 `android-preview/latest.json` 实际字段及GitHub Pages远程可访问文件为唯一依据。未验证线上rev177之前一直显示 `BLOCKED_NOT_PUBLISHED`。

## CAC-0022 · **原APK176用户可直接下载的正版RSA签名资源热更新 #177 已正式上线**（2026-10-16）

本条是此日志此前「签名缺失」「没有真正更新」历史状态的**最新替代结论**；之前的CI失败记录保留供审计，但已经不再代表当前发布状态。

1. **恢复真正原RSA签名能力，无新密钥替换**：从用户本人此前持有的备份凭据在受控本地环境完成旧密钥读取，以 OpenSSL 派生的公钥DER验证与已安装 APK176 内不可变公钥逐字节相同，随后仅签署可信资源清单。**原私钥、Android keystore、密码均未进入 GitHub、Actions、源代码、manifest、日志或下载产物；完成后受控工作目录中的私钥临时复制已清除，用户个人原文件保持不动。**公开仓库旧Secrets确为0，但不会再阻挡这次已完成的**一次性本地签名→GitHub安全验签入库**交付。
2. **原游戏真实内容PCK**：采用 Godot 4.4.1 真实原版 APK176 主场景、正房室外/室内进出、WorldX资源验收通过的唯一 QA 构建 `38882131496`，绝非新建无关Demo。已发布的资源PCK长度 **20,361,696字节**（约19.4MiB），SHA-256 `af5e08020e7ae473a31ed2917839ea3544bdf3747b15790bcea49e46a54eb6f3`；签名manifest修订 **177**，严格限定Android **versionCode 1176**、包名 `org.canglan.ancient25d.preview`、官方HTTPS。
3. **正式上线与服务端校验**：签名handoff `release-handoff/canglan-rev177-SIGNED-original-apk176.json` **只包含公开签名与哈希，没有私钥**。正式发布GitHub Actions [run 38884507811](https://github.com/160701541-cell/xinyanshuo/actions/runs/38884507811) 全部PASS，同一次Git提交添加 `android-preview/canglan-content-rev-177.pck` 并将 `android-preview/latest.json` 更新为177。独立外网HTTPS验证 [run 38884890631](https://github.com/160701541-cell/xinyanshuo/actions/runs/38884890631) 实际接收官网JSON确认原RSA签名且版本177、远端PCK整包哈希及长度完全一致，并验证安装包更新器必需的HTTP Range **206 Partial Content / 1,048,576字节**。输出 `PASS_REV177_NOW_DELIVERABLE_TO_INSTALLED_ORIGINAL_GAME`。至此**已正式推送到原游戏更新源**，不再只是PCK候选或空构建。
4. **玩家操作**：保持已安装的APK176不变，打开手机《苍岚》进入 `苍岚·世界更新`，点击 `检查更新`，显示#177后点击 `下载安装资源补丁`。更新后进入原世界可体验受控HD2D/WorldX建筑图与正房室内进出候选；**无需下载另一款APK，更不可卸载旧游戏**。
5. **QA分级保持诚实**：原游戏场景真实Godot引擎加载与屋内进出、资源签名、远端完整包SHA和CDN分块服务均通过；**尚无用户Android手机实际更新成功、加载画面与存档稳定的实机确认**。已发布的WorldX建筑为早期美术候选（场景与家具仍须优化，第一/第二/第三视角未完全落实）；本次发布意味着功能样板正式可供手机测试，不代表最终美术达标。
6. **额外独立验证**：新增真正APK176编译器内`Crypto.verify`协议的Godot 4.4.1签名接受性测试。首次CI识别仅Linux测试夹具缺失Terrain3D本机GDExtension；已按用户APK中Android .so的SHA-256严格比对真实上游v1.0.2后恢复Linux同版插件，避免假造引擎错误、也不改动签名更新；本项最终结论以新的CI结果为准。

对应官网可见版本条目同步进入 `data/updates.json` 与 `data/development.json`，历史旧数据保留。所有研发新内容下次再发，**不再修改rev177已经签名的PCK**；后续修订需使用更高revision和原有RSA签名链。

### rev177 原客户端签名协议最终复验（2026-10-16T10:10Z）
Godot 4.4.1对从**原签名Android APK176**提取的实际`update_protocol.gdc`/`update_channel.gdc`运行`Crypto.verify`、实际已发布PCK的SHA/长度和`ProjectSettings.load_resource_pack`，并装载原`res://scenes/main.tscn`。本机Terrain3D同版校验后，GitHub Actions [run 38885361170](https://github.com/160701541-cell/xinyanshuo/actions/runs/38885361170) **SUCCESS**，输出 `PASS_APK176_PERMANENT_RSA_PCK_AND_CANONICAL_MAIN_SCENE` 与 `PASS_ORIGINAL_ANDROID_UPDATER_NATIVE_GODOT_RSA_REV177_RESOURCE_MOUNT`。因此不仅OpenSSL、也确证**原版Godot客户端验签方式接受rev177发布**。真实用户Android手机下载、存档和画风验收仍待操作。


### 2026-10-16 原版已签名rev177已发布，但用户实图发现视觉QA严重失败（待rev178修复）
- **实际已发布，不再引用旧「rev167尚未更新」状态**：原仓库 `android-preview/latest.json` 当前为 **revision 177**，APK兼容范围versionCode=1176；同目录有真实 `canglan-content-rev-177.pck`（20,361,696字节）。GitHub run `38884507811` RSA签名验证通过并原子发布；run `38884890631` 在正式HTTPS网站验证RSA清单、PCK SHA256与CDN 206 Range；run `38885361170` 用原APK176真实Godot Crypto、原主场景加载验证通过。以上不代表已在用户手机确认更新成功。
- **用户提供真实画面对照**：室内画面左半幅为大面积纯棕空白、右侧只出现屋顶/门廊照片；室外底图是另一画风的WorldX 2D镇图，前景直接贴了1024×1024的青蓝屋顶整院图片（带角落AI生成字样），拼贴边缘明显。尽管Godot功能检查绿灯，这样的视觉质量必须**REJECT**，不能作为最终游戏美术QA通过。
- **实际后续候选修复，尚未替换已签名rev177**：将室外整张院落贴图替换为源图RGB逐像素不变的 `source_edge04/main_house_edge04_candidate.png` 523×553 RGBA独立建筑可见部分，stage 到 `res://hd2d/courtyard/main_house_isolated_edge04.png`；透明区域不再出现原图矩形/角落AI生成字样。室内Control改为顶层局部画布，Sprite2D采用保持比例的**cover铺满**，解决半屏纯色留白（会裁掉部分方形原图，房间原画本身依旧需整改）。Godot QA增加全屏覆盖、源图非1024整张且透明角落检查。
- **迭代签名安全**：rev177已签名清单与对应PCK内容为不可变发布物，不能用新代码直接改写旧rev177 PCK，否则客户端RSA/SHA会拒绝。以上候选变化必须作为**rev178**重新由原APK接受的相同RSA私钥签名并完整视觉验收后才可进入用户手机。原版RSA私钥目前在本会话未取得可重签的可用证据；既有rev177预签数据不等于有rev178签名能力。不得擅自将本候选覆盖进线上rev177。


### CAC-0022 · 用户上传旧画面对比→真Godot图像缺陷修复与二次视觉拒绝（2026-10-16）
- 用户实图：室内左半屏是完全均匀棕色（像素审计在宽度10%–38%、高度46%–88%区域RGB标准差均为0）；室外上层整张1024方院落图带文字水印，与底层暖棕版画风格的WorldX镇图割裂。
- **rev178仅为未签名候选**：原室外全幅正方院落叠加图替换为仓库里已有 `source_edge04/main_house_edge04_candidate.png` (523×553 RGBA，原像素提取)，正式PCK构建与三个QA流程现在将该透明源图打包为 `hd2d/courtyard/main_house_isolated_edge04.png`。原图仍保留作溯源但不再显示整幅带水印的图片。
- 室内Canvas改为独立顶层Control，房间PNG用center+uniform cover铺满景框，不再以错误父级偏移导致左半屏空白。新建 `tools/qa_worldx_house_screenshots.py` 用图像采样识别大面积纯色室内；该检测已用用户提供的上一张截图做过**失败回归**，确认会将旧缺陷打红。真实引擎画面自动化改用 `workflow_run` 接续成功的原版主场景QA，不需聊天会话每秒轮询。
- 功能与引擎 QA：新原版完整Main+rev178原 PCK run `38887138760` SUCCESS，候选SHA-256=`71e194a2fffa4308802d2cafd0b1995cbe1e5fb47904c3367c106dcb3083ff1a`，未签名大小21,019,200字节；进出组件 run `38887094538` SUCCESS；WorldX内容 run `38887094598` SUCCESS。
- **真实Vulkan截图 QA** run `38887506246` SUCCESS，1280×720两帧可下载：室内纯色区域指标从0提升至 `[71.75,48.25,45.75]`；全屏照片不再只占右边；室外独立房图的矩形边及原图右下水印消失。这个绿灯**只说明空屏、资源格式和布局通过**。
- **最高级艺术QA仍REJECT**：新外景虽然无矩形接缝，但冷青高清正房依然是从写实图上抠出来的，放在暖棕版画街道上非常割裂；新的室内只是一张近距离木梁/窗墙照片，画面没有清晰俯视地板和独立家具，仍无法当作真正可自由行走室内。左上功能测试HUD也不适合正式游戏。不得将这两个真截图的绿灯当作美术完成或手机版本更新成功。
- **发布隔离**：线上已签名rev177完全不动；rev178当前只有GitHub Actions未签名PCK候选和截图，缺乏本轮艺术验收与新revision对应RSA签名，**绝不能把源码变更描述为已传到用户手机**。

### 2026-10-16 玩家截图反馈：优先让游戏真正有内容
- 用户展示的两张《苍岚 HD2D素材库》大合集是**素材概览/概念排版图**，不是已经拆成透明背景、带碰撞、能交互的独立游戏资产。不能将海报中的所有建筑/NPC/家具误报为游戏实装。
- 真实原版APK176 HD2D截图显示：WorldX地图仍是平面贴图，外置正房与场景画风割裂；进入室内时出现巨大的空白棕色区域，图片被裁切或布局不正确。此前“Godot测试通过”仅说明场景可以启动、切换，不等于画面合格，也不等于手机已收到更新。
- 为解决“只有图片，没有内容”，本次修改 `scripts/hd2d_original_overlay_ota177.gd`：不再因`SHOW_LEGACY_QA_ASSETS=false`一起屏蔽WorldX六名NPC，实际调用`_add_worldx_npcs()`，使NPC的移动/点击及地图导航能够在HD2D中运行；继续隔离黑底旧图集与不协调的石路。**此修改已经提交，尚待新的真实运行与画面验收；NPC风格暂未达最终标准。**
- 发布界限：尚未拿到原APK的RSA私钥，`tools/publish_original_rev177_ota.py`仅是候选签名发布工具，**绝不可宣称已推送到手机**。必须有同一原版公钥验证通过的签名PCK，才能发布rev177；不能把未签名PCK或新签名APK当成原游戏更新。

### 2026-10-16 玩家质疑截图后的严格美术审计与实际修复增量
- **线上版本状态**：在仓库 `android-preview/latest.json` 实际读取为**已经使用原版RSA签名发布的rev177**，**不是**早期日志所说的rev167。用户的旧APK176可通过游戏内「世界更新」检查与安装 #177；当前缺少来自用户手机的下载安装完成凭据。**已签名rev177不允许热替换**，后续视觉修订必须使用合法rev178和原RSA匹配私钥重新签名。
- **用户发图的严重问题**：原测试版室内左侧纯棕大空白、另一半是被裁切的屋檐照片，室外是暖色WorldX平面城市与冷青高清正房强行贴合。新rev178真实Godot运行截图（CI `38889095820`）确认左侧空白虽已修复，但仍存在**室内没有地板/可交互家具，玩家与NPC悬浮于近距离门廊照片前，外景建筑依旧画风割裂**，绝不可称美术QA合格，也不能说rev178正式推送手机。
- **本次代码修复**：针对新截图中NPC在室内墙面上漂浮的问题，修改 `scripts/hd2d_house_portal.gd`：进入室内时隐藏完整WorldX室外图层（含NPC与交互点）并使室内控制层z-index高于NPC（6），退出重显原场景；原版PCK自动组件QA加强`outside.visible`及层级断言，真实Vulkan截图QA增加室内不得显示室外地图的断言。属于具体问题修复，不伪称完整艺术质量达标。待对应QA绿灯及室内真正场景素材通过后，再评估新版签名热更新。

## 2026-10-16 / CAC-PROC-001 / 大量场景与建筑改用程序生成（公开工程）

- **用户正式改变生成策略**：停止围绕低合格率高清贴图持续重复卡住，优先通过可复现算法创建大规模村镇、不同类型建筑与室内场景，物品/道具必须独立可交互。
- **已实际上传代码**：`game-source/hd2d-world/scripts/procedural_building.gd`（程序屋顶、瓦、门窗、灯、损伤）、`procedural_prop.gd`（树四季/成长、竹、井、灯笼、推车、木桶、摊位、田、石、座椅）、`procedural_city.gd`（种子、6×4院落、街巷、河岸、桥梁、道路、分区、唯一实体表）、`procedural_interior.gd`（同屋ID关联、单独编号室内家具），并将 `village.gd` 的旧远程JPG图集预览换成可点选、开门进入室内、四季/昼夜/建筑损毁/拖动缩放的运行入口。
- **QA代码已更新**：`tests/scene_smoke.gd` 检查24院落、至少50建筑、100独立物件、唯一ID、同种子复现、门及损伤、季节、夜灯、室内/家具、256px石路无缝和缩放。两个公开HD2D工作流改为 `cancel-in-progress: true`，避免每个中间提交排队重复构建；引擎工作流不再请求旧图集作为交付证明。
- **本轮真实状态**：以上文件已提交公开仓库main；引擎实运行结果和真实渲染截图在此记录阶段**待CI证据验证**；独立debug APK能否成功生成、视觉审美及Android性能/触摸操作**仍待验**；未更新旧正式签名APK176/OTA177、玩家存档或正式分发清单。
- **有意保留的缺口**：画面仍是原创程序几何，不可宣称达到参考国漫手绘品质；程序建筑暂不是原游戏权威库存/产权/建造系统的真实实体，不具备NPC路径、室内碰撞、破坏持久化。后续优先用真实Godot渲染截图定位造型问题，优化建筑层级/阴影/地物穿插，再做接入原客户端的公开源兼容回归与真机对照。

## 2026-10-16 / CAC-3D-001 / 开源原生3D重新成为唯一开发主线

- **指令改变**：用户明确停止HD2D，恢复《苍岚·人生世界》之前的3D方向，要求代码/模型能开源尽开源并将世界地形、古风院落、建筑内部、NPC、道具尽量工业化自动生成。旧HD2D方案标为SUPERSEDED，历史文件保留不再扩展。
- **已真实提交公开 `160701541-cell/xinyanshuo` 的 native 3D Godot项目**：`game-source/godot3d/project.godot`、`scenes/main.tscn`；脚本 `world_rules.gd`、`terrain_chunk.gd`、`building_factory.gd`、`prop_factory.gd`、`npc_agent.gd`、`interior_factory.gd`、`world_main.gd`。启动场景种子 `20261016`；场景规则产生5×5个可替换的带碰撞地形块、20院落＋60建筑、约80独立身份/职业NPC及超过600个独立ID生态与生活道具，通过MultiMesh绘制高频重复物体。所有量为**生成目标/游戏代码中真实创建对象的预期计数**，本轮Godot自动化实测结果尚不可引用为已通过证据。
- **真正的3D模型工厂**：新增 `game-source/godot3d/tools/generate_glb_pack.py`、`requirements-models.txt`、`tests/test_generated_glb.py`，在同一构建产线产出18建筑、10自然道具、10NPC职业的38份 GLB **模型候选**，逐件SHA校验，不能把三维人体刚体替身冒充有骨骼/真实动作捕捉的成品角色。当前聊天另已在本地以 Python/trimesh 真实导出38件、核对SHA并生成候选ZIP（共约1.54MB GLB）；候选尚未获得人眼视觉批准。
- **源代码和兼容权限**：新增MIT许可证、来源清单 `opensource/registry.json` 和第三方许可说明；Godot/MultiMesh/FastNoiseLite等标准组件已接入，Terrain3D 1.0.2、Kenney/PolyHaven/ambientCG仅列作候选，**未安装/未导入**。所有新上传仅公开源码，无旧私库提交、签名密钥、隐私或不明授权资产泄漏。
- **真实构建QA路径已接入**：`tools/audit_public_3d.py`、Godot `tests/world_smoke.gd`、`tests/capture_real_frame.gd`，加强 `.github/workflows/canglan-public-qa.yml` 实际生成GLB/导入/逻辑/Framebuffer画面QA，新增 `.github/workflows/canglan-public-3d-android.yml` 单独ARM64 QA APK构建，独立调试签名不会覆盖用户原APK176。新工作流实际执行是否PASS、画面截图是否达到用户参考美术、Android安装/帧率/发热、本次3D模块是否整合回原安装游戏，均是**PENDING/UNAPPROVED/NOT_RELEASED**。旧用户安装包和签名内容包保持不变。
- **待改进问题不可隐藏**：当前三维建筑为程序顶点色基础几何，NPC仍是未绑骨骼/表情的人体候选；没有生活物理工序、存档权威数据、完整人群寻路/战斗、多人同屏性能达标证据。下一优先级是读取真正Godot CI与截图并修复语法/绘制问题，通过手机质量门禁后再增量迁移到原游戏并出正式签名更新。

### CAC-3D-002 / Original 3D 实际源码兼容迁移（2026-10-16）

这一增量**不是从零臆造全部旧版本**：经 GitHub 只读核对原私有 `160701541-cell/canglan-world` 的真正 `godot3d/project.godot`、`scripts/world_state.gd`、`scripts/entity_codes.gd`、`scripts/terrain/heightfield.gd`，审核无显式密钥字符串后将后三件原始 GDScript **逐字节复制** 到公开 `game-source/godot3d/` 中。公开blob SHA与旧源一致：WorldState `f7174a7b59370deb456906d8bf8457c9d13fb52d`，EntityCodes `7d82d7de396208c799d4e5bac23741d1d436a71e`，原2km山地高度场 `7c950e459af84c57557abdb31b7b4f23266e7347`。原私库没有收到本次提交，密钥/旧存档/商业素材没有上传。

`world_main.gd` 的80个三维NPC已经改为由**真实原版** `WorldState.create_actor` 分配 `actor_...` canonical ID，再读取原版 `NPC-HX-...` 公开ID作外观节点，保留空初始库存，不凭空生成可制造物料。`world_state_bridge.gd` 验证同步移动速度、实体类型和ID，禁止远距离瞬移与无权修改库存；原始世界有 `serialize/restore` 可作为持久化协议基础。新 `world_rules.gd` 采用真正旧版 Terrain3D `heightfield.gd` 的南北/西山脉和城池海拔算法，再按新场景坐标降到y=0绘制分块碰撞网格；渲染仍是Godot SurfaceTool而非将未经真机验证的Terrain3D GDExtension假装已安装。Godot引擎运行/旧档多版本回归仍 PENDING；尚未从旧版本整体迁移原场景、原UI、原资产、原NPC生活工序或原签名发布链，因此**不是原APK已正式升级**。

## 2026-10-16 / CAC-3D-003 / 恢复开发：原生3D场景与Qwen3离线AI同包构建

**用户指令**：「先接入游戏，一次性把AI本地模型也接入进去」，随后要求「恢复」，应从该任务断点继续，而不是回到 HD2D/重新讨论模型选型。

### 实际已提交代码（不等于Android已安装）

1. **离线推理真实Native实现**：`game-source/godot3d/local_ai/native/canglan_local_llm.cpp/.h` 和 `register_types.cpp`，CMake 源码锁定开源 `llama.cpp b6000` 与 `godot-cpp godot-4.4-stable`；C++后台单工作线程读取私有目录GGUF、调用 `llama_model_load_from_file/llama_decode` 并发送原生信号。无HTTP请求、云备援或“假生成成功”对话。CPU默认3线程和2048上下文，真实手机耗时/峰值RAM未知。
2. **真正模型资源与版权**：`local_ai/model_manifest.json` 锁定 Qwen3-0.6B Q4_K_M 量化GGUF、**484MB级别**、SHA-256 `7af3fdf842f87b24672f8a7f1dd50404043f0bfb71093ff91c31d2b49df4631d`，Apache-2.0，权重不放入Git仓库。经上游 HuggingFace 页面交叉核对准确文件哈希和许可；CI在构建时下载、核验并将模型及上游Apache/MIT许可证打入APK。默认联网权限仍关闭；手机仅从APK提取到应用私有目录，文件检验失败应报告不可用。
3. **接入真实Godot场景/NPC**：`scripts/local_ai_service.gd` 处理约484MB GGUF的2MiB块式本地复制、增量SHA256校验、加载状态、失败告警；`world_main.gd` 创建 `OfflineLocalAI`，提供手机聊天输入/模型状态，交互半径7米，按原 `WorldState` 身份ID找NPC、限流串行对话。回复仅为文本，**禁止把模型猜测当成授权交易/制造/真实库存行为**。离线模型加载失败时游戏世界仍应继续运行。
4. **程序化模型真实嵌入**：`building_factory.gd` 有18栋建筑候选GLB导入路径，新修改 `npc_agent.gd` 实际将10种职业的GLB模型作为80个NPC对应可见模型（导入缺失时回退程序人体）；`tests/world_smoke.gd` 在模型存在时新增80个GLB真实场景节点检查。GLB NPC未绑Humanoid骨骼，简单视觉浮动并不能冒充完整人物骨骼步态。
5. **构建门禁**：`.github/workflows/canglan-public-3d-android.yml` 先生成38个GLB，下载与校验真实Qwen GGUF、编译 Linux 与 Android ARM64 原生 `llama.cpp` GDExtension、运行 `tests/offline_ai_inference_smoke.gd` 实际生成中文回复、`tools/audit_local_ai_runtime.py` 核对SHA和AArch64 ELF，然后引擎导出Android ARM64独立调试APK，核对压缩包内原生 `.so`；任意一步失败即不发新版。源文件许可与SHA记录同步至 `opensource/registry.json`、`local_ai/NOTICE.md` 及 `tools/audit_public_3d.py`。
6. **源码修复**：已修正 Godot `Node` 类型不能静态访问脚本自定义信号的问题（使用动态 `connect`）；并确保导入的人物是3D模型节点、模型缺失时不用假资产。

### 状态矩阵（严禁混淆）

- `PUBLIC_SOURCE_COMMITTED = YES`：本轮公开GitHub实际源码已上传。
- `REAL_GLB_CANDIDATE_ARCHIVE = 38/38`：会话本地验证ZIP中38个文件的 glTF魔数和GLB容器长度一致，**并非国漫画质审核通过**。
- `MODEL_SHA_UPSTREAM_VERIFIED = YES`：远端模型页明确提供的文件哈希与清单一致；**不代表GitHub Actions已经下载成功**。
- `LINUX_CPP_BUILT = UNVERIFIED`，`ANDROID_ARM64_SO_BUILT = UNVERIFIED`，`GODOT_3D_IMPORT = UNVERIFIED`，`ON_DEVICE_LLM_REPLY = UNVERIFIED`，`ANDROID_APK_PUBLISHED = UNVERIFIED`，`ORIGINAL_SIGNED_GAME_UPDATED = NO`。
- `VISUAL_QA = UNAPPROVED`；`ANDROID_RAM_FPS_THERMAL_TEST = NOT_RUN`；早期正式APK、其PCK与玩家存档未动。
- 下一优先级：**读取本次真实CI/job日志和Godot截图**，按真实编译/解析失败逐项修复，确保独立AI+3D APK实际可启动和跑中文对话，再走原安装包签名/资源兼容流程；不得仅靠commit宣称手机已升级。

本轮不触碰原私库版本构建、旧签名密钥和用户存档；停止HD2D路线继续有效。

## 2026-10-16 / CAC-3D-004 / 下一步：依据真实GitHub Actions错误日志定点修复

**不是“正在处理”的空进度。本阶段读取了公开Actions真实作业ID和完整失败日志，现已在公开仓库实施对应修复。**

- 公开Android/离线AI构建作业 `38900955107`，失败 `tools/audit_public_3d.py: scripts/prop_factory.gd: missing entity_id`。实际独立道具的稳定身份在 `_entity(id,...)` → `entities[id]` 数据字典，不是渲染节点 `entity_id` 元数据。修正源码静态QA，不伪造 `entity_id` 渲染器标识。对应提交 `8e08c8932e4db8a226daa31d71a0c9c6c7f83d0c`。
- 原生3D严格 QA 作业 `38900513434`，报 `generate_glb_pack.py line 162: assert combined.vertices.shape[0] > 20`。单个盒子等低模可以合法使用8顶点/12面，误判有效几何。已改为 `>=8 vertices, >=12 faces` 且继续执行 `tests/test_generated_glb.py` 容器/SHA/网格测试。提交 `d3ca39e9ee1a3edf378a704be74145d4bb1e77ce`。
- 最新初轮严格Godot作业 `38901239353`：**真实引擎已成功导入、创建25块地形/80个院落建筑/80原版WorldState NPC/937个GPU模型实例**。然而 `world_props=586` 未达到`>=600`硬门槛，`tests/world_smoke.gd:51` 失败，严格拒绝放行。已在 `prop_factory.gd` 将可生成林木采样420→480；实体仍有稳定ID和实际3D MultiMesh，非简单降门槛；待重新运行确认。提交 `e88e223a79ae051b09164a6d8e4ff922e14bcbc9`。
- Android AI构建作业 `38901239340`：实际Qwen GGUF**从上游成功下载且通过SHA256校验**，实际 CMake/Linux 编译 llama.cpp 后在 GDExtension C++ 环节失败：`fatal error: godot_cpp/classes/node.hpp: No such file or directory`。根因是旧Godot 4.4 CMake 目标是 `godot::cpp`（别名 `godot-cpp.template_debug`），不是无头文件传播的裸 `godot-cpp` 链接文字。已经更改 CMake 真实target为 `godot::cpp` 并增加缺失时的 fail-closed 错误，提交 `8f20a0a8372490aed63d2f8bcb84e81eee6842aa`；另将头文件 `godot_cpp/variant/string.hpp` 显式包含，提交 `dfc46758f13a47c95e85d2ab21f00077e618ba85`。
- 之前 Android Workflow YAML 曾在补包检查时出现重复段、破坏shell正则，已将 APK 导出后的剩余工作流区块全部重建并经GitHub识别执行，提交 `a5fbad6a59918a31f74e17b8819ccc4ac665fcb8`。
- **结果边界：** 修复已经提交，不等于本轮重测通过。上述历史作业均为失败；修复后的严格场景QA运行 `38901820922`、Android AI+3D一体化APK运行 `38901821292` 已触发，当前需要读取它们的最终结果。没有成功的APK下载和手机实测；原APK、原签名与玩家存档均未修改。

## 2026-10-16 / CAC-3D-005 / 按实测修复玩家碰撞检索与600+实物门禁

- 严格Godot引擎真实运行工单 `38901820922` 显示，全部38个程序GLB生成成功、原世界身份/角色已在真实场景启动；实际计数：地形块25，真实建筑/院落80，NPC80，原版WorldState实体80，**独立道具627**，MultiMesh GPU实例**1025**。此前 `world_props 586 < 600` 的QA缺陷已被真实修复。
- 此次未通过下一门槛：`tests/world_smoke.gd:97` 报 **Player has no physical character collider**。查代码：`_build_avatar()` 创建 `CollisionShape3D.new()` 并挂至 `CharacterBody3D`，但是程序化子节点未显式命名；测试的 `get_node_or_null("CollisionShape3D")` 因Godot自动命名找不到它。修复方案保留原有物理碰撞器，仅新增 `shape.name="CollisionShape3D"`，不将QA换成“存在即通过”的假判定。
- 实际修复提交 `8376ccb6f05ccd694b74ba2bfbe93595dd9798cc`（先在 `fix/cac-3d-qa-collider-native-20261016` 修复，随后以预期父SHA的非强制fast-forward将该提交发布到 **公开main分支**）。
- main最新严格3D实测任务 `38903246205` 与含本地Qwen/Android ARM64任务 `38903246208` 已由实际代码变更触发，尚无成功结果。**Android签名原版APK未被替换**，人物绑骨/国漫画质和手机性能仍未完成验收。

## 2026-10-16 / CAC-MALE-001 / 男平民母版V1真实建模、接入游戏与测试

用户在 `A 女母版 / B 男母版 / C 建模生产清单` 中选择 **B**。本轮执行男平民母版**真实建模与Godot源码集成**，不是只交口头规格。

- 原创参数化主脚本：`game-source/godot3d/tools/male_civilian_master.py` (首次真实GitHub提交 `14d0bc3978ae3d7ececffa8f01158e0beb71e6c8`, 后续为调整袖子比例提交 `5807c12d9ea2916e700bd50a984fd1c0792135d7`)。同一身体形体/交领/腰带/四肢/耳眼鼻嘴/布鞋/颈部/帽檐挂点规范，生成村民、商贾、学徒、卫卒、书生5款颜色和职业模块；主体留骨架挂点元数据，但**并未做蒙皮/真正Humanoid动作**。
- 5个真实GLB已经在本地Python `trimesh` 实际导出并逐件通过 glTF魔数、容器长度、SHA256、载入三角网格、尺寸校验。各模型分别约1716—1808个三角面；人体高约2.44m；所有新角色采用灰青、灰蓝、灰粉、深青、浅灰绿低饱和色系。模型/源码/设计清单/预览PNG存为本轮可供用户查验的ZIP。预览只是软件生成的静态候选渲染，**不是Godot引擎截图**。
- 工厂集成：`tools/generate_glb_pack.py` 从38件扩展成 **43件真实GLB**，新增 `npc/male_villager_v1.glb`、`male_merchant_v1.glb`、`male_apprentice_v1.glb`、`male_guard_v1.glb`、`male_scholar_v1.glb`；`tests/test_generated_glb.py` 新增男女母版边界/文件数、面数、世界尺寸、元数据和五种文件SHA验证。
- 运行时真实接入：`scripts/npc_agent.gd` 对职业索引1、4、6、8（商人、学徒、卫卒、书生）优先导入新男母版GLB，保留旧模型作为异常回退，不强迫其他身份变成男性；由原版 `WorldState` 管理NPC canonical ID，不触碰库存、存档、签名。Godot `tests/world_smoke.gd` 新增对应职业实例元数据和GLB节点断言（预计32/80居民属于这4职业，须以真实Godot测试结果为准）。
- 工业化规范已提交 `docs/CAC_MALE_NPC_MASTER_V1.md`，描述层叠交领、围裙挂点、面部最小信息、衣袖非圆柱轮廓、实际共享身体测量、职业可换件和后续真实蒙皮/动画质量门槛。
- **真实状态**：本地5个GLB文件可用性确认；公开GitHub源码已提交并触发后续CI；但生产仓库43件联合生成、Godot引擎实时全量导入、Android APK/旧APK热更新、最终画风审批，在本次提交时仍须看新CI的真实结果，不可假称全部通过。
- 其他QA背景：修复后的原3D场景25地形、80院落建筑、80角色、627道具/1025批量实例曾经在真实Godot CI启动并通过主体场景，后续实际严格截图步骤失败；含Qwen本地模型Android流程在真实推理冒烟前仍有失败，暂不声称已可安装。男母版不会解除上述现有发布阻塞。

### CAC-MALE-001 / 本轮真实CI证据补录

公开GitHub Actions严格3D作业 `38905880781`（`aee58119cf1c5d9af1dbf3b05cc256346b832a66`）中，已明确执行至 **Capture actual 3D gameplay framebuffer on Mesa software GPU**，前置批量生成43份GLB/模型校验与**Godot完整场景冒烟全部通过**；原始日志逐字打印 `PASS PUBLIC CANGLAN 3D GODOT SCENE: 25 live terrain chunks / 60 houses / 80 NPC / 600+ props / indoor furniture / door / collapse / stable IDs`，启动统计 `world_props=627`、`batched_instances=1025`，这也意味着 `world_smoke.gd` 新增的4个男母版职业GLB真实场景引用断言已通过。

但**整条严格CI尚未通过**：后续 Mesa/Xvfb 真正取帧阶段存在 `ERROR: Condition "status < 0" is true. Returning: ERR_CANT_OPEN`，且QA策略遇到 `ERROR:` 必须失败，不许跳过。需单独定位是软件GPU截图打开错误或其它渲染资源错误；这是截图QA的BLOCKER，不能宣传所有测试绿灯。Android ARM64+Qwen GGUF整包仍未通过真机验收。

## 2026-10-16 / CAC-LIFE-001 / 游戏玩法优先：WorldBox式活世界模拟第一轮

用户明确反馈：不必继续追求复杂写实美术，甚至使用像素或WorldBox式方块世界，只要《苍岚》玩法丰富、世界有内容。研发优先级已经从纯美术转为“玩家行为—NPC生产生活—真实资源变化—村镇建设—反作用于世界”。不更换原3D引擎及原版WorldState身份系统，不再为母版图消耗主线。

**实际提交：**
- `game-source/godot3d/scripts/worldbox_life_sim.gd`：独立Godot `RefCounted`确定性经济仿真，真实资源粮/木/石/泥/水/食物/铜钱；NPC年龄/饥饿/精力/心情，农人、樵夫、采石、厨师、陶工按时间产出，夜晚休息和一日三餐消耗，食物短缺带来真实数值后果。玩家申请房屋、田地、工坊必须原材料充足且一次性扣减，有建设完成记录。村庄繁荣由住房容量、田地、工坊、食物不足驱动，有限长度事件日志便于UI和存档。
- `game-source/godot3d/scripts/world_main.gd`：**确实接入同一个Godot3D实时世界**，80个原WorldState NPC保留原身份编码，另建立独立生活生产索引；按职业分工，现有3D HUD显示村民、日时、繁荣、粮木石粮食等库存，虚拟时间每小时推进一次。AI文本对话不再承担经济权威。
- `game-source/godot3d/tests/worldbox_life_smoke.gd`：演算25小时，检查4种职业生产、建筑前材料扣除、非法无资源建设拒绝、完成后房屋+1、库存不负、事件记录、重复随机种子/同操作序列可复现。`game-source/godot3d/tools/quality_gate.sh` 已加入此场景真实Godot测试，失败阻止发布。
- **限制与边界：** 这是生活模拟第一层而非完成的WorldBox游戏；目前NPC行走的美术行为与职业生产通过稳定ID对应，但还没有寻路工作站/野外真实伐木对象耗尽机制、天气灾害、国家战争或玩家建筑UI；村镇初始物资暂是测试村落的预置资源（不是无中生有交易）。仍需Godot CI实测确认脚本全部无解析/类型错误，当前只确认源码提交，不能宣称整包通过、手机已更新。
- **下一里程碑**：优先“砍树→背木回村→建房→村民搬入→种田→收获→做饭→吃饭”可被摄像机看到的完整闭环，再扩充交易/研究/灾害，最后统一美术。不再拿造型脚本替代游戏内容。

## 2026-10-16 / CAC-LIFE-002 / 首个玩家可触发可见闭环：砍树、背运、建屋、收粮、做饭、进食

**真实源码提交，不是已经安装的APK：** `scripts/worldbox_life_sim.gd` 新增注册世界天然资源节点 `natural_nodes`，每棵树有限剩余容量；`gather_to_actor` 只改变实体剩余与人物携带物，**不向村庄库存瞬移木材**；`deliver_carried` 才允许木材入村仓，携带物不允许重复入库。另提供 `harvest_field`（田地每天一次有限收割和次日重生）、`prepare_meal`（2粮+1水→3饭）、`feed_citizen`（消耗1饭，降低饥饿），所有输入经过实体所属村庄校验，事件变更写入有界历史。

`scripts/worldbox_visible_worksite.gd` 在原Godot 3D世界的玩家附近真正放出有限大树、砍后树墩、几根可见木头、具有行走动画/实际抵达要求的仓库搬运工、真实扣资源后下一游戏小时出现的新房、可收割农田、做饭后的可见食物。此示范节点是**自带工人的可见生活工业循环**，非全世界NPC AI通用行为；碰撞、正式建筑装修和职业寻路尚未验收。

`scripts/world_main.gd` 把工作场景加在已有原版3D主场景上，新增6个玩家可触控动作按钮（砍树→木材入库→建房→收粮→煮饭→进食）和错误反馈，没有另建HTML游戏。主NPC身份/WorldState保持不变，动作权威始终在经济模块。素材暂采用简洁低模，不再被错误宣传成美术达标。

`tests/worldbox_life_smoke.gd` 新增可重复确定性测试：每棵树木材只可被搬一次，采收时村库不增加、仓库交付才增加，村庄木材/粮草负库存不被允许，田地不能重复收割，做饭/进食耗材准确，以及两次同seed、同操作的快照严格一致。`tools/quality_gate.sh` 执行该真实Godot测试，失败即阻止正式QA。

**当前状态**：文件已进入 `160701541-cell/xinyanshuo` main，最新严格QA运行号 `38910293756`，Android 3D+Qwen 构建运行号 `38910293606`。直到看到成功的作业报告前只称“已提交等待验证”，并非实机安装完成。原版游戏APK签名未动。下一步包括读取上述真正CI日志、修复运行时缺陷、为可见工人添加寻路/全量NPC分工、使材质到WorldBox风格统一，且正式更新之前必须检查兼容和签名。

### CAC-LIFE-002 / GitHub正式Godot引擎验证结果（日志已读取）

作业 `38910293756`（严格QA job `117004255932`）**在真实Godot 4.4.1 Linux headless引擎中完成并通过了**：
- 43件GLB工厂生成与审查；程序场景中25块地形、60栋房屋、80名NPC、627件独立道具、1025批实例，完整主场景测试：`PASS PUBLIC CANGLAN 3D GODOT SCENE`。
- 新生活/生产演算测试：`PASS CAC WORLD LIFE SIM: 4 jobs, real resource costs, 25 ticks, deterministic state, new house, finite tree, real carrier, regrowth, cooking/eating, no negative stock`。
- 原版WorldState身份与现有3D场景仍通过冒烟门槛，玩家可见工地的按钮/几何物已作为主场景加载，仍须手机目视验收。

**但此GitHub严格QA整体仍然为FAILURE**，后续真实GPU Mesa/Xvfb截图步骤返回 `ERROR: Condition "status < 0" is true. Returning: ERR_CANT_OPEN`，并被防绕过策略阻拦。这不是经济演算失败，也不能说“所有QA通过”。Android GGUF和正式APK结果仍未验证。

## 2026-10-16 / CAC-LIFE-003 / 村民开始自发劳动（真实Godot主场景增量）

用户继续要求推进WorldBox式玩法。核心目标不是“增加背景NPC数量”，而是**能从实际资源节点出发、靠自身走到地块、携物回家、只有到仓库才能完成资源入账**。

### 已经实际提交的代码

- `scripts/autonomous_village_director.gd`：新增主世界自主职业调度器（Godot Node3D），以玩家原有80名NPC作为工作执行者，目前为10人有限范围的自主工组：8名樵夫/石工、2名农人。每个人独立分配职业资源目标、家附近交付点和行动阶段 `to_resource → to_depot → to_resource`，农田用 `waiting_field` 等到次日可再次收获。实体树/石头/农田拥有稳定的资源编号与渲染节点；每棵树/石有9单位可采存量，消耗殆尽后视觉节点消失；农田每天产出有限。
- `scripts/npc_agent.gd`：增加 `assign_work_destination` / `cancel_work_destination` / `reached_work_destination`，已分配任务的角色由工作命令接管目标，**保留非工作NPC原先日常漫步行为**；离摄像机190米远时不再停止任务逻辑，只关闭远距可视化，允许物资经济在玩家视线外继续推进。当前为平面方向直线转向，**没有NavigationAgent/NavMesh绕障，仍属于寻路技术候选**。
- `scripts/worldbox_life_sim.gd`：禁掉仍有实体世界资源时的虚空木材与石头增益；启用具稳定地块ID的 `register_field` 与 `gather_field_to_actor`，农民粮食先装到个人运输仓，不能当场凭空加村庄库存，仓储交付时才入账，次日字段 `ready` 再允许收成。保留手动 `harvest_field` 以兼容上一轮试玩。
- 自主工人真实物料可视：工人拿到木材/石头/谷物后，角色节点上创建相应颜色的盒状物料标记 `RealCarried_xxx`，到仓库交付后释放，NPC不是只跑数值；村镇自动支付12木/6石并申请新屋，等经济时钟完成施工后才生成可见房屋。
- `scripts/world_main.gd`：在**同一原Godot主3D场景**实例化 `AutonomousNPCJobsWorldVisible`，并在HUD报告有多少人工作、几次采集/交货、新房数与森林剩余值。与上一轮玩家六键手动闭环并存；原版WorldState人物和已有建筑系统没有被清空。
- QA：`tests/world_smoke.gd` 确认10个实际NPC工单和8块天然资源+一棵手动试验树、2块农田，并检查真实NPC节点接收工作目标；`tests/autonomous_job_smoke.gd` 加入确实在Godot场景里实例化NPC，**测试通过人为模拟到达**资源点/仓库以验证采集、负载、交付、建筑，附加2位农夫实物粮袋搬运验证；`tools/quality_gate.sh` 把上述测试作为CI放行硬门槛。
- 截图QA的Mesa/Xvfb工作流加入 `--audio-driver Dummy`，尝试排除Linux无声卡导致的 `ERR_CANT_OPEN`，但未看新CI最终结论前不能声称已经修好。

### 当前明确限制

1. 工作NPC可以“走向工作目标”但没有真正寻路网格、障碍绕行与地形成本，暂不具备数万人规模调度；这是下一轮重大技术门槛。
2. 新村屋的外形是程序生成的简易灰瓦白墙，而不是完整建筑内部；自动建房还未链接真实住房分配和迁入。
3. 工作循环影响的是新增生活经济模块，不意味着原本私有旧APK中的正式全部系统已经迁移。旧包签名与玩家存档继续保持原样。
4. 已生成/提交所有源码并触发公开GitHub构建和Godot QA；**当下并无新版实机APK成功结果可引用**。后续必须读真实job日志，修复任何未通过的脚本/安卓GDExtension后才发可安装包。

主要公开3D Godot测试流水线：https://github.com/160701541-cell/xinyanshuo/actions/workflows/canglan-public-qa.yml

### CAC-LIFE-003 第二批持续修复（实际提交记录）

- 截至 `fda44bd1b7dbdd782818399238fa77352a93d5f9`，自主职业扩展为**8名林木/采石搬运工 + 2名种田工**。2人能到具有独立实际3D作物节点的农地收粮，并将**可见粮袋附在真实NPC身上**，搬回仓库才增加村庄粮仓5；田地在同日收获后枯竭，等待次日重新生长。运木/石同样附带可见载荷，不是远程传送库存。
- 资源守恒关键修复：`worldbox_life_sim.gd` 不再在场景资源存在时凭工作时间虚构木/石/粮收获。任意字符串捏造的田地ID不能再直接收获；合法农地必须预先 `register_field`，并受村庄真实田地总数上限约束（漏洞回归检查已加）。
- 主世界现在有3块合法登记的实际田地（2块自主生产、1块玩家可交互体验田），且每棵天然树/石头有有限的资源量。自动建房会在仓库实物交付后的下一次调度轮次扣费，避免入库与扣款在同一操作中造成难以追查的库存变化。
- 新增与强化严格 `tests/autonomous_job_smoke.gd` 与 `tests/world_smoke.gd`：真实Godot场景下10个NPC有独立工作目标；按到达模拟验证可见粮袋、采集不立即入库、仓库入账、一天一次的农地、支付建设。QA中人工将NPC移到目标仅为了测试到达转移逻辑，**不宣称已通过障碍寻路/NavMesh和真机手动游玩**。
- 之前真实Godot QA作业 `38911811631` 的失败原因已经从日志确认：测试脚本写死了8个工人，而最新实际系统已有10个。已将 `tests/autonomous_job_smoke.gd` 硬断言改为10人，保留硬性门槛而非删测。
- 最新全量实测与 Android ARM64 AI构建触发号分别是 `38912463503` / `38912463371`，写日志时尚未完成；未通过所有门槛前绝不宣称正式APK/旧游戏热更新成功。

## 2026-10-16 / CAC-TEXT-001 / 完全按用户要求优先测试玩法：3D世界+可点选文字NPC

用户明确指令：**不等人物建模；暂时用文字代替视觉形象，保留所有真实3D世界机制；同职业两人也必须各自独立，有可点选的UI状态栏；可以未来再替换素材库裁图，当前先用文字方案验证玩法。**

实际提交：
- `scripts/npc_text_avatar.gd`：在每个真实NPC三维坐标中挂载 `Label3D` 朝向摄像机显示文字职业、独立姓名/状态与个体身份尾码；每个标记保留 `Area3D/CollisionShape3D`，可用Godot的3D射线和手机触屏点选，**不是假二维网页**。
- `scripts/npc_agent.gd`：增加 `TEXT_ONLY_TEST_MODE = true`；80个NPC默认不再载入被拒绝的圆筒模型或不合格GLB，改用个人文字牌；人物运动、3D地形高度、工作目的地、原版WorldState身份、经济库存、独立年龄/精力/饥饿/心情继续存在；无可见骨架时跳过旧走路关节动画的空指针。
- 姓名由固定姓氏、名和稳定个人身份ID尾码组成，保证两名农人即使职业相同也不会显示为同一人。
- `scripts/world_main.gd`：建立全体 `npc_node_index`、每0.6秒读取当前真正生活经济记录更新可见的个人三维标签；增加独立 `IndividualCitizenInfoPanel` 状态卡。初始显示两名不同农民的独立按钮，分别可检查姓名/身份码/年龄/职业/精力/饥饿/心情/工作/携物/实时三维坐标，点选三维世界中文字碰撞体同样可以打开对应角色资料。
- `tests/world_smoke.gd`：硬性检查80个NPC各有独立 `TextOnly_NPC_3D`、`Label3D`职业和姓名、`Area3D`三维触摸体、可关联各自WorldState与生活模拟；分别选择两名农民需显示不同身份码和不同状态卡，禁止把NPC合并成“农民×2”。
- 开发选择：暂时停用不合格人物模型的运行时渲染，**不删除原模型文件和原独立素材库，也不取消未来正式替换**。本轮首选无需任何图片授权与裁图流程、无需重新做3D角色资产；游戏其他建模、地形、建筑、碰撞、室内、NPC身份、生命周期、工作规则照常保留。

状态：以上为已提交GitHub真实修改；当前严格Godot QA `38913866098` 与 Android 3D/Qwen `38913866059` 已触发，尚未读取最终结果。Android 原版正式游戏未覆盖更新，绝不将源码提交谎称手机已更新。

### CAC-TEXT-001 / 实际Godot QA完成证据和用户需求对齐修正

- 真实Actions运行 `38914096861` **整个严格Godot技术QA已成功（SUCCESS）**。Godot 4.4.1 场景烟测里，80个NPC全部为世界三维 `Label3D + Area3D` 文字占位，没有继续显示不合格的3D人偶；测试点选两名具有**不同原版身份ID**的农民，必须呈现各自独立人物状态卡。
- 同一运行依次输出 `PASS PUBLIC CANGLAN 3D GODOT SCENE`、`PASS CAC WORLD LIFE SIM`、`PASS CAC AUTONOMOUS NPC LOOP`，之后真实Mesa画面截图校验也通过，实际QA artifact: `12051079137`（截图是**真实Godot引擎渲染**，非概念图）。
- 经用户精确要求审查发现原职业贴图 `role_index`（比如商贾）和实际经济职业 `work_roles`（比如农民）并不总相同；2026-10-16再修复每次 `refresh_text_status` 以真实职业显示如 **“农民”**，而不是以前残留的美术职业。增加硬性 `world_smoke.gd` 断言：**两名拥有不同ID的农民文字牌都必须以“农民”开头**；两人仍拥有各自的年龄、精力、饥饿、心情、携物、当前位置及工作状态。
- 上述最后一处文字与职业对齐修复后，最新完整复测 `38914348125` 和 Android 技术构建 `38914347991` 已提交；尚无最终结果时不能称“手机端已更新”。正式原APK和原存档保留不动。

最终游戏开发取舍：暂停角色建模，将质量要求转为可解释的世界规则、真实物理位置及个人身份/状态/交互。后续所有视觉资源只充当可替换渲染表示，不允许破坏世界状态与NPC个体的数据身份。

## 2026-10-16 / CAC-TEXT-APK-001 / 按用户要求真正出可安装包

用户明确要求“更新进游戏”，不再满足于源码与Godot QA。因此立即新增独立快速安卓APK打包流水线 `.github/workflows/canglan-text3d-playtest-apk.yml` 并实际提交 `b5e2b7b86fbbad57b0a9102ee26229367b3d875c`。构建运行 `38915113119` 由GitHub真实触发。

此流水线从真实 `game-source/godot3d` Godot 3D主游戏构建（不是网页、概念图和空壳演示），在发布前严格运行实际场景、人名/身份/点击/两个农民分离状态、个人经济规则、自主采集运输建造的Godot测试；使用临时Android调试密钥创建APK，成功则在同一**公开GitHub Releases**发布 `Canglan-3D-TextNPC-Playtest.apk`。未通过测试不得发布。

本次为加快将用户当前明确要求的玩法交到手机，**将可选的484MB Qwen3权重和尚未通过的llama.cpp ARM64原生编译独立出去**；此快速APK的“离线AI”界面会如实显示不可用，但所有非LLM的NPC自动工作/库存/状态与文字操作继续可用。原重型3D+Qwen全量流水线不删除，可并行研发。

技术与用户安全边界：其独立包名 `com.xinyanshuo.canglan.oss3dqa`、GitHub临时调试签名不同于用户原版的已安装《苍岚》，即便APK成功也**不能原位覆盖、不能自动共享原私有存档、不能谎称原版热更新**。必须获取官方签名与正式OTA更新链的兼容确认后才能对既有游戏覆盖更新。不得建议用户卸载原游戏。此代码完成了“同一Godot3D主游戏工程出独立可安装试玩包”的打包路径，但结果尚须以Actions结论和真实下载文件为证。

## 2026-10-16 / CAC-MOBILE-UX-001 / 用户首次手机真机截图反馈：遮挡与曝光修复

用户提交的横屏Android实机截图 `1000067679.jpg` 表明：独立3D文字NPC可运行、3D场景与个人状态可见，但此前试验版存在**左侧巨大透明黑色调试HUD占据近1/3画面、农民档案和操控按钮全常驻、世界地形/建筑泛白曝光偏高、远处角色文字太小**。这是视觉/操作明显不合格，不得因为GitHub QA绿灯便声称游戏体验合格。

本轮直接提交实用UI修复（`scripts/world_main.gd`）：
- 默认关闭整个个人档案/经济/动作/AI调试大面板；横屏左上仅保留约144×46像素的 `☰ 人物 / 玩法` 按钮。用户点击按钮可打开/关闭，或点击场景中的某个真实NPC可自动打开独立人物档案；打开后的面板左侧固定宽度约440，**内部独立滚动而不占满整屏高度**。
- 在现有Godot原生CanvasLayer/PanelContainer上应用不透明度90%的深色背景圆角面板；移动摇杆/相机不再受到整块常驻HUD遮挡，3D世界默认显示更多有效画面。
- 将白天Sun直射光强从1.15降到0.70、天空环境光从0.66/0.65降到0.34，保留原阴影，目的是缓解截图中白墙与地面的过曝发白；仍须真机截图复核实际设备gamma。
- 新增 `tests/world_smoke.gd` 实际Godot断言：启动时调试面板关闭、可按菜单打开与关闭、点选不同独立NPC时才主动打开对应资料。这轮没有重新造模型或改变世界模拟数据。
- 上述已经进公开 `main`：`d91e0137681b629fe81879a2ce6c297868c28974`、`73386a392a38a8c1f7fc821d4633ae9e11cf0cc3`、`ad5e421ba9b860177e9c385824bc9af9abd6e7f2`。新快速独立测试APK真实GitHub Actions运行 `38916876513`，严格Godot QA运行 `38916876739`；本次记录时间尚未通过新打包/实机验证，不可直接给用户旧APK冒充更新。原签名安装包仍未能热更新。

说明：此次根据真机截图做第一轮布局修复，不代表操作手感、地形纹理与场景视觉已达美术标准。真正应优先完善可用操作、物体交互、任务流程，再优化场景。

### CAC-MOBILE-UX-001 / 严格QA与APK实际交付确认

- `38916876739` **严格Godot+实际Mesa渲染截图QA成功**（全部步骤SUCCESS），覆盖默认HUD折叠、打开/关闭按钮、点击独立居民自动展示其状态、原真实Godot世界与自主生产生活回归检测。
- `38916876513` **Godot Android debug APK实际构建+GitHub prerelease发布成功**。构建源SHA `ad5e421ba9b860177e9c385824bc9af9abd6e7f2`；独立测试包 `Canglan-3D-TextNPC-Playtest.apk` 实际上传大小28,238,730字节。
- APK公开下载链接：`https://github.com/160701541-cell/xinyanshuo/releases/download/canglan-text3d-playtest-ad5e421ba9b8/Canglan-3D-TextNPC-Playtest.apk`。属于独立Godot debug APK，**不是用户原签名APK的覆盖热更新**。持续集成使用每次随机生成的调试签名，同包名的独立旧测试APK可能因签名变化无法直接覆盖安装；不得要求用户卸载原正式游戏。为避免数据损失，任何卸载先确认仅为独立测试应用且没有需要保留的本地测试存档。
- 这份更新是在收到用户真实手机截图之后实际提交、真实Godot回归通过、构建成功的修正版。手机用户仍需目视复核UI缩放、触控、亮度和性能；CI的Mesa截图不是手机设备本身的验收。

## 2026-10-16 / CAC-SPRITE-001 / 直接复用已经做过的世界盒子NPC素材，取消重新造低模人物

**用户问“之前不是生成那么多角色吗？直接套用不会吗？”——正确答案是应当立即复用，不应该再次造圆柱人偶。** 代码及资源实际已提交；并非原版游戏的正式热更新。

- 实地检索公开素材库 `game-source/apk176-ota177-candidate/hd2d/worldx/npcs/npcs.json` 和既存真实PNG：已有6张可动精灵表，每张170×204像素单帧、6列×5行、正面/背面/侧面行走、正反侧待机帧。MIT WorldX来源，可复用而无需重新绘制。
- 其中5张符合古代世界视觉测试：`npc_00` 王掌柜（商户）、`npc_01` 李半仙（方巾书生/算命）、`npc_02` 苏捕头（捕快）、`npc_03` 陈阿狗（市井短打，农/匠通用测试）、`npc_04` 张老醉（餐饮/酒馆测试）。`npc_05` 林小夏**现代连衣裙+手机，禁止进入凡俗古代NPC资源集**。不能错误地把NPC图片里的王掌柜当作模拟世界里真实姓名，图片仅作可替换的外观模板。
- 新增 `tools/stage_existing_worldx_npcs.py`：构建时读取已有素材，逐项校验PNG头、尺寸表结构及原文件SHA256，保留出处和MIT许可证，复制到Godot `assets/generated/npc/worldx/{merchant,scholar,guard,plain_civilian,tavern}.png`。实际通过 `tools/generate_glb_pack.py` 的批量生成环节导入，后续Godot资源扫描可加载，**不需要再次生成图片**。
- `scripts/npc_agent.gd`：在已有80名可点选独立身份居民的世界节点直接新增Sprite3D；保留文字职业/独立姓名/三维空间、射线碰撞、经济/精力/饥饿/年龄/个人库存/工作移动；走路播放6帧精灵图、停步回到正确静态帧；无图时退回纯文字，不显示先前被否决的难看模型。职业与模板按实际生活职业映射：农夫/伐木/石工/陶工→朴素短打；厨师→酒馆类外观；商人/书生/卫卒→对应图。
- `tests/world_smoke.gd` 新增资源存在时每个真实NPC必须有 `ReusedWorldXSprite3D` 及6×5动画帧、停步帧18和原本独立个人ID与状态标签的检查。
- 所有提交进入公共Godot3D实验分支当前main，首轮真实严格CI `38919795797` 已触发等待Godot 4.4测试。**本轮未签原版RSA PCK、未修改原游戏OTA最新版Manifest，因此不能声称原版手机游戏已得到热更新。** 后续需要完成APK176兼容适配和原版OTA。

## 2026-10-16 / CAC-ORIGINAL-OTA-178-PROGRESS / 回归真正的原APK176热更新开发

用户要求“继续”：本轮明确**不发布任何新的独立测试APK**，直接实施**原版APK176（versionCode1176）兼容的Godot增量内容**，并实测原版OTA签名能力，绝不使用新密钥欺骗老游戏。

1. **签名能力真正执行了远程检查**：公开仓库 `.github/workflows/canglan-original-ota-secret-readiness.yml` 真正运行 `38920447159`。CI的 `tools/check_original_ota_secret.py` 明确返回 `original_signing_key_candidates_available=0`, `original_rsa_key_matches_apk176=false`, `safe_to_sign_original_ota=false`, `BLOCKED_ORIGINAL_OTA_SIGNING_KEY_NOT_CONFIGURED_OR_MISMATCH`。这是明确的发布P0阻塞，并非推测。不能伪造/复用旧revision177签名来签新PCK，也不能让用户下载另一个APK。
2. **修复原游戏现有素材场景**：`game-source/apk176-ota177-candidate/scripts/hd2d_worldx_npcs.gd` 新版本延用早前的WorldX PNG精灵动画，实际只创建5名历史人物；剔除第6个拿智能手机的现代服饰角色。5名NPC各有自己`entity_id`、独立年龄、饥饿、精力、心情、职业、个人库存字段、坐标和当前活动。每名NPC点选信息包含独立的ID/属性；维护原动画与地图通行逻辑，绝不是“商人×5”共享一个状态。同一APK176候选叠加场景本身已有`character_selected`点击交互，保持原游戏旧入口不变。注意这是原APK内HD2D叠加场景，不是把独立3D重建项目直接当作原游戏。
3. **老APK176原工程检测**：原版`canglan-apk176-hd2d-overlay.yml`作业`38920761609`已真正SUCCESS：打出未签名的旧工程资源PCK并验证原签名安装包中编译主场景可覆盖加载；原版WorldX素材检测 `38920848620` 已触发。新版 `logic-qa/tools/verify_worldx_npc_content.gd` 新增强制校验5名不同ID、独立状态、禁现代手机角色。提交后另外开启`38921132853`真正还原APK176旧编译场景和Terrain3D插件进行启动/正房室内等全场景严苛验证。
4. **正式上线状态明确仍为BLOCKED**：原游戏官网 `android-preview/latest.json` 仍是**已签rev177**；新候选revision178尚无原RSA签名密钥，未进入正式热更新频道。玩家原APK不需要下载、卸载或破坏存档。待严苛测试通过、合法生产私钥由授权安全途径在CI提供时，才能形成签名rev178+校验并推送官网；不能对用户称原游戏已经热更新。

### CAC-ORIGINAL-OTA-178-PROGRESS / 本轮真实Godot执行完成结论

前两轮因 `hd2d_worldx_npcs.gd` 点选资料代码多一个缩进而触发旧APK176 Godot真实测试 `SCRIPT ERROR: Parse Error: Expected statement, found "Indent" instead`；已以提交 `761ce72ec92799a9e1daf1c8ceab17ee9044bb1a` 纠正并恢复每人活动与位置写入。**没有通过删除严格断言绕过。**

修复后原APK176三条真正QA作业**全部SUCCESS**：
- `38921298132`：原APK编译主场景/脚本和Godot PCK装载认证：`PASS_APK176_HD2D_OVERLAY_MOUNT_AND_CANONICAL_MAIN_SCENE`。
- `38921298121`：以旧APK176导出的编译主场景和真实Terrain3D插件启动、场景/正房室内真实加载，无引擎ERROR：`PASS_APK176_ACTUAL_MAIN_INSTANTIATED_NO_ENGINE_ERRORS_WITH_REAL_HOUSE`。生成rev178完整**未签**候选PCK `21,021,440` 字节，SHA-256 `4bf2e3e9e934a0bbdea97275b824317dbe6472b1782ee50a461673ffc4d93bdc`；原版固定RSA签名安全门明确**拒绝未签包**，没有发布。
- `38921298024`：`PASS_WORLDX_REAL_GAME_ASSETS maps=2 NPCs=5 walk_frames=30 clickable_hotspots=3`；校验全部五个独立ID/年龄/精力/饥饿、可点击地图交互与旧APK场景PCK装载。
- **原游戏热更新发布仍被硬性阻塞**：`38920447159` 已证明公开仓库Actions中原版签名密钥候选数量为0，无法使用APK176固定公钥认可的私钥签rev178。官网 `android-preview/latest.json` 仍然rev177，**没有热更新到手机**。不能把未签候选上传正式频道、不能复用旧签名、不能改固定公钥或让用户重装APK。

这个阶段真正完成的是**原版APK176可加载的增量兼容PCK候选+严格本地引擎QA**，而非实际签名OTA交付；另一个独立原生3D工程虽有前轮Sprite3D美术接入，通过独立严格QA，但其包结构仍与APK176不兼容，不能以“原游戏3D功能已完全进入更新”为结论。

## 2026-10-16 / P0-REPO-BOUNDARY / 用户严格要求唯一公开仓库
用户再次明确：**绝不使用私有仓库**。之前的助手调查了不被允许的旧私有仓库，这属于流程错误，并不构成任何跨仓库迁移的授权。本次已在项目根 `AGENTS.md` 设为P0硬性禁令：只允许 `160701541-cell/xinyanshuo` 公开 `main`，禁止再搜索、读取、修改、引用或调用任何私有仓库，不得拿私有仓库的签名密钥解释或阻塞公开仓库发布。唯一目标仍是原游戏内热更新，不推荐重装独立APK。已经清除 `tools/check_original_ota_secret.py` 中不恰当的私有仓库指向：只检查公共仓库运行时真正注入的合法签名Secret，检查结果不能扩展解释为其他仓库没有密钥。此提交**仅修正规则和诊断，不宣称rev178已签名或手机已热更新**。

## 2026-10-16 / CAC-ORIGINAL-REV178-SIGNER-PUBLISHER / 只在公开仓库执行正式热更新链

实际新增 `tools/publish_original_rev178_ota.py`：严格只接受 `38921298121` 中原始APK176已通过Godot实场景/室内交互QA的**完全一致**21,021,440字节rev178候选PCK（SHA-256 `4bf2e3e9e934a0bbdea97275b824317dbe6472b1782ee50a461673ffc4d93bdc`）。在签名前检查当前已发布正版rev177有真实APK内置公钥认可的RSA签名、APK包名和1176兼容范围、Godot实场景无ERROR、未签候选manifest的rev178信息；在安全临时目录用同一内置公钥匹配的签名私钥产生rev178正式签名，必须通过原版RSA + PCK SHA-256安全门才能写官方 `android-preview/latest.json` 与 `canglan-content-rev-178.pck`，无外来独立APK、无新证书、无私钥上传。

实际新增 `.github/workflows/canglan-original-apk176-rev178-signed-ota.yml`：构建/签名/发布**仅使用公开仓库 `160701541-cell/xinyanshuo`**，由GitHub Actions在主分支以 `actions/download-artifact@v4` 从同公开仓库对应已通过的真实Godot QA提取候选，验证后才会提交原游戏官网同一更新频道。该流程不会在失败时污染线上manifest；没有“忽略安全门失败”行为，也不引入独立安装包。用户不需要重新下载APK。

**已真实触发，准确结果**：公开仓库运行 `38922763801` 在正式原RSA签名预检查阶段 `BLOCKED: original pinned-key RSA signer unavailable in PUBLIC xinyanshuo Actions context`，没有进入签名、没有推送。这里仅证明**这个公开仓库这次GitHub Actions作业没有拿到与APK176的RSA公钥匹配的私钥**，并不能断言用户曾经没有配置别的密钥；尤其不能把Android APK签名keystore误当成PCK更新清单RSA密钥。公开源代码无法自行恢复私钥，也不允许复用rev177签名给不同的rev178字节。当前官网仍是正式签名rev177，待公开仓库允许合法原RSA key注入后同一流水线可继续，但不可谎称已经更新到手机。

### 2026-10-16 / rev178 实际发布重试（用户明确指令“开始发布”）
- 只使用公开仓库 `160701541-cell/xinyanshuo`。用户授权实际发布，执行 GitHub Actions `rerun_failed_workflow_run_jobs`，正式原版OTA流程 `38922763801` 重试成功**启动**（尝试次数更新、作业ID `117047980016`）。
- 最终结果 **FAIL CLOSED**：在 `Check original production signing key without exposing any secret` 步骤返回 `BLOCKED: original pinned-key RSA signer unavailable in PUBLIC xinyanshuo Actions context`、exit 2；后续下载QA PCK、签名、原官网提交步骤未执行。
- 这只说明本次公开仓库Actions Job中注入的候选值**没有与已安装APK176固定公钥匹配的签名密钥**；不意味着用户没配置其他类型的密钥、也不代表密钥不存在。Android APK keystore与OTA manifest RSA是不同用途，不能混用。程序从未输出私钥明文。
- 官网正式OTA `android-preview/latest.json` 仍是rev177；没有rev178已签名/已发布的证据。禁止补签伪证书、绕过签名校验、以独立APK替代或要求重新安装。
- 下一步必须在**同一个公开仓库**检查 Actions Secret 名称和值的实际注入范围及其与原版内置RSA公钥的匹配（不暴露内容），然后重试同一公开OTA workflow；无授权匹配私钥前不能把rev178当成正式更新。

## 2026-10-16 / CAC-OTA-ROOTCAUSE-001 / 公开仓库实际深度排错——不是“用户没设置密钥”

用户要求“那你倒是查啊”，本轮仅用公开仓库 `160701541-cell/xinyanshuo` 做真实可复现排障，而非反复空转同一个失败的发布任务。

**实际查明的事实和证据：**
1. 公开工作流 `38924521435`：使用GitHub Actions当前job的原版PCK签名Secret注入，经安全脚本分类后**五个原本在源码中声明的候选别名均返回 `NOT_INJECTED_IN_THIS_JOB`，不是“私钥已注入但公钥不匹配”**。相关别名：`CANGLAN_PCK_SIGNING_KEY_B64`、`CANGLAN_ORIGINAL_OTA_PRIVATE_KEY_PEM`、`CANGLAN_UPDATE_PRIVATE_KEY_PEM`、`CANGLAN_OTA_PRIVATE_KEY_PEM`、`CANGLAN_UPDATE_SIGNING_KEY_PEM`。这是对特定公开job注入情况的结论，不能推断用户没有在其他位置设置过密钥。
2. 本job经 GitHub CLI 调用公开仓库 REST 查询，唯一可读取的现存环境名为 `github-pages`；`actions/secrets` 和 `actions/variables` 元数据API对 Actions 自带 `GITHUB_TOKEN` 返回权限不可读，**此结果不是仓库不存在对应Secret的证据**，只是 Actions token 没权限枚举Secret名称。
3. 针对唯一现有环境 `github-pages` 单独做了真正环境级只读注入诊断，运行 `38924776815` 的 `existing-pages-environment-signing-probe` job 也证明**五个别名均未注入**，`CANGLAN_ANDROID_KEYSTORE_B64` 也未注入。环境名称是在公开仓库REST枚举得到，绝未尝试任何私有仓库。
4. 同一 `38924776815` 的 `no-secret-genuine-rev178-artifact-qa` job **SUCCESS**。它实际下载了 `38921298121` 的旧版原主场景QA工件、调用`qa_proof` 验证PCK字节、原版RSA签名rev177父版本、APK176兼容范围、真实引擎加载日志及候选sha256，输出 `PASS_PUBLIC_APK176_REV178_AUTHENTIC_PCK_AND_LIVE_MAIN_PROOF_NO_SECRET_REQUIRED`。由此排除“rev178本身无法通过发布前资源/运行时审查”的先前未知项。
5. 排障发现一个**独立的真实发布脚本逻辑BUG**：`tools/publish_original_rev178_ota.py` 错误地要求 Godot `live-main-room-runtime.log` 包含 `PASS_APK176_ACTUAL_MAIN_...`，但此句是工作流Shell在关闭日志文件后才echo出来，不可能出现于Godot日志文件。这意味着即使签名Secret注入成功也会被错误拦截。提交 `7b6aa5f1a739ea277b25e9b9295fd9b6548083b3` 修复错误条件，仍要求有效Godot运行成功标识、运行日志中零错误，并由发布Actions另行检查源CI实际`conclusion=success`；本轮`38924776815`已实证兼容QA通过。
6. 修复秘钥格式适配：`tools/check_original_ota_secret.py`与共享`tools/publish_original_rev177_ota.py`已支持PEM、转义换行PEM和换行分组base64 PEM，诊断只报告是否注入/格式无效/公钥不同/公钥相符，**从不输出秘钥原文、长度或私钥指纹**。增加只访问公开仓库的Actions元数据安全诊断脚本`tools/diagnose_public_actions_scopes.py`；GitHub没有授权此Actions token读取Secret设置页面，本工具绝不越权。
7. 停止浪费资源：`canglan-public-3d-android.yml`和`canglan-public-hd2d-android.yml`两条**独立APK**构建流水线取消每次推送自动构建、保留手工运行；旧版rev177发布工作流也停用自动推送触发，避免与rev178正式发布冲突或制造噪音。唯一正式交付目标仍是原游戏内签名热更新。

**当前准确根因界定：** 原游戏rev178 QA资源、代码验证均可通过；当前这个公开仓库的普通主分支Actions job与现有`github-pages`环境job均**没有注入五个已声明的RSA签名Secret名称**，签名步骤无法执行。可能是配置别名不同、配置的密钥用途不同或所处的Secrets作用域与该job不重叠。由于 GitHub runner token 无权读取仓库Secret元数据，无法仅凭该token判定实际已设置的别名；也不能从签名公钥反推RSA私钥。

**发布状态**：rev178尚未签名与推送，`android-preview/latest.json`仍是rev177；不得让玩家重装APK、不使用私有仓库、不绕过RSA。下一步唯一需解决的是合法签名Secret在允许的公开仓库CI中正确注入，复跑 `.github/workflows/canglan-original-apk176-rev178-signed-ota.yml`，最后必须真机更新验收。

## 2026-10-17 / P0 APK176 rev178 发布实际执行（用户称现已可打包更新）

**用户授权执行之后，立即实际重跑仅公开仓库发布任务**：原安装包APK176签名热更新工作流 `38925668945`（重试新作业 `117077997517`）已经运行，**结论failure，因正式签名私钥仍未注入而在安全门阻止发布**。同时重跑环境配置排查 `38925680620`：`github-pages`环境 `117078363015` 是fail closed，原APK176真实rev178未签补丁资源QA `117078366090` 为SUCCESS。

安全状态探针的本次新增发现（仅报告有无，不显示任何机密内容）：
- `CANGLAN_ANDROID_KEYSTORE_B64` **现在确实在公开仓库Actions job中已注入**（以前报告false、此次报告true），说明用户近期配置至少有一个安卓APK签名所用Secret；但这只能证明变量非空，并未验证文件有效或证书是否与原安装包相同。
- 五个OTA RSA签名候选别名 **均为 `NOT_INJECTED_IN_THIS_JOB`**，包括 `CANGLAN_ORIGINAL_OTA_PRIVATE_KEY_PEM`、`CANGLAN_PCK_SIGNING_KEY_B64`。其本身不表明用户未配置密钥，只表明公开主分支发布runner与`github-pages`环境当前均取不到其中任何一个。安卓APK keystore并不自动具备与原游戏信任根匹配的PCK内容签名能力，不能私自代用或修改公钥。
- `CANGLAN_SITE_PUBLISH_TOKEN` 标志false但本发布工作流使用 `GITHUB_TOKEN`提交公库，非此轮卡点；`CANGLAN_ENABLE_OTA_RELEASES` 的当前工作流变量探针为不存在/false（当前实际rev178流程不依赖它），不是阻塞主因。
- `qa_proof` 经不读取机密的独立真实CI重试成功验证：21,021,440字节、SHA-256 `4bf2e3e9e934a0bbdea97275b824317dbe6472b1782ee50a461673ffc4d93bdc` 的rev178原版内容补丁及实场景QA符合代码的兼容检查。
- 本次**没有发布新版manifest、没有改线上rev177、没有签发假的RSA签名、没有交付独立APK替代热更新、没有使用任何私有仓库**。下一个合法动作是让已签过原版rev177更新的原始RSA签名私钥在本公开仓库以正确名/正确作用域注入，再运行同一流水线；不能凭空生成原私钥。

## 2026-10-17 / CAC-OTA-178-RELEASED / 《苍岚》原安装APK176的真实签名rev178热更新已发布

**用户确认已经在公开仓库设置好RSA密钥之后，终于按“只用公开仓库、只用游戏内热更新、不重装APK、不删存档”正式发布成功。**

### 实际执行与证据
1. **正式签名/原版实QA/公开仓库Git发布全部成功**：对唯一允许的 `160701541-cell/xinyanshuo` 的原版发布Actions `38925668945` 发起Failed Jobs重试，最新Job ID `117105352623`，最终`conclusion=success`。预检：`PASS_RSA_SIGNER_MATCHES_INSTALLED_APK176_PUBLIC_KEY_NO_SECRET_EXPOSED`。真正下载此前原APK176主场景完整 QA成功run `38921298121` 已严格测试的固定字节候选PCK，签名后分别给出 `PASS_ORIGINAL_APK176_SIGNED_REV178_STAGED`、`PASS_PUBLIC_REPO_ORIGINAL_APK176_REV178_SIGNED_RSAPINNED_OTA`，将 `android-preview/latest.json` 与 `android-preview/canglan-content-rev-178.pck` 一同发布到公开仓库 main，发布git提交 `b1e917a`，Log `PASS_ORIGINAL_CANGLAN_REV178_SIGNED_PCK_AND_MANIFEST_PUBLIC_COMMIT`。
2. **原版PCK签名与包身份正确**：发布后GitHub源码实际读取 `android-preview/latest.json` 确认revision=178、渠道`android-preview`、兼容Android versionCode=1176、原引擎已安装包名 `org.canglan.ancient25d.preview` 的固定RSA公钥验证通过。PCK大小 `21021440` 字节、SHA-256 `4bf2e3e9e934a0bbdea97275b824317dbe6472b1782ee50a461673ffc4d93bdc`，**禁止把这个包理解成安卓APK或独立demo包**。
3. **GitHub Pages部署实际成功**：官方站Pages build/deploy run `38940171362` 三job (build/deploy/report) 均 `conclusion=success`。
4. **已验证真正的公网HTTPS而不仅是GitHub仓库**：新增只读 `tools/verify_original_rev178_public_ota_http.py` 和发布后外网严格核验Action `.github/workflows/canglan-original-rev178-public-https-proof.yml`。Actions run `38940623092` **SUCCESS**，GitHub官方Ubuntu runner通过公网请求 `https://160701541-cell.github.io/xinyanshuo/android-preview/latest.json` 得到新rev178、对照公开仓库文本、使用原APK176固定RSA公钥验证签名，完整下载公网 `canglan-content-rev-178.pck` ~21MB并验证二进制`GDPC`头/长度/SHA-256完美一致；日志 `PASS_PUBLIC_HTTP_ORIGINAL_APK176_SIGNED_MANIFEST_178` 和 `PASS_PUBLIC_HTTPS_ORIGINAL_APK176_REV178_FULL_PACK_SHA256`。
5. **角色玩法**：rev178基于原版引擎兼容资源，同版已做好5名历史WorldX人物既有动画、独立ID、年龄/精力/饥饿/心情等可点选信息、旧版地图与正房室内进出，详见 `CAC-ORIGINAL-OTA-178-PROGRESS`。并不宣称将独立原生3D测试APP整体热更进原版了。
6. **保留真实的最后一步**：尚未由用户手机实机验证游戏内发现178、下载、校验、实际进入场景并保留原存档。所有公开RSA+Pages+完整PCK公网QA虽均绿，仍将**手机实机验收**标记为 `PENDING_USER_DEVICE_ACCEPTANCE`，不能冒充通过。

**当前状态**：官方原版热更新rev178 **已成功合法签名、官网发布、公网校验**；现由用户直接打开原安装《苍岚》、使用游戏内检查更新验证。**无需下载新APK，不可卸载旧版本，禁止暴露RSA私钥。**

## 2026-10-17 / CAC-MATERIALS-NPC-WORLD-001 / 世界由NPC建，我们只生产材质（用户纠偏）

用户明确否决此前错误的 WorldX 四面建筑立面图、整套建筑图、HD2D 背景方案。**用户要的是：我们只批量做可复用的材料纹理；建筑、道路、城镇由有身份的NPC根据自身需求和世界资源亲自建成真正3D实体。** 而不是四面贴图取巧搭一个伪3D城镇。

### 实际撤销
- 删除之前未经运行的4个WorldX四面成品建筑生成文件：`tools/asset_factory/worldx_four_facades.prompt.md`、`worldx_four_facades.mjs`、`test_worldx_four_facades.mjs`、`verify_worldx_four_facades.py`。**没有运行四面建筑的付费生成请求**。
- `AGENTS.md`新增最高级规则禁止继续生成完整建筑/四面图片或HD2D地图当作游戏世界；未来只生成材料纹理。
- 删除 `scripts/autonomous_village_director.gd` 原“村民一搬运完就立刻刷出预制房屋”的临时逻辑，实际资源采集运输保留。

### 实际完成的NPC自主建设源码
- `game-source/godot3d/scripts/worldbox_life_sim.gd`：扩充原有实体仓库加工材料 `timber`、`cut_stone`、`mortar`、`roof_tile`；原木、石、泥土与水等基础库存继续作为生产来源。
- 新 `game-source/godot3d/scripts/npc_building_system.gd`：已经把有ID的80 NPC划分出木匠、石匠、陶工、建筑工，城市作坊缺失时由世界状态触发NPC建设计划；真实工人必须抵达材料工坊，消耗有限的木/石/泥/水加工中间材料；建筑工必须从仓库领取相应材料，随身携带实体货物到指定地块后交付；必须完成劳动计数后，4个阶段才在**世界3D空间**出现地基/木架/墙面/屋瓦。最后工作坊数量才从0变1，财产和职业记录有ID与事件日志。无物品/工人未到现场不能凭空造房。
- `game-source/godot3d/scripts/world_main.gd` 真正挂载 `NPCBuilding`；80名原有NPC保留不同稳定身份，新设对应建筑职业；HUD显示规划项目编号、施工阶段、本人施工状态，保留第三人称3D世界，不是独立HD2D贴图。
- `game-source/godot3d/tests/npc_material_construction_smoke.gd` 严格集成测试3D实际Godot主场景：NPC规划前不得存在成品建筑、3种加工职业、材料确实扣账、货物在角色身上且运达、地基/木构/墙/瓦按阶段装配、最终经济中增加工坊数量与玩家可观察的3D建筑实体；禁止负库存。测试中仅人为模拟“NPC已走到目标点”，所以**不证明自动寻路导航、复杂城市完全自主规划、持久存档读取通过**。
- CI `.github/workflows/canglan-npc-material-build-qa.yml` 真实 Godot 4.4.1 无APK增量QA，run `38946236428` 和改HUD后的 `38946345582` **SUCCESS**；原有3D综合Godot QA `38946343576` **SUCCESS**。这只验证了单个工坊建设样本和原游戏3D实验工程，后续NPC选址、个体记忆、完整大规模城市建设需要继续迭代。

### 真实WorldX素材流水线：只做材料（已真实成功生成4张）
- 新 `tools/asset_factory/worldx_raw_material_template.md`、`worldx_raw_materials_batch01.mjs`、`test_worldx_raw_materials_batch01.mjs`。扩展真正YGYOOO/WorldX指定提交 `edb4976` 的prompt-loader，使用公开仓库已授权 `SILICONFLOW_API_KEY` 调用API，每种材质一次，**无付费失败自动重试**；只生成4种1024×1024表面：深棕木纹 `timber`、青灰石面 `cut_stone`、灰泥 `mortar`、青灰瓦 `roof_tile`。不生成房子、立面、院落地图或人物贴纸。须诚实称为“WorldX上游工具扩展”，因为上游原生的map generator是二维俯视地图工具，并不是PBR材质生产工具。
- `.github/workflows/canglan-worldx-materials-only-batch01.yml` 实际 run `38947005032` **SUCCESS**，在四次受控生成后校验每份文件大小、1024²尺寸、SHA256并提交到公开仓库 `art-source/worldx/materials-batch01/`。4个真实PNG分别有元数据、生成源码prompt与请求账本；程序明确标 `GENERATED_UNAPPROVED`，不能谎称已经过无缝拼接检测或美术审批、不能直接发布手机。生成原图已存入公开仓库可供玩家/开发方查阅。
- 新 `docs/NPC_WORLD_CONSTRUCTION.md` 固化后续蓝图、职业、世界进化、有限资源、建造失败/中止条件与存档规则。

**发行状态**：目前这些新的材料/建筑工代码和WorldX纹理是公开仓库新增研发布局，**尚未为安装在玩家手机里的APK176制作合法兼容的新版rev179 PCK、更未通过原版3D主场景/移动端实机验收**；已发布rev178不能视为这次NPC建设系统已经进入原版。不能建议重装独立测试APK。下一轮要让真正WorldX材料经过风格/无缝审核并成为3D纹理，再解决原版兼容增量补丁，然后签名热更新。

## 2026-10-17 / CAC-LOCAL-NPC-CC0 / 用户要求离线AI驱动NPC思想、弃自造模型改用免费成熟3D资产

**最新用户指令：** NPC思想接入本地模型；不要自己造人物/村庄3D模型。Kenney、Quaternius、Poly Pizza优先免费可商用且风格可统一的成熟资源，直接导入Godot。WorldX只生成独立材料纹理，NPC通过真实世界物资经济自主建造。

**真实代码和资源（只用公开仓库 `160701541-cell/xinyanshuo`）：**
- `game-source/godot3d/opensource/cc0_asset_catalog.json`：Kenney CC0城堡/自然、Quaternius CC0免费Standard模块与角色的锁定Git Blob SHA、固定来源commit、许可和原网站。Poly Pizza不同模型需逐个核实CC0/CC-BY，不随便当成免署名CC0。
- `tools/asset_factory/import_cc0_model_packs.py`：无AI生成/无私库，真实HTTPS下载已存在的GLB、gltf、bin、PBR贴图，逐字节校验hash和gltf依赖，生成准确来源记录。
- `game-source/godot3d/scripts/cc0_asset_bridge.gd` + `tests/cc0_existing_assets_smoke.gd`：让Godot读取真实12个现成3D模型并验证网格、来源和节点，候选视觉/动画还需后续QA。实际CI `38948880609`首批**SUCCESS**：10模型22文件成功放进游戏仓库（提交`24249ff`）；后续`38949607844`**SUCCESS**：扩增为12模型24文件，含Quaternius真实骨骼人物和有12条原始动画的Knight GLB。旧的30MB级PBR贴图将来需压缩/优化安卓内存和远端补丁量。
- `scripts/npc_building_system.gd`：已在真实Godot3D施工工地和实体库存流程中使用Kenney木料与石块真正网格，Quaternius墙/瓦模块作为视觉候选，不会凭空生成完成房屋，NPC仍然完成伐木/采石/加工/搬运/四阶段施工。
- `scripts/npc_intent_policy.gd` + `scripts/local_ai_service.gd` 已具备基于每位NPC的精力、饥饿、职位、粮食、施工状态的离线AI候选意向与现实规则验收，遵守单一模型串行推理、不经审查不允许直接生金币/虚造建造。实际native C++逻辑修正 `canglan_local_llm.h/.cpp`：新增单独`intent_mode`，不再让“只许输出对话”的强制system prompt压制NPC ACTION=行为判断。其Linux真C++编译任务 `.github/workflows/canglan-offline-npc-native-linux-qa.yml` 已触发，但**只有编译成功才能说原生库编译通过；安卓ARM64实机推理未做**。
- `AGENTS.md`已写最新P0：禁止自造3D游戏美术模型，优先Kenney/Quaternius CC0、Poly Pizza逐个许可；AI仅拥有NPC意向、世界库存/建筑权威独立，严格区分原版热更新。并在 `.github/workflows/canglan-public-qa.yml`移除重新生成程序低模屋/人偶的工作流步骤，改为现成CC0素材和已有经校验精灵。

**当前实际交付**：以上是真实的公开Godot3D研发源码/材质/模型和本地AI行为代码，**尚未集成进已签名原APK176/rev178的正式热更新包，也未进行用户手机上的离线GGUF和人物动画验收**。不能把公开3D工程测试冒充旧APK热更新。原版APK不存在已确认的llama.cpp ARM64组件；升级原版安卓底层库需单独验证是否真正需要覆盖APK，只能沿用旧包名/签名和存档，不能推荐重新安装另一应用。详细进展与来源见 `docs/NPC_OFFLINE_AI_CC0_ASSET_PIPELINE.md`。

## 2026-10-17 / CAC-NPC-LOCAL-AI-CC0-001 / 改用真实CC0素材并让NPC拥有受约束的本地AI决策
**新要求**：用户禁止继续生成低质量自建模型和AI整屋贴片。优先采用Kenney、Quaternius、Poly Pizza等已存在且许可可逐项审计的免费可商用模型；世界真正由各NPC根据供需/图纸/材料/劳动建设。NPC离线模型只负责思考，世界规则负责审查和执行。
**真正提交且生效的源码**：
1. game-source/godot3d/opensource/cc0_asset_catalog.json 和 tools/asset_factory/import_cc0_model_packs.py，新增固定Git SHA和Blob SHA的Kenney/Quaternius民居结构件、树木、门窗道具与普通人形/带12个预制原动画片段的骑士GLB。Poly Pizza必须按模型核对CC0/CC-BY署名，不贸然导入其他人版权内容。
2. 公开仓库CC0实际导入CI 38949607844 **SUCCESS**：下载24个真实文件、逐一比对原Git blob校验、通过Godot 4.4.1原生编辑器导入并真实实例化12个资源入口，确实Git commit回唯一公开仓库 game-source/godot3d/assets/free_cc0/，非只写清单；约28.8MB源文件及依赖。
3. game-source/godot3d/scripts/cc0_asset_bridge.gd 暴露12类现成真实3D模型；npc_building_system.gd 在消耗实际材料、工人背负到工地并完成地基/支架/墙/屋顶后才按部位装配外部CC0构件，不凭空刷现成房子，旧实体ID与成本/施工规则不变。
4. npc_agent.gd 对Guard优先尝试真正的Quaternius可动角色，强制存在Idle+Walk AnimationPlayer才启用；否则仍使用旧动画素材占位，不许静止人偶模拟走路。world_main.gd新增实际卫卒职业。已下载的Quaternius基础普通人形为真实绑定模型但尚无自带动画，不谎称80个居民全都已用骨骼模型。
5. local_ai_service.gd 增加与玩家交谈相隔离的 ask_npc_intent 和 npc_intent 异步回调；world_main.gd 将在本地模型真正可用时选择附近一名非忙碌NPC，每75秒最多请求一次，80个角色复用一份Qwen3-0.6B GGUF + llama.cpp，引擎未装/权重未通过SHA校验时不假装AI可用。
6. 新增 npc_intent_policy.gd 严格允许 eat、rest、inspect_stock、inspect_site、keep_working。模型只能提出意图：权限验证依据NPC ID、真实职业/村落/体力/真实粮食和施工进度，拒绝任意脚本、恶意文字凭空创造资源、忙碌工人被任意改调。
**QA结果**：CC0导入真实Godot QA 38949607844 SUCCESS；NPC建造/本地AI逻辑真实Godot测试 38949995322 SUCCESS（包括粮食真扣账、休息数值边界、移动到仓库须经过实际位置、角色身份隔离、不允许直接给物资）；综合3D Godot QA 38950055947 SUCCESS。Android原生llama.cpp编译 38950144223 本次记录时仍在运行，不能写成功。
**严格分辨交付**：这批为唯一公开GitHub仓库的新3D源工程和经过实测的已导入CC0文件，**不是**原已安装APK176的签名rev179热更新；未做Android本地模型实机运行、原APK兼容、存档回归或实机温控。未来如首次导入原版需要额外的Android ARM64原生推理组件，必须使用原包合法签名作一次底层APK组件升级，随后业务脚本和资源更新依旧走游戏内热更新，禁止独立APK冒充正式更新。

### 同批补充：弃用错方向的自动构图工作流
- `.github/workflows/canglan-worldx-3d-four-facades.yml` 的4面建筑图像生成Job已`if:false`硬禁用，GitHub实际触发 `38950619657` **skipped**，不会再调用图片API付费。
- `.github/workflows/canglan-original-worldx-four-facade-3d-qa.yml` 的原APK176四面图片伪3D候选Job已`if:false`硬禁用，实际 `38950628325` **skipped**。旧素材保留审计，不再声称更新。
- `.github/workflows/canglan-worldx-apk176-content.yml` 的2D地图/HD2D重导入Job亦已`if:false`禁用。真正材料专用WorldX流程 `canglan-worldx-materials-only-batch01.yml`不受影响。
- `.github/workflows/canglan-public-qa.yml`已取消重新绘制程序生成房屋/人偶GLB，改为已导入的真实Kenney/Quaternius和已有角色贴图。真实Godot全场景严格QA run `38950055947` 最终**SUCCESS**。
- 真实已来源校验的12个CC0模型/24个贴图及二进制入库真实CI `38949607844` **SUCCESS**；至少Quaternius既有knight GLB含12条动画、另一个基础人形GLB有骨骼无动作，不可声称两个都已具备动画。离线Qwen3 native Linux源码构建由 `38950144223` 单独检查；尚未完成手机端运行验收。
- **P0发布边界**：正式站原手机应用签名rev178未因此改版，上述新3D材料/AI代码**尚未进入正式旧APK**。

## 2026-10-17 / CAC-NEW-CHAT-CONTINUE-AI-NATIVE-001 / 跨对话接续：NPC离线思想、自建世界而非图片

用户新对话发来上一轮会话触顶截图：继续已确认的优先任务，不再要求重新解释——NPC离线AI决定意图、权威世界规则决定是否落实，NPC亲自采集/加工/运输/分阶段建造，维持真3D；免费Kenney/Quaternius CC0可商用现有模型优先，不再自造人偶或HD2D整图；只用公开 `xinyanshuo`，仅原版签名热更新算游戏交付。

**本轮实际GitHub修复：** 核查最新原生Qwen+llama.cpp Linux GDExtension编译QA运行 `38950144223`，从完整Job log核实原C++ `libcanglan_ai.so` 实际在Linux编译成功，Job败在 Python文本合同断言：原引擎源码输出是`严格只输出单独一行 ACTION=xxx`，断言却错误找`只返回一行`，不是C++编译失败，更不是手机离线AI已运行。修改 `.github/workflows/canglan-offline-npc-native-linux-qa.yml`：断言精确匹配意图分支实际系统提示，并同时验证对话分支禁止凭空交易。提交 `8fc5eb559a395bf88ab000188a2a2bce22796f2d`，真实Linux QA run `38953517388` 自动启动，等待最终结论。**仅Linux编译QA，绝非Android ARM64、原版APK176的GDExtension已安装或手机GGUF实际推理。**

**当前实际交付边界：** 源码改动和QA修复不构成新版本正式OTA。最后成功发布的原游戏RSA签名包为rev178，新的NPC生活/施工/CC0/离线AI内容尚未签发到原应用；不可拿独立测试APK替代。下一阶段要核实原版APK176的Android原生库可升级能力和不换包名、不换签名的安全路径，再决定需要APK覆盖还是仍可走签名PCK。

## 2026-10-17 / CAC-PHONE-RELEASE-REQUEST-LOCAL-AI / 原手机APK176原生AI组件实际兼容性检查

用户明确要求将“离线Qwen NPC + Kenney/Quaternius既有CC0模型 + NPC自主施工”**发布到原手机游戏，不新装独立APK**。按P0安全发布要求，先检查真正在用户手机上安装的原版APK176二进制有没有llama.cpp所需Android native ARM64动态库，防止仅把GDScript和3D源码仓库打成PCK、冒充功能正常。

- 新增 `tools/audit_original_apk176_npc_ai_native_bridge.py`，公开repo本身已收录`android-preview/base-latest.json`指定的真实原APK176 ZIP二进制；逐条审计lib/*.so和Godot GDExtension相关元数据，输出清单与阻断理由，完全不需要访问私库、不产生APK、不泄漏密钥。
- 新增仅用于真实性审计的公开repo Action `.github/workflows/canglan-original-npc-ai-phone-compat-audit.yml`；**真实CI `38954290732` 运行SUCCESS**，Job `117153125491` 回传 `ORIGINAL_NATIVE_LIBS 3 AI_BACKEND_MATCHES 0`、`P0_BLOCKED_ORIGINAL_APK176_NO_NATIVE_LLAMA_LIBS`、`PASS_TRUTHFUL_PHONE_RELEASE_BOUNDARY_AUDIT`。这意味着**原版APK176中没有可核验的llama.cpp / canglan_ai / ggml本地推理Android动态库**；只通过PCK上传权重和脚本不可能让内置 `ClassDB.class_exists("CanglanLocalLLM")` 自动变真。现有单独3D工程里的NPC本地AI逻辑/CC0已实测，不等于安装版兼容。
- **正式手机发布状态**：目前`android-preview/latest.json`仍然revision178，本次未签rev179、未发布不兼容PCK、未生成其他包、未碰用户存档。**这不是成功发布**。推进路径：在唯一公库构建同原包名、同原签名的Android底层升级，以带合法原版keystore签名的覆盖APK只做一次llama.cpp ARM64/GDExtension初始化与真正3D世界兼容迁移；之后内容继续签名PCK OTA。或先发布不依赖本地AI的新行为与建设系统，但同样先证明原版主场景3D装载兼容。不得谎称旧APK176本身已经有离线Qwen。

## 2026-10-17 / CAC-NPC-LLM-CHOICE-DEFERRED / 本地模型用户以后自己选，其他3D建造功能继续

用户明确决定：**本地NPC AI模型由用户自行选择后再接入；当前先推进游戏里其他系统**。不允许默默指定Qwen3 0.6B、强制下载约484MB模型、假装NPC已经能调用AI；也不允许回退到HD2D、四面建筑图片或自行逐个造3D模型。

已实改公开仓库原生3D游戏源码 `game-source/godot3d/scripts/local_ai_service.gd`：新增用户选择文件 `user://local_models/selected_model.json` 的显式授权门；不存在该文件时显示 `awaiting_user_selection` 并直接退出AI启动，**不加载、不下载任何默认GGUF**。已写入其他不依赖AI的NPC生活、工作、采集、木匠/石匠/陶工材料加工、实体运输、分阶段房屋建造均继续运行的预期。

原生3D工程已有且继续沿用 `cc0_asset_bridge.gd` 12项**真正已导入的**Kenney、Quaternius开源3D GLB/glTF模块（包括门、石阶、墙、屋顶、木料、石块、人物/护卫）；`npc_building_system.gd` 已根据真实库存与工人劳动阶段装配这些现成模块。Poly Pizza暂不自动抓取，须逐个核对创作者及CC0/CC-BY许可，不能笼统认定其全部商用无署名。绝不让图片替代实体3D。

新增 `tests/deferred_ai_and_cc0_build_smoke.gd` 与公开仓库专属真实Godot 4.4.1 CI `canglan-npc-materials-no-forced-llm-qa.yml`，用真实Godot引擎验证模型选择门、实体CC0模块、NPC及加工配方，运行ID `38955498300`；**在该工作流成功且与原版APK176兼容的签名PCK真正发布之前，绝不宣称本次修改已经更新到手机**。

注意：以后用户选择本地模型时，需要实现可选模型菜单、用户可见的GGUF文件导入/验证和llama.cpp能力检查，不得用预置固定模型代替用户选择。


## 2026-10-17 / CAC-MASTER-LOG-ADOPTION / 用户指定完整工程总设计为后续开发日志

用户明确指示“现在以这个为开发日志”，将本对话生成的《苍岚人生世界_完整游戏工程总设计_v1.0.md》（21章，涵盖美术、NPC、资源工业、修仙、技术、QA、原版发布）设为今后研发总蓝图与开发日志基准。

**本轮实际GitHub提交**：新增 `docs/GAME_ENGINEERING_MASTER.md` 作为**长期维护的工程总日志主入口/执行索引**，覆盖21领域、G0–G8路线、第一批Issue、质量门禁、原版发布边界、日志模板；提交 `cd2c2b3faeeac4d1eb748613ed13a2e19d290e12`。原有本历史日志完整保留，之后每轮应先读 `AGENTS.md` + 本文件 + `docs/GAME_ENGINEERING_MASTER.md`，并同时更新实际进展。**详版母本目前作为对话附件供下载，尚未逐字节提交到GitHub；GitHub中的是工程执行索引，不能谎称完整母本已归档。**

**本次状态**：仅文档/研发规范提交；未修改Godot玩法代码、未签名PCK、未更新rev178、未完成手机实机验收。下一阶段优先G0原版兼容/发行链与G1美术基准村庄、G2物资守恒闭环。


## 2026-10-17 / SIM-001-P0-NO-FREE-RESOURCES / 按工程总纲开始真实代码修复

**已读取** `AGENTS.md`、`docs/GAME_ENGINEERING_MASTER.md`（前轮）、本日志、正式rev178基线，并检查 `worldbox_life_sim.gd` 与 `autonomous_village_director.gd`。发现P0真实缺陷：`_citizen_work()` 中农民、伐木工、采石工在未登记自然资源节点时，仍能通过每小时`_add_stock`凭空增加粮、木、石；`start()`没有清空自然节点、搬运背包、农田状态，重开模拟存在陈旧状态残留。

**实际源码提交**：`b2e4ab03c4a5e50e04504b60dbf16033d2880a15` 修改 `game-source/godot3d/scripts/worldbox_life_sim.gd`：三种职业的时间tick不再直接产出原料；只等待已有资源/农田的实体采集与运输任务；`start()`清空节点、在途货物、农田数据。现有`gather_to_actor→deliver_carried`守恒路径保留。

**新增测试**：`acdde42f916f0c779296d42d2508782fbc8b1d49` 添加 `game-source/godot3d/tests/resource_conservation_smoke.gd`，覆盖1000 tick无资源凭空生成、有限树木采集、双重交货拒绝、耗尽后拒采、重新启动清空旧状态。

**真实QA状态**：测试源码已提交，**尚未运行Godot**（当前执行环境没有Godot命令），不能写通过。仍需在公开CI跑真实Godot引擎测试；既有`autonomous_village_director.gd`还存在“根据NPC住址生成自然节点”和临时BoxMesh视觉资产问题，后续按先有资源后派工重构。**正式OTA状态**：仍为rev178；未完成原版APK176兼容审计、RSA签名PCK、手机实机验收，不能称已更新手机。


## 2026-10-17 / SIM-002-PREEXISTING-RESOURCES / NPC不再为任务生成资源

按`docs/GAME_ENGINEERING_MASTER.md`继续推进G2：`worldbox_life_sim.gd`新增`resource_positions`及`register_resource_position`、`get_available_resource_nodes`，查询仅返回**预先登记、具有世界坐标、尚未耗尽**的资源，按ID排序，重启清理坐标；提交`39b3790cf15a0fb639d9505ba45f092a44631ac8`。

`autonomous_village_director.gd`改为仅给NPC分派已存在的节点、避免多个NPC初次争抢同一节点；不再在派工时注册树/石/田。提交`6a8d6519ff862883bdef6cbbd62cc4f14143d1f2`。移除该调度器用于资源与货物的临时BoxMesh造型，待合法现成3D资产接入，提交`c598d4e29ffb56ce4aa4800644bf49dfc34ce25b`。扩充资源守恒测试：位置登记、耗尽后不可再次分派、重启清空坐标，提交`0ed99712b9bcf1cec3160447ce3917608fe171d5`。

**重要限制/潜在回归**：当前调度器不再自动生成资源，因此若原场景没有**在setup前**预先登记节点及坐标，NPC不会接到采集工作，画面也不会有旧BoxMesh树/石占位。此为P0世界生成前置依赖，下一批必须补上真正独立世界资源播种、合法资产渲染桥和场景接线；不能称已形成完整可玩闭环。

**QA状态**：GitHub源码已提交，尚未运行真实Godot/安卓，测试结果PENDING；没有签发新PCK，原版仍rev178，未手机验收。


## 2026-10-17 / ECO-003-REGEN-RICH-VEINS / 用户确认资源恢复与大型矿脉

用户新增规则：可恢复资源在休养后重新产出；大型矿脉储量更高、恢复更快，但恢复速率不能超过正常开采速度。落实到`game-source/godot3d/scripts/worldbox_life_sim.gd`，提交`f0cfbddfe41fae3c3554ff3d29470a1cf315c4a8`：资源节点新增`capacity/regen_units/regen_hours/recovery_hours/next_regen_hour`；默认旧节点保持不恢复以避免无意改变世界；按生态明确配置后才恢复，恢复有上限与冷却；大型矿脉`register_rich_mineral_vein`支持1001–100000容量，默认12000，初始暴露1000，每12小时最多恢复2单位，首轮开采后延迟24小时再按周期恢复。单次采集最多3单位，持续采矿必然快于恢复；储量不会超容量。该数值是**初版平衡参数**，不等于现实矿石自然再生；在世界观里可解释为矿脉深层矿层逐渐暴露。

新增回归测试提交`4be646bc79b73cbf1af2815692788fe4300b256a`：大型矿脉容量/开采/冷却/慢速恢复，树木72小时恢复1单位。**测试尚未在Godot实际执行，不能标通过。**

**尚未完成**：真正的世界生成器需要按地貌、生态和矿脉类型预先播种这些节点；NPC耗尽资源后的重新派工/休养后复工、恢复中的视觉成长、存档兼容迁移、Android实机和原版签名OTA均待做。正式游戏仍rev178。


## 2026-10-17 / SIM-004-RECOVERY-REDISPATCH / 资源耗尽后重新找矿、恢复后复工

检查`autonomous_village_director.gd`发现此前去掉BoxMesh后仍保留两处直接访问`natural_art[node_id]`，会在采集资源耗尽或交货后触发无效字典索引。提交`89c3c442b30f401ff7ae22ae11d6cde310d65cb7`：改为安全可选视觉节点访问，NPC在资源耗尽时进入`waiting_resource`而非反复向空节点寻路；调度器每次轮询预先存在的可用节点，按ID稳定选择新资源；矿脉/树木恢复后可重新派工。**前提：世界生成器必须先登记资源位置，尚未完成场景集成。**

新增真实Godot 4.4.1 GitHub Actions回归工作流`.github/workflows/canglan-resource-conservation-qa.yml`，提交`57a6fb0fec153c8d54d4a3ba0eda7fac92020c0c`，执行1000 tick无凭空产出、资源耗尽、重复交货、矿脉恢复和树木再生测试。**工作流已提交，但本次尚未核验CI运行结果；不写QA通过。** 原APK176正式rev178仍未改变，未手机验收。


## 2026-10-17 / ECO-005-WORLD-SEEDING / 资源在NPC派工前真实进入模拟地图

提交`10dfe9b933426ee76e571a80edafc0cad84642b7`新增`game-source/godot3d/scripts/world_resource_seeder.gd`：使用世界种子确定性创建16棵可恢复树木、10处普通石点、6处黏土点（其中一处大型矿脉）、7块农田，绑定真实地形高度、固定实体ID、有限库存及恢复规则。大型矿脉12000最大储量；树木48小时/1单位且24小时休养。新增测试`c5e9a44f3d6f7f6ae4cefb47ec234517bcbfe1c5`，检查节点数量、位置和同种子可重复生成。提交`b74dd0f8cdec4657ee1a4bd9147e47d85e61562c`修改`world_main.gd`，**在NPC调度器setup之前**执行资源播种；并把硬编码Qwen3 UI标题改为玩家自行选择模型。提交`6dfeaa8015f9689eb497cd3930313aeaeede8689`更新Godot CI同时跑守恒与世界播种测试，并添加pipefail。

**关键限制**：当前完成的是权威模拟层真实坐标/储量/派工前播种，尚未将每个资源点绑定到授权3D资产渲染节点，不能说手机中已经能看见完整森林/矿区；地形/道路空间避让仍为初步规则，尚需碰撞与导航验证。CI本轮未读取实际运行结果，标记PENDING。未生成原版签名PCK，原版仍rev178。


## 2026-10-17 / WORLD-006-VISUAL-DEBUG / 资源位置和储量可视化调试

依总纲和AGENTS.md推进：新增`game-source/godot3d/scripts/world_resource_visuals.gd`（提交`b18a0480f1d10c5bcf29161ffdab7c83a7c6a846`），为播种后的自然节点与农田创建真实3D世界坐标的Label3D调试标识；每秒从权威模拟读取节点ID、类型、当前储量/容量，耗尽时隐藏，恢复后重新显示；农田显示成熟或生长状态。此显示层**不生成资源，不修改库存，不是正式树木/矿石模型**。主世界`world_main.gd`已接入显示层，提交`59d368b520d832e15c25f7f7af64e6aa2e4437e0`。

**QA门禁**：仅确认GitHub提交成功；本轮没有真实Godot运行结果、画面截图或Android实机数据，不得称画面已验收。下一批需优先处理：已导入CC0树木/石矿素材实际绑定与许可审计、碰撞及寻路、真实CI失败诊断；同时检查原版APK176兼容桥与签名PCK发行阻塞。**原版OTA未更新。**


## 2026-10-17 / ECO-007-REAL-CC0-VISUALS-AND-LOGISTICS-P0

本轮不再只堆调试标签：真实资源视觉系统`world_resource_visuals.gd`使用**已在公开仓库真实导入且有来源记录**的Kenney CC0 `tree_oak.glb`与`rocks-small.glb`，按权威节点ID/坐标实例化32个3D模型；每秒根据自然节点剩余储量切换显隐，树木按剩余比例显示成长缩放。资源标识保留为开发调试（不算正式完整风格QA）。提交`ae2fb48354e6b536a86f18e03aeedfa82e0142b5`。未擅自创建新模型或改变库存。

发现此前世界生成器播种7个农田已占满`fields=7`额度，导致既有玩家交互农田`FIELD-LOOP`登记失败，形成P0玩法回归。现世界播种6块预置农田，给原交互工作区保留1块；提交`ab43c378ab4e8d8ea7191b8dde65fc60b263d2af`，播种回归调整`fce6f42827f499d308b901919a749eb7fe20ee44`，主世界检查调整`49ec0170feab2983f5016adfb6a405e63a3a6435`。

发现`worldbox_life_sim.gd.harvest_field`旧API可在没有运输的情况下直接把粮食写入村庄仓库，违反守恒与真实物流。提交`032cde58f53489e6fbccb7805ee132fb19bc5e8a`改为调用`gather_field_to_actor`，只将粮食记入搬运者负载；`worldbox_visible_worksite.gd`提交`8744abeb7e46cc1ab4695286ad86db5b2489f260`让交互收割后必须走到仓库才能确认入库（该旧演示场景仍包含临时BoxMesh其他对象，**未达到正式美术标准**）。资源守恒回归测试增加重复采集/重复入库防护，提交`158ea9f5dc632709c741a63825a636ca434c7d1b`。

此前`autonomous_job_smoke.gd`仍依赖已被移除的`natural_art`方块节点并严格断言旧8+2结构，不能用于新资源生成器；现按真实资源位置验证NPC采集/搬运/两名农民交货，提交`f1edbab91c4b3945f764142d0e91f9b5ef5e4996`。Godot CI增加GLB导入、完整3D主世界和NPC运输集成检查，提交`127b27f1d740985d18e07d137ae26864e5cf88bd`。

**QA状态：本次只确认源码实际提交，Godot CI未读取成功结果，不标通过；Android原版APK176签名OTA仍未更新，手机未验收。** 仍需优化寻路避障、素材统一风格、替换演示场景临时方块，审查原版PCK兼容及合法生产签名链。


## 2026-10-17 / REL-FAST-GATE-001 / 用户要求精简测试流程而不降低安全

本轮将“快速进原版手机看画面”作为优先目标，不再每批盲目重复完整Godot资产导入、全量构建和模拟CI，也不接受以独立3D原型APK替代原安装包。

**已经真实提交：**
- `tools/quick_view_preflight.py` 提交 `d19cb7db52f6cebeb90e91b283a850102b3ea5f3`，只读、快速检查公开原版APK176的包名1176、正式更新通道rev、固定HTTPS地址、manifest签名字段、3D候选完整性和原版入口验收fixture；输出精简JSON阻塞报告。不生成不签发PCK，不修改latest.json，不泄漏密钥。必须明确：有签名字段不是新内容签名通过。
- `.github/workflows/canglan-one-click-original-quick-view.yml` 提交 `9074889ba5753c9e536dadb0e81a05ac4935ff2c`，手动触发一键前置门禁：先快查原版身份及既有RSA验证回归，再检查由公开Actions秘密环境注入的生产私钥是否与APK176内原公钥一致；缺私钥立即停止，不下载Godot与任何资源，不执行无效的长耗时构建。始终保存无密钥的短报告，默认**从不自动发布**。修正测试入口调用提交 `888e4d4c9987f8283a689eb72918f4c5bf1a39dd`。
- `tools/test_ota_release_gate.py` 修复过时硬编码revision177预期（目前正式基线是rev178），改为依当前live版本动态检查下一个修订严格递增，提交 `4740d12c2c38ec5609a808e4e4cc67e99b46f6a6`。这是避免门禁被旧常数卡死的直接优化。

**新的简化门禁**：第一层约几秒级的仓库静态与固定公钥验签/秘钥就绪检查（缺项早停）→仅第一层可发布条件满足时才在原APK176场景执行兼容和玩家/存档QA→根据真实候选计算PCK哈希/大小，生产RSA签名并再次使用固定原公钥检验→网页manifest+包同步发布、HTTP再次核对→用户原已安装游戏验收。每一层只测自己负责的不变量，避免对同一变更反复安装Godot和重复跑几套相同集成测试。

**真实状态**：workflow及脚本提交成功，但当前GitHub连接不提供workflow_dispatch执行命令，本轮未实际触发/取得该门禁的运行结果；不能称快速门禁PASS。原版主场景能否装载新3D及原RSA签发密钥是否已经恢复均待实际验证；**rev178未改、无手机热更新、没有要求用户换APK**。下次验证应以CI artifact的独立结果为依据，不允许猜测。


## 2026-10-17 / QA-FAST-002 / 去重CI、优先原APK176快速可发布性门禁

用户要求继续精简但不犯错，研发重点仍是**原游戏能否通过合法OTA进入手机**，不增加新玩法以免扩大不可交付积压。

**已提交的真实变更：**
- `.github/workflows/canglan-resource-conservation-qa.yml` 提交 `63b493236ab51d0744ee747dde000687e05b351b`：取消与主NPC研发CI重复的每次push自动运行，保留`workflow_dispatch`作为人工深入诊断。节省重复下载Godot、重复资源导入。
- `.github/workflows/canglan-npc-material-build-qa.yml` 提交 `302db30650ebb151b5becdbee4b4db24e397e62d`：使用**一次Godot 4.4.1下载及一次真实GLB导入**，同一次主流水线依次验证1000 tick资源守恒、确定性资源播种、既有NPC采集运输、建筑工地、本地AI意向规则，并上传各阶段日志。受资源脚本变更触发主流水线，不再自动触发第二套独立资源QA。
- `game-source/godot3d/scripts/world_resource_seeder.gd` 提交 `60dfe41696fbc88f86db7577c0ed239d89e28c07`：清理一处注释内误留下的字面`\\n\\t`字符，避免代码审阅混淆。

**简化后单通道：** 先执行公开仓库手动快速原版签名/更新前置门禁（上轮`canglan-one-click-original-quick-view.yml`）；签名不具备则跳过新PCK构建，直接报告阻塞。源代码常规提交只跑合并后的唯一Godot主集成CI；确定原版兼容及签名具备后，才运行旧APK176主场景真正验证/构建、原RSA验签、官网发布与手机现场验收。测试类别未删除，只消除重复导入和错误的rev177常数。

**实际验收状态：** GitHub文件更新完成，但当前连接未提供可直接运行workflow_dispatch并取得结果的API；没有Godot日志证明最新合并流水线PASS，没有合法新revision PCK签发，也没有改`android-preview/latest.json`，原游戏仍rev178。严禁写“已经更新手机”。


## 2026-10-17 / REL-QUICK-VIEW-003 / 快速发布门禁自动启动一次

用户继续要求优先进入手机原版游戏。本轮修改`.github/workflows/canglan-one-click-original-quick-view.yml`，提交`0964738c518cbfec44115c4c9e4659eb6d3ccd15`：保留手动`workflow_dispatch`，同时仅当**这个门禁工作流自身变更并提交main**时自动触发一次快速检查；其它开发提交不重复触发这个昂贵/无意义的发布检查。检查内容仍为原APK176发布身份、已签的官方更新清单固定公钥验证、原生产签名私钥是否注入及密钥匹配。缺原私钥绝不尝试发布，也不访问任何私有仓库。没有触发签名、修改manifest或者发APK。

**执行证据边界**：GitHub已返回提交SHA。当前GitHub连接的`fetch_commit_workflow_runs`仅查询PR类运行，提交查询为空不能推断push作业成功/失败；网页查询也未取得可用日志。因此快速门禁的实际运行结论**未确认**，后续需读取公开Actions run/产出的`Canglan-original-quick-view-preflight-...`证据。完整3D旧APK176主场景兼容与原RSA签名仍是P0阻塞，正式rev178未修改，手机尚无新更新。


## 2026-10-17 / REL-SIGNER-RECOVERED-004 / 原版RSA密钥恢复：真实GitHub重新验签PASS

用户明确告知“密钥修复了的，可以直接发布”。本轮**实际重跑**公开仓库 GitHub Actions 之前失败的原APK176签名检查 job `117038701416`，重新运行产生 job `117176737579`，run `38920447159`。GitHub连接返回 rerun `success=true`，随后实际读取最新job结论 **`completed/success`**，读取新的作业日志包含：`original_signing_key_candidates_available=1`、`original_rsa_key_matches_apk176=true`、`safe_to_sign_original_ota=true`。**因此原版内容RSA签发能力此刻确认恢复**，旧日志中零密钥的阻塞已解除。未读取、打印、提交或持久化私钥。

**不可直接用旧rev178发布脚本**：公开站`android-preview/latest.json`当前已是合法正式revision 178；`tools/publish_original_rev178_ota.py`写死`REVISION=178`、parent revision177、原rev178内容hash和固定老测试artifacts。重跑此工具会被正确拦截，不能产生含新3D资源的revision179。新3D项目`game-source/godot3d`尚未通过*原APK176导出资源的主场景*及手机验收，不能直接照搬成旧版签名PCK。下一步需产生**实际含可见3D资源/场景挂接的原版rev179候选**，跑原APK176场景及存档兼容QA，再对rev179具体PCK使用已经确认恢复的原RSA私钥签发、发行HTTPS并由手机验证。绝不重签rev178冒充新资源更新。

**本轮状态**：RSA签名阻塞✅已解除（真实GitHub QA日志）；可发行rev179 PCK❌尚未构建和验收；正式latest.json未修改，手机仍rev178。只用公开仓库。


## 2026-10-17 / REL-NEXT-179 / 新增动态下一修订候选暂存器

已经提交 `tools/stage_original_next_ota.py`，提交号 `cc0b78f5525a488b3f0b25f9a34f9d4b0f31087e`。相对原先写死rev178的发布器，此工具按当前已签署的公开latest.json计算下一修订，要求签名前出示PCK文件、未签署的原版APK176测试候选清单及运行日志；核验包名、1176版本、PCK哈希/长度、原签名、签署后使用APK176固定公钥重验。仅暂存到独立输出目录，**不会自动写官网latest.json、不自动发布、更不生成独立APK**。其`--original-qa-success`开关必须由调用工作流核查真实成功状态后提供，目前没有一条合格的rev179原APK176三维场景构建/启动流水线来调用它，因此目前只是发行候选工具，还不能上架。尚未取得新rev179可用PCK、运行日志、手机截图；原版仍rev178。注意旧rev178叠加HD2D资源不能当作用户要求的3D新内容发布，下一步必需真正的三维场景兼容验收。


## 2026-10-17 / REL-3D-179-SIGNED-ORIGINAL-APK-PIPELINE / 首次将真实CC0三维预览接入原APK176发布链

本轮按用户“先进入原游戏看画面”的要求，不再只堆独立3D技术工程。已完成以下**真实源码提交**：

- `game-source/apk176-ota177-candidate/scripts/apk176_cc0_3d_preview.gd` 提交 `4a7d571c34be45d7e0a04eb5ab80159a9109085a`：在**原游戏主场景内**以CanvasLayer+SubViewport/Camera3D加载Kenney CC0原版GLB字节，经Godot GLTFDocument真正解析出3D场景并创建16棵橡树/10处石块实例，显示真实光照及技术地面，可点击返回原游戏/重新打开。明确仅为**视觉观察室**，未实现原大世界NPC生产自治、未修改玩家存档、不引入新APK。为避免透明全屏UI层窃取旧游戏触控，提交 `c4487ead42a056cdcd6a0d3686d837a565cf8e85` 加强鼠标/触控穿透。
- `game-source/apk176-ota177-candidate/scenes/main_original_3d_preview_rev179.tscn` 提交 `c26b820439b523382895b8f99cc4d9ac2faeaad4`：**继承APK176真实编译Main**并保留之前HD2D/室内返回功能，在同一节点树挂真实3D CC0观察室；`scenes/main_rev179.tscn.remap` 提交 `8f04c0d572a470c1ccc6a53b09993177eee13a9a`。
- `logic-qa/tools/build_apk176_3d_preview.gd` 提交 `21e81443d3224e462ebd69f365b8666d205d246a`：新的原游戏PCK打包脚本使用原主场景remap、复用旧素材交互及两份**已有授权Kenney GLB实文件**，没有自建正式树石模型，也没有拿独立3D游戏替代旧APK。
- `logic-qa/apk176-export-fixture/verify_original_main_3d_preview_rev179.gd` 提交 `9bed56586a7c3cd85fd41dca749a51fe226f7e83`、加强真实MeshInstance和触控穿透检查提交 `7fc19c4485edd16abbeaa2a356dfd90bb8465aa1`：严格要求原APK176导出资源内真实主场景能够加载包含26个许可GLB三维实体的SubViewport，并验证关闭和重新打开。
- `tools/stage_original_next_ota.py` 补充3D视觉目标与运行日志特征双重验证，提交 `81c3584feb0fb7819075ee9885b5da415dd5a604`，防止把旧HD2D候选简单改名rev179后签发。
- `.github/workflows/canglan-apk176-rev179-real3d-signed.yml` 提交 `164146d17ad2f7bf088012338bc44701057043e3`，并在 `f9f13ab4bcca05f606bbb8b8c0ca3d8c8b36dd03` 加固：一条真实原APK176流水线恢复旧版导出资源、确认Terrain3D版本、构建原版PCK、执行真实原APK176 3D预览及旧正房进出回归、生成未签候选、用已恢复的原RSA密钥签发并用原公钥验签，**只有全部通过才发布rev179到同一个正式Android更新频道**。旧rev178不会被无条件重签，新rev179只有校验合格才替换，不发布独立APK。新工作流按变更自动触发且取消被更新替代的构建。

**实际发布状态仍须以公开GitHub Actions的运行结论及`android-preview/latest.json`版本为准**。本轮只确认提交成功，当前连接没有列出新工作流的run ID和完成结果，不允许称rev179已发布。Android用户实机启动、更新UI加载及存档验收仍未完成。即便rev179经原APK176运行QA最终发布，用户看到的先是“可退出的Kenney CC0真3D树林/矿石观察室”，不是完整NPC生态与新3D大世界；后续真实世界整合仍需持续推进。


## 2026-10-17 / REV179-QA-SAFETY-008 / 原版3D候选的真实PCK字节审计与返回交互修复

本批没有堆新场景；聚焦之前已提交的原APK176真3D rev179发布链潜在发布事故：

1. 新增`tools/verify_apk176_rev179_3d_pck.py`（提交 `408c8f3dc2674e7acbeef85d2c57d5b3b9f3c215`）：逐项读取Godot 4.4 PCK v2资源索引和校验资源MD5，确认仍指向**原APK176编译主场景**、包含原版返回/房屋脚本及真3D脚本、两份Kenney GLB真实二进制头与长度正确，并与仓库已授权源模型逐字节SHA-256匹配。阻止把LFS指针/损坏GLB/2D假场景签名发布。
2. 原APK176 rev179流水线已在Godot引擎运行前加入这项校验（提交 `aa7674ced8584739fa74f1cd17443015d31e393a`）；校验失败直接停止，不进行签名和更新清单覆盖。
3. 发现旧rev178 HD2D CanvasLayer在新3D预览关闭后仍遮住原游戏世界。现3D预览就绪时先关闭旧HD2D界面但**保留旧节点与功能**，退出预览时真正露出原3D世界（提交 `c03a425fe26c18ad2fb9f1a23db25cdfb945a7b9`）；新增原APK176 Godot用例断言旧2D界面未挡住3D（提交 `bbdb311f2e9c3b9e896151e5f73d5de49f1edcb4`）。

**真实状态**：源码已在公开GitHub提交；本次GitHub连接未返回新rev179流水线的实际跑完结论，未取得全量Godot runtime输出、安卓设备更新证据或已发布PCK。再次读取正式版本仍为rev178，**不能说手机已可更新rev179**。后续只能按GitHub真实CI运行产物、官网latest.json及手机验收三方证据升级状态灯。


## 2026-10-17 / REV179-FAIL-REAL-LOG-38963284512 / 按用户提供的具体失败Actions日志修复

**真实失败定位（不是猜测）**：用户提供的GitHub Actions运行`38963284512` / job `117183464134`，公开连接读取了完整job步骤与真实日志。1-6步成功：恢复真实APK176资产、Terrain3D v1.0.2精确匹配、Godot4.4.1下载、26条资源PCK索引/双GLB SHA完整性验收PASS（21,059,168字节）；**第7步Godot原APK176实时3D场景验收失败**，错误为 `GLTFDocument.append_from_buffer`中`p_base_path.is_empty()`导致图像解析失败，以及`FAIL_APK176_REV179_3D_PREVIEW no_real_Godot_3d_renderer`。后续rev179候选签名/发布步骤按门禁被正确跳过。并非RSA密钥失效，也不是PCK没有打包。

**真实修复代码**：
- `game-source/apk176-ota177-candidate/scripts/apk176_cc0_3d_preview.gd` 提交 `99406392dbb182cb910d2966c996736ac3f9f62a`：Godot GLB内贴图解析需要非空基路径，把错误的`append_from_buffer(data, "", state)`改为`append_from_buffer(data, path.get_base_dir(), state)`，不修改源模型和授权。
- `logic-qa/apk176-export-fixture/verify_original_main_3d_preview_rev179.gd` 提交 `61aa64b697ba06bf74e075a8e8f5cae18a6b4876`：将Godot SubViewport场景验收由`viewport.world_3d`改用`viewport.get_world_3d()`查询实际使用的3D World（`own_world_3d`是开关，不是拿资源的断言接口）。
- 现有rev179工作流已监听这两份源码路径，提交后将按既有门禁重新执行。**本批只证实GitHub修复代码提交，未取得新一轮Godot成功或rev179更新成功的运行证据**。正式`android-preview/latest.json`仍须等待真实原版3D渲染、房屋/存档回归、RSA验签及推送同时满足后才能改为rev179。未改官网live或重新安装APK。


## 2026-10-17 / REV179-FAIL-38963913645 / 从第二次真实GitHub日志修复共享调色板与无屏测试误判

用户提供的运行URL对应 run `38963913645` / job `117185731063`。**实际运行记录**确认1~6步成功，包括原APK176导出资源与准确版本Terrain3D、Godot4.4.1及PCK真GLB逐字节检查；第7步失败。日志与上次不同，暴露两个独立问题：`GLTFDocument`解析rocks模型时找不到`res://Textures/colormap.png`（Kenney Castle Kit原本就有独立共享贴图，之前只打包GLB漏了贴图）；另外无显示设备的`--headless`环境`SubViewport.get_world_3d()`为空，验证脚本直接归为`no_real_Godot_3d_renderer`，但日志已有实际新增MeshInstance3D和正常移动渲染模式的运行证据。**不是RSA失败，也不是PCK/场景主入口资源缺失**。

本轮真实修复：
- `logic-qa/tools/build_apk176_3d_preview.gd` 提交`453bc880acd55ab79fe1a2577a32ca8bdfbca5a9`：把Kenney原包共享贴图 `Textures/colormap.png` 放入原版APK176 PCK同名路径。
- `.github/workflows/canglan-apk176-rev179-real3d-signed.yml` 提交`f223c0f20dede781305c1290798c9047a679287e`：从公开Kenney CC0素材镜像读取原包独立调色板PNG，校验PNG magic和合理尺寸后才运行原版游戏测试，不通过则停止构建。Kenney官方关于GLB引用的外部贴图要求亦明确需要复制相邻Textures目录，不能用空白占位图假冒完整素材。
- `logic-qa/apk176-export-fixture/verify_original_main_3d_preview_rev179.gd` 提交`38809bee7722b5e92e8b16489370dc20c48676e6`：无屏Godot验证关注真实存在的SubViewport节点、own_world_3d开关、1280x720尺寸、Camera3D、26个授权GLB实例及渲染MeshInstance节点；不以headless的World3D空值伪装失败。更严格的手机实际截图仍待验收。
- `tools/verify_apk176_rev179_3d_pck.py` 提交`a3975d5b8fe405e9f8a5f79adf00046ec77c82c4`：把共享PNG列入PCK必有文件，校验魔数，避免签出仍丢色彩的3D模型。

**状态**：本次修改均返回真实GitHub提交记录，但当前回合尚未获取这些最新提交所触发的rev179流水线成功结果；正式旧游戏更新清单是否升至rev179必须重新查`android-preview/latest.json`并用新运行结果验证。原RSA已单独实际通过，不需重复配置。未声称手机已更新。


## 2026-10-17 / REL-179-FINAL-PUSH-CONFLICT / 修复最后一步并发提交冲突

用户提供真实GitHub运行 `38964273466`、job `117186774293` 和手机截图；连接读取的真实日志显示**步骤1~10全部通过**，包括旧APK176 Godot原主场景+26件Kenney CC0素材的3D检查、原房屋进出回归、rev179 PCK（21066816字节、SHA256 `b1317883b1f884264b6a4a6e063683c2fb0cb324d13c81003564a8ff84a6a4e1`）、**原版生产RSA签名验签PASS**。仅**第11步GitHub push失败**：`! [rejected] HEAD -> main (fetch first)`，因为CI开始后还有其他研发提交推高了公开main；Git没有权限将旧基础的发布commit直接快进推送。不是密钥缺失、场景解析失败或PCK无效。

已修改`.github/workflows/canglan-apk176-rev179-real3d-signed.yml`，提交`8f1581cadf93e3789dade9ae79af187fccf15b68`：签名候选通过后，发布器循环抓取origin/main，要求远端**仍为rev178且没有rev179 PCK**（否则阻止覆盖）；再仅对**已验证、内容不变的正式签名文件提交**做`git rebase origin/main`并push，最多3次有限重试。若新版由其他并行发布者先上线则立即停止，不乱覆盖。该流水线文件受push自身路径过滤，会自动触发新一轮构建。仍需核实本轮新run实际结论和正式网站rev179，不可仅凭提交成功称手机更新。


## 2026-10-17 / REL-179-PUBLISHED-IN-PUBLIC-MAIN / 原APK176签名真实3D预览rev179已进入公开仓库正式频道

本轮重新读取**实际公开仓库** `android-preview/latest.json`，正式通道已由rev178推进为**rev179**，`minimum_android_code=maximum_android_code=1176`，包名仍受原APK176门禁约束。GitHub仓库存在`android-preview/canglan-content-rev-179.pck`，最新发行提交 `74ad36cda135aab71e209deb106a0a6e4a2ccb7a`，提交标题为`release(official): APK176 RSA signed real-3D CC0 preview rev179 [skip ci]`，说明上轮git non-fast-forward冲突修复后**PCK与manifest已真正提交正式main**。manifest: SHA-256 `b1317883b1f884264b6a4a6e063683c2fb0cb324d13c81003564a8ff84a6a4e1`；大小`21066816`字节；地址`https://160701541-cell.github.io/xinyanshuo/android-preview/canglan-content-rev-179.pck`。该SHA与上轮实际CI `38964273466` 的原版RSA验签成功、完整Godot QA成功的签署候选一致。**源码仓库的正式发布已经完成。**

**严格界限**：本轮无法通过可用工具对GitHub Pages站点完成独立HTTP可达性与下载内容验证，尚无用户手机完成下载/装载的截图，不能冒充安卓实机验收完成。可立即请用户打开**原已安装的《苍岚》**内置更新器检查是否发现rev179（无需重装APK、勿清存档）。预期此次仅为可返回的Kenney CC0树木+石头3D预览，未实现完整NPC生态接管原版主世界。如手机仍检测不到rev179，下一优先级应审查Pages发布延时/缓存及客户端版本通道，而不是重复签发。


## 2026-10-17 / OTA179-USER-BROWSER-SHOWS-178 / P0网页CDN未升级，补全真实Pages部署而不重签

用户在**手机浏览器直接访问正式地址**确认显示`revision:178`，同时公开仓库main下`android-preview/latest.json`已经是`revision:179`且完整签名PCK rev179存在。这直接证明问题位于**源仓库到github.io网站的部署/缓存链**，暂时不应把问题归咎于手机版更新器，也不必重新签发PCK。

已在唯一公开仓库增加`.github/workflows/canglan-official-pages-ota-deploy.yml`，提交`bd016185e145d73868f87050705abf13cc41a7fc`。此前rev179成功的是`git push origin main`，并未显式执行GitHub Pages官方`configure-pages → upload-pages-artifact → deploy-pages`。新工作流只上传网站可公开的静态根文件和`android-preview/`等前端所需目录（不把game-source、签名密钥或任何私有代码打成公开部署artifact），先验证候选PCK SHA-256/长度及原1176版本边界，完成真实Pages部署后立即从CDN获取文件并运行`tools/verify_original_rev179_live_http.py`，核对用户原游戏的固定RSA、公网manifest版本、PCK字节以及1MiB分段下载能力；不合格则记录json，**绝不声称手机更新完成**。

注意GitHub Pages仓库设置必须允许**GitHub Actions为部署源**、且工作流要取得pages:write及id-token:write。当前仅确认GitHub工作流文件提交成功，仍需读取新的Actions运行/实际网页HTTP结果。若仓库Pages仍按Branch源工作，该发布工作流可能提示源配置错误；应以真实日志为准定位。旧rev179的正式签名PCK不需更改；手机端还未下载/验收。


## 2026-10-17 / REL-OTA179-PAGES-SOURCE-REPAIR / 实际用户浏览器停在rev178：继续查Pages配置并修复部署源

用户手机浏览器访问官方HTTPS`android-preview/latest.json`明确读到rev178，而公开main已包含通过原版RSA和Godot验收的rev179。故障指向**GitHub Pages发布/缓存**，不重签、不改游戏、不可报手机已成功。

本轮实改`.github/workflows/canglan-official-pages-ota-deploy.yml`：`cdbc1e4039d9351376828d7b3f4d132fb2b2a819`加入对GitHub Pages官方REST元信息的读取，把source/build_type、安全HTTP状态、不含任何令牌的配置诊断存于`qa-results/rev179-pages-configuration.json`，并纳入Actions artifact；`1c899cd45dfa354581d32a736460c0ded7b1a70c`在检测到旧`build_type=legacy`时尝试通过公开仓库自身`pages:write`授权REST切换为`build_type=workflow`，若平台拒绝则给明确的Settings→Pages→Source=GitHub Actions阻塞提示。此流程之后会继续以官方Pages Artifact发布静态网站与rev179 PCK，再独立从实际CDN验证固定RSA、公网manifest、SHA及Range。保留原密钥与旧存档不动。

**真实性声明**：本轮确认的仍只是代码已提交；当前GitHub集成未暴露按workflow名查询最新运行的操作，且当前容器无法解析github.io；尚无新工作流成功日志、Pages HTTP成功结果或手机实测。因此仍不能标记官网rev179已上线。用户可提供最新Official Website and APK176 OTA - Deploy to Pages运行URL，优先直接读取作业日志继续消除具体阻塞。


## 2026-10-17 / OTA179-PAGES-FULL-RECOVERY / 自行定位与实测rev179 CDN可达性——已验收发布链，等待手机

用户不再愿意提供GitHub链接，要求“自己看”。本轮首次通过已授权公开仓库GitHub REST GET工作流列表精确找到最新运行，不再让用户复制Actions URL。

**实际证据**：
- `38966384092` / job `117193808589`：先前追加的“检查并自动切换Pages部署源”流程失败，日志显示GitHub Pages当前是`build_type=legacy`、source=`main:/`，API切换被拒绝。但事实证明这**不是用户必须手动修复的阻塞**：更早的`38965376371` / job `117190433146` 已使用GitHub Pages官方Actions部署方法成功，在runner公网实测 rev179 RSA/PCK/Range 全部通过。
- `38966415561`：原Pages自动`pages build and deployment`最终`success`，说明旧`main:/`发布链本身能成功发布，之前多个连续提交造成了流水线取消及缓存时序混乱。
- 因此清除不必要的legacy source迁移步骤，**恢复已经有真实成功记录的Pages直部署逻辑**，提交`b000f49681f1d468601f5e60a5cd1d17bf14df60`。
- 同时主动重试旧失败的公网诊断job `117189407985`，新的job `117195219763` / run `38965071226` **completed/success**：公网 `latest.json` 真实返回`revision=179`，原APK176固定RSA验签成功；公网PCK长`21,066,816`字节，SHA256 `b1317883b1f884264b6a4a6e063683c2fb0cb324d13c81003564a8ff84a6a4e1`，HTTP Range返回206，公网缓存头`Cache-Control: max-age=600`。
- 恢复后官方官网部署新run `38966857594` / job `117195356245` **completed/success**；日志明确`PASS_PAGES_SITE_CONTAINS_SIGNED_ORIGINAL_OTA 179`、`Reported success!`及`PASS_REV179_PUBLIC_HTTPS_RSA_SHA256_AND_RANGE`。**可确定远程正式官网已是rev179且可完整下载和断点续传**，不必重签补丁，不必切换Pages Source，也无需再跑Godot构建。

**剩余唯一不可代替环节**：用户原已安装的Android APK176应用内点击检查更新并实测下载/装载，仍待现场结果。之前用户的浏览器看到178时，官网发布可能尚未完成，且文件声明`max-age=600`（最多10分钟公共缓存），不说明当前仍是178。可用手机浏览器带查询参数`?v=179`单独观察源站rev179；游戏固定manifest URL是否有额外Android HTTP缓存需以新一次原版应用内检查结果判断。无论如何，绝不可宣称手机验收通过。
