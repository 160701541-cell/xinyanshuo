"""Standalone verification of P1 material PNG serialization and determinism."""
import hashlib
import json
from pathlib import Path
import struct
import tempfile
import unittest
import zlib
from generate_materials import SIZE, build

def decode_png_rgb(path):
    blob = path.read_bytes()
    assert blob[:8] == b'\x89PNG\r\n\x1a\n'
    p, data = 8, bytearray()
    while p < len(blob):
        count = struct.unpack('>I', blob[p:p+4])[0]; p += 4
        tag = blob[p:p+4]; p += 4
        chunk = blob[p:p+count]; p += count
        check = struct.unpack('>I', blob[p:p+4])[0]; p += 4
        assert zlib.crc32(tag + chunk) & 0xffffffff == check
        if tag == b'IHDR':
            assert struct.unpack('>IIBBBBB', chunk) == (SIZE, SIZE, 8, 2, 0, 0, 0)
        if tag == b'IDAT': data.extend(chunk)
    raw = zlib.decompress(data)
    assert len(raw) == SIZE * (1 + SIZE * 3)
    assert all(raw[y*(1 + SIZE*3)] == 0 for y in range(SIZE))
    return raw

class MaterialTest(unittest.TestCase):
    def test_exports(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            manifest = build(root)
            self.assertEqual(set(manifest['materials']), {'qing_tile','ivory_plaster'})
            for maps in manifest['materials'].values():
                for item in maps.values():
                    path = root / item['path']
                    self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), item['sha256'])
                    decode_png_rgb(path)
                normal = decode_png_rgb(root / maps['normal']['path'])
                self.assertGreater(normal.count(b'\xff'), 0)
            first = (root/'manifest.json').read_bytes()
            build(root)
            self.assertEqual(first, (root/'manifest.json').read_bytes())
            self.assertEqual(json.loads(first)['status'], 'prototype_unapproved')

if __name__ == '__main__':
    unittest.main()
