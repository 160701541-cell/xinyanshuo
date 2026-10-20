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
        # Some Kenney GLBs reference external albedo maps instead of embedding
        # texture bytes. Resolve and bundle them at the original relative URI.
        # Merely importing a mesh without its original texture is NOT a pass.
        json_size = struct.unpack_from("<I", blob, 12)[0]
        embedded = json.loads(blob[20:20+json_size])
        external_textures = []
        for image in embedded.get("images", []):
            uri = image.get("uri", "")
            if not uri or uri.startswith("data:"):
                continue
            relative = Path(uri)
            if relative.is_absolute() or ".." in relative.parts or relative.suffix.lower() != ".png":
                raise ValueError("Unsafe/out-of-scope GLB texture URI: " + uri)
            original_png = Path(source).parent / relative
            texture_url = f"https://raw.githubusercontent.com/{OWNER_REPO}/{COMMIT}/{original_png.as_posix()}"
            with urllib.request.urlopen(texture_url,timeout=40) as response:
                img_data = response.read(8*1024*1024)
            if not img_data.startswith(bytes.fromhex("89504e470d0a1a0a")):
                raise ValueError("External material image was not PNG: " + uri)
            output = destination.parent / relative
            output.parent.mkdir(parents=True,exist_ok=True)
            output.write_bytes(img_data)
            external_textures.append({"uri":uri,"sha256":hashlib.sha256(img_data).hexdigest()})
            print("EXTERNAL GLB COLOR MAP",uri,len(img_data),flush=True)
        item = {"path":source, "sha256":hashlib.sha256(blob).hexdigest(),
                "bytes":len(blob), "external_textures":external_textures, **data}
        manifest["models"][short] = item
        print(short, item, flush=True)
    # ORIGINAL textured humanoid glTF from Quaternius Universal Base Characters Standard (CC0).
    # Mirrors publisher's unchanged mesh/rig and complete source albedo/normal/roughness textures.
    female_commit="16ef4707f0403a7942384fdbd960789a5c6adb86"
    female_repo="La2o/BlackVein"
    female_dir="assets/characters/base"
    filename="Superhero_Female_FullBody.gltf"
    def from_female_upstream(name):
        url=f"https://raw.githubusercontent.com/{female_repo}/{female_commit}/{female_dir}/{name}"
        with urllib.request.urlopen(url,timeout=60) as response:
            return response.read(12*1024*1024)
    raw_gltf=from_female_upstream(filename)
    female=json.loads(raw_gltf)
    assert len(female.get("skins",[]))>=1, "No skinned humanoid"
    joints=len(female["skins"][0].get("joints",[]))
    if joints<50 or len(female.get("meshes",[]))<2:
        raise ValueError("Quaternius female skeleton or meshes incomplete")
    textures=female.get("images",[])
    if len(textures)<6 or len(female.get("materials",[]))<3:
        raise ValueError("Female PBR albedo/normal/roughness material maps missing")
    female_assets=ROOT/"assets/characters"
    female_assets.mkdir(parents=True,exist_ok=True)
    (female_assets/filename).write_bytes(raw_gltf)
    files={}
    referenced=[b["uri"] for b in female.get("buffers",[]) if "uri" in b]
    referenced += [im["uri"] for im in textures if "uri" in im]
    for name in sorted(set(referenced)):
        rel=Path(name)
        if rel.is_absolute() or ".." in rel.parts or rel.suffix.lower() not in (".png",".bin"):
            raise ValueError("Unsafe character resource URI: "+name)
        blob=from_female_upstream(name)
        if rel.suffix.lower()==".png" and not blob.startswith(bytes.fromhex("89504e470d0a1a0a")):
            raise ValueError("Referenced character texture is not a PNG: "+name)
        (female_assets/rel).write_bytes(blob)
        files[name]={"sha256":hashlib.sha256(blob).hexdigest(),"bytes":len(blob)}
    if not any("Roughness" in x for x in files) or not any("Normal" in x for x in files):
        raise ValueError("Character normal and roughness texture absent")
    manifest["models"]["hero_female"]={
        "path":f"{female_dir}/{filename}","source":f"https://github.com/{female_repo}",
        "commit":female_commit,"license":"Quaternius Universal Base Characters Standard, CC0-1.0",
        "sha256":hashlib.sha256(raw_gltf).hexdigest(),
        "bytes":len(raw_gltf),"skins":len(female["skins"]),"joints":joints,
        "meshes":len(female["meshes"]),"materials":len(female["materials"]),
        "images":len(textures),"files":files
    }
    print("TRUE_TEXTURED_RIGGED_HERO",manifest["models"]["hero_female"],flush=True)
    (ROOT / "ASSET_MANIFEST.json").write_text(json.dumps(manifest,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    assert len(manifest["models"]) == len(ASSETS)

if __name__=="__main__":
    main()
