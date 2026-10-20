import hashlib,struct,sys,tempfile,unittest,zipfile,zlib
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent/"private-apk-lab"))
from verify_android_package_consistency_v39 import inspect_apk
PACKAGE="com.xinyanshuo.worldbox.lab31"
def fake_dex(klass):
    names=["DiagnosticsActivity","DiagnosticReport","ModDeployment","ExternalModImporterV32"]
    d=bytearray(112)+bytearray(b"\0".join(
      ("Lcom/xinyanshuo/worldbox/"+klass+"/"+name+";").encode() for name in names))
    d[:8]=b"dex\n035\0"
    struct.pack_into("<I",d,32,len(d))
    d[12:32]=hashlib.sha1(d[32:]).digest()
    struct.pack_into("<I",d,8,zlib.adler32(d[12:])&0xffffffff)
    return d
def fake_apk(file,data):
    with zipfile.ZipFile(file,"w") as z:
        z.writestr("AndroidManifest.xml",(PACKAGE+" manifest").encode("utf-16le"))
        z.writestr("classes5.dex",data)
class AndroidManifestDexGateTest(unittest.TestCase):
    def test_correct_v39_passes(self):
        with tempfile.TemporaryDirectory() as td:
            path=Path(td)/"ok.apk";fake_apk(path,fake_dex("lab31"))
            self.assertEqual(inspect_apk(path)["status"],"PASS_PRIVATE_PACKAGE_CLASS_CONSISTENCY")
    def test_actual_v38_regression_fails(self):
        with tempfile.TemporaryDirectory() as td:
            path=Path(td)/"crash.apk";fake_apk(path,fake_dex("lab13"))
            with self.assertRaisesRegex(ValueError,"ClassNotFoundException"):
                inspect_apk(path)
    def test_stale_checksum_fails(self):
        with tempfile.TemporaryDirectory() as td:
            path=Path(td)/"bad.apk";dex=fake_dex("lab31");dex[50]^=1  # corrupt header bytes, preserve all class strings
            fake_apk(path,dex)
            with self.assertRaisesRegex(ValueError,"DEX SHA1 signature"):
                inspect_apk(path)
if __name__=="__main__":unittest.main()
