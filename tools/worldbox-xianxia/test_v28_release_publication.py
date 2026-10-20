"""Guard the public v0.28 release location against private binaries."""
import json,unittest
from pathlib import Path
ROOT=Path(__file__).parent
DIR=ROOT/"releases"/"v0.28"
class ReleaseV28(unittest.TestCase):
 def test_public_source_only_and_no_fake_device_verification(self):
  x=json.loads((DIR/"PUBLIC_RELEASE_MANIFEST.json").read_text(encoding="utf-8"))
  assert x["project"]=="WORLDBOX_THIRD_PARTY_MOD_DERIVATIVE_TEST"
  assert x["contains_commercial_apk"] is False and x["contains_signing_key"] is False
  assert x["private_apk"]["public_uploaded"] is False
  assert x["private_apk"]["installed_on_device"] is False
  assert x["private_apk"]["verified_running_on_device"] is False
  assert x["private_apk"]["sha256"]=="9efa49f98e92921f7ee8b9341f14b68b39d426323bc0a8cf25d8acc41e6cc822"
  assert x["main_canglan_unchanged"] is True
  assert (ROOT/"private_stage_mono_v28.py").exists()
 def test_release_folder_disallows_apk_and_secrets(self):
  bad={".apk",".pck",".aab",".dll",".dex",".so",".jks",".keystore",".p12",".pfx",".idsig"}
  files=[x for x in DIR.rglob("*") if x.is_file()]
  assert len(files)>=2
  assert not [x.name for x in files if x.suffix.lower() in bad]
 def test_readme_is_not_disguised_apk_download(self):
  t=(DIR/"README.md").read_text(encoding="utf8")
  assert "SIGNED_PRIVATE_APK_DEVICE_PENDING" in t
  assert "未公开上传" in t
if __name__=="__main__":unittest.main()
