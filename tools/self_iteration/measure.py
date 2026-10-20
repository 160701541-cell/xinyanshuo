#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""R4 自动量测器：按 docs/SELF_ITERATION_OPTIMIZATION_PROTOCOL_V1.md 第 2 节门槛表，
从固定机位渲染图提取数值。禁止肉眼估计（本机无视觉模型，数值是唯一证据）。

用法:
    python3 tools/self_iteration/measure.py --round 1 --out metrics.json 图1.png 图2.png 图3.png 图4.png

测法（每一项都写明，可复现；同一机位=620x820 / 头部特写 cam(0,1.62,-0.95) fov16）:
- bg         : 图片最外 2px 边框像素的中位数（纯色环境，固定机位）
- 主体掩膜   : 与 bg 的 CIEDE2000 距离 > DE_SUBJECT 的像素
- delta_L    : |主体 L* 均值 - 背景 L* 均值|（CIELAB L*）
- 分类       : CIELAB 色相/彩度分类（忽略明度，因为渲染光照只近似缩放 L）：
               彩度<8 -> neutral(内衫/靴)；色相170-215 -> robe(袍)；彩度>=28且色相50-110 -> gold(金边点缀)；彩度12-28且色相30-100 -> skin；
               色相60-100且彩度>=15 -> skin(皮肤)；其余 -> unclassified
- accent_area_pct: gold 像素 / 主体像素 ×100
- delta_E00  : 主色(robe)像素 Lab 均值 vs 色板(CHARACTER_SPEC.md 外袍 线性RGB 0.085,0.255,0.250)
               的 CIEDE2000；其余分类同样算出写进 extra 供核查
- neck_gap_px: 头部特写机位下画面主体即颈肩区，取以下两者的较大值：
               (a) crack = 同一行内被主体像素左右夹住的背景色像素最长连续宽度
               (b) thru  = 同一行内被 robe 像素左右夹住的 skin 像素最长连续宽度（头壳/皮肤从领口穿出）
