#!/usr/bin/env python3
"""Package private user-provided compatible modules; never publish their bytes.

This writes a reproducible checksummed Android asset tree, not a playable claim.
Only this script is original/public; inputs and resulting asset files stay private.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil


def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()


def build(loader,dependencies,combat,combat_dll,frontiers,license_file,out):
    if out.exists():raise FileExistsError('Use a fresh private asset staging directory')
    out.mkdir(parents=True)
    def copy(source,target):
        dest=out/target;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(source,dest)
    copy(loader,'files/mods/NeoModLoader.dll')
    for p in sorted(dependencies.glob('*.dll')):
        if p.name=='Assembly-CSharp-Publicized.dll':continue
        copy(p,'files/mods/NML/Assemblies/'+p.name)
    copy(license_file,'files/mods/NML/LICENCES/NeoModLoader_MIT.txt')
    selected=[(combat,combat_dll,'CombatGods','TURBO_SAKUGA'),
              (frontiers,frontiers/'Frontiers.dll','Frontiers','MIDNIGHT_FRONTIERS')]
    for folder,dll,name,uid in selected:
        meta=json.loads((folder/'mod.json').read_text(encoding='utf-8-sig'))
        if meta.get('GUID')!=uid:raise ValueError('Wrong mod input '+name)
        for p in sorted(folder.rglob('*')):
            if not p.is_file():continue
            relative=p.relative_to(folder)
            if relative.parts[0] in ('Code','bin','obj','.git') or p.suffix.lower() in ('.dll','.pdb','.cs') or p.name=='mod.json':continue
            copy(p,'Mods/'+name+'/'+relative.as_posix())
        copy(dll,'Mods/'+name+'/'+uid+'.dll')
        meta.pop('FolderPath',None);meta.pop('FailReason',None)
        meta.update(ModType=1,targetGameBuild=725,IsWorkshopLoaded=False)
        target=out/'Mods'/name/'mod.json'
        target.write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    files=[]
    for p in sorted(out.rglob('*')):
        if not p.is_file():continue
        rel=p.relative_to(out).as_posix()
        if not (rel.startswith('files/mods/') or rel.startswith('Mods/')):raise ValueError('Unexpected deployment target')
        files.append({'target':rel,'size':p.stat().st_size,'sha256':digest(p)})
    token='v18-'+hashlib.sha256(json.dumps(files,sort_keys=True).encode()).hexdigest()[:16]
    manifest={'build_token':token,'loader':'Legacy Mono NeoModLoader 1.2.1.1',
              'mods':['Combat Gods 1.0.5','Frontiers 2.0.1'],
              'device_test':'USER_PENDING','files':files}
    (out/'install.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    print('PRIVATE_MOD_PAYLOAD_READY',token,'files',len(files),'bytes',sum(f['size'] for f in files))


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    for name in ('loader','dependencies','combat','combat-dll','frontiers','license-file','out'):
        parser.add_argument('--'+name,type=Path,required=True)
    a=parser.parse_args();build(a.loader,a.dependencies,a.combat,a.combat_dll,a.frontiers,a.license_file,a.out)
