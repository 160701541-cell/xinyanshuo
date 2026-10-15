#!/usr/bin/env python3
"""Strict audit for ZIPs of candidate-only HD2D PNGs; never approves art.

Run: python cac_zip_qa.py --out audit.json bundle1.zip bundle2.zip
Nonzero exit when any candidate is not game-production-ready.
"""
import argparse
import hashlib
import io
import json
from pathlib import Path
import re
import zipfile
from PIL import Image, UnidentifiedImageError

ASSET_RE = re.compile(r'^[A-Za-z0-9._-]{1,100}$')

def sha(data):
    return hashlib.sha256(data).hexdigest()

def audit_zip(path, minimum=512):
    result={'zip':Path(path).name,'zip_sha256':sha(Path(path).read_bytes()),'passed':False,
            'source_png_in_archive':False,'entries':[],'errors':[]}
    with zipfile.ZipFile(path) as z:
        names=z.namelist()
        if len(names)!=len(set(names)):
            result['errors'].append('DUPLICATE_ARCHIVE_NAMES')
        if any(n.startswith('/') or '..' in Path(n).parts or '\\' in n for n in names):
            result['errors'].append('PATH_TRAVERSAL_ARCHIVE')
        m=json.loads(z.read('candidate_manifest.json'))
        assets=m.get('assets',[])
        if m.get('num_candidates')!=len(assets) or not assets:
            result['errors'].append('MANIFEST_COUNT_OR_EMPTY')
        if m.get('approved')!=0 or m.get('type')!='CANDIDATE_ONLY':
            result['errors'].append('FALSE_APPROVAL')
        ids=[]
        for a in assets:
            aid=a.get('id')
            issues=[]
            if not isinstance(aid,str) or not ASSET_RE.fullmatch(aid):
                issues.append('BAD_ID')
            ids.append(aid)
            if a.get('status')!='UNAPPROVED' or a.get('visual_qa')!='NOT_REVIEWED':
                issues.append('MISSING_CANDIDATE_QUARANTINE')
            name=a.get('file','')
            if not isinstance(name,str) or name not in names or '..' in Path(name).parts:
                issues.append('MISSING_OR_UNSAFE_IMAGE')
            else:
                data=z.read(name)
                if sha(data)!=a.get('sha256'):
                    issues.append('SHA256_MISMATCH')
                try:
                    with Image.open(io.BytesIO(data)) as im:
                        im.load()
                        fmt, mode, size=im.format,im.mode,im.size
                        rgba=im.convert('RGBA')
                    alpha=rgba.getchannel('A')
                    p=alpha.load();w,h=rgba.size
                    edge=sum(p[x,0]>0 or p[x,h-1]>0 for x in range(w)) + sum(p[0,y]>0 or p[w-1,y]>0 for y in range(h))
                    if fmt!='PNG':issues.append('NOT_PNG')
                    if mode!='RGBA':issues.append('NOT_NATIVE_RGBA')
                    if min(size)<minimum:issues.append('BELOW_NATIVE_RESOLUTION_MIN')
                    if alpha.getextrema()[0]==255:issues.append('NO_TRANSPARENCY')
                    if edge:issues.append('VISIBLE_ALPHA_TOUCHES_CANVAS_EDGE')
                except (UnidentifiedImageError,OSError,ValueError):
                    issues.append('UNDECODABLE_IMAGE')
                    size=[0,0];mode='?';edge=-1
                result['entries'].append({'id':aid,'file':name,'dimensions':size,'mode':mode,
                                          'edge_visible_pixel_positions':edge,'issues':issues})
            if issues and not (result['entries'] and result['entries'][-1].get('id')==aid):
                result['entries'].append({'id':aid,'issues':issues})
        if len(ids)!=len(set(ids)):
            result['errors'].append('DUPLICATE_ASSET_IDS')
    result['passed']=not result['errors'] and all(not x['issues'] for x in result['entries'])
    result['approved_count']=0
    return result

def main():
    p=argparse.ArgumentParser()
    p.add_argument('zips',nargs='+')
    p.add_argument('--out',required=True)
    p.add_argument('--minimum',type=int,default=512)
    a=p.parse_args()
    results=[audit_zip(path,a.minimum) for path in a.zips]
    assets=[x for b in results for x in b['entries']]
    report={'schema':1,'status':'FAIL' if not all(x['passed'] for x in results) else 'CANDIDATE_TECH_PASS_ONLY',
            'archives':len(results),'candidates':len(assets),'game_approved':0,
            'below_native_resolution':sum('BELOW_NATIVE_RESOLUTION_MIN' in x['issues'] for x in assets),
            'edge_touch':sum('VISIBLE_ALPHA_TOUCHES_CANVAS_EDGE' in x['issues'] for x in assets),
            'native_rgba_fail':sum('NOT_NATIVE_RGBA' in x['issues'] for x in assets),
            'hash_mismatch':sum('SHA256_MISMATCH' in x['issues'] for x in assets),
            'batches':results}
    Path(a.out).write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(f"{report['status']}: {report['candidates']} candidates, {report['below_native_resolution']} low-res, {report['edge_touch']} edge-touched, 0 approved")
    raise SystemExit(0 if all(x['passed'] for x in results) else 1)

if __name__=='__main__':main()