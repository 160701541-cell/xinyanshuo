import importlib.util
import json
import hashlib
from pathlib import Path
import tempfile
import unittest

path=Path(__file__).parent/'private-apk-lab/build_mod_payload.py'
spec=importlib.util.spec_from_file_location('mod_payload',path)
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)


class ModPayloadTests(unittest.TestCase):
    def test_private_precompiled_layout_and_checksums(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);deps=root/'deps';deps.mkdir()
            (deps/'0Harmony.dll').write_bytes(b'dependency fixture')
            (deps/'Assembly-CSharp-Publicized.dll').write_bytes(b'never bundle SDK reference')
            loader=root/'NeoModLoader.dll';loader.write_bytes(b'loader fixture')
            license_file=root/'license.txt';license_file.write_text('fixture license')
            combat=root/'combat';frontiers=root/'frontiers'
            for folder,uid in [(combat,'TURBO_SAKUGA'),(frontiers,'MIDNIGHT_FRONTIERS')]:
                folder.mkdir();(folder/'Code').mkdir();(folder/'Code/ignore.cs').write_text('fixture source')
                (folder/'Locales').mkdir();(folder/'Locales/cz.json').write_text('{}')
                (folder/'mod.json').write_text(json.dumps({'name':'fixture','GUID':uid,'FolderPath':'C:\\old','ModType':0}))
            combat_dll=root/'combat.dll';combat_dll.write_bytes(b'compiled combat fixture')
            (frontiers/'Frontiers.dll').write_bytes(b'compiled frontiers fixture')
            out=root/'payload';module.build(loader,deps,combat,combat_dll,frontiers,license_file,out)
            meta=json.loads((out/'install.json').read_text())
            self.assertFalse(any(p.suffix=='.cs' for p in out.rglob('*')))
            self.assertFalse(any(p.name=='Assembly-CSharp-Publicized.dll' for p in out.rglob('*')))
            for f in meta['files']:
                self.assertTrue(f['target'].startswith(('Mods/','files/mods/')))
                self.assertEqual(hashlib.sha256((out/f['target']).read_bytes()).hexdigest(),f['sha256'])
            for name,uid in [('CombatGods','TURBO_SAKUGA'),('Frontiers','MIDNIGHT_FRONTIERS')]:
                m=json.loads((out/'Mods'/name/'mod.json').read_text())
                self.assertEqual(m['ModType'],1);self.assertNotIn('FolderPath',m)
                self.assertEqual([p.name for p in (out/'Mods'/name).glob('*.dll')],[uid+'.dll'])
            with self.assertRaises(FileExistsError):module.build(loader,deps,combat,combat_dll,frontiers,license_file,out)


if __name__=='__main__':unittest.main()
