import json
import tempfile
import unittest
from pathlib import Path
from PIL import Image, ImageDraw
from atlas_reality_audit import audit_atlas, normalized_crop


class RealAtlasAuditTest(unittest.TestCase):
    def test_reject_invalid_crop(self):
        with self.assertRaisesRegex(ValueError, 'CROP_BOX_OUTSIDE'):
            normalized_crop(Image.new('RGBA',(100,100)),[0.1,0.2,1.2,0.9])

    def test_require_explicit_flatten_for_fake_alpha(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d)
            path=root/'atlas.png';layout=root/'layout.json'
            im=Image.new('RGBA',(256,256),(240,240,240,250))
            ImageDraw.Draw(im).rectangle((60,60,195,195),fill=(40,80,60,250))
            im.save(path)
            layout.write_text(json.dumps({'slots':[{'id':'CL01','name':'demo','box':[0,0,1,1],
                    'sprite_region':[0,0,1,1]}]}))
            result=audit_atlas(path,layout,root/'reject')
            self.assertEqual(result['cutout_candidate_count'],0)
            self.assertEqual(result['approved_count'],0)
            result=audit_atlas(path,layout,root/'allow',flatten_ambiguous_alpha=True)
            self.assertEqual(result['cutout_candidate_count'],1)
            self.assertFalse(result['assets'][0]['art_approved'])
            self.assertEqual(result['assets'][0]['analysis_alpha_normalization'],
                             'EXPLICIT_RGB_CHANNEL_PRESERVATION_NOT_ALPHA_RECONSTRUCTION')
            self.assertTrue((root/'allow/candidates/CL01/two_backgrounds.png').exists())

    def test_reject_duplicate_ids(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);im=Image.new('RGB',(300,300),'white')
            im.save(root/'im.png')
            (root/'layout.json').write_text(json.dumps({'slots':[{'id':'A1','box':[0,0,1,1]},
                                                                 {'id':'A1','box':[0,0,1,1]}]}))
            with self.assertRaisesRegex(ValueError, 'INVALID_ASSET_IDS'):
                audit_atlas(root/'im.png',root/'layout.json',root/'out')


if __name__=='__main__':
    unittest.main()
