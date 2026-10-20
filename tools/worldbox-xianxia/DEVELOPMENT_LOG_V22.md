# WorldBox·万界仙侠 v0.22 中文化优先专项

这是WorldBox第三方MOD实验分支，绝非原创《苍岚·人生世界》研发。用户明确要求先做原版完整汉化和其他MOD汉化，暂缓继续添加修仙玩法。

本轮实际新增 `localization/ChineseLocalizationV22.cs`：内置王国/城市/战争/外交/人口/特质/设置/模组管理器/错误状态等常用英文→简体中文精确匹配字典，含其他MOD常见术语；允许在游戏私有目录 `XianxiaModStaging/zh_cn_overrides.txt` 中按 `英文=中文` 添加至多2000条用户翻译，安全地只读加载，不改写游戏程序集。中文模组管理器添加「载入模组中文词库」按钮和条目数。翻译引擎已加入Android公开NML SDK编译项目及v22独立工作流，新增5项自动回归。

**关键事实限制：** 目前翻译引擎仅为词库查询API和游戏内加载入口，**没有钩住原版WorldBox本地化管理器，也没有拦截第三方MOD Text/TMP文本显示**；因此不能声称游戏已经全中文。要做到完整汉化，下一阶段必须取得WorldBox 0.51.4真实文本键表/语言资源，并在安卓NML SDK中验证本地化注册接口、动态王国/城市/人名中文命名及其他MOD的运行时翻译和性能开销。词库只能翻译已覆盖的条目，不能保证任意未知MOD英文都被翻译。

Work仍负责私有APK整合、签名、安卓16真机验收。不得上传商业游戏APK、密钥或其他MOD二进制到公开仓库。不得改动苍岚主项目。


---

## 2026-10-20 同分支持续开发记录：运行时中文显示、菜单指南、保留用户全部设定

### 先行自检与缺陷修复
- 检查v0.22原有自动化运行 **39425732146**：安卓公开NML SDK编译通过，私有APK通用检查器编译通过，但离线源码QA失败，原因是早期v21安全测试要求UI明确出现“尚未安装或启用”，而界面仅写“未执行安装或启用”。
- 已在 `ui/ChineseModManagerV21.cs` 修复中文提示，严格区分模组文件已暂存与已安装/已启用。该修复后的旧工作流曾在提交 `ba91eef6` 获得全任务成功（运行对应分支历史）。
- 任何CI成功都**不是**WorldBox APK已加载、汉化完整或Android16真机通过。

### 本轮实质新增代码（已提交本分支）
1. `localization/RuntimeChineseOverlayV22.cs`：在WorldBox实际运行时每5秒有限扫描已激活的 `UnityEngine.UI.Text` / `TMPro.TMP_Text`，以 `ChineseLocalizationV22.Translate()` 对**完全匹配**的英文UI文本替换为简体中文。默认开启，可关闭；关闭或模组退出时只恢复仍然等于本MOD译文的字段，防止覆盖游戏/其他MOD随后动态修改的文本。最大跟踪480项、每种控件检查1200项、首次解析后缓存类型、扫描异常限频记录。**此层面面向原版UI与其他MOD共用，未直接修改任何第三方程序集**。
2. `localization/OriginalMenuGuideV22.cs`：游戏内中文操作指南，分多页解释世界创建、地形、放置生灵、资源、王国外交、单位属性、存档、世界法则等常用功能，并有实时中文开关及扫描计数。页面明确标注是通用操作说明，**不冒充已经完成的原版逐项菜单汉化**。
3. `nml-observer-v07/Code/XianxiaObserverV07.cs`：在实际观察器循环中启动翻译扫描、关闭时还原，并加入「原版菜单中文说明」触屏入口；与中文模组管理器界面互斥防遮挡。
4. 三套 `tests/WorldBoxObserver.*.csproj` 都已纳入以上两个新的C#文件；正式独立工作流 `.github/workflows/worldbox-external-mod-lab-v22.yml` 将二者纳入遗留Mono源候选、NML编译候选以及分发测试包。
5. `tests/RuntimeChineseScenarioV22.cs` 和同名csproj：新增**可执行C#行为验证**，涵盖原版“Kingdoms”中文化、其他MOD的TextMeshPro“Mod Manager”中文化、未识别专有名词不强制改写、隐藏文本不扫描、动态文本刷新、关闭恢复、自定义覆盖词条优先级及卸载还原。此测试不取代安卓实机运行验证。
6. 本开发日志更新、隔离规则不变，仅 `tools/worldbox-xianxia/**` 和专用工作流可改；绝不涉及《苍岚·人生世界》主项目或将WorldBox实验合并到main。

### 现实覆盖范围与已知限制（必须保留）
- **并未达成完整汉化**。本功能只处理游戏中能被反射枚举、且原文完全命中词库的Unity UI Text/TMP文本；其他MOD采用IMGUI、自绘字体、特殊语言表、原版UI本地化API的文本、名称模板及未纳入词库的英文仍可能保持英文。
- 外部MOD可以不断更新文本，扫描时主动让出对其改变过的控件的控制；对于运行中新增的世界事件/分页文本需要继续采集、扩充词库。
- 运行时IL2CPP反射枚举在**用户持有的WorldBox 0.51.4 Android版本仍待真实设备验证**，不能把SDK编译通过当作可运行保证。CJK字体覆盖问题需要一同检查。
- 已注意到用户当前会话附件另有`0.51.+中文名模组ChineseName_1.5.1.zip`（作者一米，MIT许可）。文件内已有王国、城池、人物、文化、宗教等名称生成补丁。它与普通UI术语翻译**不是同一层面**：后续以**可选兼容接入**为主，避免同时给新建王国重复注入名称，也不把其源代码/全部词库未审查就公开复制。此压缩包中`mod.json`未明确声明与用户安卓NeoModLoader引导链的兼容性，因此实机兼容**未知**。

