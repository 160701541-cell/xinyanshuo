# WorldBox·万界仙侠 / Work文件库交接（2026-10-21）

**这份文档为公开源码交接指针，不含商业APK。**

### 持久化文件库真实路径
`/WorldBox-万界仙侠/Work交接/`

该私有文件库目录的以下文件已实际上传成功，并通过重新列目录确认，Work应使用ChatGPT文件库查找/提取原始字节；`/mnt/data`是当前普通聊天的临时容器路径，不能直接假定Work云电脑拥有。

- `WorldBox_WanjieXianxia_v0.28_Private_Android16_DEVICE_PENDING.apk`：189,287,005字节；SHA256 `9efa49f98e92921f7ee8b9341f14b68b39d426323bc0a8cf25d8acc41e6cc822`。
- `WorldBox_Xianxia_v18_Cultivation_Test.apk`：187,773,264字节；SHA256 `b415bf01ccb17c4503cdb51f544127caa8afe28de99ade6d8580b57463b937c5`；重建基线。
- `WorldBox_万界仙侠_v0.27_传统Mono源码MOD_待实机.zip`：v0.28所嵌入原始MOD。
- `WorldBox_万界仙侠_v0.27_安卓NML预编译MOD_待实机.zip`：其他加载器路线备选。
- `private_stage_mono_v28.py`、`test_v28_private_stage.py`：本轮本地曾执行的打包器与单元测试。
- `WorldBox_v028_APK私有整合静态验收报告.json`：离线证据。
- `WorldBox_Work_交接_2026-10-21.md`：私有文件目录内完整Work交接说明。

### Work开工
1. 先读本分支`DEVELOPMENT_LOG_V22.md`、`WORK_HANDOFF_APK_V13.md`与这个目录；从文件库真正提取APK，核验SHA256。若Work当前会话未授权访问文件库，应让用户在Work聊天中明确附加此文件，而不能根据文件名凭空模拟。
2. 用真实用户手机日志确认v18/v0.28有没有启动Unity与NML动态加载。过去`MOD_DEPLOY_OK`仅说明文件部署，不证明MOD加载。验证简中菜单及存档，修复引导链后才扩展玩法。
3. 所有源码修改继续在专用WorldBox分支，不碰`main`/苍岚正式发布。每次更新开发日志。**Work不可将完整商业WorldBox APK、他人MOD或签名私钥上传公开GitHub**。

### 设备状态
v0.28 APK实际签名完毕，未有Android16安装/可玩证据：`SIGNED_PRIVATE_APK_DEVICE_PENDING`。

### 后续实测纠正与日志入口修复
用户实际Android16 PKR110日志已证明v0.28进入Unity；CombatGods和Frontiers已加载，观察模块V07报告FAILED；检测灵根按钮有一次ACTION记录。特性编辑器groupsBuilder两次空键异常。不能继续写“完全没有安装/运行证据”，也不能称完整修仙系统通过。

2026-10-21用户明确反馈手机复制不完长日志。入口修复在当前WorldBox分支的：
- private-apk-lab/DiagnosticsActivity.java
- private-apk-lab/DiagnosticReport.java
- private-apk-lab/ModDeployment.java（接续原实现）
复制≤6000字符关键摘要；导出分享ZIP包含四份现存日志原字节及摘要。使用系统文件保存器和content URI附件，不再发送180000字符EXTRA_TEXT。
CI私人打包工具工件增加原创WorldBoxDiagnostics_classes5.dex及SHA256；必须等对应CI成功再取用。只含自有Java入口/部署器，无商业游戏字节。

Work需检查原classes5.dex仅包含对应自有入口与部署器后替换/重建；若其中有其他必要类必须保留后合并，不能盲目覆盖。原生DEX更新与MOD源码升级是两步；private_stage_mono_v28.py --replace-own-module只更新MOD源码，不更新DEX。完成后zipalign、使用既有正确测试证书签名，并测试保存取消、ZIP导出、附件分享、复制摘要和启动游戏。不可仅更新MOD就宣称日志按钮已修复。用户无需再复制超长日志、无需MT手动操作。

### 用户截图UI/中文名称修复（f96dc29，CI 39465488094 success）
NativeBridgeSources工件现在包含原生桥、修仙面板、原规则、DiagnosticLog、IntegratedModBootstrap及SharedPanelsV30/PixelFrameV30/ChineseWorldNamesV30完整源图。旧DLL需要精确用户Mono引用重编、保留原有入口挂载并更新Managed.zip/部署缓存；NML源码候选也要同步更新。仅拷贝新MOD不能移除旧桥重复入口。

目标：一个“万界”入口，修行/观察/字体窗口互斥，不透明灰绿像素边框；英文实体名在真实setName接口支持且原名成功持久化备份时分人物/城池/王朝改中文，已有中文名保留。
自动命名和单窗行为模拟测试已通过，实际用户0.51.4 get/setName与BaseSystemData字符串get/set、kingdoms/cities集合、原生桥编译和手机观感仍待验证；不得宣称全中文或UI已进手机。必须测Kodana原实体在原版详情/地图/存档重载中的真实名称，王国/城池改名及原名恢复、窗口互斥、所有触摸入口和字号、旧存档保留。已接续原规则普通十三层不代表隐藏十三层规则完成。

### 超大地图入口（810fd45，需查该提交CI）
原生桥现在也依赖GiantMapOptionsV11.cs和ObserverFrameGuardV12.cs，已加入NativeBridgeSources。不得仅编原来的8个源文件遗漏这两个。原生桥每5秒在创建项/标签未就绪时尝试EnsureExtremeChoice；NML也保留独立重试。
修复不只是add尺寸：校验MapSizeLibrary.getSizes真实列表含xianxia_extreme_32；必要时仅追加已确认的string[] _mapSizes缓存并回读，不兼容时明确未就绪并恢复原缓存。中文label从asset.getLocaleID实际key登记。主入口可见2048档状态，当前世界不会被改尺寸。

实际验收必须在用户原Mono库编译后打开原版新建世界菜单，找到2048×2048、选取并生成，读回MapBox宽高2048及4194304格，再测保存读回、模拟和内存/温度。getSizes校验/模拟场景成功不等于真正生成和存读通过。现有截图448×448为未达标证据，不能拿原版Titanic尺寸冒充用户目标；不得私自自动改小目标。先保护旧存档；只对用户主动新建的世界生效。


### 2026-10-21 新增的v30双工件已实际上传同一私有Work交接目录
- `WorldBox_v30_中文命名_UI_修炼_NML候选与源码.zip`：来自绿灯run `39465488094` 的NML候选工件，实际包含可用两种MOD加载布局、已写入的修炼/中文命名/独占窗口/字体及本地化源代码；无商业WorldBox APK。
- `WorldBox_v30_原生桥及完整私有整合工具_非APK.zip`：来自同run原生私有集成辅助工件，实际包含`NativeBridgeSources/XianxiaMonoBridge.cs`、`CultivationBridgeV18.cs`、`CultivationRulesV18.cs`、`SharedPanelsV30.cs`、`PixelFrameV30.cs`、`ChineseWorldNamesV30.cs`、`IntegratedModBootstrap.cs`、`DiagnosticLog.cs`及已构建诊断入口`WorldBoxDiagnostics_classes5.dex`和校验SHA256。此ZIP约36.8MB，文件库上传返回succeeded。
- 配合此前已真实上传的 `WorldBox_WanjieXianxia_v0.28_Private_Android16_DEVICE_PENDING.apk` 由Work进行**私有同签名升级集成、APK启动、真实修炼入口、UI样式、人物/城市/国家中文名、存档和原版放置工具回归**；不要将这两份非APK工件当成安卓可安装游戏。
- **当前重点**：手机旧包确实进入Unity且CombatGods/Frontiers加载，但自有Observer V07 FAILED及groupsBuilder空键尚未有新APK复验；仅GitHub源码绿灯不等于手机修复。未来任何人接手先看此文件和`DEVELOPMENT_LOG_V22.md`，不能丢掉用户已定的真玩法和完整汉化要求。

