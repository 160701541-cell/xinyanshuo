# 贴图脸生成器（动漫/古风风格）
# 映射：u=0..1 -> 脸面 ±98°，v=0 -> y=1.645（额顶）, v=1 -> y=1.440（下颌）
# 画布 1024x1536，接近各向同性（≈7000 px/m）
from PIL import Image, ImageDraw, ImageFilter
import math

W, H = 1024, 1536
S = 2
w, h = W*S, H*S
img = Image.new("RGBA", (w, h), (0,0,0,0))
d = ImageDraw.Draw(img)

SKIN   = (247, 219, 200)
SKIN_S = (226, 186, 170)
LIP    = (206, 132, 140)
LIP_D  = (156, 88, 98)
LINE   = (52, 38, 44)
BROW   = (58, 44, 54)
SCLERA = (252, 253, 253)
IRIS_D = (26, 66, 74)
IRIS_M = (52, 146, 138)
IRIS_L = (122, 214, 194)
PUPIL  = (16, 20, 26)

def e(v): return int(round(v*S))

# ── 底色 ──
for y in range(h):
    t = y / (h-1)
    k = 1.0 - 0.07*t*t
    d.line([(0,y),(w,y)], fill=(int(SKIN[0]*k), int(SKIN[1]*k), int(SKIN[2]*k), 255))

def glow(cx, cy, rx, ry, color, alpha, blur):
    m = Image.new("L", (w,h), 0)
    ImageDraw.Draw(m).ellipse([e(cx-rx),e(cy-ry),e(cx+rx),e(cy+ry)], fill=alpha)
    m = m.filter(ImageFilter.GaussianBlur(e(blur)))
    global img, d
    img = Image.composite(Image.new("RGBA",(w,h),color+(255,)), img, m)
    d = ImageDraw.Draw(img)

# 额头/鼻梁高光
glow(512, 300, 330, 230, (255,250,244), 34, 90)
# 腮红
glow(296, 905, 96, 62, (236,148,140), 40, 40)
glow(728, 905, 96, 62, (236,148,140), 40, 40)

EYE_Y = 655
EYE_DX = 218
EW, EH = 118, 62        # 半宽 / 半高

