# WorldBox·万界仙侠 v0.44：安卓MOD导入与预编译升级清理

本版本为非官方、仅用户私有的WorldBox安卓0.51.4衍生测试，不是《苍岚·人生世界》，不修改苍岚main，不公开商业WorldBox原包及私钥。

## 用户问题和实质修复

用户v41 Android16/PKR110日志确认自有Observer加载失败，NeoModLoader的动态C#源码编译报CS0009 Invalid public key。上一版v0.43已将自有观察模块换成ModType=1预编译候选，但此前安装遗留的19个Code/*.cs不自动消失。

- v0.44新增OwnedModSourceCleanupV44.java：仅当旧文件位于本项目专有Mods/WorldBoxXianxiaObserver/Code/目录，且**文件SHA256等于已知v0.42原版19份源码的逐个SHA256**时才删除；玩家修改过的、其他第三方MOD、未知目录或存档一律不删除。每次记录实际清理数量与保留数量；不卸载应用。
- 新版ModDeployment使用签名APK内部部署表`obsolete_owned_files`执行上述校验清理，之后才提交部署版本缓存token。
- v0.44将已有SafeZipPathsV42的安全归一化接入ExternalModImporterV32，允许**安全的Windows反斜杠ZIP分隔符、./前缀和冗余斜杠**；仍阻止绝对路径、..目录穿越、不可接受控制字符、重复标准化路径，仍坚持压缩文件大小、个数和Android可执行文件限制。兼容mod.JSON大小写及安全目录条目。
- 本版尚未得到用户`凡人修仙传_v1.1.16.zip`原件，因此不能声称该压缩包已经能导入/正常运行。桌面BepInEx格式、独立DLL与Android NML的兼容问题依然需要单独适配，非可信包仍进入待兼容目录而非执行。

## 实际代码、CI和私有整合APK

源码：`private-apk-lab/SafeZipPathsV42.java`、`ExternalModImporterV32.java`、`OwnedModSourceCleanupV44.java`、`ModDeployment.java`，测试：`tests/SafeZipPathsV42Test.java`、`tests/OwnedModSourceCleanupV44Test.java`，原有工作流新增Android SDK javac+d8编译及两个安全回归。

GitHub Actions `39565890856`：offline-source-qa、android-public-sdk-compile、private-user-file-apk-inspector三项全部成功，导入器与清理器实际打进新编译的Java DEX（不是只提交源码）。

以私人v0.43最终完整APK为基线，只改变自有`classes5.dex`与`assets/worldbox-xianxia/v18/install.json`，DEX由CI产物生成后**统一lab13→lab31的等长Java类型声明并重算DEX SHA1/Adler32**，与AndroidManifest及用户已安装的lab31应用一致；原WorldBox程序集、原有预编译Observer候选、修仙、171物资图标、经济与虚拟10000²分区图原字节不变。

真实私有签名安装包：`WorldBox_万界仙侠_v044_模组ZIP导入与旧源码清理修复_待实机.apk`；188052893字节；SHA256 `022e8d2195e046c867c2fca7a7614d50ee1d6bbd755a4a2acf0b7324a4c03baf`；包名 `com.xinyanshuo.worldbox.lab31`；沿用相同lab31测试签名，v1/v2/v3签名与ZIP CRC校验通过。部署保留893项用户自有MOD资产目录并新增19条受SHA保护的过期清理名单；APK本体内没有这19份旧源码。

APK、私有验收报告、私有重建脚本已上传用户Work Library目录`/WorldBox-万界仙侠/Work交接/`。GitHub只保存自有源代码与此文档。

## 严格P0实机状态

**没有实机通过证据**：APK在用户PKR110能否启动、是否完成受哈希保护的旧源码清理、观察MOD是否从FAILED变为LOADED、用户真实ZIP能否导入运行均待实测。NML动态编译的其他第三方Chronicle模块仍可能因CS0009失败。10000×10000是虚拟分区世界预览，**不是能探索1亿真实WorldTile的WorldBox地图**。如观察MOD仍FAILED，需新实机日志，不盲目重复堆功能。

手机后续检查：`MOD_DEPLOY_OK build=v44-safzip...`的`obsoleteOwnCodeRemoved`和`preserved`；`MOD_STATE XINYANSHUO_WORLD_BOX_OBSERVER_V07=`；导入`凡人修仙传_v1.1.16.zip`时若仍失败，导出完整日志和上传原压缩包以排查具体文件路径。
