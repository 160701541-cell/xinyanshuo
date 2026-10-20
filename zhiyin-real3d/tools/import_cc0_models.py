#!/usr/bin/env python3
"""Download pin-locked CC0 Kenney glTF/GLB furniture & characters into the Godot project.

This is a *model* pipeline, not Kenney's 2D isometric PNG render pipeline.
Verify glTF structure, embedded materials and license provenance before packaging.
"""
from pathlib import Path
import hashlib, json, struct, urllib.request

OWNER_REPO = "shorepine/kenney"
COMMIT = "3694c6879e487c108f55677be7dd2ca75b07cc3b"
ROOT = Path(__file__).resolve().parent.parent
ASSETS = {
    "bed": "3d/furniture/bedSingle.glb",
    "dresser": "3d/furniture/bookcaseClosedDoors.glb",
    "bookshelf": "3d/furniture/bookcaseOpen.glb",
    "desk": "3d/furniture/desk.glb",
    "chair": "3d/furniture/chairCushion.glb",
    "sofa": "3d/furniture/loungeSofa.glb",
    "fridge": "3d/furniture/kitchenFridgeSmall.glb",
    "stove": "3d/furniture/kitchenStove.glb",
    "sink": "3d/furniture/kitchenSink.glb",
    "plant": "3d/furniture/pottedPlant.glb",
    "floorlamp": "3d/furniture/lampRoundFloor.glb",
    "box": "3d/furniture/cardboardBoxClosed.glb",
    "rug": "3d/furniture/rugRectangle.glb",
    "table": "3d/furniture/tableCoffee.glb",
    "book": "3d/furniture/books.glb",
    "bathroom": "3d/furniture/bathroomSink.glb",
    # A REAL 3D mesh, but not a substitute for the requested high-fidelity
    # humanoid with humanoid bone rig / expressions / motion capture.
    "prototype_character": "3d/blocky-characters/character-f.glb",
}

def read_gltf_metadata(data: bytes):
    if len(data) < 20 or data[:4] != b"glTF":
        raise ValueError("Not a binary glTF/GLB header")
    version, declared_length = struct.unpack_from("<II", data, 4)
    if version != 2 or declared_length != len(data):
        raise ValueError("Corrupt/incomplete GLB container")
    count, chunk_type = struct.unpack_from("<II", data, 12)
    if chunk_type != 0x4E4F534A or count < 2 or count > len(data)-20:
        raise ValueError("No glTF JSON chunk in GLB")
    gltf = json.loads(data[20:20+count])
    if not gltf.get("meshes") or not gltf.get("nodes"):
        raise ValueError("GLB must include real 3D mesh and scene nodes")
    if not gltf.get("materials"):
        raise ValueError("GLB must contain its real materials, not a blank prop")
    materials = gltf["materials"]
    return dict(
        meshes=len(gltf.get("meshes", [])), nodes=len(gltf.get("nodes", [])),
        materials=len(materials), skins=len(gltf.get("skins", [])),
        animations=len(gltf.get("animations", [])), textures=len(gltf.get("textures", [])),
        pbr_metallic_roughness=sum("pbrMetallicRoughness" in m for m in materials),
    )

def main():
    targets = ROOT / "assets/models"
    targets.mkdir(parents=True, exist_ok=True)
    manifest = {"license":"CC0-1.0", "source":f"https://github.com/{OWNER_REPO}",
                "commit":COMMIT, "models":{}}
    for short, source in ASSETS.items():
        destination = targets / (short + ".glb")
        url = f"https://raw.githubusercontent.com/{OWNER_REPO}/{COMMIT}/{source}"
        with urllib.request.urlopen(urllib.request.Request(url,headers={"User-Agent":"ZhiYin-Godot-AssetImporter/0.1"}), timeout=40) as r:
            blob = r.read(6 * 1024 * 1024)
        data = read_gltf_metadata(blob)
        destination.write_bytes(blob)
        item = {"path":source, "sha256":hashlib.sha256(blob).hexdigest(), "bytes":len(blob), **data}
        manifest["models"][short] = item
        print(short, item, flush=True)
    (ROOT / "ASSET_MANIFEST.json").write_text(json.dumps(manifest,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    assert len(manifest["models"]) == len(ASSETS)

if __name__=="__main__":
    main()
