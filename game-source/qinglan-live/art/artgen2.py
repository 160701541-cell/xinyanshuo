from PIL import Image, ImageDraw
import math, random
from artlib import bg, dust, radial_light
S=640
def A(d,box,s,e,fill,width=2):
    x0,y0,x1,y1=box; x0,x1=sorted((x0,x1)); y0,y1=sorted((y0,y1))
    if x1-x0<1 or y1-y0<1: return
    d.arc([x0,y0,x1,y1],s,e,fill=fill,width=width)
def save(im,n): im.convert('RGB').save(n)

# 1 玄天斩
im=bg(S,S,seed=41,glow=(120,200,220)); d=ImageDraw.Draw(im)
cx,cy=320,330; a=math.radians(-28)
def R(p,q): return (cx+p*math.cos(a)-q*math.sin(a), cy+p*math.sin(a)+q*math.cos(a))
for i in range(7): d.line([(0,470+i*24),(640,430+i*24)],fill=(13,15,21),width=2)
d.polygon([R(-18,-268),R(18,-268),R(18,74),R(-18,74)],fill=(118,130,148))
d.polygon([R(-18,-268),R(-7,-268),R(-7,74),R(-18,74)],fill=(198,212,228))
d.polygon([R(7,-268),R(18,-268),R(18,74),R(7,74)],fill=(90,102,122))
d.polygon([R(-7,-268),R(7,-268),R(7,74),R(-7,74)],fill=(160,174,192))
for k in range(60):
    y=-262+k*5.6
    d.line([R(-17,y),R(-8,y)],fill=(226,236,248,55),width=1)
    d.line([R(8,y),R(17,y)],fill=(72,84,104,55),width=1)
for k in range(13): A(d,[R(-3,-240+k*22)[0],R(-3,-240+k*22)[1],R(3,-226+k*22)[0],R(3,-226+k*22)[1]],300,120,(206,220,236),1)
d.line([R(0,-262),R(0,70)],fill=(110,124,144),width=5)
d.line([R(-2,-258),R(-2,66)],fill=(180,194,210),width=2)
d.polygon([R(-18,-268),R(0,-312),R(18,-268)],fill=(228,238,250))
d.polygon([R(-18,-268),R(0,-312),R(0,-268)],fill=(252,254,255))
d.polygon([R(-76,64),R(-22,52),R(-22,92),R(-64,104)],fill=(72,150,154))
d.polygon([R(76,64),R(22,52),R(22,92),R(64,104)],fill=(58,130,136))
d.polygon([R(-22,54),R(22,54),R(22,94),R(-22,94)],fill=(140,226,222))
for k in range(4):
    A(d,[R(-58,60+k*9)[0],R(-58,60+k*9)[1],R(-30,72+k*9)[0],R(-30,72+k*9)[1]],180,330,(34,92,96),2)
    A(d,[R(30,60+k*9)[0],R(30,60+k*9)[1],R(58,72+k*9)[0],R(58,72+k*9)[1]],210,360,(34,92,96),2)
d.polygon([R(-12,94),R(12,94),R(12,186),R(-12,186)],fill=(34,32,34))
for k in range(8):
    y=98+k*11; d.line([R(-12,y),R(12,y+5)],fill=(104,92,76),width=3)
d.ellipse([R(-15,200)[0]-13,R(-15,200)[1]-13,R(-15,200)[0]+13,R(-15,200)[1]+13],fill=(206,168,92))
for g in range(3):
    pts=[R(6+g*6,190)]
    for k in range(1,15): pts.append(R(6+g*6+math.sin(k*0.62+g*1.4)*34,190+k*19))
    d.line(pts,fill=(156,44,50),width=6-g)
for k in range(44):
    t=k/43.0; y=-250+t*300; d.line([R(-10,y),R(-6,y+7)],fill=(120,226,232,int(50+140*abs(math.sin(t*8)))),width=2)
for i in range(14):
    x=random.randint(90,550); y=random.randint(400,600); r=random.randint(3,8)
    d.polygon([(x,y-r),(x+r,y),(x,y+r),(x-r,y)],fill=(36,40,48))
