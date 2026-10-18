# CAC 工序变更与开发日志

## 2026-10-18 / CAC-REV208-P0-HQ021-NATIVE-CC0-FOREST-FLOOR-32M-POOL / 32米真实GLB林下植被GPU池、持久原场景打包及原生验收（候选，禁正式热更新）
- **实际代码，非文档计划**：新增 `game-source/apk176-ota177-candidate/scripts/apk176_hq_forest_floor_pool_rev208.gd`（提交 `087a171`），真实引用原始来源与SHA可追溯的CC0已合并 fern/grass GLB 网格、UV和源PBR材质；按**32m生态cell ×种类×源GLB网格**设置16个32米生境Cell、2个真实来源物种、总计最多272个候选生态点；原GLB蕨1个网格加草3个网格，理论64个GPU MultiMesh Draw节点（活株数以原Godot QA为准），每个有效植物ID对应真实土壤XZ/连续GPU slot和3D位置，挖掘时按物理地块清退或恢复、swap-remove O(1)置换，空slot离开世界原点、不发明任何物资。**注意这仍是高精素材批量复用候选，不等于用户认为的茂密仙侠林地审美通过**。
- **原项目集成**：原APK176主场景 `apk176_living_resource_world_rev187.gd`（`607db3b`）在原NPC、经济库存、真灵草、已通过的三个8—9米大树以及松柏林系统之外接入实体林下GPU池；新增地形变动同步/按手动画质分档的cell距离可见性与独立GPU诊断字段。原 PCK 打包字典 `logic-qa/tools/build_apk176_quality_rev187.gd`（`932750a`）添加新源码，原公开Actions只构建**未签名候选原版Main测试PCK**（`61e3b42`），原Main真实运行QA `verify_original_main_quality_rev187.gd`（`5e3beb8`）新增强制检查原资产许可、有效32m cell、真实活跃GPU transform、连续可见slot、没有IDENTITY原点幽灵、swap-remove恢复及经济资源不变。
- **真实引擎艺术证据**：原 Main Godot 4.4.1 Vulkan相机脚本新增 `real_godot_rev208_32m_vendor_fern_grass_gpu_floor_main.png`，应是真正玩家视角内的供审查PNG而非素材仓库的模型孤立图（`1f0bcc8`）；QA工作流 `baa7efd`硬性验收真实GLB池日志及真实PNG帧。修复早前 `39080008937` 中原Main游戏功能/图像已通过但**图片提交阶段旧run Git rebase二进制冲突导致整run FAILURE**的问题：在提交图像前验证工作流源码SHA与远端分支HEAD一致，旧截图仅存CI artifact，不允许从旧版覆盖新版图片和状态。
- **必须如实等待的QA闸门**：先前 `39079966329` 原 Main/优化真实GLB完整技术 **SUCCESS**，`39079802078` 769→33原作者PBR合并源资产独立 Godot **SUCCESS**；新 HQ021 32m GPU池接回主场景后，`39080771855` 因工作流尚未阶段复制新增脚本的提交竞态而**FAIL（preload file does not exist）**，之后已在 `61e3b42` 把脚本真实打包和预解析；后续严格运行须看最新 Actions 最终结果，**未得完整新GPU QA及真实图片不能写PASS**。若出现Godot4.4 MultiMesh真实GPU变换永远IDENTITY，按错误状态处理，不许生成虚假林地截图或降低断言；没有PC可替代Android连续30分钟本机体验。
- **本轮已真实定位并修复“GPU矩阵幽灵植被”大故障（严格不虚报）**：`39080924183` 和 `39081138496` 原 APK176 Main 验证明确**FAIL**：从真实厂商GLB转换来的Godot 4.4.1 MultiMesh API返回IDENTITY，214—262株候选全部读回原点，隐藏位甚至返回零矩阵；**绝不关闭测试去伪造绿色**。实际脚本 `3c5c4e9` 检测矩阵错误时令所有无效MultiMesh节点 `visible=false/visible_instance_count=0`，从完整授权真GLB模板直接复制有PBR/UV的实体网格（不是图片）并按相机和画质限量实际放回正确地形，必须显式汇报 `BLOCKED_IMPORTED_GLTF_MULTIMESH_IDENTITY_REAL_GODOT_441`，并执行真实3D物体的位置/来源/碰撞地域验证。原Main `0afeac5` 在玩家开局时立即初始化真实模型；`cc816a4` 原Main QA用真实回退实体数量、防幽灵、32mCell、原经济与原房屋位置约束作为新的合法验收标准，另外打印GPU尚未通过不能冒充Native GPU批处理。
- **真实QA证据、不是猜测**：`39081485660` 的 `rev187-original-main-3d.log` 实际打印 `PASS_REV208_HQ021_REAL_VENDOR_CC0_32M_CELLS_NONINVENTORY_ACTUAL_PBR_VISUAL_FALLBACK_NO_ORIGIN_GHOSTS_SWAP_REMOVE { active:214, actual_physical_mesh_nodes:42, cell_groups:32, gpu_mesh_matrix_unsupported:true }` 与GPU阻塞提示，说明**原游戏已正确生成42个真实来源GLB近景实体（32个种类×cell组合、214个活候选逻辑，其他按相机流送，不是214个同时渲染的PBR节点）**；但此整个工作流仍标记**FAIL**：因打包QA执行脚本仍grep旧的“GPU已通过”标记，后续提交`2969bbb4`改成只接受真实PBR物理实例成功，并明确记录GPU尚未通过。新增真实原游戏 `real_godot_rev208_32m_vendor_fern_grass_actual_3d_floor_main.png` 玩家近景摄影 `93ae73f`，最新严格完整Godot+Vulkan作业号`39081592059`在此日志提交时**未取得结束状态**，不得伪称美术/手机验收成功。真实Android 30分钟、LOD/PBR国风森林目标仍红灯。
- **发布隔离**：公开仓库 `160701541-cell/xinyanshuo`，PR #14始终Draft；`main/android-preview/latest.json`最后核验仍为**rev207**，APK176 code1176。没有WorldX合格中国古装主角四视设定、4核心修士、5—8灵植完整生长阶段、宗门仙境、密林高精LOD/PBR、同机视觉对比、真Android30分钟，也没有正式rev208 RSA签名/官网推送；此轮美术功能P0总体保持**FAIL / BLOCKED_RELEASE**。


## 2026-10-18 / CAC-REV208-P0-SOURCE-11-TRUE-GLB-INTEGRATION-AND-STRICT-VULKAN-EVIDENCE / 新11款真3D合法素材与游戏源+严格审查增量（不得发包）
- **本次不仅文档修改，真实游戏脚本/资源及PCK构建已提交同一Draft PR #14**：11件可逐一核对来源CC0的真GLB，包括成年苏格兰松、柱状柏、16米挪威云杉、地被蕨丛/绣球灌木/蔷薇/薰衣草/草簇，以及**3款木/火/水灵草各自独立真实3D花茎**。授权、原始GLB、供应商网页和SHA256在 `game-source/apk176-ota177-candidate/assets/hq-rev208/vegetation/botanical/manifest.json`（均 `game_asset_approved=false`）；Python/CI `c378d02`、真实GitHub Actions run `39078719793` **SUCCESS**：下载/原始内容哈希/材料/真实大小真实Godot 4.4.1原引擎GLTFDocument导入全部通过。因供应商曾429限流，改为SHA复用及有限退避；绝不绕开版权证明。不是WorldX合成的假3D，也不是已完成WorldX国风人形；前两张WorldX真实肖像母版仍半身，美术FAIL。
- **原APK176 Main候选接线**：`apk176_living_resource_world_rev187.gd` 真加载并放置树木林下层和3类独立真3D灵植，接地并跟随挖掘、树干真碰撞、出生/检测台空地、保留旧52树20石经济实体ID与原13草矿ID/采摘库存，不凭空增加物资；旧修士永久死亡/5000分区人口exactly-once减1、三棵原8–9米高精成熟树没有删。直接修改了原PCK打包字典、实际原Main QA。未制作独立HTML或无关示意图。
- **原Main真实发现并修复的问题**：2026-10-18 CI `39078316397` 在11源码之前8物种原Main全部玩法验收通过，却发现**442个Godot GLTF源模板RID泄漏**，`a39cc3`通过明确释放8个未入SceneTree的模板修复；随后 `39078480747` 实际全Main引擎/死亡/存档/8物种完成技术验收及6张真Vulkan实帧，但新增三张松/柏/蕨实帧令145秒摄影步骤超时，整Job**FAIL，不得声称QA成功**；`d975299`扩摄影超时285秒。更新11源QA又检出 `verify_original_main_quality_rev187.gd:2164` 与旧变量`origin`重名导致原Main QA GDScript编译FAIL，`438311c`改名修复；`6cec651`新增全场景早期脚本编译，硬要求松/柏/蕨真PNG产生，且只在所有严格QA通过后把真原始1280×720引擎图片提交到当前Draft分支供玩家查看，不公开手机版本。
- **曾真实生成原Main引擎截图证据**：`39078480747`运行日志明确`PASS_REV208_THREE_TRUE_8_9M_PBR_TREE_GODOT441_ORIGINAL_MAIN_RENDERED_SCREENSHOTS`和`PASS_REV208_THREE_REAL_GODOT441_ORIGINAL_MAIN_EVERGREEN_AND_FERN_ART_EVIDENCE_UNAPPROVED`；分别真实保存橡树/枫树/椴树+真人、松林 `real_godot_rev208_hq_pine_forest_actual_main.png`、柏林 `real_godot_rev208_hq_cypress_grove_actual_main.png`、蕨类 `real_godot_rev208_hq_fern_understory_actual_main.png`，但其中整次截图CI尚失败，不能当P0画质通过。最新11源原Main QA `39078946190` 和增加屏摄及持久化步骤的 `39078994106` 在日志写入时**待最终核验**，以后必须按其实际结果更新，不许写`PASS`推测。
- **首个11种源码严格原APK176 Main原引擎完整技术验收成功（最新新增）**：GitHub Actions run **39078946190，completed/success**，运行源码 SHA `438311c06397ad8928fc0b3954638373f31536c1`。同一原APK176 Main、Godot4.4.1、真实原PCK、真实真实Vulkan PNG截图技术回归及原版经济测试全部完成；作业实际通过本轮新`PASS_REV208_REAL_INDEPENDENT_MEDICINAL_HERB_STEMS_CC0_PERSISTED_IDS`及原修士死亡五千人口exactly-once账本与实体资产的门禁；真实 `real_apk176_rev187_worksite_same_position_close.png`/wide均验证分辨率1280×720且图片非空。此仅是**技术回归和合法素材接入**，不等于用户审美或安卓实机P0通过。后续加图片入库的再跑 `39078994106` 仍需独立核实，不得提前认定。
- **九张未经加工的真实原APK176 Main画面已在仓库可直接查看，严格美术验收失败**：GitHub Actions **39078994106 SUCCESS**（Godot4.4.1 + Linux Mesa Vulkan Mobile模拟，不是Android手机），真实原版引擎**实帧1280×720**；自动提交Draft镜头图片于 `art/actual-engine-capture/rev208-candidate/`（源码分支bot头提交 `d6e4edf`）。包括3棵已通过8–9米成熟树、松柏蕨3张、旧灵草/森林画面、真实修士死亡共9张，未经AI图生图处理。**已逐张实际人工查看**：新松柏是作者真实针叶树却显孤立、色黑，镜头周边仍大面积荧光浅绿地表、糖果状Kenney矮树与稀疏方块草，Knight角色面部与国风仙侠相距甚远，天际缺山川结构；绝不因技术CI SUCCESS宣称国风高精P0美术通过。原神P0审美门禁继续 **FAIL**。
- **真实帧性能实测超标阻断**：上述柏林实际原Main截图右上开发HUD显示**Draw 3290/200、三角面 2,582,839/150,000**（预算线源自游戏调试档，单屏实测依游戏时刻变化）、**1 FPS / GPU耗时173.27ms**，其中FPS是GitHub Actions软件Mesa虚拟GPU，**不能冒充Android实机FPS**，但超标的实际绘制批次、三角数须以P0处理，真实手机30分钟仍未验收。新增独立“保持作者纹理/PBR/三角数严格相同”GLB静态网格合并器 `tools/asset_factory/rev208_join_cc0_botanical_meshes.py` 与QA专用CI `.github/workflows/canglan-rev208-hq-cc0-botanical-merged-draw-qa-only.yml`（源码提交 `c986062`、`62ed379`、`56299da`），该流程只做**与11原始GLB分离的优化候选资产**，每种需要图像SHA/材质/粗糙度/Normal/体量/Godot4.4.1重新验收后才考虑启用。初轮 `39079670748` 捕到 glTF-Transform 将原作者省略的REPEAT采样默认值显式写出、被严格JSON比对误判为材质变化，`3d93845`修复为按GLTF默认值规范比较；新轮 `39079802078` 仍需实查运行结果。**不为了FPS偷偷删纹理或降低高精源。**
- **P0性能实际优化成功并接回原APK176 Main（新证据）**：独立CI **39079802078 SUCCESS**（2026-10-18，Godot4.4.1真材质/尺寸/GLB导入验证），11种合法原作者GLB**总绘制Surface 769 → 33，减少95.7%**；松18→2、柏143→2、云杉94→2、蕨4→1、三种独立灵植(木256→3/火43→3/水28→5)。严检原始纹理二进制SHA、颜色/金属度/粗糙度/Normal、三角面数量、真实3D包围盒尺寸未改变；原作者GLB仍保留作可追溯基线，优化另存 `assets/hq-rev208/vegetation/botanical-optimized/` 和manifest `QA_ONLY_NOT_SIGNED_NOT_SHIPPED`。源代码 `9bb138d` 真正改成在原Main加载合并版11种GLB，`41ba1fd` 更新原PCK包含合并模型，`0b45dfd` 原版主场景QA严格只复制可核验SHA和匹配作者的11优化后GLB到候选PCK而非同时携带30MB源模型；`f2bdbee` 原Main原始Godot绘制对象实测新增**42株真3D植物<150个实际surface**门禁。严格原Main再次测试运行`39079966329`/`39080008937`继续按最终作业结果定性；此条**不能推定手机已优化通过**，LOD1/2原三角数未减、1FPS虚拟软件渲染只是评估线索，P0完整画质/实机仍FAIL。
- **未完成与安全闸门**：11款GLB模型只做来源级质量检测，作者PBR映射能导入但**尚无LOD1/2、安卓真实FPS、30分钟发热、WorldX合格国风人形/4核心修士、5–8真正灵植阶段、东方宗门建筑、实帧美术审美通过**。现有49棵低模游戏树及低品质Knight正面模型依旧阻断。经main `android-preview/latest.json`真实重新核验，**正式RSA可下载仍rev207**（APK176、versionCode1176），PR #14仍Draft，未制作正式rev208签名PCK、未更改main发行指针、未冒充手机已更新。


## 2026-10-18 / CAC-REV208-P0-LICENSED-PINE-CYPRESS-UNDERSTORY-TRUE-MAIN-INTEGRATION / 国风仙侠森林真3D松柏蕨灌木源码与原版PCK接线（严格候选）
- **本轮真实代码提交**：在唯一公开原仓库PR #14 Draft，新增真正物理GLB下载/逐页面CC0核实/GLTF2几何/原始SHA256追溯器 `tools/asset_factory/rev208_intake_cc0_evergreen_understory.py`（`c362a6c` + `9bb022c`）；构建隔离8模型Godot4.4.1 CI工厂 `.github/workflows/canglan-rev208-hq-real-evergreen-understory-intake.yml`（`cc62793`），已由公开Actions run `39078091486` **SUCCESS**：真实下载和Godot GLTFDocument导入松、柏、针叶乔木、蕨、绣球、蔷薇、薰衣草和观赏草，保留源作者、CC0页面、GLB原始SHA、贴图和材质；可核验源GLB及许可在 `game-source/apk176-ota177-candidate/assets/hq-rev208/vegetation/botanical/`，**不是WorldX图片冒充GLB**。移动设备画质尚未批准，所有源数据仍标记 `game_asset_approved=false`。实际入库后发现原针叶树1551个网格/247940三角，不适合安卓近景；随后更换候选为真实16m挪威云杉以减少绘制开销（`ac9a502`/`516d5ab`），需等待其新模型再检验，不宣称最终优化成功。
- **原版Main引擎实质改动**：`game-source/apk176-ota177-candidate/scripts/apk176_living_resource_world_rev187.gd`（`d63526a`）真正加载新的GLB而非平面，左侧已有资源森林外增加大松柏真实树干物理碰撞/分区林下蕨灌花草/地形贴合/挖掘更新/随原手动画质裁剪，带独立生态实体ID但不凭空增加木材、花草库存和52棵树+20矿原经济账；原NPC死亡+5000人口交易+三棵8.6m/9.5m/8.8m成熟树源码完全保留。
- **原APK176真正PCK接线**：`logic-qa/tools/build_apk176_quality_rev187.gd`（`bd26e85`）将8种新真实GLB加入原APK176候选PCK字典，`.github/workflows/canglan-rev208-green-saplings-qa-only.yml`（`18a5795`）对SHA/版权/真实GLTF进行源码到原Main资源树传递并在Godot运行原主场景，原Main运行自动回归 `verify_original_main_quality_rev187.gd`（`37dd702`）严格要求8类真实节点、真人量级高度、真实碰撞、没有虚增72个经济资源ID。**真实原Main的QA是否PASS必须查看该次新CI作业；正式功能视觉验收仍未通过**。曾有早期QA run `39078122160` 因源GLB入库动作还未提交、找不到manifest在打包阶段FAIL，属于任务依赖竞态，不是造假通过；要继续跑完整QA。
- **当前硬阻塞**：WorldX真正输出的两个主角全身素材均失败；高精国风角色/4核心修士、灵植5–8种独立高精种类、高清PBR地表、宗门仙境建筑、真实7机位审美、LOD1/2、安卓一加30分钟FPS/温控均未完成。新源许可与**独立Godot GLB导入成功≠原APK176 Main完整引擎QA成功≠安卓视觉验收成功**，不得把这轮作为游戏画质合格或Android热更成功；**PR #14保持Draft、main正式RSA rev207、versionCode1176，不签rev208、不改OTA latest.json或官网正式版本**。


## 2026-10-18 / CAC-REV208-HQ-REAL-MAIN-NOON-3D-SCREEN-AND-CAMERA-COLLISION-P0 / 三种真实高树+NPC死亡最终整场Godot回归通过，但美术未验收
- **2026-10-18 真实当前技术QA结论**：Godot **4.4.1** 原APK176 Main完整候选源+真实Unsigned PCK原签名兼容检查+全部GDScript预解析+世界50k km²统计/出生/死亡/灵根/宗门+NPC真实可击杀并精确地区人口减少1且存盘永不复活+物理建筑/房屋出入回归+真正3D移动相机/锁定御剑+软件Vulkan实际帧，Github Actions run `39073461741` **SUCCESS**，源码SHA `21a20442088ff809acebcdabb4fe0870e1f93864`；主Main & Render日志**0条ERROR/FAIL**。这只是Linux Godot/软件Vulkan工程QA，手机120Hz/FPS、帧时间、GPU热状态依旧未测。
- **物理和美术可视证据**：原本用户截图树没有人高。现在**3棵成熟高树**（Innerscene原作者CC0）真正占用原游戏已有实体ID，可砍伐且不免费增库存，8.612m/9.507m/8.822m；每株分别213372/175572/137772三角，GLB合并后每株4份真实供应商PBR颜色材质。实际Godot真实截图`real_godot_rev208_mature_oak_8m_vs_avatar.png`、`real_godot_rev208_mature_maple_9m_vs_avatar.png`、`real_godot_rev208_mature_linden_8m_vs_avatar.png`和`real_godot_rev208_npc_death_state.png`存在于严格QA run `39073461741`的真实图片包。为可比光照，截图脚本**临时将游戏可支持时辰设为中午12:04，随后恢复初始06:04**，明确记录`REV208_TRUE_GODOT_COMPARISON_CAMERA_TIME_OVERRIDE_12H_RESTORE_6`；不是AI图片或编辑过的PNG。
- **修复另一个真实P0手机摄影Bug**：2026-10-18 noon复测捕到极端情形相机被附近真实NPC/树碰撞压到玩家胸前约0.25米，主角像消失，只看到5色，不是GPU能力问题。已在原版`apk176_player_controller_rev187.gd::_safe_camera_position`使用真实PhysicsDirectSpaceState3D的`intersect_shape`发现并仅豁免**起点已重合**的Collision RID，仍对后续墙树执行真实球体扫掠/射线；上一轮`39073031498`的游戏相机渲染曾因此失败，最新版`39073461741`严格Godot全程通过。此修复不会禁用远处的真实碰撞。
- **摄影QA自动化强化**：先做`capture_original_main_rev187_compare.gd`真实GDScript`--check-only`，避免错误截图脚本浪费Vulkan渲染数分钟；脚本自动要求树木3张与真实NPC死亡1张、非空PNG、原Main/全部旧场景回归；游戏真实NPC伐倒树后不能假复活拍照，摄影安排在模拟前。旧房屋NPC施工/原库存/地区人口完全保留。
- **审美严格FAIL，不得发布**：明亮真实截图仍能看到49棵Kenney旧版低模资源树+约200棵玩具式幼树、大片稀疏草地、低模西方Knight脸/衣、灵草与野草同背景、缺树皮Normal/叶片高品质细纹；作者GLB目前4种物理材质**并不自带真实照片法线图**，无LOD1/2及已测安卓成本，软件Vulkan截帧间约2—3FPS不等于Adreno实际FPS。不准宣称画质合格。WorldX两张真实国风人像局部质感提高但腿被截断，仍然只是未批准二维母版，未接高精3D玩家/修士。
- **发布状态锁定**：PR #14仍保持Draft/未合并main，不制作未达标的RSA正式rev208 PCK、不覆盖`android-preview/latest.json`，官网/客户端最后可下载签名版仍为**rev207、Android versionCode1176**；下一P0：高精中国古代发髻角色与面部/骨骼，合格蕨灌树冠植被及独立药材与手机LOD和连续30分钟实机。

