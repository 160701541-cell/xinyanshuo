# 心魇说 · xinyanshuo

《苍岚·人生世界》独立公开网站及游戏内容更新渠道。

**官网：** https://160701541-cell.github.io/xinyanshuo/

**部署记录：** https://github.com/160701541-cell/xinyanshuo/actions/runs/38456820899 （GitHub Pages build / deploy 均成功）

**已发布资源更新清单：** [`android-preview/latest.json`](android-preview/latest.json)（首次签名测试修订 #104）

## 网站当前状态

- ✅ 公开仓库已创建，ChatGPT GitHub 应用访问已授权。
- ✅ GitHub Pages 已启用；部署成功记录对应首页提交 `de3ef429`。
- ✅ 网站静态资源包括 `index.html`、`style.css`、`site.js`、`favicon.svg`。
- ✅ 已部署签名修订 #104：`latest.json` + `canglan-content-rev-104.pck`，版本兼容基包 Android `versionCode=1102`。此资源属于技术测试，未经过手机实机 OTA 验收。
- ✅ Android 基包 v0.2.0-dev.102 已通过固定签名证书校验；⏳ 尚未确认用户手机成功下载、应用并回退补丁。
- ⚠️ GitHub Pages 部署已成功，但从无登录的外部网络连续下载、Range 续传的自动化检查仍未通过，请以手机实际打开网址/游戏为最终依据。

本公开仓库不得保存游戏源代码、玩家存档、个人令牌或任何签名私钥。旧调试包与未签名模板 **禁止** 发布到 `android-preview/latest.json`。

如需更新游戏内容，必须先在私有游戏项目完成 Godot QA、签名 APK 配置和加签 PCK，并按真实 SHA-256 校验结果上传发布资源。

