import hashlib, tempfile, unittest, zipfile, struct, zlib
from pathlib import Path
from private_side_by_side_v31 import OLD,NEW,stage

class SideBySideTests(unittest.TestCase):
 def build(self,folder,broken=False):
  p=Path(folder)/'input.apk'
  d=bytearray(bytes(112)+b'v'*128)
  d[:8]=b'dex\n035\0'
  d+=((OLD.replace('.','/')+';').encode()+b'\0')*11
  d[12:32]=hashlib.sha1(d[32:]).digest()
  struct.pack_into('<I',d,8,zlib.adler32(d[12:])&0xffffffff)
  with zipfile.ZipFile(p,'w') as z:
   z.writestr('AndroidManifest.xml',(OLD* (10 if broken else 11)).encode('utf-16le'))
   z.writestr('resources.arsc',OLD.encode('utf-16le'))
   z.writestr('classes5.dex',d)
   z.writestr('assets/synthetic_game',b'stub only')
  return p
 def test_isolated_package_and_game_contents_preserved(self):
  with tempfile.TemporaryDirectory() as t:
   source=self.build(t)
   dest=Path(t)/'isolated.apk'
   before=source.read_bytes()
   r=stage(source,dest)
   self.assertTrue(r['new_app_has_separate_saves'])
   self.assertEqual(before,source.read_bytes())
   with zipfile.ZipFile(dest) as z:
    self.assertIsNone(z.testzip())
    self.assertEqual(z.read('assets/synthetic_game'),b'stub only')
    self.assertEqual(z.read('AndroidManifest.xml').count(NEW.encode('utf-16le')),11)
    self.assertEqual(z.read('resources.arsc').count(NEW.encode('utf-16le')),1)
    d=z.read('classes5.dex')
    self.assertEqual(d.count(NEW.replace('.','/').encode()),11)
    self.assertEqual(hashlib.sha1(d[32:]).digest(),d[12:32])
    self.assertEqual(zlib.adler32(d[12:])&0xffffffff,struct.unpack_from('<I',d,8)[0])
 def test_missing_reference_rejected(self):
  with tempfile.TemporaryDirectory() as t:
   source=self.build(t,broken=True)
   with self.assertRaises(ValueError):stage(source,Path(t)/'isolated.apk')
if __name__=='__main__':unittest.main()
