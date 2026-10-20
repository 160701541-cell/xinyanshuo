"""Executable, synthetic-only tests. Never place the user's commercial APK in CI."""
import io
import json
import tempfile
import unittest
import zipfile
from pathlib import Path
from private_loader_audit_v27 import audit

def make_archive(path, entries):
    with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED) as z:
        for name, payload in entries.items():
            z.writestr(name, payload)

class PrivateAndroidLoaderAuditTests(unittest.TestCase):
    def _case(self, folder, dex):
        root=Path(folder)
        managed=io.BytesIO()
        with zipfile.ZipFile(managed,"w") as mz:
            mz.writestr("Assembly-CSharp.dll", b"MZ\x00synthetic fake")
            mz.writestr("UnityEngine.CoreModule.dll", b"MZ fake")
        apk=root/"own.apk"
        loader=root/"loader.zip"
        make_archive(apk, {
          "lib/arm64-v8a/libmonosgen-2.0.so": b"test",
          "lib/arm64-v8a/libil2cpp.so": b"test",
          "assets/Mono/Managed.zip": managed.getvalue(),
          "classes.dex": dex,
        })
        make_archive(loader,{
          "NeoModLoader.dll": b"not a mobile loader",
          "说明.txt": "Copy into worldbox_Data/StreamingAssets/mods".encode(),
        })
        return apk,loader

    def test_mono_il2cpp_presence_is_not_device_loader_proof(self):
        with tempfile.TemporaryDirectory() as td:
            a,b=self._case(td,b"com.unity3d.player.UnityPlayer")
            r=audit(a,b)
            self.assertTrue(r["apk_static"]["mono_arm64_present"])
            self.assertTrue(r["apk_static"]["il2cpp_arm64_present"])
            self.assertTrue(r["apk_static"]["managed_csharp_present"])
            self.assertFalse(r["apk_static"]["has_any_static_named_bootstrap_hint"])
            self.assertFalse(r["supplied_loader"]["mobile_neomodloader_dll"])
            self.assertTrue(r["supplied_loader"]["desktop_install_instructions"])
            self.assertFalse(r["compatible_runtime_proven"])
            self.assertFalse(r["device_installed_or_passed"])
            self.assertEqual(r["device_qa"],"BLOCKED_NO_DEVICE_LOADER_EVIDENCE")
            self.assertNotIn("UnityPlayer",json.dumps(r))

    def test_marker_is_hint_not_proof_or_apk_build(self):
        with tempfile.TemporaryDirectory() as td:
            a,b=self._case(td,b"debug MelonLoader bootstrap")
            r=audit(a,b)
            self.assertTrue(r["apk_static"]["dex_loader_name_markers"]["melonloader"])
            self.assertTrue(r["apk_static"]["has_any_static_named_bootstrap_hint"])
            self.assertFalse(r["compatible_runtime_proven"])
            self.assertFalse(r["commercial_apk_repacked"])

    def test_invalid_or_broken_inputs_fail_closed(self):
        with tempfile.TemporaryDirectory() as td:
            p=Path(td); a=p/"bad.apk";b=p/"loader.zip"
            a.write_bytes(b"not an APK")
            make_archive(b,{"NeoModLoader.dll":b"test"})
            with self.assertRaises(ValueError):
                audit(a,b)

if __name__ == "__main__":
    unittest.main()
