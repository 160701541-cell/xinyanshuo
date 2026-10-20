"""Offline synthetic regression; never upload the actual commercial APK to CI."""
import hashlib, io, json, tempfile, unittest, zipfile
from pathlib import Path
from private_stage_mono_v28 import stage,ROOT,MANIFEST,MOD

def synthetic(directory):
    root=Path(directory)
    base=root/"test-base.apk"
    payload=root/"test-mod.zip"
    m=io.BytesIO()
    with zipfile.ZipFile(m,"w") as z:
        z.writestr("Assembly-CSharp.dll",b"FAKE CS")
        z.writestr("WorldBoxXianxiaMonoBridge.dll",b"FAKE BOOT")
    old=b"FAKE RESOURCE"
    install={"build_token":"v18-old","mods":["old"],"files":[
        {"target":"Mods/Old/file.json","size":len(old),
         "sha256":hashlib.sha256(old).hexdigest()}]}
    with zipfile.ZipFile(base,"w") as z:
        z.writestr("assets/Mono/Managed.zip",m.getvalue())
        z.writestr("classes5.dex",b"fake dex")
        z.writestr(ROOT+"Mods/Old/file.json",old)
        z.writestr(MANIFEST,json.dumps(install))
        z.writestr("META-INF/WORLDBOX.RSA",b"FAKE SIG")
    modjson=json.dumps({"GUID":"XINYANSHUO_WORLD_BOX_OBSERVER_V07",
                        "ModType":0,"version":"0.27.0-chinese-device-pending"})
    with zipfile.ZipFile(payload,"w") as z:
        z.writestr(MOD+"mod.json",modjson)
        z.writestr(MOD+"Code/XianxiaObserverV07.cs","// synthetic")
        z.writestr(MOD+"Locales/cz.json",'{"hello":"你好"}')
    return base,payload

class StageTests(unittest.TestCase):
    def test_real_manifest_and_signed_state_never_faked(self):
        with tempfile.TemporaryDirectory() as td:
            base,mod=synthetic(td)
            dest=Path(td)/"output.apk"
            audit=stage(base,mod,dest)
            self.assertFalse(audit["worldbox_device_loaded"])
            self.assertTrue(audit["signing_required"])
            self.assertEqual(audit["source_files_added"],3)
            with zipfile.ZipFile(dest) as z:
                self.assertIsNone(z.testzip())
                self.assertNotIn("META-INF/WORLDBOX.RSA",z.namelist())
                self.assertIn(ROOT+MOD+"mod.json",z.namelist())
                self.assertEqual(len(json.loads(z.read(MANIFEST))["files"]),4)
    def test_upgrade_requires_explicit_replacement_and_preserves_foreign_bytes(self):
        with tempfile.TemporaryDirectory() as td:
            base,mod=synthetic(td)
            first=Path(td)/"first.apk"
            stage(base,mod,first)
            before=hashlib.sha256(first.read_bytes()).hexdigest()
            with zipfile.ZipFile(mod) as z:
                new_files={name:z.read(name) for name in z.namelist()
                           if not name.endswith("Locales/cz.json")}
            new_files[MOD+"Code/XianxiaObserverV07.cs"]=b"// fixed observer"
            with zipfile.ZipFile(mod,"w") as z:
                for name,data in new_files.items():z.writestr(name,data)
            dest=Path(td)/"repaired.apk"
            with self.assertRaises(ValueError):stage(first,mod,dest)
            self.assertFalse(dest.exists())
            audit=stage(first,mod,dest,replace_own_module=True)
            self.assertEqual(audit["own_module_files_replaced"],3)
            self.assertEqual(before,hashlib.sha256(first.read_bytes()).hexdigest())
            with zipfile.ZipFile(first) as a,zipfile.ZipFile(dest) as b:
                for name in ("assets/Mono/Managed.zip","classes5.dex",ROOT+"Mods/Old/file.json"):
                    self.assertEqual(a.read(name),b.read(name))
                self.assertEqual(b.read(ROOT+MOD+"Code/XianxiaObserverV07.cs"),b"// fixed observer")
                self.assertNotIn(ROOT+MOD+"Locales/cz.json",b.namelist())
                self.assertEqual(len(b.namelist()),len(set(b.namelist())))
                old_meta=json.loads(a.read(MANIFEST))
                meta=json.loads(b.read(MANIFEST))
                self.assertNotEqual(old_meta["build_token"],meta["build_token"])
                self.assertFalse(audit["worldbox_device_loaded"])

    def test_same_size_corrupted_base_asset_refused_before_output(self):
        with tempfile.TemporaryDirectory() as td:
            base,mod=synthetic(td)
            with zipfile.ZipFile(base) as z:
                entries={name:z.read(name) for name in z.namelist()}
            name=ROOT+"Mods/Old/file.json"
            entries[name]=b"X"*len(entries[name])
            with zipfile.ZipFile(base,"w") as z:
                for name,data in entries.items():z.writestr(name,data)
            dest=Path(td)/"output.apk"
            with self.assertRaisesRegex(ValueError,"checksum mismatch"):stage(base,mod,dest)
            self.assertFalse(dest.exists())

    def test_refuse_apk_without_existing_loader(self):
        with tempfile.TemporaryDirectory() as td:
            base,mod=synthetic(td)
            with zipfile.ZipFile(base,"w") as z:
                z.writestr("AndroidManifest.xml",b"not patched")
            with self.assertRaises(ValueError):stage(base,mod,Path(td)/"output.apk")
    def test_refuse_module_zip_slip(self):
        with tempfile.TemporaryDirectory() as td:
            base,mod=synthetic(td)
            with zipfile.ZipFile(mod,"a") as z:
                z.writestr(MOD+"../../outside.cs","attack")
            with self.assertRaises(ValueError):stage(base,mod,Path(td)/"output.apk")

if __name__=="__main__":unittest.main()
