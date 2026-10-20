#!/usr/bin/env python3
"""Private, hash-audited reuse of approved original art. Does not edit Canglan.

Eight independent building icons are used by the in-game catalog. Four existing
spirit-grass frames are used by the cultivation panel. Neither is claimed to be
a replacement of the native world renderer or finished animated architecture.
"""
import argparse
import hashlib
import json
from pathlib import Path
import zipfile


def stage(payload, approved_zip, prototype_pack):
    manifest=payload/'install.json'
    meta=json.loads(manifest.read_text())
    prefix='files/mods/WorldBoxXianxia/'
    if any(f['target'].startswith(prefix) for f in meta['files']):
        raise ValueError('Owned assets already staged')
    additions=[]
    def put(relative,data,source):
        target=prefix+relative;path=payload/target
        path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
        additions.append({'target':target,'size':len(data),'sha256':hashlib.sha256(data).hexdigest()})
    catalog=[]
    with zipfile.ZipFile(approved_zip) as z:
        if z.testzip() is not None:raise ValueError('Original approved archive CRC failure')
        for row in json.loads(z.read('manifest.json')):
            data=z.read(row['icon'])
            put(row['icon'],data,'approved original independent PNG')
            catalog.append({'id':row['id'],'name':row['name_zh'],'use':'catalog_only',
                            'source':'Canglan_Approved_Assets_Batch02.zip',
                            'native_building_replacement':False,'missing_animation_states':True})
    provenance=json.loads((prototype_pack/'asset_manifest.json').read_text())
    seq=next(s for s in provenance['sequences'] if s['key']=='vegetation/spirit_grass/mature')
    for frame in seq['frames']:
        p=prototype_pack/frame['path'];data=p.read_bytes()
        if hashlib.sha256(data).hexdigest()!=frame['sha256']:raise ValueError('Prototype frame hash mismatch')
        relative=frame['path'].removeprefix('GameResources/xianxia/')
        put(relative,data,'original v0.4 prototype spirit grass')
    put('catalog.json',(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n').encode(),'original provenance')
    meta['files']=sorted(meta['files']+additions,key=lambda f:f['target'])
    meta['build_token']='v18-'+hashlib.sha256(json.dumps(meta['files'],sort_keys=True).encode()).hexdigest()[:16]
    meta['original_module']='WorldBox cultivation v18: root/training/qi13/gather/alchemy/catalog; device pending'
    manifest.write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n')
    print('PRIVATE_OWNED_ART_STAGED',len(additions),'files;',len(catalog),'catalog entries; no native-building replacement claim')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    for n in ('payload','approved-zip','prototype-pack'):p.add_argument('--'+n,type=Path,required=True)
    a=p.parse_args();stage(a.payload,a.approved_zip,a.prototype_pack)