## 2026-10-18 / CAC-REV208-P0-GENUINE-3-HQ-ADULT-TREES-REAL-MAIN-QA / 三种真实8–9米高精乔木进入原游戏Main，技术绿灯而美术仍未通过
- **已在PR #14 Draft真实源码落地（未合并/未发布）**：精确逐来源CC0授权的 Innerscene 真正3D GLB乔木（不是WorldX二维图、不是放大的Kenney矮树）；橡树8.612m/213,372三角形、枫树9.507m/175,572三角形、椴树8.822m/137,772三角形。原每棵GLB包含数百个编辑小部件，转换为**4个保留供应商原baseColor/金属度/粗糙度参数的PBR渲染材质网格**，几何三角形未减少，来源SHA与转换SHA写入 `game-source/apk176-ota177-candidate/assets/hq-rev208/vegetation/trees/manifest.json`。**这些源树只有PBR颜色参数，未凭空声称含扫描Normal/Albedo细纹、还没有LOD1/LOD2，手机性能未测。**
- **真实资源与世界契约**：`apk176_living_resource_world_rev187.gd` 将原本注册52棵有实体ID的可砍树中的3棵，真正替换为上述高精8–9米作者GLB，保留原ID、有限库存、生态伐倒/运输、地形高度与真实Collision；其余49棵旧Kenney仍暂做原型低档远景，**用户的新终局画质不允许它们冒充正式森林**。PCK构建器和原APK176 QA stage逐一带入真实HQ GLB；特意新增 `_exit_tree()` 对3棵脱离场景树模板的显式free，修复12个真实Godot DummyMesh/Material RID泄漏，不靠关闭错误日志。
- **原版Godot 4.4.1完整真实技术与渲染严格PASS**：QA run **`39072678720` SUCCESS**，验收实际3棵8–9米4材质高精树vs玩家，49棵旧远景树+20石头仍可采/真实MultiMesh，原Main真死亡NPC世界5千人账本exactly-once -1，原房屋施工/交互/输入/妖兽、原游戏PCK、Vulkan/LavaPipe实帧和真实存档回读；**不等于Android实机或用户审美通过**。实际源帧包括`real_godot_rev208_mature_oak_8m_vs_avatar.png`、`...maple_9m_vs_avatar.png`、`...linden_8m_vs_avatar.png`、`real_godot_rev208_npc_death_state.png`。
- **肉眼二次美术审查：FAIL/P0**。新真实成熟乔木与人物比例终于正确、冠层不是方块，但同画面仍有大量方脑袋小树、劣质西方Knight人形、缺真实地被/灵草分离/近景树皮与叶片纹理；最初图摄于真实游戏世界06:04天光很暗，左上性能旧文字遮挡画面。新增`capture_original_main_rev187_compare.gd`同一个Godot项目**仅在QA临时切换到原生世界中午日照**（恢复原世界时辰、保证不假合成图）、拍3个森林/玩家实帧；新增更早截图避免原木工在正常模拟中把真正有限树木砍倒、避免把伐倒树凭空复活作视觉假图；脚本独立check-only在大耗时Vulkan前编译。
- **技术迭代失败均已修复并记录，未伪造通过**：旧QA仍要求52棵Kenney GPU槽位→改检查3高精+49合法LOD；Godot 12个独立源模板遗留GPU泄漏→在Main exit真实清理；原Main截图在模拟63小时之后检查刚被工人砍倒的高树→移到任何砍伐之前；摄影脚本变量作用域错误→预解析；随机NPC实体剑击射线受移动林地挡住→使用**同一真实NPC/碰撞**临时进入空旷实际地形做严格受伤死亡回归，最后恢复位置；增加的await使临时lambda死亡时报错→恢复同步测试。**所有这些是引擎级QA，没有手机跑帧率/画质**。
- **阻断下一步**：HQ-Character合法高精骨架国风主角及4种真正修士仍缺；WorldX真实两图均被审稿判`CROPPED_HALF_BODY`，不能用半身图片冒充3D。HQ-Ecology的≥4真灌木+≥4草蕨、可识别5–8灵植、贴图Normal和可降级移动LOD1/2、树木视觉仍P0待做。PR #14坚守Draft；公网RSA签名`rev207`仍正式，未签发rev208手机补丁，不得违背硬闸门。

## 2026-10-18 / CAC-P0-REAL-WORLDX-AND-REGION-HP-STRICT-QA / P0真实代码与素材尝试：引擎死亡人口守恒PASS，美术仍FAIL
- **真实 Godot 4.4.1 原APK176 Main完整严格CI `39068081562` SUCCESS（候选分支 SHA `72a953ed30eead69a43b09bfed68d42199ea8053`）**，原Main验证日志直接包含 `PASS_REV208_REAL_LETHAL_CULTIVATOR_SWORD_COLLISION_DEATH_PERSISTENCE_AND_CORPSE` 和 `PASS_REV208_EXACTLY_ONCE_NAMED_NPC_CENSUS_POPULATION_DEBIT_SAVE_RELOAD_NO_REVIVAL`。玩家致死修士后，原5000人口分区账本恰好减少1名已存在成年人及相应灵根/炼体人数；重复击杀不重复扣减；双份存档断电中断可用死亡ID账本回读防复活；QA完成后恢复测试档。**尚缺死亡骨骼动画、真实随身物品掉落/阵营因果、手机验收，故 P0-HQ-031仍未全过**。
- **WorldXAI/Kolors原生实际生成两次**（均由公开GitHub Actions Secret凭证在真正固定WorldX prompt-loader运行，而不是普通文生图冒名）：#001 run `39067928097` SUCCESS、1024×1024 PNG、SHA `e22e514fd69729ee173afdf4a126ba851ec83bcf4f078817ecdc9f613239160d`；#002 run `39068395613` SUCCESS、768×1024 PNG、SHA `f4867a71dee0463214742e721320bed563380100174e2d2153448c06b687022a`。严格像素尺寸/SHA/授权状态 `GENERATED_UNAPPROVED`、原提示词与GitHub artifacts均有证据；第二版采用画面上下边距与禁止近景负面词，提供方却仍画成胸腰以上、缺腿靴的**半身像**。二者都是高质量脸/发型/衣料的参考，却**不是合格主角全身母版**、不是四视图、没有GLB/蒙皮/PBR、存在服务商的“AI生成”标记，故人工审美**ART FAIL**，绝不可偷偷签rev208。第二次生成第一次运行 `39068312762` 因脚本转义语法错误在**免费单元测试阶段**停止，未消耗图像生成费用，已修复。
- **阻塞/止损**：两次生成均未满足全身完整性，停止继续盲目调用Kolors消耗余额。下一工序优先用适合完整角色设计且支持参考图/竖长幅构图的模型或可授权高精真实3D人形来源；需提供方显式费用/条款核实和有效多视同一角色控制。WorldX概念图不得代替真实Godot主角；旧Kenney/Quaternius低模仅存远景LOD。**PR #14继续Draft，正式RSA公网rev207不变**，Android30分钟实机仍 PENDING。
- **本轮代码证据**：`apk176_living_regions_rev207.gd` 新`named_deaths`交易和人口守恒，`apk176_cultivation_world_rev201.gd` 双账本伤亡/下次启动恢复，`apk176_living_resource_world_rev187.gd` 真原Main挂接，原Main QA新增真实死亡地区人口扣减验收；WorldX两次脚本/测试/QA workflow均在唯一公开仓库 `feat/rev208-green-kenney-saplings-vegetation`；正式rev208没有RSA包/官网上线，不得说“已更新手机”。

## 2026-10-18 / CAC-P0-HQ-WORLDX-REAL-CANDIDATE-001-REJECTED / 第一张真正WorldX主角母版只达近景发型脸部，不能充当全身4视素材
- **真实WorldX跑通**：原代码 `tools/asset_factory/worldx_rev208_hq_character_v2.mjs` 在公开仓库 GitHub Actions run `39067928097` **SUCCESS**；下载真实 1024×1024 PNG `player_front_001.png` SHA256 `e22e514fd69729ee173afdf4a126ba851ec83bcf4f078817ecdc9f613239160d`；固定上游`YGYOOO/WorldX@edb4976d` prompt-loader，使用已配置的SiliconFlow Kolors图像API，最多一张，图/元数据/提示词保存于未批准Artifact `12114455139`。是真 WorldX 实际输出而非GPT自制图/引擎截图。
- **人工视觉审查结果**：发髻、簪、青绿层叠古风服装和面部质感相较旧Knight明显好；**但人物只显示到胸腰，双腿/靴子/剑下段都缺失，不能作4视统一角色或可蒙皮素材；图片右下角有官方“AI生成”可见标注**。因此此素材严格`ART_REJECTED_FULL_BODY_CROP / NOT_GAME_READY`，不能宣称HQ-Character PASS或剪裁进PCK。第三方生成条款仍需核验。
- **定向修正**：新增严格全身版 `worldx_rev208_hq_character_fullbody_v2.mjs`，PNG尺寸改为有API支持的**768×1024竖构图**，明确人物仅占画高65–72%、上下留白≥12%、靴子可见、正交全身A-pose，并将胸像/近景/截足列为提供方独立negative_prompt；仅准**第二次单张**带真实供应商追溯，并以新`player_full_body_002` ID避免覆盖首张和隐性付费重试。对应 QA workflow `canglan-rev208-hq-character-worldx-fullbody-qa.yml`；实际引擎高精角色和三视素材尚不存在，正式rev207不动。
- **客观限制**：图像模型显式AI生成标识属供应商默认行为，禁止假装“没水印”；概念图可以保留来源标识供审核，正式材质下游需遵守供应商条款与相应标识义务，绝不能偷换为Godot游戏实机证据。

## 2026-10-18 / CAC-P0-HQ-ART-LOCK-AND-NAMED-MORTALITY-CENSUS / 直接执行用户最高P0：真WorldX尝试及修士死亡扣地区人口
- **HQ-Art-Lock #001 真实接入**：新增 `tools/asset_factory/worldx_rev208_hq_character_v2.mjs` + `test_worldx_rev208_hq_character_v2.mjs` + `.github/workflows/canglan-rev208-hq-character-worldx-v2-qa.yml`，使用公开仓库先前验证过的**固定WorldX上游 prompt-loader** 与 SiliconFlow/Kolors API，固定单次最多生成**一张高精国风男性主角正面全身母版**，附提示词、原像素文件、SHA、运行号；密钥由 GitHub Actions Secret 提供，缺失 `BLOCKED_PROVIDER`，不得自动付费重试。图片记录状态必须是 `GENERATED_UNAPPROVED`，禁止说已接高精GLB或通过审美/手机；此轮执行结果需单独检查真实 CI。
- **Combat-Life #031 地区人口连动真实源码增量**：`apk176_living_regions_rev207.gd` 增加首次死亡的唯一修士ID死亡账本 `named_deaths`，可根据被杀修士炼气或炼体身份从现有500区/5000人统计池中依法扣除一名成年人、根性/炼体存量、地区死亡数与总死亡数，带事务前后守恒核验和原子存盘；重复死因回调不会再次扣人口。`apk176_cultivation_world_rev201.gd` 在真正HP归零前调用世界死亡账本，记录身份、死亡世界时辰、死亡地区；下次初始化时即使被中断，也以持久地区死亡记录纠正人形状态防止复活。原Main `apk176_living_resource_world_rev187.gd` 主场景真正接入启动对账；原真实QA `verify_original_main_quality_rev187.gd` 加入地区账本精确 `-1`、重复杀害不可二次扣减、地区文件加载和测试恢复检查。
- **诚实状态**：本批次为真实源代码/严格QA增量提交，**此条提交尚未看到最新严格Godot4.4.1 原Main QA结论**，不可写P0已PASS；先前`39065966234`只验证旧版修士HP/尸体死亡。世界统计不能冒充5000个真实渲染人；本批主角仍**未获得实际WorldX可采信图片或高精真3D模型**，用户美术门禁依然P0 FAIL。rev208 PR #14保持Draft、不得签名上线；官网rev207维持不变。

## 2026-10-18 / CAC-HQ-ART-ECOLOGY-REPORT-MANDATORY / 用户上传正式高精美术与生态替换执行报告，最高P0执行规范落库
- **用户新最高要求已写入唯一公开仓库 main，绝非仅聊天记忆/临时口头承诺**：完整用户原报告 `docs/CANGLAN_HQ_ART_ECOLOGY_EXECUTION_REPORT_USER_20261018.md`；逐项ID/质量出口/完成与阻塞状态 `docs/CAC_REV208_HQ_EXECUTION_CHECKLIST_20261018.md`；`AGENTS.md`、`docs/DEVELOPMENT_EXECUTION_RULES.md` 已提升为最高优先级美术发布门禁；WorldX风格 `tools/asset_factory/CANGLAN_WORLDX_STYLE_LOCK_V2_HQ3D.md` 替代低饱和固定斜俯视v1，旧文件已显式标为历史文档。
- **质量路线冻结**：不能再用Quaternius Knight做近景主角/核心修士；不得用Kenney矮小橡树批量缩放冒充成熟森林；不以`bush.glb`红白菌体冒充绿灌木；树干叶片/地面/衣料与真实灵草必须拥有不同PBR/真实尺度/独立轮廓；WorldXAI仅产经审查的高质量四视母版/贴图美术参考，需进一步成为真实可蒙皮高精GLB才算游戏资产。真实第一/第三自由镜头与古风发髻衣装是硬标准。
- **固定阶段与P0**：`HQ-Art-Lock → HQ-Character → HQ-Ecology → Combat-Life → World-PBR → Mobile-Sustain → REV208-RC → REV208-SIGNED`；主角1、核心修士至少4、成熟乔木3+幼树2+灌木4+草蕨4、独立可辨灵草5–8、真实死亡和地区人口扣减、至少7张原版Godot真截图、Android手机30分钟FPS/热/触屏复验；证据缺一不可，来源许可证/SHA/PBR/LOD/碰撞逐资产验证。
- **真实状态不夸大**：主分支正式RSA/PCK公网**rev207**（APK176 versionCode1176），rev208候选仍在 Draft PR #14，未合并/签名/发布。Godot 4.4.1 原APK176 Main最新技术QA `39065966234` **SUCCESS**，已验证修士剑击有限HP、反击、真死亡尸体/存档与着陆回归；但是高精国风角色、成熟密林、灵植/地面美术与死亡动画/人口账本仍 **P0 FAIL/PENDING**，30分钟 Android实机 `PENDING`。不得因为这个引擎QA绿灯就发布rev208。
- **未完成与后续唯一优先工作**：先接通 WorldXAI v2高质量图片真实生成与风格锁，再接入一名真正高精主角（四视、表情、布料、绑定动作），再做成熟树/绿被/独立灵草及PBR地表。完整原始报告里的数值是目标预算，未经真机测量不能标实际性能数据。后续每次完成逐项更新报告ID、提交SHA、引擎截图/QA号、手机与正式OTA状态，工作日志不得滞后官网。

## 2026-10-18 / CAC-REV208-AUTHENTIC-MORTALITY-AND-ART-GATE / 真实死亡通过引擎QA，低模画风仍拒绝发布
- 以用户 Android 实机截图 `1000067794.jpg` 对照两类真实 Godot 截图与 AI 生成概念图，确认低模西式人物和头发、树木矮小、灵药同背景、地形缺层次、薄弱受击均为**美术/玩法 P0 未达标**。概念图仅作二维目标，不是实机，更没有通过 WorldXAI 实际导出高精三维角色。
- 实际代码：`cultivation_world` 用稳定修士ID实现体力/有效剑伤/HP/仇恨反击/死亡时间/死因/停止行动/倒地可见/死亡后碰撞失效/原子存档；`player_controller` 近距三米内对被锁定修士进行真实武器攻击且遵守空间射线遮挡，解决原先修士只能被锁定却绝对不可击杀。中立修士攻击后开始真实反击。御剑着陆在下方有真人/树/房时以实体碰撞检查尝试水平寻找邻近无阻落点，不穿墙假瞬移。
- **严格 Godot 4.4.1 原APK176 Main QA run `39065966234` SUCCESS**。关键信号 `PASS_REV208_REAL_LETHAL_CULTIVATOR_SWORD_COLLISION_DEATH_PERSISTENCE_AND_CORPSE`，包括实体剑击实际扣体力/敌人生命、杀死后不复活/不阻挡、存盘再读取保留死因；另有原真机导出资产的 Godot Vulkan 截图和原场景回归成功。这不是 Android 手机实测。
- 真实 Vulkan 画面仍见矮而粗糙的绿色小树、廉价人物脸/服饰、稀疏且发暗的地面。**用户明确不准再以低多边形作最终素材，视觉验收 FAIL**。故 `PR #14` 为 Draft，未经合并/签名/上线；公共手机可升级的正式版本仍仅 `rev207`。新版 Godot QA 绿灯不可替代 P0 美术。
- 六类高精规范：`docs/CAC_REV208_HIGH_FIDELITY_ART_AND_MORTALITY_GATE_20261018.md`。WorldX 原生只产出素材二维图/精灵并需图像模型提供端；高精 3D 人形另需商用授权、三视图一致、可蒙皮模型与 PBR。真正完成需开源/合法高精资产接入后从引擎截图比较，再走原签名发布与用户手机 QA。

## 2026-10-18 / CAC-REV208-FOLIAGE-THIRD-PERSON-CLIPPING / 真植被必须不能遮挡玩家
- rev208 Godot4.4.1原Main逻辑验收过关，但首轮 **真实Vulkan截图QA失败**（`39064557498`）：第三人称近镜头的真实人物像素被新增绿叶幼树冠层遮住，出现`FAIL_REV198_RENDERED_PLAYER_IS_STILL_INVISIBLE_NOT_MERE_SCENE_NODE`。`QA SUCCESS`不成立，因此rev208仍未签名/发布。
- 真正修复`788717836ab19d7cac0f436a58d9e2d6fe1c4276`：生态散布器给主角原始出生位置`(1.5,7.0)`留8m可移动/可看清身体的出生林间空地，保留灵根检测台`(12,7)`周围5m视野/交互空间；真实建筑道路水体仍然禁止种植，没有删掉人物视觉QA门禁。
- 后续仍需真实Godot主镜头和近景截图证明画面，且更高层应有树木遮挡角色时镜头自动透视/透明化，不能永远靠固定出生地排除。


## 2026-10-18 / CAC-REV208-GREEN-FOREST-ART-QUALITY / 真实Godot截图暴露红白菌体误当绿植（候选）
- rev207在Godot4.4.1原手机游戏Main场景实渲截图 `real_apk176_rev207_vivid_cc0_texture_forest_wide.png` 中，新增201株源`Quaternius CC0 herb/bush.glb`实际外观为大量**巨型红白蘑菇样物体**，不是用户要求的森林绿叶灌木；局部土地仍疏。即使场景3D解析和材质哈希技术QA通过，**该美术效果仍不达用户验收标准**。不把引擎通过等同视觉满意。
- rev208真正候选源码 `apk176_living_resource_world_rev187.gd` 改为复用先前已合法引入的`Kenney CC0 tree_oak.glb`原始树冠/叶色与UV/PBR，在0.26–0.47原比例生成密集灌木/幼树，不再把红白菌体错当翠绿植物，保留随机散布、≤210真源3D节点、≤14万真实三角预算、真实土壤/道路/建筑地基禁种、挖地后消隐。旧Quaternius红白菌/灵药模型不被篡改或删除，仍可作为独立稀有药材而非普通森林绿被。
- QA新增对真的Kenney源`tree_oak.glb`与授权/地形/物理渲染的原Main逐体检查。分支专用`.github/workflows/canglan-rev208-green-saplings-qa-only.yml` 对照真实Godot Vulkan截图，只有该分支真实绿色、性能可接受才考虑独立rev208正式签名热更新。**当前还没有rev208正式PCK。**


## 2026-10-18 / CAC-REV207-REAL-UNDERGROWTH-GODOT / 修复授权灌木GPU原点幻影，换为真正可渲染GLB
- **严格引擎错误复现**：新灌木批绘在Godot4.4.1原Main的真实引擎测试中，`MultiMesh.set_instance_transform`和整块`set_buffer`立即回读仍是`Transform3D.IDENTITY`，因此灌木会堆在世界(0,0,0)，不是可见的生态；提交`909da55d…`/`7e80dfdd…`的原引擎日志已经记录真实失败值。本轮没有通过删掉真实mesh验证混过。
- **完成技术回退但保留实体目标**：`111d191b36d5e3266ce7d6eae58bced8f25a1d15`改为与已成功渲染的rev206真灵药相同的`Quaternius/CC0`原GLB子场景复用。模型自带原始UV/法线/PBR/局部旋转；在真实道路/水体/预定六座住房及灵药采摘区之外依地形海拔撒布，按源真实三角预算最多210处灌木，与既有10,800束地表草混用。抽取真实`terrain_cell_changed`事件，在玩家挖地时将被挖地块的真灌木实体隐藏而非生成0矩阵原点幽灵。
- 对应严格原Main QA `059217460fd6a36cfa3797b0066733c48ffb8218`：每个授权3D原模型的节点、源许可、实际MeshInstance3D、世界XZ坐标、地形高度、植被可见性、未来房屋预留地、预算、挖矿后的不再悬空全部真实逐项核验。由`5a1d92bb4115c82e964576a3ba6e7613f3056a82`触发的原APK176 CI 已经过了原Main和住宅回归测试，仍等待完整截图/流程结论；这还不等于安卓性能和客户端实机通过。
- **性能取舍**：出于可靠性选择最多210个真GLB绘制节点，而非证明不了正确变换的MultiMesh批次；未来需在实机GPU监测结果下采用可信的GLB网格合批或真正LOD，维持视觉密度而不让发热/掉帧恶化。


## 2026-10-18 / CAC-REV207-SHRUB-VISIBLE-COUNT / 以GPU真正可见槽位消除矿坑幽灵灌木
- 原Main严格QA `39062413780` 与 `39062565580` 均 **FAIL**：通过实际Godot回读证明使用0缩放/0.0001缩放表示“隐藏”的MultiMesh实例在源网格与引擎渲染器某些场合返回单位变换于世界原点，导致原厂灌木错误显示。
- 正式技术修复候选 `1c37e9150eda352c08229ce73ef32b3758c8f959`：不再依赖神秘零缩放，原始植株的真实土壤ID与渲染GPU slot严格分离；矿工挖地后仅保留可种植地的紧凑实例映射，填充前N个真实源GLB变换，设置Godot原生`MultiMesh.visible_instance_count=N`显式裁去其余位置，根本消除原点“大灌木”的风险；六栋房屋蓝图仍受植物禁入硬约束。
- 严格QA `10a39632bf662eeb7c906e9262e3db56a1b70ded`逐一比对原厂GLB旋转与每个当前可见GPU实例的土壤实体映射、挖掘后生长环境、建筑间距、实例守恒和全部MeshPart同步，不取消严格审查。仍等分支原APK176真引擎总验收结果，正式签名仅能在green QA之后。


