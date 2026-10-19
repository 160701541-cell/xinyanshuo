# 底模骨相问题（为什么不“像中国人”）

## 根本原因
character.glb = Quaternius `SuperHero_Male`：
- 眉骨前突、眼窝深（西式英雄面相的核心特征）
- 下颌方且宽、颧骨高
- 鼻梁挺直偏高
- 肩宽腰窄（英雄体型），与“清瘦修士”不符

逐像素 shader 只能改皮肤上的图案（眼/眉/唇/肤色），改不了上述骨骼与体块。

## 仓库现有底模（只有三个）
| 文件 | 内容 | 能否用 |
|---|---|---|
| character.glb | SuperHero_Male，69 骨、1 skin、三网格 Face/Face.001/SuperHero_Male | 可用，但骨相是西式 |
| monk.glb | 低多边形雕像，黑蓝+金线，无骨骼 | 不可用 |
| dragon.glb | 单网格无骨骼 | 不可用 |

## 唯一可行路径：Blender 改骨相
用 bpy 对头部顶点做形变，再套回现有 shader 五官：
1. 压眉骨：z 在 [眉线, 眉线+2cm] 的顶点，沿 -y 收 3–5mm
2. 收下颌：z < 唇线的顶点，x 缩放 0.90、y 收 2mm
3. 低鼻梁：鼻区（|x|<1.5cm）顶点沿 +y 收 3mm
4. 脸收窄：全头 x 缩放 0.95
5. 导出覆盖 character_ea.glb，skin 权重不动，绑定不破

## 状态
- 未开始（本轮只做到“五官参数中式化”，见 out/face_cn2.png）
- 风险：Blender 导入/导出 glTF 会重排骨骼顺序 → 拆分脚本按“最大权重骨”分组仍可用，但要重跑 partsplit 验证

## 已执行（第一版形变）
- blender/head_deform.py：导入 character.glb → 取最大网格 SuperHero_Male（7281 顶点）
- 判定正面：头部 |y| 最大顶点为鼻尖，front = sign(y)
- 形变：整脸 x×0.955；下颌（z < 眼线−5.5cm）x×0.90、y−2mm；眉区（眼线上 0–2.5cm、正面）y−4.5mm；鼻梁中线（|x|<16mm）y−3.5mm
- 影响顶点：头 1493、眉 124、下颌 211、鼻 176
- 导出 character_ea.glb（保留 skin/骨骼），Godot 端可正常加载
- 对照图 out/ea_head_front.png
- 坑：glbshot 相机原在 -Z（模型正面是 +Z），所有早期“正面图”其实是背面；已改到 +Z。
