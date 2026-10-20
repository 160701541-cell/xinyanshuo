# WorldBox 外部游戏 MOD 衍生实验 v0.7 — 完全独立于《苍岚》游戏开发

> **本项目只是在相同公开仓库的独立 `worldbox/*` 分支进行其他游戏 WorldBox 的非官方 MOD 测试。绝不属于原创游戏《苍岚·人生世界》的研发、源代码升级、签名、PCK热更新或正式发行。不得合并到 `main`。**

## 真实新增内容
- `NOTICE_EXTERNAL_MOD_ONLY.md`：长期固定的第三方 MOD / 原创游戏隔离规则。
- `project_scope.json` + `scope_gate.py`：校验所有新增路径只能位于 `tools/worldbox-xianxia/` 和专用实验 workflow；拒绝修改原游戏源码、官网和 OTA；拒绝公开 APK、DLL、PCK、RAR 等第三方文件。
- `nml-observer-v07/Code/XianxiaObserverV07.cs`：**源码候选**，通过 NeoModLoader `BasicMod<T>` 调用 WorldBox 读地图、读附近NPC、点击跟随、范围缩放与视角旋转，按 Point 过滤绘制倾斜伪3D图块。
- `observer_math.py`：离线可验的 0°/90°/180°/270° 投影及 32/64/96 真实原生 LOD 选择。
- `test_v07.py`：隔离范围、MOD身份、只读协议、几何/LOD共13个Python单测（**在CI实际运行前不可称已通过**）。
- `tests/WorldBoxObserver.SourceSyntax.csproj`：使用**标注为非游戏SDK的C#桩**试编译真实观察MOD源码，只证明语法/设计契约符合，**不证明真实0.51.4 NML移动版能运行**。
- 独立 GitHub Actions `.github/workflows/worldbox-external-mod-lab-v07.yml`：只在本分支触发，不触碰原游戏流水线，权限仅contents:read。

## 功能与局限
当前观察层是实际 NML C# **候选源代码**，但没有真实安卓ModLoader运行证据。能显示真实地图/人物、旋转、跟随的功能需要设备加载后才能认定完成；它**不是可自由行走的第一人称3D**。观察窗口的 Point 过滤不等于修复原版WorldBox主地图模糊；96像素仍是以前资源的最高可验证原生分辨率。

## 验收状态
- **GitHub分支和文件**：已提交。
- **本地纯Python镜头参考与分支策略**：11项基础测试已通过。
- **GitHub完整13项及C#桩编译Actions**：PENDING，需要实际工作流证据。
- **WorldBox Android 0.51.4实机加载/显示/耗电/存档**：DEVICE_PENDING。
- **王朝、宗门、天气、雷劫、秘境、NPC本地大模型和真正3D附身**：仍待引擎集成。
- **《苍岚》主项目**：本轮零修改。

所有WorldBox第三方MOD实验记录只能写到本目录的文档，不往《苍岚》正式开发日志混入实验进度。