## v0.30 实际玩法APK已进Work私有文件库
# 2026-10-21 v0.30 真实玩法增量集成：不是单纯汉化包

**真正的187,840,198字节私有签名APK已由本次会话对用户已有v0.28私有APK增量生成并上传至用户私有文件库** `/WorldBox-万界仙侠/Work交接/`，不公开上传商业WorldBox本体。其SHA256：`1c6dcf0e8f55520497aa516f2c971c37588a3890a3352569c890ebdd1f517fcf`；包名保持lab13；私有测试签名v1/v2/v3通过，但签名证书与v0.28不同（请先备份存档，不能承诺覆盖安装）。

这次打包**不只有汉化**：原旧v18原生桥内已经存在的人物选择/灵根检测、获得功法、修为吐纳、炼气层级突破、灵草和灵石采集与补充、聚气丹炼制服用、少数NPC世界时间规则修行，继续实存于托管桥DLL。MOD源码从18份升级为21份，包含当前`CultivationV18.cs`修行系统、`XianxiaObserverV07.cs`角色/地图观察、`ChineseWorldNamesV30.cs`中文命名候选、`SharedPanelsV30.cs`互斥窗口、`PixelFrameV30.cs`像素框架等。更新的原生Java `classes5.dex`还包含`DiagnosticReport`、`DiagnosticsActivity`、`ModDeployment`，用于真机完整日志导出。manifest由732条→735条，每个资产SHA256/大小及APK ZIP CRC通过；游戏原有Managed.zip/AndroidManifest/globalgamemanagers保持不变。

**不能伪装已可玩：**先前用户实机已报告观察组件FAILED。此次V30中文名字/单窗变化只更新NML源码，**v18原生托管桥尚未重编为V30**，故旧桥仍可能出现旧UI冲突。真正尝试用现有私人APK提取167份Mono参考程序集、合并8份最新NativeBridgeSources，经`GameAssemblyToolkit compile`编译失败（`Assembly-CSharp.dll`的`Invalid public key`和Mono/netstandard引用冲突），错误日志与合并源文件已上传私有Work文件库。这些V30桥功能**不宣称生效**。未实现多城王朝官制、皇宫建筑/等级、浮岛/地府、全境界体系/特殊十三层天劫及NPC大模型，不得将原版游戏自带的功能冒充新开发。

真正新增原创Python签名前四字节zip对齐器`private_zipalign_python_v30.py`及合成回归（不含商用文件），私有APK测试签名密钥和密码**仅保存私有Work文件库**，绝不进入公开GitHub。v0.30包仍为`SIGNED_PRIVATE_APK_DEVICE_PENDING`。

Work下一步：在真实Android16手机运行这一准确SHA256包，收集`MOD_DEPLOY_BEGIN/OK`、`NML_ASSEMBLY_LOADED`和观察失败的完整压缩日志；根据真实Mono参考程序集修补独立原生桥编译，再处理窗口和命名问题。签名差异须先保全旧存档、不可强制卸载。


---

## 2026-10-21 P0真机安装报错：签名冲突已确诊；已制作隔离并行测试包（未实测）

- 用户安装截图清楚显示：「安装失败／已安装了签名冲突的应用」。这属于同包名签名不匹配，**与APK自身签名验证成功不是一回事**，也不是修仙玩法错误。此前做v0.28/v0.30时反复生成新签名证书导致用户无法正常覆盖，必须承认流程缺陷。
- 已按本分支日志追溯并在私有容器对实际四份APK调用Android `apksigner verify --print-certs`：旧v14/v18 SHA256 `a1fa2827668e11da772e9984f277623bb95fc7e0556622a755b7117b8c407104`；v0.28 `70d2cd47f69dc29d7126597b166521e68b4d7da3525ba44d070ad8e0137ea846`；v0.30 `20087dc8c210c7c6a35a4492500324f33f36f7c5eb3a77dc62040c21281c400e`。原APK的签名私钥未找到，**不能复用原证书签新同包名**。此前只检查签名有效、忽略升级签名连续性是P0流程遗漏。
- 为不让用户卸载旧`com.xinyanshuo.worldbox.lab13`导致存档损失，实际制作一份**新包名并行测试v0.31** `com.xinyanshuo.worldbox.lab31`（原v0.30玩法候选不新增新玩法）：`WorldBox_v031_Isolated_Install_DEVICE_PENDING.apk`，187840198字节，SHA256 `37c271ad006df570496231b777547c7a5ab57b36a193b5e16ff0ecf8d1766c1f`。准确补丁11条AXML包名、1条资源包名、11条DEX类命名；重算DEX SHA1/Adler32、重新ZIP 4/16K对齐、用v0.30的私有测试证书签名。APK签名v1/v2/v3、ZIP CRC及包名二进制读回检查全通过；未经Android16安装/Unity运行，不能把静态签名合格等同真机可玩。
- **私有文件已上传并回传成功**：`/WorldBox-万界仙侠/Work交接/WorldBox_v031_Isolated_Install_DEVICE_PENDING.apk`、`WorldBox_v031_signer_gate_report.json`、`private_side_by_side_v31.py`、`private_signing_gate_v31.py`；不向GitHub公开分发商业WorldBox。
- 签名兼容门禁补进独立分支源代码及6项本地Python合成测试（均通过），离线还核验基线v18和最新v31签名证书，输出明确`SEPARATE_APP_ID`。旧应用/旧存档绝不卸载；`lab31`是单独新数据目录，不自动继承旧存档，可能被游戏SDK授权/包名关联限制，手机测试结果决定是否可继续使用。
- **后续优先级**：真实Android16安装实验版→实际Unity/NML/日志与玩法→寻找原v18签名密钥（只有找到才能按旧包名签升级版）→修复原生桥编译失败、观察FAILED、UI叠层/人物名称和2048地图。不要再无故换签名，不要修改苍岚main。


---

# 2026-10-21 WorldBox《万界仙侠》v0.32：真正导入其他MOD + 2048×2048新建地图候选

## 这次已实际进入私有APK（不只是文字设定）

