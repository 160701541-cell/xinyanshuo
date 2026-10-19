# 角色与服饰程序化流水线（苍岚人生世界）

用 **真实 CC0 人体网格**（Quaternius SuperHero_Male）做底模，程序化地"长"出古装，
再逐像素画五官、软体做下摆，最后一次性出四视角验收。

## 目录
| 路径 | 内容 |
|---|---|
| `src/partsplit.gd` | 按骨骼权重把人物网格拆成 9 组（头/躯干/左右臂/左右手/左右腿/足） |
| `src/cloth.gd` | 袍身放样、袖、交领刷色、腰封、垂绦、软体下摆、眼/眉/嘴贴片、发帽、靴 |
| `src/face_decal.gdshader` | 五官贴片（mode 0 眼 / 1 眉 / 2 嘴，side 镜像） |
| `src/face.gdshader` | 皮肤 + 鼻影 + 头发区域（按模型坐标判定） |
| `src/eye.gdshader` | 单眼贴片（眼白/上睑/瞳孔） |
| `src/item3d.gd` | 物品引擎：旋转体/椭球/锥/倒角，品阶×属性矩阵，批量化出图 |
| `src/icon_light.gdshader` | 图标专用光照（世界空间主光 + 天光 + 地面反弹 + 镜面） |
| `src/head_deform.py` | Blender 脚本：压眉骨/收下颌/低鼻梁/整脸收窄，导出 `character_ea.glb` |
| `docs/CHARACTER_SPEC.md` | **标准参数表**（7.5 头身、肩腰摆、袖长、交领角度、配色） |
| `docs/GARMENT.md` | 服饰流水线：四类生成器 + 九件部件清单 |
| `docs/RECOVERY.md` | 踩坑记录（脚本被写坏、绕序、软体撕裂、A-pose 爆炸） |
| `docs/PIPELINE.md` | 六工位 + 四道关的流程 |
| `shots/` | 四视角、九组拆分、物品与生物拼图 |

## 已达成
- 九组拆分可单独查看与替换（`shots/parts.png`）
- 袍有独立体积（不再是从人体外扩的"泳衣"）
- A-pose 下垂袖、锥形下摆、V 交领 + 金边、腰封 + 垂绦、发帽 + 发髻、靴
- 物品：旋转体引擎，5 品阶 × 5 属性矩阵，120 件批量出图

## 未达成（交给下一个接手者）
1. 袖口内壁是黑盘（末端开口朝镜头）→ 需要给袖口加内衬色/收口
2. 后脑发片与头壳穿插，颈部有浅色污渍
3. 脸仍是 Quaternius 骨相（西式深眼窝），只有 Blender 改骨相能根治
4. 下摆软体在腿碰撞处仍会撕裂 → 需要更多 pin 行或换 cloth 方案

## 复现
```bash
# 环境：Godot 4.4.1 arm64 + Xvfb :99
DISPLAY=:99 godot --path <project> --rendering-driver opengl3 \
  --resolution 620x820 res://rig/cloth.tscn -- --yaw=0
```
