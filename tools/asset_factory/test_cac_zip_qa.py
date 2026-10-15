import io,json,tempfile,unittest,sys,hashlib
from pathlib import Path
from zipfile import ZipFile
from PIL import Image,ImageDraw
from cac_zip_qa import audit_zip

def make_zip(p,small=False,touch=False,tamper=False):
 n=280 if small else 512
 img=Image.new('RGBA',(n,n),(0,0,0,0))
 ImageDraw.Draw(img).rectangle((0 if touch else 30,30,n-30,n-30),fill=(150,100,80,255))
 data=io.BytesIO();img.save(data,format='PNG')
 item={'id':'ASSET_1','file':'candidates/test.png','status':'UNAPPROVED','visual_qa':'NOT_REVIEWED','sha256':'bad' if tamper else hashlib.sha256(data.getvalue()).hexdigest()}
 manifest={'num_candidates':1,'approved':0,'type':'CANDIDATE_ONLY','assets':[item]}
 with ZipFile(p,'w') as z:
  z.writestr('candidate_manifest.json',json.dumps(manifest));z.writestr('candidates/test.png',data.getvalue())

class Tests(unittest.TestCase):
 def test_valid_technical_still_never_approves(self):
  with tempfile.TemporaryDirectory() as d:
   p=Path(d)/'a.zip';make_zip(p)
   r=audit_zip(p);self.assertTrue(r['passed']);self.assertEqual(r['approved_count'],0)
 def test_small_fails(self):
  with tempfile.TemporaryDirectory() as d:
   p=Path(d)/'a.zip';make_zip(p,small=True)
   self.assertIn('BELOW_NATIVE_RESOLUTION_MIN',audit_zip(p)['entries'][0]['issues'])
 def test_edge_fails(self):
  with tempfile.TemporaryDirectory() as d:
   p=Path(d)/'a.zip';make_zip(p,touch=True)
   self.assertIn('VISIBLE_ALPHA_TOUCHES_CANVAS_EDGE',audit_zip(p)['entries'][0]['issues'])
 def test_hash_fails(self):
  with tempfile.TemporaryDirectory() as d:
   p=Path(d)/'a.zip';make_zip(p,tamper=True)
   self.assertIn('SHA256_MISMATCH',audit_zip(p)['entries'][0]['issues'])

if __name__=='__main__':unittest.main()