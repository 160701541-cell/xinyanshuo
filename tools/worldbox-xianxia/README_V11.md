# WorldBox 第三方非官方MOD衍生测试 v0.11（2026-10-20）

**这是其他游戏《WorldBox》的非官方 MOD 衍生研究，不属于《苍岚·人生世界》原创游戏的研发、美术更新、APK/PCK热更新或发行。它仅借用相同公开GitHub里的实验分支。禁止合并到main。**

## 用户本轮的要求

> “我不会你还是做成整合包吧，另外地图越大越好，骁龙八至尊版能带动最好。”

这是以**能一键玩到的安卓整合安装包**为最终交付目标，不是单纯源码/脚本。当前尚不能交付真正已经验证的合体游戏APK：用户WorldBox Android 0.51.4上传APK采用传统Mono加载说明，和我们在官方NeoModLoader Mobile 2.1 SDK成功编译的安卓IL2CPP MOD运行时不同；缺少设备上的真正加载链确认与安卓实机验证，不能谎称完成。更不能把别人的商业APK和MOD素材拼进ZIP，就冒充“安装即玩”的新APK。不会篡改原APK内付费解锁机制。

## 本轮实质改进

- 实际读取公开Android版 `Assembly-CSharp.dll` **PE metadata**，确认 `MapSizeLibrary`、`MapSizeAsset`、`MapBox.setMapSize`等类型/入口真实存在。源文件 `inspector/Program.cs`，CI自动产出 `WORLDBOX_PUBLIC_MAP_TYPES.json`。只读分析，不执行游戏或修改APK。
- `huge-map-mod/GiantMapOptionsV11.cs` 作为与观察器**同一程序集**的可选扩展，默认不开启。观察窗口提供“实验大地图10-20”按钮，需要连续两次确认才尝试注册10×10、12×12、16×16、20×20规模；只调用图尺寸库可能的`add`资源注册，不触发生成/重设现有地图、不写入存档。真实0.51.4上是否能正常显示新世界尺寸 **DEVICE_PENDING**。
- 观察窗口展示当前`MapBox.width × MapBox.height`地图大小以及近似FPS。保留角色跟随、4方向伪3D等距画面。
- `world_size_planner.py` 做按64格区块的准确相对面积预算：原8×8=512²；12×12=768²约2.25倍面积；16×16=1024²约4倍；20×20=1280²约6.25倍；30×30=1920²约14.06倍。**20×20仅在实际FPS、可用内存、NPC数量验证之后才可尝试。** 骁龙8至尊版硬件并不自动保证游戏大量NPC路径寻路/AI模拟足够快；设备RAM也未必仅凭CPU名称获知。
- `package_android_mono_source.py`增加额外地图注册源文件，和`XianxiaObserverV07.cs`打包到同一个 `Mods/WorldBoxXianxiaObserver/Code` 源码MOD。另一种`NMLMods`版在GitHub Actions基于真实官方安卓SDK编译成单个原创DLL；**不建议两种方案混用**。
- 所有GitHub分支CI测试通过，仅证明源码/编译/ZIP结构，不是手机验收。

## 实际交付边界

用户要求“自己不会安装”，不能继续叫用户手动折腾MT管理器。当前只能交付**一个完整归档的非正式测试整合包**供保管和后续封装；其本身不是安装即玩的APK，也不能要求用户将两个MOD解压到系统目录。没有证据证明能从Android 16通过另一个普通APK静默写入WorldBox受保护的 `Android/data`。所以不能冒充“自动安装器”。

真正的一键APK必须先明确兼容运行时/引导程序、合规的应用签名与本机安装方法、模拟+Android实机运行、存档安全和触控实际验收；失败不得发布。
 
项目原则：本实验任何日志都只能更新到 `tools/worldbox-xianxia`，绝不动《苍岚》正式游戏日志或更新通道。
