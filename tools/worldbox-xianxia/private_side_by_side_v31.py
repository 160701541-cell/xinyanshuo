#!/usr/bin/env python3
"""Create a private, isolated, side-by-side Android test variant for a user-owned
WorldBox mod APK when the old original signing key is unavailable.

Only rewrites the exact installed experiment appId in the three owned Android
entry components (AXML manifest, resource package name, v30 diagnostic DEX),
requiring equal-length package names and consistent Dex SHA1/Adler32 headers.
Does not re-sign, bypass license checks, or modify game logic. Does not
promise compatibility or storage migration. Never publish output in public GitHub.
"""
import argparse, hashlib, json, os, struct, tempfile, zipfile, zlib
from pathlib import Path

OLD = 'com.xinyanshuo.worldbox.lab13'
NEW = 'com.xinyanshuo.worldbox.lab31'
AXML = ('AndroidManifest.xml','resources.arsc')
DEX = 'classes5.dex'
TARGETS = set(AXML+(DEX,))


def dex_checksum(data):
    if not data.startswith(b'dex\n') or len(data)<112:
        raise ValueError('invalid owned diagnostics DEX')
    b=bytearray(data)
    b[12:32]=hashlib.sha1(b[32:]).digest()
    b[8:12]=struct.pack('<I',zlib.adler32(b[12:])&0xffffffff)
    return bytes(b)


def patch_entry(name,data):
    if name in AXML:
        x,y=OLD.encode('utf-16le'),NEW.encode('utf-16le')
        required=11 if name=='AndroidManifest.xml' else 1
    elif name==DEX:
        x,y=OLD.replace('.','/').encode(),NEW.replace('.','/').encode()
        required=11
    else: raise ValueError('unexpected path')
    if len(x)!=len(y) or data.count(x)!=required or data.count(y):
        raise ValueError(name+' unexpected package references; stop, do not corrupt')
    result=data.replace(x,y)
    if name==DEX:result=dex_checksum(result)
    if result.count(y)!=required or result.count(x):
        raise ValueError(name+' package patch unverified')
    return result,required


def stage(input_apk,output_apk):
    src,dst=Path(input_apk),Path(output_apk)
    if src.resolve()==dst.resolve():raise ValueError('input must not be overwritten')
    dst.parent.mkdir(parents=True,exist_ok=True)
    temp=Path(str(dst)+'.partial')
    counts={};removed=0;copied=0
    try:
        with zipfile.ZipFile(src) as zin, zipfile.ZipFile(temp,'w',allowZip64=True) as zout:
            names=zin.namelist()
            if not TARGETS.issubset(names) or len(names)!=len(set(names)):
                raise ValueError('missing patch targets or duplicate original ZIP entries')
            for info in zin.infolist():
                name=info.filename
                if name.startswith('META-INF/') and name.upper().endswith(('.RSA','.DSA','.EC','.SF','MANIFEST.MF')):
                    removed+=1
                    continue
                if name in TARGETS:
                    payload,count=patch_entry(name,zin.read(info))
                    counts[name]=count
                else:
                    payload=zin.read(info)
                    copied+=1
                zout.writestr(info,payload,compress_type=info.compress_type)
        with zipfile.ZipFile(temp) as output:
            if output.testzip() is not None:raise ValueError('CRC failure')
            for name in TARGETS:
                payload=output.read(name)
                if name==DEX:
                    assert hashlib.sha1(payload[32:]).digest()==payload[12:32]
                    assert zlib.adler32(payload[12:])&0xffffffff==struct.unpack_from('<I',payload,8)[0]
            assert counts=={'AndroidManifest.xml':11,'resources.arsc':1,'classes5.dex':11}
        os.replace(temp,dst)
    finally:
        if temp.exists():temp.unlink()
    return {'status':'UNSIGNED_SIDE_BY_SIDE_ANDROID_QA_ONLY',
            'original_package':OLD,'new_package':NEW,
            'patched_components':counts,'unchanged_archive_members':copied,
            'original_apk_preserved':True,'new_app_has_separate_saves':True,
            'signed':False,'installed_on_device':False,
            'license_and_runtime_compatibility':'NOT_VERIFIED'}

if __name__=='__main__':
    p=argparse.ArgumentParser()
    p.add_argument('--apk',required=True,type=Path)
    p.add_argument('--out',required=True,type=Path)
    a=p.parse_args()
    print(json.dumps(stage(a.apk,a.out),ensure_ascii=False,indent=2))