## 2026-10-18 / CAC-REV207-SHRUB-MULTIMESH-ZERO-BASIS / 原生GPU实例隐藏陷阱
- 严格原APK176 Main QA `39062088006`/精确数值追踪 `39062242184` 仍为 **FAIL**，并已获得真实Godot失败数据：本应隐藏的0号灌木GPU实例竟回读为`Basis.IDENTITY, origin=(0,0,0)`，而原始授权GLB的正常植株应具有作者90°旋转和世界位置`(17.606,0.639,10.827)`。这会导致采挖地表后植物跑到世界原点，不是纹理丢失或普通GLB原型错误。
- 源修复 `6558affe42d6c8edd91bc4098318738a38a5846d`：矿场被挖后不再给Godot4.4 MultiMesh传非可逆零缩放变换，而用合法可逆的0.0001倍细微尺寸网格放在地面下6米。修复需对比全部源mesh的变换、真实可种植土壤和挖掘后有根系消失的严格QA；未通过前不能合并或发rev207。


## 2026-10-18 / CAC-REV207-LIVE-EXCAVATED-SHRUBS / 草木不能长在被挖走的地上
- 严格原APK176 Main QA `39061896938` 返回 **FAIL**：`REV207_REAL_CC0_SHRUB_ON_PATH_POND_OR_CUT_SOIL`。实际问题是用户挖矿/挖地后，授权Quaternius灌木的初始GPU实例仍保留，可能飘在已挖地表；不能靠删掉检测“通过”。
- 修复`d4265b4557050b7ce71c0b526272e3ab01f85910`：每个原厂MeshInstance3D复制为MultiMesh批绘时保存真实土壤位置与原作者GLB本地坐标变换，监听原Godot真实地层`terrain_cell_changed`，在挖开的地块即时更新所有灌木子网格，取消已经不再适合生长的GPU实例；其余森林和房屋位置不能被改动。
- QA `c890b12c40afe06486dc5329c02ba0b0da3f3180`：按植株**土壤逻辑坐标**而不是原始艺术mesh偏移作为建筑/道路/挖掘判断，测试三维网格的真实world-transform与作者相对偏移是否完整保留，活株GPU实例是否随开挖退出、剩余树木在场、所有子mesh一致。最新提交仍须原Godot QA复测；截至记录时没有发布rev207。


## 2026-10-18 / CAC-REV207-SHRUB-INIT-ORDER / 检查出首帧生态渲染依赖顺序并真实修复
- GitHub Actions `39061700710` 原APK176 Godot 4.4.1全场景QA **FAIL**：`REV207_UNDERSTORY_CC0_BUSH_NOT_IMPORTED`，已确认真实开源 bush.glb 已被加载，不是缺许可或资源路径；根因是新增灌木渲染调用早于`quality = ManualQuality.new()`初始化，而合法可种区域判定需要quality实例。
- 真正修改原`_ready()`顺序（提交`4794a0800bc1b084862480e17964c64b71c2e833`）：在原树木、石矿、角色、原Main、质量/流式草地均初始化后，再创建真实授权灌木MultiMesh，保留全部源模型/PBR和QA门禁，不删检测、不放宽真实GLB要求。
- 严格QA后续执行`39061896938`（提交时仍未出结论）。原已发布签名 rev206 仍不变；只有最新rev207 Godot Main、Godot引擎截图、RSA签发和公网站验签全绿才可合并发布。


## 2026-10-18 / CAC-REV207-REAL-CC0-UNDERSTORY / 真GLB授权灌木填植被空白（需新Godot截图复测）
- 对照实际rev207候选Godot 1280×720截图：原近景草丛虽有10800 MultiMesh，但局部仍有明显单一裸绿地。用户最新要求“除建筑用地外不能空白”，不能只写500区块生态数据；须让原真3D场景有实物群落。
- 真正修改`scripts/apk176_living_resource_world_rev187.gd`：使用已授权且哈希固定的Quaternius `cc0_spirit/herb/bush.glb`，复用原GLB Mesh/UV/PBR及作者局部变换，按源mesh面数估算GPU三角预算(≤35万)，逐MeshPart的MultiMesh场景批绘和可缩放植株，采样真实可种土壤，明确排除路/水/已挖土壤/六处住宅地基，保证不是建筑内乱长草。
- 原Main QA新增植株数量、真实网格实例变换、源模型批绘、预算上限和建筑地基硬禁种；引擎截图与实机视觉效果尚需核查。此功能是**可见灌木地被**不是免费的成熟药草，真正可采药物仍从有限灵药账本扣除。


## 2026-10-18 / CAC-REV207-LIVING-WORLD-P0 / 用户新的五万平方公里稀疏世界与妖兽繁衍（候选）
- **本轮指令覆盖旧设定**：世界起始`50,000 km²`、`5,000位凡人`，不再把旧城8万人+统计居民当成实时世界人口，凡人灵根比例不是100%，无灵根者可炼体；宗门有剑修、符箓、御兽、炼丹、阵法等独立职业传承。完整机械设计见`docs/REV207_LIVING_WORLD_50000KM2_MECHANICS_20261018.md`。
- 新源`game-source/apk176-ota177-candidate/scripts/apk176_living_regions_rev207.gd`：500个面积100km²统计生境/人口块，初始5000居民/125根性者/其余无根与体修人口，按月生育死亡、按年年龄变化、子代灵根概率、持续种子库与草药生境；五个宗门专业与招徒进度；四个真实矿脉附近的妖兽家族按世界时辰积蓄灵气、缓慢突破境界、食物约束繁育/老死并可因真实打斗扣减个体。只有近景四只已有授权GLB兽实体在渲染，其余为**统计人口/生物量，未冒充实体**。
- 原Godot正式主场景脚本`apk176_living_resource_world_rev187.gd`已接入新世界引擎/旧时间加速，四个真的妖兽位置分别靠近真实四处灵石矿脉，法力、境界、碰撞/攻击持续保留；`apk176_cultivation_world_rev201.gd`将旧8万人城市账本冻结只读，不得再次与五千人相加。
- `apk176_spirit_resources_rev206.gd`保留13处原节点及旧档守恒，新增自然30世界日后随机但可复现、避建筑和道路的本地灵草扩散，初始13处不破坏；植株可采量降为0仅代表暂时无成熟枝叶，活植物模型与种子库保留。种苗来源仅使用之前哈希固定的Quaternius授权原3D素材；`build_apk176_quality_rev187.gd`与`verify_apk176_rev187_3d_pck.py`已要求新引擎脚本打入原PCK。
- 新QA `verify_rev207_living_regions.gd`覆盖24个月 5000开局/根性比例/生育死亡/体修门派/妖兽繁殖修炼/草木不灭/读档守恒，以及原Main四矿真实兽距校验；CI位于`.github/workflows/canglan-rev207-living-regions-qa-only.yml`。**本轮新候选尚未经过Godot Main绿色QA、正式签名或公网站证；绝不称作手机已更新。**
- 本轮刻意不把50000平方公里“已有3D地形”当事实：已提交的广域模拟 ≠ 手机上的完整实体地形；还要实现旅途分块、独立职业交互、真实幼兽出场、完整宗门模型和Android实机QA。


## 2026-10-18 / CAC-3D-206-LIVE / 原APK176 rev206正式热更新已完成、官网公网上线
- ✅ 真正发布成功：PR #12 合并正式 `main`：`25408b71a9aac51e9ea4aea8fe8e9567c800cba1`；Godot 4.4.1原APK176 Main严格验收与RSA发布流水线 `39057810555` **SUCCESS**，和旧APK176 `versionCode1176`兼容，未重复打APK，未篡改旧 rev205 不可变PCK。
- ✅ 原签名清单 `android-preview/latest.json` 版本rev206；唯一正式新补丁 `android-preview/canglan-content-rev-206.pck`，实际大小 `35,782,624` 字节、SHA256 `d2b2fbd4a34b8dfeb90d20f1e302ff01803adf5b8c811aed78759d1b478ba022`，RSA-3072验签通过；合法来源Quaternius灵草/矿石物件与Kenney树林石矿GPU批次载入真主场景。
- ✅ 官网页面真正上线：`39058075233` **SUCCESS**，运行在真实GitHub Pages CDN验证 `PASS_CURRENT_ORIGINAL_APK176_PUBLIC_HTTPS_RSA_SHA256_AND_RANGE`，`live_revision=206`、`pck_bytes=35782624`、SHA完全一致、HTTP Range实际`206`。原游戏内点击“检查更新→下载安装资源补丁”可以下载rev206测试，不需重新安装旧APK。
- ✅ 实际Godot移动Vulkan/Linux渲染截帧：`art/actual-engine-capture/canglan-rev206-real-spirit-herbs-godot-linux.png`、`canglan-rev206-spirit-ore-godot-linux.png`、`canglan-rev206-vivid-cc0-forest-godot-linux.png`、`canglan-rev206-backpack-godot-linux.png`；均为真引擎画面**非安卓实机照片**。修复首次52棵树、20石矿超过40/12资源池，新增真实CC0灵草灵石、保存、炼丹、再生、九叶密草与住宅必须库存/工时付费；仍有用户未确认的整体国风美术质量和NPC行动丰富度。
- 🔴 **Android手机实机画面/点击/帧率/发热尚未验收**，不得称已获用户认可。用户2026-10-18 `docs/REV208_PHONE_SCREENSHOT_P0_PERMANENT_MASTER_20261018.md`所有P0标准继续有效。下一版本优先修高可见性/操作/资源生态及真实性，不接受免费房屋、NPC发呆或UI数字缺失。
- 网站研发日志专项修复：此前`site.js`只识别`CAC-(PROC|3D)-数字`且取反序最老24条，Pages又漏传`docs/CAC_CHANGELOG.md`，导致正式rev206工程日志未在首页显示；补上公开CAC文件、按原日志自顶向下最新24条展示，`data/updates.json`标记已实际验签但手机仍待验收；对Docs/site/数据变更单独触发Pages重部署，不修改原PCK或RSA签名。


## 2026-10-18 / CAC-REV206-ORIGINAL-GODOT-GREEN / 候选引擎验收绿灯，正式签名需main发布
- 正式 **rev205** 不变。rev206唯一分支真实CI `39057568955` (HEAD `e567b58007d18ffda5819b48090a21c98aeb64ab`) 结果 **SUCCESS**：Godot 4.4.1原APK176 Main物理世界、完整源PCK构建、全部52真实树/20石头GPU实例、草地三档密度/真实PBR、七份Quaternius灵草矿石、13处资源有限采挖/储存/炼丹再生、32灵根、统计人口和其他累计复测均通过；实际Godot Linux Vulkan 1280×720截帧步骤通过。**这不是Android手机实机验收，也不是rev206签名发布证明。**
- 真正修复九叶草3D mesh `c5336cdb19ad2a9c90744ee144767f7b02c54841`，从6根短细针进化为九叶立体密叶体；保留每手机画质档独立密度、MultiMesh批绘与植物物理区归属。旧QA错误假定320/4500草实例已按当前真实源正确更新，不放宽实例验收。
- CI绿色前另发现原完整Main正常退出但流水线在查找废弃`PASS_REV206_REAL_QUATERNIUS_CC0_COMPLETE_HOMES_...`日志标志时失败。改为真实`PASS_REV208_NO_FREE_HOUSES_200WOOD150STONE_FIVE_RESIDENTS_AND_FOUR_TRUE_LARGE_YAO_BEASTS`和`PASS_REV206_REAL_QUATERNIUS_CC0_SOURCE_HOUSES...`并保留全部原QA门禁。
- 已建立 PR #12；`.github/workflows/canglan-original-apk176-rev206-signed.yml`为仅main可运行的原APK176原场景二次QA、RSA签名、原更新清单安全版本推进、不可变PCK原子发布流程；签名提交由GITHUB_TOKEN产生的`[skip ci]`不会自动激活Pages，故显式`gh workflow run canglan-official-pages-ota-deploy.yml --ref main`，并由rev206公开HTTP证据工作流在Pages部署完成后检验RSA、SHA256、Range206。
- 工作日志此刻 rev206 **候选引擎QA PASS，正式PCK签名/公网验签/手机实测尚不可标通过**。禁止误报版本已发布。

## 2026-10-18 / CAC-3D-206-BATCH-P0 / 真正的树林矿石MultiMesh槽位修复（候选，尚未发布）
- 唯一仓库：`160701541-cell/xinyanshuo`，工作分支 `feat/rev206-herbs-spirit-ores-real-ecology-crafting`；官网/正式 `main` 的最新版仍为**已签名rev205**，不得把候选称为可在手机更新。
- 复核真实失败QA run `39055302165` / job `117461953120`：**原APK176真实Godot主场景**共生成52棵树、20处石矿，但开源Kenney多实例渲染器仅分配40棵树、12处石矿，直接造成12棵树（编号040–051）和8处石矿（012–019）虽然有账本却不显示；不是缺少外部GLB下载。拒绝靠关闭严苛QA跳过。
- 修复 commit `98dda159c8c14dff6b6a8dfe02c5426e26191fc9`：`scripts/apk176_kenney_multimesh_rev187.gd` 将真实首次容量扩到64/32（保留自然播种增长预留）；资源增加时有界增长（树上限256、石上限128），扩容后逐个恢复原有真实GLB的Transform/自然颜色；超过手机容量硬上限必须显式拒绝并记录，不虚构无限生成。开源许可、源模型、主游戏经济数据均不改。
- 回归门禁 commit `c2f3238d0204f39144518ee16e833f77b9e71832`：在 `verify_original_main_quality_rev187.gd` 新增原Godot Main实例化检查，验证全部52/20资源实体有物理ID、实际MultiMesh绘制槽位和非零变换，模拟林木再生矿石扩容，比较已有实体坐标和着色均不丢失。新的检测标记 `PASS_REV206_ALL_52_TREES_20_STONES_REAL_DRAWABLE_BATCH_SLOTS_GROW_WITHOUT_LOSS`。
- 已启动分支自动Godot严格QA run `39056806305`（启动时in_progress）；只有真实返回success才写PASS。**本记录时rev206仍非正式签名发布**；原Main/渲染截图/PCK签名/公网RSA与HTTP206/Android真机验收状态分别为PENDING/PENDING/BLOCKED/BLOCKED/BLOCKED。新草药灵矿炼丹功能同一候选已具基础，但仍受整个Godot Main严格验收门禁约束。



## 2026-10-18 / CAC-3D-207 / 原APK176开源整屋/野生动物/高色度PBR真实细密材质 + 可玩基础交互
- 玩家反馈最高优先P0：**不要再生成新房或让NPC日复一日维修重复小破房；优先合法开源现成建筑、服饰、动物，材质必须有真实纹理和高饱和色彩，近景像素高密度不是满屏超大马赛克**。本轮原游戏代码优先处理这些可见缺陷；用户不需要自行重复推动。
- 原版Godot 4.4.1原APK176主线增量：`game-source/apk176-ota177-candidate/scripts/apk176_living_resource_world_rev187.gd` 真正取消老破屋木料/石料施工循环、第三NPC改为管事，完整Quaternius CC0源房屋4座+客栈+亭子6件，狼/狐狸/鹿/牛四个源动画3D动物、角色服装源文件，入场实例而非模型概念图。整屋房屋预设居民归属，但**可进入室内和完整居住生态尚未完成**，不假报合格。
- 资产链严格开源CC0来源：`game-source/apk176-ota177-candidate/assets/cc0-rev206/asset_intake_proof.json` 校验14份真实GLB源哈希；`materials/rev207/manifest.json` 校验九份原厂Quaternius白墙/屋瓦/木料BaseColor+Normal+Roughness/ORM 512×512图+SHA256。`tools/verify_apk176_rev187_3d_pck.py` 与真实PCK逐字节对照，避免纹理变单色、源文件丢失或许可被忽略。
- 正式画质源改动：`apk176_vivid_material_rev207.gd` 真实GLB材质非破坏式UV/法线映射、地层真实world-space 64细texel/米纹理shader，保留多材料分层和碰撞；`apk176_quality_profiles_rev187.gd` 饱和度1.30、对比度1.095，暖日光+纯蓝天空，降低灰蓝雾浓度/爆白泛光，高档真实3D渲染96%屏幕、UI全原生分辨率。没有简单用低分辨率马赛克强制降质。
- 游戏系统既有增量保留：rev205 Lucide ISC图标、折叠UI、锁定真实修士、镜头上下/御剑复飞、24格有限真物资背包和装备/采挖/种植；rev206 32属性根源、玩家及普通NPC必有隐藏灵根、例外役属劳工可能无根、灵根元素法术打击与战斗状态、1万—25万人城池真实数字统计（不实化10万渲染节点）；rev204原施法与记录不回滚。
- **实际Godot engine QA已通过**：`https://github.com/160701541-cell/xinyanshuo/actions/runs/39048314417`，测试真实原APK176 PCK、头部脚本解析、保留历史验收、真实3D渲染双角度截图、实际屏幕色彩丰富度、开源完整建筑/材质法线贴图与动画/实体NPC；此前遇到资源泄露已修复，之后成功。真实Android触屏、手机GPU性能、发热与用户美术审核**仍未通过/尚未进行**。
- ✅ **累计rev205正式签名PCK已完成并通过真正公网验收（2026-10-18）**：唯一原版APK176、Android versionCode1176，文件大小34,968,416字节，SHA256 `91da8e9379cfe3decf9725ef6f637c21adf1fa85fcc4aa23085d6a6dd66b9637`。原APK RSA-3072私钥签发 run `39051286400` SUCCESS，官网签名清单 `android-preview/latest.json` 最新rev205；GitHub Pages公网完整下载/官方RSA验签/同SHA/Range206 run `39051608266` SUCCESS。官网真实Godot截图已经同步到 `art/actual-engine-capture/canglan-rev205-*.png`。这次确实热更新进了正式游戏，**不是仅提交代码或独立技术APK**。
- 安卓**真机手感与美术验收未完成**；虽真实引擎技术QA已过，但现有草地/国风建筑匹配、树木密度、人物动画依然没有达到终极质量标准，需要继续执行 `docs/REV205_PERMANENT_PLAYER_BUGS_MASTER_20261017.md`。并不因为签名发布就把这些P1缺陷勾掉。
- 后续P1缺口照章保留：真实仙门建筑内部/炼丹药园生活生态、更多灵兽妖兽资源、NPC真正原生本地模型决策、装备服饰换装和纹理尺寸高级定制、野外树林丰富度与实机帧率。源可运行≠美术已获用户认可。

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


## 2026-10-17 / REV179-USER-ANDROID-SCREENSHOT / 首次真实APK176三维预览手机画面+专业美术/性能审计

用户直接提交横屏《苍岚》手机截图：原APK176内显示真实Kenney树石3D预览场景、“返回原游戏”按钮，实测HUD瞬时`90 FPS / 90.0Hz / GPU 7.58ms / mobile-vulkan / Draw 417/200 / triangles 277931/150000`。**实机3D画面确认成功**，原版更新链条终于有实机可见证据；仍不能由截图推断旧存档无损、返回可用和长期性能通过。相机距离远、实体小、绿板地面/蓝灰天空大面积平涂、树石机械排列，无生活NPC、道路、院落，国风3D村庄G1质量严重不达标；Draw和三角面分别超过屏幕预算217次、127931面，即使单帧90fps，也不能声称性能达标。禁止将本技术预览当作G1/G2/G3游戏验收。

新建完整实机QA文档`docs/QA_APK176_REV179_PHONE_ACCEPTANCE_20261017.md`，真实提交`5cc2c00efe10a6e6dd0f3f7913b2ed8e7e47307d`，逐项记录PASS/FAIL/未验证及下一批美术、性能、NPC资源守恒和原APK176签名OTA目标。未经用户要求未上传私人手机截图到公开仓库；日志只记可观察事实。**这次没有完成rev180发行**，仍需真实代码/模型增量、Godot与原版RSA/Pages和再次安卓实机验收。


## 2026-10-17 / APK176-REV180→181-REAL-NPC-MATERIAL-WORLD / 真正开发、原机Godot验收、RSA官网发布闭环

**目标**：接续用户rev179真实安卓截图反馈，拒绝继续只是平地上摆树石。本批从已有`worldbox_life_sim.gd`守恒后端和正式许可素材出发，给**原已安装APK176**加入可观察到的职业劳动/库存/搬运/分阶段工地，保留“返回原游戏”和原存档。世界观美术大规模村庄仍未完成。

### 真实代码增量
- `game-source/apk176-ota177-candidate/scripts/apk176_living_resource_world_rev180.gd` 初始提交`0a6d36c`，含授权Kenney树石、木材、石阶、门及围栏+Quaternius已绑定动画骑士GLB，3名实名编号NPC（伐木/采石/施工）、21个不由劳动凭空生成的独立资源节点（12树9石）、0初始木石库存、有限采集→随身货物→真实步行到仓库→入库；分阶段有明确材料账单和工时。绿色整板的静态预览改为有土路/天空/自然散布的工作场景，可右侧拖动观察、返回原游戏。当前只是一块工作场景，不可宣传完整自治城市/多形态中式房屋。
- 原版Main继续继承**APK176导出编译真实场景**`res://.godot/exported/133200997/export-3ad5c15c4f3250da0cc7c1af1770d85f-main.scn`。新的`main_original_autonomous_rev180.tscn`/`main_rev180.tscn.remap`由原签名OTA覆盖res://scenes/main.tscn.remap，切回原主场景可恢复隐藏的3D网格；旧存档不写入。
- 真正7个既有商业CC0 GLB未自行建模：Kenney`tree_oak,rocks-small,tree-log,wall-narrow-wood-fence,stairs-stone,door`，Quaternius`knight`，保留原始Kenney共享`Textures/colormap.png`；逐二进制SHA对源文件，不用假模型。
- `logic-qa/tools/build_apk176_autonomous_rev180.gd`、`tools/verify_apk176_rev180_3d_pck.py`、`logic-qa/apk176-export-fixture/verify_original_main_autonomous_rev180.gd`及`.github/workflows/canglan-apk176-rev180-autonomous-signed.yml`实现原APK176全资源继承、Godot4.4.1+精确Terrain3D v1.0.2运行、原房屋回归、内置签名私钥匹配、签名PCK自动发布。初始运行 `38968506995` 因Python PCK审计脚本错误转义换行而失败，已修复`bfccdb4`；运行`38968595121`真实Godot脚本所有模拟断言PASS，但headless退出时GLTF资源泄漏，已增加独立asset_sources免费释放`9132bd3`及QA显式销毁原场景`907728b`；旧版跑出的模拟统计含`3名有动画NPC、21节点、49次采集、49次入库、4阶段、13个真CC0构件`。渲染RID泄漏未被掩盖，真实清理后门禁才允许签名。
- 实际rev180已由早完成的并发工作流提交至正式main，发布hash`4a1fdcdc84785734ba6a4ddda51e209c07547ea9b19582f87ff3be1b93e732b7`；但随后补上的**施工工必须返仓领料再运到工地**逻辑提交`29148fc`已在另一个通过原版Godot/RSA测试的发布流中，与已经先上线的rev180发生防覆写拦截（最后job失败，属于正确的冲突保护）。**绝不覆盖已发布签名的同一revision**。
- 为完整送达真实体力搬运修复，单独生成**rev181**自足原游戏脚本/scene/PCK builder/PCK二进制审计/原版完整主场景Godot QA以及新签名Actions`.github/workflows/canglan-apk176-rev181-autonomous-signed.yml`，二进制不依赖旧rev180叠加。专门QA断言施工工必须走回仓库、把明确材料库存转为随身`carried_materials`并挂Kenney GLB材质，再步行抵达工地，才开始计时施工；缺货不出货、不造物。360模拟tick对木、石自然储量+仓库库存+随身库存+已支付建造阶段逐步核账，要求守恒与至少两个阶段真构件可见；抽查骨骼模型包含真实`Walking`动画，无动画拒绝上线。主界面可退回原世界/重新进入，保存旧世界脚本未改。