- outline_px : 本轮机位未启用 rig/sso.gdshader 屏幕空间描边 -> 输出 null (BLOCKED)
- parts_readable: 可辨部件数需人眼/视觉模型 -> 输出 null (BLOCKED，禁止编造)
- extra      : neck_head_width_ratio（颈部肤色带最宽行 / 头部主体最宽行）、triangles 由 --meta 传入
exit 0 表示量测完成；数值判定交给 check_round.py。
"""
import argparse
import json
import sys

import numpy as np
from PIL import Image

DE_SUBJECT = 6.0
PALETTE_LINEAR = {                      # CHARACTER_SPEC.md 线性 RGB
    "robe": (0.085, 0.255, 0.250),
    "hem": (0.045, 0.150, 0.155),
    "inner": (0.52, 0.50, 0.45),
    "gold": (0.40, 0.30, 0.11),
    "skin": (0.86, 0.72, 0.56),
    "boot": (0.16, 0.17, 0.18),
}


def lin2srgb(c):
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * np.power(np.clip(c, 0, None), 1 / 2.4) - 0.055)


def srgb2lab(rgb):                        # rgb: (...,3) in 0..1 sRGB
    c = np.asarray(rgb, dtype=np.float64)
    lin = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    m = np.array([[0.4124564, 0.3575761, 0.1804375],
                  [0.2126729, 0.7151522, 0.0721750],
                  [0.0193339, 0.1191920, 0.9503041]])
    xyz = lin @ m.T / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 0.008856, np.cbrt(np.clip(xyz, 0, None)), 7.787 * xyz + 16 / 116)
    L = 116 * f[..., 1] - 16
    a = 500 * (f[..., 0] - f[..., 1])
    b = 200 * (f[..., 1] - f[..., 2])
    return np.stack([L, a, b], axis=-1)


def de00(lab1, lab2):
    """CIEDE2000; 支持广播。lab* 为 (...,3)。"""
    L1, a1, b1 = lab1[..., 0], lab1[..., 1], lab1[..., 2]
    L2, a2, b2 = lab2[..., 0], lab2[..., 1], lab2[..., 2]
    C1 = np.hypot(a1, b1)
    C2 = np.hypot(a2, b2)
    Cb = (C1 + C2) / 2
    G = 0.5 * (1 - np.sqrt(Cb ** 7 / (Cb ** 7 + 25 ** 7 + 1e-30)))
    a1p, a2p = (1 + G) * a1, (1 + G) * a2
    C1p, C2p = np.hypot(a1p, b1), np.hypot(a2p, b2)
    h1p = np.degrees(np.arctan2(b1, a1p)) % 360
    h2p = np.degrees(np.arctan2(b2, a2p)) % 360
    dLp = L2 - L1
    dCp = C2p - C1p
    dhp = h2p - h1p
    dhp = np.where(dhp > 180, dhp - 360, np.where(dhp < -180, dhp + 360, dhp))
    dhp = np.where((C1p * C2p) == 0, 0.0, dhp)
    dHp = 2 * np.sqrt(C1p * C2p) * np.sin(np.radians(dhp / 2))
    Lbp = (L1 + L2) / 2
    Cbp = (C1p + C2p) / 2
    hbp = h1p + h2p
    hbp = np.where(np.abs(h1p - h2p) > 180, np.where(hbp < 360, hbp + 360, hbp - 360), hbp) / 2
    hbp = np.where((C1p * C2p) == 0, h1p + h2p, hbp)
    T = (1 - 0.17 * np.cos(np.radians(hbp - 30)) + 0.24 * np.cos(np.radians(2 * hbp))
         + 0.32 * np.cos(np.radians(3 * hbp + 6)) - 0.20 * np.cos(np.radians(4 * hbp - 63)))
    Sl = 1 + (0.015 * (Lbp - 50) ** 2) / np.sqrt(20 + (Lbp - 50) ** 2)
    Sc = 1 + 0.045 * Cbp
    Sh = 1 + 0.015 * Cbp * T
    Rt = -2 * np.sqrt(Cbp ** 7 / (Cbp ** 7 + 25 ** 7 + 1e-30)) * np.sin(
        np.radians(60 * np.exp(-(((hbp - 275) / 25) ** 2))))
    return np.sqrt((dLp / Sl) ** 2 + (dCp / Sc) ** 2 + (dHp / Sh) ** 2 + Rt * (dCp / Sc) * (dHp / Sh))


def palette_lab():
    out = {}
    for k, lin in PALETTE_LINEAR.items():
        srgb = lin2srgb(np.array(lin))
        out[k] = srgb2lab(srgb)
    return out


def enclosed_background(mask):
    """被主体完全包围的背景像素（孔洞）。从四边泛洪，泛不到的背景即孔洞。"""
    from collections import deque
    h, w = mask.shape
    bg = ~mask
    reach = np.zeros_like(bg)
    dq = deque()
    for x in range(w):
        for y in (0, h - 1):
            if bg[y, x] and not reach[y, x]:
                reach[y, x] = True
                dq.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if bg[y, x] and not reach[y, x]:
                reach[y, x] = True
                dq.append((y, x))
    while dq:
        y, x = dq.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and bg[ny, nx] and not reach[ny, nx]:
                reach[ny, nx] = True
                dq.append((ny, nx))
    return bg & ~reach


def longest_run(flags):
    """一维布尔数组里最长 True 连续段长度。"""
    best = cur = 0
    for v in flags:
        cur = cur + 1 if v else 0
        best = max(best, cur)
    return best


def _bg_color(rgb):
    """背景色：图像上缘 4 行的量化众数（每通道 16 级）再取该桶均值。

    固定机位下背景必然占据上缘；用全图边框中位数会被触底的主体污染。
    """
    top = rgb[:4].reshape(-1, 3)
    q = np.clip((top * 16.0).astype(np.int32), 0, 15)
    key = q[:, 0] * 256 + q[:, 1] * 16 + q[:, 2]
    vals, counts = np.unique(key, return_counts=True)
    best = int(vals[int(np.argmax(counts))])
    return top[key == best].mean(axis=0)


def _clean_mask(mask, min_frac=0.005):
    """只保留面积达标的 4 连通分量，剔除角落杂点（否则会把大片背景误判成'内部裂缝'）。"""
    from collections import deque
    h, w = mask.shape
    flat = mask.reshape(-1)
    seen = np.zeros(flat.size, dtype=bool)
    keep = np.zeros(flat.size, dtype=bool)
    min_px = max(2000, int(min_frac * flat.size))
    for s in np.flatnonzero(flat):
        s = int(s)
        if seen[s]:
            continue
        seen[s] = True
        comp = [s]
        dq = deque([s])
        while dq:
            i = dq.popleft()
            y, x = divmod(i, w)
            nb = []
            if x > 0:
                nb.append(i - 1)
            if x < w - 1:
                nb.append(i + 1)
            if y > 0:
                nb.append(i - w)
            if y < h - 1:
                nb.append(i + w)
            for j in nb:
                if flat[j] and not seen[j]:
                    seen[j] = True
                    comp.append(j)
                    dq.append(j)
        if len(comp) >= min_px:
            keep[np.array(comp, dtype=np.int64)] = True
    return keep.reshape(mask.shape)


def analyse(path):
    im = Image.open(path).convert("RGB")
    rgb = np.asarray(im, dtype=np.float64) / 255.0
    h, w, _ = rgb.shape
    lab = srgb2lab(rgb)
    bg = _bg_color(rgb)
    bg_lab = srgb2lab(bg)
    de = de00(lab, bg_lab)
    mask = _clean_mask(de > DE_SUBJECT)

    L, A, B = lab[..., 0], lab[..., 1], lab[..., 2]
    chroma = np.hypot(A, B)
    hue = np.degrees(np.arctan2(B, A)) % 360

    sub = mask
    delta_L = float(abs(L[sub].mean() - bg_lab[0])) if sub.any() else None

    cls = np.zeros_like(mask, dtype=np.int8)          # 0 none 1 neutral 2 robe 3 gold 4 skin 5 other
    # 仪表 v2：CIELAB 下金/黄 ≈ 色相 55–110°、彩度 ≥28；肤色是低彩度橙（12–28）。
    # v1 按色相 35–60 判金边，实测把金色判成了肤色（金黄 Lab 色相 ≈80°）→ 已修正。
    cls[sub & (chroma < 8)] = 1
    cls[sub & (chroma >= 8) & (hue >= 170) & (hue <= 215)] = 2
    cls[sub & (chroma >= 12) & (hue >= 30) & (hue <= 100)] = 4      # skin
    cls[sub & (chroma >= 28) & (hue >= 50) & (hue <= 110)] = 3      # gold（高彩度覆盖肤色）
    cls[sub & (cls == 0)] = 5
    n_sub = int(sub.sum())
    area = {k: float((cls == v).sum()) / max(1, n_sub) * 100.0 for v, k in
            [(1, "neutral"), (2, "robe"), (3, "gold"), (4, "skin")]}
    pal = palette_lab()
    pal_of = {"robe": "robe", "gold": "gold", "skin": "skin", "neutral": "inner"}
    de_by_class = {}
    for k, v in [("neutral", 1), ("robe", 2), ("gold", 3), ("skin", 4)]:
        sel = cls == v
        if sel.sum() < max(1, int(0.005 * n_sub)):
            continue
        de_by_class[k] = float(de00(lab[sel].mean(axis=0), pal[pal_of[k]]))

    neck_head_ratio = None
    rows = np.where(mask.any(axis=1))[0]
    if len(rows):
        top, bot = int(rows[0]), int(rows[-1])
        width = mask.sum(axis=1)
        head_rows = width[top:top + max(1, (bot - top) // 3)]
        head_px = int(head_rows.max()) if len(head_rows) else 0
        skin_w = (cls == 4).sum(axis=1)
        neck_px = int(skin_w.max()) if n_sub else 0
        if head_px > 0:
            neck_head_ratio = round(neck_px / head_px, 3)

    # 仪表 v3：裂缝只认「被主体完全包围的背景孔洞」（四边泛洪，泛不到的背景即孔洞）。
    # v2 的「同行左右夹住」会把头与肩之间的天然凹陷算成裂缝 → 已废。
    enclosed = enclosed_background(mask)
    hole = 0
    for y in range(h):
        e = enclosed[y]
        if e.any():
            run = longest_run(e)
            if run > hole:
                hole = run
    # 仪表 v4：穿帮只认「领口金边上沿以下、却被袍/金边夹住的皮肤」——
    # 领口以上的脖子是正常可见颈部，不算穿帮；而金边上沿以下本该被袍面盖住。
    gold_rows = np.where((cls == 3).any(axis=1))[0]
    rim = int(gold_rows[0]) if len(gold_rows) else 0
    thru = 0
    cap = max(4, int(0.10 * w))
    for y in range(rim, h):
        cov = (cls[y] == 2) | (cls[y] == 3)
        skn = cls[y] == 4
        if cov.any() and skn.any():
            ri = np.where(cov)[0]
            lo, hi = int(ri[0]), int(ri[-1])
            inner = skn[lo:hi + 1]
            if inner.any():
                run = longest_run(inner)
                if run <= cap:
                    thru = max(thru, run)
    return {
        "file": path, "size": [w, h],
        "delta_L": round(delta_L, 2) if delta_L is not None else None,
        "accent_area_pct": round(area.get("gold", 0.0), 2),
        "delta_E00": round(de_by_class.get("robe", float("nan")), 2) if "robe" in de_by_class else None,
        "neck_gap_px": int(thru), "neck_gap_src": "skin-below-collar-rim",
        "silhouette_hole_px": int(hole),
        "outline_px": None,
        "parts_readable": None,
        "extra": {"neck_head_width_ratio": neck_head_ratio,
                  "crack_px": int(hole), "skin_through_collar_px": int(thru),
                  "crack_cap_px": int(cap),
                  "area_pct_by_class": {k: round(v, 2) for k, v in area.items()},
                  "delta_E00_by_class": {k: round(v, 2) for k, v in de_by_class.items()}},
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("images", nargs="+")
    ap.add_argument("--out")
    ap.add_argument("--meta", help="JSON：额外网格量测值（triangles/head_torso_leg_ratio 等）")
    a = ap.parse_args()
    per = [analyse(p) for p in a.images]
    agg = {}
    for k in ("delta_L", "accent_area_pct", "delta_E00", "neck_gap_px"):
        vals = [p[k] for p in per if p[k] is not None]
        agg[k] = round(float(np.mean(vals)), 2) if vals else None
    agg["outline_px"] = None
    agg["parts_readable"] = None
    agg["extra"] = {"per_view": per}
    if a.meta and __import__("os").path.exists(a.meta):
        with open(a.meta, encoding="utf-8") as f:
            agg.update(json.load(f))
    print("%-18s %-10s %-10s %-10s %-12s" % ("指标", "均值", "最小", "最大", "测法"))
    keys = [("delta_L", "主体/背景 L* 差"), ("accent_area_pct", "金边占比 %"),
            ("delta_E00", "主色漂移 ΔE00"), ("neck_gap_px", "颈接缝穿帮 px")]
    for k, name in keys:
        vals = [p[k] for p in per if p[k] is not None]
        print("%-18s %-10s %-10s %-10s %s" % (name, agg[k], min(vals) if vals else "-",
                                              max(vals) if vals else "-", k))
    for p in per:
        ex = p["extra"]
        print("  %s: neck/head=%.3f crack=%d skin_through=%d 面积%%=%s" %
              (p["file"].split("/")[-1], ex["neck_head_width_ratio"] or -1,
               ex["crack_px"], ex["skin_through_collar_px"], ex["area_pct_by_class"]))
    if a.out:
        with open(a.out, "w", encoding="utf-8") as f:
            json.dump(agg, f, ensure_ascii=False, indent=2)
        print("已写 %s" % a.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
