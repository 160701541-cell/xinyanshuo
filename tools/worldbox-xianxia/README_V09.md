# WorldBox 万界仙侠 · 外部游戏 MOD 衍生实验 v0.9（2026-10-20）

> **本项目仅为其他游戏 WorldBox（安卓版0.51.4）制作非官方 MOD 兼容性测试。和原创游戏《苍岚·人生世界》开发没有关系。只借用它同一个公开 GitHub 的流水线工具，不修改《苍岚》main、原 Main、签名、PCK、官网、正式开发日志。任何WorldBox测试分支不得合并进main。**

## 本轮P0实质进展：首次接入真实Android NML编译依赖

1. 真实查证，用户提供的 `NeoModLoader_1.2.1.1.zip` 内的 `NeoModLoader.dll` **属于桌面说明的安装方式**，其文档提示放在 `worldbox_Data/StreamingAssets/mods`，不能自动当作新版Android加载器。
2. 找到独立 Android ModLoader 项目 `WorldBoxOpenMods/AndroidModLoader` 官方发布的 `NeoModLoader_mobile.dll` **2.1版（发布日2026-05-26）**。官方GitHub release SHA256：`9ed209cdc783ed26998d31e461d1bbd317c83aff7ed8eefe844ddb0878a19c6a`，大小 `20135424` B。URL：https://github.com/WorldBoxOpenMods/AndroidModLoader/releases/download/latest/NeoModLoader_mobile.dll 。此文件由GitHub Actions在临时工作目录下载和验证，**本项目不重新发布第三方加载器**。
3. 新增 `WorldBoxObserver.AndroidSdk.csproj`：从官方 `AndroidModLoader/android-assembly-dependencies` 的公开引用程序集获取 `UnityEngine.CoreModule.dll` / `UnityEngine.IMGUIModule.dll` / `Assembly-CSharp.dll` / `Assembly-CSharp-firstpass.dll` / `Il2CppInterop.Runtime.dll` / `Il2Cppmscorlib.dll`，配合官方Android NML v2.1构建 **我们的原创** `XianxiaObserverV07.cs`。**这里完全不使用自定义WorldBox假接口桩**。
4. GitHub Actions 运行ID `39380528609` 的 `android-public-sdk-compile` 子任务已确认 success。此前仅使用假SDK编译的v0.7-v0.8已提升为：**真实公开Android SDK编译过，但用户0.51.4 APK实际运行未验收**。
5. 增加独立CI成果包：原始Mod C#源文件+mod.json+用真实Android公开SDK编译出的原创MOD探针 DLL，**不包含外部 APK、WorldBox游戏DLL、NeoModLoader_mobile.dll及其他第三方文件**。GitHub Actions artifacts是测试候选，不是可直接点开安装的APK。

## Android加载器具体阻塞

- 安卓官方AndroidModLoader的安装引导为 LemonLoader → `MelonLoader/com.mkarpenko.worldbox/Mods/neomodloader_mobile.dll` → 经过启动后用于NML MOD的目录。不要把PC `NeoModLoader.dll` 随意替换到这个安卓目录。
- 用户的0.51.4上传APK虽然含 `libil2cpp.so`、`libmonosgen-2.0.so` 和 `assets/Mono/Managed.zip`，**这些不足以证明已配置LemonLoader/NML的启动bootstrap**。
- 社区有报告WorldBox 0.51.4的部分安卓加载方案崩溃；在本项目不能拿到实际设备日志前，状态仍然是 `DEVICE_PENDING`。不得自动重新签名用户APK，不得覆盖安装造成原世界存档丢失。
- 此前 v0.7 源码仍只读4方向伪3D观察，原版整个主地图放大清晰度未修改，UI/伪3D等都仍需安卓实机验证。缺少真实验证不得声称“游戏已整合”。

## 核验状态

| 验收层 | 状态 |
|---|---|
| 原创WorldBox NML探针 C#源码 | 已提交 |
| 官方移动版 NeoModLoader_mobile.dll SHA256验证 | 真实GitHub Actions已通过 |
| 原创MOD源码使用真正的公开Android WorldBox/NML引用DLL编译 | 已在GitHub Actions验证通过（依赖参考库不一定与0.51.4精确相同） |
| 离线隔离测试/不触碰《苍岚》原版 | 已通过 |
| MOD被用户安卓0.51.4的NML真实加载 | **DEVICE_PENDING** |
| 游戏内点击/伪3D渲染/天气/雷劫/秘境/王朝联动 | **DEVICE_PENDING/NOT_IMPLEMENTED** |
| 原APK本体和《苍岚》发布渠道 | **没有修改** |

工作流：`.github/workflows/worldbox-external-mod-lab-v09.yml`。官网、游戏、资源、启动日志互不冒充。