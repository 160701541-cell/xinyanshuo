from PIL import Image, ImageDraw, ImageFilter
import random
random.seed(5)
W,H=768,1024
im=Image.new('RGBA',(W,H),(12,14,18,255)); d=ImageDraw.Draw(im)
for y,c in [(700,(20,26,32)),(760,(24,30,36)),(820,(28,34,40))]:
    d.polygon([(0,y),(180,y-40),(360,y-10),(540,y-50),(768,y-18),(768,H),(0,H)],fill=c+(255,))
for i in range(9):
    x=40+i*88+random.randint(-10,10)
    d.rectangle([x,480,x+7,1024],fill=(22,30,30,255))
    for j in range(6):
        y=520+j*72
        d.line([(x+7,y),(x+7+random.randint(18,34),y-18)],fill=(26,36,34,255),width=3)
fog=Image.new('RGBA',(W,H),(0,0,0,0)); fd=ImageDraw.Draw(fog)
for i in range(12):
    x=random.randint(0,W); y=random.randint(600,1000); r=random.randint(80,180)
    fd.ellipse([x-r,y-r,x+r,y+r],fill=(150,170,190,10))
im=Image.alpha_composite(im, fog.filter(ImageFilter.GaussianBlur(30)))
d=ImageDraw.Draw(im)

cx=384
d.ellipse([cx-150,940,cx+150,984],fill=(9,10,13,255))
# 背后长剑
d.line([(cx+96,318),(cx+24,760)],fill=(58,64,74,255),width=26)
d.line([(cx+96,318),(cx+24,760)],fill=(86,94,106,255),width=14)
d.line([(cx+92,330),(cx+30,742)],fill=(126,136,150,255),width=3)
d.polygon([(cx+72,268),(cx+120,262),(cx+132,318),(cx+84,326)],fill=(150,196,196,255))
d.polygon([(cx+86,206),(cx+108,204),(cx+112,266),(cx+90,268)],fill=(46,44,48,255))
for k in range(4):
    y=214+k*13; d.line([(cx+87,y),(cx+111,y+3)],fill=(110,98,82,255),width=3)
d.ellipse([cx+82,190,cx+114,214],fill=(198,162,92,255))
d.line([(cx+108,300),(cx+150,392)],fill=(168,54,58,255),width=4)
robe=(74,96,96); robe_l=(96,122,120); robe_d=(52,72,72)
d.polygon([(cx-140,600),(cx+140,600),(cx+176,930),(cx-176,930)],fill=robe_d+(255,))
for sx in (-1,1):
    x=cx+sx*62
    d.polygon([(x-34,800),(x+34,800),(x+30,916),(x-30,916)],fill=(46,48,56,255))
    d.polygon([(x-38,912),(x+38,912),(x+42,962),(x-42,962)],fill=(32,34,40,255))
    d.ellipse([x-44,950,x+44,972],fill=(24,26,30,255))
d.polygon([(cx-96,400),(cx-30,392),(cx+30,392),(cx+96,400),(cx+136,470),(cx+166,930),(cx-166,930),(cx-136,470)],fill=robe+(255,))
d.polygon([(cx-120,404),(cx+4,404),(cx+4,700),(cx-152,700)],fill=robe_l+(255,))
for k in range(5):
    x=cx-100+k*50
    d.line([(x,470),(x-10,918)],fill=robe_d+(255,),width=3)
    d.line([(x+8,470),(x-2,918)],fill=(112,138,136,255),width=1)
d.polygon([(cx-56,392),(cx,470),(cx+56,392),(cx+34,386),(cx,424),(cx-34,386)],fill=(232,228,216,255))
d.polygon([(cx-58,392),(cx,472),(cx-2,474),(cx-70,398)],fill=(206,202,190,255))
d.rectangle([cx-128,556,cx+128,592],fill=(56,58,66,255))
d.rectangle([cx-128,556,cx+128,562],fill=(96,100,110,255))
d.ellipse([cx-16,584,cx+16,620],fill=(140,196,180,255)); d.ellipse([cx-8,592,cx+8,612],fill=(206,244,232,255))
d.line([(cx,620),(cx-6,676)],fill=(168,60,64,255),width=3)
for sx in (-1,1):
    x=cx+sx*120
    d.polygon([(x-sx*6,410),(x+sx*64,432),(x+sx*80,650),(x+sx*18,676)],fill=robe+(255,))
    d.polygon([(x-sx*6,410),(x+sx*20,420),(x+sx*26,652),(x+sx*18,676)],fill=robe_l+(255,))
    d.polygon([(x+sx*10,668),(x+sx*70,646),(x+sx*76,690),(x+sx*16,712)],fill=robe_d+(255,))
    hand=(x+sx*44,690)
    d.ellipse([hand[0]-24,hand[1]-26,hand[0]+24,hand[1]+26],fill=(232,198,176,255))
    if sx>0:
        for k in range(3):
            d.line([(hand[0]-12+k*10,hand[1]+6),(hand[0]-12+k*10,hand[1]+22)],fill=(198,160,140,255),width=3)
    else:
        d.line([(hand[0]-22,hand[1]+10),(hand[0]-6,hand[1]+14)],fill=(198,160,140,255),width=3)
        d.line([(hand[0]-24,hand[1]+18),(hand[0]-10,hand[1]+22)],fill=(150,60,60,255),width=3)