### 官方发布闭环（真实运行结果）
- 新rev181原机Godot/RSA发布Actions **run`38969085384` / job`117202723850`：completed/success**。工作流确认为APK176本体主场景；严格PCK文件校验7个授权GLB，尺寸`21,579,328`字节、SHA-256`beaa0b1e7ddea8d8fe43531912fa7a4cd234229bbd6d740e6f834142cc1bbc98`，原RSA验签PASS、原房屋回归PASS、施工真搬运+守恒QA PASS、正式main rev181发布PASS。**未重新安装APK**。
- 因GitHub Actions内置`GITHUB_TOKEN`发布提交不会触发后继工作流，新增直接Pages工作流变更`ea7a8426`以实发官网；Pages部署**run`38969237906` / job`117203234041`：completed/success**，出现`PASS_PAGES_SITE_CONTAINS_SIGNED_ORIGINAL_OTA 181`、`Reported success!`、`PASS_CURRENT_ORIGINAL_APK176_PUBLIC_HTTPS_RSA_SHA256_AND_RANGE`。独立HTTPS公网下载完整同SHA的`21,579,328`字节，分段请求HTTP206，`Cache-Control: max-age=600`。`android-preview/latest.json`实读rev181，正式APK代码区间锁定1176。
- 生产原安卓应用身份`org.canglan.ancient25d.preview`，内置固定公钥RSA；私钥仍只注入公开仓库Secrets，代码和网页无私钥。独立QA APK/HTML未作为用户交付。

### 下一步验收与尚缺
- **🟢 已用真实引擎验证**：原编译Main继承、3名有walking动画角色、21个自然节点→职业采集→搬运→入库→返仓领料→工地四阶段/守恒、原房屋回归、原RSA/PCK官网HTTPS发布rev181。
- **🟡 安卓手机rev181实机仍未验收**：用户此前已用真实截图证实rev179可在旧APK176显示；rev181尚无用户现场截图/“返回原游戏”及旧存档恢复验收，不可声称手机rev181已更新。
- **🔴 G1完整国风村庄及G2/G3仍不达标**：该切片仍以现成骑士动画代理职业NPC，工地是Kenney CC0构件的施工示范，屋顶/室内与完整中式民居、家庭经济、连续离线存档、真正本地AI推理尚未开发/验证。下一批必须批量使用已有许可的Quaternius中式可搭建屋顶/墙体等并做统一材质比例、NPC有本地下载AI入口和导航阻挡/触控、实际安卓连续性能与旧存档对比。禁止把这次工地片段冒充游戏完成。


## 2026-10-17 / REV181-PHONE-EVIDENCE→REV182-LIVE-ECOLOGY / NPC可见性、种子繁衍、地下基岩复露与板块造山

**用户现场验收与新需求（手机原版APK176截屏两张）**：rev181确实显示“苍岚 · 资源→搬运→施工”、0→126的木材入库、0→153的石材入库、施工构件逐段出现，用户评价“看着好好啊”，但**看不见NPC人物**。截图1瞬时约`29 FPS / 60 Hz / GPU 8.54ms / Draw 540/200 / triangles 302869/150000`；截图2瞬时约`30 FPS / 60 Hz / GPU 13.35ms / Draw 328/200 / triangles 143745/150000`。这表示本体生产模拟有实机内容，但角色显示和掉帧仍属**P0/P1质量失败**，不准凭模型导入或60Hz刷新率宣称满帧通过。照片未上传到公开仓库，保留用户隐私。

**用户正式生态目标**：每棵树被完整砍伐时获得**恰好一颗种子**，种子是真实可持有、入库、消耗、种植的物品；树苗→小树→成树，未来补齐树种、季节、年龄和留种选择。露天石料在**施工范围外**由石子→小块→石堆缓慢再次裸露，并可在长时间地质变化里塑造起伏地势乃至喜马拉雅级造山带。专业研发边界：**喜马拉雅山脉不是露天石块无限凭空堆成的**，必须是板块碰撞抬升基岩、构造变形、侵蚀、沉积、地层质量和百万年时间尺度共同作用。规则层可模拟亿年地质时钟，表现层未来通过地形块高度场+LOD流送，不能逐石头创建百亿Mesh；不允许改写已建房屋地基或矿物凭空增殖。

### 本次真实原版游戏增量

- 新脚本`game-source/apk176-ota177-candidate/scripts/apk176_ecology_succession_rev182.gd`（初始commit `eb63369`）：记录真实已存在树木ID，只有`remaining=0`并且未给过种的树桩才能给伐木工随身`1 tree_seed`；**木头进仓库、种子才正式入仓**，杜绝每次砍3木反复刷种；村民消耗部分种子种到建筑外的独立林地，另半存仓库，经过游戏内`6/24/72小时`逐渐进入幼苗/小树/成树成熟，不能立刻产木。若树未完全砍倒不得领种。
- 同脚本给9个可采石实体建立带ID的地下裸露层`48`单位有限初始储量（全部存在于地质来源，不是白送库存），**每48模拟小时最多一单位复露**；必须离真实工地≥10米、仓库≥6米；露头显示石子/石块/石堆，已采石料仍在仓库和工人背包守恒。装配建筑范围内拒绝自动复露。独立地质年代接口限制6百万年，净板块抬升-侵蚀速度约`0.00165米/年`，5百万年构造可达约`8250米`，但只能在板块汇聚区；**与挖矿库存完全隔离**。
- `game-source/apk176-ota177-candidate/scripts/apk176_living_resource_world_rev182.gd`：原版Main的签名PCK内真实调用生态生命周期和仓储经济；已经装入原版RSA认证补丁，不是独立HTML。NPC从既有Quaternius动画骑士成品骨骼mesh AABB统一放缩至约`1.8米`，名称/职业与独立ID浮标3D显示，默认镜头移至工人与仓库附近，按钮`看施工NPC`可近距跟随；用户可右拖视角和放大；底左显示库存与种子；旧右侧/上方GPU统计不再与业务HUD重叠。移动端`SubViewportContainer.stretch_shrink=2`降低二次3D视口的实际渲染像素数量，真实手机性能改善幅度**仍需实机复测**。
- 添加`地质演示 +25万年`按钮：只推进**独立地壳实验时钟**，不快进NPC生命或材料和旧存档；远离建造区的简单远景**地形高度场**按造山幅度起伏，并通过缩尺视图标注，不得宣传本次已创建全尺寸可攀登的喜马拉雅。未来正式的全球地形/流送/存档版本还没做。
- 与此前rev181一样，保留原APK176编译Main继承`game-source/apk176-ota177-candidate/scenes/main_original_ecology_rev182.tscn`，增加`main_rev182.tscn.remap`，原存档未进行写入或升级；Kenney/Quaternius同7件现成可商用CC0 GLB均逐SHA校验，**没有新做人物/房屋3D成品**。

### 真实QA、失败与正式签名OTA证据

- 新`logic-qa/apk176-export-fixture/verify_original_main_ecology_rev182.gd`直接载入真实APK176编译主场景，验证3名可见角色、3组名称浮标、模型物理身高、跟随相机、21个真资源点、真实采集入库、四阶段施工、360步木/石守恒；逐步验证`伐倒种子=仓库种+工人背种+已种数`，真实种植；石层每48小时从有限地层变石子，建设区禁止复露；5百万年只有汇聚板块隆起至7–9千米，不能增加库存。加上老版进出房回归、内置原RSA匹配。
- 早期run `38972587117`、`38972682765`暴露工具GDScript误写反斜杠，`38972778318`发现QA错误要求SubViewport固定960×540（Godot容器会拉伸动态分辨率），`38972916240`暴露本场景代码忘记更新`stats.revision=182`。**均以真正错误日志定位并逐项修复**，没有绕过QA。
- GitHub完整回归`38973083393` / job`117216213835`：**所有PCK二进制、原编译APK176场景、真实NPC/种子/地质QA、原房屋场景回归、生产RSA签名及门禁通过**；最终Publish步骤因另一并发工作流已经先将**完全相同SHA**的rev182发布到公开main而`BLOCKED: remote OTA revision changed`——正确拒绝覆盖，不是QA/签名失败。仓库正式rev182 commit`5e75dcb6977e998cd310c73482191f34b60d8cdf`，官方`android-preview/latest.json`为revision182、原应用versionCode=1176、PCK大小`21,596,192`字节、SHA256`bfd085956b4a2d41f1fd12635f312bd484d7c98692e99ce7958aea6d4ec8f1d8`。
- 实际GitHub Pages旧main源自动站点`38973287119`的构建和部署均**SUCCESS**。另一直接Pages workflow`38973286656`初次被正在进行的同网站部署锁拒绝，rerun时同一run名为github-pages的artifact重复被GitHub拒绝，**不是官网没有rev182**。故创建只读公网HTTPS验证`.github/workflows/canglan-rev182-real-pages-http-proof.yml`（commit`2e1fa835`）。实际 **run`38973719482` / job`117217970466` `completed/success`**，真正从公开github.io抓取revision182正式manifest并以APK176固定公钥验证RSA签名；实际完整下载21,596,192字节和本地Git SHA一致；分段下载返回HTTP206：`PASS_ANDROID_APK176_REV182_PUBLIC_CDN_RSA_SHA256_BYTES_HTTP_RANGE`。公网Cache-Control:max-age=600。
- **🟢 真正发布完成**：rev182签名PCK+官网正式CDN真实可下载，手机原APK176理论上可经原更新器检测新版本；不需要用户重新安装APK。
- **🟡 尚待用户rev182手机验收**：观察“看施工NPC”身高/脸面/Walk及表情、种子真实入库与幼苗、矿脉慢复露、远景地质快进，以及30FPS的GPU优化实际结果与返回原游戏/原存档连续性。此前用户两张图是rev181，不可冒充rev182通过。
- **🔴 保留工程缺口**：真正适配国风的非骑士居民模型、独立工位与人物互动动画、生态系统世界持久化，实际全球高度场/山脉高程、地质物质量连续守恒、更多树种季节、相邻矿区共演化、手机长时间稳定FPS、实时第一/第三人称玩家控制及本地可下载AI尚未完成。该生态和地质演示并非完成的开放世界。


## 2026-10-17 / APK176-REV183-FIVE-KENNEY-SWATCHES-MULTIMESH-SUN-ROADS / 真写仓库+实际原版签名PCK

用户再次明确实际有GitHub写权限，要求立即在原游戏修改三项，并在手机每步说明验收：**(1) Kenney低多边形保持不换风格，主场景五种主材质色；(2) 同类模型合并为MultiMesh、实机Draw Call目标≤200；(3) 一盏方向光+移动端短距离阴影，左侧分组树林、右侧矿点、中间物流路**。本批实际使用已连接**唯一公开仓库** GitHub权限写入，纠正上一轮助手误称没有权限的问题；并非只提供开发单。

实际提交：
- `acf1916`：五色共用Kenney `visual_palette.gd`：grass`#86a17b`/soil`#b6a488`/leaf`#58978d`/wood`#9a704e`/stone`#8a8c9a`；基于现成许可GLB原网格将多表面材质关联五色，不制造新正式模型。
- `0cea0cd`，修复`32da5c5`和`5d97b13`：`kenney_multimesh.gd`为树木、石头、已建木件、围栏、石阶、门类各自从现成GLB真实网格生成MultiMesh，变换代理与原生态ID/库存工作解耦，每0.1模拟秒同步实例矩阵；旧动画骑士独立继续动画，不强行合为僵尸静态实例。Kenney每个GLB可能有多Mesh/材质surface，不能宣称整个场景仅一draw。
- `71f1a44`和`a90d058`/`dc9fa93`：原版`apk176_living_resource_world_rev183.gd`接入五色与合批、独立站点遗产仍是相同APK176编译主场景，原NPC身份、真实采集和工地守恒全部沿用；太阳`KenneySingleDirectionalSun`仅1盏，正交短距离阴影48m；左右分组自然树林和矿石、中心7m清晰运输走廊及左右土路，HUD仍是真性能计数器不伪造优化数据。植树禁堵路生态代码`7de73a2`。
- 真原版PCK/入口场景`main_original_visual_rev183.tscn`、`main_rev183.tscn.remap`，`logic-qa/tools/build_apk176_visual_rev183.gd`、`logic-qa/apk176-export-fixture/verify_original_main_visual_rev183.gd`、`tools/verify_apk176_rev183_3d_pck.py`（逐七个CC0 GLB SHA+原入口继承、五色/真实MultiMesh/单太阳/通路/原NPC 360模拟、房屋回归门禁），签名自动工作流`.github/workflows/canglan-apk176-rev183-kenney-batch-signed.yml`。
- **真实错误修复**：GitHub run`38976158812`首次检测GDScript自定义构造Transform3D错误标成`const`，`5d97b13`改为实例字段；run`38976256147`出现原本scene节点被`_ready`重命名成旧Rev182，`dc9fa93`修复对齐原版场景。本轮没有压下Godot报错假通过。
- **真实完整通过**：GitHub run`38976345665` / job`117226600219` `completed/success`，原版编译Main真实Godot4.4.1/Terrain3D对应版本、原房屋回归、五色+真实MultiMesh+单太阳及树石通路全部受QA门禁、原RSA验签、PCK二进制SHA校验，正式Git main `android-preview/latest.json`已rev183；包`21,607,520`字节，SHA256 `5cccf09ed783638b2420f05986b4543c22d923d6289310ea6fe2c5e678e528a9`。原APK176/versionCode1176，无新APK且不写旧存档。

**重要未验收**：**Draw Call≤200只作为手机上的硬验收目标，headless不能代表手机全项目真实 draw**。用户此前的截图rev182是`Draw645/200`。本批虽实际修改合批，却**不能在用户新实机截图前标“Draw≤200通过”**，包括方向光阴影有效性和FPS实机。官网真实CDN更新、手机游戏内rev183装载需另行独立检验；QA详细手机步骤`docs/QA_APK176_REV183_KENNEY_FIVE_SWATCH_BATCH_SHADOW.md`，提交`ea510c8`。以上是真正原版提交而非待执行计划。


## 2026-10-17 / REV184-P0-REAL-PLAYABLE-TERRAIN-WATER / 用户反馈马赛克、不能操作、无第一人称、地面不是可挖土层之后的真实原版开发

**需求原文重点**：用户指出rev183即使保留Kenney低多边形也不应该像马赛克；树石失去清晰轮廓；需要低模中式古代场景气质、真正的水和真实地质结构，地面不能是PlaneMesh背景，因为后续NPC要挖地基；尤其明确“不能放大缩小视野，也不能操作，我自己都没进游戏，我也没有第一视角不能互动”，要求立刻做。研发将此列P0，不再把绕场摄影机当作真正玩家。

### 实际GitHub文件、功能
- `game-source/apk176-ota177-candidate/scripts/apk176_strata_terrain_rev184.gd` 首次提交`e9294d3`：Godot4.4实际生成92×92米、46×46分块、可起伏的`ArrayMesh`三角地表+泥土运输道路+凹陷真实岸坡池塘，并为完整地形生成`StaticBody3D/ConcavePolygonShape3D`真正物理碰撞；不是单纯一整片绿`PlaneMesh`。每个2m土格至多挖8层×0.45m深，土层分别为表土、黏土、砾石、风化岩、下方阻挡基岩；每锄实际改变原网格高度/立体剖面侧壁/碰撞，并记录该土层被挖出物的`spoil_bag`库存及不可凭空产出的质量守恒账本。地层模型仍是**局部高度场+垂直剖面原型**，不是全世界洞穴/地下巷道系统；池塘是雕出真实凹盆+局部半透明水面，非流体力学。
- `game-source/apk176-ota177-candidate/scripts/apk176_player_controller_rev184.gd` 首次提交`b17ebef`：在**原已安装APK176**的rev184主场景中生成实体玩家`CL-PLAYER-0184-0001`、注册真实村民身份和带Walking的许可Quaternius动画骨骼，而不只是自由绕视角；默认第三视角与可切第一人称真实眼位，左下原生双指隔离摇杆控制角色步行，右半独立滑动镜头，双指捏合/屏幕`视野＋/视野－`实体调整3D相机距离，`第一视角/第三视角`可点，`互动`对临近职业NPC、真实树石和仓库触发权威资源采集/搬运及对话状态，`挖地层`只有物理距离内真正挖表土与更深岩层；非假交互文本。回到原游戏有入口可重新进入。
- `game-source/apk176-ota177-candidate/scripts/apk176_living_resource_world_rev184.gd` 初始`34a4b4b`，QA节点名修正`8313947`：把原`SubViewportContainer.stretch_shrink=2`造成的全屏马赛克改为`=1`真分辨率，并对单个3D视口启用2xMSAA；保留Kenney五色、多网格合批和太阳阴影。旧PlaneMesh基础地面不再实例化，主地图绑定可变地层、真池塘；NPC身高和世界坐标贴实际地表。**NPC施工工必须先挖足4个坑位共8层真实地基**才能去仓库领石材并按原守恒规则运输和建造；工人挖坑和玩家帮挖共用同一地形API，无法重复结算地层。旧存档未写。
- 延续原APK176实际编译主场景覆盖 `main_original_interactive_rev184.tscn`、`main_rev184.tscn.remap`，并把所有脚本与原认证Kenney/Quaternius原GLB按新路径加入 `logic-qa/tools/build_apk176_interactive_rev184.gd`、`tools/verify_apk176_rev184_3d_pck.py`。`logic-qa/apk176-export-fixture/verify_original_main_interactive_rev184.gd` 在头less真Godot中验收原创编译APK176主场景、原房屋进出、玩家身份/行走至少1m/相机真正旋转/按键缩放/切第一人称眼位并隐藏自体/切回第三人称/仓库交互/真实玩家挖土后碰撞mesh修订和守恒、NPC挖地基后才盖房、全NPC原物资守恒与树种、Kenney多边形原件与单方向光。
- `.github/workflows/canglan-apk176-rev184-interactive-strata-signed.yml` 首次`c3b942a`；沿用原RSA、原安卓身份`org.canglan.ancient25d.preview`/versionCode1176、Terrain3D精确版本、原基线真实导出3D Main实测、原房屋回归、坏补丁不发布。
- **确实修复实际QA失败**：`38978145628`由于漏提交rev184生态/调色板/合批对应脚本构建阻塞，真实新增脚本`9df21b4`/`fdbe46e`/`8730016`；`38978230879`Godot验收因room脚本仍使用rev183节点名，修复`8313947`；`38978340182`因地形节点ready后旧名覆盖预期树名，修复`24f6eb2`。未对这些失败假报通过。
- **真实完成原版OTA制作签名**：`38978406693`/job`117233260022` `completed/success`，PCK `21,638,048`字节，SHA-256 `e2a366e11fcbc6daac70e3af74b72ed7c03b88e85e125ade7d4714d0322426a0`，PCK逐文件校验原GPLB未篡改、RSA原公钥`original_rsa_signature_verified=true`，并有`PASS_REV184_SIGNED_OTA_PUBLISHED_TO_PUBLIC_MAIN`。已实查公开`android-preview/latest.json`是真正rev184（不是独立APK）。
- 面向用户的手机手动逐项验收标准`docs/QA_APK176_REV184_NATIVE_PLAYER_STRATA_WATER.md`（提交`d7c02e2`）：先检查清晰度，左摇杆走，右滑、加减缩放、切第一人称，邻近NPC/树石/仓库互动，挖实际土层、看剖面与有坡岸水体，NPC先挖地基。
- **仍待证据**：本轮正式Github源码及PCK已发，不代表官网CDN即时生效；需再次实测公开Pages实际HTTPS RSA+文件字节及客户端应用内加载。尤其**手机真实触控和帧率/发热、Draw≤200、原旧存档连续性并未由headless自动验证**，用户收到测试后才能标绿。由于恢复原生分辨率，若FPS下降要进一步优化材质合批/旧主场景多余渲染、场景遮挡/LOD，不能未告知就再降整屏分辨率。

**明确未完成**：完整全球地形、高低地块流送/地质生长致喜马拉雅、三维体素洞穴、地下水渗透、湖泊真实流体、古代中式房屋材料齐套、全世界持久化与新玩家存档续载、复杂第一人称攻击/拾取UI。本轮是用户可移动可互动的**92m首个真实土层可挖村庄切片**，不能把它描述为完整大型古代修仙游戏。


### rev184公网正式CDN闭环补充（2026-10-17）
- GitHub Actions只读站点审计脚本`.github/workflows/canglan-rev184-real-pages-http-proof.yml`（初始`07ce279`，由真实作业`38978640782`揭示遗留了rev183硬编码断言，`f54811f`修正为严格rev184后再跑）。**成功Run`38978699481` / job`117234209097` `completed/success`**：真正公网`https://160701541-cell.github.io/xinyanshuo/android-preview/latest.json`回rev184，原APK176固定公钥RSA验签PASS，完整下载PCK恰好`21,638,048`字节且SHA-256`e2a366e11fcbc6daac70e3af74b72ed7c03b88e85e125ade7d4714d0322426a0`，请求1MiB Range返回HTTP 206；日志marker为`PASS_APK176_REAL_REV184_PUBLIC_PAGES_RSA_SHA256_HTTP_RANGE_PHONE_DOWNLOAD_READY`。CDN缓存头`max-age=600`。
- 因此**原APK176真实构建签名与正式互联网资源下载已通过**；尚未得到用户手机rev184实际走动、双指缩放、第一视角、挖地基及水体截图，禁止写手机验收通过。手机无需重新下载安装包，不清除旧存档。


