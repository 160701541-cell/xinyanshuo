from PIL import Image, ImageDraw, ImageFilter
import math, random

def bg(W,H,seed=1,c=(9,10,14),glow=(120,150,175)):
    random.seed(seed)
    im=Image.new('RGB',(W,H),c); d=ImageDraw.Draw(im)
    for r in range(int(min(W,H)*0.9),0,-4):
        t=r/(min(W,H)*0.9); k=int(6+26*(1-t)**2.4)
        d.ellipse([W/2-r,W/2-r,W/2+r,W/2+r],fill=(k,k+1,k+5))
    im=im.convert('RGBA')
    fog=Image.new('RGBA',(W,H),(0,0,0,0)); fd=ImageDraw.Draw(fog)
    for i in range(14):
        x=random.randint(0,W); y=random.randint(int(H*0.45),H); rr=random.randint(50,140)
        fd.ellipse([x-rr,y-rr,x+rr,y+rr],fill=glow+(9,))
    im.alpha_composite(fog.filter(ImageFilter.GaussianBlur(26)))
    return im

def dust(d,W,H,n=80,col=(175,228,238)):
    for i in range(n):
        x=random.randint(10,W-10); y=random.randint(10,H-10)
        r=random.choice([1,1,2]); a=random.randint(16,90)
        d.ellipse([x,y,x+r,y+r],fill=col+(a,))

def metal_panel(d,quad,base,lit,dark,steps=40):
    # 沿四边形画竖向渐变分条（近似拉丝金属）
    x0=min(p[0] for p in quad); x1=max(p[0] for p in quad)
    for i in range(steps):
        t=i/(steps-1)
        c=tuple(int(dark[k]+(lit[k]-dark[k])*math.sin(t*math.pi)**0.8) for k in range(3))
        xa=x0+(x1-x0)*t; xa2=x0+(x1-x0)*(t+1.0/steps)
        d.polygon([(xa,min(p[1] for p in quad)),(xa2,min(p[1] for p in quad)),
                   (xa2,max(p[1] for p in quad)),(xa,max(p[1] for p in quad))],fill=c)

def glow_line(d,pts,col,width=4,passes=3):
    for k in range(passes):
        w=max(1,width-k)
        a=60+k*30
        d.line(pts,fill=col+(a,),width=w)

def cloth(d,quad,base,light,dark,folds=6,seed=3):
    random.seed(seed)
    d.polygon([tuple(map(int,p)) for p in quad],fill=base)
    xs=[p[0] for p in quad]; ys=[p[1] for p in quad]
    x0,x1,y0,y1=min(xs),max(xs),min(ys),max(ys)
    for k in range(folds):
        fx=x0+(x1-x0)*(k+0.5)/folds
        d.line([(fx,y0),(fx+(random.random()-0.5)*12,y1)],fill=dark,width=2)
        d.line([(fx-3,y0),(fx-3+(random.random()-0.5)*12,y1)],fill=light,width=1)

def radial_light(im,cx,cy,r,col=(255,220,150),a=120):
    lay=Image.new('RGBA',im.size,(0,0,0,0)); ld=ImageDraw.Draw(lay)
    ld.ellipse([cx-r,cy-r,cx+r,cy+r],fill=col+(a,))
    im.alpha_composite(lay.filter(ImageFilter.GaussianBlur(int(r*0.55))))
