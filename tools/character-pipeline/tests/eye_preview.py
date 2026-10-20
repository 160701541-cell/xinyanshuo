import numpy as np, sys
from PIL import Image
def ss(a,b,x):
    t=np.clip((x-a)/(b-a),0,1); return t*t*(3-2*t)
def V(*c): return np.array(c,float)
def mix(a,b,t): t=np.asarray(t)[...,None] if np.ndim(t)==2 else t; return a*(1-t)+b*t
def eye(side,new,W=480,H=240):
    u=(np.arange(W)+.5)/W; v=(np.arange(H)+.5)/H
    U,Vv=np.meshgrid(u,v); px=(U*2-1)*side; py=Vv*2-1
    py=-py   # 屏幕向上为 +y（与现有截图里"上睑在上"一致）
    sclera=V(.97,.96,.93); pupil=V(.06,.05,.05); iris=V(.22,.12,.07); flesh=V(.80,.52,.47); lid=V(.10,.08,.08)
    qy=py+.18*px; d=np.hypot(px/.95,qy/.42); a=1-ss(.9,1,d)
    col=np.broadcast_to(sclera,(H,W,3)).copy()
    if not new:
        pd=np.hypot((px-.10)/.26,(py+.02)/.30)
        col=mix(col,pupil,(1-ss(.88,1,pd)))
        ll=1-ss(0,.10,abs(py-.30)); col=mix(col,pupil,ll*.85)
    else:
        col=sclera*(1-.24*ss(.30,1,d))[...,None]
        col=mix(col,flesh,.55*ss(.55,.95,-px))
        ipx,ipy=px-.10,py+.02
        idist=np.hypot(ipx/.31,ipy/.38); imask=1-ss(.9,1,idist)
        s1=ss(.15,.95,idist)[...,None]; ic=iris*1.3*(1-s1)+iris*.55*s1
        ic=mix(ic,pupil,.65*ss(.78,1,idist)); col=mix(col,ic,imask)
        pd=np.hypot(ipx/.145,ipy/.18); col=mix(col,pupil,1-ss(.85,1,pd))
        col=col*(1-.38*ss(-.05,.30,py))[...,None]
        rawx=px*side; pcx=.10*side
        hl=1-ss(.55,1,np.hypot((rawx-pcx+.07)/.075,(py+.02-.11)/.095))
        hl2=1-ss(.55,1,np.hypot((rawx-pcx-.08)/.04,(py+.02+.10)/.05))
        col=mix(col,V(1,1,1),np.clip(hl*.95+hl2*.35*.95,0,1))
        lw=.10+.07*ss(0,.9,px); ll=1-ss(0,1,abs(py-.30)/lw)
        col=mix(col,pupil,ll*.88)
        low=1-ss(0,.09,abs(d-.93)); col=mix(col,lid*2.2,low*.30*(1-ss(-.10,.10,py)))
    a=a*(1-ss(.34,.56,py))
    return col,a
skin=V(.60,.46,.34)
rows=[]
for new in (0,1):
    imgs=[]
    for side in (-1,1):
        c,a=eye(side,new); imgs.append(c*a[...,None]+skin*(1-a[...,None]))
    rows.append(np.concatenate([imgs[0],np.full((240,40,3),skin),imgs[1]],1))
out=np.concatenate([rows[0],np.full((20,rows[0].shape[1],3),skin),rows[1]],0)
Image.fromarray((np.clip(out,0,1)*255).astype('uint8')).save(sys.argv[1])
