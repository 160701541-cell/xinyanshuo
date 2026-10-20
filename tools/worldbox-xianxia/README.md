# WorldBox《万界仙侠》专用素材导出器（独立分支 / 仅作为工具）

本目录复用 **character-pipeline** 分支的 3D→PNG 渲染结果，为用户持有的 WorldBox 安卓版制作 2D 像素精灵素材。**不是《苍岚》更新**，不得进入 `android-preview/`、`latest.json` 或《苍岚》签名 OTA。

## 来源

- 同仓库 `tools/character-pipeline/src/item3d.gd`：法器、丹药、资源和多角度人物/生物试样。
- `tools/character-pipeline/src/cloth.gd`：古风人物和服饰试样。
- `tools/worldbox-xianxia/export_nml_sprites.py`：新的 WorldBox 精灵标准化、单帧拆分和 NML `GameResources` 导出。

## 用法

安装 Pillow (`python -m pip install pillow`) 后：

```bash
python tools/worldbox-xianxia/export_nml_sprites.py \
  --renders /path/to/character-pipeline/out \
  --sheets /path/to/WorldBox_Xianxia_AI_v0.3/assets/buildings \
  --out /tmp/worldbox-xianxia-assets --size 64 --pixel 2
```

`--renders` 接受 `out/roles/farmer_0.png`、`out/beings/wolf_1.png`、`out/matrix/...` 等实际渲染 PNG；`--sheets` 接受 `alchemy_idle_spritesheet.png`（横向 N 个正方形单帧）。

输出 `GameResources/xianxia/<category>/<asset>/<state>/<direction>_<frame>.png`，各分类 `sprites.json`（1 PPU；建筑/NPC地面锚点；物品图标中心锚点），`asset_manifest.json`（来源 SHA256、每帧 SHA256、顺序、动作、帧数）。

### 不能跳过的验证

1. 输入必须是真实生成的 PNG；没有图像时不能声称生成了素材。
2. 采用统一 64×64/2像素块候选规格，不声称适合 WorldBox 所有类型或动作；先看实机效果后再针对性调尺寸和 pivot。
3. **导出各帧不等于游戏已经注册动态动画**，游戏内行为状态机、天气、灵植、雷劫、秘境、王朝仍需要真实 NML C# 代码和当前 0.51.4 加载验证。
4. 只保留用户提供/自产/明确许可素材；不包含、重签或分发WorldBox商业APK/第三方DLL。
5. 安卓 MOD Loader/NML Mono 配置和 WorldBox 0.51.4 的加载能力尚未在用户手机通过。代码与贴图质量都不能替代设备验收。

## 原生游戏画风

只取多角度 3D 角色模型的稳定造型与光影，导出时降至 32～64 像素附近的 2D sprites，不改变 WorldBox 原有沙盘/像素画风。

## 关联设计

旧独立四界原型 v0.3 有33类建筑×6状态×8帧像素动画，但之前没有按 NML `GameResources` 拆分。本导出器补充了这一环节。四界、宗门、王朝和 AI 仍与《苍岚》原版 Godot 更新通道完全隔离。

## 2026-10-20 新增实际 Godot 渲染流水线

`.github/workflows/worldbox-xianxia-godot-render.yml` 在隔离分支自动运行真实 Godot 4.4.1（Xvfb/OpenGL），把现有 `character-pipeline/src/item3d.gd` 和 `icon_light.gdshader` 装入小型独立 Godot 场景，尝试导出 8 种角色/生物 × 4 角度，以及 5 品阶 × 5 属性的物品图。然后调用本导出器生成 Sprite/JSON 并上传 Action Artifacts。**新增 workflow 并不等于真实运行成功**，必须查对应运行日志和产物；仍未进入 WorldBox 安卓游戏。无付费模型/API 调用，不触碰《苍岚》OTA。
