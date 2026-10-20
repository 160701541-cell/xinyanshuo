"""face_morph_core 单元测试（纯 numpy，不需要 Blender / Godot）。

运行：python3 -m unittest discover -s tools/character-pipeline/tests -v
"""
import os
import sys
import unittest

import numpy as np

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))
import face_morph_core as fm  # noqa: E402


def synthetic_body(height=1.80, n_lat=60, n_lon=96):
    """合成一个 1.8m 的人：身体圆柱 + 头部椭球（含鼻子凸起），前向 +Y，上向 +Z（Blender 约定）。"""
    pts = []
    for z in np.linspace(0.0, 1.50, 40):                    # 身体
        for a in np.linspace(0, 2 * np.pi, 48, endpoint=False):
            pts.append((0.15 * np.cos(a), 0.10 * np.sin(a), z))
    cz = 1.68
    rx, ry, rz = 0.08, 0.10, 0.12
    for i in range(n_lat + 1):                              # 头：纬度从下到上
        phi = -np.pi / 2 + np.pi * i / n_lat
        for j in range(n_lon):
            th = 2 * np.pi * j / n_lon
            x = rx * np.cos(phi) * np.sin(th)
            y = ry * np.cos(phi) * np.cos(th)
            z = cz + rz * np.sin(phi)
            if y > 0 and abs(x) < 0.015 and 1.62 < z < 1.70:  # 鼻子：中线前凸 2cm
                y += 0.02 * (1 - abs(x) / 0.015)
            pts.append((x, y, z))
    pts.append((0.0, 0.0, height))                           # 保证 zmax = 1.80
    return np.array(pts, dtype=np.float64)


def all_weights(value):
    return {k: value for k in fm.PARAMS}


class FaceMorphCoreTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.v = synthetic_body()
        cls.frame = fm.HeadFrame.from_mesh(cls.v)

    # ---- 标定
    def test_frame_front_sign_and_levels(self):
        self.assertEqual(self.frame.front_sign, 1.0)
        self.assertAlmostEqual(self.frame.head_z, 1.8 - 0.135 * 1.8, places=6)
        self.assertAlmostEqual(self.frame.eye_z, 1.8 - 0.078 * 1.8, places=6)

    def test_frame_detects_back_facing_mesh(self):
        flipped = self.v.copy()
        flipped[:, 1] *= -1
        self.assertEqual(fm.HeadFrame.from_mesh(flipped).front_sign, -1.0)

    # ---- 零权重
    def test_zero_weights_do_nothing(self):
        d = fm.displacement(self.v, self.frame, {})
        self.assertEqual(float(np.abs(d).max()), 0.0)

    # ---- 对称
    def test_left_right_symmetry(self):
        w = {k: 0.7 for k in fm.PARAMS}
        d = fm.displacement(self.v, self.frame, w)
        mirrored = self.v.copy()
        mirrored[:, 0] *= -1
        dm = fm.displacement(mirrored, self.frame, w)
        expected = d.copy()
        expected[:, 0] *= -1
        np.testing.assert_allclose(dm, expected, atol=1e-12)

    # ---- 位移上限与局部性
    def test_extreme_weights_never_exceed_cap(self):
        rng = np.random.default_rng(1)
        for _ in range(200):
            w = {k: float(rng.choice([-1.0, 1.0])) for k in fm.PARAMS}
            d = fm.displacement(self.v, self.frame, w)
            self.assertLessEqual(float(np.linalg.norm(d, axis=1).max()), fm.MAX_DISP + 1e-12)

    def test_out_of_range_weights_are_clamped(self):
        a = fm.displacement(self.v, self.frame, all_weights(1.0))
        b = fm.displacement(self.v, self.frame, all_weights(5.0))
        np.testing.assert_allclose(a, b, atol=1e-12)

    def test_body_and_neck_untouched(self):
        d = fm.displacement(self.v, self.frame, all_weights(1.0))
        below = self.v[:, 2] <= self.frame.head_z
        self.assertEqual(float(np.abs(d[below]).max()), 0.0)

    def test_back_of_head_untouched_by_front_params(self):
        w = {k: 1.0 for k in fm.PARAMS if k not in ("face_width", "jaw_width", "nose_width")}
        d = fm.displacement(self.v, self.frame, w)
        back = (self.v[:, 1] < -0.02) & (self.v[:, 2] > self.frame.head_z)
        self.assertLess(float(np.abs(d[back]).max()), 1e-12)

    # ---- 平滑（无硬切折痕）
    def test_displacement_field_is_smooth(self):
        zs = np.arange(self.frame.head_z - 0.01, self.frame.zmax, 0.001)
        for x in (0.0, 0.02, 0.05):
            line = np.stack([np.full_like(zs, x), np.full_like(zs, 0.06), zs], axis=1)
            d = fm.displacement(line, self.frame, all_weights(1.0))
            step = np.linalg.norm(np.diff(d, axis=0), axis=1)
            # 1mm 步长内位移变化不得超过 2mm（斜率 ≤ 2）；硬切会出现数毫米的跳变
            self.assertLess(float(step.max()), 0.002, msg=f"x={x}")

    def test_seam_starts_at_zero(self):
        z = np.array([self.frame.head_z, self.frame.head_z + 0.0005])
        p = np.stack([np.zeros(2), np.full(2, 0.05), z], axis=1)
        d = fm.displacement(p, self.frame, all_weights(1.0))
        self.assertEqual(float(np.abs(d[0]).max()), 0.0)
        self.assertLess(float(np.abs(d[1]).max()), 1e-4)

    # ---- 方向语义（文档里写的"+1 是什么意思"）
    def _delta(self, name, mask_fn):
        d = fm.displacement(self.v, self.frame, {name: 1.0})
        m = mask_fn(self.v)
        self.assertTrue(m.any(), name)
        return d[m]

    def test_direction_semantics(self):
        ez = self.frame.eye_z
        brow = self._delta("brow_ridge", lambda v: (v[:, 2] > ez + 0.005) & (v[:, 2] < ez + 0.02) & (v[:, 1] > 0.04))
        self.assertLess(float(brow[:, 1].mean()), 0)           # +1 眉骨后退
        nose = self._delta("nose_bridge", lambda v: (np.abs(v[:, 0]) < 0.008) & (v[:, 1] > 0.10) & (v[:, 2] > ez - 0.03) & (v[:, 2] < ez + 0.02))
        self.assertLess(float(nose[:, 1].mean()), 0)           # +1 鼻梁变低
        jaw = fm.displacement(self.v, self.frame, {"jaw_width": 1.0})
        lower = (self.v[:, 2] > self.frame.head_z + 0.03) & (self.v[:, 2] < ez - 0.06) & (np.abs(self.v[:, 0]) > 0.04)
        self.assertTrue(lower.any())
        self.assertGreater(float((np.abs(self.v[lower, 0] + jaw[lower, 0]) - np.abs(self.v[lower, 0])).mean()), 0)  # +1 下颌变宽
        chin = self._delta("chin_length", lambda v: (v[:, 2] > self.frame.head_z + 0.02) & (v[:, 2] < self.frame.head_z + 0.045) & (np.abs(v[:, 0]) < 0.02) & (v[:, 1] > 0.02))
        self.assertGreater(float(chin[:, 2].mean()), 0)        # +1 下巴上移的符号：沿上向为正

    # ---- 坐标轴无关（Blender Z-up ↔ Godot Y-up）
    def test_godot_axes_give_same_result(self):
        w = fm.weights_for_npc("npc_axes", "guard")
        d_blender = fm.displacement(self.v, self.frame, w)
        # Blender (x, y, z) → glTF/Godot (x, z, y)：Y 上、+Z 前
        vg = self.v[:, [0, 2, 1]]
        fg = fm.HeadFrame.from_mesh(vg, up=1, front=2, side=0)
        d_godot = fm.displacement(vg, fg, w)
        np.testing.assert_allclose(d_godot[:, [0, 2, 1]], d_blender, atol=1e-12)

    # ---- 确定性随机
    def test_fnv1a32_known_values(self):
        self.assertEqual(fm.fnv1a32(""), 0x811C9DC5)
        self.assertEqual(fm.fnv1a32("a"), 0xE40C292C)
        self.assertEqual(fm.fnv1a32("foobar"), 0xBF9CF968)

    def test_weights_are_deterministic_and_in_range(self):
        a = fm.weights_for_npc("npc_042", "scholar")
        b = fm.weights_for_npc("npc_042", "scholar")
        self.assertEqual(a, b)
        self.assertTrue(all(-1.0 <= x <= 1.0 for x in a.values()))
        self.assertEqual(list(a.keys()), fm.PARAMS)

    def test_different_npcs_get_different_faces(self):
        ws = [tuple(fm.weights_for_npc(f"npc_{i:03d}", "villager").values()) for i in range(300)]
        self.assertEqual(len(set(ws)), 300)

    def test_population_statistics(self):
        arr = np.array([list(fm.weights_for_npc(f"id-{i}", "villager").values()) for i in range(4000)])
        base = np.array([fm.ARCHETYPES["villager"][k] for k in fm.PARAMS])
        # 均值贴近原型（被 ±1 截断会略偏，容差放宽到 0.05）
        np.testing.assert_allclose(arr.mean(axis=0), base, atol=0.05)
        # 标准差接近 JITTER_SIGMA（截断使其略小）
        self.assertTrue(np.all(arr.std(axis=0) > 0.28))
        self.assertTrue(np.all(arr.std(axis=0) < 0.37))

    def test_gauss_is_unit_variance(self):
        rng = fm.Mulberry32(12345)
        g = np.array([rng.next_gauss() for _ in range(40000)])
        self.assertAlmostEqual(float(g.mean()), 0.0, delta=0.03)
        self.assertAlmostEqual(float(g.std()), 1.0, delta=0.03)

    def test_all_archetypes_are_valid(self):
        for name, ws in fm.ARCHETYPES.items():
            self.assertEqual(set(ws), set(fm.PARAMS), name)
            self.assertTrue(all(-1.0 <= x <= 1.0 for x in ws.values()), name)

    def test_golden_vectors_roundtrip_json(self):
        import json
        s = json.loads(json.dumps(fm.spec(), ensure_ascii=False))
        for g in s["golden"]:
            again = fm.weights_for_npc(g["id"], g["archetype"])
            self.assertEqual(fm.fnv1a32(g["id"]), g["fnv"])
            for k in fm.PARAMS:
                self.assertEqual(again[k], g["weights"][k])


if __name__ == "__main__":
    unittest.main()
