import io,json,tempfile,unittest,zipfile
from pathlib import Path
from apk_loader_preflight import audit
from android_log_gate import check
from observer_math import Camera,zoom_lod
from scope_gate import validate_paths,validate_change_entries

class V08IsolationAndCompatibility(unittest.TestCase):
    def test_project_isolation(self):
        self.assertEqual(validate_paths(["tools/worldbox-xianxia/qa.py",".github/workflows/worldbox-external-mod-lab-v12.yml"]),[])
        for p in ("AGENTS.md","game-source/x.gd","android-preview/latest.json","docs/CAC_CHANGELOG.md","data/updates.json"):
            self.assertTrue(validate_paths([p]),p)
    def test_deleted_canglan_file_blocked(self):
        self.assertTrue(validate_change_entries(["D\tgame-source/Main.gd"]))
        self.assertTrue(validate_change_entries(["D\tandroid-preview/latest.json"]))
        self.assertEqual(validate_change_entries(["D\t.github/workflows/worldbox-external-mod-lab-v11.yml"]),[])
    def test_mock_loader_and_apk(self):
        with tempfile.TemporaryDirectory() as td:
            apk=Path(td)/"game.apk";loader=Path(td)/"loader.zip"
            buf=io.BytesIO()
            with zipfile.ZipFile(buf,"w") as z:z.writestr("game/Assembly-CSharp.dll",b"MOCK")
            with zipfile.ZipFile(apk,"w") as z:
                z.writestr("assets/Mono/Managed.zip",buf.getvalue())
                z.writestr("lib/arm64-v8a/libmonosgen-2.0.so",b"MOCK")
                z.writestr("lib/arm64-v8a/libil2cpp.so",b"MOCK")
            with zipfile.ZipFile(loader,"w") as z:z.writestr("NeoModLoader.dll",b"MOCK")
            result=audit(apk,loader)
            self.assertTrue(result["apk_static_features"]["mono_runtime_present"])
            self.assertTrue(result["apk_static_features"]["il2cpp_runtime_present"])
            self.assertFalse(result["neomodloader_mobile_dll_present"])
            self.assertFalse(result["android_loader_verified"])
            self.assertEqual(result["status"],"DEVICE_PENDING")
    def test_empty_log_is_blocked(self):
        self.assertEqual(check("")["status"],"DEVICE_PENDING")
    def test_missing_loader_is_blocked(self):
        self.assertEqual(check("[XIANXIA-V07] SOURCE_ONLY_LOAD\n[XIANXIA-V07] REAL_MAP_SAMPLE")["status"],"DEVICE_PENDING")
    def test_ordered_milestones_only_candidate(self):
        s="NML loaded\n[XIANXIA-V07] SOURCE_ONLY_LOAD\n[XIANXIA-V07] REAL_MAP_SAMPLE"
        self.assertEqual(check(s)["status"],"CANDIDATE_LOG_EVIDENCE_PRESENT")
        self.assertEqual(check("\n".join(s.splitlines()[::-1]))["status"],"DEVICE_PENDING")
    def test_errors_block(self):
        s="NML loaded\n[XIANXIA-V07] SOURCE_ONLY_LOAD\n[XIANXIA-V07] REAL_MAP_SAMPLE\nXIANXIA-V07 ERROR"
        self.assertEqual(check(s)["status"],"DEVICE_PENDING")
    def test_camera_rotation_reference(self):
        for q in range(4):
            x,y=4,-2
            dx,dy=((x,y),(-y,x),(-x,-y),(y,-x))[q]
            self.assertEqual(Camera(10,20,6,q).project(10+dx,20+dy),Camera(10,20,6,0).project(14,18))
    def test_zoom_fails_closed(self):
        self.assertEqual(zoom_lod(100),96)

if __name__=="__main__":unittest.main(verbosity=2)
