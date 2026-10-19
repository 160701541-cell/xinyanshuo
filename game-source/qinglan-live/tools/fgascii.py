import sys
from PIL import Image
import numpy as np
path=sys.argv[1]; W=int(sys.argv[2]) if len(sys.argv)>2 else 60
x0,y0,x1,y1=(int(v) for v in sys.argv[3:7]) if len(sys.argv)>6 else (None,)*4
im=Image.open(path).convert('RGB')
a=np.asarray(im).astype(int)
if x0 is not None: a=a[y0:y1, x0:x1]
h,w,_=a.shape
# 背景：四角中位数
corners=np.concatenate([a[:6,:6].reshape(-1,3),a[:6,-6:].reshape(-1,3),a[-6:,:6].reshape(-1,3),a[-6:,-6:].reshape(-1,3)])
bg=np.median(corners,axis=0)
d=np.abs(a-bg).sum(axis=2)
fg=d>26
lum=a.mean(axis=2)
ramp=" .:-=+*#%@"
rows=max(6,int(W*h/w*0.52))
iy=(np.linspace(0,h-1,rows)).astype(int)
ix=(np.linspace(0,w-1,W)).astype(int)
out=[]
for r in iy:
    line=""
    for c in ix:
        if not fg[r,c]: line+=" "
        else:
            v=lum[r,c]
            line+=ramp[min(9,int(v/256*10))]
    out.append(line)
print("\n".join(out))
