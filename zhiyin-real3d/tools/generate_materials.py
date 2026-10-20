#!/usr/bin/env python3
"""Deterministic physically meaningful albedo / normal / roughness maps.
No flat Canvas colors. Maps are tileable and imported as Godot StandardMaterial3D textures.
They are original procedural textures (not generative illustrative renderings).
"""
from pathlib import Path
from PIL import Image
import math
import random

ROOT=Path(__file__).resolve().parent.parent/"assets"/"materials"
ROOT.mkdir(parents=True,exist_ok=True)
S=512
rng=random.Random(20261021)
def noise_at(x,y,seed=0):
    return (math.sin(x*2.17+y*.3+seed)*.45+
        math.sin(x*.57-y*1.31+seed*3)*.32+
        math.sin(x*5.2+y*2.8+seed)*.15)
def clamp(v):return int(max(0,min(255,v)))
def build(kind):
    height=[0.0]*(S*S)
    rgb=bytearray(S*S*3)
    rough=bytearray(S*S*3)
    for j in range(S):
        y=j/S
        for i in range(S):
            x=i/S
            # Periodic components make repeating materials seamless.
            nx=math.sin(2*math.pi*x)
            ny=math.sin(2*math.pi*y)
            n=noise_at(nx,ny,3.4)+.25*noise_at(nx*3,ny*3,7.5)
            if kind=="oak":
                stripe=math.sin(2*math.pi*(x*25 + 0.018*n+
                    .02*math.cos(2*math.pi*y*3)))
                h=.57+n*.11+stripe*.12
                shade=h*17 + stripe*7
                col=(116+shade,73+shade*.70,49+shade*.43)
                r=.64+stripe*.055+n*.026
            elif kind=="wall":
                h=.50+.07*n+.05*math.sin(2*math.pi*x*9)*math.sin(2*math.pi*y*9)
                shade=n*9
                col=(207+shade,191+shade,178+shade)
                r=.88+.06*n
            else:
                joints=1 if min(abs((x*8)%1),abs((y*8)%1))<.016 else 0
                h=.51+n*.10-joints*.11
                shade=n*13-joints*27
                col=(128+shade,132+shade,133+shade)
                r=.75+.09*n
            at=j*S+i
            height[at]=h
            rgb[3*at:3*at+3]=bytes(clamp(c) for c in col)
            v=clamp(255*r)
            rough[3*at:3*at+3]=bytes([v,v,v])
    normal=bytearray(S*S*3)
    for j in range(S):
        for i in range(S):
            def h(x,y):return height[((y+S)%S)*S+((x+S)%S)]
            gx=(h(i+1,j)-h(i-1,j))*3.4
            gy=(h(i,j+1)-h(i,j-1))*3.4
            denom=math.sqrt(gx*gx+gy*gy+1)
            n=[-gx/denom,-gy/denom,1/denom]
            at=(j*S+i)*3
            normal[at:at+3]=bytes([clamp(127.5+v*127.5) for v in n])
    for suffix,data in (("albedo",rgb),("roughness",rough),("normal",normal)):
        p=ROOT/(kind+"_"+suffix+".png")
        Image.frombytes("RGB",(S,S),bytes(data)).save(p,optimize=True)
        print(p.name,p.stat().st_size)
for k in ("oak","wall","stone"):build(k)
