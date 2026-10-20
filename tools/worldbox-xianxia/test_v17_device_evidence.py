import sys,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent/"qa"))
from verify_android_world_evidence import verify
class DeviceEvidenceTests(unittest.TestCase):
 def test_no_forged_pass_from_preset(self):
  x=verify("[XIANXIA-V16] MAP_API_READY titanic.size=8 addParam=MapSizeAsset")
  self.assertEqual(x["verdict"],"NO_2048_WORLD_PROOF")
  self.assertFalse(x["observed_exact_2048_square"])
 def test_real_dimension_still_not_saveproof(self):
  x=verify("[XIANXIA-V16] MAP_API_READY | WORLD_SIZE_MATCH actual=2048x2048 target=2048x2048 tiles=4194304")
  self.assertTrue(x["observed_exact_2048_square"])
  self.assertFalse(x["save_reload_verified"])
  self.assertFalse(x["apk_one_tap_verified"])
  self.assertEqual(x["verdict"],"DIMENSIONS_ONLY_NEEDS_DEVICE_QA")
 def test_last_world_readback_wins(self):
  x=verify("WORLD_SIZE_MATCH actual=2048x2048\nWORLD_SIZE_DIFFERENT actual=768x768")
  self.assertFalse(x["observed_exact_2048_square"])
  self.assertEqual(x["actual_dimensions"],[768,768])
 def test_fatal_crash_blocks_pass(self):
  x=verify("WORLD_SIZE_MATCH actual=2048x2048\nFATAL EXCEPTION")
  self.assertEqual(x["verdict"],"FAIL_CRASH_SIGNATURE")
 def test_false_match_dimensions_blocked(self):
  x=verify("WORLD_SIZE_MATCH actual=512x512")
  self.assertFalse(x["observed_exact_2048_square"])
if __name__=="__main__":unittest.main()