- 安装包：`WorldBox_v032_万界仙侠_直接导入MOD_2048大地图_待实机.apk`（187,848,395字节；SHA256 `3698773435e2a63fa07ccd75a9aa5b9f7ab3fb009d235f52ca5f4e3ef8fe12dc`），包名 **`com.xinyanshuo.worldbox.lab31`**。
- **延续v0.31相同测试签名** `20087dc8...`，避免之前因每版更换私钥导致无法覆盖lab31。它属于独立`lab31`应用，**不能无损覆盖旧`lab13`，旧游戏存档也不会自动同步**。
- **Android原生MOD导入已在 APK 中**：DiagnosticsActivity新增「导入第三方MOD ZIP（支持多选）」；通过系统SAF多选最多8份ZIP，不用MT手动解压；用户确认只导入可信MOD；读取每份`mod.json`判断ModType 0（传统Mono）或1（移动NML），按现有移动部署目录规则安装至本应用独立空间。每ZIP最多48MiB，解压128MiB/1200项以内；阻断路径穿越、重复文件、异常格式、无描述文件、同名模组覆盖，失败回滚已写入目标。**导入不代表MOD已在Unity/NML运行，须重新进入游戏并检查日志**；第三方未知依赖不能自动解决，其他版本可能不兼容。
- **2048×2048（32×32区块）地图预设真正连接到既有v18 Mono游戏入口**：新增独立`WorldBoxXianxiaMapPreset.dll`，使用dnlib仅在用户现有`WorldBoxXianxiaMonoBridge.dll`的Overlay.Update开头注入调用`MapPresetBridgeV32.Tick()`，原Update 18条既有IL语义保留。每5秒检查真实WorldBox地图尺寸AssetManager API，注册32区块候选并验证`MapSizeLibrary.getSizes()`返回可见id；当旧Mono布局存在缓存，校验模板及数组后写新列表并回读，不碰当前世界与存档。**真实2048格地图生成、UI显示、内存、保存/重载/性能还没手机验收，不能冒充最终大地图已经运行。**
- v0.32真正替换了**classes5.dex（原生多选导入）**、**assets/Mono/Managed.zip（增强既有Mono桥+追加MapPreset帮助DLL）**以及**assets/worldbox-xianxia/v18/install.json（构建token刷新部署）**；已逐项对比用户的v0.31 APK，其他原版游戏及MOD资产条目CRC未改变，APK ZIP CRC与v1/v2/v3签名检验通过。
- Github源码：`private-apk-lab/ExternalModImporterV32.java`、`private-apk-lab/DiagnosticsActivity.java`、`private-apk-lab/MapPresetBridgeV32/`、`private-apk-lab/Program.cs`（仅自有桥IL增量补丁）及测试`tests/MapPresetBridgeV32.Tests.cs`；隔离CI对真实Android SDK编译原生DEX，对Netstandard地图帮助DLL及C#模拟菜单注册编译测试通过。功能CI `39474793381`三项绿灯。
- **Work私有文件库实际上传成功**：`/WorldBox-万界仙侠/Work交接/`目录里放有v0.32完整APK、准确私有打包审计JSON、`private_integrate_v32.py`和由绿色CI得到的v0.32完整构建工具包。禁止向公开GitHub传商业WorldBox APK、其他MOD/密钥；本次仅上传独立源码和可审计指纹。

## 仍是红灯/黄灯的真实要求

1. 安卓16 PKR110尚未安装实机测试此版：系统SAF能否取回用户其它MOD、第三方MOD是否实际加载、日志与存档有无冲突均**未过验收**。不同MOD兼容性、依赖冲突、卸载/禁用单模组和游戏内Unity MOD面板按钮也尚未完整实现；当前导入入口是**本APK启动前的原生整合界面**，不是已接入Unity面板的全功能管理器。
2. 地图**代码注册了2048候选入口**并真实嵌入原有托管桥，是否在用户版本的世界创建界面出现/可生成4,194,304格并保存未经过PKR110实机证据。内存/性能风险必须测，游戏生成器可能另有限制。不得把候选注册、SDK模拟和全量生成混为一谈。
3. 观察组件FAILED、原有窗口重叠、王朝/人物英文名、原生桥V30全量重编、完整王朝皇宫、浮岛地府及本地AI仍是其他待验待实现项。**当前仅注入地图帮助DLL，没有宣称这些问题已经解决。**
4. 同证书`lab31`更新需v0.31签名证书一致；任何`lab13`更新仍缺原旧测试私钥，禁止未备份卸载旧应用。与《苍岚》main完全隔离。


---


## 2026-10-21 v0.33——用户实机地图选项仍显示7/8，已复盘原版真实CLR程序集并修复

**用户截图是失败证据，不能说“2048地图已经进入新建世界菜单”。** 用户当前选项“最大 7/8”说明实际仍然是原版8个尺寸，明确判定v0.32交付/视觉验收不合格。

### 静态取证：首次真正用用户原有APK程序集定位根因
- 已从私有用户安装包提取的真实0.51.4 `Assembly-CSharp.dll`运行原始dnlib只读元数据检测 `GameAssemblyToolkit inspect-map-ui`（工具源提交`b101a724`，修复编译提交`1063defa`），确认 `MapSizeLibrary.init()`将tiny/small/standard/large/huge/gigantic/titanic等资产放在继承来的 `AssetLibrary<MapSizeAsset>.list`，原代码**没有可供直接读取的 `MapSizeLibrary.titanic` 成员**。
- v0.32原错误 `Member(lib,"titanic")`因不存在而直接 `WORLD_SIZE_NOT_READY` 返回，**根本没有调用add注册2048**。先前测试伪造了`titanic`字段，绿灯并不能证明真实原版行为，这是QA设计缺陷。
- 真实`MapSizeLibrary.getSizes()`返回静态`_mapSizes`，`MapSizeTextUpdater.updateVars`以及`WorldTemplatesWindow.increaseSize`/`decreaseSize`读取此数组展示当前项/总项；`MapSizeLibrary.convertToOldFormat()`是真实原版维护此数组的方法，通过资产`list`重新生成新建世界尺寸列表。
- 修复源码 `private-apk-lab/MapPresetBridgeV32/MapPresetBridgeV32.cs`：改用真实继承`get("titanic")`模板+在新候选尺寸进入资产列表后调用原版`convertToOldFormat()`，然后验证 `getSizes()`包含新ID；保留受限回退的缓存检查。不覆盖当前世界、已有存档、任何付费接口。
- 修复旧测试`tests/MapPresetBridgeV32.Tests.cs`：明确删除伪造的`titanic`字段，模拟原版8项和继承`get`及`convertToOldFormat`，要求`8→9`并保留原8个选项、重复启动不重复。构建`39479083365`的3项任务**全部通过**，但这些仍是源码行为/SDK/私有工具编译，非手机UI证据。

