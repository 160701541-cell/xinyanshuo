# 仙凡共生 / 临安县活世界 Android 测试版 v0.2

本目录 **严格独立于《苍岚》及 WorldBox 游戏**。代码和APK均使用完全不同的 Android applicationId；在仓库内仅共享Git托管空间。

- 独立分支：`xianfan/independent-living-county-v0.1`，禁止直接合并至《苍岚》正式 `main`。
- Android应用ID：`com.xinyanshuo.xianfan.county`，正式安装包的Android升级需要**相同应用ID + 相同签名证书 + 更高versionCode**。
- 本试验版 APK versionCode **2**、versionName **0.2.0**；后续包在保留签名证书的同时递增versionCode。
- **警告：当前使用公开的仅供测试的签名证书，它不能证明官方发布者身份，不适合用于真正商业分发。正式发行应使用私有、受保护的签名密钥，并提前规划包名/升级迁移。切勿给旧《苍岚》APK覆盖安装。**
- Android实现：离线Android WebView + WebViewAssetLoader，从APK本地assets安全加载现代ES modules和IndexedDB；不需要打开聊天软件里的 HTML 链接。
- 核心：13,680名持久化居民；18个区域及建筑入口；有限行为、时间、粮食交易、县衙赈济、修士御剑、初遇历史与离线存档。**人口记录 != 1.3万人已经具备自主智能。**
- 基于浏览器的体验版数据与Android应用各自独立，不自动同步。覆盖升级安卓APK时不卸载、不清除应用数据才可能保留存档。

## 构建

GitHub Actions `.github/workflows/xianfan-county-android.yml` 在本独立分支推送Android相关源码时调用Gradle构建和独立测试，发布 `xianfan-county-0.2.0-demo.apk` 到 GitHub Actions Artifact，并尝试发布专属 GitHub 预发行版。两者都不能冒充已经通过 Android 真机验收。

本地：`cd projects/xianfan-living-world/android && gradle :app:assembleRelease`（依赖 Android SDK 35 和 JDK17），产出 `app/build/outputs/apk/release/app-release.apk`。

## 验收

`node --test projects/xianfan-living-world/tests/world.test.mjs`。还需实机检查 WebView 加载、离线、存档、从此版本**覆盖升级到后续versionCode**。原游戏无升级关系。