### 绝不能丢失的用户决策：天道、修仙和王朝城市规模
**P0：所有菜单、王国详情、建造、放置、外交、科技、世界法则及第三方MOD面板都必须有正确简体中文，并有“这是什么/怎么用”的短说明。** 先真正接入原版语言管理器，再讨论完成率，不能只靠有限文字扫描就标“完整汉化”。
**P0：玩家扮演天道；保留原版创造/放置生灵、资源、地形的能力并扩展到修士、灵兽、妖兽、灵石、灵脉、灵植、飞剑、飞舟、修仙宗门；新增内容不能只能在只读观察器里查看。** 使用原版放置系统和地图选点，不要另起一个无法放东西的玩具界面。
**P1：世俗王朝完整行政与聚落层级**：人类维持原版人类与王国演化；新增王朝→州/郡→府/县→城镇→村落的数据层级、城郊商路和人口账本，允许一个王朝拥有许多独立城池而不再只有几座小村落。分层人口近景实体/远景账本，禁止将百万人口全生成手机实物。
**P1：都城与皇城**：首都不是普通村庄标签，要有宫城、皇城、内城、外城、城外农田；皇宫大殿、官署、国库、禁军、城门和城墙对应实际建筑和事务。迁都、扩建、叛乱、攻城导致的王朝事件必须联动。
**P1：建筑等级**：建筑类型、等级、品质、损坏状态四个维度分开，升级需真实材料/资金/劳动力/时间，外观/纹理/规模/耐久/功能随等级改变；适用民居、市场、军营、城墙、皇宫、宗门、护山大阵。
**P1：多层世界空间**：独立人间、地下、云海浮岛、九天、地府/幽冥层，统一世界时间和人物身份，御剑、飞舟、洞府入口及传送阵允许真正跨层；高度不能只做背景图片，原版高度属性也不可被擅自当成立体碰撞系统。此系统尚未实现。
**P1：修仙世界生态**：普通动物小概率启灵→妖兽/灵兽；筑基起直接飞行消耗灵力、御剑更快、飞舟由灵石驱动；宗门优先山顶灵脉、家族靠近城池；护山大阵有阵眼、供能、敌我与破阵机制；境界每境界12层（历史v18暂含炼气十三层须后续纠正）。
**P2：世界演变**：王朝盛衰、修仙庇护/冲突、秘境、妖潮、州县财政、战争后勤、四季城建演替、材质和实际建筑等级，符合用户高质量要求。
**验收P0**：不得动《苍岚》main、官网和APK/PCK；Work负责拥有的WorldBox APK的私有集成、签名、Android16真机截图与安装验收，不能以源码通过或zip候选代替已交付可玩的APK。

### 后续分支工作交接顺序
1. 获取**用户这版WorldBox 0.51.4**真正的本地化资源接口和界面原始key，建立按页面覆盖统计，实际接管原版语言键表，避免英文仍存在。
2. 将其他MOD的文本/控件自动中文化扩展到IMGUI及安全的本地翻译包匹配；有冲突/无法检测须中文提示，不可虚报100%。
3. 原版天道工具菜单中加入可放置修仙单位/资源/建筑的真实WorldBox操作；确认可存档。
4. 构建王朝城市群→首都皇城→建筑等级原型，并完成单位/物品ID、城市账本、远景聚合模拟。
5. 云海浮岛、地下洞府、地府和跨层移动完成后再称“多层世界”。


---

## 2026-10-20 后续实作：原版真正的语言键登记 + 大规模菜单词库（同v0.22分支，没有新开遗失旧任务的分支）

### 已读取的事实来源与研发取舍
- 本轮先确认上一轮提交 `8b762441` 的GitHub Actions **39428356271全部成功**，但是只证明离线源码QA、公开SDK编译、候选包校验，并非用户的Android 16 WorldBox 0.51.4已成功启动。
- 阅读开源 **WorldBoxOpenMods/AndroidModLoader** 的 `general/LM.cs` 与 `api/ILocalizable.cs`：原生NeoModLoader语言入口为 `NeoModLoader.General.LM.Add(language,key,value)`，简体中文使用 **`cz`** 语言代码， `LM.Has(key,lang)` 可避免覆盖已有注册的其他MOD词条；`LM.ApplyLocale(...)` 会应用本地化，原版核心为 `LocalizedTextManager.instance._localized_text`。文档《Documentation-en/BasicConcept/Multilingual.md》与Android源码相互验证。**该开源NML接口研究不等于用户旧改版APK已包含此加载器**。
- 所有专有原版英文键名须从真正的 `LocalizedTextManager` 运行时字典读取，禁止凭空推断游戏内部资源键；对无法读取的Android IL2CPP字典提供反射枚举后备并明确显示不支持状态。

### 本轮真实代码及文件
1. **`localization/NativeLocaleBridgeV23.cs`**：新增可点击的“登记原版中文”。只读获取当前原版 `LocalizedTextManager.instance._localized_text` 中真实存在的键值，限定最多检查16000项、注册3000项；英文值或真实键名命中 `ChineseLocalizationV22.Translate` 才经NML `LM.Add("cz", key, chinese)` 注册；先通过 `LM.Has(key,"cz")` 避免覆盖其他MOD已经注册的汉化。C#的IEnumerator和IL2CPP反射GetEnumerator有后备路径。按钮 **不擅自强切用户语言**；若当前已是 `cz`，可点击“刷新简体中文”调用`LM.ApplyLocale("cz", true)`，否则提示到原版游戏设置手动选简中。原版本体的键、程序集、玩家存档不被修改。
2. **`localization/ChineseMenuGlossaryV23.cs`**：新增**580组**人工校订的英语界面术语候选及简体中文。按“世界生成/存档、天道工具/地形、王朝/皇城/外交、人口单位属性、城建/经济/建筑等级、MOD管理、修仙”七类覆盖；这些是词典，不是逐条提取自0.51.4游戏文件的全量键，需真实UI命中测试。`ChineseLocalizationV22.cs` 同步使用新词典，用户本地覆盖词条优先级最高。
3. **`localization/OriginalMenuGuideV22.cs`**：中文说明面板新增 `登记原版中文` 与 `刷新简体中文` 操作、报告扫描及登记计数，保留原版菜单解释和“实时中文”显示开关。
4. **`inspector/LocaleTypes.cs` 与 .csproj**：独立元数据只读诊断器，在GitHub CI使用**公开Android NML/WorldBox SDK参考程序集**检查`LocalizedTextManager`与`NeoModLoader.General.LM`的真实方法和成员名称，并向Work测试候选包附上`WORLDBOX_PUBLIC_LOCALE_TYPES.json`；绝不抓取或公开用户商业游戏APK二进制。
5. **`tests/NativeLocaleScenarioV23.cs` 与 .csproj**：可执行C#测试模拟原版真实`_localized_text`和NML公开LM接口，验证确实采用原版**真实key**、注册`cz`简体中文、已存在第三方MOD词条不覆盖、未知王国/人名不破坏、不强切用户语言、显式简中刷新成功；与v22旧文本组件翻译C#测试互相补充。
6. **`test_v23_native_locale.py`**：增加脚本层结构回归验证与580个新增英汉词条重复检查。
7. 三个安卓/语法项目已纳入2个新C#组件；`.github/workflows/worldbox-external-mod-lab-v22.yml` 已加入C#真实API契约测试、离线SDK本地化元数据校验、Legacy源候选和预编译NML候选的汉化源码完整性检查。仍旧只在当前独立WorldBox分支运行，不修改正式苍岚仓库main。

