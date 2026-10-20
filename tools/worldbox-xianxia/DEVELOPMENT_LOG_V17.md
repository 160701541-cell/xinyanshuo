# WorldBox 第三方非官方MOD实验 v0.17 — 2026-10-20

**项目严格隔离声明：** 本文件与本分支只涉及对第三方《WorldBox》游戏的非官方 MOD 衍生测试，不属于《苍岚·人生世界》原创游戏的开发或发布。不得合并 main、修改苍岚源码、官网、签名、APK/PCK或热更新。

## 用户与 Work 分工

用户要求继续实际研发MOD内容，Work单独负责对用户持有的WorldBox 0.51.4安装包进行私有整合APK、重新签名、手机实机启动及交付。我们不能把GitHub自动化代码成功编译等同于可直接安装的游戏成品。

## 本轮实际提交

- 新增 `qa/verify_android_world_evidence.py`：解析Work从**真实安卓设备**采集的WorldBox日志，可输出结构化JSON，区分：NML日志出现、地图API读到、2048×2048**实际地图宽高**、崩溃关键字及尚未完成的APK安装/存档重读/FPS等验收。**不允许通过截图/错误地图比例/仅注册预设就谎称2048地图已生成。**
- 新增 `test_v17_device_evidence.py`：5个针对极限世界真实性的单元测试，覆盖预设假阳性、生成尺寸比对、最后一次世界尺寸、致命错误、错误宽高等。
- 将 `WORK_HANDOFF_APK_V13.md` 更新至 v0.17分支，Work继续执行单独的APK打包、签名、Android16运行测试；不会发布用户上传的商业APK与第三方MOD二进制到公开仓库。
- 使用WorldBox专属 Actions `worldbox-external-mod-lab-v17.yml` 执行回归，沿用观察器、中文字体与大地图SDK编译及严格路径隔离。

## 实际状态

**现有功能：** 字体缩放100%～175%、部分MOD小字兼容、只读人物观察、2048×2048新建地图实验选项（已编译未实测成功）、FPS自适应。新增日志真实性QA辅助Work验收。

**仍未完成：** 2048×2048世界真机生成/保存重载、复杂修仙战斗玩法全部整合、Work一键APK交付。脚本从日志识别出地图宽高仍**不能证明APK安装、长时间稳定运行或存档恢复**；这些项必须提供实机证据。

命令范例：`python tools/worldbox-xianxia/qa/verify_android_world_evidence.py --log /local/logcat.txt --out /local/worldbox_report.json`。用户的APK、密钥和日志只能留在私有环境。
