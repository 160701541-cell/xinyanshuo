# 苍岚游戏内更新（android-preview）

此目录是给正式发布的资源补丁使用的公开 HTTPS 发布目录。

**当前状态：尚未发布正式补丁。** `latest.json` 不存在是刻意的：这意味着客户端离线运行或提示更新站未开放，而不是下载未经签名的文件。

只有同时满足下列要求后才能发布：

- 首次长期基础 APK 已使用**固定的 Android 签名密钥**，并打包了对应的 RSA-3072 公钥。
- 补丁文件 `canglan-content-rev-N.pck` 是 Godot 正常导出的实际 PCK，不包含更新器信任锚、签名私钥或 Android keystore。
- `latest.json` 的 RSA 私钥签名与基础 APK 的不可更改公钥相符；内容修订号递增、完整性 SHA-256 和实际长度一致。
- 在公网先存放完整 PCK，再发布指向它的 `latest.json`，并核验普通 Android 浏览器匿名访问成功。

目前只有官网成功部署，没有开启任何可安装的补丁，勿上传测试用 UNSIGNED_DEVELOPER_TEMPLATE。
