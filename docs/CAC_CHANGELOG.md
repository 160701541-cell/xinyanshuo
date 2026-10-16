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
