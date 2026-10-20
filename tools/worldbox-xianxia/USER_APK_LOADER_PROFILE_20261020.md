# 2026-10-20 | WorldBox用户上传安卓安装包（只读静态审计）

> **独立第三方 WorldBox MOD 衍生实验；与原创《苍岚·人生世界》游戏开发、更新及发布完全无关。** 没有上传、修改或重新打包任何第三方安卓APK/DLL。

## 文件与版本证据

- 原始输入文件：用户上传的 `安卓版世界盒子(支持模组)_0.51.4 (1).zip`，内部APK名 `世界盒子_0.51.4(64位，支持模组).apk`。
- 内部APK字节数：`168526010`；SHA256 `c39817efa21e539fe61f318dc1ad4050b424c6120ab8ed384d94148f869c4bdc`。
- `AndroidManifest.xml` 的UTF16字符串池中出现 `0.51.4`，没有发现 `0.51.2` 字符串。**外包安装指南仍两次称“0.51.2”**，不能用这份说明文字断定APK真正版本或所有API兼容。
- APK里有 `lib/arm64-v8a/libil2cpp.so`、`lib/arm64-v8a/libmonosgen-2.0.so`、`assets/Mono/Managed.zip` 与 `assets/Mono/mono.zip`。共存证明文件存在，**不证明启动时处于哪条可用MOD运行时**。
- 外包说明文字推荐将 `NeoModLoader.dll` 放在 `Android/data/com.mkarpenko.worldbox/files/mods/`，另将MOD放在 `Android/data/com.mkarpenko.worldbox/Mods/`：这是针对该上传改版所声称的**传统Mono加载路线**。
- 与本轮公开官方 `WorldBoxOpenMods/AndroidModLoader` 新版移动NML路线（`NeoModLoader_mobile.dll` + `NMLMods`）**不同**。**v0.10在真实公开安卓SDK上编译的 `NMLMods` 候选，尚不能直接认定适用于该上传APK和其传统Mono路线。**
- 上传APK的外包说明文字还提到付费解锁等非MOD改动。本项目不会研究、修改或分发任何支付解锁/DRM绕过功能。

## P0分叉判断

**A. 如果用户当前游戏真实运行的是传统Mono方案**，应使用与其已经生效的`NeoModLoader.dll`对应的MOD源码/编译器入口；现有v0.10移动IL2CPP NML预编译DLL不应直接替换旧加载器或冒充兼容。

**B. 如果用户当前游戏另有已正常工作的LemonLoader+移动NeoModLoader2.1方案**，v0.10的`NMLMods/WorldBoxXianxiaObserver`预编译候选才有测试意义，但仍需备份地图、观察加载日志与启动稳定性。

## 已确认与未知

- ✅ 上传APK二进制静态结构、SHA、XML版本字符串、外包说明中的目录区分。
- ✅ 官方新版移动NML的源代码依据：`Paths.ModsPath = Combine(GamePath, "NMLMods")`、预编译模组检测根目录DLL。
- 🟡 当前手机到底加载的是传统Mono NML还是新版IL2CPP NML，尚无现场证据。
- 🔴 不能据静态检查声称任何第三方MOD已经进入用户WorldBox。
- 🔴 不能据此声称`v0.10`候选能直接在用户实际APK运行。当前唯一可信状态是 `ANDROID_DEVICE_PENDING`。

**下一步**应针对用户已安装的运行时定向编译，优先采用无需修改或重签现有游戏APK的安全方式。原世界存档必须备份并保留。