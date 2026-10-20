# 2026-10-21 v0.30 真实玩法增量集成：不是单纯汉化包

**真正的187,840,198字节私有签名APK已由本次会话对用户已有v0.28私有APK增量生成并上传至用户私有文件库** `/WorldBox-万界仙侠/Work交接/`，不公开上传商业WorldBox本体。其SHA256：`1c6dcf0e8f55520497aa516f2c971c37588a3890a3352569c890ebdd1f517fcf`；包名保持lab13；私有测试签名v1/v2/v3通过，但签名证书与v0.28不同（请先备份存档，不能承诺覆盖安装）。

这次打包**不只有汉化**：原旧v18原生桥内已经存在的人物选择/灵根检测、获得功法、修为吐纳、炼气层级突破、灵草和灵石采集与补充、聚气丹炼制服用、少数NPC世界时间规则修行，继续实存于托管桥DLL。MOD源码从18份升级为21份，包含当前`CultivationV18.cs`修行系统、`XianxiaObserverV07.cs`角色/地图观察、`ChineseWorldNamesV30.cs`中文命名候选、`SharedPanelsV30.cs`互斥窗口、`PixelFrameV30.cs`像素框架等。更新的原生Java `classes5.dex`还包含`DiagnosticReport`、`DiagnosticsActivity`、`ModDeployment`，用于真机完整日志导出。manifest由732条→735条，每个资产SHA256/大小及APK ZIP CRC通过；游戏原有Managed.zip/AndroidManifest/globalgamemanagers保持不变。

**不能伪装已可玩：**先前用户实机已报告观察组件FAILED。此次V30中文名字/单窗变化只更新NML源码，**v18原生托管桥尚未重编为V30**，故旧桥仍可能出现旧UI冲突。真正尝试用现有私人APK提取167份Mono参考程序集、合并8份最新NativeBridgeSources，经`GameAssemblyToolkit compile`编译失败（`Assembly-CSharp.dll`的`Invalid public key`和Mono/netstandard引用冲突），错误日志与合并源文件已上传私有Work文件库。这些V30桥功能**不宣称生效**。未实现多城王朝官制、皇宫建筑/等级、浮岛/地府、全境界体系/特殊十三层天劫及NPC大模型，不得将原版游戏自带的功能冒充新开发。

真正新增原创Python签名前四字节zip对齐器`private_zipalign_python_v30.py`及合成回归（不含商用文件），私有APK测试签名密钥和密码**仅保存私有Work文件库**，绝不进入公开GitHub。v0.30包仍为`SIGNED_PRIVATE_APK_DEVICE_PENDING`。

Work下一步：在真实Android16手机运行这一准确SHA256包，收集`MOD_DEPLOY_BEGIN/OK`、`NML_ASSEMBLY_LOADED`和观察失败的完整压缩日志；根据真实Mono参考程序集修补独立原生桥编译，再处理窗口和命名问题。签名差异须先保全旧存档、不可强制卸载。
