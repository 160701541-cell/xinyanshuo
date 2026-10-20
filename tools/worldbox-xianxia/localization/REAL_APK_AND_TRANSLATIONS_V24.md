# WorldBox 0.51.4 汉化组件：已核实的资源、兼容性与授权界限

日期：2026-10-20；仅限 **WorldBox·万界仙侠** 第三方MOD实验。与《苍岚·人生世界》工程、APK、PCK、网站及main完全隔离。

## 真实用户文件（当前工作环境只做了只读检查）
- WorldBox 0.51.4 用户上传APK：SHA256 `c39817efa21e539fe61f318dc1ad4050b424c6120ab8ed384d94148f869c4bdc`，约168.5 MB。该安装包含 `lib/arm64-v8a/libmonosgen-2.0.so`、`lib/arm64-v8a/libil2cpp.so`、`lib/arm64-v8a/libunity.so`，内嵌 `assets/Mono/Managed.zip` 有 `Assembly-CSharp.dll`，但**未发现** `NeoModLoader.dll` 位于该内层Managed.zip顶级目录。此只读证据无法决定究竟是哪个Mono/IL2CPP引导器工作，真实安装和加载仍未验证。
- 用户提供中文名称MOD归档 `0.51.+中文名模组ChineseName_1.5.1.zip`：SHA256 `094b856262a93f24f639774ae235058d2e5c035a8bf8e465264406e397094470`，有`ChineseName_1.5.1/LICENSE`为MIT许可，原作者一米/Inmny，`mod.json` GUID `一米_中文名`、版本1.5.1；包含人物、城市、国家、氏族、家族、文明、装备、宗教、联盟、战争等中文生成器/补丁。其自带说明主要描述**桌面WorldBox/NML安装流程**，不是安卓16直接可用的保证。该文件**不要作为二进制或源码直接推送到公开GitHub仓库**；交由Work以用户拥有文件进行私有加载测试，保留MIT署名。
- 尚未从用户APK私有Unity资源包中获得完整原版文本资源键列表。由于缺少适配资源提取环境，既不能宣称已经把官方语言资源逐项提取，也不能由这些散列资源文件名称反推出中文覆盖率。

## 已经存在的第三方0.51.x汉化资源（只提供出处，不在公开仓库复刻资源）
来源：`Worldbox-OWL/resource-index` 的`mods.json`，非本项目文件，具体版权与安卓兼容性均需核查。
1. **简单汉化模组修正** — 作者一米、半梦半醒，0.51.x，版本1.0.8；资料明确其针对原版可翻译游戏内容，**不负责人物名字和其他MOD汉化**。发布地址：
   `https://github.com/Worldbox-OWL/mod-resources/releases/download/v1.0.8-game0.51.x-20251214094821-32216d1b/0.51.%2B._1.0.8.zip`
2. **上帝模式翻译** — 作者素和晟睿寒海、半梦半醒，0.51.x，版本1.2.2；对调试面板/上帝模式部分选项提供中文与说明。安卓可用性、鼠标特定操作与其他MOD冲突待验证。发布地址：
   `https://github.com/Worldbox-OWL/mod-resources/releases/download/%E4%B8%8A%E5%B8%9D%E6%A8%A1%E5%BC%8F%E7%BF%BB%E8%AF%91-v1.2.2-game0.51.x-20260727042408/0.51.%2B.GodToolsInfo_1.2.2.zip`
3. **中文名模组** — 作者一米，0.51.x，1.5.1；用户已经提供一份归档，按用户提供的源文件与哈希为准。该MOD有MIT许可，但依赖加载链仍待查证。

## 冲突与版权原则
- 不能以“支持WorldBox 0.51.x”为由直接断言兼容**用户改版0.51.4安卓16APK**。Work必须先验证**安卓引导器真实加载路径**，对每个MOD分别测试启动、创建王国、城市及人物、重新读取存档和帧率。
- **优先复用**已有原版汉化和中文名生成器，不盲目重写他人代码。若已经加载中文名生成器，不要为同一个王国/城市再注册第二套动态命名补丁。
- **其他MOD自有英文界面**由本项目`RuntimeChineseOverlayV22`和`ChineseKeyPackV24`提供通用翻译适配：前者对可访问Text/TMP匹配中文，后者给真实本地化键注册精确翻译。不宣称对任意自绘界面、程序生成内容自动100%翻译。
- 没有检查授权的第三方发布归档不能直接复制进公开源码；Work只在合法授权范围内使用用户持有文件/资源，保留来源、版本、署名、许可证和哈希。

## 本轮源码集成
- `ChineseKeyPackV24.cs`：玩家自主导入 `XianxiaModStaging/zh_cn_keymap_v24.txt`，采用`真实语言键=中文译文`，限制512KiB/4000条，整文件校验、重复键拒绝，先检测NML词条及现有原版简中内容，避免覆盖已有翻译。**游戏内系统文件多选尚未开发，不能谎称可以直接批量选ZIP。**
- `NativeLocaleBridgeV23.cs`：`RegisterExplicitKeys`注册按真实键名翻译；提供**用户点击才触发**的`SwitchToChineseByUserTap`，通过反射验证`LocalizedTextManager.setLanguage(string)`并切换 `cz`，不在后台擅自改系统语言。此前的“登记原版中文”“刷新简中”保留。
- `ChineseTextTemplatesV24.cs`：对 `Population: 1,200`、`Level: 12`、`Health: 30/40` 等白名单数字字段做安全中文化，数字原值不变；不翻译包含人物/城市名、ID、URL和任意文本的字符串。
- 新功能已纳入NML公开SDK编译、Legacy Mono源码候选及可执行C#回归测试；**用户APK的真实Android16加载和中文覆盖率仍为PENDING**。

## Work下一步真实验收所需证据
(1) 对用户APK加载器做私有运行或静态检查；(2) 中文名/原版汉化/上帝模式翻译分别启停测试；(3) 统计并截图至少原版创造、外交、王国详情、人物属性、设置及MOD面板各类文本；(4) 测试所有中文字体不乱码/不遮挡；(5) 报告原版键翻译数量、漏译数量、英文专有名词是否正常；(6) 保存/读取老档及性能测试；(7) 只有签名APK安装启动成功才标可玩/已更新。
