# 《苍岚·人生世界》NPC本地AI与现成CC0三维素材落地记录

**2026-10-17，用户已决定：不用自己建3D角色或建筑模型，不用AI生成完整房屋；从Kenney、Quaternius、Poly Pizza等合法免费现成资源获取外观。WorldX只做纹理材料，NPC根据世界规律自己建造。**

## 1. 现有可用真实素材

真实素材下载程序：`tools/asset_factory/import_cc0_model_packs.py`。只从已核验并固定Git提交的公开镜像获取**原作者既有资产**，逐文件检查Git Blob SHA和SHA-256，不创建或生成美术模型。结果放在`game-source/godot3d/assets/free_cc0/`，保留`import_provenance.json`。

- **Kenney**：CC0 1.0，官方网站 `https://kenney.nl/support`，`https://kenney.nl/assets/castle-kit`。已经导入树木、木料、石块、木栅栏、石阶、木门、木桥等7个低模GLB。
- **Quaternius**：CC0 1.0，官方 `https://quaternius.com/packs/medievalvillagemegakit.html`。免费Standard套装已导入3种**可拆卸组合**的3D件：灰泥墙、瓦屋顶、木箱，及对应共用外部纹理PNG和glTF二进制。没有将整栋预制房屋凭空生成为世界。
- **Quaternius角色**：CC0 1.0，从可复核公开派生项目导入已存在的`character.glb`（Humanoid骨架，暂缺内建动画）和`knight.glb`（骨骼，12条预制动画）。不能将有骨骼=已经实现流畅走路。须对动画名称、重定向、比例、手机渲染做独立Godot/安卓QA后再替换NPC外观。
- **Poly Pizza**：版权不是统一CC0。按`https://poly.pizza/docs/tos`，每个模型可能分别采用CC0或CC-BY；必须先记录具体模型、作者、原下载链接、许可版本；CC-BY需符合署名条件。**目前暂未导入任何Poly Pizza模型**，不声称它们全部可无署名再分发。

公开仓库Godot 4.4模型工厂已在真实GitHub Action `38948880609` 首批成功完成：**Kenney与Quaternius 10种真正可加载的3D资源**，22个依赖文件的Blob/SHA校验，Godot真实实例化和MeshInstance3D检查通过，源码Commit `24249ff`。之后添加2种真正的Quaternius派生角色模型，CI `38949607844`完成**12种真实Godot模型+24文件**的同等严格入库校验。它们是**真实资产**，不是AI生成或自研模型，也不是原手机APK的新热更新。

美术桥：`scripts/cc0_asset_bridge.gd`；`scripts/npc_building_system.gd`现在按库存建设流程，在真实3D材料仓库放置CC0木料与石头，建房阶段的Quaternius模块已加载为需视觉审核的候选节点，暂不挤掉真实分阶段几何体、碰撞或实体ID。建筑依然由樵夫、采石工、木匠、石匠、陶工和搬运/建筑NPC加工生产及运送材料。

## 2. NPC拥有本地AI“意向”，但AI不等于世界权威

- 实际本地推理底座已存在：`Qwen3-0.6B.Q4_K_M.gguf`（Apache 2.0）、`llama.cpp b6000`（MIT）、`Godot 4.4.1 C++ GDExtension`。下载权重前须验证许可、哈希和存储条件。无真实模型权重、动态库、内存时**必须显式显示不可用**，不得用脚本假装模型说话。
- `scripts/local_ai_service.gd`现区分`dialogue`（NPC与玩家说话）与`intent`（NPC想下一步做什么），共享单套模型、串行推理、限词限上下文，不做80份模型的并发常驻；已有离线状态检查及合法房屋/食物等局部事实入提示词。
- `scripts/npc_intent_policy.gd`只能解析允许的行动类型，校验NPC身份、精力、职业、现实库存/工地和频率；例如偷改别人ID、凭空发金币、作弊建房一律不能执行。世界物资库存、NPC职业、房屋施工阶段始终由Godot的真实模拟处理，不接受模型直接改变游戏数据。
- C++ native曾硬编码“只输出角色会说的话”，导致`ACTION=`意向模式与真正本地模型系统提示冲突；已经修改`local_ai/native/canglan_local_llm.h/.cpp`使`request_reply`可显式设置`intent_mode`，`local_ai_service.gd`用`48,true`调用，让模型**能够真正输出行动意向**。C++编译与Android ARM64真机推理必须另行严格验证，不可把静态代码变更写成已经手机推理通过。
- 现有绝大多数NPC继续使用无需AI的稳定职业/饥饿/精力/运输/施工算法；本地模型只给具有明确边界的个体意向层增益。长期需补足每人的长期记忆、家庭关系、技能、法律、可达路径、职业和经济动机、存档序列化。
- **本地模型需要原生Android推理GDExtension**。先核实原版APK176是否已有兼容的native ARM64库；若无，按用户“仅安卓底层组件升级才覆盖APK”的规则准备**一次兼容原包名与原安卓签名证书的原版底层升级**，并继续使用同一游戏内PCK热更新通道。不能将新项目的独立debug APK叫原版更新，更不允许用户反复卸载丢存档。

## 3. 质量红线及交付状态

- 模型资源必须做：官方许可核查、单文件SHA、Godot导入/材质/骨架、LOD和内存预算、可移动实体碰撞、导航、战斗/动作、60fps或设备指定标准的实际性能验收。GDScript本地测试不能代替手机真实测试。
- 原官网目前最新已签名正式热更新仍为`rev178`，**本页新3D资源及NPC本地意向代码尚未被原版手机游戏的签名PCK热更新验收**。不得拿独立APK代替。
- 已经取消严格3D QA里不必要的“每次重新生成程序GLB房子和人偶”，换为固定的、真实CC0来源素材与已有WorldX人物精灵必要时的过渡保底。不允许未来擅自恢复制作自研人形模型。

后续首要工作：严格验证Quaternius动画实际名称及移动效果→选择不违背中国古代画风的衣装/材质→接Godot已存在80个真实NPC的Identity组件→将他们自主建造的3D件统一风格，按优先级解决安卓底层离线推理与原版热更新兼容。
