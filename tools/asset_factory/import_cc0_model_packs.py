#!/usr/bin/env python3
"""Fetch REAL existing CC0 low-poly 3D models for Canglan Godot 4.4.

Sources: specific Kenney packs + Quaternius free Standard kit; exact mirror
git commit/blob SHA pinned to prevent asset substitution. The actual pack
license is on the original creator's site; mirrors are transparent download
transport only. No AI generation and NO private repository.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import tempfile
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
CATALOG = ROOT / "game-source/godot3d/opensource/cc0_asset_catalog.json"
OUTPUT = ROOT / "game-source/godot3d/assets/free_cc0"


def checked_rel_path(raw: str) -> PurePosixPath:
    relative = PurePosixPath(raw)
    if not relative.parts or relative.is_absolute() or any(
        part in ("", "..", ".") or part.startswith(".") for part in relative.parts
    ):
        raise ValueError(f"Unsafe asset pathname: {raw}")
    if str(relative) != raw or len(relative.parts) > 5:
        raise ValueError(f"Noncanonical asset path: {raw}")
    return relative


def git_blob_sha1(binary: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(binary)).encode() + b"\x00" + binary).hexdigest()


def validate_gltf_references(source_root: Path, pack: dict) -> None:
    """Every Quaternius glTF URI must resolve to a pinned local sidecar."""
    listed = {entry["path"] for entry in pack["files"]}
    for record in pack["files"]:
        if not record["path"].endswith(".gltf"):
            continue
        path = source_root / record["path"]
        data = json.loads(path.read_text(encoding="utf-8"))
        assert data.get("asset", {}).get("version", "").startswith("2.")
        dependencies = [
            entry["uri"] for kind in ("images", "buffers")
            for entry in data.get(kind, []) if "uri" in entry
        ]
        for item in dependencies:
            if item.startswith("data:"):
                continue
            target = (PurePosixPath(record["path"]).parent / item)
            if str(target) not in listed:
                raise AssertionError(f"Unpinned dependency: {path} -> {item}")
            if not (source_root / str(target)).is_file():
                raise AssertionError(f"Missing glTF dependency: {target}")


def fetch_one(url: str, path: Path, expected_git_sha: str, expected_length: int) -> dict:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.is_file():
        raw = path.read_bytes()
        if len(raw) == expected_length and git_blob_sha1(raw) == expected_git_sha:
            return {"size": len(raw), "sha256": hashlib.sha256(raw).hexdigest()}
        raise ValueError(f"Local file differs from pinned CC0 source; do not overwrite: {path}")
    request = urllib.request.Request(url, headers={
        "User-Agent": "Canglan-Open-Source-CC0-Audit/1.0"})
    with urllib.request.urlopen(request, timeout=85) as response:
        if response.status != 200:
            raise OSError(f"HTTP error {response.status}")
        # Abort oversized server payload before touching the target destination.
        raw = response.read(expected_length + 1)
    if len(raw) != expected_length or git_blob_sha1(raw) != expected_git_sha:
        raise ValueError(f"Source mirror bytes failed pinned git blob verification: {path.name}")
    with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as temp:
        temp.write(raw)
        temp_path = Path(temp.name)
    try:
        temp_path.replace(path)
    finally:
        temp_path.unlink(missing_ok=True)
    return {"size": len(raw), "sha256": hashlib.sha256(raw).hexdigest()}


def stage(catalog_path: Path = CATALOG, destination: Path = OUTPUT) -> dict:
    catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    if catalog.get("schema") != 1:
        raise ValueError("Unknown third-party model catalog")
    summary = {"schema": 1, "asset_type": "REAL_EXISTING_CC0_MODELS",
               "stage": "IMPORTED_CANDIDATE_PENDING_VISUAL_AND_PHONE_QA",
               "assets": [], "sources": []}
    for pack in catalog["sources"]:
        if pack["id"] not in ("kenney", "quaternius", "quaternius_humanoid", "quaternius_knight") or pack["license"] != "CC0-1.0":
            raise ValueError("Unapproved pack licensing or provenance")
        repo = pack["mirror_repository"]
        commit = pack["mirror_commit"]
        if not (len(commit) == 40 and all(c in "0123456789abcdef" for c in commit)):
            raise ValueError("Unpinned mirror source commit")
        if repo not in ("shorepine/kenney", "J-Ponzo/gltf-medieval-village-megakit",\n                        "programasweights/avatar", "ilrein/warptracker"):
            raise ValueError("Unknown mirror: "+repo)
        folder = destination / pack["id"]
        pack_assets = []
        for asset in pack["files"]:
            path_str = asset["path"]
            relative = checked_rel_path(path_str)
            url = f"https://raw.githubusercontent.com/{repo}/{commit}/{path_str}"
            sha = asset["git_blob_sha1"]
            if len(sha) != 40 or any(x not in "0123456789abcdef" for x in sha):
                raise ValueError("Bad pinned Git SHA for "+path_str)
            size = int(asset["bytes"])
            if not 400 < size <= 9_000_000:
                raise ValueError("Model exceeds mobile import budget: "+path_str)
            result = fetch_one(url, folder / str(relative), sha, size)
            pack_assets.append({"file": str(relative), "sha256": result["sha256"],
                                "bytes": result["size"], "git_blob_sha1": sha,
                                "license": "CC0-1.0",
                                "origin_website": pack["upstream_official"],
                                "mirror_transport_commit": commit})
            print("CC0_SOURCE_VERIFIED", pack["id"], relative, size, flush=True)
        validate_gltf_references(folder, pack)
        summary["sources"].append({"source":pack["id"],"official":pack["upstream_official"],
                                  "mirror_repo":repo,"mirror_commit":commit,
                                  "asset_license":"CC0-1.0"})
        summary["assets"].extend(
            [{"supplier":pack["id"],**entry} for entry in pack_assets])
    # Ensure EVERY source and SHA passed before publishing any provenance.
    assert any(a["supplier"] == "quaternius_humanoid" for a in summary["assets"])
    assert any(a["supplier"] == "quaternius_knight" for a in summary["assets"])
    summary["character_paths"] = catalog["import_plan"]["characters"]
    summary["world_effect"] = "SCENERY_AND_NPC_APPEARANCE_ONLY; NO PREBUILT_VILLAGE"
    summary["original_phone_signed_pck"] = "NOT_RELEASED"
    destination.mkdir(parents=True,exist_ok=True)
    (destination / "import_provenance.json").write_text(
        json.dumps(summary, indent=2, ensure_ascii=False)+"\n",encoding="utf-8")
    print("PASS_REAL_EXISTING_CC0_3D_ASSET_LIBRARY_IMPORTED",
          len(summary["assets"]),flush=True)
    return summary


if __name__ == "__main__":
    p=argparse.ArgumentParser()
    p.add_argument("--catalog",type=Path,default=CATALOG)
    p.add_argument("--out",type=Path,default=OUTPUT)
    args=p.parse_args()
    stage(args.catalog,args.out)
