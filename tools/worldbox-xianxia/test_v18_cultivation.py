"""WorldBox nonofficial third-party MOD cultivation gameplay safety tests."""
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parent
C=(ROOT/"gameplay"/"CultivationV18.cs").read_text(encoding="utf-8")
UI=(ROOT/"nml-observer-v07"/"Code"/"XianxiaObserverV07.cs").read_text(encoding="utf-8")
class CultivationTests(unittest.TestCase):
    def test_realm_tree_complete(self):
        for name in ["炼气十三层","筑基初期","结丹初期","元婴初期","化神初期","炼虚初期","合体初期","大乘","渡劫"]:
            self.assertIn(name,C)
    def test_explicit_actor_cultivation_and_2s_cooldown(self):
        self.assertIn("Meditate(Actor actor,float now)",C)
        self.assertIn("MinimumPulseSeconds = 2f",C)
        self.assertIn("record.Qi+=advance",C)
        self.assertIn("record.RealmIndex++",C)
    def test_bounded_session_only_no_save(self):
        self.assertIn("MaxActors = 256",C)
        self.assertIn("ResetOnWorldChange()",C)
        self.assertNotIn("saveWorld",C)
        self.assertNotIn("writeSave",C)
    def test_touch_ui_is_actually_wired(self):
        self.assertIn('"吐纳修炼"',UI)
        self.assertIn("CultivationV18.Meditate(target,Time.unscaledTime)",UI)
        self.assertIn("cultivator.Summary",UI)
    def test_book_maintenance_not_every_frame(self):
        self.assertIn("nextCultivationCleanup=Time.unscaledTime+15f",UI)
if __name__=="__main__": unittest.main()
