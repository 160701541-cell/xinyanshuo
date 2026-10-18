# REV208 HQ-ECOLOGY 国风森林地表 PBR 与真实扫描地被 —— 执行报告

- 日期：2026-10-18
- 分支：`agent/dsh-p0-xianxia-ecology`（基于 rev208 候选 `f1bc797`）
- 代码提交：`c4bfdd6`
- 对应清单条目：**REV208-HQ-003 / REV208-HQ-020 / REV208-HQ-022**
- 发布状态：**候选源，未合并 main、未 RSA 签名、未改 `android-preview/latest.json`、未产 APK**

## 1. 为什么做这一轮（先查后做）

按 `AGENTS.md` 的首次阅读顺序读完 5 份规范后，先核对了 rev208 分支现有生态资产的实际数据，发现真实缺口（不是重复劳动）：

| 现有资产 | 真实状态 |
|---|---|
| `assets/hq-rev208/vegetation/trees/manifest.json` | 3 棵成熟树是 oak / maple / linden —— **欧洲行道树**；`texture_resolution` 与 `material_channels` 均为 `NOT_MEASURED`，**完全没有任何贴图**，只有 baseColorFactor |
| 同上 | `triangle_lod1` / `triangle_lod2` 均为 `NOT_PRODUCED` |
| `materials/rev207/` | 只有 512² 的灰泥 / 瓦 / 木三组**建筑**贴图 |
| 地表 | 靠 256² 程序生成 grain + 顶点 biome 色，**不是真源 PBR** |

结论：`REV208-HQ-022`「Poly Haven 类合法 CC0 真源贴图建立 macro 2–8 m、detail 2–8 cm 两级地表着色，Normal/ORM 通道逐源核验，8K 源不直接装入安卓 PCK」**一直没有落地**。本轮就补这一条，并顺带补 `HQ-020` 缺的灌木 / 地被 / 蕨 / 苔 / 山石层级。

## 2. 素材清单（全部 CC0，逐资产页面核验，无任何 AI 生成图）

来源：**Poly Haven**（<https://polyhaven.com>，全站 CC0，许可证页 <https://polyhaven.com/license>）。
完整机器可读记录：`game-source/apk176-ota177-candidate/assets/hq-rev208/ecology-intake-provenance.json`
（含每个文件的 SHA256、官方 MD5、源 URL、真实像素尺寸、通道布局、glTF 真实三角面数）。

| 用途 | 源资产 | 作者 | 许可证 | 纹理 | 通道 | SHA256(前16) |
|---|---|---|---|---|---|---|
| 林地腐殖落叶地面（主要地表） | `forrest_ground_01 (Forest Ground 01)`<br>https://polyhaven.com/a/forrest_ground_01 | Rob Tuytel | CC0 | 1024x1024 | albedo:sRGB / normal:linear GL+Y / orm:linear R=AO,G=Rough,B=Metal | `3dd6875cb3908e02` |
| 林缘草甸 | `leafy_grass (Leafy Grass)`<br>https://polyhaven.com/a/leafy_grass | Charlotte Baglioni | CC0 | 1024x1024 | albedo:sRGB / normal:linear GL+Y / orm:linear R=AO,G=Rough,B=Metal | `cfa40bc9d9417d18` |
| 湿润落叶泥土 | `brown_mud_leaves_01 (Brown Mud Leaves 01)`<br>https://polyhaven.com/a/brown_mud_leaves_01 | Rob Tuytel | CC0 | 1024x1024 | albedo:sRGB / normal:linear GL+Y / orm:linear R=AO,G=Rough,B=Metal | `c598c555f13cd532` |
| 稀疏草地（林间空地） | `sparse_grass (Sparse Grass)`<br>https://polyhaven.com/a/sparse_grass | Amal Kumar | CC0 | 1024x1024 | albedo:sRGB / normal:linear GL+Y / orm:linear R=AO,G=Rough,B=Metal | `ae94f2b34597b910` |
| 细枝落叶细节层 | `forest_leaves_02 (Forest Leaves 02)`<br>https://polyhaven.com/a/forest_leaves_02 | Rob Tuytel | CC0 | 1024x1024 | albedo:sRGB / normal:linear GL+Y / orm:linear R=AO,G=Rough,B=Metal | `2bac85cdc76927fa` |
| 苔藓山石表面 | `mossy_rock (Mossy Rock)`<br>https://polyhaven.com/a/mossy_rock | Rob Tuytel | CC0 | 1024x1024 | albedo:sRGB / normal:linear GL+Y / orm:linear R=AO,G=Rough,B=Metal | `4dbf37f1b0465c9c` |
| 中国雪松/古柏树皮（古柏用） | `chinese_cedar_bark (Chinese Cedar Bark)`<br>https://polyhaven.com/a/chinese_cedar_bark | Charlotte Baglioni | CC0 | 1024x1024 | albedo:sRGB / normal:linear GL+Y / orm:linear R=AO,G=Rough,B=Metal | `53e388eda1394bcb` |
| 疙瘩松树皮（苍松用） | `knotted_pine_bark (Knotted Pine Bark)`<br>https://polyhaven.com/a/knotted_pine_bark | Dimitrios Savva | CC0 | 1024x1024 | albedo:sRGB / normal:linear GL+Y / orm:linear R=AO,G=Rough,B=Metal | `e90289609b11ddb4` |
| 蕨类丛 | `fern_02 (Fern 02)`<br>https://polyhaven.com/a/fern_02 | Rob Tuytel / Rico Cilliers | CC0 | 1024x1024 | material#0(fern_02): baseColor+metallicRoughness+normal | `bd529946a7e67689` |
| 低矮灌木 | `shrub_03 (Shrub 03)`<br>https://polyhaven.com/a/shrub_03 | Rico Cilliers | CC0 | 1024x1024 | material#0(shrub_03): baseColor+metallicRoughness+normal | `4d3536ccd6569a91` |
| 苔藓块 | `moss_01 (Moss 01)`<br>https://polyhaven.com/a/moss_01 | Rob Tuytel | CC0 | 1024x1024 | material#0(moss_01): baseColor+metallicRoughness+normal | `e2ebebdfb6adb8eb` |
| 苔藓山石组 | `rock_moss_set_01 (Rock Moss Set 01)`<br>https://polyhaven.com/a/rock_moss_set_01 | Kless Gyzen | CC0 | 1024x1024 | material#0(rock_moss_set_01): baseColor+metallicRoughness+normal | `89afc1e782371895` |

