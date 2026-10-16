# 原APK176 / rev183 · Kenney 五色 / MultiMesh 合批 / 简易日照 手机验收

状态：**原版 Godot 4.4.1 运行与 RSA 签名已通过，实机 Draw≤200 尚需现场核实，不得假写通过**。
用户要求保留 Kenney 低多边形风格，不引入不同风格的整栋房屋/人形；此批只改现成 CC0 资源绘制组织、材质及场景布局，保留 NPC 采集/种子/石层与实体建造守恒逻辑。唯一原手机应用包：`org.canglan.ancient25d.preview` (APK176, versionCode1176)。

## 第一步：五种主色（五色并非限制天空像素 RGB）
共用 `visual_palette.gd` 五种主材质色：草地 `#86a17b`、土路 `#b6a488`、叶冠 `#58978d`、木材 `#9a704e`、石料 `#8a8c9a`。对载入授权Kenney原GLB顶点保持不变，仅把其各mesh表面映射到统一材质对象；真正走出“树叶/树干不混色”仍要靠表面区分来源。太阳/天空与UI是照明而非第六种主要实体材质。

**手机怎么看**：打开原游戏检查更新rev183，进入3D劳动场景。在默认取景看到树林、矿石、土路三类区域：左林偏青绿、地面浅绿、道路暖土黄色、矿石偏冷灰。转动右侧镜头，看旧式乱色或部分树干被叶色覆盖的缺陷是否出现。目标美术品质按用户实机截图判定，不靠headless颜色推断。

## 第二步：真合批（不可把MultiMesh一个网格誓称所有物体仅一个draw）
`kenney_multimesh.gd`把**每份授权GLB的实际MeshInstance3D部分**实例化为MultiMeshInstance3D：树木/石头/木料/围栏/石阶/门分别合批，不做近百次对象mesh复制；原生态ID、资源坐标、可见性/生长比例、施工新增件由transform-only代理维持，每隔0.1秒同步矩阵。一种GLB可能有多个mesh与材质面，每种mesh需独立的MultiMesh，**真实Draw数还受其他原版网格、Quaternius有骨骼动态NPC、阴影通道和UI影响**。动态骨骼人物不硬合为静态网格，避免人物走路再次像僵尸。

**手机怎么看**：开启左上原版性能HUD，记录`Draw 当前/200`，对比rev182截图`645/200`。默认场景、绕视角一周、点击“看施工NPC”近距，逐一拍照；**所有场景Draw≤200且物品/NPC正常可见，才可标实机PASS**。现阶段没有新图，不能代替用户宣称达标。如果仍超200，回收确切实机HUD统计，下一批继续优化原版旧层和动态网格/材质。FPS、GPU耗时、三角面预算独立测，勿混为同一指标。

## 第三步：一太阳+短距离阴影、树林与矿石聚落、畅通物流土路
场景仅一盏`DirectionalLight3D`，`SHADOW_ORTHOGONAL`，阴影最远48米，无增设点光/聚光、无成本高昂实时GI；地面/土路共享五色材质。12棵原资源树依照两片随机扰动的林地分布左方（X≤-11），9处矿石依两片随机扰动矿组落在右边（X≥12）；中间一条7米宽的工作通路，仓库向两侧额外通行土路。生态未来播种确保不堵中路。

**手机怎么看**：先看全景左侧两片树林、右侧矿点、中间土黄通路与工地；注意光从侧上方照射时树底和石头一侧有没有柔和阴影。跟随施工NPC观察仓库→工地、林地/矿点→仓库有没有被树石阻断；旋转视角看阴影是否闪烁及帧率是否明显下降。

## QA证据和状态
- `game-source/apk176-ota177-candidate/scripts/apk176_kenney_visual_palette_rev183.gd` 五色资源库
- `game-source/apk176-ota177-candidate/scripts/apk176_kenney_multimesh_rev183.gd` 真MultiMesh批处理
- `game-source/apk176-ota177-candidate/scripts/apk176_living_resource_world_rev183.gd` 三项接入原游戏，保留NPC/生态
- `game-source/apk176-ota177-candidate/scripts/apk176_ecology_succession_rev183.gd` 继续守恒与禁堵路播种
- 实际原版继承Main场景 `main_original_visual_rev183.tscn`，`main_rev183.tscn.remap`
- 原版真实性`verify_original_main_visual_rev183.gd`要求恰好5色、真实MeshInstances批次、一个启用阴影的方向光、三条物理道路、植被与矿物各自离开中心走廊、动画NPC/收获/仓储/建筑守恒/原房屋回归；头less不冒充Android Draw监测。
- **原版APK176源代码/原RSA/游戏存档不被独立demo替换**。原版签名PCK rev183经Godot QA、验签发布至公开Git main：run`38976345665` / job`117226600219` completed/success；资源包21,607,520字节、SHA256 `5cccf09ed783638b2420f05986b4543c22d923d6289310ea6fe2c5e678e528a9`。游戏官网HTTPS CDN下载/客户端装载将单独复核。
