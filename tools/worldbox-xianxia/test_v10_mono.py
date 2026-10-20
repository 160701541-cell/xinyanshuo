import io,json, tempfile,unittest,zipfile
from pathlib import Path
from package_android_mono_source import create,ROOT,UID

class MonoCandidateTests(unittest.TestCase):
    def test_source_only_install_layout_and_no_external_binary(self):
        with tempfile.TemporaryDirectory() as td:
            td=Path(td)
            src=td/"observer.cs"
            src.write_text("public class A : BasicMod<A>{void OnModLoad(){} void T(){World.world.GetTile(1,2);}}",encoding="utf8")
            original=td/"mod.json"
            original.write_text(json.dumps({"name":"a","author":"b","version":"v","description":"d","GUID":UID,"ModType":1,"targetGameBuild":725}),encoding="utf8")
            output=td/"build.zip"
            result=create(src,original,output)
            self.assertEqual(result["status"],"DEVICE_PENDING")
            with zipfile.ZipFile(output) as z:
                self.assertEqual(z.testzip(),None)
                files=z.namelist()
                self.assertEqual(len(files),4)
                self.assertIn(ROOT+"/Code/XianxiaObserverV07.cs",files)
                self.assertIn(ROOT+"/mod.json",files)
                self.assertNotIn("NMLMods/WorldBoxXianxiaObserver/mod.json",files)
                self.assertFalse(any(x.endswith((".apk",".dll",".pck")) for x in files))
                meta=json.loads(z.read(ROOT+"/mod.json"))
                self.assertEqual(meta["ModType"],0)
                self.assertEqual(meta["targetGameBuild"],725)
                self.assertEqual(meta["GUID"],UID)
                self.assertIn("DEVICE_PENDING",z.read("README_传统Mono安装前必读.txt").decode("utf8"))
                self.assertEqual(json.loads(original.read_text())["ModType"],1)
    def test_wrong_GUID_fails(self):
        with tempfile.TemporaryDirectory() as td:
            td=Path(td)
            src=td/"a.cs";src.write_text("BasicMod<X> OnModLoad() World.world.GetTile",encoding="utf8")
            meta=td/"mod.json";meta.write_text(json.dumps({"GUID":"bad"}),encoding="utf8")
            with self.assertRaises(ValueError):create(src,meta,td/"out.zip")

if __name__=="__main__":unittest.main(verbosity=2)
