# 2026-10-20 WorldBox 外部MOD测试实验 v0.10

**项目性质：第三方游戏WorldBox的非官方MOD衍生测试，和《苍岚》原创游戏的开发完全无关。**

- 继承 `worldbox/external-mod-lab-v09`，只修改 `tools/worldbox-xianxia/` 以及 v10 专用GH Actions流水线。
- 阅读官方 `WorldBoxOpenMods/AndroidModLoader/services/ModCompileLoadService.cs` 和 `constants/Paths.cs`，确认安卓 `NMLMods` 与根目录DLL才是NML自动发现编译模组的依据。
- 修复v0.9 `mod.json` 与预编译DLL分离的问题；新 `package_android_compiled_mod.py` 导出 `NMLMods/WorldBoxXianxiaObserver/`，自动放入基于真实公开安卓NML SDK构建的原创DLL、带版本声明的mod.json、SHA256。
- 本轮自动化额外增加预编译目录结构/阻断缺失DLL/错误GUID/错误构建号的回归测试。
- 编译与封装由独立分支 Actions 完成，仅公开自己的源文件，测试构建的原创程序集在Actions artifact中交付，不放到GitHub主源码。
- **P0：即使目录正确，设备启动链仍无现场证据。SDK编译通过不等于安卓运行。**
- 《苍岚》正式 main、游戏、官网、RSA、OTA、开发日志均未修改。