### 仍未完成（请未来所有GPT/Work先看并保留）
- **还不是完整原版或全第三方MOD汉化**：词典的准确覆盖率需由真实WorldBox 0.51.4菜单截图/语言资源键完整提取测定；部分原版专有本地化组件、Unity IMGUI、自绘、动态单位说明、未列入的英文文本不可由现有覆盖器/LM自动解决。
- 用户的**原版国家、城市、人物动态中文名**尚待验证附带《中国名》MOD或者接入独立姓名生成器，不能只通过翻译'Kingdoms'声称中文王朝完成。
- 原版放置按钮“天道创造”必须扩展真修仙单位、灵石矿、灵植、法宝与地形；当前还不能放置自定义新增实体。
- 世俗国家一城太小：按王朝/州/郡/府/县/城/镇/村多城模拟，首都建完整**皇城宫殿群**（宫城+皇城+内城+外城+城郊），人口远近景分层；建筑 **等级/品质/损坏状态**四维及真实可见升级、升级消耗材料资金劳动力时间，绝不能降成简单数值。
- 空间高度：人间、云海浮岛、地下、九天、地府作为多个真实层级，角色身份世界时间统一，御剑、飞舟、洞府、传送跨层，不能拿2D背景冒充真实浮岛。
- 生灵妖兽生态、炼气/筑基每境界**12层**、筑基御空需灵力、御剑更快、飞舟灵石供能、山顶宗门/城郊修仙家族/大阵需供能阵眼等原定需求全部保留；本轮按照用户优先级未继续扩散玩法代码。
- 下一执行优先顺序：① Work对用户持有安卓APK确认引导链及`LocalizedTextManager`/LM元数据 ② 全部原版菜单实际按页汉化覆盖统计和第三方MOD匹配测试 ③ 支持未翻译英文内容收集（隐私默认关闭）④ 真正天道放置 ⑤ 皇城和城市建筑等级 ⑥ 跨层世界。
- 签名/安卓实机验证继续由Work负责：**没有APK实机成功证据不得声称验收通过**，所有源代码保留在WorldBox独立分支，永不改动《苍岚·人生世界》及其官网、APK、PCK和正式日志。



### 本轮扩展：原版/第三方MOD漏译词条的私有采集与回归
- 新增 `localization/UntranslatedMenuAuditV23.cs`：**默认关闭**，只在玩家主动点击「开启漏译采集」后，利用原版和第三方MOD目前可访问的可见文本控件收集未命中英汉词库的疑似英文界面短标签，最多160条，重复合并，拒绝数字ID、邮箱/网址典型格式及长段代码。注意部分王国/城市/人物英文名称可能仍被收集，因此面板明确提示分享前必须人工检查。
- `RuntimeChineseOverlayV22.cs` 已对未译短标签调用 `UntranslatedMenuAuditV23.Observe`，中文菜单说明页新增「开启/停止漏译采集」及「导出漏译清单」，仅在玩家主动点击后本地写入私有 `XianxiaModStaging/missing_chinese_ui_v23.txt`，**绝不上传服务器或自动导出**。该清单用于将真实无法识别的英文原文补进下一版词库，而不是声称全覆盖。
- 新增`tests/UntranslatedMenuScenarioV23.cs`和csproj作为**可执行安全回归**，检查默认无采集、不会偷偷导出、用户主动选择才导出、已汉化按钮和非英文不误报、邮箱样式不收集、只写本机私有文件、内存清除；新增源码/检查纳入安卓NML、Mono候选以及专用CI。
- **CI进度真实记录**：在此项提交前，v22分支 `39431758726` 已通过原C#测试与公开SDK编译；最新追加漏译采集测试的运行仍必须另行查看、不能继承旧测试结果或宣称手机已验收。
- 原版菜单全量键抽取与中文覆盖率报告需要Work持有的实际WorldBox0.51.4 APK及安卓运行日志。公开SDK检查只是接口证据，不是专有本体翻译语料；现在有了**自主汉化+真实漏译反馈**的完整迭代基础，但尚未达成100%汉化。


### 当日最终CI核验与故障闭环（真实记录）
- 自动化曾因 **v23源码安全测试把注释中的“setLanguage()”误认为实际强制切换操作**失败，已改为仅检测真实方法调用；保留“不得未经用户操作强制改语言”的原约束。
- 在旧工作流 `39431893667` 发现两个新的P0打包阻塞：① 新增本地化元数据检查器后，旧 `inspector/MapTypes.csproj` 默认通配编译了两套顶层C#程序，导致`CS8802`；② `package_android_mono_source.py` 严格拒绝新漏译导出源文件中的`File.Write...` 字符串。已分别将原MapTypes.csproj限制为只编译`Program.cs`，并将明确授权的MOD私有词条报告改用`StreamWriter`输出，**没有修改/关闭原Mono源码包安全门禁**。
- 整体回归 `39432212199`，对应提交 **`f251ddaf`**：**三项工作均成功**（离线源码QA含Python与C#可执行场景、公开Android NML SDK编译及双格式候选包核验、私有用户APK通用检查器编译）。本结果可称**源码构建/安全测试通过**，**绝不等同Android 16手机可用/完整汉化/已生成交付签名APK**。
- 该成功回归后仅更新WORK交接说明和本日志；没有改动已通过的C#、Python功能源码、SDK编译项目或独立工作流。后续任务必须继续以本文件记录的P0/P1清单推进，不可把长远皇城、可升级建筑、天道放置、天空浮岛、地府误标为已实现。


---

## 2026-10-20 v0.24 同分支实际进度：用户一键简体中文、第三方MOD键值包、动态数值翻译、用户APK实查

**时间/分支**：与前轮完全相同的 `worldbox/external-mod-lab-v22-zh-localization`，绝不合并到main，也绝不修改《苍岚·人生世界》源码、官网、安卓APK176或PCK补丁。依据用户“先完整汉化、模组也要中文”和连续“继续”执行，未挪用游戏开发任务先写抽象文档。

