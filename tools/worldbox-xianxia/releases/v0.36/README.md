# WorldBox·万界仙侠 v0.36 | 真实王国城市经济读取

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
