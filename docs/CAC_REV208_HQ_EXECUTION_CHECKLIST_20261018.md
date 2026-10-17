# 《苍岚》rev208 高精美术—生态—战斗正式执行清单（用户批准：2026-10-18）

> **性质：发布阻断型 P0/P1 工单，而非概念规划。** 全文原始报告：[`CANGLAN_HQ_ART_ECOLOGY_EXECUTION_REPORT_USER_20261018.md`](CANGLAN_HQ_ART_ECOLOGY_EXECUTION_REPORT_USER_20261018.md)。以后每轮“继续”先读 `AGENTS.md` → `docs/DEVELOPMENT_EXECUTION_RULES.md` → 此清单 → `docs/CAC_CHANGELOG.md`，从第一个未通过项接续；在有证据前不得打勾。原报告中动态版本/CI状态如与新证据冲突，以**当日真实GitHub Manifest、原版Godot验证与公开更新链**为准，不改写用户需求。

## 第一阶段：冻结错误模型与 HQ-Art-Lock（P0）

- [ ] **REV208-HQ-001** WorldXAI/正式可调用图像端产出统一 **v2 HQ3D** 主角四视图（正/侧/背/3⁄4）、服装/发型、成熟树林、灵药、湿润山地地表、日照目标帧。若生成端未接通，标 `BLOCKED_PROVIDER`；不能把聊天中的AI插图当作WorldX产物或游戏实机。
- [ ] **REV208-HQ-002** 用户认可统一风格：不再遵守旧 WorldX style v1 的“低饱和、固定斜俯视、四合院拆PNG、手绘2D即最终画面”；覆盖为高品质**自由第一/第三视角真3D国风**，翡翠绿/墨绿/深绿，可信古代发髻/冠簪/交领、真实材质尺度，拒绝西方骑士/魔法师和肉眼可见低模块面。旧世界 **NPC建造和资源经济**规则仍有效。
- [ ] **REV208-HQ-003** 完成资源追溯manifest（每资产 `source_name/author/source_url_or_asset_id/license/original_sha256/converted_sha256/LOD0-2 triangles/texture_resolution/material_channels/collision_type/godot_import_notes`）。许可证未逐模型核实的 Poly Pizza 资产禁止入库。未测量数据写“未指定”。
- [ ] **REV208-HQ-004** Kenney `tree_oak.glb` 只充当幼树/远景LOD，`bush.glb` 不充当通用绿灌木，`animated_knight.glb` 不充当近景玩家/核心修士，`wizard.glb` 不充当核心东方修士；原实体ID、存档、旧素材和低级LOD回退不得删除。

## 第二阶段：HQ-Character（P0，先一名合格玩家，再四名核心修士）

- [ ] **REV208-HQ-010** 接入一名合法来源、可复验真高精**国风**主角GLB：成年人7.5–8头身、细脸眼、正常手脚、古风长发束髻/簪冠、青绿/藏蓝多层真实衣服与纹理/Normal/Roughness；LODs0/1/2建议主角120k–180k/60k–90k/20k–35k tris，仅为**目标预算**，由GPU实测调优，禁止从低模加细分假装有效纹理。
- [ ] **REV208-HQ-011** 统一Humanoid骨架真实动作：Idle、8向移动、跑、跳、普攻、受击、倒地/死亡、御剑，手脚确实运动；相应脸/发/衣/剑近景视觉证据；布料/头发不穿模、鞋底落地。Quaternius Universal Animation Library仅作为许可核查后的动画底库。
- [ ] **REV208-HQ-012** 至少**四种真正独立外观**的核心修士；宗门长老/炼丹/符箓/剑修/御兽等不可全套同一 Knight 模型换色；高阶可用LOD0目标70k–110k tris，普通45k–70k（预算建议，非既有实测）。凡人/杂役低一档可接受，但不准方块脸手、欧美骑士轮廓。
- [ ] **REV208-HQ-013** 人物近景必须有真实Godot全身正面/侧面/背面、脸部特写（屏高≥40%可分辨眉眼发丝衣料），不能只上传示意图。

## 第三阶段：HQ-Ecology + World-PBR（P0）

- [ ] **REV208-HQ-020** 至少**3成熟大树 +2幼树+4灌木/地被+4类草/蕨**，成熟树常规8–20米，高出玩家；不同树冠/树皮/枝形、镜头遮挡时透明/镜头自动处理；真土壤坡度/湿度/道路/房屋/水体禁种。
- [ ] **REV208-HQ-021** 生态植被按32m/48m Cell + 物种 + LOD分离资源池，活跃槽位连续、swap-remove、`visible_instance_count`；**逐slot检查真实Godot GPU transform**，避免过去 `IDENTITY`/原点幽灵，手机近景地表不出现大面积单色空白。
- [ ] **REV208-HQ-022** Poly Haven等合法CC0 PBR地表真源贴图建立 macro 2–8米、detail 2–8厘米两级着色；Alpha Scissor/Hash 叶子，Normal/ORM通道逐源核验；源8K不直接装入安卓PCK，手机纹理按1K/2K预算。全局 saturation不允许再作为万能修补工具。
- [ ] **REV208-HQ-023** 灵草至少**5–8种**独立轮廓和幼株/成株/采摘后生长状态；6–10米无名字标签仍能区分普通草；微弱叶脉/花蕊局部灵气，不整株霓虹；**原13处资源逻辑及库存/30天种子库不破坏**。灵矿有精确材质与真实护矿妖兽。
- [ ] **REV208-HQ-024** Godot Mobile不能以SSAO作承诺；暖阳4800–5200K视觉基准/冷环境7000–8500K、雾晴天密度0.00035–0.00065均为**调试起点**，不是未测即固定值；真正按同机位两版截图差异审美验收。
- [ ] **REV208-HQ-025** 所有可进入房屋真门洞/室内/床位/碰撞，NPC按有限物资施工；后续P1宗门建筑群、洞府、药园、四季、妖兽LOD同源生态扩展。

