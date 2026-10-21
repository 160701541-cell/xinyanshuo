#!/usr/bin/env python3
"""Map iconset export: source of truth is atlas.mjs's built-in SVG symbols.
Pure standard library, deterministic, self-authored vector assets. No AI/external art required.
"""
from pathlib import Path
import json,re,hashlib
root=Path(__file__).resolve().parents[1]
source=(root/'atlas.mjs').read_text(encoding='utf-8')
dest=root/'assets'/'map-icons'
dest.mkdir(parents=True,exist_ok=True)
results=[]
for name,body in re.findall(r'<symbol id="ico-([a-z]+)" viewBox="0 0 48 48">(.*?)</symbol>',source,re.DOTALL):
    contents=f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" role="img" aria-label="{name}">{body}</svg>\n'
    file=dest/(name+'.svg')
    file.write_text(contents,encoding='utf-8')
    results.append({'id':name,'path':'assets/map-icons/'+file.name,'sha256':hashlib.sha256(contents.encode('utf8')).hexdigest()})
(dest/'manifest.json').write_text(json.dumps({'schema':1,'origin':'self-authored SVG vectors in atlas.mjs','license':'Original project artwork','count':len(results),'icons':results},ensure_ascii=False,indent=2)+'\n',encoding='utf8')
print('Generated',len(results),'deterministic map icon assets')