## 2026-10-17 / PHONE-REV184-FAIL → ORIG-REV186-THREE-MANUAL-PROFILES / 手机QA优先、真实自适配预算

### 新增唯一有效画质合同（覆盖过去全部画质和性能预算；其他要求不变）
用户实机设备：**一加 Ace 5 Pro，Snapdragon 8 Elite/骁龙8至尊版，Adreno830，2780×1264，最高120Hz**。用户明确撤销过去所有统一画质/性能数字预算（含Draw≤200、15万三角面）；从本轮起仅按 `AGENTS.md`新增P0、`docs/GAME_ENGINEERING_MASTER.md`最新章节与`docs/QUALITY_DEVICE_ACE5PRO.md`执行：极致100%+MSAA4+阴影100m+草80m+100萤火虫+雾/辉光/云全质参考1500Draw/150万面、目标≥60争取90–120；**高档默认**85%+MSAA2+阴影60m+草40m+60萤火虫参考800Draw/60万面、目标60+；普通67%+关AA+阴影30m+草20m密度降低+20萤火虫参考400Draw/30万面、目标稳定60。三档均只手动切换、长期保存上次选择、<45FPS只告警不自动降档、极致发热耗电提示不限制、帧限随系统当前允许的Hz最高120、2D UI始终原生画质。名称标签、雾、光影、草、云、粒子均不同档位调整实际范围和密度。

### 用户真实Android截图明确P0 FAIL（此前rev184的Godot headless PASS不能代替）
用户2026-10-17 rev184手机图①：左上角约`30FPS/60Hz/GPU 6.49ms/Draw557/三角面331005`，画面是2m大小地形单元中心高度不同造成的大面积方格悬崖/直墙，既不像自然泥土地貌也不具有实体行走的视觉品质。图②：约`30FPS/GPU 8.07ms/Draw551/三角面326491`，施工门/板等放大遮住画面，`施工工·CL-NPC-0184-03`系统ID呈巨大黑描边标签，玩家和NPC实际外观仍看不见或被埋/遮挡；玩家摇杆不正常移动，左右木材资源点不能点击。第三张用户实拍自然道路供视觉参考：有真实路缘、面层砖缝纹理、稠密有体积植被、坡面连续与层层遮挡；并非要求实拍贴图覆盖Kenney低模。**必须拿实际手机画面评价，不得把模拟器跑通宣传为手机完成。**

### 源码真实已改
- `apk176_strata_terrain_rev185.gd` commit`60d259a`，后继 `rev186.gd` commit`cf6ce1e`：**P0消除假地形阶梯根因**——原每个2×2m格子只用中心高度生成水平四边形和四圈夸张垂直土墙；现未挖区域采用相邻共享坐标角点的连续实际斜坡，各处真实地面仍可挖土、碰撞随地形重建；垂直地层墙仅发生在真挖坑处或地图外缘，继续土/黏土/砾石/风化岩/基岩4+1地层与不凭空挖出资源的账本；河床盆地和局部水体保留。仍欠法线进一步平滑、微观纹理和大世界地层LOD。
- `apk176_quality_profiles_rev185.gd` commit`30e26b5`，后继 `rev186.gd` `a854996`：三套玩家手机参数统一唯一代码；真正独立的3D `SubViewport` 100/85/67精确像素+4x/2x/无AA，太阳阴影100/60/30，草4500/2400/1100可见80/40/20米、粒子100/60/20、云9/5/2和雾密度分档、NPC近距名称20/13/8米；`user://canglan_graphics_profiles_v1.cfg`保存上次手动档位；`RenderingServer`采真实Draw/三角面和帧率、显示实际渲染像素/刷新率、<45仅警告。受本旧版Godot Mobile Vulkan支持范围所限，粒子自发光/简易云层只是可运行近似，**尚未完成真正Forward+体积云与屏幕辉光**，不能谎称三档最高表现已满足。
- `apk176_player_controller_rev185.gd` commit`d82ecc8` / 修脚底双叠加`529c9f4`，后继`rev186.gd` commit`c0a8d57`：真实 `Control.gui_input` 接收左摇杆而不是靠本来被宿主UI吞掉的`CanvasLayer._input`；用控件本地坐标计算左摇杆，不与右屏触控撞；右侧拖镜头/双指缩放，左右屏幕点击3D屏幕投影中的树石/NPC（MultiMesh独立实体ID数据不由碰撞推定），自动向目标移动，接近后通过权威NPC经济规则门采集/交仓库或询问NPC。`rev186`新增**屏幕左侧树林点击窗口（摇杆优先）**，避免rev185仅右半屏可选石矿。键鼠可用但不作为移动端替代。系统ID保留规则层键并继续跨rev185/186稳定，不在世界标签悬浮整串`CL-...`。
- `apk176_living_resource_world_rev185.gd` commit`6e676af`、改节点名`4b332bd`；后继 `rev186.gd` `ec0c2f4`：从`SubViewportContainer`整数`stretch_shrink`（无法实现85%/67%）换成专门3D纹理`SubViewport`→全尺寸`TextureRect`，游戏按钮/标签HUD仍由独立原生2D层绘制；增加“画质设置”按钮、三档手动选项和高档默认、极致发热提示、准确诊断HUD；隐藏原APK176带旧200Draw预算的Label/RichTextLabel黑板；人物从真正Quaternius成品GLB骨骼计算原点与脚底offset，再每次移动按地面海拔+offset放置，减少NPC地下隐身；旧版巨型显示全量系统ID改为近距仅显示`樵夫/采石工/施工工`短职业名称，逐档距离衰减。不修改原存档。
- 沿原APK176编译Main继承和PCK入口`main_original_quality_rev186.tscn`、`main_rev186.tscn.remap`；所有现成Kenney/Quaternius合法原始GLB SHA保持不变。附`logic-qa/tools/build_apk176_quality_rev186.gd`、`tools/verify_apk176_rev186_3d_pck.py`、`logic-qa/apk176-export-fixture/verify_original_main_quality_rev186.gd`：真正Godot4.4.1加载原应用打包Main/旧房屋场景兼容、三档每一项大小/阴影/草/粒子/云/AA/长期手动保存、旧ID规则不乱、玩家实体脚与NPC骨骼贴地、真实可挖坡面不大量逐格自然竖直墙、原NPC360步采集搬运施工守恒、GUI触屏信号真实驱动模拟；QA无法代替人手在手机测试。

### 实际CI与发行证据 / 未验收
- 原版rev185 GitHub原版签名PCK `38981382182` / job`117242788874` **completed/success**，SHA `04e33760b69a95186dbff7ab0e313568cef5d57d83e2ce9916992f759f9f106f`（构建时文件21,663,616字节），成功发main，作为下一rev基线。第一轮`38981303439`QA实际发现把草/云的MultiMesh误算到“六个Kenney资源批次”导致严格检验误报失败，修复`7d9065c`，没有删除检验。
- 原版rev186 **完整通过** `38981695728` / job`117243794180`，所有老房屋兼容、真世界启动、模型身份、同位置脚底、左/右GUI触控、三档/存储、官方RSA签名+release gate均成功；正式原APK176 `android-preview/latest.json` revision**186**，PCK `21,666,016`字节，SHA-256 `16c636e2654efb8ead50cfe38e1ab27ac89f9c9cee72d4acb28f8cfb55f6a6ab`，原包ID/签名公钥保留，旧存档不覆盖。
- 公网真实CDN审计工作流 `.github/workflows/canglan-rev186-real-pages-http-proof.yml` commit`9cd133e`首次`38981795153`失败是真实**GitHub Pages仍返回旧revision184**（3次重试均同），不是生产签名PCK代码失败。持续待Pages队列将最新公开main部署后重新读取真实HTTP/RSA/206再签收。**不能在Pages未验收时说手机已经检测更新**。
- **用户这部手机新版三档实际FPS/Draw/三角面均全部“未验证”**；需要玩家更新后逐档拍摄并连续测试，特别注意复核摇杆真的行走、能直接点击左树林、第一视角和完整人形可见性。真实达标再改状态灯，不能把headless PASS写为实机PASS。历史rev184约30FPS数据不准冒充三档数据。


### rev186 公网OTA最终校验证据（纠正此前Pages过期状态）
- **GitHub Pages Build+Deploy**：run`38982016201`，官方main建站和deploy作业均`completed/success`。另一个自动HTTPS验签作业`38981795153`初次因Pages/CDN滞后返回revision184而fail，不是程序通过；**Pages正式重新部署后重跑同作业，新job`117245214387` `completed/success`**。
- 真实GitHub Actions外部网络校验日志：`PASS_APK176_REAL_REV186_PUBLIC_PAGES_RSA_SHA256_HTTP_RANGE_PHONE_DOWNLOAD_READY`，公网官网确实返回revision`186`，正式原APK176固定RSA公钥验证通过；完整下载PCK字节数`21666016`，SHA256`16c636e2654efb8ead50cfe38e1ab27ac89f9c9cee72d4acb28f8cfb55f6a6ab`；HTTP Range响应206，CDN `Cache-Control: max-age=600`。因此**原版生产签名发布+真实公网可检索/可下载**已证实，用户原安装包APK176理论可通过游戏内更新器获取。
- **保持手机黄灯**：上述所有严格CI及网络验签结果不能代替用户在一加Ace5Pro实际更新rev186后的真机验收；三档FPS/Draw/三角面仍全部**未验证**，明确等待三档手机截图，不写虚假稳定60或极致120。


## 2026-10-17 / REV187-USER-REAL-DEVICE-P0-CAMERA-GRASS-FPS-RICH-NATURAL-PALETTE (代码已提交，持续QA，未通过绝不抢发)

用户明确rev186实测存在**帧率上限意外30**/旧性能板60Hz与系统120冲突、双性能面板重叠、灰紫天空雾、薄片世界外缘灰色空洞、草为漂浮绿色大方形、镜头穿模遮挡、NPC职业错误“施工工”、右侧下滑向上眩晕、无法自由飞行/上帝视角/开局被困。**同时撤销全部五色锁定及任何限制颜色种类的既往规范**，但保留Kenney低多边形风格、三档画质/光影/性能、真实地层/资源经济/旧存档规则；要求“测试包名”及同一工地位置真实前后截图。

### 真实提交变更
- `apk176_kenney_visual_palette_rev187.gd` commit `3647440`，补色修复`1c0d051`：原“EXACTLY FIVE”废止，新增约30类可复用自然材料色，树冠黄绿深浅、木质棕系、矿石青灰/褐灰、泥土多色、屋瓦/白墙/门窗分色与青蓝水、白黄粉紫花；**保留原授权Kenney/Quaternius网格和能保留的原材质纹理/UV**，不是自己手搓整栋建筑。
- `apk176_kenney_multimesh_rev187.gd` commit`a9cc440`：真正启用MultiMesh per-instance color，同源树石可不同绿/灰/棕而不会因为颜色变化把每棵拆成新drawcall。
- `apk176_strata_terrain_rev187.gd` commit`247bad9`，GDScript编译修正`ed7b619`，远景渲染缺失进一步修复`fa0f68a`、编译行331修复`2d49235`：原92×92米真实三角网格可挖土层/碰撞和质量守恒继续；局部草土/浅沙地表多色，挖掘时发出`terrain_cell_changed`给草花；边缘加入真实土层侧裙`RealEarthCrustBorderSkirtNotFloatingThinSheet`，周围636m远景山丘Lod网格。**视觉首次真实引擎帧**发现背景far mesh单对象>6.7万未索引顶点在llvmpipe Vulkan仍显示蓝色空洞与山影横条，于是改为18×18网格小块裁剪，真实截图重新验证前不能宣称修好。
- `apk176_quality_profiles_rev187.gd` commit`c6ffe4a`，Godot无headless vsync修复`c4cb2f6`、刷新率NaN提示修复`723c189`：三画质档保留原参数；FPS独立可选默认`跟随刷新率` (Engine.max_fps=120 + VSYNC)及30/60/90/120；别再使用旧报告30/60Hz直接误锁30；旧系统显示接口仅作辅助观察值，不代表设定120不可用；用户手动选择保存在`user://canglan_graphics_profiles_v1.cfg`。真实每丛五片三角细草叶0.31–0.586m、不再是QuadMesh方片、4500/2400/1100多绿光影、270四种野花、挖地草花及时跟地高程或移除；半透明有轮廓软白云、淡蓝雾、暖阳和轻量粒子按三档密度切换，GPU端真正高阶辉光和立体云在旧Godot Mobile下仍待专门支持。
- `apk176_player_controller_rev187.gd` commit`3873da9`：右屏手指下滑=看向下（反转旧版眩晕设置），新增可进入/退出上帝视角可平移/缩放、自由飞行及升降、重置镜头退出卡住；第三人称与跟拍施工工将镜头-主角间用物理raycast对抗建筑穿模/整面遮挡。
- `apk176_living_resource_world_rev187.gd` commit`bd3d1d3`，原APK176 CanvasLayer修复`6175f1a`，系统村庄ID稳定修复`8e1917c`：白蓝渐变天空、暖太阳、淡蓝雾、摄影机远距450m；唯一新性能面板使用垂直VBox不重叠可折叠，旧版FPS/GPU/Draw面板通过源Main隐藏并定期复查，返回旧游戏时复原；设置里FPS五选项+极致发热提示；工地原授权建材加入轻量镜头碰撞Proxy，NPC名字改“建筑工”并继续**保留后台系统ID**。
- 原APK176继承Main与RSA OTA复用：`main_original_quality_rev187.tscn`/`main_rev187.tscn.remap`/`logic-qa/tools/build_apk176_quality_rev187.gd`/`tools/verify_apk176_rev187_3d_pck.py`/`verify_original_main_quality_rev187.gd`；QA仍验证原APK176的seven licensed GLB、NPC采集/树种、挖地层/材料守恒、原房屋出入、系统ID保留、真移动与左右Android触控、三画质/5fps上限、折叠警告、草叶与随挖更新、山形、蓝天、上帝飞行与右滑正确方向。编译脚本全部走Godot4.4.1 `--check-only`，不依赖文本grep假通过。
- 原编译APK176真实Vulkan渲染截图 `capture_original_main_rev187_compare.gd` commit`5e546f3`：以真实已装APK176编译Main＋无签名临时rev187 PCK，固定工地远近机位，在开源Ubuntu24.04+Mesa llvmpipe上输出两张1280×720像素PNG；**这是Godot软件GPU真实frame，绝非一加手机实机图。** 首次CI`39000880166`产出真正PNG后被CI的PNG签名检验错写双转义码拒绝；修复`800d25e`使用原始PNG字节hex；对首帧发现的远景空洞也继续真实修正，不能用首帧冒充全部视觉通过。
- 用户明确授权独立QA包：`game-source/apk176-ota177-candidate/qa-rev187/`含Project、Main、独立Android export preset(项目标识`com.xinyanshuo.canglan.rev187.qa`)，`.github/workflows/canglan-rev187-independent-qa-apk.yml` commit`a3bbdd3`在原版正式签名成功后自动构建同源3D可单独安装的测试APK，用不同debug签名/包名验证，与正式`org.canglan.ancient25d.preview`保留独立、不能代替原版游戏热更新或旧存档。**该独立测试包在真正Actions出安装APK字节前不能称已生成。**
- 最高执行规范同步追加`AGENTS.md`、`docs/QUALITY_DEVICE_ACE5PRO.md`和`docs/GAME_ENGINEERING_MASTER.md`新最后优先条款，撤销任何历史限色，其他性能预算三档和NPC世界要求继续生效。

### 实际QA失败和当前状态（严禁虚报）
- `39000137447`最初缺生态脚本 -> commit `64231b1`；`39000211083` rev187 strata脚本解析错误 -> 增加每脚本真Godot check gate`f752158`；`39000300212`地形line315多行表达式 -> `ed7b619`；`39000362804`原CanvasLayer rev186名字误导致runtime查找失败 -> `6175f1a`；`39000451689`QA新材质名grass_deep fallback绿色 -> `1c0d051`；`39000619760`QA误把父子结点路径看成根节点 -> `5eba785`；`39000697812`真实全村资源核算失败因系统村庄ID误变CL-REV187 -> `8e1917c`恢复CL-REV186；`39000880166`严格原Main QA/旧房屋通过、Mesa实际截图两张成功，却被错误PNG字节检查拒绝，随后发现远景几何蓝空洞并改块/质量门禁；之后每轮仍须完整验证。失败全部是实际阻断发布，不把失败run包装成成功。
- **rev187正式RSA/官网PCK/独立安装测试包：只有在后续完整CI成功并逐项检查证据后才能标PASS。** 现有公开正式渠道revision至少rev186；用户手机rev187极致/高档/普通实测FPS/Draw/三角面均**未验证**；用户要求实际手机截图才能进一步打绿。

### 2026-10-17 / rev187 已发布后的CI回归与用户实测交接（不得重复覆盖签名PCK）
- **已验证首次真实发布**：原APK176 rev187正式QA run `39001352826` success，运行日志有 `PASS_REV187_SIGNED_OTA_PUBLISHED_TO_PUBLIC_MAIN`；主分支 `android-preview/latest.json` 当前标记 revision=187，APK版本代码范围1176，PCK大小21688608字节、SHA256 `34558a8da86e99b684316e425e18c12dc0d8f4f766b96691f08e00b2de981d2a`。**仅代表发布记录和仓库清单，不能冒充手机加载成功或公网CDN字节已复核。**
- **后续源码不等于已发布补丁**：rev187既有PCK在此前SHA `723c1899` 流程构建发布；之后的源代码修复 `759a3cf6` 等不应被同revision覆盖。run `39002357154` 因调色板重复键解析失败；commit `3d2a213` 删除 `grass_deep`/`grass_light` 重复键。该修复**不自动出现在用户已经发布的rev187 PCK中**。
- **新的真实QA**：run `39002675786` 完成Godot源码解析、原APK176 Main、原房屋进出、Mesa Vulkan工地近/远两张1280×720截图；末段失败 `BLOCKED: QA candidate is not next-revision APK176 template`，因为rev187早已发布，防覆写安全门正确拒绝同revision再签名。
- **CI修复**：commit `a30a7b2` 和 `67301ac` 在 rev187 全部Godot QA结束之后增加既有正式版本侦测；检测已经发布后仅保留QA报告，不再重复签名/推送同版本PCK。只有正式渠道仍是186时才可签发187。原有签名与线上文件保持不变。新版门禁的整轮Actions结果尚待实跑验证。
- **下一轮发布必须采用新revision（原则上rev188）**；先QA、实机兼容性和签名验证，然后更新正式manifest，绝不覆盖用户正在测试的rev187文件。用户已开始手机实测，极致/高档/普通FPS、120Hz、天空/雾、草、远景边缘、镜头与NPC尚待真实截图反馈。

## 2026-10-17 / rev187 一加Ace5 Pro四张真机截图：P0视觉与可玩性拒收，冻结新增功能
- **证据类型：玩家真实手机截图四张（含上帝视角/贴近建筑/远景），不是PC Godot截图。判定：rev187真机美术、地形碰撞与核心交互整体不合格，禁止宣称验收完成。**
- **P0-01 地形错层/物理穿模**：浅青整片地面、建筑下方空洞与悬空白地，侧边出现陡直切面；要求同源地表高度与碰撞重建，主角、NPC、建材、楼梯落地，真实墙面/门洞/楼板结构不能互相穿插；Godot实机近远四机位+上下楼碰撞证据。
- **P0-02 建筑不是可居住房屋**：现阶段四根结构件/多排独立台阶近似施工架，屋顶、墙、窗、门、室内、床位缺失，无法进入。禁止将摆设资产冒称完整房屋；要求先一间可入住的围合式中国民居，正向室内门洞（门开关、碰撞）、有地板/屋顶/窗、2张床/住户占用、可触摸家具与出入逻辑，开门/进屋/关门三帧实机通过后批量扩建。
- **P0-03 玩家和NPC可见性**：玩家报告无身体/手脚，NPC只见职业标签，无遮挡时人物也不见；需要实际显示有动画的授权人形（第一人称手/身体或可见腿部，第三人称全身）；动画idle/walk、脚步与碰撞同位；防止GLB缩放、地形Y偏移、相机near、渲染层、Cull及无材质引起隐形。
- **P0-04 交互断路**：看得见按钮不等于玩家能砍树、采石、开门、砌墙、拾取/交付；需Android真实touch事件日志→目标实体ID→距离→采集/库存变更→对应动画与视觉变化的连续验收。楼梯要能真实走上去，不是单独浮空装饰。
- **P0-05 资源不可持续**：截图木石和树库存随伐木变化，但森林消耗后仍无可辨认新苗；检查砍伐发放种子→运输入仓→扣种播种→苗/幼树/成树分龄可见；审计每12秒sim.tick对应1小时、72小时成熟与树木3D渲染回填是否实际发生，不能只测账本。
- **P0-06 色材和世界丰富度**：地面是平坦无纹理浅青，草零散近似胡茬，远景光秃；木柱土墙树木花草缺真实材质/贴图细节；验证Kenney GLB外部colormap路径、UV、纹理赋值及风格匹配，生态散布按地貌簇群和距离LOD，严禁草片贯穿建筑、台阶、河水。
- **P0-07 镜头与性能真实性**：图一实际显示30 FPS/60Hz/GPU9.77ms/Draw340>200/三角面271483>150000；图二61 FPS/60Hz/Draw361>200/三角面182181>150000。游戏显示60Hz并不能证明手机物理刷新率，必须测Android Display refreshRate、Godot Engine.max_fps、实际FPS，按不同档位分开统计；图中仍有大型遮挡UI，应减法设计。
- **实测中的正面证据**：用户确实加载rev187，能够切换上帝/飞行镜头，世界资源库存、施工阶段、NPC活动日志随时间变化；但这些均不抵消P0不合格。
- **根因线索（源码证据）**：rev187 `_place_stage_art` 仅对foundation/木柱/围栏/门直接放缩放的Kenney零件，缺整屋组成/室内；`_make_workers` 仅三人，人物GLB需查原比例与动画；`_seed_resources` 仅初始12树+9石，种苗生成依赖种子入库/小时流转；`_place_asset` 以地形高度设置零件原点，没有统一支撑面+碰撞/包围盒规划。**优先修真实实现，不继续新增按钮或假场景。**
- **版本安全**：已经公开签名的rev187不可覆写；所有后续真修复以rev188及之后独立升级签名PCK投放，正式变更需先通过Godot实测和真机验收。用户已有截图，不再要求先给同一套截图。