### 真实代码增量（不是未执行的计划）
1. `localization/NativeLocaleBridgeV23.cs` 增加 **`SwitchToChineseByUserTap()`**：玩家在游戏内主动点击「一键选择简中」时先验证原版 `LocalizedTextManager.setLanguage(string)` 的公开反射签名，再请求切换到NeoModLoader所用简中代码`cz`；**不会在后台强制改语言**。还新增`RegisterExplicitKeys()`，按玩家/第三方MOD提供的真实本地化键注册翻译，检查NML已注册键，并在原版当前语言为简中且已有中文时避免覆盖，保留作者自己的译文。
2. 新增 `localization/ChineseKeyPackV24.cs`：实现按**真实key**导入 `Application.persistentDataPath/XianxiaModStaging/zh_cn_keymap_v24.txt` 中的 `key=中文` 翻译包（最大512KiB/4000条），先完整验证格式、重复键和非法控制字符，再注册NML `cz` 键；不修改原版程序集和存档。该程序只是**游戏内私有目录文件导入器，非安卓SAF批量选ZIP文件器**；不谎称已实现游戏内文件选取。
3. 新增 `localization/ChineseTextTemplatesV24.cs`：改善原版和其他MOD动态数值文本，例如 `Population: 1,200`→「人口：1,200」、`Level: 12`→「等级：12」、`Health: 30/40`→「生命：30/40」，只处理白名单字段加安全的数字后缀，避免误翻王国名/人物名/未知其他MOD消息。`ChineseLocalizationV22.Translate` 已实际调用该匹配器。
4. `localization/OriginalMenuGuideV22.cs` 已做真正的手机触屏汉化控制台：新增「一键选择简中」「导入中文键值包」，保留旧的中文开关、登记原版语言键、刷新简中、漏译采集/导出/清空、分章节原版菜单说明；调整按钮和状态区域布局。
5. Android真实公开SDK/语法三套工程及三个C#行为测试工程都已纳入这些汉化实现，独立 `.github/workflows/worldbox-external-mod-lab-v22.yml` 已同步更新NML预编译候选与Legacy Mono源码候选的实际包文件及断言。
6. `NativeLocaleScenarioV23.cs` 可执行测试新增：含第三方MOD键值导入、原有MOD汉化不覆盖、非法包整包拒绝、手动简中切换；`RuntimeChineseScenarioV22.cs` 新增数值菜单自动汉化、未知王朝名字保护、关中文后还原英文。
7. 增加独立 `localization/REAL_APK_AND_TRANSLATIONS_V24.md`，记录**对真实用户上传的原版WorldBox0.51.4 APK和中文名1.5.1 ZIP的本机只读检查**、哈希、插件来源、授权及Android适配障碍。

### 实际用户APK与中文名文件（本机只读，不公开商业二进制）
- 用户APK SHA256 `c39817efa21e539fe61f318dc1ad4050b424c6120ab8ed384d94148f869c4bdc`，包含ARM64 libunity、libil2cpp、libmonosgen，`assets/Mono/Managed.zip`内有`Assembly-CSharp.dll`，但内层顶级目录没有`NeoModLoader.dll`。**因此尚不能确认对应Android0.51.4加载链真的有NML**，更不能说已将其他MOD装进APK。
- 用户中文名MOD `0.51.+中文名模组ChineseName_1.5.1.zip` SHA256 `094b856262a93f24f639774ae235058d2e5c035a8bf8e465264406e397094470`，源包里有MIT LICENSE、`mod.json`，含王国/城市/单位/家族/装备/宗教等动态中文名源码和配置。**只适合做用户私有构建的可选依赖**，需验证0.51.4安卓加载及和其他命名补丁的冲突；不盲目复制版权资产到公开GitHub。
- Worldbox-OWL索引还列出0.51.x「简单汉化模组修正1.0.8」（原版文字）、「上帝模式翻译1.2.2」（调试/上帝模式部分中文和提示）、「中文名模组1.5.1」（中文名称）三类现成候选。**不等于已测试Android兼容**，其他两份授权未审查所以只记录出处及交给Work核验。

### 自动化真实验收
- 曾有v24中间提交CI红灯：`NativeLocaleScenarioV23.cs`测试输入文件的换行被写成文字反斜杠+n，使两条key读成一行。已改成C# `Environment.NewLine` 实际按行写入，测试后续通过。
- **绿灯 `39440588704`（提交`ff504ae7`）**：安卓公开SDK编译、Legacy Mono源码包与NML预编译MOD候选打包校验、离线Python及C#行为测试、项目隔离规则、私有APK通用工具编译全部通过。绿灯只是编译/模拟测试，不代表真机已通过。
- 后续仅增加本日志/候选MOD授权调研，不改变上述核心游戏运行代码；未来Work必须实际运行用户APK、检查显示/存档与批量MOD安装，收集带设备时间戳的截图日志，才能确认“完整汉化已交付”。

### 下一步P0（原有长清单继续有效）
1. Work用用户APK确认**真实Mono/NML/IL2CPP加载链**并整合原版可授权中文包、中文名、上帝模式翻译及本项目汉化候选；无设备证据不报APK完成。
2. 在原版「创造世界、天道工具、王国、外交、城市、人物、建筑、世界法则、设置、MOD管理器」逐页记录**已汉化/仍英文**，提交真实缺口，修复实际词条与渲染重叠；原版100%和任意第三方MOD100%尚**未**实现。
3. 保留后续天道原版放置能力扩展、世俗王朝多城行政、都城皇城、升级外观、灵兽妖兽、宗门大阵、多空间云海浮岛/九天/地下/地府/跨层交通、每境界12层+特殊十三层天劫机制；本轮**均尚未实现**，不能抢占汉化优先级，也不能遗忘。


---

## 2026-10-20 v0.25 同分支实际开发：原版内置简体中文证据、NML自动加载语言包、中文优先切换

**用户本轮指令：继续；继承此前“先完整汉化、原版菜单与所有MOD也要中文”、每次必须写入本分支开发日志。** 本轮并未创建新分支，沿用 `worldbox/external-mod-lab-v22-zh-localization`，禁用苍岚main跨项目改动。

### P0发现——用户的WorldBox 0.51.4 APK实际上已索引简体中文资源！
- 对 **用户本人上传的商业APK** `WorldBox_0.51.4_用户上传安装包_未整合仙侠MOD.apk` 进行了本机只读检查，SHA256仍为 `c39817efa21e539fe61f318dc1ad4050b424c6120ab8ed384d94148f869c4bdc`。
- Unity资源索引 `assets/bin/Data/globalgamemanagers` 中，可辨认**38种语言**，原版**简体中文 `locales/cz/*` 共70个资源分组**，英文 `locales/en/*` 也为70个分组，两者分组名称全部对应。含：`kingdoms`、`powers`、`resources`、`debug`、`creatures`、`ui_new_world`、`ui_buttons`、`ui_options`、`ui_tabs`、`world_laws`、`statistics`、`traits_units` 等。
- **重要严谨性**：这是Unity原始本地化**分类资源路径的存在证据**，不代表已经逐条解码与对比翻译的字句，不代表简中内容100%完备，更不代表任何第三方MOD自带中文。至少说明“APK完全没有原版简体中文”这个假设不成立；下一步应**优先真正选择原版自带`cz`语言，而不是重复发明与其冲突的原版文本替换**。
- 本地仅向用户本人生成只读数据报告 `WorldBox_0.51.4_原版简体中文资源_只读审计.json`，内容只有资源类别、数量、差异和以上限制，不含商业游戏受版权保护的文本；没有将APK或资源文件上传GitHub。
- 新增可复用 `localization/audit_apk_locales_v25.py` 与 `test_v25_apk_locale_index.py`：通过APK内`globalgamemanagers`长度前缀索引扫描语言名，不读取或复制实际TextAsset内容；可输出资源组覆盖报告；测试涵盖相同资源组、缺失组、异常APK与伪造非长度前缀，**不给虚假的100%汉化通过**。

