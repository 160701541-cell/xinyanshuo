
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
