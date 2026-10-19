from PIL import Image, ImageDraw
import math

# —— 极简轴对齐盒体渲染器（伪 3D：等轴投影 + 每面按法线着色）——
def rot(p, yaw):
    x,y,z=p; c,s=math.cos(yaw),math.sin(yaw)
    return (x*c-z*s, y, x*s+z*c)

def project(p, yaw, cx, cy, s, tilt=0.30):
    x,y,z=rot(p,yaw)
    sx=cx + x*s
    sy=cy - y*s + z*s*tilt
    return (sx, sy), z

FACES=[((-1,0,0),(0,-1,0),(0,0,-1)),((1,0,0),(0,1,0),(0,0,1)),
       ((0,-1,0),(1,0,0),(0,0,-1)),((0,1,0),(-1,0,0),(0,0,1)),
       ((0,0,-1),(1,0,0),(0,-1,0)),((0,0,1),(-1,0,0),(0,1,0))]

LIGHT=(-0.45,-0.72,-0.52)
def shade(base, n, yaw):
    nx,ny,nz=rot(n,yaw)
    d=max(0.0, nx*LIGHT[0]+ny*LIGHT[1]+nz*LIGHT[2])
    k=0.48+0.62*d
    return tuple(min(255,int(c*k)) for c in base)+(255,)

def draw_box(d, box, base, yaw, cx, cy, s, tilt=0.30, blur=False):
    x0,y0,z0,x1,y1,z1=box
    V=[(x0,y0,z0),(x1,y0,z0),(x1,y1,z0),(x0,y1,z0),(x0,y0,z1),(x1,y0,z1),(x1,y1,z1),(x0,y1,z1)]
    quads=[(4,5,6,7),(0,1,2,3),(0,3,7,4),(1,5,6,2),(3,2,6,7),(0,4,5,1)]
    norms=[(0,0,1),(0,0,-1),(-1,0,0),(1,0,0),(0,1,0),(0,-1,0)]
    out=[]
    for idx,(qi,n) in enumerate(zip(quads,norms)):
        pts=[project(V[i],yaw,cx,cy,s,tilt) for i in qi]
        depth=sum(p[1] for p in pts)/4.0
        out.append((depth, [p[0] for p in pts], shade(base,n,yaw)))
    out.sort(key=lambda t:t[0])
    for _,pts,col in out:
        d.polygon(pts,fill=col,outline=None)

def rx(x): return x
