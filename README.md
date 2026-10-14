# 心魇说 · 《苍岚·人生世界》官方网站

官网：**https://160701541-cell.github.io/xinyanshuo/**

本仓库是《苍岚·人生世界》的公开官方网站与**正式签名的 Android APK / PCK 内容分发站点**；游戏源码、角色源工程、玩家存档及任何密钥不得进入公开站点。

## 2026-10-14 视觉标准正式修订：高清国风概念海报就是最终美术方向

**项目主理人明确纠正之前错误：官网完全可以、也应该使用高品质概念美术作为视觉中心。** 《苍岚·人生世界》最终追求的视觉方向就是用户提供的“古风CG大世界官网”效果，不能因为当前Godot测试版本粗糙，就故意让官网也只展示粗糙平面SVG。**既大胆展示愿景，又诚实标明非实机**：两者不矛盾。

网站已经实际提交4张新的原创高清国风幻想概念作品（WebP源站正式托管）：
- `art/canglan-vision-hero.webp`：1440×904，青绿长袍旅人、晨光万里山川城郭、江河城镇的全站封面；
- `art/canglan-towns-life.webp`：1130×371，商队、集市、灯笼、江南水运；
- `art/canglan-six-kingdoms.webp`：1130×369，雪岭关城、六国战事、旗帜；
- `art/canglan-robed-wanderer.webp`：650×785，青绿长袍旅人/主角愿景特写。

上面四张均由**AI作为原创静态概念美术**专门生成，仅供官网海报/风格规划，不是用户要求的预绑骨骼的角色GLB，也不能假装是已经实现的游戏画面。视觉目标承诺**尽量达到电影质感国风**，实际进度独立显示真实签名版本、开发日志与缺陷清单。横屏版大幅电影式主视觉，移动竖屏整栏铺满（解决旧官网在用户手机上左栏过窄、右侧大片空白的问题），下方展示世界类别卡片、概念图库、诚实更新状态、版本下载和玩家社区。

### 正式用户社区入口

| 服务 | 官方信息 | 官网按钮 |
|---|---|---|
| QQ官方测试群 | **心魇说官方测试群 1125050836** | 用户亲自提供的 `https://qun.qq.com/universal-share/share?...` 受邀链接（含群邀请令牌，明确要求对公众发布；此令牌可能失效，失效后须由主理人更新） |
| QQ联系 | **160701541** | `https://wpa.qq.com/msgrd?v=3&uin=160701541&site=qq&menu=yes`（另有复制QQ号，移动端打不开聊天链接时可以使用QQ搜索） |
| 抖音 | **xys160701541** | `https://www.douyin.com/search/xys160701541?type=user` 账号搜索链接；并非未经验证的 sec_uid 用户个人主页直链 |

每次正式开发完成后继续自动更新官网**工作日志与签名更新日志**，两类记录必须不同来源，不得把未合并PR/概念视觉称为手机已更新版本。网页约60秒轮询数据，Pages/CDN非即时强一致。今后新的海报可通过 `art/` 和页面栏目滚动扩展，但所有概念图必须带有“视觉概念·非实机”的准确说明，不能变成宣传欺骗。

## 2026-10-14 长期必守要求：开发日志、更新日志上官网

用户要求**持续公开开发过程、正式更新记录和世界观美术**，不是一次性改版。因此以下规则固定执行：

1. **开发工作日志**：游戏私有仓库主分支 `docs/DEVELOPMENT_LOG.md` 是唯一官方原始开发记录；当主分支日志发生变化，独立 `Official Website — Sync Public Devlog and Signed Changelog` GitHub Actions **自动同步**经脱敏的真实内容到公开 `data/development.json`。官网显示最新时间、历史记录与原始内容摘要，可以展开查看，失败/缺陷/尚未完成都应披露。
2. **游戏更新日志**：唯一可信的正式版本来源是已校验并真实公开分发的 `android-preview/latest.json` **签名修订**。自动网站同步程序 `tools/site_log_export.py` 只能将签名可信、版本单调递增、SHA-256合法的发布加入 `data/updates.json`，绝不能将 PR草案或Godot源码通过CI当作线上正式更新。
3. **实时同步的准确含义**：日志在主分支对应变更**提交后自动推送**到本仓库并触发 GitHub Pages 构建；网页打开后约**每60秒**刷新数据，浏览器回到前台时也会重新读取；每15分钟有计划任务补偿。GitHub Actions/Pages/CDN的实际网络延迟通常是**几十秒至数分钟**，并非毫秒级流式实时系统。网页明确标识最后同步时间。
4. **概念美术与海报**：原创 `art/canglan-world-poster.svg`、`art/canglan-village-concept.svg` 和 `art/canglan-frontier-concept.svg` 已进入官网；表现山河、村镇、商路、众生和不同人生路径。**必须明确标明“原创概念美术，非实际游戏画面”**，以防玩家误认项目已达 CG 成片画质。所有真实游戏截图另按真实Godot截图工具验收。
5. **信息安全**：日志内容经正则脱敏处理；公开网站不会复制私有 Git 仓库源码、密钥、签名私钥、上传的个人材料、CMU动作原始包或普通未签名构建。所有下载仍采用客户端本地的数字签名与版本兼容校验。

## 页面导航

- [首页 / 世界理念](https://160701541-cell.github.io/xinyanshuo/#world)
- [国风原创海报 / 世界观概念图](https://160701541-cell.github.io/xinyanshuo/#concept)
- [真实开发工作日志](https://160701541-cell.github.io/xinyanshuo/#devlog)
- [正式签名游戏更新日志](https://160701541-cell.github.io/xinyanshuo/#changelog)
- [已签名的 Android APK 下载](https://160701541-cell.github.io/xinyanshuo/#download)

## 自动化路径和验证

- **源仓库工作流**：`160701541-cell/canglan-world/.github/workflows/site-log-sync.yml`，触发：正式主分支开发日志提交、Android签名发布工作流成功结束、15分钟补偿、人工 dispatch。
- **源仓库导出代码**：`tools/site_log_export.py`，只读正式主分支日志和**本站**的签名发布元数据；摘要脱敏；两份数据字段互不混淆。
- **公开仓库网站**：`index.html`、`site.js`、`style.css`；无第三方运行时依赖，不需要登录即能查看；采用 DOM `textContent` 安全渲染日志文本。
- **公开仓库测试**：`.github/workflows/site-content-qa.yml` 对 JS语法、HTML锚点、三张SVG原始概念图及非实机标记、工作日志schema、签名revision/SHA一致性做自动验收。
- **资源入口**：`android-preview/latest.json`、`android-preview/base-latest.json` 均来自签名发布流水线。**网页显示是信息展示，不能代替客户端的 RSA 验签。**

正式主角角色画质、美术母版、开源许可证和移动端性能仍应严格以实际游戏版本和玩家实测为准。
