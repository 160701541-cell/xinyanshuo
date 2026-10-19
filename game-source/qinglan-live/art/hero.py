from PIL import Image, ImageDraw, ImageFilter
import math, random
random.seed(9)
W,H=768,1024
def rot(p,yaw):
    x,y,z=p; c,s=math.cos(yaw),math.sin(yaw); return (x*c-z*s,y,x*s+z*c)
def proj(p,yaw,cx,cy,s,tilt=0.26):
    x,y,z=rot(p,yaw); return (cx+x*s, cy-y*s+z*s*tilt), (x*s+z*c)
LIGHT=(-0.42,-0.74,-0.52)
def face_col(base,n,yaw):
    nx,ny,nz=rot(n,yaw)
    d=max(0.0,nx*LIGHT[0]+ny*LIGHT[1]+nz*LIGHT[2])
    k=0.66+0.60*d
    return tuple(min(255,int(c*k)) for c in base)+(255,)
def box(b,base): return (b,base)
QUADS=[((0,0,1),(4,5,6,7)),((0,0,-1),(0,1,2,3)),((-1,0,0),(0,3,7,4)),
       ((1,0,0),(1,5,6,2)),((0,1,0),(3,2,6,7)),((0,-1,0),(0,4,5,1))]
def render(boxes,yaw,cx,cy,s,tilt=0.26):
    items=[]
    for b,base in boxes:
        x0,y0,z0,x1,y1,z1=b
        V=[(x0,y0,z0),(x1,y0,z0),(x1,y1,z0),(x0,y1,z0),(x0,y0,z1),(x1,y0,z1),(x1,y1,z1),(x0,y1,z1)]
        for n,qi in QUADS:
            pts=[proj(V[i],yaw,cx,cy,s,tilt)[0] for i in qi]
            zc=sum(rot(V[i],yaw)[2] for i in qi)/4.0
            items.append((zc,pts,face_col(base,n,yaw)))
    items.sort(key=lambda t:t[0])
    return items
yaw=math.radians(20); cx,cy,s=384,742,11.4
skin=(238,204,182); robe=(70,96,96); robeD=(56,78,78); hair=(38,34,40)
B=[]
B.append(((-4.7,-0.2,-2.0,-1.5,2.4,2.0),(30,32,38)))
B.append((( 1.5,-0.2,-2.0, 4.7,2.4,2.0),(34,36,42)))
B.append(((-4.6,0,-1.6,-1.6,13,1.6),(44,48,56)))
B.append((( 1.6,0,-1.6, 4.6,13,1.6),(40,44,52)))
B.append(((-6.4,12,-3.2, 6.4,16.5,3.2),(60,82,82)))
B.append(((-6.8,16.5,-3.4, 6.8,17.6,3.4),(74,98,96)))
B.append(((-4.8,17,-2.9, 4.8,33,2.9),robe))
B.append(((-5.1,25.5,-3.0, 5.1,28.6,3.0),(46,52,58)))
B.append(((-6.6,32.5,-3.1, 6.6,37,3.1),(74,98,98)))
B.append(((-8.6,23.5,-2.7,-4.9,36,2.7),(68,92,92)))
B.append(( 4.9,23.5,-2.7,  8.6,36,2.7),(58,80,80))
B.append(((-9.0,21.5,-2.5,-5.4,25,2.5),skin))
B.append(( 5.4,21.5,-2.5,  9.0,25,2.5),skin))
B.append(((-1.9,36,-1.9, 1.9,39.4,1.9),skin))
B.append(((-3.5,39.4,-3.1, 3.5,48.2,3.1),skin))
B.append(((-3.7,46.6,-3.3, 3.7,49.4,3.3),hair))
B.append(((-3.7,40.6,2.4, 3.7,48.8,3.6),hair))
B.append(((-2.1,49.4,-1.7, 2.1,53.4,1.7),hair))
B.append((( 3.3,25,3.0, 4.7,52,3.9),(78,86,98)))     # 剑鞘
B.append((( 3.1,50,2.8, 4.9,54,4.1),(150,196,196)))   # 剑格
B.append((( 3.4,54,3.0, 4.6,58.4,3.9),(44,42,46)))    # 剑柄
B.append((( 3.1,58.4,2.8, 4.9,60.2,4.1),(198,162,92))) # 剑首
# 修正错误括号
B=[b for b in B]
import copy
