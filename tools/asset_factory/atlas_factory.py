#!/usr/bin/env python3
"""Batch atlas slicer: candidate-only sprites/icons, traceable and fail-closed."""
import argparse, hashlib, json, math, zipfile
from collections import deque
from pathlib import Path
from PIL import Image, ImageOps, ImageFilter

# Normalized crop zones per cell; configurable in atlas_layout.json.
def crop_norm(im, box):
    w,h=im.size
    return im.crop(tuple(round(v*d) for v,d in zip(box,(w,h,w,h))))

def background_mask(im, threshold=38):
    """Remove only near-black connected-to-edge background; no guarantee for patterned cells."""
    im=im.convert('RGBA'); w,h=im.size
    rgb=im.convert('RGB'); pix=rgb.load(); alpha=im.getchannel('A')
    ap=alpha.load(); visited=bytearray(w*h); q=deque()
    # Seed all edges; avoid treating bright objects touching border as background.
    for x in range(w):
        for y in (0,h-1):
            if max(pix[x,y]) < threshold: q.append((x,y))
    for y in range(h):
        for x in (0,w-1):
            if max(pix[x,y]) < threshold: q.append((x,y))
    while q:
        x,y=q.popleft(); i=y*w+x
        if visited[i]: continue
        visited[i]=1
        if max(pix[x,y]) >= threshold: continue
        ap[x,y]=0
        for nx,ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
            if 0<=nx<w and 0<=ny<h and not visited[ny*w+nx]: q.append((nx,ny))
    im.putalpha(alpha)
    return im

def icon(im, size=512):
    bbox=im.getchannel('A').getbbox()
    if not bbox: return Image.new('RGBA',(size,size))
    obj=im.crop(bbox)
    obj.thumbnail((int(size*.86),int(size*.86)),Image.Resampling.LANCZOS)
    canvas=Image.new('RGBA',(size,size))
    canvas.alpha_composite(obj,((size-obj.width)//2,(size-obj.height)//2))
    return canvas

def main():
    p=argparse.ArgumentParser();p.add_argument('--image',required=True);p.add_argument('--layout',required=True);p.add_argument('--out',required=True);p.add_argument('--dark-cutout',action='store_true');a=p.parse_args()
    source=Path(a.image);out=Path(a.out);out.mkdir(parents=True,exist_ok=True)
    im=Image.open(source).convert('RGBA'); layout=json.loads(Path(a.layout).read_text(encoding='utf-8'))
    records=[];sha=hashlib.sha256(source.read_bytes()).hexdigest()
    for slot in layout['slots']:
        cell=crop_norm(im,slot['box']); candidate=crop_norm(cell,slot.get('sprite_region',[.04,.14,.96,.78]))
        if a.dark_cutout: candidate=background_mask(candidate)
        target=out/'candidates'/slot['id'];target.mkdir(parents=True,exist_ok=True)
        spr=target/'scene_candidate.png';ic=target/'icon_candidate.png'
        candidate.save(spr);icon(candidate).save(ic)
        records.append({'id':slot['id'],'name':slot['name'],'source_sha256':sha,'source_box':slot['box'],
            'scene':str(spr.relative_to(out)),'icon':str(ic.relative_to(out)),
            'sprite_size':candidate.size,'review':'UNAPPROVED','warnings':[
                'Candidate is cropped from composite; may include background, neighbors, text or truncation',
                'Icon is resized from same crop, not independently illustrated',
                'Do not import to production without manual inspection and clean transparency']})
    (out/'candidate_manifest.json').write_text(json.dumps({'source':str(source),'source_sha256':sha,'count':len(records),'approved_count':0,'assets':records},ensure_ascii=False,indent=2),encoding='utf-8')
    print(f'Created {len(records)} candidate sprites and icons; 0 approved. Output: {out}')

if __name__=='__main__':main()
