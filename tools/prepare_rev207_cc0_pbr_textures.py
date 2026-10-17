#!/usr/bin/env python3
"""Build nine MOBILE-sized genuine Quaternius CC0 PBR maps.

The original diffuse/normal/ORM/roughness bitmaps are already in the
official Canglan source checkout. Every original Git blob SHA1 is pinned.
Only BaseColor is color-graded; NEVER recolor tangent normal or roughness.
No invented generic image can quietly substitute a missing source PNG.
"""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageEnhance

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "game-source/godot3d/assets/free_cc0/quaternius/glTF"
DEST = ROOT / "game-source/apk176-ota177-candidate/materials/rev207"
PIN = {
 "plaster_albedo.png":("T_Plaster_BaseColor.png","14ff755f0dc786a775faea8eb9d51ef1e4dcd613"),
 "plaster_normal.png":("T_Plaster_Normal.png","2acb6dca1684544e4a99eb19aff8892c0c2ee232"),
 "plaster_orm.png":("T_Plaster_ORM.png","460dbd52ccfb6ab72eaa4223c889f24b6f659cfa"),
 "tile_albedo.png":("T_RoundTiles_BaseColor.png","1499f2b4d6eda2da8ca7512c342ed29632cf3d1e"),
 "tile_normal.png":("T_RoundTiles_Normal.png","abf6b84678b40f1bdbb5f557c73414d8568bfa15"),
 "tile_roughness.png":("T_RoundTiles_Roughness.png","625b67a09c51c5db00c8500bb473002d8fc82367"),
 "timber_albedo.png":("T_WoodTrim_BaseColor.png","3547da835b7b1aa89e27e98c68b1582bd203ef93"),
 "timber_normal.png":("T_WoodTrim_Normal.png","f959c6344604f28800497bb276f70043aee0fea2"),
 "timber_roughness.png":("T_WoodTrim_Roughness.png","0dd5136db0bac8f968604a8a1bebfa47b4ea776f"),
}
TARGET_RESOLUTION=512
MAX_OUTPUT_BYTES=9*1024*1024


def original_sha1(raw: bytes) -> str:
    return hashlib.sha1(f"blob {len(raw)}\0".encode()+raw).hexdigest()


def main() -> None:
    DEST.mkdir(parents=True,exist_ok=True)
    result=[]
    for dst,(src,expected_sha) in PIN.items():
        path=SOURCE/src
        raw=path.read_bytes()
        actual=original_sha1(raw)
        if actual!=expected_sha:
            raise RuntimeError(f"Changed upstream CC0 PBR source: {src} {actual}")
        with Image.open(path) as opened:
            if opened.width<512 or opened.height<512:
                raise RuntimeError(f"Source resolution too small: {src}")
            img=opened.convert("RGB")
            img.thumbnail((TARGET_RESOLUTION,TARGET_RESOLUTION),Image.Resampling.LANCZOS)
            if img.size!=(512,512):
                # Real source maps must have square UV layout, not stretched.
                raise RuntimeError(f"Non-square source refused: {src} {img.size}")
            if dst.endswith("_albedo.png"):
                # Vivid yet restrained source-faithful chroma adjustment.
                img=ImageEnhance.Color(img).enhance(1.24)
                img=ImageEnhance.Contrast(img).enhance(1.055)
                img=ImageEnhance.Brightness(img).enhance(0.955)
            img.save(DEST/dst,optimize=True,compress_level=9)
        data=(DEST/dst).read_bytes()
        result.append({
            "file":dst,"source":src,"source_blob_sha1":expected_sha,
            "output_sha256":hashlib.sha256(data).hexdigest(),
            "bytes":len(data),"width":512,"height":512,
            "role":"albedo" if dst.endswith("_albedo.png") else (
                "normal" if dst.endswith("_normal.png") else (
                "orm" if dst.endswith("_orm.png") else "roughness")),
            "license":"CC0-1.0",
        })
    total=sum(m["bytes"] for m in result)
    if total>MAX_OUTPUT_BYTES:
        raise RuntimeError(f"Mobile PBR material pack too heavy: {total}")
    manifest={
        "schema":207,"source":"Quaternius CC0 original PBR source PNGs",
        "source_directory":str(SOURCE.relative_to(ROOT)),
        "license":"CC0-1.0","size":512,"count":len(result),
        "bytes":total,"maps":result,
        "modification":"512x512 Lanczos preserving original normal/roughness; 1.24x chroma & restrained contrast on albedo only",
    }
    (DEST/"manifest.json").write_text(json.dumps(
        manifest,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print("PASS_REV207_REAL_SOURCE_VERIFIED_QUATERNIUS_NINE_PBR_MAPS_512PX",total)


if __name__=="__main__":
    main()
