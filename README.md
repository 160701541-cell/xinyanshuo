# 心魇说 · 《苍岚·人生世界》官方网站

## P0 最高指令：持续公开GPT-6 / Work进展与构建状态（2026-10-14）

用户要求任何时刻能区分「GPT-6/Work正在工作、CI在排队/运行、构建失败、APK已经正式发布、暂无可观测进展」，并且**不能重复快速请求GitHub工作流接口导致限流**。本规则高于官网美术和其他非紧急功能，私有游戏仓库 `docs/DEVELOPMENT_LOG.md` 顶部保存其完整原文规范。

- **事件驱动，而不是疯狂轮询API**：游戏仓库 `.github/workflows/site-log-sync.yml` 接收真正 Android / Godot / 美术 QA workflow 的 `requested/in_progress/completed` 事件，及 Work/GPT-6 PR 的打开、提交更新、结束事件。事件 payload 直接由 `tools/site_build_status_export.py` 净化后提交到本站 `data/build-status.json`，**不会发起额外GitHub REST工作流查询**。失败同样要公开，不能筛掉失败运行。
- **严格120秒节流**：手机网页版`site.js`只刷新官方静态JSON，前台页面**每120秒一次**且重新可见时刷新，不从浏览器请求GitHub私有API。人工必要的GitHub REST查询至少隔120秒，遇403/429等待限流窗口，不循环重试。
- **不会伪装能看见后台脑内任务**：未在GitHub提交的Work思考/离线活动不可观测；官网写「没有新的可核实事件 / 仍待确认」，永不随口写“卡死”或“持续工作”。PR代表实际提交，而CI pass不代表手机真机体验。
- **官方APK与内容包独立展示**：`build-status.json` 的`signed_release.apk_published=true`仅当公网仓库中签名APK的*物理文件大小、SHA256和原证书*与最新元数据一致；PCK物理包 SHA256/签名元数据独立检查。主线构建失败不会把旧版APK冒充本次构建成功；最新Android APK与旧v1 PCK可能是不同修订（Terrain3D原生库需要新APK，不能PCK热更覆盖）。
- **失效警示**：超过40分钟未收到运行中工作流的新事件，只显示「状态待确认」，仍可点开原始Actions和PR链接核实。GitHub Actions/Pages传播有延迟，事件无需2分钟API主动查询，但不是秒级无间断监控，网页需显示最后有效事件时间。


官网：**https://160701541-cell.github.io/xinyanshuo/**

本仓库是《苍岚·人生世界》的公开官方网站与**正式签名的 Android APK / PCK 内容分发站点**；游戏源码、角色源工程、玩家存档及任何密钥不得进入公开站点。

## 2026-10-14 长期必守要求：开发日志、更新日志上官网

用户要求**持续公开开发过程、正式更新记录和世界观美术**，不是一次性改版。因此以下规则固定执行：

1. **开发工作日志**：游戏私有仓库主分支 `docs/DEVELOPMENT_LOG.md` 是唯一官方原始开发记录；当主分支日志发生变化，独立 `Official Website — Sync Public Devlog and Signed Changelog` GitHub Actions **自动同步**经脱敏的真实内容到公开 `data/development.json`。官网显示最新时间、历史记录与原始内容摘要，可以展开查看，失败/缺陷/尚未完成都应披露。
2. **游戏更新日志**：唯一可信的正式版本来源是已校验并真实公开分发的 `android-preview/latest.json` **签名修订**。自动网站同步程序 `tools/site_log_export.py` 只能将签名可信、版本单调递增、SHA-256合法的发布加入 `data/updates.json`，绝不能将 PR草案或Godot源码通过CI当作线上正式更新。
3. **实时同步的准确含义**：日志在主分支对应变更**提交后自动推送**到本仓库并触发 GitHub Pages 构建；网页打开后约**每120秒**刷新数据，浏览器回到前台时也会重新读取；每15分钟有计划任务补偿。GitHub Actions/Pages/CDN的实际网络延迟通常是**几十秒至数分钟**，并非毫秒级流式实时系统。网页明确标识最后同步时间。
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
