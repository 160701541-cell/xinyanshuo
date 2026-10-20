# WorldBox external MOD lab v0.14 — 2026-10-20

**这不是《苍岚·人生世界》的开发。** 所有内容限制在 `worldbox/external-mod-lab-v14-giant-map` 专用分支的 `tools/worldbox-xianxia/**`，不得合并main，不得修改《苍岚》的源码、官网、APK176/PCK热更新、正式开发日志或任何RSA签名。

用户要求继续研发WorldBox MOD，由Work独立负责最终安卓整合APK构建/签名/真机验收；目标地图大小2000×2000格，按照64格区块对齐开发为**32×32区块、2048×2048格、4194304地形格**（对比512²为16倍）。

本轮代码真实新增：
1. `GiantMapOptionsV11.cs` 独立2048²实验入口，双击确认且仅尝试向游戏地图尺寸库注册一个新世界候选项；既不生成地图也不改变已有世界/存档，不宣称在目标WorldBox 0.51.4中已经能生成。
2. `XianxiaObserverV07.cs` UI增加「2048×2048实验」按钮和「确认2048×2048」二次确认，保留既有字体放大功能（v13）以及性能守护（v12）。
3. `world_size_planner.py` 新增32×32面积预算；`test_v14_giant.py`新加入5项自动化验证，包括无默认强制巨图、大地图登记与单独确认。
4. Work任务交接文档更新为v14分支及新地图目标；专属Actions改成v14分支，仅限WorldBox目录。

关键待验收：
- v14官方安卓SDK/模拟桩构建结果需以GitHub Actions最新版日志为准。
- 按照真WorldBox API源码，尺寸资源能否从Mod正确注册，世界生成、存档、AI模拟/性能，均**DEVICE_PENDING**。
- 安卓游戏完整整合APK尚未在本轮制作：Work单独负责其私有构建及设备验收，不得以MOD zip冒充可玩APK。
- 2000×2000精确尺寸不是32区块对齐，当前选择2048×2048作为近似更大目标，Work须再验证API真实尺寸单位。
