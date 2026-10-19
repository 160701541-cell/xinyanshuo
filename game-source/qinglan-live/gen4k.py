"""从 prompts.json 生成 4K 材质贴图（本地可跑的部分）。
真正的 text-to-3D（Tripo/Rodin/Meshy/Hunyuan3D）需要联网与额度，见 gen3d.py 的适配层。
"""
import json, numpy as np
from PIL import Image

S = 4096
rng = np.random.default_rng(7)

def fft_noise(size, beta=2.0, seed=0):
    r = np.random.default_rng(seed)
    f = np.fft.fft2(r.standard_normal((size, size)))
    fy = np.fft.fftfreq(size)[:, None]; fx = np.fft.fftfreq(size)[None, :]
    k = np.sqrt(fx**2 + fy**2); k[0, 0] = 1e-6
    out = np.real(np.fft.ifft2(f / k**beta))
    out -= out.min(); out /= out.max()
    return out.astype(np.float32)

def octaves(size, seed, base_beta=2.0, n=5):
    acc = np.zeros((size, size), np.float32); amp = 1.0; tot = 0.0
    for i in range(n):
        acc += fft_noise(size, base_beta + i * 0.35, seed + i) * amp
        tot += amp; amp *= 0.55
    return acc / tot

def ramp(x, stops):
    """stops: [(pos, (r,g,b)), ...] 0..1 -> 0..255"""
    out = np.zeros(x.shape + (3,), np.float32)
    for i in range(len(stops) - 1):
        p0, c0 = stops[i]; p1, c1 = stops[i + 1]
        m = (x >= p0) & (x <= p1)
        t = np.clip((x[m] - p0) / max(p1 - p0, 1e-6), 0, 1)[:, None]
        out[m] = np.array(c0, np.float32) * (1 - t) + np.array(c1, np.float32) * t
    return np.clip(out, 0, 255).astype(np.uint8)

def hexc(h):
    h = h.lstrip('#'); return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def save(arr, name):
    Image.fromarray(arr).save(f"/root/game/tex4k/{name}.png", optimize=True)

def stone(pal, seed):
    n = octaves(S, seed, 2.2, 6)
    cracks = 1.0 - np.abs(octaves(S, seed + 40, 1.1, 4) - 0.5) * 2.0
    v = np.clip(n * 0.75 + (1 - np.clip(cracks * 2.2, 0, 1)) * 0.25, 0, 1)
    return ramp(v, [(0, hexc(pal[0])), (0.55, tuple(int(c*1.12) for c in hexc(pal[0]))), (1, (232, 230, 226))])

def timber(pal, seed):
    warp = octaves(S, seed, 2.4, 3)
    y = np.linspace(0, 1, S, dtype=np.float32)[:, None] * 60 + warp * 8
    rings = 0.5 + 0.5 * np.sin(y * 6.28)
    v = np.clip(rings * 0.55 + octaves(S, seed + 9, 2.0, 5) * 0.45, 0, 1)
    return ramp(v, [(0, hexc(pal[0])), (0.5, tuple(int(c*1.35) for c in hexc(pal[0]))), (1, (120, 96, 74))])

def tile(pal, seed):
    g = np.zeros((S, S), np.float32)
    cell = 128
    yy, xx = np.mgrid[0:S, 0:S]
    row = (yy // cell).astype(np.int32)
    xx2 = (xx + (row % 2) * cell // 2) % S
    colx = (xx2 // cell).astype(np.int32)
    fy = (yy % cell) / cell; fx = (xx2 % cell) / cell
    edge = np.minimum(np.minimum(fy, 1 - fy), np.minimum(fx, 1 - fx))
    g = np.clip(edge * 4.0, 0, 1) * 0.5 + octaves(S, seed, 2.1, 5) * 0.5
    return ramp(g, [(0, (24, 32, 48)), (0.35, hexc(pal[0])), (0.8, (96, 130, 176)), (1, (170, 200, 230))])

def steel(pal, seed):
    v = octaves(S, seed, 2.6, 4)
    streak = 0.5 + 0.5 * np.sin(np.linspace(0, 90, S, dtype=np.float32)[None, :] + v * 5)
    f = np.clip(v * 0.6 + streak * 0.4, 0, 1)
    return ramp(f, [(0, (70, 88, 108)), (0.5, hexc(pal[0])), (1, (246, 252, 255))])

def linen(pal, seed):
    yy, xx = np.mgrid[0:S, 0:S]
    weave = 0.5 + 0.5 * np.sin(xx * 0.9) * np.sin(yy * 0.9)
    v = np.clip(weave * 0.45 + octaves(S, seed, 2.3, 6) * 0.55, 0, 1)
    return ramp(v, [(0, (150, 142, 128)), (0.6, hexc(pal[0])), (1, (252, 250, 244))])

BUILD = {"gate": stone, "pavilion": timber, "sword": steel, "pill": steel, "tree": timber, "robe": linen}

if __name__ == "__main__":
    d = json.load(open("/root/game/prompts.json"))
    for a in d["assets"]:
        fn = BUILD[a["id"]]
        arr = fn(a["palette"], seed=len(a["id"]) * 13)
        save(arr, a["id"])
        print("4K", a["id"], arr.shape)