for sgn in (-1, 1):
    cx = 512 + sgn*EYE_DX
    # 眼窝
    glow(cx, EYE_Y-6, 132, 82, SKIN_S, 26, 34)

    def upper(t):   # 上眼睑弧线（t: 0..1 从左到右）
        return EYE_Y - EH*math.sin(math.pi*t)**0.62

    def lower(t):
        return EYE_Y + EH*0.86*math.sin(math.pi*t)**0.80

    # 眼白
    pts = [(e(cx-EW+2*EW*(i/44)), e(upper(i/44))) for i in range(45)]
    pts += [(e(cx-EW+2*EW*(i/44)), e(lower(i/44))) for i in range(44, -1, -1)]
    d.polygon(pts, fill=SCLERA+(255,))

    # 虹膜（大眼，占眼高 85%）
    ir = EH*0.92
    icx, icy = cx + (5 if sgn > 0 else -5), EYE_Y + 3
    d.ellipse([e(icx-ir),e(icy-ir*1.02),e(icx+ir),e(icy+ir*0.98)], fill=IRIS_D+(255,))
    d.ellipse([e(icx-ir*0.86),e(icy-ir*0.90),e(icx+ir*0.86),e(icy+ir*0.90)], fill=IRIS_M+(255,))
    d.ellipse([e(icx-ir*0.70),e(icy+ir*0.05),e(icx+ir*0.70),e(icy+ir*0.92)], fill=IRIS_L+(255,))
    d.ellipse([e(icx-ir*0.40),e(icy-ir*0.40),e(icx+ir*0.40),e(icy+ir*0.42)], fill=PUPIL+(255,))
    # 上缘压暗 + 高光
    d.ellipse([e(icx-ir*0.98),e(icy-ir*1.05),e(icx+ir*0.98),e(icy-ir*0.18)], fill=(18,30,38,150))
    d.ellipse([e(icx-26),e(icy-30),e(icx-2),e(icy-6)], fill=(255,255,255,245))
    d.ellipse([e(icx+18),e(icy+16),e(icx+34),e(icy+32)], fill=(255,255,255,170))

    # 上眼线（粗，眼尾外扬）
    for i in range(80):
        t = i/79
        x = cx - EW - 10 + (2*EW + 26)*t
        if x <= cx + EW:
            tt = (x - (cx-EW))/(2*EW)
            yt = EYE_Y - EH*math.sin(math.pi*max(0.0,min(1.0,tt)))**0.62
        else:
            yt = EYE_Y - EH*0.06 + (x-(cx+EW))*0.55
        th = 17*math.sin(math.pi*min(1.0, t*1.02))**0.42 + 3
        d.line([(e(x),e(yt-th*0.35)),(e(x),e(yt+th*0.65))], fill=LINE+(255,), width=e(1.6))
    # 眼尾 3 根睫毛
    for k in range(3):
        bx = cx + EW*sgn
        by = EYE_Y - EH*0.06
        d.line([(e(bx),e(by)),(e(bx+sgn*(20+k*10)), e(by-(12+k*5)))], fill=LINE+(255,), width=e(3.0-k*0.6))
    # 下睫毛
    for i in range(30):
        t = i/29
        x = cx - EW*0.95 + 2*EW*0.95*t
        yy = lower(t*0.95)
        d.line([(e(x),e(yy)),(e(x),e(yy+5))], fill=(112,86,92,200), width=e(1.4))
    # 双眼皮
    for i in range(40):
        t = i/39
        x = cx - EW*0.92 + 2*EW*0.92*t
        yy = EYE_Y - EH*math.sin(math.pi*t)**0.62 - 20
        d.line([(e(x),e(yy)),(e(x),e(yy+4))], fill=(186,132,126,120), width=e(1.2))

    # 眉毛
    for i in range(52):
        t = i/51
        x = cx - 128 + 256*t
        yy = 372 - 30*math.sin(math.pi*t)**0.62 - (26 if t > 0.5 else 0)
        th = 5 + 12*math.sin(math.pi*min(1.0, t*1.2))**0.5
        d.line([(e(x),e(yy)),(e(x),e(yy+th))], fill=BROW+(255,), width=e(1.5))

# ── 鼻 ──
glow(496, 940, 16, 52, SKIN_S, 34, 20)
glow(512, 1002, 18, 11, (240,210,192), 90, 12)
for sgn in (-1,1):
    d.ellipse([e(512+sgn*18-7),e(1004-5),e(512+sgn*18+7),e(1004+5)], fill=(178,134,124,150))

# ── 唇 ──
# 上唇
d.polygon([(e(512-78),e(1170)),(e(512-44),e(1140)),(e(512),e(1156)),(e(512+44),e(1140)),
           (e(512+78),e(1170)),(e(512+34),e(1196)),(e(512),e(1188)),(e(512-34),e(1196))], fill=LIP+(255,))
# 下唇
d.ellipse([e(512-62),e(1188),e(512+62),e(1244)], fill=(216,146,152,255))
d.ellipse([e(512-34),e(1198),e(512+34),e(1216)], fill=(230,168,170,255))
# 唇线
for i in range(70):
    t = i/69
    x = 512-78 + 156*t
    yy = 1170 + 22*math.sin(math.pi*t) - 10*math.sin(math.pi*t*2)
    d.line([(e(x),e(yy)),(e(x),e(yy+5))], fill=LIP_D+(220,), width=e(1.3))
# 下唇高光
glow(492, 1222, 26, 10, (255,240,238), 120, 8)
# 唇下阴影
glow(512, 1268, 62, 18, SKIN_S, 46, 18)

# ── 下颌/颈部柔和阴影（弱） ──
glow(512, 1470, 210, 90, (214,176,160), 34, 60)

out = img.resize((W, H), Image.LANCZOS)
out.save("/root/game/art/face_tex.png")
print("face tex", out.size)
