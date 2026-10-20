"""Independent WorldBox 0.51.4 MOD diagnostic QA, never the original Canglan project."""
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parent
class GeneratedMapEvidenceTests(unittest.TestCase):
    def test_live_world_size_readonly(self):
        s=(ROOT/"huge-map-mod"/"GiantMapOptionsV11.cs").read_text(encoding="utf8")
        segment=s.split("public static string DiagnoseActualWorld()",1)[1].split("// Read-only runtime diagnostics",1)[0]
        for key in ['MapBox','WORLD_SIZE_','actual=','target=2048x2048','matched=w==2048&&h==2048']:
            self.assertIn(key,segment)
        self.assertNotIn('add.Invoke',segment)
        self.assertNotIn('setMapSize(',segment)
        self.assertNotIn('generateMap(',segment)
    def test_diagnostic_reports_both_actual_and_api(self):
        s=(ROOT/"nml-observer-v07"/"Code"/"XianxiaObserverV07.cs").read_text(encoding="utf8")
        self.assertIn('DiagnoseMapApi()+" | "+GiantMapOptionsV11.DiagnoseActualWorld()',s)
        self.assertIn('[XIANXIA-V16]',s)
if __name__=="__main__":unittest.main()
