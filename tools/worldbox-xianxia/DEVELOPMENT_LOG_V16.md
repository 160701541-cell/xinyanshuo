# WorldBox第三方MOD实验 v0.16 — 2026-10-20

**严格隔离声明：这是其他游戏《WorldBox》的非官方MOD衍生测试，完全不是《苍岚·人生世界》的游戏开发或发布。** 所有更改仅在专用分支 `worldbox/external-mod-lab-v16-diagnostics` 下进行，不得合并main，不得触碰苍岚的源码、官网、APK/PCK、签名与热更新。

根据用户与Work已有分工：本助手研发WordBox MOD功能，Work负责私有安卓整合APK、重新签名、安装启动和实机验收。用户最终目标仍是开箱即用的一体APK，不接受源码ZIP代替。

本轮真实提交：
- `GiantMapOptionsV11.DiagnoseActualWorld()`：只读检查已生成地图实际 `MapBox.width` 与 `MapBox.height`，区分 `WORLD_SIZE_MATCH`、`WORLD_SIZE_DIFFERENT` 与 `WORLD_SIZE_FAIL`，日志包括实际宽高和地形格总数，以免把2048²实验预设成功注册误认为世界已实际生成。
- `XianxiaObserverV07.cs` 的「尺寸API自检」按钮同时展示地图接口状态、游戏实际宽高，并写 `[XIANXIA-V16]` 日志供Work验收。
- `test_v16_actual_world.py` 新增2项自动回归，验证真实宽高诊断不改写存档，不生成世界，以及观察UI暴露诊断结果；更新旧v15日志前缀回归以适应v16。
- 单独增加 v16 GitHub Actions workflow并更新项目隔离门禁；Work整合交接文档补充最新分支和实际地图生成证据采集要求。
- 保留2048×2048 (32×32地图区块)实验入口、字体100/125/150/175%以及低FPS自适应观察层。

**仍未完成/不可宣称：** 2048×2048实际生成与存档重载成功，游戏内真实字体渲染、安卓设备持续负载，以及完整一体签名APK，这些必须由Work按设备/构建日志进行验收。Github SDK构建和本地单元测试不能替代。
