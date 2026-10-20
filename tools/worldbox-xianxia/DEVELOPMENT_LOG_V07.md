# 2026-10-20 / WorldBox 非官方MOD衍生测试 v0.7

目标用户游戏：WorldBox Android 0.51.4。**此分支与开发原创《苍岚·人生世界》无关。**

- 建立 `worldbox/external-mod-lab-v07`，从v0.6观察层开发分支延续。与原游戏main严禁合并。
- 创建边界声明及机器校验策略，将修改限制在WorldBox实验目录与该项目独立 Actions。
- 已提交 `XianxiaObserverV07.cs`：使用原游戏读地图、读NPC、只读跟随、触屏按钮、4方位伪3D等距图；无写入存档/刷怪等代码。
- 已提交 `observer_math.py` 和自动化测试；本地Python相应参考版本11项通过。
- 已设置13项扩展GitHub Python测试 + C# stub build，尚未取得远端真实运行结果，不能写CI通过。
- GitHub compare自上一分支点起所有变更均在 `tools/worldbox-xianxia/**` 或独立 workflow；《苍岚》的 game-source/android-preview/docs/data/art/AGENTS等正式工程文件零修改。
- 安卓0.51.4 NML真实装载和稳定性 **DEVICE_PENDING**。不能发布第三方APK或所谓可玩MOD。
- 原版模糊缩放未被更改；本次Point最近邻仅用于新只读观察窗口。