radial_light(im,300,180,190,(120,210,230),50); dust(d,S,S,110,(180,232,240)); save(im,'r1.png')

# 2 镇岳印
im=bg(S,S,seed=42,glow=(200,180,140)); d=ImageDraw.Draw(im)
d.ellipse([150,548,490,596],fill=(11,12,16))
d.polygon([(150,320),(490,320),(478,552),(162,552)],fill=(230,230,220))
d.polygon([(150,320),(320,320),(320,552),(162,552)],fill=(246,246,238))
for k in range(9):
    x=172+k*36; d.line([(x,326),(x-14,548)],fill=(206,206,196),width=2)
for k in range(6): A(d,[150,350+k*34,490,376+k*34],200,340,(212,212,202),2)
d.polygon([(270,150),(370,150),(404,300),(236,300)],fill=(240,240,232))
d.polygon([(270,150),(320,110),(370,150)],fill=(252,252,246))
d.polygon([(292,214),(320,168),(348,214)],fill=(204,204,194))
for k in range(3): A(d,[250+k*40,160,300+k*40,206],200,340,(214,214,204),3)
for (x0,x1) in ((186,300),(340,454)):
    d.rectangle([x0,376,x1,492],outline=(196,60,56),width=10)
    d.line([(x0,434),(x1,434)],fill=(196,60,56),width=8)
radial_light(im,320,430,170,(255,236,180),55); dust(d,S,S,70,(246,240,214)); save(im,'r2.png')

# 3 无咎钟
im=bg(S,S,seed=43,glow=(210,190,130)); d=ImageDraw.Draw(im)
d.polygon([(230,150),(410,150),(500,520),(140,520)],fill=(146,138,92))
d.polygon([(230,150),(320,150),(320,520),(140,520)],fill=(186,178,120))
d.polygon([(140,520),(500,520),(478,566),(162,566)],fill=(112,104,66))
d.polygon([(140,520),(500,520),(492,538),(148,538)],fill=(198,190,132))
for y in (200,262,324):
    d.rectangle([176,y,464,y+16],fill=(96,88,54)); d.rectangle([176,y+16,464,y+22],fill=(196,188,128))
    for x in range(190,460,28): A(d,[x,y+2,x+20,y+16],200,340,(168,160,104),2)
for y in (352,392,432,472):
    for x in range(210,470,44):
        d.ellipse([x-7,y-7,x+7,y+7],fill=(206,198,140))
d.polygon([(300,60),(340,60),(348,120),(292,120)],fill=(226,196,112))
for sx in (-1,1): A(d,[320+sx*10-34,64,320+sx*10+34,132],0,180,(206,176,98),7)
for k in range(8):
    y=214+k*22; d.line([(300,y),(300,y+10)],fill=(240,212,126),width=2); d.line([(306,y+3),(316,y+3)],fill=(240,212,126),width=2)
radial_light(im,320,300,200,(255,220,140),50); dust(d,S,S,80,(244,228,170)); save(im,'r3.png')

# 4 照胆镜
im=bg(S,S,seed=44,glow=(150,220,220)); d=ImageDraw.Draw(im); cx,cy=320,300
for r,c in [(250,(150,160,176)),(236,(196,206,220)),(214,(230,238,248)),(186,(170,232,232))]:
    d.ellipse([cx-r,cy-r,cx+r,cy+r],fill=c)
d.ellipse([cx-150,cy-150,cx+150,cy+150],fill=(120,204,204))
d.ellipse([cx-96,cy-96,cx+96,cy+96],fill=(168,236,234))
d.ellipse([cx-56,cy-56,cx+56,cy+56],fill=(214,250,248))
A(d,[cx-210,cy-210,cx+210,cy+210],200,340,(255,255,255),6)
for k in range(8):
    t=k*math.pi/4; d.line([(cx+int(96*math.cos(t)),cy+int(96*math.sin(t))),(cx+int(186*math.cos(t)),cy+int(186*math.sin(t)))],fill=(90,102,120),width=3)
