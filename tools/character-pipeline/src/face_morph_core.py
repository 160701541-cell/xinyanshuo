"""NPC FaceMorph 核心：把"头部骨相"变成 8 个可调参数，并按 NPC id 确定性地生成。

设计要点（为什么这样做）
1. 五官（眼/眉/嘴）是按模型坐标判定的贴片/着色器（face.gdshader、face_decal.gdshader），
   所以任何顶点位移都必须很小，否则五官和骨相对不上。→ 总位移硬上限 MAX_DISP（8mm）。
2. head_deform.py 用的是"硬切"区域（z 超过阈值就整体缩放），会在颈部和区域边界留下折痕。
   这里全部改成 smoothstep 软权重，并在头底（颈部接缝）渐变到 0。
3. 位移只用 |x| 的偶函数、且 x 方向只做"向中线收放"，因此 **左右严格对称**。
4. 同一个 NPC id 永远得到同一张脸：id → FNV-1a(32) → mulberry32，只用 32 位整数运算，
   GDScript 端（face_morph.gd）可逐步复刻，结果一致（见 GOLDEN 测试向量）。
5. 本模块只依赖 numpy，不依赖 bpy/Godot，所以可以单独跑单元测试。

坐标
HeadFrame 用三个轴下标描述头的朝向，Blender（Z 上、Y 前）与 glTF/Godot（Y 上、+Z 前）都能用：
    Blender : up=2, front=1, side=0
    Godot   : up=1, front=2, side=0
"""

from __future__ import annotations

import json
import math
from dataclasses import dataclass

import numpy as np

# ---------------------------------------------------------------- 参数表
# 每个参数的权重取值 [-1, 1]；AMOUNT 是权重 = 1 时的最大位移（米，或缩放比例）。
# 与 head_deform.py 的第一版形变量级对齐（眉 4.5–7mm、鼻梁 3.5–6mm、下颌 x 缩放 0.86–0.90）。
PARAMS = [
    "face_width",    # 整脸宽：x 缩放
    "jaw_width",     # 下颌宽：x 缩放（下半脸）
    "jaw_depth",     # 下颌前后：沿前向位移
    "chin_length",   # 下巴长短：沿上向位移（只动下巴）
    "brow_ridge",    # 眉骨前突：沿前向位移（眉区）
    "nose_bridge",   # 鼻梁高低：沿前向位移（鼻中线）
    "nose_width",    # 鼻翼宽：x 缩放（鼻区）
    "cheekbone",     # 颧骨高低/外扩：x 外扩 + 前向
]

AMOUNT = {
    "face_width": 0.040,   # ±4% 的 x 缩放
    "jaw_width": 0.080,    # ±8%
    "jaw_depth": 0.0030,   # ±3mm
    "chin_length": 0.0060,  # ±6mm
    "brow_ridge": 0.0045,  # ±4.5mm
    "nose_bridge": 0.0035,  # ±3.5mm
    "nose_width": 0.100,   # ±10%
    "cheekbone": 0.0030,   # ±3mm
}

MAX_DISP = 0.008           # 任何顶点最终位移不得超过 8mm（保护五官贴片对位）
NECK_FADE = 0.020          # 头底以上 2cm 内位移渐变到 0（颈部接缝不撕裂）


# ---------------------------------------------------------------- 头部坐标系
@dataclass
class HeadFrame:
    """由网格推出的头部标定（与 head_deform.py 同一套比例）。"""

    up: int
    front: int
    side: int
    front_sign: float
    head_z: float   # 头底（约下巴）
    eye_z: float    # 眼线
    zmax: float

    @staticmethod
    def from_mesh(verts: np.ndarray, up: int = 2, front: int = 1, side: int = 0) -> "HeadFrame":
        v = np.asarray(verts, dtype=np.float64)
        zmin = float(v[:, up].min())
        zmax = float(v[:, up].max())
        h = zmax - zmin
        head_z = zmax - 0.135 * h
        eye_z = zmax - 0.078 * h
        head = v[v[:, up] > head_z]
        if len(head) == 0:
            raise ValueError("找不到头部顶点（网格高度异常？）")
        nose = head[np.argmax(np.abs(head[:, front]))]
        sign = 1.0 if nose[front] > 0 else -1.0
        return HeadFrame(up, front, side, sign, head_z, eye_z, zmax)


def smoothstep(e0: float, e1: float, x: np.ndarray) -> np.ndarray:
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def _band(x: np.ndarray, lo: float, hi: float, soft: float) -> np.ndarray:
    """[lo, hi] 内为 1，两侧各 soft 宽度平滑过渡到 0。"""
    return smoothstep(lo - soft, lo, x) * (1.0 - smoothstep(hi, hi + soft, x))