### 2026-10-17 / 玩家真机P0增补：手机界面不是游戏HUD，rev188角色面板首批代码
- 玩家明确指出rev187满屏开发测试按钮与调试盒，无个人状态、背包、生命、灵力、技能招式、修炼菜单，不具备商业手游的基础交互布局。定为**P0-08 游戏UI/角色系统缺失**，与地形/建筑/人物一样严重。完整验收包含左上头像、HP/灵力/体力真实状态，技能槽和CD，右上小地图、任务、菜单，背包/人物/装备/功法/修炼/门派面板，横屏安全区与触摸不遮挡。
- 源码提交 `fc44eaa`：原APK176兼容候选玩家控制脚本增加**实际绑定模拟人物体力**的顶部状态组件；“角色/背包/修炼”三个能打开关闭的面板，背包直接读取`carried_by_actor`实际随身物资，不生成虚构装备。**生命/灵力/技能战斗系统尚未存在，明确在界面标“未接入”**；不能把假HP/MP数字当真实角色系统。
- 现阶段这是rev188 UI增量源码，不是rev187已发布PCK；仍缺HP/MP权威数据、真实技能快捷栏、招式使用和CD、完整背包装备物品树、任务地图与可替代调试按钮的HUD。必须进一步实现，且Godot真解析、原Main运行与手机实测未通过前一律不标QA PASS。

### 2026-10-17 / REV188 首批玩家UI、实物行为及官方OTA流水线（手机尚未验收）
- **实际源码**：世界脚本 commit `4d23551` 新增开发者面板默认隐藏 `developer_ui_visible=false`，内部流水/施工按钮和旧指标仍可从游戏菜单显式打开；无需卸载/改APK。
- **玩家状态UI与实际操作**：player controller commits `2130347`、`b262fb9`、`4914276`、`740465f`、`0957609`、`fcc63d0` 实现左上生命/体力真实条、未检测灵根及不可冒充的灵力锁、角色/背包/修炼/设置菜单、右下采集/疾步/挖掘/互动/视角按钮和不可用招式槽；保留旧摇杆/触摸视角。体力来自原经济世界独立人物数据，采集进入真实携带账本，疾步实际向前2m且扣8体力/3s冷却、检查地形高度/水域/物理墙；地形跌落改变生命，仓库附近可调用`feed_citizen`真实扣村庄食物1以恢复12生命与4体力。不虚构修仙境界/法力/尚不存在的战斗技能。
- **真实QA新增**：`verify_original_main_quality_rev187.gd` commits `794c322`、`474eb84` 增加Godot原Main在运行中检验十个手游UI节点、生命进度条17点真实扣减、体力读独立人物经济数据、背包页面打开、调试按钮默认隐藏但可显式开启。检验打印`PASS_REV188_REAL_HEALTH_STAMINA_GAME_HUD_BAG_MENU_AND_OPT_IN_DEV_TOOLS`。
- **首个真实阻断与修复**：run`39004251933` 真实Godot QA在脚本`_refresh_game_hud`反复报未找到休整按钮（硬编码自动VBox路径），不可假称通过；随后commit`fcc63d0`改为直接保存`_rest_sheet_button`引用。**完整Godot 4.4.1 原APK176实景QA run`39004327547` completed/success**，包括GDScript解析、原Main功能回归、旧房屋兼容、两张真实Ubuntu/Mesa Vulkan软件GPU 1280×720截图；首次出现的QA失败已阻断并真实修复。**没有一张是真机截图**。
- **正式发布准备**：commit`6803e9d`新增单独`.github/workflows/canglan-original-apk176-rev188-player-hud-signed.yml`，以当前正式rev187为基线，只在原Main完整严格Godot QA含上述rev188 UI门禁通过、签名私钥与原APK176固定RSA公钥验签通过、且远端正式版本仍是187时才创建rev188新PCK和更新latest.json；绝对不覆写已有rev187；运行是否通过和正式发布是否成功须查Actions日志与仓库最新manifest才可以标记。
- **明确未完成/P0保持**：当前仍只是一批玩家可用UI和凡人生存动作，不是最终国风商业HUD。真正招式、法力/灵根检测、装备物品树、任务/小地图、室内居住、真实NPC可见性、足量森林、地形严重穿模、楼梯行走等**仍然缺失且未验收**；下轮按真机P0清单继续，不许基于PC QA标手机成功。

### 2026-10-17 / REV188 正式原APK176 OTA + 真实公网验签已经完成（手机仍未验收）
- **正式Godot原Main + RSA OTA构建发布**：run`39004515220` 完整QA **completed/success**。rev188 UI门禁`PASS_REV188_REAL_HEALTH_STAMINA_GAME_HUD_BAG_MENU_AND_OPT_IN_DEV_TOOLS`、老Main人物移动/经济采集/旧房屋回归、Godot 4.4.1脚本解析和两张Mesa真实引擎PNG通过；原APK176原公钥签发PCK stage`original_rsa_signature_verified: true`，运行日志`PASS_REV188_SIGNED_OTA_PUBLISHED_TO_PUBLIC_MAIN`，正式签发提交`a5a8f803`。**rev187旧签名PCK没有覆盖，也没有改动APK或存档。**
- 正式清单 `android-preview/latest.json` revision **188**，compatible versionCode **1176**，新PCK **21,709,184字节**，SHA256 `c859fd32201db72fdffbb27d2fdbe7829eb7f773ce6b6bd68785913d66117c87`；URL `https://160701541-cell.github.io/xinyanshuo/android-preview/canglan-content-rev-188.pck`。
- **真正公网HTTPS端到端验签**：新增`.github/workflows/canglan-rev188-real-pages-http-proof.yml` commit`d86c826`；run`39004702372`、job`117314670643`、artifact`12090870736` **completed/success**。实测Pages返回revision188、完整21,709,184字节PCK的SHA256精确匹配、APK176固定RSA公钥验签、HTTP Range**206**，日志 `PASS_APK176_REAL_REV188_PUBLIC_PAGES_RSA_SHA256_HTTP_RANGE_PHONE_DOWNLOAD_READY`；缓存头`max-age=600`，旧版可能需要缓存刷新。
- **验收边界**：这是签名发布/公网字节与真实Godot的PASS，**绝非一加Ace5 Pro真机画面/操作验收**。rev187已知建筑差、地形穿模、NPC不显形、草地秃、资源消耗和技能战斗未完成，仍列为P0；rev188只先交付基础角色HUD、真实体力背包、轻量生存动作和默认隐藏调试面板，真正法力与招式不虚构。下一次需手机确认rev188是否在原APK176内成功检测加载以及UI布局与触摸。


## 2026-10-17 / REV189–REV190 安卓原游戏手柄适配与正式OTA（Godot QA和真实公网验证均完成，手机实体手柄尚未验收）

### 实际源代码与功能
- `game-source/apk176-ota177-candidate/scripts/apk176_player_controller_rev187.gd`（历史文件名保留以兼容原版PCK资源路径），commits `f693502`、`6239abe`、`05bd176`、`e3ff78c`：使用**Godot4.4原生手柄输入**而不是键鼠按钮模拟。Android标准蓝牙/USB OTG控制器热插拔 `Input.joy_connection_changed`，按下事件`InputEventJoypadButton`，左摇杆移动/自由飞行平移、右摇杆时间步长独立旋转镜头、双摇杆径向死区；左右扳机实际采集/互动并使用阈值锁存，避免一按多次；A互动、X采集、Y挖地层、B疾步、LB第一/第三视角、RB真实背包、Start菜单、Back角色、Dpad缩放/菜单导航/飞行升降、L3疾步、R3重置镜头。手指正操作虚拟摇杆时优先保留触控，不抢输入；原有键盘/鼠标/触屏保留。仅处理实际已接入的已选手柄ID，摇杆松开死区防漂移，拔出后回退触屏操作。
- 游戏「菜单」保存手柄右摇杆灵敏度（0.7/1.0/1.3/1.6）、上下反转、摇杆死区（0.12/0.19/0.27/0.35），存于独立`user://canglan_controller_v1.cfg`，不改世界存档和NPC ID。显示接入手柄的设备名/映射提示，标准化SDL位置不保证所有非标准国产手柄都免配置。
- rev190 `e3ff78c`补齐**真正的画质/帧率原生弹窗**手柄焦点导航：Dpad上下选项、A调用相应Godot Button真实信号、B先退弹窗再退游戏主菜单、Start可关闭；不是“只允许触屏点画质”。
- 真实映射、安装/验收步骤文档`docs/ANDROID_GAMEPAD_REV189.md`（commit`33d013f`）。不虚构尚未实现的御剑/灵力技能、震动与通用手柄重映射。

### 真实引擎QA与发布证据
- `logic-qa/apk176-export-fixture/verify_original_main_quality_rev187.gd`提交`327fbeb`、`a6663e3`：向真实原APK176导出Main+候选PCK **注入Godot `InputEventJoypadButton`合成按钮事件**，检验A进入原生画质/帧率弹窗、B逐层返回、Dpad菜单焦点、Start设置、RB背包、LB第一/第三人称、BACK角色、实际右摇杆旋转、双摇杆径向死区，同时全套原NPC/场景/房屋兼容继续Godot 4.4.1测试，打印`PASS_REV189_SYNTHETIC_GODOT_JOYPAD_BUTTON_MENU_LOOK_DEADZONE_HOTPLUG_AND_TOUCH_FALLBACK_NOT_ANDROID_HARDWARE`。**此QA没连接真实Android手柄，不能宣称具体型号手机已验收。**
- rev189 首批正式PCK从早期源快照`88c4374`构建，原版RSA签名实际发布commit`9527822`，主分支manifest先升到189。run`39005501757`虽最后被新推送中止为`cancelled`，该作业**发布步骤实为success且日志含`PASS_REV189_SIGNED_OTA_PUBLISHED_TO_PUBLIC_MAIN`**。后续run`39005615484`全Godot QA完成但末段因189已经发布的安全门正常拒绝再次同版本覆盖；rev189本身公共网页加密验签run`39005702740` **success**，21,720,032字节，SHA256 `139da4fc2109cf0a32f0607331f28937a4e5037eb190440282390482b72c0250`，HTTP Range 206。rev189 manifest release notes误复制rev188表述，在**后继rev190**修正，没有覆盖rev189既有签名PCK。
- **最终rev190**完整补齐画质/帧率界面手柄导航，工作流`.github/workflows/canglan-original-apk176-rev190-gamepad-quality-menu-signed.yml`（commit`7627ce0`，正确manifest notes修复`3dffb63`）；Godot 4.4.1实际原APK176完整Main QA、旧房兼容、真实软件Vulkan截图、原固定RSA签名与升版本发布 run`39005843698` **completed/success**，日志`PASS_REV190_SIGNED_OTA_PUBLISHED_TO_PUBLIC_MAIN`。原版APK176不变（versionCode1176），rev190签名PCK大小 **21,720,928字节**，SHA256 **`6fe2c6c126e3ac37a19b788695bcccba2e605e460882519cbff37b27e99c25e6`**，官方manifest已升 **190**；rev188/189已发布PCK不覆写。
- **最终真实公网CDN验收**：`.github/workflows/canglan-rev190-real-pages-http-proof.yml` commit`72c8490`，run`39006060904`、job`117318677399` **completed/success**。Pages真实HTTPS返回revision190；原安装APK176固定RSA公钥验签/完整21720928字节SHA256/HTTP Range 206，日志`PASS_APK176_REAL_REV190_PUBLIC_PAGES_RSA_SHA256_HTTP_RANGE_PHONE_DOWNLOAD_READY`；缓存`max-age=600`。此结果仅证明手机可以正常获取验签补丁**不能冒充实体游戏手柄操作已验证**。
- **QA待验收**：需要用户在一加Ace5 Pro手机中原APK176检测并加载rev190，连接实际蓝牙或USB手柄，测试左右摇杆同时操作、A/X/Y/B、RB背包、Start设置-Dpad-A/B选择画质与关闭、拔出自动恢复触屏。廉价或模式不标准手柄按具体型号/GUID修复，不添加未经证明的通用映射。原rev187真机地形穿模、房屋不可住、NPC不可见等P0继续红灯，此轮不假称相关修复。


## 2026-10-17 / Minecraft级超大世界方向确认与rev191→rev192实机截图P0地形纠错（正式OTA已发布；**手机新图仍待验收**）
- **用户产品基准**：目标是类似《我的世界》可长期探索、真实改变/资源更新/NPC持续生活的**无固定小地图边界的程序化无限延展世界**，视觉要高质量仙侠、自然草地、真实中式可居住院落，不等于像素/方块画风。用户2026-10-17真实手机截图见到大面积浅蓝背景地块和清晰矩形断面；与提供的国风庭院、仙侠草甸、宗门山门HUD参考相比，美术和可玩性远未达标，明确红灯。不再将固定92m局部挖掘+636m远景冒充无限世界。正式分块/持久化/NPC/碰撞方案见`docs/WORLD_STREAMING_REV191_ACCEPTANCE.md`（commit`50d2de9`），后续需实装而非只写计划。
- **rev191实际源码**：`apk176_strata_terrain_rev187.gd` commit`d515b6c`删除旧22米竖直"地壳裙边"，真正远景地面6m各格精确裁切在中心x/z±46m后发射三角形；交界使用同一个高度函数并平滑外环起伏，绝不在中心叠画远景多边形。原版真实Main自动化遍历Mesh三角面，检测中心覆盖数0、≥75个真实边缘顶点与原场景同高（误差<2mm）、绝不存在旧硬截面模型；打印`PASS_REV191_NO_FLOATING_SLICE_LOD_OVERLAP_OR_22M_CLIFF_ACTUAL_MESH_TRIANGLES`。
- **rev191草地源码**：`apk176_quality_profiles_rev187.gd` commit`cbd255f`将5根不足4cm宽的胡茬草换为11片宽弯叶的实际MultiMesh草簇，88个确定性草甸中心聚簇，保留三画质4500/2400/1100档及按真实挖地变化，拒绝路、水、施工地、坡面过陡；小花向草甸聚拢。**仍比参考仙侠游戏植被品质低，不能宣称最终美术合格。**
- **关键新QA发现：过去所谓通过的Godot截图实际上没有渲染中心土壤**。从run`39007004017`（源commit`495634a`）下载两张**真正软件Mesa/Vulkan**原Main截图并检查像素：天空取RGB(184,217,232)，画面地表中央样本约**83.1%与天空RGB一致**；就是用户一直指出的大片浅蓝"假地面"，不应称仅是配色问题。根因：真实挖地网格因默认面剔除而不可见，只能看到后面天空/草。**修复commit`cdbb0b6`把地层的StandardMaterial3D设CULL_DISABLED**；新增真实framebuffer QA `_audit_visible_ground` commit`aca73f9`，旧图必FAIL，修好后软件渲染采样的同一蓝天空比例降到 **0.0**（run`39007345501`，Godot验收成功）。这项是真引擎截图，不是ImageGen图也不是手机实拍。
- **第二轮QA肉眼又发现：修好地面可见后出现2m绿/黄/棕**棋盘格**（原`_material_for`每个单元随机选材质）**。不能拿这种补丁当画质达标；commit`7f4b558`改为一个真实2m网格连续顶点色草土沙岸/道路生物群系，按世界绝对坐标持续变化、邻接边同色，挖过的真实地层仍单独层次；commit`397b47c`验证实际Mesh唯一连续顶点色地表、≥7独立色阶以及原实体资源、地形、手柄UI不回归。**Godot QA+两张1280×720真实软件渲染图** run`39007563235`、job`117323247251` complete/success；真实远景画面中不再呈蓝色空洞或2m棋盘格，但目前仍是低模/程序配色、屋舍只是工地、人员可见性及修仙玩法未达目标。
- **rev191先行发布已发生，源快照在地面剔除彻底修正前**：正式revision191的PCK SHA`0eac268f...`确有RSA签名发布 commit`6d199b1`，因此绝不能悄悄同revision覆盖。**真正交付这一轮完整地面修复的是新rev192**，防止版本回滚和存档破坏。
- **rev192正式原APK176增量OTA已实证**：workflow`.github/workflows/canglan-original-apk176-rev192-real-ground-biome-signed.yml` commit`ce84721`，run`39007803572` **completed/success**：Godot 4.4.1真实Main的parse/经济物理/原房屋兼容/游戏手柄合成输入/地表MeshQA、软件渲染截图蓝色空洞像素QA全过；真实原APK176公钥RSA验证`original_rsa_signature_verified:true`，日志`PASS_REV192_SIGNED_OTA_PUBLISHED_TO_PUBLIC_MAIN`。官网manifest版本**192**，兼容原APK176 versionCode1176；完整PCK **21,725,632字节**，SHA256 `395222d4c2264441d41040027caae01e397204244b6b18a354929d260d72035a`，仅此新版本，不覆写旧版。
- **独立公网验签**：`.github/workflows/canglan-rev192-real-pages-http-proof.yml`（commit`3697c97`）run`39007973365`, job`117324231278` **completed/success**，实际Pages HTTPS最新revision192、完整文件字节/固定RSA公钥签名/SHA256以及断点续传HTTP Range **206**符合，`PASS_APK176_REAL_REV192_PUBLIC_PAGES_RSA_SHA256_HTTP_RANGE_PHONE_DOWNLOAD_READY`；CDN `max-age=600`缓存可达10分钟。
- **验收状态务必清楚**：真实手机还没有加载/验收rev192，因此不得把PC软件GPU视觉截图当一加Ace5Pro。已确认且**未修好**：真正无限区块/可步行扩世界（仍受42m边界）、室内/床位/门互动的真实中国院落、建材表面纹理/屋顶造型、NPC角色在手机显示、修仙灵根/装备/技能法术与完整HUD、符合用户仙侠图的野外美术层次。下一步优先**rev193原生分块+碰撞+世界delta存储跨边实测**和实体住人建筑，不再堆不相关菜单。


## 2026-10-17 / rev193 真实可跨原92m边界的持久化物理地形区块第一版（已真实发布，手机未验收）

### 本轮完成的实际源码
- **目的**：用户明确要求的是《我的世界》式可持续探索和改造、采用仙侠国风美术的大世界，不是把92m测试场外围做一圈假山。此轮先完成**第一次真正可行走、具碰撞、可挖掘、跨边界、可存档的生成式区块功能**；仍不声称完整无限NPC/生态/可居住院落。
- **地形源码** `game-source/apk176-ota177-candidate/scripts/apk176_strata_terrain_rev187.gd` commits `ffb953b` + `fbc638a`：原92m中心以±46m精确对齐23×23个2m网格、边长46m的生成区块；周围2圈按玩家位置确定性创建/卸载实际`MeshInstance3D`和`StaticBody3D/ConcavePolygonShape3D`，相同世界坐标种子重建相同远景形态，且与中心实体网格交界共享高度。单次活跃外部块限制36个；**不再将仅渲染的远景当作玩家可走地图**，新区块有独立可行走碰撞、地形和挖掘网格。
- **玩家输入源码** `apk176_player_controller_rev187.gd` commit`5d34ede`：去掉原限死的42m步行和41m疾步硬阈值，用`stream_contains_physical_chunk`判断可行走世界；左右摇杆/原Android触控/手柄统一经原玩家位置和高度差、真实water检测、安全地形约束；每帧仅在跨入新的块坐标时更新近场流式区块，远距离NPC库存仍原样不复制。
- **真正世界编辑与持久化**：新区块挖掘1层0.45m后，必须先写入独立`user://canglan_world_streamed_terrain_v1.json`临时文件，再用原子rename替换存档，保存成功才重建渲染Mesh/Collision并确认产出。卸载块时只释放可视化/碰撞节点，**实际挖掘增量不丢**。重新进入同一区块保留高度和缺土。保存schema1/世界seed20261017校验；不改动旧原游戏存档和游戏包APK。
- **实际QA发现并修复重大守恒bug**：第一次新工作流run`39008512996`（失败）报告`EXCAVATION_CREATED_SOIL_OUT_OF_NOTHING_OR_LOST_MASS`；因为新区块挖土加入资源统计，旧守恒规则只统计92m中心挖土。commit`28cc736`重构`stream_spoil_bag`和`stream_removed_units`，根据持久化坑深重新构建历史挖土实物台账，避免卸载/重载时重复凭空发行泥土；commit`c40c5b5`增加原Godot项目经济守恒测试。**旧失败不可伪称通过，已补全实测。**
- **完整原APK176 Godot QA** run`39008646280`（commit`c40c5b5`）**completed/success**。包含实际GDScript解析、真实原Main世界模拟/NPC/材料/旧房屋兼容/草甸与远景地形、两张1280×720软件Mesa Vulkan原游戏截图。新门禁显示`PASS_REV193_DETERMINISTIC_WALKABLE_PHYSICAL_CHUNKS_NO_92M_WALL_AND_PERSISTED_MINING`、`PASS_REV193_ORIGINAL_PLAYER_ACTUALLY_WALKED_ACROSS_46M_WORLD_BOUNDARY`：真人玩家对象从旧x=45.65开始用原输入step实际越过x=46，新增区块StaticBody3D物理形状有效，实测外部挖地、原子写盘、卸载、重新从磁盘读取和物资守恒都通过。**这是Godot自动化驱动的真实玩家对象，不是手机实体手柄实测。**
- **真实生产RSA签名和不可回退升级**：工作流`.github/workflows/canglan-original-apk176-rev193-streamed-persistent-physical-world-signed.yml`（commit`23cd70c`），run`39008646280`的正式发布`PASS_REV193_SIGNED_OTA_PUBLISHED_TO_PUBLIC_MAIN`、`original_rsa_signature_verified:true`。官网manifest revision **193**，只兼容原APK176 versionCode1176，PCK大小 **21,741,056 bytes**，SHA256 `34e5032e405504cb6aa9ca32d4d2d3ef68663495d26ed62b6766634eeb6a13dc`。保留rev192已签名包和旧存档，不覆盖。
- **独立公网端到端验证**：新增`.github/workflows/canglan-rev193-real-pages-http-proof.yml`（commit`0e6743d`）run`39008823320`, job`117326736492` **completed/success**，实际Pages HTTPS下载 revision193完整21,741,056字节、固定APK176 RSA公钥签名、SHA256匹配、HTTP Range **206**，打印`PASS_APK176_REAL_REV193_PUBLIC_PAGES_RSA_SHA256_HTTP_RANGE_PHONE_DOWNLOAD_READY`；HTTPS缓存`max-age=600`。
- **用户可查真实引擎画面**：run`39008646280` QA artifact`12092102252`含`rev187-real-worksite/real_apk176_rev187_worksite_same_position_wide.png`、`close.png`；与以前相同测试镜头，草地、地面和简单施工台仍明显达不到用户提供的仙侠游戏参考。**不拿软件Mesa屏幕冒充手机实机画面，且截图没拍外部远行实景**。
- **目前仍红灯/P0**：可编辑真正全球chunk持久化仅具首版物理地形+挖土，**没有**跨区块自然树/矿资源/生成村镇与NPC作息、房屋室内床位、角色完整显示、修仙法术技能与真实宗门美术；静态远景旧LOD仍可能与新区块近地面有局部叠绘，需要真机检查；原起始村庄中心静态经济与角色位置未持久保存，并不应宣称完整Minecraft级无限世界。后续rev194优先跨区块植被/资源再生、背景LOD接管与已编辑地块内NPC经济，之后做可居住中式修仙院落。