for k in range(16):
    t=k*math.pi/8; x=cx+int(220*math.cos(t)); y=cy+int(220*math.sin(t))
    d.ellipse([x-9,y-9,x+9,y+9],fill=(88,100,118)); d.ellipse([x-4,y-4,x+4,y+4],fill=(206,214,226))
d.polygon([(300,548),(340,548),(352,596),(288,596)],fill=(200,172,96))
d.rectangle([280,594,360,612],fill=(124,114,86))
radial_light(im,cx,cy,220,(180,252,252),70); dust(d,S,S,70,(200,246,246)); save(im,'r4.png')

# 5 青囊灯
im=bg(S,S,seed=45,glow=(255,200,120)); d=ImageDraw.Draw(im)
for y in range(60,220,14): A(d,[316,y,324,y+8],0,180,(158,150,132),2)
d.polygon([(150,392),(490,392),(452,540),(188,540)],fill=(112,182,172))
d.polygon([(150,392),(320,392),(320,540),(188,540)],fill=(150,208,198))
d.polygon([(150,392),(490,392),(474,362),(166,362)],fill=(178,228,216))
d.rectangle([232,432,408,462],fill=(198,238,228))
for k in range(5):
    x=196+k*58; d.polygon([(x,392),(x+26,362),(x+52,392)],fill=(140,200,190))
radial_light(im,320,300,170,(255,200,110),160)
d.polygon([(320,168),(376,268),(344,332),(296,332),(264,268)],fill=(255,190,86))
d.polygon([(320,196),(356,272),(320,320),(284,272)],fill=(255,236,180))
d.polygon([(320,224),(340,272),(320,300),(300,272)],fill=(255,252,226))
for sx in (-1,1): d.line([(320+sx*128,392),(320+sx*176,500)],fill=(64,124,120),width=7)
dust(d,S,S,90,(255,224,168)); save(im,'r5.png')

# 6 九幽伞
im=bg(S,S,seed=46,glow=(150,120,210)); d=ImageDraw.Draw(im)
d.polygon([(40,340),(600,340),(440,120),(200,120)],fill=(56,58,72))
d.polygon([(64,340),(576,340),(436,142),(204,142)],fill=(90,94,110))
for k in range(13):
    x0=64+k*41; x1=204+k*18; d.line([(x0,340),(x1,142)],fill=(30,31,40),width=4)
for k in range(4):
    t=k/3.0; d.line([(64+18*t,340-66*t),(576-18*t,340-66*t)],fill=(118,122,138),width=2)
d.polygon([(300,96),(340,96),(350,140),(290,140)],fill=(214,190,140))
d.line([(320,140),(320,600)],fill=(156,146,124),width=8)
d.polygon([(310,560),(330,560),(336,606),(304,606)],fill=(170,120,220))
for k in range(11):
    x=90+k*46; d.line([(x,346),(x-6+k%3*4,470+(k%4)*16)],fill=(60,50,92),width=3)
radial_light(im,320,240,220,(150,120,210),45); dust(d,S,S,80,(190,160,240)); save(im,'r6.png')

# 7 蛊母鼎
im=bg(S,S,seed=47,glow=(150,220,140)); d=ImageDraw.Draw(im)
d.ellipse([120,590,520,620],fill=(10,11,15))
d.polygon([(110,200),(530,200),(486,470),(154,470)],fill=(126,94,72))
d.polygon([(110,200),(320,200),(320,470),(154,470)],fill=(158,120,92))
d.polygon([(110,200),(530,200),(506,240),(134,240)],fill=(180,140,106))
for k in range(5):
    x=170+k*72; A(d,[x,268,x+56,330],180,360,(84,60,44),5); d.ellipse([x+18,296,x+38,316],fill=(60,44,34))