# ---------------------------------------------------------------- 位移场
def displacement(verts: np.ndarray, frame: HeadFrame, weights: dict) -> np.ndarray:
    """返回每个顶点的位移向量（与 verts 同形状）。weights 缺省的参数按 0 处理。"""
    v = np.asarray(verts, dtype=np.float64)
    n = len(v)
    d = np.zeros((n, 3), dtype=np.float64)
    up, fr, sd, fs = frame.up, frame.front, frame.side, frame.front_sign

    z = v[:, up]
    x = v[:, sd]
    y = v[:, fr] * fs                      # 以"向前为正"的前向坐标
    ax = np.abs(x)
    in_head = z > frame.head_z
    # 头底接缝：从头底渐变到 NECK_FADE 以上才满权
    seam = smoothstep(frame.head_z, frame.head_z + NECK_FADE, z)
    front_gate = smoothstep(-0.005, 0.015, y)      # 只动朝前的半个头，不碰后脑

    w = {k: float(max(-1.0, min(1.0, weights.get(k, 0.0)))) for k in PARAMS}
    amt = AMOUNT

    def add_x_scale(mask: np.ndarray, scale: float) -> None:
        # 向中线收放：x 方向位移 = x * scale，偶函数 → 左右对称
        d[:, sd] += x * scale * mask

    def add_front(mask: np.ndarray, dist: float) -> None:
        d[:, fr] += fs * dist * mask

    def add_up(mask: np.ndarray, dist: float) -> None:
        d[:, up] += dist * mask

    head_mask = in_head * seam
    if w["face_width"]:
        add_x_scale(head_mask, w["face_width"] * amt["face_width"])

    # 下半脸：眼线下 5.5cm 以下满权（与 head_deform.py 的下颌判定同一界线），
    # 往上 2cm（眼线下 5.5cm → 3.5cm）平滑渐隐到 0
    lower = (1.0 - smoothstep(frame.eye_z - 0.055, frame.eye_z - 0.035, z)) * head_mask
    if w["jaw_width"]:
        add_x_scale(lower, w["jaw_width"] * amt["jaw_width"])
    if w["jaw_depth"]:
        add_front(lower * front_gate, w["jaw_depth"] * amt["jaw_depth"])
    if w["chin_length"]:
        # 下巴：最低 2.5cm 范围、中线附近（|x| < 4.5cm 软边）
        chin = (1.0 - smoothstep(frame.head_z + NECK_FADE, frame.head_z + NECK_FADE + 0.025, z)) \
            * seam * (1.0 - smoothstep(0.030, 0.050, ax)) * front_gate * in_head
        add_up(chin, w["chin_length"] * amt["chin_length"])

    # 眉区：眼线上 0–2.5cm，朝前
    if w["brow_ridge"]:
        brow = _band(z, frame.eye_z, frame.eye_z + 0.025, 0.010) * front_gate * in_head
        add_front(brow, -w["brow_ridge"] * amt["brow_ridge"])      # 权重 +1 = 眉骨更平（更"中式"）

    # 鼻梁中线：|x| < 16mm，眼线下 3cm 到上 2cm
    nose_core = (1.0 - smoothstep(0.012, 0.020, ax))
    if w["nose_bridge"]:
        nb = nose_core * _band(z, frame.eye_z - 0.030, frame.eye_z + 0.020, 0.008) \
            * smoothstep(0.010, 0.030, y) * in_head
        add_front(nb, -w["nose_bridge"] * amt["nose_bridge"])      # 权重 +1 = 鼻梁更低
    if w["nose_width"]:
        nw = (1.0 - smoothstep(0.022, 0.034, ax)) \
            * _band(z, frame.eye_z - 0.050, frame.eye_z - 0.015, 0.008) \
            * smoothstep(0.010, 0.030, y) * in_head
        add_x_scale(nw, w["nose_width"] * amt["nose_width"])

    # 颧骨：|x| 在 3–6.5cm，眼线下 0–4.5cm
    if w["cheekbone"]:
        cb = _band(ax, 0.030, 0.065, 0.012) * _band(z, frame.eye_z - 0.045, frame.eye_z, 0.010) \
            * front_gate * in_head * seam
        d[:, sd] += np.sign(x) * cb * w["cheekbone"] * amt["cheekbone"]
        add_front(cb, w["cheekbone"] * amt["cheekbone"] * 0.6)

    # 总位移硬上限：按向量长度等比压缩，不改变方向
    mag = np.linalg.norm(d, axis=1)
    over = mag > MAX_DISP
    if np.any(over):
        d[over] *= (MAX_DISP / mag[over])[:, None]
    return d