d.polygon([(cx-24,366),(cx+24,366),(cx+27,406),(cx-27,406)],fill=(226,192,170,255))
d.polygon([(cx-24,366),(cx+2,366),(cx+2,406),(cx-27,406)],fill=(210,176,156,255))
hy=246
d.ellipse([cx-72,hy-86,cx+72,hy+96],fill=(238,206,184,255))
d.polygon([(cx-72,hy+40),(cx-40,hy+104),(cx+40,hy+104),(cx+72,hy+40)],fill=(238,206,184,255))
d.polygon([(cx-52,hy+78),(cx,hy+104),(cx+52,hy+78),(cx+40,hy+96),(cx,hy+112),(cx-40,hy+96)],fill=(226,192,170,255))
for sx in (-1,1):
    d.ellipse([cx+sx*70-10,hy+6,cx+sx*70+10,hy+42],fill=(226,192,170,255))
d.polygon([(cx-74,hy-30),(cx-60,hy-92),(cx,hy-112),(cx+60,hy-92),(cx+74,hy-30),
           (cx+64,hy-56),(cx,hy-72),(cx-64,hy-56)],fill=(36,34,40,255))
d.polygon([(cx-78,hy-24),(cx-64,hy+50),(cx-52,hy+30),(cx-58,hy-30)],fill=(36,34,40,255))
d.polygon([(cx+78,hy-24),(cx+64,hy+50),(cx+52,hy+30),(cx+58,hy-30)],fill=(36,34,40,255))
d.ellipse([cx-30,hy-140,cx+30,hy-88],fill=(42,38,44,255))
d.line([(cx-54,hy-116),(cx+54,hy-108)],fill=(216,186,120,255),width=6)
d.ellipse([cx+50,hy-116,cx+64,hy-102],fill=(232,206,140,255))
d.polygon([(cx-52,hy-6),(cx-16,hy-12),(cx-18,hy-4),(cx-50,hy+2)],fill=(44,40,44,255))
d.polygon([(cx+16,hy-12),(cx+52,hy-6),(cx+50,hy+2),(cx+18,hy-4)],fill=(44,40,44,255))
d.polygon([(cx-44,hy+14),(cx-20,hy+10),(cx-20,hy+26),(cx-44,hy+28)],fill=(250,248,242,255))
d.polygon([(cx+20,hy+10),(cx+44,hy+14),(cx+44,hy+28),(cx+20,hy+26)],fill=(250,248,242,255))
d.ellipse([cx-36,hy+14,cx-24,hy+26],fill=(46,54,66,255))
d.ellipse([cx+24,hy+14,cx+36,hy+26],fill=(46,54,66,255))
d.ellipse([cx-33,hy+16,cx-29,hy+20],fill=(240,246,252,255))
d.ellipse([cx+27,hy+16,cx+31,hy+20],fill=(240,246,252,255))
d.line([(cx-6,hy+26),(cx-2,hy+44)],fill=(210,176,156,255),width=3)
d.line([(cx-14,hy+58),(cx+14,hy+58)],fill=(186,96,92,255),width=4)
warm=Image.new('RGBA',(W,H),(0,0,0,0)); wd=ImageDraw.Draw(warm)
wd.ellipse([cx-360,hy-300,cx+60,hy+220],fill=(255,220,170,34))
im=Image.alpha_composite(im, warm.filter(ImageFilter.GaussianBlur(90)))
rim=Image.new('RGBA',(W,H),(0,0,0,0)); rd=ImageDraw.Draw(rim)
rd.line([(cx+150,420),(cx+186,930)],fill=(150,210,240,90),width=8)
rd.line([(cx+120,300),(cx+150,420)],fill=(150,210,240,70),width=6)
im=Image.alpha_composite(im, rim.filter(ImageFilter.GaussianBlur(10)))
d=ImageDraw.Draw(im)
for i in range(70):
    x=random.randint(20,W-20); y=random.randint(60,H-40)
    r=random.choice([1,1,2]); d.ellipse([x,y,x+r,y+r],fill=(210,226,236,random.randint(20,80)))
im.convert('RGB').save('char_luqingya_768.png')
print('char ok')
