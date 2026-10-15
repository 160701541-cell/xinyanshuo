import json
import tempfile
import unittest
from pathlib import Path
from PIL import Image, ImageDraw
from candidate_cutout import remove_uniform_background, process


class CutoutTest(unittest.TestCase):
    def test_light_background_cleanup(self):
        im = Image.new('RGB', (128, 128), (250, 250, 250))
        ImageDraw.Draw(im).ellipse((25, 25, 103, 103), fill=(40, 120, 90))
        cleaned, report = remove_uniform_background(im)
        self.assertEqual(cleaned.getpixel((0, 0))[3], 0)
        self.assertEqual(cleaned.getpixel((64, 64))[3], 255)
        self.assertEqual(report['operation'], 'UNIFORM_EDGE_CONNECTED_CUTOUT_CANDIDATE')

    def test_black_background_cleanup(self):
        im = Image.new('RGB', (128, 128), (0, 0, 0))
        ImageDraw.Draw(im).rectangle((30, 30, 100, 100), fill=(190, 80, 42))
        cleaned, _ = remove_uniform_background(im)
        self.assertEqual(cleaned.getpixel((0, 0))[3], 0)
        self.assertEqual(cleaned.getpixel((64, 64))[3], 255)

    def test_existing_alpha_preserved(self):
        im = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
        im.putpixel((30, 30), (220, 45, 60, 123))
        cleaned, report = remove_uniform_background(im)
        self.assertEqual(cleaned.tobytes(), im.tobytes())
        self.assertEqual(report['operation'], 'PRESERVED_EXISTING_ALPHA')

    def test_mixed_corner_reject(self):
        im = Image.new('RGB', (128, 128), 'white')
        ImageDraw.Draw(im).rectangle((0, 0, 20, 20), fill='blue')
        with self.assertRaisesRegex(ValueError, 'INCONSISTENT_CORNER'):
            remove_uniform_background(im)

    def test_lost_opaque_subject_reject(self):
        im = Image.new('RGB', (128, 128), 'white')
        with self.assertRaisesRegex(ValueError, 'AMBIGUOUS_BACKGROUND'):
            remove_uniform_background(im)

    def test_manifest_with_real_files_and_safe_unapproved_output(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d) / 'raw'
            out = Path(d) / 'clean'
            a = root / 'candidates' / 'test01'
            a.mkdir(parents=True)
            im = Image.new('RGB', (256, 256), 'white')
            ImageDraw.Draw(im).ellipse((36, 20, 200, 221), fill='green')
            im.save(a / 'scene_candidate.png')
            data = {'count': 1, 'approved_count': 0, 'assets': [{
                'id': 'test01', 'review': 'UNAPPROVED',
                'scene': 'candidates/test01/scene_candidate.png',
                'icon': 'candidates/test01/icon_candidate.png'}]}
            (root / 'candidate_manifest.json').write_text(json.dumps(data))
            report = process(root, out)
            self.assertEqual(report['cleaned_candidate_count'], 1)
            self.assertEqual(report['approved_count'], 0)
            self.assertEqual(report['assets'][0]['review'], 'UNAPPROVED')
            with Image.open(out / report['assets'][0]['scene']) as img:
                self.assertEqual(img.getpixel((0, 0))[3], 0)
            self.assertTrue((out / 'candidates/test01/visual_review_preview.png').is_file())

    def test_path_escape_blocks_asset(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d) / 'raw'
            root.mkdir()
            out = Path(d) / 'clean'
            data = {'count': 1, 'approved_count': 0, 'assets': [{
                'id': 'test01', 'review': 'UNAPPROVED', 'scene': '../../x.png'}]}
            (root / 'candidate_manifest.json').write_text(json.dumps(data))
            report = process(root, out)
            self.assertEqual(report['cleaned_candidate_count'], 0)
            self.assertEqual(report['assets'][0]['cleanup_status'], 'BLOCKED')

    def test_no_nested_overwrite(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d) / 'raw'; root.mkdir()
            with self.assertRaisesRegex(ValueError, 'OUTPUT_MUST_NOT'):
                process(root, root / 'nested')

    def test_source_falsely_marked_approved_is_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d) / 'raw'; root.mkdir()
            (root / 'candidate_manifest.json').write_text(json.dumps({
                'count': 1, 'approved_count': 0, 'assets': [{
                    'id': 'test01', 'review': 'APPROVED', 'scene': 'any.png'}]}))
            with self.assertRaisesRegex(ValueError, 'INVALID_OR_APPROVED'):
                process(root, Path(d) / 'out')


if __name__ == '__main__':
    unittest.main()