for x in range(190,470,52): d.ellipse([x,352,x+22,374],fill=(168,130,98))
radial_light(im,240,330,80,(160,240,130),120); radial_light(im,400,330,80,(160,240,130),120)
d.rectangle([150,150,490,204],fill=(190,150,112)); d.rectangle([236,96,404,154],fill=(140,106,80))
d.rectangle([286,64,354,98],fill=(212,192,146))
for k in range(3): A(d,[276+k*30,72,336+k*30,110],200,340,(168,140,100),3)
for (ax,bx) in ((150,216),(424,490)):
    d.polygon([(ax,470),(bx,470),(bx+22,600),(ax-22,600)],fill=(72,52,40))
d.rectangle([298,470,352,600],fill=(72,52,40))
dust(d,S,S,90,(180,240,160)); save(im,'r7.png')

# 8 春秋笔
im=bg(S,S,seed=48,glow=(200,200,240)); d=ImageDraw.Draw(im)
d.polygon([(280,120),(360,120),(352,470),(288,470)],fill=(198,176,136))
d.polygon([(280,120),(310,120),(316,470),(288,470)],fill=(236,220,180))
for y in (190,268,346):
    d.rectangle([274,y,366,y+14],fill=(132,112,84)); d.rectangle([274,y+14,366,y+20],fill=(226,210,172))
for k in range(6):
    x=286+k*12; d.line([(x,126),(x-6,466)],fill=(212,194,156),width=1)
d.polygon([(288,470),(352,470),(340,566),(300,566)],fill=(92,72,50))
d.polygon([(292,500),(348,500),(334,606),(306,606)],fill=(38,38,50))
for k in range(9):
    x=294+k*6; d.line([(x,504),(x+(3 if k%2 else -2),604)],fill=(64,64,80),width=2)
d.rectangle([266,92,374,124],fill=(214,194,144)); d.rectangle([296,62,344,94],fill=(234,214,164))
radial_light(im,320,130,150,(220,210,255),45); dust(d,S,S,80,(224,224,252)); save(im,'r8.png')

# 9 解语琴
im=bg(S,S,seed=49,glow=(255,180,200)); d=ImageDraw.Draw(im)
d.polygon([(110,230),(556,206),(566,300),(100,330)],fill=(140,96,60))
d.polygon([(110,230),(556,206),(558,224),(108,248)],fill=(190,142,96))
for k in range(7):
    x=126+k*62; d.line([(x,240-k*0.4),(x+6,320-k*1.2)],fill=(240,234,218),width=2)
d.polygon([(96,236),(140,232),(146,318),(100,326)],fill=(94,62,40))
d.polygon([(520,214),(566,210),(566,296),(522,300)],fill=(94,62,40))
for x in (150,430): d.polygon([(x,330),(x+26,330),(x+20,372),(x+6,372)],fill=(168,124,84))
for x in (176,392):
    for k in range(4): d.line([(x+k*4,372),(x-8+k*6,452)],fill=(176,58,64),width=3)
d.rectangle([100,326,568,342],fill=(84,54,34))
radial_light(im,320,280,200,(255,198,206),40); dust(d,S,S,70,(255,210,220)); save(im,'r9.png')

# 10 不系舟
im=bg(S,S,seed=50,glow=(140,200,240)); d=ImageDraw.Draw(im)
d.polygon([(70,410),(300,392),(570,410),(500,520),(300,540),(140,520)],fill=(122,102,76))
d.polygon([(70,410),(300,392),(570,410),(556,432),(300,416),(84,432)],fill=(176,150,114))
for k in range(7):
    t=k/6.0; d.line([(120+60*t,520-16*t),(480+40*(1-t),520-16*t)],fill=(96,78,58),width=2)
d.polygon([(250,400),(350,400),(360,300),(240,300)],fill=(150,128,96))
for k in range(4): A(d,[240,312+k*22,360,342+k*22],200,340,(112,94,70),3)
d.polygon([(470,404),(540,398),(556,300),(500,286)],fill=(238,232,212))
d.line([(320,398),(320,290)],fill=(70,58,44),width=6)
for y in (556,580,600): d.line([(60,y),(580,y-4)],fill=(110,172,222) if y==556 else (76,132,182),width=4 if y==556 else 2)
dust(d,S,S,80,(180,220,250)); save(im,'r10.png')
print('all 10 redesigned')
