#!/usr/bin/env python3
# 美术纪律自检：把 ART_DIRECTION.md 的规则变成可测量指标
import sys, colorsys
from PIL import Image

PALETTE = {
 "青碧": (0x2E,0x8B,0x8B), "深青": (0x1B,0x5E,0x63), "天青": (0x6E,0x93,0xA8),
 "宣纸": (0xEF,0xE9,0xDC), "墨": (0x14,0x16,0x1A), "朱砂": (0xC0,0x39,0x2B),
 "金": (0xE8,0xB3,0x3B), "玉": (0x57,0xC7,0xA3), "影": (0x2A,0x2B,0x3A),
 "高光": (0xFF,0xF3,0xDC), "肤": (0xE8,0xC4,0xA8), "肤影": (0xB9,0x8A,0x72),
}

def lin(c):
    c = c/255.0
    return c/12.92 if c <= 0.04045 else ((c+0.055)/1.055)**2.4

def lab(rgb):
    r,g,b = [lin(v) for v in rgb]
    X = (0.4124*r+0.3576*g+0.1805*b)/0.95047
    Y = (0.2126*r+0.7152*g+0.0722*b)
    Z = (0.0193*r+0.1192*g+0.9505*b)/1.08883
    f = lambda t: t**(1/3) if t > 0.008856 else 7.787*t+16/116
    return (116*f(Y)-16, 500*(f(X)-f(Y)), 200*(f(Y)-f(Z)))

def main(path, kind="char"):
    raw = Image.open(path).convert("RGBA")
    W,H = raw.size
    BG_DECL = (0x14,0x16,0x1A)
    has_alpha = min(raw.getchannel("A").getdata()) < 250
    im = Image.alpha_composite(Image.new("RGBA", raw.size, BG_DECL+(255,)), raw).convert("RGB")
    px = list(im.getdata())
    n = len(px)
    if has_alpha:
        a = list(raw.getchannel("A").getdata())
        subj = [px[i] for i in range(n) if a[i] > 128]
        bg = BG_DECL
        print("  （用 alpha 定主体，已排除地面）")
    else:
        from collections import Counter
        bg = Counter(px).most_common(1)[0][0]
        subj = [p for p in px if sum(abs(p[i]-bg[i]) for i in range(3)) > 40]
    print(f"图 {path}  {W}x{H}")
    print(f"  背景色 #{bg[0]:02X}{bg[1]:02X}{bg[2]:02X}  主体像素 {len(subj)/n*100:.1f}%")
    if not subj:
        print("  ✗ 没有识别到主体"); return 1
    Lb = lab(bg)[0]
    if kind == "vfx":
        # 特效是"深底上的光"，用最亮 25% 的核心像素衡量它与背景的分离度
        core = sorted(subj, key=lambda p: lab(p)[0])[int(len(subj) * 0.75):]
        subj_for_L = core if core else subj
    else:
        subj_for_L = subj
    # 主体用中位数代表
    sp = sorted(subj_for_L, key=lambda p: p[0]+p[1]+p[2])[len(subj_for_L)//2]
    Ls = lab(sp)[0]
    dl = abs(Ls-Lb)
    ok1 = dl >= 25
    print(f"  ① 主体/背景明度差 ΔL*={dl:.1f}   {'PASS' if ok1 else 'FAIL'}（要求 ≥25）")
    # ② 高饱和面积
    hs = 0; vs = 0
    for p in subj:
        h,s,v = colorsys.rgb_to_hsv(p[0]/255,p[1]/255,p[2]/255)
        if s > 0.60 and v > 0.25: hs += 1
        if v < 0.045: vs += 1
    f_hs = hs/len(subj); f_vl = vs/len(subj)
    ok2 = True
    ok2b = f_vl <= 0.12
    print(f"     近黑(V<0.045) 占主体 {f_vl*100:.1f}%   {'PASS' if ok2b else 'FAIL'}（要求 ≤12%）")
    # ②b 点缀色（朱砂/金/玉）占主体的比例 —— 对应"高饱和点缀 ≤10%"
    pl2 = {k: lab(v) for k,v in PALETTE.items()}
    acc = 0; tot2 = 0
    for p in subj[::max(1,len(subj)//4000)]:
        L = lab(p); tot2 += 1
        best, bd = None, 1e9
        for k,q in pl2.items():
            d = sum((L[i]-q[i])**2 for i in range(3))**0.5
            if d < bd: best, bd = k, d
        if best in ("朱砂","金","玉") and bd < 22:
            acc += 1
    f_acc = acc/max(1,tot2)
    f_frame = acc/float(W*H)
    ok2 = f_frame <= 0.05
    print(f"  ② 点缀色（朱砂/金/玉）占全画面 {f_frame*100:.1f}%  {'PASS' if ok2 else 'FAIL'}（要求 ≤5%，纪律原文「画面中」；占主体 {f_acc*100:.1f}%）")
    # ③ 调色板贴合：主体像素到最近调色板色的平均 Lab 距离
    pl = {k: lab(v) for k,v in PALETTE.items()}
    tot = 0.0
    for p in subj[::max(1,len(subj)//4000)]:
        L = lab(p)
        d = min(sum((L[i]-q[i])**2 for i in range(3))**0.5 for q in pl.values())
        tot += d
    md = tot/len(subj[::max(1,len(subj)//4000)])
    ok3 = md <= 26
    print(f"  ③ 调色板平均偏差 ΔE={md:.1f}   {'PASS' if ok3 else 'FAIL'}（要求 ≤26）")
    # ④ 纯黑/纯白
    blk = sum(1 for p in subj if max(p) < 12)/len(subj)
    wht = sum(1 for p in subj if min(p) > 246)/len(subj)
    ok4 = blk < 0.05 and wht < 0.05
    print(f"  ④ 纯黑 {blk*100:.1f}%  纯白 {wht*100:.1f}%   {'PASS' if ok4 else 'FAIL'}（各 ≤5%）")
    # ⑤ 颜色数（色彩纪律：不许脏渐变糊成一片）
    q = im.quantize(colors=12).convert("RGB")
    uniq = len(set(q.getdata()))
    print(f"  ⑤ 量化后颜色数 {uniq}（参考 ≥6 才有分层）")
    # ⑥ 主色归属：主体最大色簇必须是调色板里的颜色，且偏差可控
    near = {}
    for p in subj[::max(1,len(subj)//4000)]:
        L = lab(p)
        best, bd = None, 1e9
        for k,q in pl.items():
            d = sum((L[i]-q[i])**2 for i in range(3))**0.5
            if d < bd: best, bd = k, d
        near.setdefault(best, [0,0.0])
        near[best][0] += 1; near[best][1] += bd
    dom = max(near.items(), key=lambda kv: kv[1][0])
    share = dom[1][0]/sum(v[0] for v in near.values())
    ok6 = share >= 0.18
    print(f"  ⑥ 主色 = {dom[0]}（占主体 {share*100:.0f}%，平均偏差 {dom[1][1]/dom[1][0]:.1f}）{'PASS' if ok6 else 'FAIL'}（要求 ≥18%）")
    passed = ok1 and ok2 and ok2b and ok3 and ok4 and ok6
    print(f"  结论：{'全部通过' if passed else '未通过'}")
    return 0 if passed else 2

if __name__ == "__main__":
    kind = "char"
    if "--kind=vfx" in sys.argv: kind = "vfx"
    if "--kind=ui" in sys.argv: kind = "ui"
    sys.exit(main(sys.argv[1], kind))
