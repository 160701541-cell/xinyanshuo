"""Regression and adversarial mutation tests for independent P1 material QA."""
import hashlib
import json
from pathlib import Path
import shutil
import tempfile
import unittest

from audit_materials import audit, read_rgb_png, QualityFailure
from generate_materials import build, png_rgb


class MaterialRegression(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.original = tempfile.TemporaryDirectory()
        cls.reference_root = Path(cls.original.name)
        build(cls.reference_root)

    @classmethod
    def tearDownClass(cls):
        cls.original.cleanup()

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        for file in self.reference_root.iterdir():
            shutil.copy2(file, self.root/file.name)

    def edit_manifest(self, edit):
        path = self.root/'manifest.json'
        doc = json.loads(path.read_text(encoding='utf-8'))
        edit(doc)
        path.write_text(json.dumps(doc,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

    def rewrite_png(self, material, channel, modify):
        path=self.root/f'{material}_{channel}.png'
        pixels=bytearray().join(read_rgb_png(path,256))
        modify(pixels)
        png_rgb(path,pixels)
        def sync(doc):
            row=doc['materials'][material][channel]
            row['bytes']=path.stat().st_size
            row['sha256']=hashlib.sha256(path.read_bytes()).hexdigest()
        self.edit_manifest(sync)

    def test_technical_success_does_not_claim_art_approval(self):
        result=audit(self.root)
        self.assertEqual(result['technical_gate'],'PASS')
        self.assertEqual(result['texture_file_count'],6)
        self.assertIn('BLOCKED',result['android_release_gate'])
        self.assertIn('BLOCKED',result['art_direction_gate'])

    def test_rebuild_is_byte_identical(self):
        manifest=(self.root/'manifest.json').read_bytes()
        checks={p.name:hashlib.sha256(p.read_bytes()).hexdigest()
                for p in self.root.iterdir()}
        build(self.root)
        self.assertEqual(manifest,(self.root/'manifest.json').read_bytes())
        self.assertEqual(checks,{p.name:hashlib.sha256(p.read_bytes()).hexdigest()
                                 for p in self.root.iterdir()})

    def test_sha_tamper_detected(self):
        with (self.root/'ivory_plaster_albedo.png').open('ab') as stream:
            stream.write(b'bad')
        with self.assertRaisesRegex(QualityFailure,'size mismatch'):
            audit(self.root)

    def test_flat_texture_with_recalculated_sha_still_fails(self):
        self.rewrite_png('ivory_plaster','albedo',
            lambda b:b.__setitem__(slice(None),bytes((219,211,198))*65536))
        with self.assertRaisesRegex(QualityFailure,'overly uniform albedo'):
            audit(self.root)

    def test_art_self_certification_rejected(self):
        self.edit_manifest(lambda d:d.update(status='production_approved'))
        with self.assertRaisesRegex(QualityFailure,'must not self-certify'):
            audit(self.root)

    def test_flat_normal_even_with_valid_crc_and_sha_fails(self):
        self.rewrite_png('qing_tile','normal',
            lambda b:b.__setitem__(slice(None),bytes((128,128,255))*65536))
        with self.assertRaisesRegex(QualityFailure,'fake flat normal map'):
            audit(self.root)

    def test_inverted_normals_rejected(self):
        def invert(buf):
            for idx in range(2,len(buf),3):
                buf[idx]=0
        self.rewrite_png('qing_tile','normal',invert)
        with self.assertRaisesRegex(QualityFailure,'inverted or implausible'):
            audit(self.root)

    def test_colorized_roughness_rejected(self):
        self.rewrite_png('qing_tile','roughness',lambda b:b.__setitem__(1,90))
        with self.assertRaisesRegex(QualityFailure,'grayscale'):
            audit(self.root)

    def test_seam_detected_after_sha_recomputed(self):
        def create_seam(buf):
            for y in range(256):
                idx=(y*256+255)*3
                buf[idx:idx+3]=b'\x00\x00\x00'
        self.rewrite_png('ivory_plaster','albedo',create_seam)
        with self.assertRaisesRegex(QualityFailure,'horizontal tiling seam'):
            audit(self.root)

    def test_crc_detected_even_after_sha_recomputed(self):
        path=self.root/'ivory_plaster_normal.png'
        data=bytearray(path.read_bytes())
        data[55]^=1
        path.write_bytes(data)
        self.edit_manifest(lambda d:d['materials']['ivory_plaster']['normal'].update(
            bytes=path.stat().st_size,sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
        with self.assertRaisesRegex(QualityFailure,'CRC mismatch'):
            audit(self.root)

    def test_unknown_asset_in_package_rejected(self):
        (self.root/'unlisted.bin').write_bytes(b'unlisted test content')
        with self.assertRaisesRegex(QualityFailure,'unexpected resource'):
            audit(self.root)

    def test_path_traversal_rejected(self):
        self.edit_manifest(lambda d:d['materials']['qing_tile']['normal'].update(path='../other.png'))
        with self.assertRaisesRegex(QualityFailure,'path substitution'):
            audit(self.root)


if __name__=='__main__':
    unittest.main()
