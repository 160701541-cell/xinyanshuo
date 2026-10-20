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
