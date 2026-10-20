# 2026-10-20 WorldBox非官方外部MOD实验 v0.12

严格项目隔离：专用分支 `worldbox/external-mod-lab-v12`，仅可修改 `tools/worldbox-xianxia/` 与专属工作流。与《苍岚·人生世界》游戏开发、正版APK/PCK、官网与OTA完全无关。

已提交：ObserverFrameGuardV12.cs；观察器与GiantMapOptions条件联动；修复大地图按钮状态被采样覆盖的问题；独立C#性能守护测试 FrameGuardScenarioV12.cs（低FPS自动暂停、高FPS自动恢复、16x16仅高FPS测试、20x20默认阻止）；对安卓SDK源构建与传统Mono源码打包流水线相应增补。

待核：GitHub Actions v0.12最新测试和编译真实结论；用户Android 0.51.4实际MOD加载仍DEVICE_PENDING。不可将任何ZIP当APK；不得修改WorldBox或《苍岚》正式安装发布渠道。
