# 《苍岚·人生世界》— 开源原生 3D 世界工程（2026-10-16）

> **当前研发主线：Godot 4.4 原生 3D；不再开发 HD2D。**
> 公开源码 MIT，但仅适用于此目录的原创程序；第三方来源与许可证见 `opensource/`。
> 本仓库的 3D 主场景尚**不是**旧 APK176 安装包里的完整旧源码，不应当将独立技术测试包冒充用户已经安装的正式 APK 更新。

## 已实际接入 `scenes/main.tscn` 的代码（技术候选）

- **地形**：`scripts/world_rules.gd` 的 FastNoiseLite 高度与生态噪声；`terrain_chunk.gd` 用 SurfaceTool 创建 96m×96m 有碰撞的三角网格，移动玩家时动态保持近景 5×5 个区块，不需要远程地图服务。河谷有水面及跨河桥；真实可无缝延展的高度函数不等于无限世界已建设完成。
- **建筑**：`building_factory.gd` 程序生成原生三维基础、夯土墙、木柱、格窗、实体青瓦双坡屋面和门铰链。起始场景 20 个带实体围墙的院落、每院 3 栋独立建筑（共 **60** 栋），还有道路、市集、作坊、寺庙、学院、茶馆、农宅、客栈等街区类别；损毁/倒塌和开关门可改变运行时实体。
- **物件**：`prop_factory.gd` 为树、石、灯、井、瓦罐、田地等分配独立 ID，但使用 Godot MultiMesh 合批绘制，避免一物一 draw call；树拥有年龄字段。视觉合批不等于伪造 NPC 库存或玩家物品。
- **NPC**：`npc_agent.gd` 初始 80 名各有 ID/职业/家庭位置/日夜日程的三维骨架替身，走路肢体摆动并按玩家距离降级渲染。**尚不是成熟人物模型、动画重定向、面部表情或真正的全自主NPC**。
- **内景**：`interior_factory.gd` 使用室外原始建筑ID生成空间和8件独立家具。玩家附近可开门进入并返回；不向旧游戏的 WorldState 自动发放物品，尚无永久存档。
- **操控**：第三人称、第一人称切换、WASD、右键转向、手机左触区方向摇杆+右触区看向、滚轮缩放，实体角色胶囊碰撞；交互可通过 HUD 选择附近建筑。

## 真正的独立 3D GLB 模型工厂（公开代码）

`tools/generate_glb_pack.py` 使用开源 numpy + trimesh 将门窗、瓦面、木构等原生几何程序建模并导出可重复构建的**38份 glTF 2.0 .glb**：18 个建筑变种，10 个自然/生活物件，10 个NPC职业人体**建模候选**。导出时静态部件合并为低 draw call GLB；门扇交由游戏的运行时动态铰链，不烘成无法打开的贴图。AI图片、付费模型和商业素材 **0强制依赖**。

命令（Python 3.11+）：

```bash
python -m pip install -r game-source/godot3d/tools/requirements-models.txt
python game-source/godot3d/tools/generate_glb_pack.py --out game-source/godot3d/assets/generated --seed 20261016
python game-source/godot3d/tests/test_generated_glb.py --root game-source/godot3d/assets/generated
```

如果导入成功，`building_factory.gd` 会优先实例化匹配的 .glb 视觉模型；从源代码直接打开且不生成GLB时，会回退到纯 Godot 程序几何，保证 3D 场景可独立运行。新的 GLB 模型是 **CANDIDATE_NOT_ART_APPROVED**，仍需结合真实截图逐栋审核；NPC GLB未预绑定人体骨架，不应宣传为高端成品人物。

## 运行和QA

Godot 4.4.1：

```bash
godot --headless --editor --path game-source/godot3d --import
godot --headless --path game-source/godot3d --script res://tests/world_smoke.gd
```

可以直接在 Godot 中打开 `game-source/godot3d/project.godot` 查看真正 3D 场景。GitHub `.github/workflows/canglan-public-qa.yml` 先生成38个GLB并验证每个 glTF 真实字节、SHA256，再运行引擎冒烟、独立许可证/秘密审计，并用 Mesa/Xvfb 采集 Godot framebuffer 做人工视觉复审工件。`.github/workflows/canglan-public-3d-android.yml` 在独立QA成功时尝试构建可单独安装的 ARM64 **调试测试** APK，使用临时调试签名及独立包名，不是旧签名游戏覆盖更新。

**当前未经证实的结果**：这轮 GitHub CI 最新结论、截图、测试 APK 以及Android真机性能未独立获取运行日志，全部保持 **PENDING**；新3D源码不等于原手机游戏安装成功。原有公开已签名APK/PCK仍应由原有 `android-preview/` 清单准确记录。

## 下一步生产级缺口

这批纯几何候选质量远低于用户批准的国漫参考最终画风。下一层必须提升共享瓦片材质/真实法线、地貌生态、建筑近景比例和合院生活细节，使用真正授权开源带骨骼人物与走/跑/交互动画，加入可被寻路系统使用的道路/地块占用、切换室内的世界定位、授权资产来源与原游戏存档/产权/制造/交易/战斗系统迁移。Terrain3D 1.0.2 (MIT) 已核对有 Android/GL Compatibility 支持文档，但本工程在 Android GPU/ARM64 GDExtension 实测之前不强制装载。

**开源边界**：只发布具备合法版权许可的代码/素材；绝不公开签名私钥、APK密钥、用户游戏存档、账号凭据或未经批准的第三方素材，也不改变旧 APK176 与签名 PCK 的数字签名锚。

## 与以前真正的原生 3D 版本关系（2026-10-16）

已查阅历史只读私有仓库 `godot3d/`：原来的 Godot 4.4 主场景含 `update_bootstrap.tscn`、Terrain3D、持久化 WorldState 和复杂 NPC/制造模块，但完整可授权安全迁移尚未完成。本公开3D工程已**逐字节复用并校验**三份原版源脚本：`scripts/world_state.gd`、`scripts/entity_codes.gd`、`scripts/terrain/heightfield.gd`，新80名NPC实际用原 `WorldState.create_actor` 注册并通过兼容桥验证位置与库存边界，地形高度使用原版500m城池/西北山地模型。这是原版数据与地貌的真实增量接入，而不是声称完整APK主场景已经搬完。原先旧版资源、角色骨骼、安装更新器和所有安全私钥继续未迁移，状态 BLOCKED/PENDING。
