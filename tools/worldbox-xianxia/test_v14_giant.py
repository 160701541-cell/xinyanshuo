"""WorldBox external third-party MOD lab: giant map budget & safety regression."""
import unittest
from pathlib import Path
from world_size_planner import calc, recommend

ROOT = Path(__file__).resolve().parent
CODE = ROOT / "huge-map-mod" / "GiantMapOptionsV11.cs"
OBSERVER = ROOT / "nml-observer-v07" / "Code" / "XianxiaObserverV07.cs"

class ExtremeMapV14Tests(unittest.TestCase):
    def test_32_chunk_size(self):
        v=calc(32)
        self.assertEqual(v.tiles,2048)
        self.assertEqual(v.tile_count,4194304)
        self.assertEqual(v.relative_to_vanilla_titanic,16.0)
        self.assertEqual(v.registration_status,"NOT_REGISTERED_IN_ANDROID_GAME")

    def test_explicit_separate_confirmation(self):
        s=CODE.read_text(encoding="utf8")
        self.assertIn("ExtremeArmed",s)
        self.assertIn("OnExtremeTap()",s)
        self.assertIn("ExtremeChunks = 32",s)
        self.assertIn("ExtremeRegistered=true",s)
        self.assertIn("Set(asset,\"show_warning\",true)",s)

    def test_only_registers_new_world_candidate(self):
        s=CODE.read_text(encoding="utf8")
        self.assertNotIn("generateMap(", "\n".join(line for line in s.splitlines() if not line.strip().startswith("//")))
        self.assertNotIn("setMapSize(",s.replace("setMapSize()",""))
        self.assertIn("add.Invoke(lib,new[]{asset})",s)

    def test_button_visible_with_separate_warning(self):
        s=OBSERVER.read_text(encoding="utf8")
        self.assertIn("2048×2048实验",s)
        self.assertIn("OnExtremeTap()",s)
        self.assertIn("确认2048×2048",s)

    def test_no_automatic_extreme_unlock_from_soc(self):
        d=recommend("Snapdragon 8 Elite")
        self.assertLess(d["tier"],32)
        d2=recommend("Snapdragon 8 Elite",7.5,105,4000)
        self.assertLess(d2["tier"],32)

if __name__=="__main__":
    unittest.main(verbosity=2)
