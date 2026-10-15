#!/usr/bin/env python3
"""Lossless candidate normalization; does not invent pixels or approve sprites."""
import argparse, hashlib, io, json, zipfile
from pathlib import Path
from PIL import Image

def run(source, dest):
    src=Path(source); out=Path(dest); out.parent.mkdir(parents=True,exist_ok=True)
    results=[]
    with zipfile.ZipFile(src) as zin, zipfile.ZipFile(out,'w',compression=zipfile.ZIP_DEFLATED) as zout:
        for name in zin.namelist():
            if not name.endswith('.png'): continue
            if name.startswith('/') or '..' in Path(name).parts or '\\' in name: raise ValueError('unsafe archive path')
            original=zin.read(name)
            with Image.open(io.BytesIO(original)) as im:
                im.load(); rgba=im.convert('RGBA'); bbox=rgba.getchannel('A').getbbox()
                if not bbox: raise ValueError('empty sprite: '+name)
                w,h=rgba.size
                margin=max(12,round(max(w,h)*.08))
                padded=Image.new('RGBA',(w+2*margin,h+2*margin),(0,0,0,0))
                padded.alpha_composite(rgba,(margin,margin))
                buff=io.BytesIO(); padded.save(buff,format='PNG'); payload=buff.getvalue()
                zout.writestr(name,payload)
                results.append({'file':name,'source_sha256':hashlib.sha256(original).hexdigest(),
                   'output_sha256':hashlib.sha256(payload).hexdigest(),'source_size':[w,h],
                   'output_size':list(padded.size),'source_mode':im.mode,
                   'native_detail_improved':False,'edge_truncation_repaired':False,
                   'approved':False,'source_edge_contact':bool(bbox[0]==0 or bbox[1]==0 or bbox[2]==w or bbox[3]==h)})
        manifest={'stage':'NORMALIZED_CANDIDATE_ONLY','approved_count':0,'count':len(results),
                  'source_zip_sha256':hashlib.sha256(src.read_bytes()).hexdigest(), 'assets':results}
        zout.writestr('normalization_manifest.json',json.dumps(manifest,indent=2)+'\n')
    return manifest

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--out',required=True)
    a=p.parse_args(); r=run(a.input,a.out)
    print(f"normalized {r['count']} real candidates; 0 art approved; source clipping remains unresolved")