### 已完成本轮真实私有增量APK构建
- 以用户已有lab31的v0.31私有实验APK为输入，使用新绿灯CI生成的`WorldBoxXianxiaMapPreset.dll` + `private_integrate_v32.py`编译工具做私有整合：同样保留多MOD ZIP导入原生DEX，仅替换`assets/Mono/Managed.zip`中的自有地图帮助DLL/自有Mono Overlay一条挂接调用，并刷新`install.json`的启动部署token。
- 私有实签产物 `WorldBox_v033_2048地图创建选项修复_待实机.apk` 187,852,486字节，SHA256 `7932eb7774d4022065155f0f7ca5373f9bbd3ab1e9e10fe6c15d10d1f66bd996`。签名仍是lab31原有私钥证书 SHA256 `20087dc8c210c7c6a35a4492500324f33f36f7c5eb3a77dc62040c21281c400e`，v1/v2/v3均验证合格，可尝试覆盖**同证书的lab31**，不能覆盖lab13。
- APK ZIP CRC通过；与v0.32比仅改变自有`Managed.zip`、部署`install.json`及签名；原版游戏`Assembly-CSharp.dll`实际SHA256一致，旧MOD内容、诊断DEX和导入ZIP功能未变；自有Overlay的旧18条IL经`verify-map-bridge`确认仅插入一个调用，其余语义保留。
- 已成功上传v0.33签名APK及`WorldBox_v033_地图界面7of8_根因修复与私有验收.json`至用户的Work持久化文件库 `/WorldBox-万界仙侠/Work交接/`，公有GitHub只上传自有修复源码和日志，不公开用户商业APK或签名密钥。
- **必须诚实的验收门槛**：还没有用户PKR110新v0.33手机截图；只有真的在新建世界菜单看见原8项基础上新增第9项“超大世界2048×2048”才可把“菜单入口显示”标通过。真正生成4,194,304格地图、保存/重载/长时间模拟也都未通过，世界生成及Config.maxMapSize可能还另有限制，必须分别测试。此前用户截图7/8为v0.32**失败**，不得再写功能交付成功。


---

## 2026-10-21 03:08 用户实机反馈：v0.33已有9档，但手机挑选多个ZIP大多数无法导入 → v0.34 P0修复真实安装包

### 本轮明确实测情况
- 用户实机反馈“**有9档了**”，地图尺寸列表由原8档出现第9档，故**只将“菜单第9档出现”改记为用户确认**；没有新世界2048×2048生成尺寸日志或存读回归，地图真实生成仍保持红灯。
- 用户Android原生MOD导入实测：一次选择多份ZIP，多数提示“ModType -1”、“找不到有效mod.json”及路径错误；有一份模组曾导入成功。界面把字面量`\\n`画成文字，导入状态可读性差。这是确实存在的导入器验收失败，不是让用户一遍遍重复选择。
- 对用户**已经上传的真实MOD ZIP**在私有环境逐个打开、校验CRC/文件布局，发现`0.51.+中文名模组ChineseName_1.5.1.zip`包含181项、真实`ChineseName_1.5.1/mod.json`却**没写ModType**，包含合法`Code/*.cs`。旧导入器只判断`ModType==0/1`而错误拒绝。`操作人物mod(1).zip`只有`z_com_TWrecksMod.dll`和说明，无mod.json；静态DLL标记BepInEx/BaseUnityPlugin，不可无端当安卓NML。`WorldBox修仙模组0.078.6整合包带国风材质.zip`含旧桌面BepInEx，`附庸国系统5.1.zip`多Lua/Civ6资源，`国风-中文汉化mod 0.10.3.zip`内还嵌其他ZIP但无NML描述文件。这些内容不能靠改个ModType蒙混加载。

