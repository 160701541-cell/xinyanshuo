import importlib.util
import io
from pathlib import Path
import tempfile
import unittest
import zipfile


path = Path(__file__).parent / 'private-apk-lab/package_private_candidate.py'
spec = importlib.util.spec_from_file_location('private_candidate', path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class PrivatePackagingTests(unittest.TestCase):
    def test_preserve_unrelated_bytes_and_original_input(self):
        with tempfile.TemporaryDirectory() as td:
            td = Path(td)
            managed = io.BytesIO()
            with zipfile.ZipFile(managed, 'w') as z:
                z.writestr('Assembly-CSharp.dll', b'original fixture')
                z.writestr('Assembly-CSharp.pdb', b'stale fixture')
                z.writestr('UnityEngine.dll', b'untouched fixture')
            apk, patched, plugin = td/'input.apk', td/'patched.dll', td/'plugin.dll'
            with zipfile.ZipFile(apk, 'w') as z:
                z.writestr('assets/Mono/Managed.zip', managed.getvalue())
                z.writestr('AndroidManifest.xml', b'manifest fixture')
                z.writestr('lib/arm64-v8a/test.so', b'native fixture')
                z.writestr('classes.dex', b'dex fixture')
                z.writestr('META-INF/CERT.RSA', b'old signature fixture')
            original = apk.read_bytes()
            patched.write_bytes(b'patched fixture')
            plugin.write_bytes(b'original addon fixture')
            out, report = td/'out.apk', td/'report.json'
            module.package(apk, patched, plugin, out, report)
            self.assertEqual(original, apk.read_bytes())
            with zipfile.ZipFile(out) as z:
                self.assertEqual(z.read('classes.dex'), b'dex fixture')
                self.assertEqual(z.read('AndroidManifest.xml'), b'manifest fixture')
                self.assertNotIn('META-INF/CERT.RSA', z.namelist())
                with zipfile.ZipFile(io.BytesIO(z.read('assets/Mono/Managed.zip'))) as m:
                    self.assertEqual(m.read('Assembly-CSharp.dll'), b'patched fixture')
                    self.assertEqual(m.read('UnityEngine.dll'), b'untouched fixture')
                    self.assertNotIn('Assembly-CSharp.pdb', m.namelist())
            with self.assertRaises(FileExistsError):
                module.package(apk, patched, plugin, out, report)

    def test_refuse_overwriting_original_input(self):
        with tempfile.TemporaryDirectory() as td:
            p = Path(td)/'original.apk'
            p.write_bytes(b'fixture')
            with self.assertRaises(ValueError):
                module.package(p, p, p, p, Path(td)/'report.json')


if __name__ == '__main__':
    unittest.main()
