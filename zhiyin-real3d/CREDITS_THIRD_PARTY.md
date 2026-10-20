# 《知音》真实3D技术测试：第三方许可

本项目所有第三方模型及动作保留许可记录，进入最终安卓产品前需要再次核实上游授权与再分发条件。

## Quaternius · Universal Base Characters [Standard]
- 源作者 Quaternius，免费Standard版本 CC0-1.0。
- 原发布页：https://quaternius.itch.io/universal-base-characters
- 项目使用65骨骼女性底模及完整纹理、Quaternius原版头部/面部、Hair_Long发型与蒙皮。
- 固定镜像源 `La2o/BlackVein` 提供原文件，commit `16ef4707f0403a7942384fdbd960789a5c6adb86`；文件SHA记录在自动生成的 `ASSET_MANIFEST.json`。

## Quaternius · Modular Character Outfits — Fantasy [Standard]
- 原作者 Quaternius，免费版 CC0-1.0。
- 装束 `Female_Peasant.glb`：已有衣裙鞋靴的真实Humanoid网格，不是未穿衣的底模。骨骼名与Quaternius基本角色逐项比对。
- 固定源 `ecbarish/generations` commit `8df479c9485969ff4ed6de8fd691e1a5e6094a3d`，源许可 `shared/assets/characters/quaternius/LICENSE-outfits.txt`，原文件SHA256 `e44904ed8c71dc76cd6641eb2ce4c26d6c0a7f043d66bef6e08dd2c18115bab8`。
- 原有衣服网格不包含脸、完整头部和头发。工程中的 `scenes/character_head.gd` 将CC0原始女性头部、眼睛、眉毛和长发蒙皮合并到同一65骨Skeleton3D，避免最终模型无头。

## Quaternius · Universal Animation Library 1 [Standard]
- 原作者 Quaternius，免费 Standard CC0-1.0。
- 43个原始骨骼动作（非手脚程序摆动），动作含 Idle、Walk、Sitting_Idle、Interact 和 Idle_Talking。
- 来源：https://github.com/Barbatos6669/elderforge/tree/bb2ce469f0ab2ccfc487faef55550ba07fae2483/assets/animations/universal_animation_library_1

## Kenney · Furniture
- 作者 Kenney，CC0-1.0。
- 17种真实GLB模型与材料，固定commit `3694c6879e487c108f55677be7dd2ca75b07cc3b`。
- 来源：https://github.com/shorepine/kenney

## BLACKVEIN Contributors — MIT License Notice
本工程 `character_head.gd` 中针对骨骼权重筛选头部的技术方法参考其开源 `scripts/person.gd`，已进行定向实现。

MIT License

Copyright (c) 2026 BLACKVEIN contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