### 真正随MOD发布的自动中文包（已修改可安装的MOD候选ZIP结构）
1. 新增 `localization/nml-locales/cz.json`、`en.json`：**38个具有唯一`xinyanshuo.wb.*`命名空间的真实NML本MOD菜单键**，包含中文模组管理器、原版菜单说明、一键选择简中、显示/恢复、缺译反馈、天道观察操作等。NML官方`BasicMod<T>`本身实现 `ILocalizable`，默认自动查找模组目录下的 `Locales/`，无需用户手动导入本MOD自己的中文文件。没有凭空伪造WorldBox商业本体的语言键，也不覆盖其他MOD所有权。
2. 新增 `localization/OwnLocaleLabelsV25.cs`：从真实NML `NeoModLoader.General.LM.Get` 读取本MOD自有的键；老加载器或缺少接口时保留清楚可读的中文后备文本。已真正连接到 `OriginalMenuGuideV22.cs`、`ChineseModManagerV21.cs`、`XianxiaObserverV07.cs` 用户可见按钮。
3. 改造 `package_android_compiled_mod.py` 及 `package_android_mono_source.py`：新增可选 `--locales`，对`cz/en`自有JSON词条数量/长度/命名空间进行安全检查，再把它们纳入**NML预编译模块ZIP**的 `NMLMods/WorldBoxXianxiaObserver/Locales/` 和**传统Mono源码候选ZIP**的 `Mods/WorldBoxXianxiaObserver/Locales/`，生成SHA256签名清单，未携带其他MOD的代码、商业APK或第三方DLL。旧pack函数默认行为保持兼容。
4. 在 **专属GitHub Actions** `.github/workflows/worldbox-external-mod-lab-v22.yml` 中，真实打包时指定 `--locales`，检查两个语言文件包含所要求的本MOD菜单键、预编译候选ZIP条目总数由4增为6、Mono源码候选确实包含两份Local​​es和汉化源码，生成自检工件。
5. 新增 `test_v25_nml_autoload.py`：以模拟PE结构做真实ZIP打包验证，检查`Locales/cz.json`和`en.json`的文件路径、翻译键一致性、拒绝伪造第三方命名空间、源码包不得带DLL、GUI实际调用本地化适配器；C#`NativeLocaleScenarioV23.cs`还新增模拟NML`LM.Get`真正从注册字典返回文本和中文兜底检查。三套公开SDK/语法构建都已引用新适配器。
6. 更新 `nml-observer-v07/mod.json` 版本为 `0.25.0-chinese-test`，保留唯一MOD GUID和WorldBox构建号725，并**明确标注不是完整汉化、不是签名APK、真机尚待验证**。

### 修复严重的汉化优先级缺陷
- 之前「一键选择简中」会**先从当前英文翻译词典推导出一批中文并注册NML，再切换原版`cz`**。即使有原版自带完善的中文，也可能被我们猜出来的译文所遮盖，导致反而更差。
- 已调整为 **优先只调用 `LocalizedTextManager.setLanguage("cz")` 请求启用原版内置中文**，再由NML常规自动加载本MOD`Locales/cz.json`。仅对真正发现的英文漏译使用可选中文覆盖，不再在一键切换时无条件预先登记大量词典。此行为有源码/合约测试，尚需真机检查原版切换按钮路径与中文显示。

### 目前事实状态/CI
- 自有中文词典与NML自动语言包、ZIP打包、单击切中文入口已提交该WorldBox分支，不是单独设计文档。
- **测试绿灯示例**：`39443939799` 整体通过（自动加载本MOD中文JSON包和ZIP布局的源码），以及后续源代码/语言资源审计的流水线（以最新实际Actions运行结果为准）。
- ***没发生的事情***：没有签名/发出新的商业WorldBox APK，没有用户手机NML引导链的真实日志，没有拿到原版完整TextAsset键与内容差异，没有对其他MOD动态英文都成功中文化的证据，没有手机创建/保存/重载世界的回归。严禁声称完整汉化、Android实机通过或全部MOD兼容。

### Work/后续开发固定顺序与保留设计
**P0**：先按用户APK真实语言入口将`cz`简中启用 → 验证原版全部创建/神力/城市/王国/外交/人物/建筑/设置菜单实际覆盖 → 可合法使用的中文名/上帝模式/其他MOD逐项兼容 → 漏译反馈与中文字体/字号/遮挡/性能验收。手游内MOD批量导入与兼容检测仍待Android文件系统授权与真实加载链适配。
**P1不丢失**：天道真正可放置小人、灵石、灵植、妖兽、修士、宗门等新增实体；更大的王朝多城/行政州郡府县，皇城、宫殿群及真实可升级建筑，天空浮岛/九天/地下/地府的可运行独立空间层级、跨层飞行/飞舟/轮回；人类世俗王朝保持原版国政，筑基能飞、每境界12层与天赋超凡特殊13层天劫公告，所有用户既定开发规则仍有效。以上未完成的游戏能力须在后续汉化验收后以可玩代码实现，不能写成完成。


### v0.25 最终候选包实际产物、QA绿灯与交付界限（更新日志追加，不替换历史）
- 本轮专属GitHub Actions **`39445362153`**，对应源码提交 **`4c288ffd`**，**三个独立作业全部成功**：offline-source-qa（88项Python/多个C#可执行场景及代码安全测试）、android-public-sdk-compile（实际公开NML/Unity/WorldBox SDK编译、两类MOD压缩包结构检验）、private-user-file-apk-inspector（用户私有构建工具编译）。前一批CI曾因为将MOD描述遗漏英文 `third-party` 违反旧安全声明测试而失败，已恢复明确第三方独立MOD身份并修复，不能将红灯留待下一轮。
- 对应Actions实际生成并下载的两个文件已经作ZIP CRC/语言包路径检查：`WorldBox_万界仙侠_v0.25_中文_NML预编译MOD_待实机.zip`（41,915 B，SHA256 `379e28dcec2db44492ac1774a1017855cb990f0858dab33499b1ec3fdeb88e0b`）；`WorldBox_万界仙侠_v0.25_中文_传统Mono源码MOD_待实机.zip`（46,946 B，SHA256 `9a2ec2e3795ca08c2afbf5f35d44e97bdbaeb459efc69e616e21985cc4da39c4`）。前者包含NMLMods下单个真实SDK构建DLL和`Locales/cz.json`、`en.json`；后者仅是旧式NeoModLoader源码候选。**这两个是MOD候选ZIP，均非完整游戏APK；原版游戏可能还不支持现有加载链，安卓16手机未运行验收。**
- 用户侧额外本机只读审计JSON：`WorldBox_0.51.4_原版简体中文资源_只读审计.json`，证实用户APK内已有`cz`原生中文分类路径70个。工程现在应优先尝试原版设置切换简中，证据不足时不另造并声称完整原版中文。
- **后续最高阻塞（红）**：用户真实WorldBox 0.51.4 APK能否运行哪种NML加载器；只有验证后才可私有整合并产生实际已签名可安装APK，必须实机菜单截图/覆盖率/存档/性能QA。**下轮不要继续无限增加相似翻译词典，优先验证真实中文切换及安装路径。** 与《苍岚》隔离仍是最高规范。


