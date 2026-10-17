# 《苍岚·人生世界》 WorldXAI Style Lock v2 HQ3D — 唯一当前美术基准

**取代** `CANGLAN_WORLDX_STYLE_LOCK.md` 的旧「低饱和/固定斜俯视/四合院透明PNG即最终资产」规范。v1 只供历史项目审计。完整用户来源 `docs/CANGLAN_HQ_ART_ECOLOGY_EXECUTION_REPORT_USER_20261018.md`；硬性 P0 `docs/CAC_REV208_HQ_EXECUTION_CHECKLIST_20261018.md`。

## 目标

自由第一／第三人称、统一古代中国审美、可自然游历/交互的高品质**真3D修仙手游**。高精国风人体比例，男子束发/发髻/冠/簪、女性发髻簪钗，交领和层叠古风丝麻锦袍，真实五官皮肤头发衣纹与剑饰；不强称某真实朝代考据。成熟树林8–20米，乔木/幼树/灌木/草蕨/苔藓/落叶四层，深绿/墨绿/翠绿/青绿分材质丰富，暖白阳光/冷蓝天光/淡蓝大气透视，地表2–8厘米尺度真实PBR细节。不允许肉眼可见的低模截面、方块手头、明显欧美fantasy或大量空白绿地。

## WorldXAI只负责可审核的视觉参考

- **人物四视图**：正面、侧面、背面、3/4角；成年人7.5–8头身，neutral A-pose、全身手足不裁切、统一灯光白/灰背景、四个角度造型绝对一致。一个人一个固定seed/角色ID。
- **核心修士组**：4个以上不同身份：剑修/丹师/符师/长老/御兽；五官、发式、服装、腰带、法器与磨损层独立。不得复用西方Knight/Wizard头模，只换色。
- **大树**：成人乔木10–18米，树干0.5–1.3米，树冠不对称自然缺口、树皮裂纹苔藓、明确枝层，前/侧/顶视概念；幼树另为独立生长期。灌木0.4–1.8米；草/蕨/苔/菌体必须不同物种轮廓。
- **灵草**：0.2–0.8米株高，茎叶花或果各异、幼株/成株/采摘后形态不同、局部叶脉花蕊露珠微亮，整体自然色，**6–10米脱离UI依然可辨识**；红蘑菇仅菌类，不覆盖绿地。
- **地表**：森林土/落叶/草/苔/微石混合，鸟瞰正交可平铺BaseColor视觉参考，2–8cm细纹、2–8m群落宏观层，禁止画入大阴影；Normal/ORM要用经来源核验的物理PBR，禁止AI猜出“正确PBR”。
- **综合目标机位**：35–50mm等效第三视角自然远近关系，主角和成人高树同时入画，正面暖阳/阴影冷天光、色彩层次深而可读，不靠全局饱和度强行提亮。

## Negative 全类别（强制）

`low-poly, visible polygon facets, blocky body and leaves, chibi, voxel, pixel art, western knight, wizard hat, medieval Europe, modern haircut, modern zipper, flat green ground, tiny toy trees, all-red fungus shrub, glowing cylinder herbs, blown-out white haze, plastic materials, inconsistent angles, painted building facades pretending full 3D, baked shadows in basecolor, blurry texture, watermark, random text, logo, extra fingers, deformed anatomy, cropped hands/feet`。

## 工厂级审核和转成真3D

1. 登记源图 ID / 生成模型 / 图像模型提供方 / 许可 / prompt版本 / seed / 源SHA。**WorldXAI图像提供端不实际可调用时必须写 `BLOCKED_PROVIDER`**，不能使用其他AI工具结果冒名。
2. 自动筛选：背景透明或干净、无水印/AI字、同角色多视一致、尺度合理、人物手面完整、植物不混种/不假高精。失败素材进隔离区，不能自动发布。
3. 高精3D必须经雕刻/重拓扑/UV/PBR/蒙皮/BlendShape/动作/LOD/低模碰撞；仅“图片画得漂亮”不算真游戏模型。
4. 具体资产统一进 `game-source/apk176-ota177-candidate/assets/hq-rev208/{characters,vegetation,terrain,beasts,buildings,provenance}/`；每资产保存作者/URL/许可/SHA/实测面数/LOD/贴图通道/来源引擎证据。
5. 同机位在**原版Godot 4.4.1实际Main**捕近景人物、背影发髻、NPC、成熟森林、灵药与普通草、灵矿妖兽战斗、NPC死亡≥7张，和概念图分文件夹并明示来源。
6. Godot截图自动脚本 PASS、多人美术审核 FAIL时仍不得签名发布；严格发布条件见完整用户报告与执行清单。

**状态（2026-10-18）**：v2规范已经入库，**尚未代表WorldXAI图像批次产生、高精角色模型实际接入、用户视觉满意或rev208发布**。
