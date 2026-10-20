#!/usr/bin/env python3
"""Add original diagnostic launcher and independent identity to a PRIVATE candidate.

Unsigned output still requires zipalign and dedicated test signing. User performs
Android QA; this tool does not claim launch success or publish commercial bytes.
"""
import argparse
import copy
from pathlib import Path
import zipfile
from clone_binary_manifest import patch
from clone_resource_table import patch_resource_table


def make(source, dex, out, payload=None):
    if out.resolve() in (source.resolve(),dex.resolve()) or out.exists():
        raise ValueError('Fresh output required')
    if dex.read_bytes()[:4] != b'dex\n':raise ValueError('Expected compiled Android DEX')
    with zipfile.ZipFile(source) as original:
        if 'classes5.dex' in original.namelist():raise ValueError('DEX slot occupied')
        manifest=patch(original.read('AndroidManifest.xml'))
        resources=patch_resource_table(original.read('resources.arsc'))
        with zipfile.ZipFile(out,'w') as target:
            for info in original.infolist():
                data=manifest if info.filename=='AndroidManifest.xml' else resources if info.filename=='resources.arsc' else original.read(info.filename)
                target.writestr(copy.copy(info),data)
            target.writestr('classes5.dex',dex.read_bytes(),compress_type=zipfile.ZIP_DEFLATED)
            if payload is not None:
                if not (payload/'install.json').is_file():raise ValueError('Missing deployment manifest')
                for file in sorted(payload.rglob('*')):
                    if file.is_file():
                        target.write(file,'assets/worldbox-xianxia/v17/'+file.relative_to(payload).as_posix(),compress_type=zipfile.ZIP_DEFLATED)
        with zipfile.ZipFile(out) as check:
            if check.testzip() is not None:raise ValueError('CRC check failed')
            for name in original.namelist():
                if name not in ('AndroidManifest.xml','resources.arsc') and check.read(name)!=original.read(name):
                    raise ValueError('Unexpected candidate change '+name)
    print('USER_DEVICE_TEST_UNSIGNED_READY; separate app identity, no access to old saves')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    for name in ('source','dex','out'):parser.add_argument('--'+name,type=Path,required=True)
    parser.add_argument('--payload',type=Path)
    args=parser.parse_args();make(args.source,args.dex,args.out,args.payload)
