# NPC FaceMorph：让每个 NPC 长不同的脸

同一个底模（`character_ea.glb`）按 NPC 的 id 生成稳定、各不相同的脸。只改骨相/体块，
不碰五官贴片；位移很小（≤ 1 cm 量级），所以眼/眉/嘴贴片仍然对得上。

## 文件
| 文件 | 作用 | 状态 |
|---|---|---|
| `src/npc_face_morph.gd` | Godot 端：id → 11 个参数；位移场 `displace()`；对节点树里所有网格施加变形 | 本机无 Godot，**未实机运行** |
| `tests/npc_face_morph_test.gd` | GDScript 无头测试（金标准、对称、颈部不动） | 同上，**未运行** |
| `tests/npc_face_params_ref.py` | `params_from_id` 的 Python 独立实现，给 GD 测试提供金标准 | 已运行 |
| `src/face_morph_core.py` | 早一版的 Python/numpy 核心：8 参数 + 6 个身份原型（villager/merchant/…），可离线烘焙 | 已运行 |
| `tests/test_face_morph_core.py` | 上一个文件的 19 个单元测试 | 全部通过 |

## 用法（Godot）
```gdscript
const FaceMorph = preload("res://tools/character-pipeline/src/npc_face_morph.gd")
var params = FaceMorph.params_from_id("npc_001")              # 稳定：同 id 永远同脸
var stats  = FaceMorph.apply_to_tree(character_root, params)  # 必须在 cloth.gd 的 _grab() 之前
```
- `strength` 控制整体幅度（0 = 底模），`bias` 可按参数名叠加偏置，例如 `{"nose_bridge": -0.3}`。
- 位移场只依赖点位置：对身体/眼睛/眉毛网格用同一个函数，它们会和脸皮一起动。
- 头底（下巴以下）位移恒为 0，不影响脖子以下的身体、袖、袍；左右严格镜像。

## 参数（顺序固定，改顺序会让所有 NPC 换脸）
`face_width, jaw_width, chin_length, chin_forward, cheek_bone, brow_ridge,
eye_socket_depth, nose_bridge, nose_tip, nose_width, forehead`，取值 [-1, 1]，0 = 底模原样。

## 已知问题（接手前请先看）
1. **有两套并行的实现，种子算法不同**：`face_morph_core.py` 用 FNV-1a + mulberry32、8 参数；
   `npc_face_morph.gd` 用 FNV-1a + xorshift32、11 参数。同一个 id 在两边得到的脸**不一样**。
   `face_morph_core.py` 文件头注释里提到的 `face_morph.gd` 并不存在。
   建议以 `npc_face_morph.gd` 为准（它有配套的 Python 参考），再决定是否保留 `face_morph_core.py`
   里的身份原型（archetype）并移植过来。
2. GDScript 部分与 GD 测试都没有在真实 Godot 里跑过；`_renormal()` 在 7k 顶点量级的网格上
   用 Dictionary 焊接，速度未测。
3. 位移幅度（`SCALE`）是按数值标定的，**还没有对照截图验收**，需要用 `glbshot.gd`
   出一组极端参数的四视角图再调。
