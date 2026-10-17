#!/usr/bin/env python3
"""REV206: acquire only audited upstream Quaternius CC0 binary GLBs.

Security policy: fixed paths, pinned Git blob SHA-1, exact byte count, GLB2
header + internal JSON validation, per-file hard caps and overall quota.
NEVER generate/manufacture new architecture, characters or animal meshes.
NEVER silently fill an unavailable binary with substitute procedural meshes.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import struct
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "game-source/apk176-ota177-candidate/assets/cc0-rev206/asset_manifest.json"
SOURCE = "https://raw.githubusercontent.com/Papyszoo/CC0-Public-Domain-Models/main/"


def import_source(model: dict) -> dict:
    dest = ROOT / model["destination"]
    dest.resolve().relative_to(ROOT)
    assert dest.suffix == ".glb" and "/cc0-rev206/" in str(dest)
    assert model["upstream_path"].startswith("packs/quaternius-")
    assert model["upstream_path"].endswith("/" + model["name"] + ".glb")
    assert 1000 < int(model["bytes"]) <= 8_000_000
    req = Request(SOURCE + model["upstream_path"],
                  headers={"User-Agent": "Canglan-CC0-Source-Importer/206"})
    with urlopen(req, timeout=90) as stream:
        data = stream.read(int(model["bytes"]) + 1)
    if len(data) != int(model["bytes"]):
        raise ValueError(f"Unexpected asset byte length: {model['name']}")
    actual_git_sha1 = hashlib.sha1(
        ("blob %d\0" % len(data)).encode() + data
    ).hexdigest()
    if actual_git_sha1 != model["blob_sha1"]:
        raise ValueError(f"Source art changed: {model['name']} {actual_git_sha1}")
    if data[:4] != b"glTF" or len(data) < 20:
        raise ValueError("Not original 3D glTF binary: " + model["name"])
    version, file_length = struct.unpack_from("<II", data, 4)
    chunk_len, chunk_type = struct.unpack_from("<II", data, 12)
    if version != 2 or file_length != len(data) or chunk_type != 0x4E4F534A:
        raise ValueError("Invalid native GLB2 header: " + model["name"])
    if not 2 <= chunk_len <= len(data) - 20:
        raise ValueError("Invalid embedded GLB JSON: " + model["name"])
    metadata = json.loads(data[20:20 + chunk_len].decode("utf-8"))
    if not metadata.get("meshes") or not metadata.get("nodes"):
        raise ValueError("No actual source mesh/node: " + model["name"])
    if len(metadata.get("meshes", [])) > 10000 or len(data) > 8_000_000:
        raise ValueError("Excessive complexity: " + model["name"])
    for buffer in metadata.get("buffers", []):
        if buffer.get("uri"):
            raise ValueError("GLB has unsafe/missing external source: " + model["name"])
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(data)
    return {"name": model["name"], "sha256": hashlib.sha256(data).hexdigest(),
            "source_blob_sha1": actual_git_sha1, "bytes": len(data),
            "meshes": len(metadata["meshes"]), "animations": len(metadata.get("animations", [])),
            "materials": len(metadata.get("materials", [])), "license": "CC0-1.0",
            "role": model["role"], "path": model["destination"]}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--max-total-mb", type=int, default=20)
    options = parser.parse_args()
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    assert manifest["schema"] == 206 and manifest["license"] == "CC0-1.0"
    assert len(manifest["models"]) >= 12
    assert sum(int(i["bytes"]) for i in manifest["models"]) <= (
        options.max_total_mb * 1024 * 1024)
    by_id: set[str] = set()
    completed: list[dict] = []
    for model in manifest["models"]:
        key = model["pack"] + "/" + model["name"]
        assert key not in by_id
        by_id.add(key)
        completed.append(import_source(model))
    output = MANIFEST.parent / "asset_intake_proof.json"
    output.write_text(json.dumps({"schema":206, "source":SOURCE,
        "asset_total":len(completed),"total_bytes":sum(x["bytes"] for x in completed),
        "committed_under_license":"CC0-1.0","models":completed},
        ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print("PASS_REV206_SOURCE_PINNED_GENUINE_LICENSED_3D_BUILDINGS_CLOTHING_ANIMALS_MONSTERS",
        len(completed),sum(i["bytes"] for i in completed))


if __name__ == "__main__":
    main()
