# WorldBox 非官方衍生MOD v0.8 — 独立外部游戏测试，非《苍岚》开发

> **项目边界**：这个分支只研究其他游戏《WorldBox》的 MOD。不是《苍岚·人生世界》的游戏、素材、热更新、发行、开发日志，更不准将 MOD 整合代码合并到《苍岚》的 `main`。只允许 `tools/worldbox-xianxia/**` 和这个分支的独立CI。

## 本轮有依据的关键诊断

复核用户上传的WorldBox 0.51.4候选APK和NeoModLoader 1.2.1.1 ZIP后发现：

- APK同时包含 arm64 `libmonosgen-2.0.so`、`libil2cpp.so` 和 `assets/Mono/Managed.zip`，其中包含 `Assembly-CSharp.dll`。
- ZIP仅包含 `NeoModLoader.dll` 和说明文本，**没有** `neomodloader_mobile.dll`。
- 静态文件存在不能证明启动时已经注入Mono/NML。实际 **DEVICE_PENDING**。
- 官方 NML 主仓库的 Android 安装指南以 **已有兼容Mono加载器**（例如 FusionCore）为前提，再让 `NeoModLoader.dll` 放置到 `<Persistentdata>/mods`。
- 官方独立 `WorldBoxOpenMods/AndroidModLoader` 则记载 **LemonLoader + `neomodloader_mobile.dll`** 的另一条路径。两条来源的方式不一致，不允许盲目混用，更不可凭空认定上传APK已安装其中之一。
- 社区2026年夏季有0.51.4加载失败的用户报告，不能保证当前0.51.4运行两款旧版桌面MOD。

**证据来源：**
- https://github.com/WorldBoxOpenMods/ModLoader
- https://github.com/WorldBoxOpenMods/AndroidModLoader
- https://worldboxopenmods.gitbook.io/mod-tutorial-en/packed/basicmod

## 本轮新实现

- `apk_loader_preflight.py`：给定自有APK+loader ZIP，只读静态验证Mono、IL2CPP、Managed、NML mobile资产、SHA256，写可信 `DEVICE_PENDING` 报告。
- `android_log_gate.py`：要求日志按序确认 NML初始化→本实验模组 `OnModLoad`→真实地图采样三种事件。日志缺失、乱序或发生错误均保留阻断；日志符合仅 `CANDIDATE_LOG_EVIDENCE_PRESENT`，不宣称手机功能验收。
- `test_v08.py`：8项独立回归（合成APK内容、误判防护、旋转、LOD、路径隔离）。
- `scope_gate.py` 从v0.7基线独立计算v0.8差异，并自动拦截对《苍岚》主游戏、官网、正式OTA和第三方二进制的侵入。
- 原v0.7 GitHub Actions连续10次 `failure`，每次 `0 jobs`。已诊断v0.7配置存在**未加引号的步骤名含 `: `**，YAML语法失败；v0.8工作流将该步骤名加引号修复，并要求源码单测+C# stub编译真实成功后才报告PASS。

## QA事实

本地 `test_v08.py` **8项全部通过**；用用户真实上传APK+加载器ZIP只读核验，结果显示兼具Mono/IL2CPP静态文件，缺 `neomodloader_mobile.dll`，未发现已成功启动的NML加载链。未编译安卓正式MOD，不伪称已进入手机。
- **WorldBox v0.51.4 NML入口**：DEVICE_PENDING
- **C#模组源码实际NML SDK编译**：SDK_PENDING（stub编译不算）
- **《战斗之神》1.0.5、《合理的世界》2.0.1原有MOD**：VERSION_COMPAT_PENDING
- **原版放大模糊全局替换**：NOT_IMPLEMENTED，现有Point只对自建观察窗口生效
- **近景伪3D观察**：SOURCE_CANDIDATE，未加载实机
- **四界、天气、雷劫、秘境、宗门、王朝、本地AI**：独立原型资料尚未接入这台安卓WorldBox
- **《苍岚》正式主游戏**：NOT_TOUCHED

下一步只有在获得真正Android NML启动证据后，才使用游戏内原始API进行资源LOD和微观观察运行测试。