---

## 2026-10-20 v0.26 同分支P0汉化真机诊断与误报修复（代码已提交，安卓待验）

- 基线：2026-10-20 GitHub Actions `39445362153` 的v0.25三项离线作业成功，但只有两个MOD候选ZIP（41,915 B/46,946 B），**并没有交付签名Android APK**。
- 修改 `localization/NativeLocaleBridgeV23.cs`：增加 **`VerifyCurrentLocale()` 真正运行时只读核验**，读取实际 `LocalizedTextManager.instance.language` 与当前 `_localized_text`，最多2000条且150毫秒预算，统计含汉字/拉丁字母/其他文字的样本量。没有导出任何原文、专有游戏资源、人物名字、玩家存档；取样并非汉化完成率。
- 修复 `SwitchToChineseByUserTap()` 之前「setLanguage反射调用没有抛异常即回报请求成功」的验收误报：现在调用后**读取真实语言码**，若仍不是 `cz` 必须显示「结果未确认」；若为cz也必须逐页真机检验原版+第三方MOD界面。
- 修改 `localization/OriginalMenuGuideV22.cs` 第二排为五个触屏按钮，新增「核验简中」用于现场查看实际语言码与当前活动字典，原来的导入包、漏译采集、导出、清空均保留。
- 修改 `tests/NativeLocaleScenarioV23.cs`：执行模拟管理器的真实词条计数测试、语言切换被忽略的误报拦截测试，并保留旧中文键/第三方MOD不覆盖/离线导入测试。上述都是**实际代码和可执行回归测试**，不是新造一个翻译词库。
- 已经查到用户本人上传的 APK 与两份MOD候选被安全保留在用户文件库；原APK静态证据只说明存在Mono/IL2CPP及原生 `cz` 资源，不能据此推断加载器确实运行。**本轮未做Android设备连接、签名、安装，不宣称完整中文或APK成功。** 后续仍按完整汉化→私有APK整合及真机验收→天道放置→多城皇城→建筑等级→浮岛地府的既定次序推进。
- 仅WorldBox隔离分支 `worldbox/external-mod-lab-v22-zh-localization`，不修改《苍岚》main、官网、游戏发行代码/安装包或开发日志。本提交触发的CI要查当前新运行号后才能评价。


### v0.26 功能提交后的最新CI闭环和本机用户私有输入审计
- **真实功能提交**：`d6c5dd8ef912dfb2a343051e1b7cdcac22d4fffa`；对应 Actions **`39448677637` 三项作业全部成功**：`offline-source-qa`、`android-public-sdk-compile`、`private-user-file-apk-inspector`。证明新C#真语言诊断、忽略语言切换回归及SDK/候选打包仍过离线测试。**不是Android16设备安装通过**。
- 本轮安全地从用户文件库实际取回原APK和两份v0.25 MOD ZIP，仅做本地字节哈希、ZIP CRC、资源分组和文件清单检查；原APK SHA256 `c39817efa21e539fe61f318dc1ad4050b424c6120ab8ed384d94148f869c4bdc`，原生`cz`和`en`资源分组均为70。无NML程序集出现在APK内`assets/Mono/Managed.zip`的顶层清单，**但无法凭此排除外部运行时注入**。候选ZIP CRC均无坏项且自身仍非APK。
- 同时实查用户上传的`模组装载器NeoModLoader_1.2.1.1(适用于0.51.+)(1).zip`：仅有`NeoModLoader.dll`和安装说明，说明明确教用户放至`worldbox_Data/StreamingAssets/mods/`（桌面端路径）；不包含`NeoModLoader_mobile.dll`。**不能把这个独立包冒充已经验证适用于用户Android16 APK的移动NML。**
- 本机只读QA产物`WorldBox_v026_用户APK与汉化加载器_私有只读审计.json`保存在当前ChatGPT工作输出中，**未加入GitHub、未上传游戏二进制、未制作/重签/安装APK**。当前P0唯一真实红灯仍是设备加载链及APK私有集成验收。之后才能进行真实汉化覆盖统计；玩法路线不变。


---

## 2026-10-20 v0.27 原版简中不覆盖修复 + 真实画面汉化统计 + 安卓静态Loader调查

**实际已提交功能代码，且真实GitHub Actions校验成功。** 当前研发分支仍为 `worldbox/external-mod-lab-v22-zh-localization`，全部修改只在 `tools/worldbox-xianxia/` 内。原《苍岚·人生世界》main/官网/Android APK176/PCK零修改。

### 优先修复P0：杜绝“切换中文后反而被词典覆盖”
- `localization/NativeLocaleBridgeV23.cs`：`RegisterActualKeys()`现在仅在原版实际语言码 **cz** 时允许自动登记已经确认仍显示英文的当前语言键；如果处于en或无法确认，**拒绝从英文表猜测并覆盖尚未加载的原生中文**。在cz时还跳过现有汉字译文，并继续保留其他MOD的既有NML翻译。
- `OriginalMenuGuideV22.cs`按钮从「登记原版中文」改为更准确的「补齐简中漏译」；`nml-locales/cz.json`、`en.json`两个真实打包语言文件同步。
- `tests/NativeLocaleScenarioV23.cs`新增自动化验证：当前英文必须拒绝盲目登记、原版中文「王国」不可被我们的「王国列表」词典替换、实际简中下尚未翻译的第三方MOD标签才可补齐、其他作者翻译不覆盖。并保留v26修复的语言切换无效误报测试。

### 运行时界面取证而不是虚报“完整汉化”
- `localization/RuntimeChineseOverlayV22.cs`每轮5秒受限扫描后返回**目前激活且可被Unity UI.Text / TMP_Text读到的**中文、纯拉丁文字及其他文字数量；对已经翻译过的可见组件也计数，而不是只统计本轮新翻译的数量。
- 汉化控制台明确提示抽样**不含IMGUI/自绘和完整原版语言资源**；不保存文本、不联网、不统计隐藏UI，也不把当前屏幕数字说成整个游戏汉化覆盖率。
- `tests/RuntimeChineseScenarioV22.cs`加入C#回归：4条中文+1条未翻译人名的可见画面计数、隐藏组件不计、重扫描不漏计、关闭后不显示陈旧计数。不会把人物姓名强翻译。

