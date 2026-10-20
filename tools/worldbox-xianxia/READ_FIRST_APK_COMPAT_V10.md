# 重要：v0.10 安卓两个MOD候选不能混用

**这个分支仅用于其他游戏《WorldBox》的非官方MOD衍生测试，与《苍岚·人生世界》原创游戏研发没有任何关系。** 无权改动《苍岚》原版游戏、安装包和签名发布链。

## 这次读取用户上传的实际安卓文件，发现了关键分歧

外层ZIP内部的 APK **AndroidManifest.xml确实含版本字符串 `0.51.4`**；外包中文说明却两次写旧版 `0.51.2`。不再仅凭说明误判游戏版本。

更加关键：用户提供的改版说明指出安装：

`/storage/emulated/0/Android/data/com.mkarpenko.worldbox/files/mods/NeoModLoader.dll`

并将MOD放到：

`/storage/emulated/0/Android/data/com.mkarpenko.worldbox/Mods/`

这属于**用户改版所声称的传统Mono/NeoModLoader入口**；不同于官方 `NeoModLoader_mobile.dll` 配套的 LemonLoader/IL2CPP 安卓分支，后者通过 `<GamePath>/NMLMods/` 发现用户模组。二者不应该相互覆盖或盲目混用。

## 因此本轮同时生成两种原创观察器候选（仅供已具备对应加载器的用户测试）

| 候选 | 目录 | 代码交付形式 | 对应平台 |
|---|---|---|---|
| **用户所给APK说明路线** | `Mods/WorldBoxXianxiaObserver/` | `Code/XianxiaObserverV07.cs` + `mod.json` (`ModType=0`) | **传统Mono NML**，由已存在的NeoModLoader在手机内编译 |
| 官方较新移动Loader路线 | `NMLMods/WorldBoxXianxiaObserver/` | 根目录原创 `XINYANSHUO_WORLD_BOX_OBSERVER_V07.dll` + `mod.json` (`ModType=1`) | 公开AndroidModLoader + LemonLoader/IL2CPP NML |

### 绝对不能据此宣称已经可玩

- 静态 APK 和来源说明**不证明用户实际安装的APK已启动任何MOD引导程序**。
- 本轮两种候选都没有在用户手机测试。
- 传统Mono版所用C#源码经过新版公开Android引用SDK编译并不保证在传统Mono NML中动态编译通过；要看游戏内加载日志。
- 新版移动IL2CPP候选在公开Android NML SDK上已编译，但不意味着可用于传统Mono入口。
- 目前能做的是合法安全的独立MOD研究；**不修改或重签用户上传的破解版APK、不分发游戏文件、不开发解锁付费内容代码**。
- 用户已存的世界要备份，不建议改动已安装的商业游戏软件和运行时。遇到不兼容，保留错误日志再定向修复。

本轮 GitHub Actions 所有真实编译和测试状态，以该分支最新成功的运行日志为准；不得因仅提交工作流就声称成功。