> 面数说明：`moss_01` 只有 204 面，是 Poly Haven 源对「苔藓块」的真实精度；manifest 里已显式标注
> **「低于1000面：只能做贴地细节，不得当作独立高模植被」**，不冒充高精。

纹理预算：所有 albedo / normal / ORM 都是 **1024×1024**（源可达 8192×8192）。
按报告要求「8K 源不直接装入安卓 PCK」，本工具只领取 1K；单文件最大 1.42 MB，总计 28.7 MB。

## 3. 工具：可复验的入库管线

`tools/asset_factory/rev208_ecology_polyhaven_intake.mjs`

```bash
# 联网取证并入库（校验官方 MD5 + 字节数 → 自算 SHA256 → 解析 JPEG 尺寸 → 解析 glTF 面数）
node tools/asset_factory/rev208_ecology_polyhaven_intake.mjs --fetch

# 完全离线复验：44 个文件全部重算 SHA256，并重新解析 glTF 数面
node tools/asset_factory/rev208_ecology_polyhaven_intake.mjs --verify
```

实跑输出：

```text
PASS_REV208_HQ_ECOLOGY_POLYHAVEN_CC0_INTAKE textures=8 models=4 files=44 bytes=28735060 largest_file_mb=1.42
```

`tools/stage_rev208_hq_ecology.py --dest <项目根>` 按清单把资产装进 PCK 树
（`res://canglan_rev187/hq_ecology_terrain/**`、`res://canglan_rev187/hq_ecology_groundcover/**`），
逐文件复算 SHA256，不一致直接非 0 退出。本机 QA 与 CI 走同一份逻辑。

## 4. 真游戏接入（不是只下载）

1. **新增** `scripts/apk176_hq_terrain_pbr_rev208.gd`
   - macro 层 2–8 m（每个材质有独立的 `macro_metres`），detail 层 2–8 cm；
   - 混合权重来自**真实世界坐标噪声 + 真实世界法线坡度**，不是调色；
   - ORM 严格按 Poly Haven `arm` 布局 **R=AO / G=Roughness / B=Metallic**；
   - albedo 用 `source_color`（sRGB），normal 用 `GL+Y` 线性；
   - `build_bark_material("pine"|"cypress")` 给苍松 / 古柏树干真源树皮 PBR；
   - `spawn_groundcover()` 布置 4 类真实扫描地被，每株独立 `world_entity_id`，按真实地形高度落地；
   - `apply_bark_to_tree()` 只接管**原本没有任何贴图**的表面，第三方已有 UV/PBR 一律保留。

2. **修改** `scripts/apk176_vivid_material_rev207.gd`
   `material_for_real_terrain("natural_ground", …)` **委派**给新模块；构建失败自动回落旧 micron 方案并记录 `hq_ecology_status`；`soil` / 石壁等其它角色保持原逻辑不变。

3. **修改** `scripts/apk176_living_resource_world_rev187.gd`
   在原 botanical 生态之后接入 `_spawn_rev208_real_scanned_groundcover()` 与 `_apply_rev208_real_bark()`；
   **资源不在包里时整段安全跳过，并把 `skipped` 原因写进 `rev208_groundcover_report`，不伪造一株植物**。