### 新增用户APK静态分析工具（仅公有源码、无商业文件）
- `private_loader_audit_v27.py`新增只读审计：从用户自己的APK检查ARM64 Mono/IL2CPP共存、内嵌Managed.zip是否有Neo/Melon/Lemon/Fusion引导程序集、DEX是否有加载器名称、另行提供的NeoModLoader ZIP究竟含PC DLL还是移动DLL及说明是否PC路径。仅返回布尔值、加载器名称与SHA256；不导出游戏文本/程序集。
- `test_v27_private_loader_audit.py`用**完全合成APK/ZIP样本**验证：Mono+IL2CPP存在不代表引导成功、就算DEX出现某加载器字符串也不代表兼容、无效文件必须拒绝，绝不将用户商业APK送GitHub测试。

### 真实用户文件本机只读分析结果
- APK SHA256：`c39817efa21e539fe61f318dc1ad4050b424c6120ab8ed384d94148f869c4bdc`，包含ARM64 Mono、IL2CPP与`assets/Mono/Managed.zip`内的`Assembly-CSharp.dll`。
- APK内部Mono程序集文件名**未发现**NML/MelonLoader/FusionCore等装载器程序集；classes.dex / classes2.dex / classes3.dex / classes4.dex中这几种加载器的ASCII名称**未命中**；APK其他归档路径也没有这些加载器文件名。此阴性结果**不等于证明玩家手机运行时无法动态注入**，还必须以真机证据决定。
- 用户所给`模组装载器NeoModLoader_1.2.1.1(适用于0.51.+)(1).zip` SHA256 `a17bb4beccf7f186ef19aa30e2f6308499c08d00c97d478400a6cc434d002721`，内部仅含`NeoModLoader.dll`与桌面目录安装说明，未含`NeoModLoader_mobile.dll`。不可据此声称已经给用户Android 0.51.4安装好了移动NML。
- 报告在当前用户私有输出`WorldBox_v027_安卓加载器静态审计_私有.json`，**未公开商用游戏二进制、密钥或其他MOD文件**。
- GitHub Actions **`39451044479`**（保护原版简中）、**`39451248727`**（当前可见汉化统计）、**`39451407384`**（Android静态loader审计）全部三项作业绿灯；这仅是离线单测、真实公开SDK编译与MOD ZIP候选打包，**不是安卓16设备安装验收或私有整合APK**。
- **P0红灯与后续顺序不变**：由Work或可访问用户设备的私有工作环境确认真实Android启动链→原版内置`cz`逐页截图→其他MOD许可/冲突汉化→私有APK构建签名及真正手机安装/存档/性能验收。完成后才按约定依次实现天道放置、多城王朝、皇城、建筑等级、浮空仙岛、地府。


### v0.27真实MOD版本号与候选包记录
- `nml-observer-v07/mod.json`版本号已经随真实代码增量正式升为 `0.27.0-chinese-device-pending`，保留原GUID和构建版本725。先前同系列ZIP曾仍标v0.25的Manifest；当前要求ZIP内`mod.json`与源码/README版本一致才当作**v0.27候选**。
- 同版新构建 **`39451867361`** 在Manifest版本号提交后自动触发；是否全部通过必须以实际Actions结果为准，不能继承此前通过的ZIP打包状态。**此项依旧不是安卓手机安装/签名验收。**


### v0.27 带正确版本号的真实MOD构建/CRC/CI最终闭环
- Manifest已更新为`0.27.0-chinese-device-pending`，最新同代码构建测试`39451867361` **三项作业全部成功**（Python+C#场景、真正公开Android NML SDK编译及MOD格式双路线、私有工具编译），仅文档追加后的`39451969938` **同样三项作业全部成功**；均非安卓实机通过。
- 实际拉取Actions生成的嵌套ZIP，逐个运行ZIP CRC、解析包内`mod.json`确保版本确实为`0.27.0-chinese-device-pending`，其中传统Mono源文件核实包含原生简中非覆盖安全门禁；新版NML根目录仅一个SDK编译DLL并带`Locales/cz.json`和`en.json`。
- 真实v0.27独立MOD ZIP（非APK）：`WorldBox_万界仙侠_v0.27_传统Mono源码MOD_待实机.zip` 48,547字节，SHA256 `f5ebde042db9edf373a1f78972a8faa54e732517e28a4e822b6cad02412fd2e6`；`WorldBox_万界仙侠_v0.27_安卓NML预编译MOD_待实机.zip` 42,943字节，SHA256 `75dfa8e734d70ce3350951332e0b3ab1e649059f31c7537c4e4eabc9574c0bda`。均已过ZIP CRC；两种安装路线不应混用。
- **状态严格不变：**这是两份测试候选MOD，不是完整、签名、已安装或手机验收的WorldBox游戏APK。当前唯一P0阻塞是用户Android16真实MOD加载器引导链与后续私有构建/现场验收。Work按交接文档执行，不动苍岚main。


---

## 2026-10-20 v0.28 私有安卓整合候选：基于用户已上传 v18 引导实验APK真正嵌入 v0.27 Mono 汉化MOD

### 本轮关键新事实（纠正只盯用户“原始0.51.4 APK”的旧阻塞）
- 再次追踪用户文件库，发现用户**此前已经提供** `WorldBox_Xianxia_v14_Android_Test.apk` 与 `WorldBox_Xianxia_v18_Cultivation_Test.apk`；不是只能使用没有引导器的原始APK。
- 实际对两个历史私有APK做字节级只读差异：v14已有新增 `classes5.dex`，且 `assets/Mono/Managed.zip` 相比原始APK多出 `WorldBoxXianxiaMonoBridge.dll`、改动 `Assembly-CSharp.dll`。**v18保留上述引导尝试**，并通过 `assets/worldbox-xianxia/v18/install.json` 列出714个可供部署的资源，内含 `files/mods/NeoModLoader.dll`、旧版NML依赖及CombatGods/Frontiers等资源。DEX字符串有 `MOD_DEPLOY_BEGIN` / `MOD_DEPLOY_OK`，Mono Bridge字符串有 `NML_BOOT_FAILED` / `NML_ASSEMBLY_LOADED`。
- 这表明历史v18确实**已编写安卓侧Java文件部署尝试与Mono加载入口**，与“原始用户APK没有嵌入加载器”不矛盾；但**静态代码/标志符仍非设备上NML成功运行的证据**。这使得先用已有v18做私有汉化实验成为可操作的途径，无需向公开仓库上传游戏APK或再重新研究引导注入。

