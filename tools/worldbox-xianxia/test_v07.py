"""No 3rd-party APK/DLL here. This tests policy and pure observer math ONLY."""
import json,unittest
from pathlib import Path
from observer_math import Camera,zoom_lod,sampled_tile_count
from scope_gate import validate_paths,evaluate_policy

class ExternalModOnlyTests(unittest.TestCase):
    def test_whitelist(self):
        self.assertEqual(validate_paths(["tools/worldbox-xianxia/a.cs",".github/workflows/worldbox-external-mod-lab-v07.yml"]),[])
    def test_main_game_protected(self):
        for path in ["AGENTS.md","docs/CAC_CHANGELOG.md","game-source/Main.gd","android-preview/latest.json","data/updates.json","art/real.png","index.html"]:
            self.assertTrue(validate_paths([path]),path)
    def test_third_party_binaries_rejected(self):
        for file in ["worldbox.apk","neomodloader.dll","thirdparty.pck","user.rar"]:
            self.assertTrue(validate_paths(["tools/worldbox-xianxia/"+file]))
    def test_scope(self):
        p=Path(__file__).with_name("project_scope.json")
        s=json.loads(p.read_text(encoding="utf8"))
        self.assertEqual(evaluate_policy(s),[])
        self.assertIn("MOD",s["title"].upper())
    def test_fabricated_android_test_rejected(self):
        s=json.loads(Path(__file__).with_name("project_scope.json").read_text())
        s["device_test"]="PASS"
        self.assertTrue(evaluate_policy(s))
    def test_4_rotations(self):
        c=[Camera(11,17,6,i).project(12,17) for i in range(4)]
        self.assertEqual(len(set(c)),4)
        self.assertEqual(c[0],(-c[2][0],-c[2][1]))
    def test_center_stable(self):
        self.assertEqual([Camera(10,10,4,i).project(10,10) for i in range(4)],[(0,0)]*4)
    def test_sampling_bounds(self):
        self.assertEqual(sampled_tile_count(3),49)
        self.assertEqual(sampled_tile_count(9),361)
    def test_limit_view(self):
        c=Camera(8,8,3)
        self.assertTrue(c.in_view(11,5))
        self.assertFalse(c.in_view(12,5))
    def test_real_lod_sources(self):
        self.assertEqual([zoom_lod(x) for x in (0.5,1,1.1,2,2.5,4)],[32,32,64,64,96,96])
    def test_fake_upsampling_forbidden(self):
        self.assertEqual(zoom_lod(100),96)
        with self.assertRaises(ValueError):zoom_lod(0)

if __name__=="__main__":unittest.main(verbosity=2)