## 5. 真实 Godot 4.4.1 验证结果

本机使用官方 **Godot_v4.4.1-stable_linux.arm64**，`--import` 全部 40 个资产后跑真引擎断言：

```text
=== rev208 HQ-Ecology real Godot verification ===
engine: 4.4.1-stable (official)
  model fern_clump       tris=6232    uv_surfaces=4 normal_mapped=4
  model shrub_low        tris=8287    uv_surfaces=4 normal_mapped=4
  model moss_patch       tris=204     uv_surfaces=12 normal_mapped=12
  model rock_moss_set    tris=63127   uv_surfaces=6 normal_mapped=6
  ground material OK  macro=0.167 tiles/m detail=16.67 tiles/m
  bark pine     albedo=1024x1024 normal=true
  bark cypress  albedo=1024x1024 normal=true
  pbr sets loaded: 6 / 6
  vivid delegation OK: HQ_TwoScale_RealCC0_PBR_Ground_REV208
  groundcover spawned=36 species={ "fern_clump": 10, "shrub_low": 8, "moss_patch": 12, "rock_moss_set": 6 }
=== checks=213 failures=0 ===
PASS_REV208_HQ_ECOLOGY_REAL_GODOT441_TWO_SCALE_PBR_GROUND_AND_GROUNDCOVER
```

断言覆盖：24 张贴图真解码 + SHA256 一致 + 尺寸在手机预算内 + albedo 绿色通道 stddev > 0.035（证明不是纯色图）+ ORM 绿通道有梯度（证明粗糙度通道真实）；4 个 glTF **引擎内实测面数与清单完全一致**且有 UV0 与法线贴图；两级材质真的被 `material_for_real_terrain` 返回；非地面角色没有被误替换；36 株地被真的挂在世界节点下且 ID 唯一。

另对**被改动的世界脚本**单独跑 `--check-only`：`exit 0`，无解析错误。

## 6. 本轮错误日志与真实阻塞（不隐藏）

| 项 | 真实情况 |
|---|---|
| Poly Haven 模型贴图 404 | glTF 里写 `textures/<name>`，实际位于 `Models/jpg/1k/<id>/`。已改为从 files API 同名 URL 取，回退相对路径 |
| 首轮下载 111.66 MB | `pickFile` 优先取了 PNG（16bit/无损，单张 5–6 MB）。改为优先 JPG 后降到 27.40 MB |
| `moss_01` 只有 204 面 | Poly Haven 源就是这样。断言下限改为 100 并显式标注「不得当独立高模」，不冒充 |
| 导出包里取不到贴图 | 初版用 `Image.load("res://*.jpg")`，在真实 PCK（jpg 已导入成 `.ctex`）会失败。已改为 **ResourceLoader 优先 + 裸文件回退** |
| `build_ground_material()` 首次返回 null | detail 层 slug 没被 `initialize()` 加载。已加 `DETAIL_SLUGS` |
| **LOD1/LOD2 仍 `NOT_PRODUCED`** | 本机容器无 Blender / meshoptimizer 抽面链路；`pip install` 重依赖在离线常态下不可靠。**如实记为阻塞**，不用「加细分假造」或「直接塞 17M 面扫描树」充数 |
| **无法本机出图** | 容器内无 `/dev/dri`，没有 GPU/Vulkan，headless 不能渲染。七张 `real_godot_rev208_*.png` 仍须由 CI（Mesa/Vulkan）或实机产出 |
| **Poly Haven `pine_tree_01` 不可用** | 1K glTF 的 `.bin` 实测 **948 MB / 17.4M 三角面**，明确不适合手机，**未入库** |

## 7. 未完成 / 下一步

1. 七张真实 Main 截图（`real_godot_rev208_*`）→ 美术审美判定，须 CI 或实机；
2. 成熟树 LOD1/LOD2 抽面链路（需 Blender 或 meshoptimizer）；
3. **真正的高精苍松 / 古柏 / 灵木 GLB** 仍是 P0 缺口 —— 本轮只做到「已有松柏 + 真源 CC0 树皮 PBR」；
4. 灵草 5–8 种独立轮廓与幼株/成株/采摘后状态（`REV208-HQ-023`）；
5. 主角与 ≥4 名核心修士（`REV208-HQ-010~013`）本轮完全未动，仍 FAIL；
6. **Android 真机 30 分钟 FPS / 发热 / 触控：一行实测都没有，全部 `PENDING_PHONE`**。

## 8. 提交前自检

> 「这次玩家是不是只需要打开手机里原来的《苍岚》，就能从游戏内自动得到更新？」

**否。** 本轮是分支上的源码 + 合法素材 + 真引擎技术验证，尚未合并、未签名、未部署。
只能称「源码 / QA 进度，尚未完成原版热更新」。
