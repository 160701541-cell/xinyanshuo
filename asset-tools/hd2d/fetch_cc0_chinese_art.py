#!/usr/bin/env python3
"""Verify downloadable CC0 Chinese architectural sources and inspect their actual files.

Source landing pages and licenses:
 https://store.godotengine.org/asset/vvaytoyek/chinese-four-corner-pavilion-free/
 https://store.godotengine.org/asset/vvaytoyek/chinese-classical-garden-wall/

Download URLs are official version-specific Godot Asset Store redirects to short-lived
signed archives, never store the signed CDN URLs. The original author is VVaytoyek.
This intake step does NOT mark art reviewed or install unreviewed archives as production.
"""
from __future__ import annotations
import hashlib
import json
import os
from pathlib import Path
import sys
import urllib.request
import zipfile

HERE = Path(__file__).resolve().parent
OUT = HERE.parent / "build" / "asset_intake"
OUT.mkdir(parents=True, exist_ok=True)

ASSETS = {
    "chinese_pavilion_cc0": (
        "https://store.godotengine.org/asset/vvaytoyek/chinese-four-corner-pavilion-free/download/1144/",
        2_000_000, 15_000_000
    ),
    "chinese_garden_wall_cc0": (
        "https://store.godotengine.org/asset/vvaytoyek/chinese-classical-garden-wall/download/1167/",
        10_000_000, 80_000_000
    ),
}

def get(name: str, url: str, minimum: int, maximum: int) -> dict:
    request = urllib.request.Request(url, headers={"User-Agent":"CanglanAssetIntake/1.0"})
    target = OUT / f"{name}.zip"
    try:
        with urllib.request.urlopen(request, timeout=90) as response, target.open("wb") as output:
            size = 0
            digest = hashlib.sha256()
            while True:
                part = response.read(1024 * 1024)
                if not part:
                    break
                size += len(part)
                if size > maximum:
                    raise ValueError(f"Archive size exceeded limit {maximum}")
                digest.update(part)
                output.write(part)
        if size < minimum:
            raise ValueError(f"Unexpectedly tiny file: {size} bytes")
        expected_sha256 = {
            "chinese_pavilion_cc0": "008fb5c4508ce57c4203e5763fd01a177ded16ca94fd5de34ea26c422b483efa",
            "chinese_garden_wall_cc0": "49478a1d43f1e4b11e6dc3d1e977011cdbba5a7b77ee56890f586166697da38e",
        }
        if digest.hexdigest() != expected_sha256[name]:
            raise ValueError("Source archive SHA256 changed: refuse unauthorized/model-content substitution")
        with zipfile.ZipFile(target) as z:
            found = []
            meshes = []
            for member in z.infolist():
                filename = member.filename.replace("\\", "/")
                if (filename.startswith("/") or ".." in filename.split("/") or
                    member.file_size > 120_000_000):
                    raise ValueError(f"Unsafe archive entry: {filename}")
                if member.is_dir():
                    continue
                found.append({"path":filename, "bytes":member.file_size})
                if Path(filename).suffix.lower() in (".glb",".gltf",".fbx",".obj",".blend",".dae",".tscn"):
                    meshes.append(filename)
            if not meshes:
                raise ValueError("Archive contains no usable Blender/glTF/Godot model file")
        return {"asset":name, "status":"downloaded_inspected", "archive_sha256":digest.hexdigest(),
                "archive_bytes":size, "source_download_endpoint":url,
                "format_candidates":meshes, "file_count":len(found), "files":found[:250]}
    except Exception as e:
        if target.exists():
            target.unlink()
        return {"asset":name, "status":"FAILED", "error":str(e), "source_download_endpoint":url}

def main() -> int:
    manifest = [get(name,*data) for name,data in ASSETS.items()]
    result = {"origin":"Godot Asset Store", "publisher":"VVaytoyek",
              "public_license":"CC0 1.0 (verify included license file before redistributing)",
              "sources":manifest, "notice":"Downloaded candidates are not approved for production or final visuals."}
    path = OUT / "intake.json"
    path.write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding="utf8")
    for item in manifest:
        print(f"=== {item['asset']}: {item['status']} ===")
        if item["status"] == "downloaded_inspected":
            print(f"sha256={item['archive_sha256']} bytes={item['archive_bytes']}")
            print("Candidates:")
            for candidate in item["format_candidates"][:100]:
                print("  " + candidate)
        else:
            print("ERROR:",item["error"])
    print("Report:",path)
    return 0 if all(x["status"]=="downloaded_inspected" for x in manifest) else 1

if __name__=="__main__":
    sys.exit(main())
