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
