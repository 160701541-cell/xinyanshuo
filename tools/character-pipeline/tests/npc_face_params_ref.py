#!/usr/bin/env python3
"""npc_face_morph.gd 里 params_from_id 的独立 Python 参考实现。

用途：
1. 给 tests/npc_face_morph_test.gd 的金标准值提供来源（两种语言各算一遍，必须一致）。
2. 以后 Blender / 离线脚本要烘焙同一张脸时，直接用它拿到和引擎里一样的参数。

用法： python3 npc_face_params_ref.py npc_001 canglan_elder
"""
import sys

PARAM_NAMES = [
    "face_width", "jaw_width", "chin_length", "chin_forward", "cheek_bone",
    "brow_ridge", "eye_socket_depth", "nose_bridge", "nose_tip", "nose_width",
    "forehead",
]
M32 = 0xFFFFFFFF


def xorshift32(s):
    s = (s ^ (s << 13)) & M32
    s ^= s >> 17
    s = (s ^ (s << 5)) & M32
    return s


def params_from_id(npc_id, strength=1.0, bias=None):
    bias = bias or {}
    h = 0x811C9DC5
    for b in npc_id.encode("utf-8"):
        h = ((h ^ b) * 0x01000193) & M32
    s = h if h != 0 else 0x9E3779B9
    for _ in range(3):
        s = xorshift32(s)
    out = {}
    for name in PARAM_NAMES:
        s = xorshift32(s)
        r1 = s / 4294967296.0
        s = xorshift32(s)
        r2 = s / 4294967296.0
        v = (r1 + r2 - 1.0) * strength + bias.get(name, 0.0)
        out[name] = max(-1.0, min(1.0, v))
    return out


if __name__ == "__main__":
    for nid in sys.argv[1:] or ["npc_001"]:
        print(nid)
        for k, v in params_from_id(nid).items():
            print(f"  {k:18s} {v:+.6f}")