def apply(verts: np.ndarray, frame: HeadFrame, weights: dict) -> np.ndarray:
    v = np.asarray(verts, dtype=np.float64)
    return v + displacement(v, frame, weights)


# ---------------------------------------------------------------- 确定性随机
M32 = 0xFFFFFFFF


def fnv1a32(text: str) -> int:
    h = 0x811C9DC5
    for b in text.encode("utf-8"):
        h ^= b
        h = (h * 0x01000193) & M32
    return h


class Mulberry32:
    """只用 32 位整数运算，便于在 GDScript 里逐行复刻。"""

    def __init__(self, seed: int):
        self.a = seed & M32

    def next_u32(self) -> int:
        self.a = (self.a + 0x6D2B79F5) & M32
        t = self.a
        t = ((t ^ (t >> 15)) * (t | 1)) & M32
        t = t ^ ((t + (((t ^ (t >> 7)) * (t | 61)) & M32)) & M32)
        return (t ^ (t >> 14)) & M32

    def next_float(self) -> float:
        return self.next_u32() / 4294967296.0

    def next_gauss(self) -> float:
        """Irwin–Hall：4 个均匀数之和，标准化到均值 0、方差 1（不用 log/sqrt 的超越函数）。"""
        s = self.next_float() + self.next_float() + self.next_float() + self.next_float()
        return (s - 2.0) / 0.5773502691896257


# ---------------------------------------------------------------- 原型（身份）
# 权重 [-1,1]。方向约定见 displacement()：brow_ridge/nose_bridge 为正 = 更平/更低。
ARCHETYPES = {
    "villager":   {"face_width": 0.0, "jaw_width": 0.0, "jaw_depth": 0.0, "chin_length": 0.0,
                   "brow_ridge": 0.4, "nose_bridge": 0.3, "nose_width": 0.0, "cheekbone": 0.0},
    "merchant":   {"face_width": 0.3, "jaw_width": 0.2, "jaw_depth": 0.1, "chin_length": -0.2,
                   "brow_ridge": 0.3, "nose_bridge": 0.2, "nose_width": 0.2, "cheekbone": 0.2},
    "apprentice": {"face_width": -0.1, "jaw_width": -0.2, "jaw_depth": 0.0, "chin_length": -0.1,
                   "brow_ridge": 0.5, "nose_bridge": 0.4, "nose_width": 0.0, "cheekbone": -0.1},
    "guard":      {"face_width": 0.2, "jaw_width": 0.5, "jaw_depth": 0.4, "chin_length": 0.1,
                   "brow_ridge": 0.1, "nose_bridge": 0.0, "nose_width": 0.1, "cheekbone": 0.4},
    "scholar":    {"face_width": -0.5, "jaw_width": -0.6, "jaw_depth": -0.2, "chin_length": 0.3,
                   "brow_ridge": 0.6, "nose_bridge": 0.2, "nose_width": -0.3, "cheekbone": -0.3},
    "elder":      {"face_width": -0.2, "jaw_width": -0.3, "jaw_depth": -0.4, "chin_length": 0.4,
                   "brow_ridge": 0.2, "nose_bridge": -0.1, "nose_width": 0.1, "cheekbone": 0.5},
}

JITTER_SIGMA = 0.35   # 个体差异：原型周围的标准差（权重单位）


def weights_for_npc(npc_id: str, archetype: str = "villager") -> dict:
    """同一 (npc_id, archetype) 永远返回同一组权重；跨 NPC 相互独立。"""
    base = ARCHETYPES[archetype]
    rng = Mulberry32(fnv1a32(npc_id))
    out = {}
    for name in PARAMS:                       # 固定顺序，保证随机流对齐
        g = rng.next_gauss()
        out[name] = max(-1.0, min(1.0, base[name] + JITTER_SIGMA * g))
    return out


# ---------------------------------------------------------------- 导出规格
def spec() -> dict:
    """给 Blender/Godot 两端共用的参数规格（写成 face_morph_spec.json）。"""
    return {
        "params": PARAMS,
        "amount": AMOUNT,
        "max_disp_m": MAX_DISP,
        "neck_fade_m": NECK_FADE,
        "jitter_sigma": JITTER_SIGMA,
        "archetypes": ARCHETYPES,
        "golden": golden_vectors(),
    }


def golden_vectors() -> list:
    """跨语言一致性测试向量：GDScript 端必须逐项复现。"""
    out = []
    for npc_id, arch in (("npc_001", "villager"), ("npc_002", "scholar"), ("苍岚-守卫-07", "guard")):
        out.append({"id": npc_id, "archetype": arch, "fnv": fnv1a32(npc_id),
                    "weights": weights_for_npc(npc_id, arch)})
    return out


if __name__ == "__main__":
    print(json.dumps(spec(), ensure_ascii=False, indent=2))
