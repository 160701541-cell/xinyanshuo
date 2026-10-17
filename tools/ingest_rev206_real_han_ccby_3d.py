#!/usr/bin/env python3
"""Only original ancient Chinese Han CC-BY-SA art from Wildfire Games' 0 A.D.

Fetch GitHub mirrored 0 A.D. pre-existing GLB models. A Git BLOB SHA-1 is
pinned for every source. This is not authoring/procedural generation.
The 0 A.D. art work (and our material derivatives) stays CC BY-SA 3.0;
do NOT conflate the source-code GPLv2 with the art licence.
"""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
import struct
from urllib.request import Request,urlopen

ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'game-source/apk176-ota177-candidate/assets/cc-by-sa-han-rev206'
ORIGINAL="https://raw.githubusercontent.com/PhantomMatthew/ZeroAD-Godot/main/"

def fetch_model(rec: dict) -> dict:
    target=ROOT/rec['local_path']
    target.resolve().relative_to(BASE.resolve())
    assert rec['source_path'].startswith('godot/assets/meshes/structural/han_')
    assert rec['source_path'].endswith('/'+rec['name']+'.glb')
    assert len(rec['git_sha1'])==40
    url=ORIGINAL+rec['source_path']
    with urlopen(Request(url,headers={'User-Agent':'Canglan-Xianxia-Han-CCBYSA-Verified/206'}),timeout=75) as q:
        data=q.read(4_000_001)
    if not 2000<len(data)<4_000_000:
        raise RuntimeError('Blocked source oversized/undersized GLB '+rec['name'])
    actual=hashlib.sha1(('blob %d\0'%len(data)).encode()+data).hexdigest()
    if actual!=rec['git_sha1']:
        raise RuntimeError('Original source blob changed, refuse import '+rec['name'])
    if data[:4]!=b'glTF' or struct.unpack_from('<I',data,4)[0]!=2 or (
        struct.unpack_from('<I',data,8)[0]!=len(data)):
        raise RuntimeError('Blocked malformed GLB2 '+rec['name'])
    chunk_len,chunk_type=struct.unpack_from('<II',data,12)
    if chunk_type!=0x4e4f534a or not 2<chunk_len<len(data)-20:
        raise RuntimeError('Blocked missing mesh metadata '+rec['name'])
    gltf=json.loads(data[20:20+chunk_len].decode('utf8'))
    if not gltf.get('meshes') or not gltf.get('nodes'):
        raise RuntimeError('Blocked empty geometries '+rec['name'])
    if len(gltf['meshes'])>400 or len(gltf['nodes'])>4000:
        raise RuntimeError('Blocked oversized mesh graph '+rec['name'])
    for buffer in gltf.get('buffers',[]):
        if buffer.get('uri'):
            raise RuntimeError('Blocked external texture/network file in '+rec['name'])
    target.parent.mkdir(parents=True,exist_ok=True)
    target.write_bytes(data)
    return {'name':rec['name'],'category':rec['category'],
            'git_sha1':actual,'sha256':hashlib.sha256(data).hexdigest(),
            'size':len(data),'meshes':len(gltf['meshes']),
            'materials':len(gltf.get('materials',[])),
            'embedded_images':len(gltf.get('images',[])),
            'source_path':rec['source_path'],'path':rec['local_path'],
            'license':'CC-BY-SA-3.0'}

def main():
    guide=json.loads((BASE/'upstream_manifest.json').read_text(encoding='utf8'))
    assert guide['license']=='CC-BY-SA-3.0' and guide['schema']==206
    assert len(guide['models'])==9
    rows=[fetch_model(rec) for rec in guide['models']]
    assert len([x for x in rows if x['category']=='home'])==4
    assert sum(x['size'] for x in rows)<3_000_000
    report={'schema':206,'license':'CC-BY-SA-3.0','source_repo':guide['source_repo'],
        'upstream_credit':'0 A.D. by Wildfire Games and contributing artists',
        'upstream_license':'https://creativecommons.org/licenses/by-sa/3.0/',
        'source_url':ORIGINAL,'total_bytes':sum(x['size'] for x in rows),
        'models':rows}
    (BASE/'verified_real_han_art.json').write_text(json.dumps(report,
        ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    print('PASS_REV206_REAL_NINE_OPEN_LICENSED_HAN_CHINESE_HOMES_SECT_MODELS_SOURCE_VERIFIED',
          len(rows),report['total_bytes'])

if __name__=='__main__':
    main()