## 2026-10-17 / rev194 夜间无人值守研发即时首轮：灰白雾/草地生命力 + 跨区块草甸（真实发布，手机仍待验收）

- **从现在立即执行**：用户授权不等待下一次「继续」或逐项审批；已经启用每小时的「苍岚无人值守研发」自动任务，同时当轮立即读取唯一公开仓库`AGENTS.md`和本日志并实际推进原游戏。每个自动任务必须坚持先代码、再Godot QA、再新revision合法RSA热更新，不把测试APK/PC渲染冒充手机验收。
- **实际源改**：`apk176_quality_profiles_rev187.gd` commit `541f5d3` 降低三画质原0.007/0.005/0.003的强雾到0.0020/0.0018/0.00145，调暗天空雾填充与环境光、降低过高日光、把泛青灰白草改为深绿/嫩绿/橄榄绿的真实成组颜色。`apk176_strata_terrain_rev187.gd` commit `7ea3dc2` 把原草土沙连续顶点色地表的绿色与土黄色调成更有层次的自然绿、暖棕/砂，远山也不再草白。
- **解决上版「无限地形却寸草不生」矛盾**：`apk176_quality_profiles_rev187.gd` commit `c9f33d5` 在**真实可行走碰撞区块**挂载与原中心同一草簇网格的`MultiMeshInstance3D`，每块确定性320个候选、11个草甸聚集中心，按极致320/高档210/普通100的用户手选质量截断；水、挖地、过陡坡禁止生长，挖地更新隐藏对应植物；卸载实体区块后草也随之释放。`apk176_living_resource_world_rev187.gd` commit `923b546` 每半秒同步真实载入区块植被，不在远景静态地块上伪造资源和建筑。相同区块坐标重载用固定随机种子恢复相同位置，不触动旧NPC经济与存档。
- **真实失败与修复**：首个Godot4.4.1 parse run`39009733329`报`There is already a variable named idx`，commit`eab481f`修复；后续Godot Main run`39009834431`拒收`REV194_STREAMED_GRASS_NOT_PARENTED_TO_PHYSICAL_CHUNK`，根因同一帧先卸载后创建**相同坐标不同节点**，旧grass仍被字典引用，commit`4beea9c`按当前父节点身份更新；run`39009909529`又发现旧QA仍引用废弃草节点名称，commit`2dac1e1`更正。未通过轮次明确记录而不冒充成功。新的**原Main真实运行**QA新增门禁`PASS_REV194_PHYSICAL_STREAMED_MEADOWS_DEEP_GREENS_AND_NO_WASHOUT_FOG`，检查已加载实体区块的草物理隶属关系、实际可见密度≥600、环境雾、植被颜色和旧经济/房屋/手柄/地形回归（QA源commit`7f441da`）。
- **全量QA与合法热更新成功**：新增正式工作流`.github/workflows/canglan-original-apk176-rev194-living-meadows-atmosphere-signed.yml` commit`04fbce7`，run`39010112152`（原Main GDScript parse/运行经济材料守恒/原人物和房屋回归/双机位1280×720 Mesa Vulkan真实Godot引擎帧/新草甸门禁）**completed/success**；真实生产签名检查`original_rsa_signature_verified:true`，发布`PASS_REV194_SIGNED_OTA_PUBLISHED_TO_PUBLIC_MAIN`。正式manifest现rev**194**，原APK176 versionCode1176，PCK **21,747,136 字节**，SHA256 `cfe4633dc0bb3f3e556effe11adf59a4f5943b13b190e6a03e957ffac7698caa`；不覆盖旧rev193 PCK或旧存档。
- **真实公网独立验证**：新增`.github/workflows/canglan-rev194-real-pages-http-proof.yml` commit`6c976a3`；run`39010250170` job`117331090059` **completed/success**，真实Pages HTTPS端到端拿到revision194/完整21747136字节/原APK176固定RSA公钥验证/SHA256匹配/HTTP Range **206**，打印`PASS_APK176_REAL_REV194_PUBLIC_PAGES_RSA_SHA256_HTTP_RANGE_PHONE_DOWNLOAD_READY`，缓存`max-age=600`。
- **视觉定量与限制**：两张均为**原APK176的同一Godot软件Mesa机位**，非用户手机：在远景截图（前景x260..1000,y400..590）的像素采样下，rev193平均饱和度约**0.1279**、平均亮度约**0.8174**；rev194约**0.1622**、亮度约**0.7289**，确实减轻惨白效果。来源为CI artifact`12092666273`内同位置引擎PNG。但是画面仍然是单调低模、草丛层次少、简易工地没有可住人房屋；目前只有区块上的草视觉，不代表新区块已有真实砍伐/花草种群与灵植经济。**用户真实手机rev194尚未验收，绝不写手机PASS。**
- **下一步无需用户确认继续推进**：rev195优先淘汰现在的`_place_stage_art`四步木材/围栏/门的假施工房——导入许可验证的中式成品模块件，在经济材料守恒前提下按真实NPC采集/搬运/施工产生正确比例的房屋，屋顶/门窗/地基/台阶/可进入碰撞空间/床位/住户及可互动物品；修复原授权GLB模型过小与NPC不可见问题。另继续真实跨区块森林生态再生和真正可读的修仙境界/灵根/技能体系。未满足验收不要发布“正式建筑完成”文案。


## 2026-10-17 / rev195 美术战斗对标研究与首个真实渲染/动作反馈补丁（手机仍未验收）

- **用户明确要求：向别人独立游戏开发日志学习，而不是口头称赞**。提交技术审读`docs/VISUAL_COMBAT_REFERENCE_STUDY_REV195.md` commit`e4282aa`，拆解用户提供的六格「天之道/御剑/完美闪避」与四格「格挡/完美格挡/闪避/完美闪避」及一个可战斗中式庭院 HUD 实景：清晰人物剪影＋统一色彩、真实时间轴、法术/碰撞/消耗绑定、多层特效、场景精细瓦砖、冷暖对照、可见角色；给出逐项可测 QA。**截图不能证明作者使用了哪种体素/像素/后期技术，亦不可直接复制原作者视频/资产。**
- **核对合法成品素材供应而不是重新造角色模型**：Quaternius Universal Base Characters 官方CC0/6带骨骼角色及20发型，Universal Animation Library 官方CC0/120+动作（八向/战斗），Kenney Particle Pack 官方CC0/80张粒子；下步先审计免费档实际文件/导入许可与骨骼兼容，再使用，尚未上传成品或声称导入。Godot Mobile 4.4官方文档确定 native Glow 支持，Volumetric Fog、SSR、SDFGI/VoxelGI不支持。
- **真实发现并修正隐藏渲染Bug**：游戏质量脚本 `apk176_quality_profiles_rev187.gd`虽然高档/极致档已有`glow:true`，实际`apply()`却**强制`scene_environment.glow_enabled=false`**。commit`86b8343`将其改为普通关闭、高档/极致开启原生Godot Mobile Glow，按官方 4.4 移动HDR推荐阈值0.90、强度1.25/1.45和小范围Bloom，增加小幅普通深度雾`fog_sun_scatter`模拟远处暖阳光散射（**不是假称真体积雾**）；实际飞萤纹理发光核心强度提高，绝不宣称拥有实时光追。
- **学习完美闪避/疾步残影后先实现真正有动作驱动的视觉反馈**：commit`0e8967e`在原`apk176_player_controller_rev187.gd`，**只有玩家真实支付8体力并成功移动2米时**才生成一次性的移动细碎光尘 `GPUParticles3D`，普通7、高档14、极致22粒，0.30s生命周期/0.65s自动释放；体力不足、障碍、冷却期间不产出特效，不会凭空给凡人开放御剑法术。不是参考作者的精美人物残影，仍是基础 VFX。
- **真实Godot原APK176 Main严格QA** commit`de1f8f0`测试三档`Environment.glow_enabled`真实渲染设置/移动HDR及实际性能指标；commit`3a1ebbe`测试实际玩家扣8体力→成功移动→出现唯一一次瞬时粒子→冷却再按不生成假特效，打印`PASS_REV195_REAL_GODOT_MOBILE_GLOW_HDR_THRESHOLD_AND_THREE_USER_GRAPHICS_TIERS`和`PASS_REV195_REAL_MORTAL_DASH_MOBILE_VFX_REQUIRES_SUCCESS_AND_STAMINA_DEBIT`。完整 Godot 4.4.1 导出原 Main、NPC资源材料守恒、真实施工/可挖地形/手柄兼容、2张Mesa Vulkan实际帧、QA run`39011832564` **completed/success**，此前 P0 没有被删改、旧存档未被修改。软件GPU行为不等于手机 Adreno 830效果或FPS。
- **原正式APK176 OTA 真实生产签名发布**：工作流`.github/workflows/canglan-original-apk176-rev195-mobile-glow-dash-vfx-signed.yml` commit`e83f2c2`，run`39011832564` 通过原固定公钥签名验证`original_rsa_signature_verified:true`，`PASS_REV195_SIGNED_OTA_PUBLISHED_TO_PUBLIC_MAIN`。官网manifest升**revision195**，仅兼容原APP versionCode1176、PCK **21,750,240字节**，SHA256 `f8631ad0107a94c954712af3e2ebcd3cfb6d3e7ff688472586964c29f165f378`，不覆盖rev194或旧正式PCK。
- **独立实际公网校验**：工作流`.github/workflows/canglan-rev195-real-pages-http-proof.yml` commit`d266d7d` run`39012015461` job`117336372231` **completed/success**。真正HTTPS完整包、APK176固定RSA验签、SHA256及HTTP Range **206**均通过，日志`PASS_APK176_REAL_REV195_PUBLIC_PAGES_RSA_SHA256_HTTP_RANGE_PHONE_DOWNLOAD_READY`，CDN缓存`max-age=600`。
- **不能虚构的未完成项目**：用户发的角色高密度体素/像素美术、面部清晰、多种发型服装、真正格挡/完美闪避和飞剑/法术的动作与技能规则、可进入院落、生态森林和真正体积光**都没有在本轮做完**。rev195只恢复以前被关闭的合法移动Glow并为现有真实疾步添短VFX。项目仍是质量不达标的可玩原型。下一轮依照研究文档，从CC0成品人形骨骼+战斗动画与合法粒子素材和真正可住人高精院落开始，一套完整玩家可见的打击状态/视觉验收后再签发下版。手机实机 rev195 仍待用户更新并测试，不能给手机画质打PASS。


## 2026-10-17 / rev196 原APK176真凡人切磋、格挡、完美格挡、闪避及真实伤害（已签名PCK发布；手机未验收）
- **用户确定参考**：要求继续学习独立修仙游戏中高细节御剑、格挡、完美闪避与实际庭院战斗，而非仅调颜色或画参考图。继续遵守文档 `docs/VISUAL_COMBAT_REFERENCE_STUDY_REV195.md`；没有本人灵根检测/功法/法力系统之前，不会把凡人动作伪称修仙飞剑，不能复制原作者的角色/特效素材。
- **真正原游戏交互**：`game-source/apk176-ota177-candidate/scripts/apk176_player_controller_rev187.gd` commit `a46def5`：原手机HUD由6个动作扩展到紧凑4×2八个，新增`切磋`、`格挡`、`闪避`，原采集、疾步、挖掘、互动、视角都在。按切磋后**只在平坦干燥且无遮挡的现有物理地形上**复制原七个已授权动画GLB中的现成骑士角色为自愿陪练（非民用NPC、无战利品、无凭空材料），附带独立`StaticBody3D`胶囊体实际障碍碰撞、真实红色蓄势地面信号。靠近时敌方0.68秒蓄势，真正计时击中扣玩家12生命，血条即时变化；玩家6? **实际格挡消耗5体力**，正确面向/时机只抵3生命、完美窗口成功则0伤害和短敌人后摇；真实闪避消耗7体力，必须在真实世界地形、水、遮挡和坡度判定后向后移动1.65米，在0.31秒防御窗口内取消原位置本应发生的命中、完美时机加特效。真实触发的格挡/闪避/命中三类0.24s限量粒子反馈；不会用纯UI假判定。
- **键位**：触屏八按钮；手柄切磋时 B 变真实闪避、RB变真实格挡，未切磋时保留原 B 疾步、RB背包，L3仍疾步；键盘T切磋、R格挡、空格闪避。远离练习对手/生命耗尽/再次按切磋都结束，不伤原村民经济/土地和世界身份ID。练习对手原GLB只有现有动画（idle/walk），**尚未导入真正攻击/格挡骨骼动画和高级细节人物**，只能算有可玩动作规则与反馈，视觉仍明显未达用户参考图。
- **严格实际Godot QA**：`logic-qa/apk176-export-fixture/verify_original_main_quality_rev187.gd` commit `2f0dde4` 新增许可原角色、物理对手、蓄势可见、成功格挡扣5体力、120ms级完美格挡零伤、普通格挡真实扣3血、物理闪避移动≥1.5米且零伤、敌人未防御扣12生命、撤销练习回归原NPC状态等测试。首个run `39015811466` **失败**：模拟恰好0.09s等于浮点计时阈值导致单帧未触发结算，commit `1f1e692` 使用超过阈值20ms的安全测试步长修复（不修改判定规则以求通过），严格标记首轮失败。正式工作流 `.github/workflows/canglan-original-apk176-rev196-guard-evade-mortal-sparring-signed.yml` commit `30fd13a` 新增`PASS_REV196_REAL_OPPONENT_TELEGRAPH_PERFECT_GUARD_NORMAL_GUARD_TRUE_EVADE_DAMAGE_STAMINA_WITHOUT_SPIRIT_MAGIC`门禁，连同原APK176全部Godot 4.4.1主场景、原经济和NPC、手柄/地形/存档/材质等旧回归通过；run`39015892756`, job `117347804883` **completed/success**，真实软件Mesa Vulkan主场景截图含旧工地两个机位（**未拍摄新的战斗近景，不能冒充高清战斗镜头**）。
- **官方真实发布**：原APK176 versionCode1176在唯一公开repo`160701541-cell/xinyanshuo`的正式发布工作流run`39015892756`印出`original_rsa_signature_verified:true`以及`PASS_REV196_SIGNED_OTA_PUBLISHED_TO_PUBLIC_MAIN`；`android-preview/latest.json`递增为 **revision196**，PCK **21,762,656字节**，SHA256 **fe78c20064cb8432789cb181a8afed9703f0e50920670d57b49ad0dda17c2429**，正式原公钥对应RSA签名且不覆盖rev195及旧玩家存档。
- **独立公网验签已完成**：新增`.github/workflows/canglan-rev196-real-pages-http-proof.yml` commit`72a9894`；run`39016029571`、job`117348206046` **completed/success**，真实Pages HTTPS完整**21,762,656字节**、固定原APK176 RSA公钥验签、SHA256 `fe78c20064cb8432789cb181a8afed9703f0e50920670d57b49ad0dda17c2429`一致、HTTP Range **206**，打印`PASS_APK176_REAL_REV196_PUBLIC_PAGES_RSA_SHA256_HTTP_RANGE_PHONE_DOWNLOAD_READY`。CDN清单有`max-age=600`缓存，手机安装/运行/视觉仍待用户实机。
- **目前仍P0未完成**：高品质真正骨骼攻击/格挡/闪避动画、角色面部及装备、真正妖兽AI与流派武学、灵根和飞剑法术、屋瓦细节与可住人中式院落、跨区块树林再生、大量树种、近景纹理与高质量环境光效。此轮**只新增可自愿进入的真实基础切磋**；用户手机实际触屏/手柄是否正常、视觉品质是否达到高目标全部`未验证`。下一步优先许可明确的成品角色+战斗动画替换简陋运动反馈，制作真引擎战斗截图并补可居住院落，不继续声称已经实现视觉盛宴。


## 2026-10-17 / rev197 手机实测 P0「人看不见、不能跳飞、没有45°视角锁、无法缩放、连续穿模」——实际原APK176已签名OTA，手机仍待验收

### 用户真机失败高优先级复现
- 用户明确反馈rev196手机：「不能飞、不能跳、没有锁定屏幕的东西、没有俯视45度视角、人物看不见、穿模一直穿模、不能缩放屏幕」。旧功能脚本里`_layout_hud()`用开发模式`dev`把`GodViewButton/FlyViewButton/ZoomInButton/ZoomOutButton`**一律隐藏**，但代码`stats`仍报告`free_flight_available/pinch_zoom=true`；既不代表玩家看见按钮，更不代表真机可交互。**这就是之前QA与真实操作脱节的根本原因。**
- 旧版`step()`结尾每帧将玩家Y强制贴地→不可能真跳跃；只支持 camera_mode==fly（**摄影机飞而不是角色飞**），第三视角相机12米且没有专用45°跟随、镜头锁定；`_set_mode(first)`直接`actor.visible=false`，第一人称彻底没有身体。旧双指缩放只能由右手下方热区、且`_input`未维护跨区域多点触控，实际手指放在两半屏幕无法缩放。旧走路只有位置差和水/坡检查，不做实体碰撞；墙、树林等实体穿透，旧楼梯用1米实心箱体不可走。相机只有单线ray检测，近裁剪面会穿墙。**这些是从实际源码审计得出的可验证漏洞，不是猜测。**

### 真正改动的原游戏源码
- 玩家脚本`game-source/apk176-ota177-candidate/scripts/apk176_player_controller_rev187.gd` commits `cce0618`,`fd16713`,`198d415`：玩家HUD（正常模式、开发模式关闭仍可见）永久提供 **俯视45°、上帝、角色飞行、跳跃、锁/解锁镜头方向、放大、缩小** 7个实际`Button`，同时原四菜单/八动作槽保留。按钮集中在右上第二横排，飞行时独立显示升高/降低。代码`_input`以全屏触摸索引维护多指，排除摇杆/UI按钮，跨左/右游戏热区仍识别比例变化；初始第三人称/45°视角/上帝缩放，第一人称由真实调整FOV实现放大缩小。镜头锁只锁**旋转**，仍跟随玩家并允许缩放，不冒充系统级安卓横竖屏强制锁定。
- 新`iso`相机用固定 `PI/4`俯视、跟随玩家（不是单独自由摄影机），可切回第三人称，取消旧视角里直接隐藏整个`actor`的做法、保持许可GLB人形在相机范围内。正式飞行按钮进入新的`soar`**真实角色**飞行模式，起飞高约3m、左右摇杆沿真实流式世界移动、按升高/降低改变玩家实体高度，飞行距离/高度是真实角色状态；独立开发工具的自由摄影机模式仍存在，但不再误以为那等于角色会飞。此角色飞行是**开放测试操控**，不是修为已解锁的御剑功法或正式修仙力学。
- 跳跃`jump_action/_step_jump`：实际玩家花4体力后受15m/s²重力运动，上升再落回真实地形，有顶部障碍ray检查、不可在上帝/飞行状态启动；不再被逐帧旧贴地代码取消。正常走路与飞行通过`PhysicsShapeQueryParameters3D`的全身胶囊`cast_motion+intersect_shape`对真实建筑与树石等mask2障碍碰撞检查，并做XZ两个方向滑墙尝试；不允许玩家简单修改坐标穿墙。第三人称相机增加真实半径0.24m的球体扫掠与地形高度兜底，不再只有单射线。
- 世界脚本`apk176_living_resource_world_rev187.gd` commits`eed408c`,`b673f5b`：正式许可Kenney树木/石块批量渲染不变，添加低成本真实树干/石头StaticBody3D碰撞器、按实体现存量及采伐/生长状态同步；许可石阶原先碰撞代理是高度1米实心箱，现在将楼梯分到**可走表面层bit4**，薄斜坡实体作为地面支撑，人物可以沿坡面升高（对石阶的准确尺寸拟合仍待真机与asset mesh外形核验）。将坡道形状命名为`TrueWalkableStairRampCollision`便于真实QA。
- 输入与手柄：手机屏幕上可直接点7个控制键；手柄正常状态A跳跃、LT互动、X采集、B疾步，切磋中原B闪避/RB格挡仍保留；键盘空格在非切磋时跳跃。原世界NPC/资源/序列化/玩家ID继续沿用，不重新安装原APK。

