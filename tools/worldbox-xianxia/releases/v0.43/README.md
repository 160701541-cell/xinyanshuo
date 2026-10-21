# WorldBox·万界仙侠 v0.43 私有安卓实验发行记录

此分支与《苍岚·人生世界》main完全独立。公开仓库不分发商业WorldBox APK或用户个人密钥。

**2026-10-21 用户实机v41证据：**安卓部署成功，NeoModLoader自身已初始化，Frontiers、Sakuga、FengyunRankings加载；但自有观察模块 XINYANSHUO_WORLD_BOX_OBSERVER_V07 显示 FAILED。编译日志显示 CS0009 Invalid public key，涉及应用私有mono目录中的两个托管程序集。第三方MICROWAVE805_CHRONICLE另行失败。这不是游戏启动器签名错误。

**本轮实际私有APK更新：**以同项目v0.42“可视10000×10000虚拟分区图”完整私有APK为基线，保留经济、地图菜单、10000虚拟地块数据和原有游戏内区块预览，将自有观察模块旧ModType=0源码包换为已有CI 39550983219成功编译的ModType=1预编译NML DLL候选。模块GUID不变，旧的19份C#源码不再打入新APK，避免自有观察模块继续依赖手机上出错的动态源码编译流程。原商业WorldBox托管程序集、现有Mono桥及安卓DEX完全未改动。**用户手机旧部署目录可能仍残留Code文件；是否遵循ModType=1并成功加载必须实机检验。**

新私有APK：WorldBox_万界仙侠_v043_虚拟分区图与预编译MOD整合测试_待实机.apk
SHA256：37892bf62c3b0c2892b6fce8a88b80f120885aa1db1e8f23bc9271c9d7a8e4e7
字节：188052893
包名：com.xinyanshuo.worldbox.lab31
签名：沿用此前lab31私有测试证书；已检验v1/v2/v3 APK签名、文件CRC及完整部署清单893项SHA256。Android16手机加载结果待用户确认。

**明确未完成：**其他第三方旧MOD的CS0009尚未通用修复；用户“凡人修仙传_v1.1.16.zip”在06:34遇到“ZIP路径格式不安全”，但该ZIP没有上传，无法区分正常Windows路径与真正目录穿越，不能绕过安全校验。已单独添加安全ZIP路径规范化及拒绝目录穿越的纯JVM测试，尚未接入本v0.43的安卓导入器。10000×10000仍是**可视虚拟分区图**，不是已经生成、渲染、保存完整一亿地块的原WorldBox真实世界。

私有APK和检查报告上传用户自己的持久文件库 /WorldBox-万界仙侠/Work交接/。后续先检查新安卓日志自有Observer状态，再继续其他玩法集成，禁止用“编译通过”冒充手机功能通过。
