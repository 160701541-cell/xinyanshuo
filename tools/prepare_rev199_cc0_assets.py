#!/usr/bin/env python3
"""Prepare unchanged-shape CC0 third-party sword and hair for real APK176 PCK.

All source bytes are pinned by public Git commit AND exact git-blob SHA-1.
Hair_Long.gltf + .bin are original Quaternius Universal Base Characters
CC0 hairstyle published in fastrouter/experiments-costa-vista/ATTRIBUTION.md.
Sole conversion is glTF JSON+BIN -> binary .glb and static preview mesh:
no generated, sculpted or invented character/weapon geometry. Permanent
rigged hairstyle must later be adapted to the exact Knight Head bone.
Sword is from Quaternius Animated Knight Pack (CC0), FBX->GLB conversion
published under ilrein/warptracker/ASSETS.md. Both provenance docs verified.
"""
from __future__ import annotations
import hashlib,json,pathlib,struct,sys,time,urllib.request

DEST=pathlib.Path(sys.argv[1] if len(sys.argv)>1 else "qa-stage/ota177/canglan_rev187")
DEST.mkdir(parents=True,exist_ok=True)
FILES={
 "hair_gltf":("fastrouter/experiments-costa-vista",
   "23e87108a281ac827e2ea23691aa7bf4b544146e",
   "public/assets/toon/hair/Hair_Long.gltf",
   "b7d6ed1f1b1ca23e7224dab7fd1254dc7e95f22c",18056),
 "hair_bin":("fastrouter/experiments-costa-vista",
   "23e87108a281ac827e2ea23691aa7bf4b544146e",
   "public/assets/toon/hair/Hair_Long.bin",
   "6dd35df4eb7157b51dff4f537a0e2191e778b0ab",181756),
 "sword":("ilrein/warptracker",
   "71bbfbdfacd118196994b26da68eec1876d55c6b",
   "public/models/sword.glb",
   "d80d47cf6ac49ae72805ba992bccc2431dcfcbfc",28420),
}
def retrieve(key: str) -> bytes:
    repo,sha,path,blob,size=FILES[key]
    url=f"https://raw.githubusercontent.com/{repo}/{sha}/{path}"
    for n in range(3):
        try:
            with urllib.request.urlopen(url,timeout=30) as response:
                content=response.read(4_000_001)
            break
        except Exception:
            if n==2: raise
            time.sleep(2)
    actual=hashlib.sha1(b"blob "+str(len(content)).encode()+b"\0"+content).hexdigest()
    if len(content)!=size or actual!=blob:
        raise ValueError(f"BLOCKED_CC0_SOURCE_MISMATCH_{key} expected {blob} got {actual}")
    print("PASS_CC0_IMMUTABLE_GIT_SOURCE",key,len(content),
          hashlib.sha256(content).hexdigest())
    return content
def pad4(data: bytes,byte: bytes) -> bytes:
    return data+byte*((-len(data))%4)
gltf=json.loads(retrieve("hair_gltf").decode("utf-8"))
binary=retrieve("hair_bin")
if len(gltf["meshes"])!=1 or gltf["meshes"][0]["name"]!="Hair_Long":
    raise ValueError("BLOCKED_UNEXPECTED_HAIR_GEOMETRY")
if len(gltf["buffers"])!=1 or len(binary)!=gltf["buffers"][0]["byteLength"]:
    raise ValueError("BLOCKED_HAIR_VERTEX_BUFFER_CHANGED")
pos=gltf["accessors"][gltf["meshes"][0]["primitives"][0]["attributes"]["POSITION"]]
assert pos["count"]>=2500 and 1.48<pos["min"][1]<1.60 and 1.70<pos["max"][1]<1.85
for prim in gltf["meshes"][0]["primitives"]:
    # Convert licensed skin-weighted existing hairstyle into a rigid attached
    # preview: preserve POSITION / NORMAL / UV / INDICES byte-for-byte.
    prim["attributes"].pop("JOINTS_0",None)
    prim["attributes"].pop("WEIGHTS_0",None)
gltf.pop("skins",None)
gltf["nodes"]=[{"name":"LicensedQuaterniusHairLongStaticHeadAttachment","mesh":0}]
gltf["scenes"]=[{"name":"ActualCC0HairLong","nodes":[0]}]
gltf["scene"]=0
gltf["buffers"]=[{"byteLength":len(binary)}]
gltf["asset"]["generator"]="CC0 Quaternius hair original vertices; static GLB wrapper only"
j=pad4(json.dumps(gltf,separators=(",",":"),ensure_ascii=False).encode()," ".encode())
b=pad4(binary,b"\0")
result=struct.pack("<4sII",b"glTF",2,12+8+len(j)+8+len(b))
result+=struct.pack("<I4s",len(j),b"JSON")+j
result+=struct.pack("<I4s",len(b),b"BIN\0")+b
outfile=DEST/"quaternius_hair_long_static.glb"
outfile.write_bytes(result)
sword=retrieve("sword")
if sword[:4]!=b"glTF" or len(sword)<20000:
    raise ValueError("BLOCKED_SWORD_NOT_REAL_GLTF")
(DEST/"quaternius_knight_sword.glb").write_bytes(sword)
manifest={
 "schema":1,
 "output_hair_glb":{"path":str(outfile),"bytes":len(result),
                    "sha256":hashlib.sha256(result).hexdigest()},
 "output_sword_glb":{"bytes":len(sword),
                     "sha256":hashlib.sha256(sword).hexdigest()},
 "license":"CC0-1.0",
 "upstream_pack_hair":"https://quaternius.com/packs/universalbasecharacters.html",
 "upstream_pack_sword":"https://quaternius.com/packs/knightcharacter.html",
 "packaging_hair":"static 3D GLB conversion of existing licensed 3080-vertex haircut, not self-modeled",
 "packaging_sword":"unmodified public CC0 converted GLB"
}
(DEST/"rev199_cc0_asset_provenance.json").write_text(
    json.dumps(manifest,ensure_ascii=False,indent=2)+"\n")
print("PASS_REV199_REAL_CC0_HAIR_AND_SWORD_BINARY_ASSETS_READY",len(result),len(sword))