### 本轮新增可复用源码（已提交GitHub本分支）
- `private_stage_mono_v28.py`：**只操作用户自己提供的既有v18实验APK副本**。必须先看到 `classes5.dex`、`WorldBoxXianxiaMonoBridge.dll`、明确的 `install.json` 才继续；接收本仓库已通过CI打包的传统Mono源MOD候选ZIP，仅嵌入所需18份`Mods/WorldBoxXianxiaObserver/`原创源码/词库；给每份附SHA256/大小并写入新版install清单，把build_token从v18更新为v28防止已有部署缓存跳过；不碰已有WorldBox游戏程序集、DEX或Unity资源，并移除旧失效签名供私有重签；zip-slip、重复路径、尺寸和正确MOD GUID/格式均有阻断。**这个工具只准备APK，不自行保证签名/安装。**
- `test_v28_private_stage.py`：仅用自己构建的合成虚拟APK与虚拟MOD文件，自动覆盖旧签名清除、新部署记录、修改token、保留既有bootstrap、无bootstrap严禁做“空壳整合”、zip路径穿越阻断；没有将第三方内容发布到GitHub。
- 功能增量提交 `c61ecd5d0a0303dbb4f8c86369dc9b91b0a6288a`、测试提交 `f0564f0c8bb49dbdf298a086b17870e650cbd6aa`；其中 **Actions `39454679404` 的三项任务全部成功**（离线源测试、公开Android NML编译/候选包、私有APK工具编译）。**该CI不包含用户商业APK**。

### 本机私有APK真实整合与签名证据（**候选可验证，不能冒充实机可玩**）
- 输入：用户自己的 `WorldBox_Xianxia_v18_Cultivation_Test.apk`，187,773,264字节，SHA256 `b415bf01ccb17c4503cdb51f544127caa8afe28de99ade6d8580b57463b937c5`。
- 增量源MOD：v0.27传统Mono包 `f5ebde042db9edf373a1f78972a8faa54e732517e28a4e822b6cad02412fd2e6`，新增18个实文件在旧v18 APK内部`assets/worldbox-xianxia/v18/Mods/WorldBoxXianxiaObserver/`，部署清单从714项增至732项，build token变为 `v28-zh-f5ebde042db9edf373`。
- **真实生成并由Android apksigner测试证书签名**：`WorldBox_WanjieXianxia_v0.28_Private_Android16_DEVICE_PENDING.apk`，189,287,005字节，SHA256 `9efa49f98e92921f7ee8b9341f14b68b39d426323bc0a8cf25d8acc41e6cc822`。APK完整ZIP CRC通过，v1/v2/v3签名验证全通过。签名证书SHA256 `70d2cd47f69dc29d7126597b166521e68b4d7da3525ba44d070ad8e0137ea846`（本地测试密钥，不加入仓库或公开分享）；`classes5.dex`、`AndroidManifest.xml`、`assets/Mono/Managed.zip`及原版`globalgamemanagers`的CRC与v18输入完全相同。
- 输出安装包保留v18实验包名 `com.xinyanshuo.worldbox.lab13`，与原始 `com.mkarpenko.worldbox` 不同；**测试签名与历史lab13签名可能不同，不能保证覆盖安装**。如已存在lab13，先备份所有存档，绝不直接强制卸载用户游戏。
- 真实验收缺口：当前会话**无法访问用户PKR110 Android16手机和ADB日志**，没有实际执行安装、启动游戏、证明v18引导成功、对比全页面中文、触发MOD行为、存档/存读回归。此版本须准确称为“**已签名的私有整合APK测试候选**”，不是“实机已经可玩/汉化100%”，任何安装/加载结果由设备实际验收决定。
- 私有完整报告：`WorldBox_v028_APK私有整合静态验收报告.json`；APK及测试证书存留当前私有工作空间，不向公开GitHub发商业APK、密钥或旧第三方MOD二进制。
- 下轮优先从**这份真正含18份MOD代码的私有APK**取得真实设备启动/装载/汉化逐页证据后修复失败，不得退回无限只产源码ZIP。后续天道放置、王朝多城、皇城、建筑升级、仙岛、地府依既定顺序推进；与苍岚main严格隔离。

---

## 2026-10-21 用户要求先上传仓库：v0.28公开源码/私人APK边界
- 本轮实际在 `worldbox/external-mod-lab-v22-zh-localization` 提交公开版本清单 `tools/worldbox-xianxia/releases/v0.28/PUBLIC_RELEASE_MANIFEST.json`、README、发布隔离单测，并把v0.28私有APK制作脚本、单测及公开版本清单装入专属Actions候选工件。仓库源代码已经可从GitHub查看，正式`main`、苍岚游戏/网站/PCK不改。
- 用户上轮取得的完整、已签名 **v0.28私有整合APK** 实际已在ChatGPT工作区，SHA256 `9efa49f98e92921f7ee8b9341f14b68b39d426323bc0a8cf25d8acc41e6cc822`、189287005字节、包名 `com.xinyanshuo.worldbox.lab13`；公开GitHub仓库不适合在未经商业游戏重新分发授权的情况下上传WorldBox APK、第三方MOD二进制或签名密钥。GitHub版本清单只公开可验证摘要，不含APK字节。
- 工作流新增自动化上传前检查确保v0.28公开候选工件没有APK或签名密钥；`test_v28_release_publication.py`离线验证状态始终为DEVICE_PENDING，不冒充设备通过。
- P0仍需真实Android16 NML装载链、简体中文逐页截图与存档验收。不得将GitHub源码工件当作安装APK。


## 2026-10-21 00:34 Asia/Shanghai — v0.28 用户实测：可启动，但自有功能均未见，P0未通过

用户原话：“目前安装包能正常进去但是根本就没有我们做的任何东西”。这只确认启动，不确认MOD加载；自有功能可见性/可用性验收失败，不能继续笼统标记为等待用户安装。

本轮只读检查提交194cec59535784024917f1d6fbea8d729b6278ab、完整交接文档、本日志、private_stage_mono_v28.py及XianxiaObserverV07.cs。确认：v0.28整合脚本将18份源码/JSON/TXT加入旧v18部署目录、改install清单和token，明确不重新编译Mono Bridge、不修改游戏启动钩子、不编译新MOD；现有预检只检查桥文件和classes5.dex存在，不能证明Android运行时执行桥、NML成功初始化、源码MOD编译成功或OnModLoad/OnGUI执行。文件嵌入成功不得等同功能整合成功。故障具体断点尚待实际运行日志，不能无证据断言是某一种加载器问题。

源码另外存在明确功能缺口：本分支XianxiaObserverV07的修炼仍标注“本次运行内，暂不保存”；原日志列出的天道放置、皇城、多城、建筑升级、跨层空间也尚未实现。即使修复加载，也不能宣称这些玩法已完成。十二层/极高天赋冲关异变进入隐藏十三层、天劫和世界消息仍为必须实现规则，不能沿用普通十三层上限。

当前执行环境由平台标记unavailable，无可用APK构建终端、手机或ADB；本轮无法重新读取实际v0.28 APK字节、重编译签名或执行手机验证。没有新APK交付，没有修复通过结论。下一步应取得现有诊断启动页“复制错误日志”的完整本次/上次日志，分别定位Java部署、Mono入口、NML初始化、MOD源码编译、OnModLoad和UI执行；环境恢复后针对确认断点修复并私下重签测试。保留现有存档，禁止卸载/清数据；v0.28签名与历史v18不同，不能假定可直接覆盖。只修改本WorldBox独立分支日志，苍岚main不动。
