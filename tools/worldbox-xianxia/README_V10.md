# WorldBox 非官方万界仙侠 MOD 衍生实验 — v0.10

> **此工作与开发《苍岚·人生世界》原创游戏完全无关。** 此处仅借用同一个公开仓库的独立分支，研究另一个商业游戏 WorldBox 的第三方 MOD。禁止合并 `main`，禁止触碰苍岚游戏源码、资源、APK/PCK、官网、签名和更新通道。

## 2026-10-20 实装改进：真正匹配安卓 NeoModLoader 的预编译MOD目录

调查官方公开 `WorldBoxOpenMods/AndroidModLoader/services/ModCompileLoadService.cs`：
- 它通过 `Directory.GetFiles(modFolder, "*.dll")` 检测用户预编译模块；根目录有原始DLL时，`ModType`会变为 `COMPILED_NEOMOD`。
- 源码型 MOD 则扫描 `*.cs`，运行时编译后从内置 CompiledMods 加载。
- 安卓 `constants/Paths.cs` 显示独立资源目录为 `<GamePath>/NMLMods`；`NeoModLoader_mobile.dll` 是不同位置的 **加载器**，不能与用户MOD插件混为一谈。
- v0.9把真正编译好的 DLL 放在 `Compiled_CANDIDATE_ONLY/`，而 `mod.json` 位于 `XianxiaObserver/`，二者不在同一个 MOD 根目录。**这样的包并不是NML能够直接自动发现的已编译MOD**。
- v0.10修复了这一缺口：可交付ZIP以 `NMLMods/WorldBoxXianxiaObserver/mod.json` + `NMLMods/WorldBoxXianxiaObserver/XINYANSHUO_WORLD_BOX_OBSERVER_V07.dll` 的结构组织，元数据声明 `ModType=1`，同时包含校验表和 **DEVICE_PENDING** 声明。
- 根目录只有原创编译DLL，不含公开Android NML加载器、不含WorldBox APK，也不捆绑未经许可的用户提供第三方MOD。

## 编译与QA

`WorldBoxObserver.AndroidSdk.csproj` 在GitHub Actions使用真正公开的 Android `NeoModLoader_mobile.dll` 和 `Assembly-CSharp.dll`、Unity、IL2CPP引用程序集编译我们自有的观察器。源码中的假SDK桩**不参与**这个编译步骤。独立的版本回归跑Python测试并验证模型只读/路径隔离。

### v0.10 包内结构

```text
NMLMods/
  WorldBoxXianxiaObserver/
    mod.json
    XINYANSHUO_WORLD_BOX_OBSERVER_V07.dll
SHA256SUMS.txt
README_INSTALL_DEVICE_PENDING.txt
```

> 仅当用户已用与自己APK适配的 Android NML 正式引导程序，并确认`GamePath/NMLMods`确实可读取时，这样的目录结构才有意义。**尚未证明用户当前0.51.4安装包具备任何可用的NML启动链。** 此候选包不是APK，不可以点一下直接安装；绝对不建议覆盖已有WorldBox安装或删除存档。

## 未完成

1. **实机Android NML打开、游戏UI点击、观察层绘图**：未验收（无设备日志）。
2. **与合理的世界Frontiers、战斗之神Combat Gods的真正共存**：未验收，且原作者构建号可能不同。
3. **放大时高清资源切换、Worldfall第三/第一人称视角**：尚未在0.51.4验证。
4. **世俗王朝、四界、天气、雷劫、秘境、宗门及本地AI**：旧原型数据仍未接通游戏主循环。下一轮以先能加载为P0，不要谎报“都完成了”。

### 执行安全

先备份游戏世界，检查NML安卓兼容性和实际日志。永不修改或重新签名WorldBox商业APK；公开GitHub仅保留我们自己的代码和测试，不公开第三方模组二进制文件。
