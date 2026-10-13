# 苍岚游戏内更新（android-preview）

**已首次发布签名的资源测试补丁。** `latest.json` 当前发布 #104，资源文件 `canglan-content-rev-104.pck`（136,432 字节）。该版本仅用于验证游戏内增量资源更新机制，不代表游戏内容已正式发行或手机 OTA 验收完成。

- 基础安装包：`v0.2.0-dev.102`（Android `versionCode=1102`），使用固定 APK 签名。
- 签名资源版次：`revision=104`，RSA 签名、文件大小与 SHA-256 已通过独立发布门禁。
- 资源内容：Work 陶罐资产与可见 HUD 文案改为「心魇说 · 苍岚·人生世界」的测试脚本。
- 更新入口：https://160701541-cell.github.io/xinyanshuo/android-preview/latest.json
- 技术注意：当前未完成 Android 手机真实下载、断网续传/回退/存档验收。GitHub Pages CI 成功不等于所有终端网络都能访问。
- 已发现默认 Godot PCK 内容选择可能把自动加载脚本一并打进包；正在对后续修订实行真实文件索引安全审查，不把 CI PASS 冒充完整安全验收。

本目录**只公开经签名核验的 PCK**，禁止提交源码、签名私钥、Android keystore、访问令牌或玩家数据。发布下一版必须先通过私有仓库质量门禁，并让 `latest.json` 指向实际存在的完整 PCK。