## 第四阶段：Combat-Life（P0）

- [x] **REV208-HQ-030 技术层已完成**：原Main修士索敌、耗体力/距离/遮挡检测、有限受伤、仇恨反击、HP=0永久死亡、不再移动/攻击、尸体姿态/禁碰撞、存档重载；**真实Godot QA run 39065966234 SUCCESS**，仅为分支源，尚未签名/手机实测。
- [ ] **REV208-HQ-031** 人形遭攻击要有真实受击硬直/格挡/闪避/倒地/死亡动画（不只静态 `rotation.x`）；尸体掉落物必须来自真人背包（非凭空造物），阵营/仇恨/因果，离线人口地区账本真实扣减，死后不复活。更新后重载和世界时钟仍一致。
- [ ] **REV208-HQ-032** 妖兽死亡外观/掉落、攻击动画、飞剑高度/视角和近身锁定镜头均实际Godot验收。

## 第五阶段：Mobile-Sustain → REV208-RC → REV208-SIGNED（全部P0）

- [ ] **REV208-HQ-040** 三档手机参数按源报告「极致/高/标准」试验。设备需记录GPU/画质档/3D scale、实际Draw与tris、平均FPS、1% low、内存、热状态；UI仍原生像素。若旧 `QUALITY_DEVICE_ACE5PRO.md` 的“禁止自动降档”与本报告“热严重时先降草/阴影/3D scale”冲突，**本报告的新可选热调节策略优先**；用户手动档不得被静默永久覆盖。
- [ ] **REV208-HQ-041** 必须交至少**七张同原APK176 Main Godot截图**：`real_godot_rev208_hq_player_close_front.png`、`real_godot_rev208_hq_player_back_hair_cloth.png`、`real_godot_rev208_hq_cultivator_npc_close.png`、`real_godot_rev208_mature_dense_forest.png`、`real_godot_rev208_spirit_herb_vs_ground.png`、`real_godot_rev208_mine_beast_guard_combat.png`、`real_godot_rev208_npc_death_state.png`；必须逐张按真人尺度/真实材质/可辨灵草/HP变化审查，概念图不得混入。
- [ ] **REV208-HQ-042** 用户原安装APK176 versionCode1176真实手机，从rev207保留旧存档进候选：主角转身360°、飞/降/索敌、进入屋内、森林/灵草/灵矿/击杀修士/重载；**连续30分钟**测中高低画质性能、温度、触屏和碰撞；没有设备结果始终 `PENDING_PHONE`。
- [ ] **REV208-HQ-043** 所有HQ高精P0视觉闸门真实PASS后才能准备PR #14从Draft转正式、合并main；原Main所有功能与截图+实机验收通过之后才签名rev208。RSA私钥只能在GitHub Secrets；新不可变 `canglan-content-rev-208.pck`，公网站点RSA/SHA256/整包下载/HTTP Range 206，`android-preview/latest.json`、官网、更新日志版本同步一致。rev207历史PCK不可覆盖。

## 当前状态（2026-10-18）

| 证据 | 状态 |
|---|---|
| 公网最新不可变RSA签名PCK | **rev207**，35,815,712字节，SHA256 `db64972a0615abbe0600919220398d11853b83cbd4c57121b125f12b10262812`；Android versionCode1176 |
| rev208候选 | **PR #14 Draft；不是正式更新** |
| Godot 4.4.1原 Main 代码逻辑/真实图片 | **QA PASS run 39065966234**；仅技术/引擎 |
| rev208主角/修士/森林/灵草视觉质量 | **FAIL/P0 BLOCKED**，不是近景高精；没有WorldXAI合法产出的高精3D资产 |
| Android真机30分钟 / 用户认可审美 | **PENDING** |
| 首个必须推进工作 | **HQ-Art-Lock → HQ-Character → HQ-Ecology**，不是给现有矮低模橡树继续调色或提前签名 |

每轮工程提交/测试必须在 `docs/CAC_CHANGELOG.md` 中记录：日期、原报告条目ID、当前状态、源码SHA、真实截图路径、Godot运行/作业号、质量门禁、是否发布/手机是否实测、阻塞和下一步。没有证据的任务只允许 `TODO`/`BLOCKED`，不得标PASS。
