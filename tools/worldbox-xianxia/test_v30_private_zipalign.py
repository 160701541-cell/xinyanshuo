import tempfile,unittest,zipfile
from pathlib import Path
from private_zipalign_python_v30 import align_apk
class AlignmentTest(unittest.TestCase):
 def test_aligns_zip_and_preserves_contents(self):
  with tempfile.TemporaryDirectory() as td:
   src=Path(td)/"in.apk";dst=Path(td)/"out.apk"
   with zipfile.ZipFile(src,"w") as z:
    z.writestr("classes5.dex",b"dexFAKE",compress_type=zipfile.ZIP_STORED)
    z.writestr("lib/arm64-v8a/libfake.so",b"soFAKE",compress_type=zipfile.ZIP_STORED)
    z.writestr("assets/example",b"data",compress_type=zipfile.ZIP_DEFLATED)
   self.assertEqual(align_apk(src,dst),2)
   with zipfile.ZipFile(dst) as z:
    self.assertIsNone(z.testzip())
    self.assertEqual(z.read("classes5.dex"),b"dexFAKE")
    self.assertEqual(z.read("lib/arm64-v8a/libfake.so"),b"soFAKE")
 def test_empty_archive(self):
  with tempfile.TemporaryDirectory() as td:
   a=Path(td)/"a.apk";b=Path(td)/"b.apk"
   with zipfile.ZipFile(a,"w"):pass
   self.assertEqual(align_apk(a,b),0)
if __name__=="__main__":unittest.main()
