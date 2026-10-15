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
