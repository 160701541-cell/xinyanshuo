# 【独立第三方MOD实验】WorldBox《万界仙侠》衍生测试——与《苍岚》游戏开发完全无关

**本分支只用于其他游戏 WorldBox 的非官方MOD衍生测试。不是原创游戏《苍岚·人生世界》的功能开发、资源改动、热更新或发行渠道。**

- 实验项目：WorldBox Android 0.51.4，NeoModLoader 及用户取得的第三方MOD兼容性研究。
- 只借用公开仓库的 `character-pipeline` 源码作为独立素材生产工具；产物只能用于WorldBox实验候选。
- 研发位置：公开仓库 `160701541-cell/xinyanshuo` 的 `worldbox/external-mod-lab-v07` 独立分支。
- 禁止本实验分支合并到 `main`；禁止修改 `game-source/`、`android-preview/`、`AGENTS.md`、`docs/CAC_CHANGELOG.md`、`data/`、`art/`、官网与正式签名/OTA工作流。
- 本阶段仅允许修改 `tools/worldbox-xianxia/` 与专用 `.github/workflows/worldbox-external-mod-lab-v07.yml`，不触碰其他源游戏资产。
- 禁止向公共GitHub提交用户上传的商业 WorldBox APK、第三方NeoModLoader DLL、Frontiers/Combat Gods等第三方二进制与无再分发授权的资源。
- 源码提交、离线单测或GitHub Actions通过不代表安卓加载成功。真实加载、清晰放大、伪3D观察、存档安全和性能各自实测前，状态必须是 `DEVICE_PENDING`。
- 默认只读；不得自动注入或重签第三方APK，不破坏原世界存档。游戏世界规则只由其本体或经过验证的MOD管理。

**第三方免责声明：本项目非WorldBox及其MOD作者官方作品，测试与原创新游戏《苍岚》没有任何从属研发关系。**

当前P0：通过真实0.51.4 NML加载日志验证 MOD入口和世界地图读取；随后才逐步验证等距微观观察、清晰缩放、天气、王朝、秘境、雷劫和本地AI。