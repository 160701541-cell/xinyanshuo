# 心魇说 · xinyanshuo

《苍岚·人生世界》独立公开网站及游戏内容更新渠道。

**官网：** https://160701541-cell.github.io/xinyanshuo/

**部署记录：** https://github.com/160701541-cell/xinyanshuo/actions/runs/38456820899 （GitHub Pages build / deploy 均成功）

**未来内容更新清单：** `android-preview/latest.json`（**尚未公开发布**）

## 网站当前状态

- ✅ 公开仓库已创建，ChatGPT GitHub 应用访问已授权。
- ✅ GitHub Pages 已启用；部署成功记录对应首页提交 `de3ef429`。
- ✅ 网站静态资源包括 `index.html`、`style.css`、`site.js`、`favicon.svg`。
- ⏳ 内容更新源尚未发布经过 RSA 签名的 `latest.json` 与 PCK；没有公网补丁就不会触发游戏客户端安装。
- ⏳ 长期固定 Android 签名 APK 尚未发布、未完成手机 OTA 验收。

本公开仓库不得保存游戏源代码、玩家存档、个人令牌或任何签名私钥。旧调试包与未签名模板 **禁止** 发布到 `android-preview/latest.json`。

如需更新游戏内容，必须先在私有游戏项目完成 Godot QA、签名 APK 配置和加签 PCK，并按真实 SHA-256 校验结果上传发布资源。

