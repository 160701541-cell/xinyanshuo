import sys
from PIL import Image
import numpy as np
p=sys.argv[1]; W=int(sys.argv[2]) if len(sys.argv)>2 else 60
im=Image.open(p).convert('RGB')
w,h=im.size
H=max(1,int(W*(h/w)*0.5))
a=np.asarray(im.resize((W,H))).astype(float)
lum=a.mean(axis=2)
ramp=" .:-=+*#%@"
lo,hi=lum.min(),lum.max()
if hi-lo<1: hi=lo+1
print(p,im.size)
for row in lum:
    print("".join(ramp[min(9,int((v-lo)/(hi-lo)*9.999))] for v in row))
