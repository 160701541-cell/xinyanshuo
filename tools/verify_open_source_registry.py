#!/usr/bin/env python3
"""CAC-OSS-001: fail closed before importing or shipping open-source dependencies.

This verifies *claims and locally integrated files*, not external web licenses or
artistic quality. Assets cannot be approved without license evidence + pinned hash.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath

PERMITTED_RUNTIME = frozenset(
    {"MIT", "Apache-2.0", "BSD-3-Clause", "BSD-2-Clause", "ISC", "CC0-1.0"}
)
PERMITTED_TOOL = PERMITTED_RUNTIME | {"GPL-3.0-or-later", "GPL-3.0-only"}
ALLOWED_STATUSES = frozenset({"ACTIVE", "CANDIDATE_NOT_IMPORTED"})
ASSET_TYPES = frozenset({"optional-asset-source", "asset"})
REGISTRY = "game-source/hd2d-world/opensource/registry.json"


class OpenSourceGateError(ValueError):
    pass


def _rel(root: Path, name: str) -> Path:
    if not isinstance(name, str) or not name or "\\" in name:
        raise OpenSourceGateError(f"Unsafe resource path: {name!r}")
    p = PurePosixPath(name)
    if p.is_absolute() or ".." in p.parts or "." in p.parts or ":" in name:
        raise OpenSourceGateError(f"Resource path traversal: {name!r}")
    resolved = (root / str(p)).resolve()
    if not resolved.is_relative_to(root.resolve()):
        raise OpenSourceGateError("Resource escapes repository: " + name)
    return resolved


def verify(root: Path, data: dict | None = None) -> dict:
    root = root.resolve()
    if data is None:
        data = json.loads(_rel(root, REGISTRY).read_text("utf-8"))
    if data.get("schema") != 1 or data.get("policy") != "CAC-OSS-001":
        raise OpenSourceGateError("Bad OSS contract/schema")
    entries = data.get("entries")
    if not isinstance(entries, list) or len(entries) < 3:
        raise OpenSourceGateError("Missing real, audited open source runtime entries")
    ids = set()
    active = 0
    candidates = 0
    for item in entries:
        if not isinstance(item, dict):
            raise OpenSourceGateError("Invalid registry record")
        uid = item.get("id")
        if not isinstance(uid, str) or not uid or uid in ids:
            raise OpenSourceGateError(f"Duplicate or missing dependency ID: {uid!r}")
        ids.add(uid)
        kind, status = item.get("kind"), item.get("status")
        if kind not in {"engine", "bundled-engine-component", "optional-asset-source", "optional-build-tool", "asset"}:
            raise OpenSourceGateError(f"{uid}: invalid kind")
        if status not in ALLOWED_STATUSES:
            raise OpenSourceGateError(f"{uid}: invalid status")
        license_id = item.get("license")
        permitted = PERMITTED_TOOL if kind == "optional-build-tool" else PERMITTED_RUNTIME
        if license_id not in permitted:
            raise OpenSourceGateError(f"{uid}: license not safely approved: {license_id}")
        for field in ("source", "license_proof"):
            link = item.get(field)
            if not isinstance(link, str) or not link.startswith("https://") or any(c.isspace() for c in link):
                raise OpenSourceGateError(f"{uid}: invalid {field}")
        used = item.get("used_by")
        if not isinstance(used, list):
            raise OpenSourceGateError(f"{uid}: used_by must be a list")
        if status == "CANDIDATE_NOT_IMPORTED":
            candidates += 1
            if used or "sha256" in item or "asset_path" in item:
                raise OpenSourceGateError(f"{uid}: candidate masquerading as installed asset")
            continue
        active += 1
        if not used:
            raise OpenSourceGateError(f"{uid}: ACTIVE component not integrated")
        for p in used:
            if not _rel(root, p).is_file():
                raise OpenSourceGateError(f"{uid}: declared integration missing {p}")
        if kind in ASSET_TYPES:
            p = item.get("asset_path")
            digest = item.get("sha256")
            if not isinstance(digest, str) or len(digest) != 64 or not all(c in "0123456789abcdef" for c in digest):
                raise OpenSourceGateError(f"{uid}: no verified asset SHA256")
            if not isinstance(p, str):
                raise OpenSourceGateError(f"{uid}: missing real asset path")
            asset = _rel(root, p)
            if not asset.is_file() or hashlib.sha256(asset.read_bytes()).hexdigest() != digest:
                raise OpenSourceGateError(f"{uid}: actual CC0 bytes missing or hash mismatch")
    if not {"godot-4.4.1", "fastnoiselite-native", "astargrid2d-native"}.issubset(ids):
        raise OpenSourceGateError("Godot native dependencies must be recorded")
    actual = _rel(root, "game-source/hd2d-world/scripts/oss_world_services.gd").read_text("utf-8")
    if "FastNoiseLite.new()" not in actual or "AStarGrid2D.new()" not in actual:
        raise OpenSourceGateError("Native OSS components not actually used")
    return {"gate": "PASS", "policy": "CAC-OSS-001", "active": active,
            "candidate_only": candidates, "embedded_third_party_asset_count": sum(
                1 for e in entries if e["status"] == "ACTIVE" and e["kind"] in ASSET_TYPES
            ), "note": "Source presence and local hashes only; Godot & visual/mobile QA separate"}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path("."))
    args = parser.parse_args()
    try:
        print(json.dumps(verify(args.root), ensure_ascii=False, sort_keys=True))
        return 0
    except (OpenSourceGateError, FileNotFoundError, json.JSONDecodeError) as exc:
        print(json.dumps({"gate": "BLOCKED", "reason": str(exc)}, ensure_ascii=False))
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
