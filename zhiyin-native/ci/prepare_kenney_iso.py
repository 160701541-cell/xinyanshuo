"""Extract only selected CC0 Kenney 2D isometric furniture sprites into Android assets.
Source: https://opengameart.org/content/furniture-kit  (Kenney, CC0).
Inputs are pinned later by asset archive SHA-256 in the Gradle workflow.
No executable code is imported from archives.
"""
from pathlib import Path
import hashlib
import sys
import zipfile

source = Path(sys.argv[1])
target = Path("app/src/main/assets/kenney")
target.mkdir(parents=True, exist_ok=True)
source_sha = hashlib.sha256(source.read_bytes()).hexdigest()
print("Kenney Furniture Kit source ZIP sha256:", source_sha)
wanted = {
    "wardrobe": "bookcaseClosedDoors_SE.png",
    "bed": "bedSingle_SE.png",
    "books": "bookcaseOpen_SE.png",
    "kitchen": "kitchenStove_SE.png",
    "wash": "bathroomSink_SE.png",
    "desk": "table_SE.png",
    "plant": "pottedPlant_SE.png",
    "sofa": "loungeSofa_SE.png",
    "lamp": "lampSquareCeiling_SE.png",
}
with zipfile.ZipFile(source) as z:
    for name, member in wanted.items():
        key = "Isometric/" + member
        if key not in z.namelist():
            raise SystemExit("Missing required Kenney CC0 sprite: "+key)
        data = z.read(key)
        if not data.startswith(b"\x89PNG\r\n\x1a\n"):
            raise SystemExit("Asset is not a valid PNG: " + key)
        out = target / (name + ".png")
        out.write_bytes(data)
        print("asset", name, "source", key, "size", len(data))
print("Baked", len(wanted), "CC0 sprites into Android native assets directory")
