import io,json,struct,tempfile,unittest,zipfile
from pathlib import Path
from package_android_compiled_mod import pack,validate_metadata,ROOT,UID

def simulated_pe():
    # Synthetic PE shape: only used to exercise package layout, never an actual DLL.
    buf=bytearray(4096)
    buf[0:2]=b"MZ"
    struct.pack_into("<I",buf,0x3c,0x80)
    buf[0x80:0x84]=b"PE\x00\x00"
    return bytes(buf)

def good_manifest():
    return {"name":"WorldBox v10","GUID":UID,"author":"source lab","version":"0.10.0",
            "description":"third party NML read-only mod candidate",
            "ModType":1,"targetGameBuild":725}

class PackagingV10Tests(unittest.TestCase):
    def test_precompiled_mod_type(self):
        validate_metadata(good_manifest())
        for key,value in (("ModType",0),("targetGameBuild",719),("GUID","OTHER_MOD")):
            data=good_manifest();data[key]=value
            with self.assertRaises(ValueError):validate_metadata(data)
    def test_compiled_dll_must_be_near_manifest_not_a_sibling(self):
        with tempfile.TemporaryDirectory() as td:
            path=Path(td)
            (path/"src.dll").write_bytes(simulated_pe())
            (path/"mod.json").write_text(json.dumps(good_manifest()),encoding="utf8")
            result=pack(path/"src.dll",path/"mod.json",path/"output.zip")
            with zipfile.ZipFile(path/"output.zip") as z:
                files=set(z.namelist())
                self.assertIn(ROOT+"/mod.json",files)
                self.assertIn(ROOT+"/"+UID+".dll",files)
                self.assertNotIn(ROOT+"/Code/XianxiaObserverV07.cs",files)
                self.assertEqual(z.read(ROOT+"/"+UID+".dll"),simulated_pe())
                self.assertEqual(json.loads(z.read(ROOT+"/mod.json"))["ModType"],1)
                self.assertIn(b"DEVICE_PENDING",z.read("README_INSTALL_DEVICE_PENDING.txt"))
                self.assertEqual(len([x for x in files if x.endswith(".dll")]),1)
                self.assertEqual(len(files),4)
                self.assertIn("original_dll_sha256",result)
    def test_reject_empty_dll(self):
        with tempfile.TemporaryDirectory() as td:
            path=Path(td);(path/"mod.json").write_text(json.dumps(good_manifest()),encoding="utf8")
            for bad in (b"",b"z"*9000,b"MZ"+b"x"*2300):
                (path/"bad.dll").write_bytes(bad)
                with self.assertRaises(ValueError):pack(path/"bad.dll",path/"mod.json",path/"out.zip")

if __name__=="__main__":unittest.main(verbosity=2)
