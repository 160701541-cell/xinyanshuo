import json,tempfile,unittest
from pathlib import Path
from world_size_planner import CHUNK,TIERS,calc,recommend

class GiantMapPlanTests(unittest.TestCase):
    def test_size_geometry(self):
        self.assertEqual(calc(8).tiles,512)
        self.assertEqual(calc(16).tiles,1024)
        self.assertEqual(calc(20).tiles,1280)
        self.assertEqual(calc(24).tiles,1536)
        self.assertEqual(calc(30).tiles,1920)
    def test_quadruple_area(self):
        self.assertEqual(calc(16).relative_to_vanilla_titanic,4.0)
        self.assertEqual(calc(20).relative_to_vanilla_titanic,6.25)
        self.assertEqual(calc(30).relative_to_vanilla_titanic,14.062)
    def test_map_preset_still_not_in_game(self):
        for n in TIERS:
            self.assertEqual(calc(n).registration_status,"NOT_REGISTERED_IN_ANDROID_GAME")
    def test_no_telemetry_no_oversell(self):
        self.assertEqual(recommend("Snapdragon 8 Elite")["tier"],12)
        self.assertEqual(recommend("unknown")["tier"],8)
    def test_high_end_after_device_actual_test(self):
        self.assertEqual(recommend("Snapdragon 8 Elite",5.2,55,4000)["tier"],20)
        self.assertEqual(recommend("Snapdragon 8 Elite",4,45,4000)["tier"],16)
    def test_huge_npc_pop_needs_conservatism(self):
        self.assertEqual(recommend("Snapdragon 8 Elite",5.2,45,40000)["tier"],12)
    def test_low_fps_rolls_back(self):
        self.assertEqual(recommend("Snapdragon 8 Elite",9,15)["tier"],8)
    def test_unknown_size_rejected(self):
        with self.assertRaises(ValueError):calc(45)
    def test_negative_population_rejected(self):
        with self.assertRaises(ValueError):recommend("x",population=-1)
if __name__=="__main__":unittest.main(verbosity=2)