### 本轮真正提交/编译并装入原有lab31的v0.34 APK
- `private-apk-lab/ExternalModImporterV32.java`实质修复：存在`mod.json`但无ModType时按包内**真正的Code/*.cs或NMLMods/*.dll结构**判断Mono源码/NML编译格式；有效Unicode/中文GUID经确定性哈希正规化为私有目录名，仍阻断路径穿越、重复同名及尺寸异常。支持一个外层ZIP含多个嵌套ZIP时**递归一层并逐包报告**；支持最长128MiB输入、384MiB总解压（边读边校验）。**绝不把桌面BepInEx、散装DLL、其他游戏Lua脚本误声明为安卓可运行MOD**。
- 新增`ModFormatV34.java`纯JVM格式检测与`tests/ModFormatV34Test.java`，采用合成ZIP文件复现缺`ModType`的`ChineseName_1.5.1/Code/*.cs`结构和NMLMods预编译结构。GitHub Actions `39482655211`三项作业全部绿灯（Android SDK javac+d8、公开SDK C#、Python/JVM回归），工件内包含真正编出的新增导入器DEX，不使用客户商业APK做公开CI。
- 对未知但**有效ZIP**新增`XianxiaModStaging/incompatible/`本应用私有待兼容目录：严格限量、按SHA256存放ZIP原字节，仅暂存**不解压执行**。用户可看到“可尝试加载N个/待兼容保管M个”和各失败原因，避免所有选择都被直接丢弃。对假ZIP、不可信可执行内容和同名覆盖保持阻断，**存下≠兼容或运行成功**。
- `DiagnosticsActivity.java`修复手机UI把`\\n`当文字的问题，结果改为真实换行、可长按选择的17sp文字；多选SAF不再误过滤某些提供方自定义ZIP MIME；启动入口过时`v18`标题更新v0.34。原版WorldBox Unity画风/菜单仍未统一、此仅原生导入入口功能与排版修复。
- **真实私人APK重新制作且签名通过：**`WorldBox_v034_第三方MOD_ZIP直接导入修复_待实机.apk`（187,852,486字节；SHA256 **`464348c8075b70f367dfab2758844baba3a168a7c189be1321d7b71caeeac1df`**）。继续使用lab31同一测试证书SHA256 `20087dc8c210c7c6a35a4492500324f33f36f7c5eb3a77dc62040c21281c400e`，v1/v2/v3签名及ZIP CRC全过，可供已有lab31用户尝试覆盖。与v0.33相比**仅改变自有`classes5.dex`和部署`install.json`、重签元数据**；原WorldBox游戏/旧2048尺寸帮助DLL/原游戏资产完全不变。
- 真正APK、仅含摘要的用户既有MOD包格式分析JSON、APK静态验收报告、私有整合脚本均已成功上传ChatGPT持久文件库 `/WorldBox-万界仙侠/Work交接/`；仓库只收录合法自有源码、诊断和开发日志，**不上传游戏APK/用户MOD二进制/私钥**。

### 不可提前写PASS的事项
- v0.34尚未通过用户PKR110设备点击导入并重启验证；真实`ChineseName_1.5.1`能否被NML编译并影响名称、第三方MOD依赖/版本冲突、模组管理启停/卸载、ZIP中嵌套包互斥冲突均待现场测试。
- v0.33用户确认新建世界9档，但**9档不是2048生成、保存与读取均成功**；仍需实际创建新世界、读取长宽、保存回读与手机性能。
- 暂存的旧DLL/BepInEx包不会自动执行。与苍岚游戏main完全隔离。



---

## 2026-10-21 v0.35 经济/物资流水线真实工作记录

# WorldBox·万界仙侠 v0.35 经济与批量素材工业生产线

> 非官方、独立的WorldBox安卓0.51.4 MOD衍生研发；**与《苍岚·人生世界》正式工程/发布无关**。从苍岚借鉴物品树与经济规则，**没有合并苍岚Godot代码或模型**。

## 这轮已有真实交付文件与代码

- **真实程序化像素工厂**：`economy-v35/material_factory_v35.py`读取一个`catalog_seed.json`，自动生成10类、97个基础物资、171个32×32 RGBA透明原创像素图标、544×374贴图总览和74条精制/官署升级材料配方。构建会校验不重复的稳定ID、PNG透明度、配方材料引用、图像哈希、生成决定性与ZIP CRC；新增物资只需增补数据种子，**不用手工逐一绘制**。
- **钱粮经济C#内核**：`economy-v35/EconomyKernelV35.cs`及`EconomyUnityAdapterV35.cs`提供铜钱/银/金面值、灵石天然采集、交易（货物流向与钱相反）、征税和军饷转账、研究与人力控制的工坊制造、村乡镇县州郡国实际所属账本结构、按WorldBox地图tile真正所有者计算王国面积及边界的算法；`tests/EconomyScenarioV35.cs`已自动通过守恒/人口行政基础测试，**但不能说WorldBox里面的NPC农商军运行了完整经济循环**。
- **原版对应分类栏绑定候选**：`EconomyVanillaTabsV35.cs`用NML真正API `CreateSimpleButton`/ `AddButtonToTab`尝试向WorldBox原版的自然(`nature`)、制造(`creation`)、文明王国(`noosphere`)三个原版栏位加入三个小图标入口，点击后可浏览所有10个资源家族的171个图标；需要用户手机本地的兼容NeoModLoader成功运行，该运行条件未验收。图标资源放进APK本地`assets/worldbox-xianxia/v18/files/mods/WorldBoxEconomy/`，由已有`ModDeployment.install`部署到应用专用文件路径，不重复画三套独立风格菜单。
- **真实APK增量**：本次将自有`WorldBoxXianxiaEconomy.dll`打入既有Mono Managed.zip，并只在用户自有Mono Overlay OnGUI中注入**一个可验证调用**，向已有「万界」菜单接入“钱粮·财政”面板。保留既有灵根修仙、2048地图选择、MOD导入、原版游戏托管`Assembly-CSharp.dll`与安卓引导DEX。
- **材质/建筑资源计划**：包括铜矿、金银、煤铁等矿石、粮草、牲畜、木石、灵植、货币；可扩展至铁器、军甲、马车、丹药、符箓与宫殿三级。当前“皇宫”只是多级资源图标及行政属性设计；**尚未变成WorldBox真实可住/可升级的皇宫建筑**。
- **领域边界**：国土tile所有权的面积计算函数已实现；没有手机运行态的实际所有者全地图扫描，就不臆造国界线或每国面积。画线、占领、财政、军事、农业就业/价格动态仍待后续实机联动。
- **批量美术**：本轮图标是原创代码生成的可检索测试资产，不是从WorldBox抠图也不是AI逐个手工做图；需要用户审核32像素下的WorldBox画风细腻度后迭代同一工厂。

## QA、签名与真实交付

- CI v35独立流水线`39489547081`两项作业成功，产出公开原创图标包与Netstandard经济DLL；原模组Android公开SDK/源代码CI`39489547057`三项作业成功，真实NML原版分类按钮C# SDK编译、Mono源包签包。
- 已在用户**私有**v0.34实验APK基础上增量生成`WorldBox_万界仙侠_v035_经济货币与171项资源流水线_待实机.apk`，实际字节`188042919`，SHA256`2504cbf0d4c3a407c9d590cd07ebaa1ff59d5f787a3b19440c25a5e8c9efc101`；继续沿用lab31的v0.31-v0.34同一个测试签名（证书SHA256 `20087dc8c210c7c6a35a4492500324f33f36f7c5eb3a77dc62040c21281c400e`），APK签名v1/v2/v3与ZIP CRC全过。APK资源部署项从735项增至911项，且商业原版Assembly-CSharp和安卓引导DEX未更换。
- 私有APK、实际资源ZIP、171张图总览、真实静态审计JSON、私有重建脚本已经上传ChatGPT文件库 `/WorldBox-万界仙侠/Work交接/`，供Work接手。GitHub public仓库仅保存原创源码、测试和无商业内容的元信息，**不将WorldBox商业APK或测试签名私钥上传公开仓库**。
- **红灯：** 尚未进行用户PKR110安卓16实际新版本的经济面板/原版资源分类按钮验收，也尚未确认2048地图实际生成存档、MOD Android成功装载、钱粮进入WorldBox NPC真实市场、皇宫实体与真正边界线出现。**APK编译签名不等于玩家已经能玩完经济系统。**

## 后续必须按工业化流水线扩展

将自然生产节点（农田、矿脉、兽群）绑定原版WorldBox真实世界tile与职业NPC → 按世界时间增量运行交易/物流/农业/国库税收与军饷 → 国土/行政区域实际划分与皇城建筑层级/高品质图标风格统一 → 手机受限内存下2048地图取样与存档验收。每新增物资/职业/生产链经catalog驱动自动出素材、自动构建配方与进出库账、自动出对应原版分类按钮；**未运行不标通过**。


---

## 2026-10-21 v0.36：原版王国—城池—领土—原生库存首次联动（用户手机待验）

**这轮不是只增加素材表。** 已从用户私有v0.35完整签名APK实际提取0.51.4游戏原始Mono程序集，以自家`GameAssemblyToolkit inspect-economy-api`确认真字段和方法，再在已有经济DLL中做实际世界读取适配并重签v0.36。与苍岚main保持严格隔离。

### 原版0.51.4 API真实检查结果
- `World.world`为静态属性返回`MapBox`；`MapBox.instance`静态字段可后备；`MapBox.kingdoms`指向`KingdomManager`。
- `Kingdom.cities`是真实`List<City>`，`Kingdom.getPopulationTotal()`是真实原版人口统计。
- `City.data.cityID`/`cityName`真实、`City.zones`是`List<TileZone>`；`TileZone.tiles`是`WorldTile[]`，因此可以对本国已有城市所属TileZone的格子数量进行**实际面积统计**（尚未证明一国全部边界像素、海外领土等100%覆盖）。
- `City.amount_gold`、`amount_wood`、`amount_stone`、`amount_common_metals`是原版原生库存读数。**原版金属资源≠我们的新铜钱国库余额，不得按原生物资自动印钞**。
- 当前市镇采用一个WorldBox城市对应一份**县级账本代理**进行数据读写隔离，**这还不是完整的历史村/乡/县/州/郡行政机关玩法**。

### 实际合并与QA
- 改`economy-v35/EconomyUnityAdapterV35.cs`，直接读取真实王国对象、城池ID/名称、人口、City.zones区域面积、原版木石金属库存；王国被吞并时城市不双重计入、移出/销毁会清除过期统计；更换地图对象立即清除旧场景账本，保证前世界资料不会显示在新世界上。
- 改`EconomyKernelV35.cs`，行政节点增加可更新名称、真实原版资源快照、原版城市数量、领土格子数及**区块边界粗统计（不是精确国界）**，且与由用户后续发展出来的铜钱/灵石账本严格区分。
- 改`EconomyMonoOverlayV35.cs`，在原有「万界·钱粮」界面加入【国家/城池】切换和翻页：国家看人口/城数/格子面积；城池看原版金/木/石/金属原生存量，不继续显示假造的默认行政数据。
- 加`tests/RealWorldEconomyScenarioV36.cs`：模拟**真实0.51.4反射结构**，覆盖两国三城、原版资源读数、领土格子累计、战争易主库存不凭空复制、城市删除、切换世界清理旧档。**GitHub Actions `39500142579`已通过`PASS_V36_REAL_0514_WORLD_COUNTRY_CITY_TERRITORY_NATIVE_STOCK_CONQUEST_RELOAD`。** 本分支源工程/Android SDK编译`39500113925`三作业成功（但不是手机运行）。
- 已将真正v0.36的`WorldBoxXianxiaEconomy.dll`从公开Actions构建工件取回**替换进入用户私有APK内的`assets/Mono/Managed.zip`**，保持原游戏`Assembly-CSharp.dll`、原有Mono安装桥、native`classes5.dex`、原版模组素材和171张图不变，刷新部署token；APK原文件在工作区保持不变。不是脱离游戏的独立演示。
- 完整私有测试APK：`WorldBox_万界仙侠_v036_真实王国城池土地资源读取_待实机.apk`，**188,042,919字节**，SHA256 `f59a272ef92fd5b7b97b1f9c4051d22676955a1ad80260affdb2e65f85d58636`；同`com.xinyanshuo.worldbox.lab31`包名、同v0.31-v0.35签名证书 `20087dc8c210c7c6a35a4492500324f33f36f7c5eb3a77dc62040c21281c400e`，签名v1/v2/v3与ZIP CRC检验通过。
- 本轮真实可变内容只包括`assets/Mono/Managed.zip`里我们自己的经济DLL、`install.json`元数据及APK签名记录（共5个改变的ZIP项目），没有修改商业原游戏代码、原本游戏存档、安卓引导DEX。已上传最新签名APK、只读审计报告、私有打包器、公开SDK编译的经济DLL到ChatGPT文件库 `/WorldBox-万界仙侠/Work交接/`，不公开分发含商业WorldBox的APK或签名私钥。

### 红灯门槛（不能虚报完成）
- **安卓16 PKR110未实际安装运行v0.36**；现有原版世界属性是否即时被桥调用、是否显示王国真实人口/领土格子/城市原生库存、屏幕滑动/性能均需用户实机截图与导出日志。
- 实测2048地图成功生成、保存/重载、精确国境线可视化仍未通过；目前只利用现成TileZone格子面积，不是上色边界绘制。
- **贸易物资物流、自动生产/消耗、NPC耕作与军饷实际改变WorldBox原生行为、皇城实体、县州郡民政、模组依赖管理/本地AI**仍待联动；不能把C#经济测试当游戏完整系统。
- 扫描上限256国/6000城与20万区域为安全帽；极端2048地图应继续做分帧扫描、性能取样与资源缓存，禁止每帧遍历400万tile。

### 下一轮优先
拿v0.36实机钱粮面板截图/日志确认真实国/城数据，然后做分帧城池/领土缓存与可视化国境线，再将农场、矿场、市场NPC/官员/士兵的产出、消耗、工资和税收联动城市库存，配合现有171图标/74配方流水线批量出资源而非手工逐一建模。


---


## 2026-10-21 v0.36 50×50 区块超大地图——当轮立即实现并打包
- 用户明确要求不要卡，直接做50×50。按照已验证的`32个区块→2048地图格`换算新增地图选项：`xianxia_extreme_50`, `size=50`，即**横向50、纵向50区块≈3200×3200实际地图格**、约1024万地图格。保留`xianxia_extreme_32` 2048地图。**注意“每轴50个区块”不是“旧地图每边乘50倍”**；后者在安卓现有内存/生成器能力下未获任何验证。
- GitHub真实源码已更新 `MapPresetBridgeV32.cs`：先注册已验收第9档的32×32区块，再注册新增50×50区块；使用WorldBox原生`MapSizeLibrary.get`和`convertToOldFormat`，避免过去的8/8假成功。回归必须要求原版8档+两档扩展共10档，重复加载不复制选项。
- 真实Actions **`39501753375` 三项作业成功**：测试套件、公开SDK编译及用户私有工具链构建。取出Actions真正编译出的`WorldBoxXianxiaMapPreset.dll`（11,264字节），替换上一版真实`v0.35` APK内托管`Managed.zip`中的原帮助DLL，其余原版WorldBox主程序集和Android DEX均保持原字节。
- 这次重打包采用**压缩数据零重编码的ZIP局部更新＋对齐器**，不再每次重写上万份原版游戏资产。新增build_token确保v18部署不会使用旧缓存。私有签名产物`WorldBox_万界仙侠_v036_50x50区块地图_待实机.apk` **188,038,876字节**、SHA256 `f23f8a423550e2262369c3de65d8fe67019d7e508c2c938907910ccae7a4fe33`，签名v1/v2/v3全部验签通过，维持原`lab31`证书SHA256 `20087dc8c210c7c6a35a4492500324f33f36f7c5eb3a77dc62040c21281c400e`，可尝试覆盖同证书`lab31`，不可覆盖`lab13`。
- APK及`WorldBox_v036_50x50区块地图_签名校验.json`已实际上传到用户私有ChatGPT Library `/WorldBox-万界仙侠/Work交接/`，公有GitHub只放原创源码、文档、摘要，**绝不发布用户商业WorldBox APK或签名私钥**。
- **P0明确未验收：**只证明新程序已入APK、签名及离线构建成功；尚无真实手机界面`10/10`截图，也没有`3200×3200`地图完整生成、存档重开或内存帧率数据。生成器若仍有地图限制需要实际游戏日志；绝不宣称已经成功产生1024万个地块。
- 本轮地图功能优先，不重复开发钱粮经济/素材流水线；保留v0.35经济与资源图标所有内容，不改苍岚main。

## v0.37 已完成真正私有APK打包并同步Work（2026-10-21）
- 新第11档 `xianxia_extreme_100` 100×100个区块，按每区块64格估算6400×6400=4096万格。保留原八档以及32×32、50×50两项，预期共11档。
- 已从GitHub Actions `39503609451` 三个成功作业中取得真实编译的地图DLL，增量修改已有lab31 v0.36签名APK。输出 `WorldBox_万界仙侠_v037_11档100x100区块地图_待实机.apk`，188038877字节，SHA256 `9c865d2e531e729403caf91ec975404ea6eaa62bc26e7249096472565dff5bc7`。
- APK v1/v2/v3验签通过，全13605个ZIP条目CRC通过；只改自身地图模块及安装清单，原WorldBox Unity主程序集、旧Mono桥及安卓DEX均未变；使用lab31相同测试证书，可尝试覆盖同签名lab31，不可覆盖lab13。
- 私有APK、真实验签报告、复现打包脚本已经上传ChatGPT持久文件库 `/WorldBox-万界仙侠/Work交接/`。商业游戏不上传公开GitHub。
- P0待证实：手机11/11菜单出现；6400平方地图成功生成、存档并重新载入；内存/卡顿。4096万格可能导致严重OOM。不能将编译/签名成功当作手机实机完成。


---


## 2026-10-21 v0.38 已私有签名重打包：错误可观测性修复（不是观察MOD已修好）
- 用户提供实机**v34**`MOD_DEPLOY_OK`，同时自家Observer`FAILED reason=`。必须先从完整Unity栈定位真实异常，不能将已成功的`Frontiers/Sakuga`或非致命`libsteam_api`警告误判为观察MOD启动成功/失败的根因。
- 已提交并经Actions `39504776367`三组全部通过：`DiagnosticsActivity.java`按安卓SAF显示实际每个被导入ZIP的文件名+失败原因；`DiagnosticReport.java`突出NML及Observer最后状态，把Steam警告折叠而不从完整日志里删除；`DiagnosticReportScenario.java`复现FAILED+Steam+zip END场景；`qa/triage_android_summary_v38.py`输出证据分级报告。
- **已真正用v0.37私有原APK增量制作`WorldBox_万界仙侠_v038_实机MOD故障诊断_待实机.apk`**，188042967字节，SHA256 `65dc2ec13f5c2d25c6c2fe94fb437b0b947c547477a95b410f680aaf5644ed73`，包名`com.xinyanshuo.worldbox.lab31`，沿用lab31原有测试签名指纹`20087dc8c210c7c6a35a4492500324f33f36f7c5eb3a77dc62040c21281c400e`。全APK ZIP CRC及Android v1/v2/v3验签通过，原WorldBox`assets/Mono/Managed.zip`、游戏主程序集、AndroidManifest不变。除签名metadata外只更新自有`classes5.dex`和部署`install.json`（build`v38-observer-zip-diagnostic-c6ce167f0bbffd91`）。与lab13不是同一个包名，不要覆盖或卸载旧lab13。
- 此私有APK及JSON审计已经实际上传用户ChatGPT Library`/WorldBox-万界仙侠/Work交接/`。**没有Android16安装验收，observer具体修复仍为红灯**，必须等待用户通过新版入口【导出并分享完整日志ZIP】上传实际异常；不要声称v38修复了ZIP自身损坏或观察模块FAILED。
- 公开GitHub只放自有代码、QA及本报告，**不上传商业WorldBox游戏APK、玩家存档或私钥**；苍岚main未修改。


## 2026-10-21 v0.39 真机启动闪退P0：静态证据确认修复（待实机复核）
- 用户称刚交付的v0.38直接闪退，未进入游戏。对照本人先前交付的v0.38和v0.37**实际APK**，确诊v0.38的AndroidManifest是 lab31，但被错误直接引入的classes5.dex包含18个诊断类全部声明于lab13（尤其 Lcom/xinyanshuo/worldbox/lab13/DiagnosticsActivity;），而Manifest需要 lab31.DiagnosticsActivity；这是Android找不到Launcher类而启动崩溃的直接静态根因，**此前“v38已签名通过”对功能可用无效**。
- 已真正从v0.38原有私人实验安装包生成v0.39，修复全部18个Java类包名 lab13→lab31（等长原地替换，自带SHA1+Adler32修复），维护原AndroidManifest，使用**相同**lab31测试证书重新打包签名。除签名外仅有自有classes5.dex及部署install.json改变；真实WorldBox商业主程序集、MonoManaged、171原创图标、经济内核、地图预设均无改动。
- 实际签名APK：WorldBox_万界仙侠_v039_安卓闪退修复_100x100地图保留_待实机.apk，188042967字节，SHA256 fbe9a980afdeb0a44aae0bffce110cd7f7902f5cf52609d2c63a426360900fc5，同lab31证书 SHA256 20087dc8c210c7c6a35a4492500324f33f36f7c5eb3a77dc62040c21281c400e；真实APK v1/v2/v3签名验证、13605项ZIP CRC、Manifest/DEX类名、原文件其他CRC不变验证均通过。
- v0.39保留经Mono DLL实际检查的 100×100区块（xianxia_extreme_100，约6400×6400地图格）和50×50区块选项，**地图实际生成、内存/存档与兼容NML加载仍待安卓16验收**。原日志中观察MOD FAILED 也未因为修正安卓启动类而自动修复。
- 将完整v0.39私有APK、真实签名/根因校验JSON、签名重建脚本成功上传用户Work Library /WorldBox-万界仙侠/Work交接/。不要上传商业APK/密钥到公开仓库。
- 新增源代码硬门禁 private-apk-lab/verify_android_package_consistency_v39.py 和 test_v39_manifest_dex_gate.py，CI里加入合成包回归：Manifest是lab31而DEX是lab13必须明确失败，防止重犯。GitHub公有CI只用模拟文件，不包含商业APK或私钥。
- **真实验收级别**：P0启动崩溃根因已静态确认并修复签名包，但v0.39尚未在用户PKR110上实机启动成功；优先安装v0.39尝试覆盖同证书lab31。如果依然闪退，需新版本导出android崩溃记录以定位其它根因；绝不继续宣称用户手机已正常运行。与苍岚main严格隔离。


---


## 2026-10-21 v0.41——10000×10000精确地图的分区底层第一步（真实源码+私有签名APK）

**不要把本轮误写为玩家已经进入10000×10000的完整WorldBox世界。** 本次实现的是真正能够按坐标访问**1亿个逻辑地块**的独立分区数据引擎，不是原版Unity `MapBox`生成了1亿个`WorldTile`。两者要进一步融合，地图画面、NPC导航、国家边界、资源采集都未自动扩容。

- 原创C# `stream-world-v41/WorldGridExactV41.cs`：逻辑地块边界准确为`0..9999`（10000×10000），128×128格/区块，横纵各79个（最边缘区块16格），总计6,241个区块。无需一次分配1亿对象，以坐标哈希按需生成基础生境；按L RU仅保留12个被访问区块，缓存淘汰时持久化玩家修改。
- `WorldGridStreamRuntimeV41.cs`：用现有`WorldBoxXianxiaMapPreset.dll`的Mono Update引导，**每10秒**通过反射尝试唤起独立`WorldBoxXianxiaStreamGrid.dll`并记录`[V41-STREAM] V41_VIRTUAL_GRID_READY`或失败原因；只采样8×8预览，不创建整世界、不修改商业`Assembly-CSharp.dll`。`[SIZE-AUDIT]`仍单独报告真正游戏`MapBox.width/height`，二者互不混淆。
- 分区更改使用有界增量字典、SHA256防坏档、先暂存后替换写盘；新增`WorldGridTestsV41`测边界10000、角落16格、跨运行保存、随机访问500处缓存≤8、真实坏档校验，不会把生成数据假装成玩家真实世界。
- GitHub Actions`39550983219`：项目测试、NML公开SDK编译、私有辅助DLL构建**三组全部成功**。对原有v0.39私人签名APK进行真实增量打包，托管`Managed.zip`里替换自有MapPreset模块并新增StreamGrid模块，修改自有install.json构建标志；与原APK比较仅此两项游戏内容变化，安卓Launcher`classes5.dex`和`AndroidManifest.xml`原样保持，不再引发lab31/lab13混用的启动类回归。
- 实际签名产物 `WorldBox_万界仙侠_v041_10000x10000分区世界底层_待实机.apk`（188,051,159字节），SHA256`b5e0d1f259477990752e555d53a2911b0eef170643f8ec20e5b0ae822f65b46f`。使用原lab31签名证书`20087dc8c210c7c6a35a4492500324f33f36f7c5eb3a77dc62040c21281c400e`，Android签名v1/v2/v3和APK ZIP CRC全部校验通过；**未用用户真机安装/验证Unity、MOD加载、内存及存盘行为**。
- 私有APK、静态集成审计JSON、无硬编码私钥的重建脚本以及源码已实际进入`/WorldBox-万界仙侠/Work交接/`。公开GitHub仅保存源码/测试/变更日志/无商业代码的元数据，不包含商业WorldBox APK或私钥；《苍岚》main未动。

**P0未验项：**旧用户手机Observer v07仍存在`FAILED`记录，v0.39启动也尚未有手机通过的证据；此并行V41引擎是否加载取决于Mono桥是否真正运行。虚拟地块还没与原版地图画面/导航/城市/国土/资源生态绑定，跨存档WorldBox世界ID隔离尚未完成。不要仅因新APK装得上/日志有100000000就写“10000×10000真实WorldBox游戏大地图已完成”。

**后续工程（明确界限）**：先取得`[V41-STREAM]`与`[SIZE-AUDIT]`的手机日志→确认真正地图生成路径及可见区域接口→把按需区块绘制/玩家坐标映射接到游戏画面及存档ID→NPC/经济在可见块高频、远区低频模拟，并提供拒绝OOM的内存预算门禁；**不通过创建带1亿Unity对象的裸157档强推给手机**。


---


## 2026-10-21 v0.42：将一亿格逻辑层做成游戏内可操作的区块预览（非可玩Unity地图）
- **真实新代码** `stream-world-v41/WorldGridViewportV42.cs`提供10000×10000坐标边界内的上下左右平移、六级放大缩小、贴近(9999,9999)的边缘夹取；`WorldGridGuiV42.cs`使用Unity原有Mono OnGUI，打开既有【万界】菜单后新增【世界分区图·10000】按钮，绘制每次最多16×10=160格的有限虚拟地形颜色预览、中心坐标、原版世界`MapBox.width/height`读数（仅供对照）。按钮通过既有经济面板绑定调用，**没有重新修改商业原版游戏Assembly-CSharp.dll**，也没有建立巨量WorldTile数组。
- `WorldBoxXianxiaStreamGrid.csproj`和`WorldBoxXianxiaEconomy.csproj`编译到独立自有DLL；`EconomyMonoOverlayV35.Draw`做反射调用，实际加载失败只影响可选窗口，不应使原版UI崩溃。代码自动构建项目使用自己的原创像素风颜色区分森林、水、山、草与湿地，并明确在窗口标注“虚拟分区地图，不是WorldBox游戏可行动的一亿格地形”。
- **质量门禁** `stream-world-v41/tests/WorldGridViewportTestsV42.cs`检查放大时不出界、最大坐标9999、16×10预览只读取160个虚拟地块、缓存≤5区块；v0.41的真实跨进程分区存档、坏档拒绝、1亿格坐标测试同时保留。独立GitHub Actions **`39562894755`三个任务全部成功**（仅源码/NML公开SDK模拟、编译与电脑单测，**不是手机游戏实机验收**）。
- **真实签名整合APK已出**：以用户既有v0.41专用私有APK为输入，替换其`assets/Mono/Managed.zip`中的自身`WorldBoxXianxiaStreamGrid.dll`与`WorldBoxXianxiaEconomy.dll`，升级自有`install.json`缓存token，**安卓launcher/classes5.dex、AndroidManifest.xml、WorldBox商业程序集和原签名证书均保持不变**，保证不再次引入v0.38包名不匹配的启动闪退。
- 私有安装包 `WorldBox_万界仙侠_v042_可视10000x10000虚拟分区地图_待实机.apk`：188059356字节，SHA256`727dd6b9ed1346ef44b8ffcf81314016abc024ee3acc41b418320f482dfa4296`。原`lab31`测试证书SHA256`20087dc8c210c7c6a35a4492500324f33f36f7c5eb3a77dc62040c21281c400e`，v1/v2/v3签名与全部APK ZIP CRC验证通过；**未在PKR110手机验证可进入游戏/看见按钮**。
- 真实APK、集成审计JSON、私有复制签名脚本已上传`/WorldBox-万界仙侠/Work交接/`；公开GitHub独立分支仅保存自有C#源码、自动化测试和记录，不发布商业WorldBox APK、个人私钥；苍岚main未动。
- **阻断项仍在**：现实WorldBox`MapBox`并未扩展为10000×10000，用户没法在本轮真实跨10000个游戏地块行动。观察MOD V07此前手机日志FAILED，原Mono桥进游戏能否工作尚待完整日志和手机验证，跨原生WorldBox存档ID的正式隔离也未完成。不能把这张“虚拟地图预览”与“已可探索真实巨世界”混为一谈。
- 下一步：在真实手机完成启动与窗口可视性验收后，研究原游戏的WorldTilemap/MapChunkManager承载方式，实施“可见区真实映射+远区分层账本”的技术原型，且首先完善每WorldBox世界存档隔离与防坏档保护，再考虑扩大实时地图本体。


---


## 2026-10-21 v0.44：ZIP安全归一化 + 预编译观察MOD旧源码受哈希保护清理

**用户实机v41报告**显示NML已初始化、Frontiers/Sakuga等成功加载，但自有Observer=FAILED，动态源码编译出现CS0009 Invalid public key；另有凡人修仙传ZIP报路径格式不安全。v0.43以预编译观察MOD替代源码，但旧手机安装目录残留原19个C#文件。

本轮已完成并入真实lab31私人APK：
- `ExternalModImporterV32.java`实际接入`SafeZipPathsV42.normalize`：能规范安全相对路径中反斜杠、点前缀、重复斜杠与大小写mod.json；仍拦截Zip Slip绝对路径、..父目录、控制字符、标准化后路径冲突、未知可执行和异常解压体积。
- `OwnedModSourceCleanupV44.java`仅删除固定本项目Observer/Code目录中与原v0.41/v0.42 APK确切文件SHA256一致的19个历史源码；变化过的用户文件、其他MOD、存档绝不删除。部署器显示清理/保留数量。
- 新增纯Java合成安全测试：ZIP路径允许安全Windows分隔符但禁止穿越，旧源码的SHA不一致不删除、第三方文件不删除、SHA一致才删除。Actions `39565890856`三项任务全部成功，编译结果是**真实Android DEX**，不是只有文档。
- v0.44以原v0.43签名整合包为输入，仅更换自有`classes5.dex`和`install.json`，在最终DEX统一lab31类名并修复SHA1/Adler32；游戏`Assembly-CSharp`、Mono桥、171图标、虚拟分区图、自有Observer预编译DLL字节不变。APK完整ZIP CRC和v1/v2/v3签名均通过。
- 私有APK：`WorldBox_万界仙侠_v044_模组ZIP导入与旧源码清理修复_待实机.apk`，188052893字节，SHA256 `022e8d2195e046c867c2fca7a7614d50ee1d6bbd755a4a2acf0b7324a4c03baf`；已上传用户私有Library`/WorldBox-万界仙侠/Work交接/`，公开仓库只有自有代码与记录，苍岚main未改变。

**P0/实机待验：** 用户仍未提供失败的`凡人修仙传_v1.1.16.zip`实际字节，所以不宣称其能加载；观察MOD由FAILED转LOADED、安卓16启动、旧源代码清理数量，均需要新版本日志才能确认；独立10000×10000分区图**不等于**原版WorldBox真实一亿格可玩地图。第三方Chronicle的CS0009未根治。只允许安卓16设备实测后再标通过。
