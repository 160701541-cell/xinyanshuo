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
