import sys
from PIL import Image
import numpy as np
path=sys.argv[1]; W=int(sys.argv[2]) if len(sys.argv)>2 else 60
crop=tuple(int(v) for v in sys.argv[3:7]) if len(sys.argv)>6 else None
im=Image.open(path).convert('RGB')
a=np.asarray(im).astype(int)
if crop: a=a[crop[1]:crop[3], crop[0]:crop[2]]
h,w,_=a.shape
c=np.concatenate([a[:5,:5].reshape(-1,3),a[:5,-5:].reshape(-1,3),a[-5:,:5].reshape(-1,3),a[-5:,-5:].reshape(-1,3)])
bg=np.median(c,axis=0)
R,G,B=a[:,:,0],a[:,:,1],a[:,:,2]
mx=a.max(axis=2); mn=a.min(axis=2); sat=mx-mn; lum=a.mean(axis=2)
isbg=(np.abs(a-bg).sum(axis=2)<26)
out=np.full((h,w),' ',dtype='<U1')
out[~isbg]='?'
# 分类
skin=(~isbg)&(R>110)&(R>B+28)&(G>70)&(sat>18)
white=(~isbg)&(lum>168)&(sat<45)
gold=(~isbg)&(R>110)&(G>80)&(B<110)&(R>B+45)&(G>B+18)
hair=(~isbg)&(lum<62)&(sat<52)
teal=(~isbg)&(G>B-40)&(B>R+10)&(G>60)
red=(~isbg)&(R>90)&(R>G+40)&(R>B+30)
ink=(~isbg)&(lum<28)
for m,ch in [(white,'W'),(gold,'G'),(red,'X'),(skin,'s'),(teal,'r'),(hair,'h'),(ink,'#')]:
    out[m]=ch
rows=max(8,int(W*h/w*0.5))
iy=np.linspace(0,h-1,rows).astype(int); ix=np.linspace(0,w-1,W).astype(int)
for r in iy:
    print(''.join(out[r,j] for j in ix).rstrip())
