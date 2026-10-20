# WorldBox 第三方 MOD 衍生测试 v0.15 (2026-10-20)

> **这不是《苍岚·人生世界》的开发。** 仅修改公开仓库 `worldbox/external-mod-lab-v15-giant-qa` 分支的 `tools/worldbox-xianxia/**` 与 WorldBox 专属工作流。永不合并 main，不涉及《苍岚》的游戏源码、APK/PCK、官网、签名或热更新。

用户与Work分工已确定：**本助手只继续研发 WorldBox 第三方 MOD/游戏功能；Work 负责最终单个 APK 的私有整合、签名、安卓运行测试与交付**。

本轮完成：
- `GiantMapOptionsV11.DiagnoseMapApi()` 新增只读运行时诊断。检查真实 WorldBox 0.51.4 `MapSizeAsset`、`MapSizeLibrary`、`AssetManager.map_sizes`、原版 Titanic 预设 `size` 以及 `add` 参数类型；不给已有地图写入任何数据，不触发新世界生成。
- `XianxiaObserverV07.OnGUI()` 新增「尺寸API自检」按钮，并输出 `[XIANXIA-V15] MAP_API_READY/FAIL` 日志，供 Work 收集 **真正的安卓运行时证据**，解决此前仅对 SDK 编译、无法证明用户安装包支持 2048² 注册的阻塞问题。
- 保留 v14 双重确认的2048×2048候选，以及 v13 中文字体100%～175%缩放和 v12 性能保护。只在原WorldBox生成新世界的尺寸候选中操作，不改变已有存档。
- `test_v15_runtime_profile.py` 新增自动化回归，专门检查诊断功能只读、日志可观察、2048实验模式仍需显式确认。
- 独立WorldBox v15 GitHub Actions工作流；QA执行结果必须以最新实际日志为准。此文件不以编译成功冒充设备已验证。

**未完成：** 2048×2048实际生成、世界存档、在高密NPC/战斗情况下的性能与发热、所提供Android 0.51.4 APK真实加载器判断及Work的最终签名可安装一体APK均待实机验证。请勿发给用户未经验证的“安装即玩”APK。
