# WorldBox 万界仙侠 v0.5：三份上传MOD的隔离整合与第一人称路线

> **WorldBox 安卓0.51.4** 项目，不是《苍岚》的游戏开发。借用`character-pipeline`美术生产工具，仅处理 WorldBox 适配。此分支不发布任何第三方商业 APK、用户上传的第三方 DLL/源码或修改原《苍岚》OTA。

## 2026-10-20 源文件实查

- **Frontiers / 合理的世界 2.0.1**：RAR5，顶层 Steam 文件夹 `3820685932`；`mod.json` 为 `MIDNIGHT_FRONTIERS`，包含 `Frontiers.dll` + PDB；67项参数配置；角色阶级、王国城墙、城堡、编队、攻城逻辑。原包仅英文Locale；用户本地私有交付另生成 107/107 个键的 `Locales/cz.json` 简体汉化。
- **Combat Gods / 战斗之神 1.0.5**：RAR5，顶层 `3819684072`；`TURBO_SAKUGA`，`targetGameBuild=719`；305个C#源码及精灵/Locales；6级战斗等级、8流派、技能与决斗。**`Code/Compat/Worldfall3D.cs` 和 `Worldfall3DOverlay.cs` 已提供 Worldfall 第三/第一视角3D兼容机制**。
- **NeoModLoader 1.2.1.1**：上传ZIP仅 `NeoModLoader.dll` 和Windows安装说明，没有独立 `neomodloader_mobile.dll`，没有PDB。不可据文件名推断这个桌面DLL在安卓可用。
- **上传的0.51.4 Android APK**：静态发现arm64 `libil2cpp.so`、`libmonosgen-2.0.so` 及内部 `assets/Mono/Managed.zip` 中的 `Assembly-CSharp.dll`。共存**不证明实际NML装载成功**。
- 原v0.4像素候选共1794帧；另从真实96px建筑动画源导出 18 序列×8帧×32/64/96 三档=432 PNG。96px保留本来细节，32/64是缩小，不冒称上采样创造纹理。

## 核心成果与验证

本次本地生成私人交付包（含原用户的两款MOD完整文件、独立翻译、可选低特效配置、多级建筑PNG、相应哈希），**不公开用户上传的模组文件**。为防直接破坏已安装游戏，`candidate/XianxiaSprites` 未放入自动加载的 `Mods` 目录。

本地 7项文件/来源/哈希及4项语义桥接单元测试通过。没有安卓NML运行日志、实际加载与FPS测试，**不可认定已进入手机 WorldBox**。

## Android P0

1. 设备上先证实实验模式下实际NML按钮与日志；加载器文件的正确形式需和设备用的补丁方案配套。
2. 单独启用Frontiers，然后Combat Gods，留存日志与存档，排查世界构建719与0.51.4差异。
3. **优先评估作者提供的 Worldfall 安卓beta**：它已有第一人称附身和3D地图，Combat Gods有现成反射兼容模块。官方安装页：https://worldfall3d.com/install/ 。作者也说安卓版仍早期，不能把它宣传成已成功适配本APK。
4. 只有NML 0.51.4端可见、3D观察模式可见、缩放LODs切换真实生效后，再宣称真正游戏集成。世俗王朝等级、Combat Gods战斗层级与修仙境界分开，防止寿元/属性重复叠加。

**本阶段只有本地用户私有整合候选与公开兼容规范，没有可验证的APK发布。**