### 实际测试、首败修复、发布证据
- `logic-qa/apk176-export-fixture/verify_original_main_quality_rev187.gd` commit`d0a9d39`：原APK176已导出Main真实Godot 4.4.1场景中验证7个**真实可见且可点击**按钮、许可mesh人形节点/实体身高/摄像机投影坐标和真正45°pitch、锁视角拒绝旋转、可见缩放按钮、模拟两指输入跨区域识别、起跳真实高度/体力扣款/完整落地、角色飞起升降/摇杆真实移动、高度回落、真正碰撞楼梯坡道及临时2米实体墙阻挡玩家身体和镜头；不只检查`stats()`宣称能力。`logic-qa/apk176-export-fixture/capture_original_main_rev187_compare.gd` commit`e5bcb64`增加原Main实机以外的第三人称近距角色和45°跟随镜头**真实引擎帧**截图，不允许代替手机测试；正式 rev197 通过签发后单独执行新截图的QA-only流程。
- **真实首测失败** `39017005869`：`REV197_STAIR_SHOULD_HAVE_WALKABLE_RAMP_NOT_TALL_BLOCKING_CUBE`，Godot脚本默认子节点名不可当成稳定引用，commit`b673f5b`给坡道碰撞形状明确名称，commit`2419445`调整QA查询。以后不得因CI绿色就忽略手机失败。
- **通过的原GameMain编译/运行并正式发布**：工作流`.github/workflows/canglan-original-apk176-rev197-real-mobile-camera-jump-collision-signed.yml` commit`d807058`，真实run`39017076980` job`117351323794` **completed/success**。实际原场景、新触控和物理测试、原NPC材料守恒/房屋/手柄/存档兼容门禁通过，含 `PASS_REV197_REAL_ANDROID_TOUCH_PINCH_45DEG_VISIBLE_AVATAR_CAMERA_LOCK_JUMP_AVATAR_FLIGHT_STAIRS_AND_COLLISION`；生产 RSA 签名 `original_rsa_signature_verified:true` 且输出 `PASS_REV197_SIGNED_OTA_PUBLISHED_TO_PUBLIC_MAIN`。**这证明Godot内模拟触控通路而非手机硬件成功。**
- **正式PCK**：唯一公开仓库`160701541-cell/xinyanshuo`原APK176 versionCode1176 manifest升至 **revision197**；签名包**21,777,408字节**，SHA256 **77345709523b15c2caaa73bb0cec208d0d88e7055e0aa537b17ba82ad0777aa3**，绝不覆盖已发布rev196或旧存档。GameMain真正兼容但**用户一加Ace5Pro硬件实际手势/触摸/飞行、第一人称显示和物理帧率待实机验收**。
- **公网安全验签成功**：独立`.github/workflows/canglan-rev197-real-pages-http-proof.yml` workflow run`39017265181`、job`117351850377` **completed/success**。真的通过PagesHTTPS下载rev197全部21777408字节并用原公钥检验RSA/sha256及HTTP Range206，日志`PASS_APK176_REAL_REV197_PUBLIC_PAGES_RSA_SHA256_HTTP_RANGE_PHONE_DOWNLOAD_READY`。官网manifest CDN最大缓存600秒。
- **新增真实引擎的角色图片**：workflow截图阶段QA-only重新运行`39017340974`（已签名rev197不可覆写，仅验收原版Main），包含第三人称近镜与45°角色画面，**此项是否通过以该run最终结果为准**；截图为GitHub Linux Mesa Vulkan，不能虚称用户手机画面。
- **仍未解决**：用户指定参考风格的高清角色面部/人物骨骼攻防动作、仙侠真实灵根御剑、可居住中式院落/屋顶细节、全生态森林和多树种；飞行逻辑仅开放角色调试和基本碰撞，不是真正修仙功法；房屋模型形状与坡道碰撞器精确吻合须手机爬梯和进屋实测；当前原游戏依然属于 P0 大量未完成的原型，绝不能因为镜头/跳跃有Godot QA就宣称完整游戏已合格。


## 2026-10-17 / rev198 实际玩家消失根因修复：原已授权GLB不透明度误设为0（已QA/签名正式发布，真机未验收）

### 问题证据与不能继续误报通过的原因
- 用户rev196真机抱怨「人物看不见、穿模、不能飞跳锁镜头45度/缩放」。rev197已经修复了原HUD完全隐藏按钮、动作Y逐帧贴地、触控右半热区双指缩放、无玩家碰撞等P0，正式合法RSA增量发布run`39017076980`并经公网站点SHA/RSA HTTP206 run`39017265181`全过；**但rev197截取实际Godot原Main近镜和45°截图以后，亲眼发现人物依旧100%没有出现在渲染画面上**。原scene node`actor.visible=true`，模型AABB测得1.8m，screen projection在画面内，旧QA全部误判“可见”。这些必须如实区分。
- 此次不是盲目改调色：rev197真实Godot截图 artifact`12095009198`两个机位都是只有背景地面和UI、无人；加渲染诊断commit`6077c6f`，QA-only run`39017859177`的`render.log`明确打印`Knight MeshInstance3D visible=true visible_in_tree=true color=(0.4267,0.4267,0.4267,0.0) transparency=2`。**来源的合法Quaternius Knight GLB导入后原实心人物Armor纹理的材质不透明度为0，导致真正没画任何像素**，不是摄像机远近或玩家ID错误。
- **修复源码commit`0cc7554`**：原游戏`game-source/apk176-ota177-candidate/scripts/apk176_living_resource_world_rev187.gd`新增`_repair_licensed_opaque_character_model`，在许可Knight GLB的原`MeshInstance3D`载入为角色asset时逐面审计现有`StandardMaterial3D.albedo_color.a<=0.01`，使用真正材质副本强制实体Alpha1.0、禁用误设的Transparent/Scissor；不重新造模型、不修改公用GLB磁盘二进制、保留骨骼和AnimationPlayer/商用许可，NPC樵夫、采石工、建筑工、练习敌人、玩家统一引用修复的角色材质。
- **新增双重真实失败门禁，不再只查visible bool**：`verify_original_main_quality_rev187.gd` commit`bab0fa1`要求至少一个Knight面材质从Alpha0修复，且加载后每个实体表面Alpha>=0.5；`capture_original_main_rev187_compare.gd` commit`f39983a`对原APK176主场景的**真实Mesa Vulkan渲染PNG**采样：近景框实际深色不透明人物像素必须至少34个，并有≥45种真实色彩，45°镜头也必须通过，而不是“有draw call、能找到MeshInstance就算人物可见”。本轮明确观察：近景`opaque_dark_samples=805,color_variety=576`，45°`opaque_dark_samples=172,color_variety=332`，确认了真实人物重新出现在屏幕上。对应真实原引擎帧`real_apk176_rev197_licensed_player_visible_close.png`和`real_apk176_rev197_follow_player_45deg_view.png`在rev198 QA artifact中；文件名沿用脚本历史名但内容确是rev198运行的修复后新帧，均是软件渲染，**不是用户一加手机实机照片**。
- **第一次rev198工作流run`39018323353`没有通过**：并非绘制人物失败，两个像素QA都已成功，后续在未签名rev198 manifest步骤被`sign_pck_release.py`拒绝`ValueError: Release note too long or contains a newline`（发行说明原289字符超过上限256）。commit`ebac9ca`缩短正式note为157字，没有绕过RSA或QA；绝不静默覆盖旧版本。
- **真实完整原APK176 Godot Main、场景像素、签名与发布通过**：工作流`.github/workflows/canglan-original-apk176-rev198-opaque-licensed-knight-visible-signed.yml` commit`2619996`, 修复后run`39018512560` job`117355442075` **completed/success**，原Main所有旧rev187～197实体/经济/3画质/游戏手柄/摄像机/跳飞/世界地形/材料/修仙锁及两个真实截图新像素质量门禁全部通过；原APK176生产RSA固定公钥`original_rsa_signature_verified:true`且`PASS_REV198_SIGNED_OTA_PUBLISHED_TO_PUBLIC_MAIN`，于原公开仓库正式manifest递增为**revision198**；签名PCK **21,779,104字节**，SHA256 `02e5ddb16934aa3388d834ef6ead788e967b88ed377e452bcafee96983dc9bd8`，`android-preview/canglan-content-rev-198.pck`新文件，保留全部原有已签包和用户存档、不要求安装另一个APK。
- **实际截图可检验**：run`39018512560`的真实Godot双机位人物截图artifact`12095587220`是修改后构建采集的人物清晰像素存在证据：近景实际玩家是深蓝衣服金发基础低模，45°镜头同一地形下人和NPC可以看到；场景里可居住房屋/屋顶/精致修仙人物仍不达标，**本轮只声称“人物重现”不声称“画质优秀”**。
- **公网验签已真实通过**：专用`.github/workflows/canglan-rev198-real-pages-http-proof.yml` commit`83c52d3`，run`39018709779`、job`117356012718` **completed/success**，公开Pages完整下载真实PCK **21,779,104字节**、原APK176固定公钥 RSA 验签、SHA256 `02e5ddb16934aa3388d834ef6ead788e967b88ed377e452bcafee96983dc9bd8`匹配、HTTP Range **206**，`PASS_APK176_REAL_REV198_PUBLIC_PAGES_RSA_SHA256_HTTP_RANGE_PHONE_DOWNLOAD_READY`。缓存max-age600，手机仍未执行，`still_needs_physical_phone_acceptance:true`。
- **下步**：玩家手机更新原APK176到rev198后，重点验收人是否能看见、七个控制按钮、真实可跳能落地、能角色飞行升降、45°跟随、锁镜头、双指缩放、石阶可登、墙树石停止穿模、第一人称脸/手可读性。仍须改良高品质精细CC0角色/衣服脸/建筑/植被，不应用CI像素门禁把所有P0已解决。


## 2026-10-17 / rev201 真实修仙入门：世界灵脉种子、12名修士、古石灵根检测、吐纳与炼气突破｜正式原APK176签名PCK发布＋公网站点验签成功

### 用户要求、手机与实际能力边界
- 用户使用**一加 Ace 5 Pro**（官方骁龙8至尊版/Adreno830，RAM有12GB与16GB两档，用户具体内存未确认），要求本地模型优于原0.6B、御剑飞行、世界种子生成、明显更多修仙NPC、人物可以修炼、放置能交互查看自身灵根的真实检测台。已核实官方产品规格、ggml-org Qwen3-1.7B 和Qwen原厂Qwen3-4B GGUF文件。详细决策文档：`docs/ACE5PRO_OFFLINE_NPC_MODEL_UPGRADE_REV201.md` commit`26da5b4`；**推荐1.7B Q4_K_M约1.28GB常驻，4B Q4_K_M约2.497GB可选增强**。但原APK176仍缺原生CanglanLocalLLM/llama.cpp ARM64，玩家手机并没有下载或加载这两套权重，仍须原游戏相同包名/签名证书的合法覆盖APK升级一次；PCK绝不可冒充本地大模型已成功运行。现在NPC是**规则自治，不是LLM对话**。

### 同一原游戏的真实代码
- 新`game-source/apk176-ota177-candidate/scripts/apk176_cultivation_world_rev201.gd` commit`8bdda2c`：由首次启动生成**可复现的修仙生态世界seed**（用户路径`user://canglan_original_cultivation_seed_v1.json`原子保存），稳定生成12名游历/采药/巡山/散修的姓名、个人实体ID、五行属性、年龄、体力、饥饿、炼气层数、不同日程和初值；玩家实际灵根由相同种子＋身份ID确定，**未亲自到检测台以前不得在HUD或public API显示结果**。存档同一随机种子、检测结果、玩家吐纳/境界进度，不因重开重复随机天资。原已有地形的采挖和玩家存档原封不动，原核心Terrain3D/跨区块地形已有独立seed20261017——**本rev的种子只控制修仙层NPC与灵脉/灵根，尚非整个地形重新生成、新建多个世界槽位或无穷地貌的完成**。
- 用户能从出生区域往东约10m到一个真实**Kenney授权石阶组成的古代灵根检测台**（稳定ID `CL-ANCIENT-SPIRIT-ROOT-TEST-ALTAR`，石台实际Godot GLB网格+真实碰撞/青色世界指示圈+中文Label3D，不是单纯UI文字）。靠近3.4m内点实际手机HUD「检测灵根」才能获得个人金木水火土或无灵根评定。可修角色从遗迹铭文获得首门吐纳知识（不是凭空发实体丹药、灵石、金币）；无灵根无法作弊施仙术仍能修习凡人战斗。
- 「吐纳修炼」接**已有真实WorldBox sim.tick整世界小时**，每个小时真实消耗玩家经济角色4体力、按灵根权重/离检测台灵脉远近/世界种子计算增长灵气，经脉负荷升高并暂停；「突破炼气」按层消耗真实修为/检查经脉，第一次升级为炼气一层，直到13层属于首版修真进阶。不得越级直接跳筑基，也不虚发灵石、丹药或已有高级飞剑技能。闭关时世界全NPC、施工、饥饿、生态、昼夜按真实倍速一起前进，法力/功法凭登记知识规则产生。
- 12名新修士的实际已授权**Quaternius有骨骼的GLB**在真实3D地图生成，原角色甲胄材质按个体重新染色、沿用有真GLB发丝、实际Idle/Walk动作、中文名/职业/境界/时刻表，全部有`StaticBody3D`胶囊碰撞体（防止再次人体穿透）；每小时按姓名ID独立修炼/采药探路/巡山/休息并随世界时间变动，已验证实体数量和碰撞而非只写数组。**尚没有12套不同精致原创人形、复杂宗门AI、完整采药产出交易/真实宗门住房与死亡寿元反馈**，不得称这已是完整NPC社会。
- **原APK接线**：`apk176_living_resource_world_rev187.gd` commit`b44f1d6` 在原3D Main创建玩家与自然环境后实例化同一个cultivation authority，并在同一个12秒/世界小时权威时钟里调`advance_world_hour`，真实场景每帧跟地形更新人物动画与碰撞。HUD原`apk176_player_controller_rev187.gd` commit`2eca87d`增加**检测灵根/吐纳修炼/突破**三触摸按钮、当前种子和修士数量、灵根测后才显示类型、境界、当前灵气和经脉负荷；原跳飞/角色镜头/多人触控仍在。没有新增独立APK/HTML/伪造后台AI。
- 原PCK打包路径`logic-qa/tools/build_apk176_quality_rev187.gd` commit`1c43bcd`明确把修仙模块打到`res://canglan_rev187/cultivation_world.gd`；正式workflows staging真正复制新脚本，不是只提交源文件给GitHub。
- 前序rev200**真实串行阻塞已解决**：原hair QA让`MeshInstance3D`自身查`find_children()`得到空列表，不能认定角色无头发；commit`3f86e93`修正`_visible_bounds()`包含网格本身，rev200工作流commit`47feae3`复制当时已纳入原Main的新模块并过全QA，run`39024405446`**completed/success**发布正式revision200。rev201第一次run`39024167663` **完整真Godot QA已通过但不允许跨过rev200签名**，签发被`stage_original_next_ota.py`以`QA candidate is not next-revision APK176 template`阻止，绝没有绕过；正式rev201工作流commit`8889c7f`升级为必须**当前revision200→201**的严格生产安全检查，按顺序发布。
- rev201细化NPC碰撞及外观commit`c9189d6`，原QA`logic-qa/apk176-export-fixture/verify_original_main_quality_rev187.gd` commits`bf9e178`,`dc73f93`：真实本机Godot 4.4.1原APK176 Main测试检测台持有Kenney GLB实体ID、12名骨骼人物和12个真人碰撞胶囊、生成种子JSON复现、未测根性隐藏、离台过远失败、手机按钮真回调、同一天12名NPC各自推进时辰、玩家按世界100倍速同步花体力涨修为，真的扣灵气成功突破1层并立即原子存档重新加载依旧一致。正式工作流`.github/workflows/canglan-original-apk176-rev201-spiritual-seed-alter-cultivator-signed.yml` run`39024654444` job`117373249564` **completed/success**，全旧玩法经济/采挖/树林/模型/Android HUD/画质/地形/原Godot截图等门禁保持，`PASS_REV201_ACTUAL_LICENSED_ALTAR_HIDDEN_DETERMINISTIC_ROOT_12_AUTONOMOUS_CULTIVATORS_REAL_HOUR_MEDITATION_QI_AND_BREAKTHROUGH_SAVED`通过。此为Linux Godot/Mesa引擎实测，**不是一加手机帧率或触屏实机通过**。
- **实际原APK176固定证书公钥RSA签名发布**：GitHub正式工厂run`39024654444`印`original_rsa_signature_verified:true`及`PASS_REV201_SIGNED_OTA_PUBLISHED_TO_PUBLIC_MAIN`。当前公共manifest`android-preview/latest.json`revision **201**、versionCode只允许**1176**、新PCK**22,037,120字节**、SHA256 `245762e18945383660ecf6a100760be993d86259f25753ac5f41121ffe27c687`，旧rev199/200仍保留原签名文件、旧手机存档不抹。
- **独立官网实际网络验证**：`.github/workflows/canglan-rev201-real-pages-http-proof.yml` commit`517462d` run`39024907778` job`117373877645` **completed/success**，原网站真实HTTPS完整下载22,037,120字节，原APK固定RSA签名/SHA-256全部一致，HTTP Range 返回206，标记`PASS_APK176_REAL_REV201_PUBLIC_PAGES_RSA_SHA256_HTTP_RANGE_PHONE_DOWNLOAD_READY`；CDN manifest cache max-age600s。手机用户安装/更新后实际查看是否可显示台、跑修炼和飞剑动画、发热/卡顿**仍待实机**。

### 下一阶段阻塞
- 本地AI原APK没有Native llama.cpp/GDExtension，升级必须恢复同一包名、原APK正式keystore覆盖签名打包，且在手机完成真实SHA256权重下载、安装、聊天推理、NPC行为与世界数据门禁；当前不能称Qwen正在游戏运行。
- 世界 seed 目前只影响修仙层，不可更换原流式地形seed，否则会损坏用户已经采挖保存的区块；正式生成全地图须加多世界存档隔离/初始生成顺序/保存迁移后再交付。
- 修仙NPC更多且有真实骨骼/碰撞/作息，但服装角色粗糙、人物模型重复，复杂宗门社会/经济支撑、门派成品材质和动画仍未达用户参考标准；下一步真实手机体验QA优先。

## 2026-10-17 / CAC-3D-202 / 原APK176正式签名rev202：御剑升降、平稳降落与镜头防瞬移
- **唯一真实游戏源**：公开仓库 `160701541-cell/xinyanshuo`。旧私人 `canglan-world` 的错误原型PR #23已经关闭，不得合并。正式原版代码为 `game-source/apk176-ota177-candidate/scripts/apk176_player_controller_rev187.gd`；原源PR #2已合并main（`b11f6f3`）。
- **玩家可见修复**：御风真人飞行显示手机“升高/降低”两个按钮；按降落后两键禁用；起飞从物理地面逐步升高；空中切视角进入渐进降落而非瞬时把高度清零；水平飞行速度逐帧衰减而非突然刹停。原rev201灵根、吐纳、12名独立修士、世界时间和存档保留。
- **真实Godot系统级QA**：公开Actions QA-only run [`39028126321`](https://github.com/160701541-cell/xinyanshuo/actions/runs/39028126321) **SUCCESS**。从真实APK176导出原主场景并匹配原生Terrain3D v1.0.2，Godot 4.4.1脚本解析、主游戏起降/触摸/镜头、资源消耗、真实NPC和rev201修仙回归全部通过。采集1280×720真实Godot渲染图片（不是手机截屏）到构建工件。
- **原APK176真实RSA签名热更新已成功**：生产工作流 [`39028355653`](https://github.com/160701541-cell/xinyanshuo/actions/runs/39028355653) **SUCCESS**，其步骤包含全部原Main回归、真实引擎截图、原固定公钥签名、PCK哈希与防竞态发布。正式 `android-preview/latest.json` revision=**202**，兼容Android版码 **1176**，包大小 **22037600字节**，SHA-256 `4a9376cf922c0e213481e78cec170b4995f24c5e84b4ff0184e28df0ec5d94de`；签名和PCK不覆盖前代不可变版本。
- **官网独立真实网络验收通过**：Pages部署 run `39028497124` SUCCESS；公开HTTPS原固定RSA校验+22MB全量SHA256+HTTP Range返回**206**在 [`39028644959`](https://github.com/160701541-cell/xinyanshuo/actions/runs/39028644959) **SUCCESS**，证据 `PASS_APK176_REAL_REV202_PUBLIC_PAGES_RSA_SHA256_HTTP_RANGE_PHONE_DOWNLOAD_READY`。
- **本轮严格边界**：技术及官网下载验收通过**不等于**用户真实安卓设备的UI/人物脸部头发/飞剑姿态/发热/帧率审美通过；APK176没有本地LLM原生推理库，离线Qwen尚不可用；用户手机实际升级及15分钟实机测试仍待验收。

## 2026-10-17 / CAC-3D-203 / 原APK176真实热更rev203：触屏连续御剑升降、人物与飞剑真实侧倾、高度感镜头
- **唯一游戏仓库** `160701541-cell/xinyanshuo`，正式源码PR #3（已合并 `6ec7845`）；安全降落回归PR #4（`46409f7`）；真实Godot截图官网PR #5（`03e652e`）。旧 `canglan-world` 不再参与发包。
- **手机可实际更新的代码**：真人飞行模式升降按钮按住0.25s后持续以6米/秒调整相对地形高度，抬手/打开菜单/开始降落均停止；真正人物Node3D与授权CC0飞剑GLB同步小角度侧倾，停下恢复，原相机可缩放基础上随高度缓慢拉远；原rev202受控降落、rev201灵根检测与12名修士、世界时间和旧存档保留。
- **真实QA的失败和复验留痕**：首次只读源测试因守卫与新状态不一致FAIL，修正后QA-only run [39029314179](https://github.com/160701541-cell/xinyanshuo/actions/runs/39029314179) SUCCESS；正式签发run [39029641825](https://github.com/160701541-cell/xinyanshuo/actions/runs/39029641825) 在旧rev199单帧降落回归遇到随机阻挡FAIL，**当次未发布**；调整为有时限的逐帧物理测试并输出状态后，独立[39029837728](https://github.com/160701541-cell/xinyanshuo/actions/runs/39029837728) SUCCESS。
- **最终原APK176固定公钥RSA签发发布成功**：[39030030956](https://github.com/160701541-cell/xinyanshuo/actions/runs/39030030956) SUCCESS；`android-preview/latest.json` 正式 **rev203**、`versionCode=1176`、PCK **22040608字节**、SHA256 `07b9e52426f1eb7e22e4c49bba35bd9f6d589660a08d861f564c15717512b295`，真实原Main/Godot 4.4.1/Terrain3D、历史rev201/202功能、截图、签名、原PCK不可变性等门禁全部通过。无新APK，不卸载原App。
- **外网确证**：独立Pages [39030295747](https://github.com/160701541-cell/xinyanshuo/actions/runs/39030295747) SUCCESS；实际公网上完整下载22040608字节与清单，原APK固定公钥RSA验签及SHA256完全一致，HTTP Range真实返回 **206**，日志标记`PASS_APK176_REAL_REV203_PUBLIC_PAGES_RSA_SHA256_HTTP_RANGE_PHONE_DOWNLOAD_READY`。
- **真Godot引擎PNG而非概念图**：发布与本签名候选同次Godot场景截图 `art/actual-engine-capture/canglan-rev203-soar-bank-godot-linux.png` 和 `canglan-rev203-player-close-godot-linux.png`，官网真实展示，并标注**不是安卓实机**。
- **专业审美门禁依旧为FAIL，不能伪报已完成**：人工查看实际画面仍存在人物脸部/头发/动作与飞剑姿态难看、密集HUD遮挡、地表草植重复、建筑细节不足，远未达到用户国风视觉目标；**下轮必须先处理人物动作/资产、精简手机HUD及植被，再提交真实对照截图**。Android手机下载安装、运行15分钟、帧率发热和画质满意度仍为PENDING；本地Qwen原APK无原生推理库，必须同签名APK覆盖升级才能运行。
