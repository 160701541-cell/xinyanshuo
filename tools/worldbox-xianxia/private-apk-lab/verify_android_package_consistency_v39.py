#!/usr/bin/env python3
"""P0 safety gate for private WorldBox lab31 Android APKs.
Never upload proprietary APKs/keys; run this only on the privately built file.
"""
import argparse,hashlib,json,struct,zlib,zipfile
from pathlib import Path
def inspect_apk(path,package="com.xinyanshuo.worldbox.lab31"):
    group=package.replace(".","/").encode("ascii")
    with zipfile.ZipFile(path) as apk:
        if not {"AndroidManifest.xml","classes5.dex"}<=set(apk.namelist()):
            raise ValueError("Android manifest or user-owned Java DEX missing")
        manifest=apk.read("AndroidManifest.xml")
        if package.encode("utf-16le") not in manifest:
            raise ValueError("Manifest is not for expected package")
        data=apk.read("classes5.dex")
        if len(data)<112 or not data.startswith(b"dex\n"):
            raise ValueError("Invalid DEX header")
        if b"L"+group+b"/DiagnosticsActivity;" not in data:
            raise ValueError("ClassNotFoundException: Manifest and DEX launcher package mismatch")
        for name in ("DiagnosticReport","ModDeployment","ExternalModImporterV32"):
            if b"L"+group+b"/"+name.encode()+b";" not in data:
                raise ValueError("DEX helper package mismatch "+name)
        if package.endswith("lab31") and b"Lcom/xinyanshuo/worldbox/lab13/DiagnosticsActivity;" in data:
            raise ValueError("Legacy lab13 Activity slipped into lab31 update")
        if data[12:32]!=hashlib.sha1(data[32:]).digest():
            raise ValueError("DEX SHA1 signature not updated")
        if struct.unpack_from("<I",data,8)[0]!=(zlib.adler32(data[12:])&0xffffffff):
            raise ValueError("DEX Adler32 checksum not updated")
        return {"status":"PASS_PRIVATE_PACKAGE_CLASS_CONSISTENCY",
                "package":package,"launcher":"DiagnosticsActivity",
                "sha256":hashlib.sha256(data).hexdigest(),"android_runtime_qa":False}
if __name__=="__main__":
    ap=argparse.ArgumentParser()
    ap.add_argument("--apk",type=Path,required=True)
    ap.add_argument("--package",default="com.xinyanshuo.worldbox.lab31")
    args=ap.parse_args()
    print(json.dumps(inspect_apk(args.apk,args.package),ensure_ascii=False))
