from PIL import Image, ImageDraw, ImageFilter
import math, random
random.seed(4)
W, H = 768, 1024

def rot(p, yaw):
    x, y, z = p
    c, s = math.cos(yaw), math.sin(yaw)
    return (x*c - z*s, y, x*s + z*c)

def proj(p, yaw, cx, cy, s, tilt=0.24):
    x, y, z = rot(p, yaw)
    return (cx + x*s, cy - y*s + z*s*tilt)

LIGHT = (-0.42, -0.78, -0.46)

def col(base, n, yaw):
    nx, ny, nz = rot(n, yaw)
    d = max(0.0, nx*LIGHT[0] + ny*LIGHT[1] + nz*LIGHT[2])
    k = 0.72 + 0.55*d
    return tuple(min(255, int(c*k)) for c in base) + (255,)

QUADS = [((0,0,1),(4,5,6,7)), ((0,0,-1),(0,1,2,3)), ((-1,0,0),(0,3,7,4)),
         ((1,0,0),(1,5,6,2)), ((0,1,0),(3,2,6,7)), ((0,-1,0),(0,4,5,1))]

def render(boxes, yaw, cx, cy, s):
    items = []
    for (b, base) in boxes:
        x0,y0,z0,x1,y1,z1 = b
        V = [(x0,y0,z0),(x1,y0,z0),(x1,y1,z0),(x0,y1,z0),
             (x0,y0,z1),(x1,y0,z1),(x1,y1,z1),(x0,y1,z1)]
        for n, qi in QUADS:
            pts = [proj(V[i], yaw, cx, cy, s) for i in qi]
            zc = sum(rot(V[i], yaw)[2] for i in qi)/4.0
            items.append((zc, pts, col(base, n, yaw)))
    items.sort(key=lambda t: t[0])
    return items

yaw = math.radians(20); cx, cy, s = 384, 748, 11.6
SKIN=(240,206,184); HAIR=(38,34,40); ROBE=(72,98,98); EDGE=(84,108,106)
B = [
 (((-4.8,-0.2,-2.0,-1.5,2.4,2.0),(30,32,38))),
]
B = [
 ((-4.8,-0.2,-2.0,-1.5,2.4,2.0),(30,32,38)),
 (( 1.5,-0.2,-2.0, 4.8,2.4,2.0),(34,36,42)),
 ((-4.7,0,-1.7,-1.5,13,1.7),(46,50,58)),
 (( 1.5,0,-1.7, 4.7,13,1.7),(42,46,54)),
 ((-6.5,12,-3.2, 6.5,16.6,3.2),(60,82,82)),
 ((-6.9,16.4,-3.4, 6.9,17.6,3.4),(74,98,96)),
 ((-4.9,17,-3.0, 4.9,33,3.0),ROBE),
 ((-5.2,25.4,-3.1, 5.2,28.6,3.1),(46,52,58)),
 ((-6.8,32.4,-3.2, 6.8,37,3.2),(74,98,98)),
 ((-8.8,23.4,-2.8,-4.9,36,2.8),(70,94,94)),
 (( 4.9,23.4,-2.8, 8.8,36,2.8),(60,82,82)),
 ((-9.2,21.2,-2.6,-5.5,24.8,2.6),SKIN),
 (( 5.5,21.2,-2.6, 9.2,24.8,2.6),SKIN),
 ((-2.0,36,-2.0, 2.0,39.6,2.0),SKIN),
 ((-3.6,39.6,-3.2, 3.6,48.4,3.2),SKIN),
 ((-3.8,46.8,-3.4, 3.8,49.6,3.4),HAIR),
 ((-3.8,40.8,2.4, 3.8,48.8,3.6),HAIR),
 ((-2.2,49.6,-1.8, 2.2,53.6,1.8),HAIR),
 (( 3.3,25,3.0, 4.8,52,4.0),(80,88,100)),
 (( 3.1,50,2.8, 5.0,54,4.2),(150,196,196)),
 (( 3.4,54,3.0, 4.7,58.4,4.0),(44,42,46)),
 (( 3.1,58.4,2.8, 5.0,60.2,4.2),(198,162,92)),
]

im = Image.new('RGBA', (W,H), (11,13,18,255))
d = ImageDraw.Draw(im)
for y,c in [(560,(16,21,27)),(660,(20,26,32)),(760,(24,30,36))]:
    d.polygon([(0,y),(190,y-40),(380,y-6),(560,y-48),(768,y-14),(768,H),(0,H)],fill=c+(255,))
    d.polygon([(0,y),(190,y-40),(380,y-6),(560,y-48),(768,y-14),(768,H),(0,H)],fill=None)
d.ellipse([cx-200, cy+6, cx+200, cy+70], fill=(7,8,11,255))
for zc, pts, c in render(B, yaw, cx, cy, s):
    d.polygon(pts, fill=c)

# —— 脸：贴在一张正面贴图上做 2D 细节，再映射到头的正面四边形 ——
x0,y0,z0,x1,y1,z1 = -3.6,39.6,-3.2, 3.6,48.4,-3.2
V=[(x0,y0,z0),(x1,y0,z0),(x1,y1,z0),(x0,y1,z0)]
quad=[proj(V[i],yaw,cx,cy,s) for i in (0,1,2,3)]
fw,fh=220,280
face=Image.new('RGBA',(fw,fh),(0,0,0,0)); fd=ImageDraw.Draw(face)
fd.rectangle([0,0,fw,fh],fill=SKIN+(255,))
fd.polygon([(0,fh),(fw,fh),(fw-40,fh-30),(40,fh-30)],fill=(228,192,170,255))
for sx in (0.28,0.72):
    ex=int(fw*sx); ey=int(fh*0.44)
    fd.polygon([(ex-34,ey-6),(ex+6,ey-12),(ex+4,ey-2),(ex-32,ey+2)],fill=(44,40,46,255))
    fd.ellipse([ex-26,ey+2,ex+26,ey+34],fill=(252,250,246,255))
    fd.ellipse([ex-12,ey+8,ex+12,ey+30],fill=(44,52,64,255))
    fd.ellipse([ex-6,ey+12,ex+4,ey+22],fill=(250,252,255,255))
fd.line([(fw//2-4,int(fh*0.52)),(fw//2+8,int(fh*0.66))],fill=(212,176,156,255),width=4)
fd.line([(fw//2-26,int(fh*0.78)),(fw//2+26,int(fh*0.78))],fill=(184,92,88,255),width=5)
fd.arc([fw//2-30,int(fh*0.80),fw//2+30,int(fh*0.90)],200,340,fill=(184,92,88,255),width=3)
face=face.filter(ImageFilter.GaussianBlur(0.6))
face_t=face.transform((int(math.dist(quad[0],quad[1])), int(math.dist(quad[0],quad[3]))), Image.QUAD,
                      (0,0,fw,0,fw,fh,0,fh), Image.BICUBIC)
im.alpha_composite(face_t, (int(min(p[0] for p in quad)), int(min(p[1] for p in quad))))
im.convert('RGB').save('/tmp/hero_prev.png')
print('ok')
