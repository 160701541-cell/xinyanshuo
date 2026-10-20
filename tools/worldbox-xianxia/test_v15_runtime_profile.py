"""WorldBox Android third-party MOD diagnostic, NOT original Canglan game QA."""
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parent

class RuntimeProfileTests(unittest.TestCase):
    def test_readonly_diagnostic_api(self):
        s=(ROOT/"huge-map-mod"/"GiantMapOptionsV11.cs").read_text(encoding="utf8")
        a=s.split("public static string DiagnoseMapApi()",1)[1].split("// Separate, explicit 32x32 test mode.",1)[0]
        self.assertIn('MAP_API_READY',a)
        self.assertIn('titanic.size=',a)
        self.assertIn('addParam=',a)
        self.assertNotIn('add.Invoke',a)
        self.assertNotIn('Set(',a)
        self.assertNotIn('setMapSize(',a)
    def test_user_facing_diagnostic_button(self):
        s=(ROOT/"nml-observer-v07"/"Code"/"XianxiaObserverV07.cs").read_text(encoding="utf8")
        self.assertIn('"尺寸API自检"',s)
        self.assertIn('DiagnoseMapApi()',s)
        self.assertTrue('[XIANXIA-V15]' in s or '[XIANXIA-V16]' in s)
    def test_2048_candidate_explicit_only(self):
        s=(ROOT/"huge-map-mod"/"GiantMapOptionsV11.cs").read_text(encoding="utf8")
        self.assertIn('public const int ExtremeChunks = 32;',s)
        self.assertIn('ExtremeArmed',s)
        self.assertIn('OnExtremeTap()',s)
if __name__=="__main__":unittest.main()
