#!/usr/bin/env python3
"""rev208 P0-HQ-ECOLOGY：把已入库的 CC0 地表 PBR 与地被资产装进真实 PCK 树。

用途（本机 QA 与 GitHub Actions 共用同一份逻辑，不允许 CI 走另一套）：

    python3 tools/stage_rev208_hq_ecology.py --dest qa-stage/ota177

目标目录结构（与 res:// 路径一一对应）：

    <dest>/canglan_rev187/hq_ecology_terrain/<slug>/*.jpg
    <dest>/canglan_rev187/hq_ecology_terrain/ecology-intake-provenance.json
    <dest>/canglan_rev187/hq_ecology_groundcover/<slug>/*
    <dest>/canglan_rev187/hq_terrain_pbr.gd

每个文件都会按 manifest 重新计算 SHA256，和记录值不一致就退出非 0。
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
ASSETS = REPO / "game-source/apk176-ota177-candidate/assets/hq-rev208"
TERRAIN = ASSETS / "terrain"
GROUNDCOVER = ASSETS / "vegetation/groundcover"
PROVENANCE = ASSETS / "ecology-intake-provenance.json"
SCRIPT = REPO / "game-source/apk176-ota177-candidate/scripts/apk176_hq_terrain_pbr_rev208.gd"
VIVID = REPO / "game-source/apk176-ota177-candidate/scripts/apk176_vivid_material_rev207.gd"

RES_TERRAIN = "canglan_rev187/hq_ecology_terrain"
RES_GROUNDCOVER = "canglan_rev187/hq_ecology_groundcover"
RES_SCRIPT = "canglan_rev187/hq_terrain_pbr.gd"
RES_VIVID = "canglan_rev187/vivid_material.gd"


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for block in iter(lambda: fh.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def fail(msg: str) -> None:
    print(f"FAIL rev208 hq ecology stage: {msg}", file=sys.stderr)
    raise SystemExit(1)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dest", required=True, help="Godot 工程根目录（PCK 树根）")
    args = ap.parse_args()

    dest = Path(args.dest)
    if not dest.is_dir():
        fail(f"dest {dest} 不存在")

    if not PROVENANCE.is_file():
        fail(f"缺少入库清单 {PROVENANCE}；先跑 rev208_ecology_polyhaven_intake.mjs --fetch")
    prov = json.loads(PROVENANCE.read_text(encoding="utf-8"))
    if prov.get("release_policy") != "QUARANTINED_CANDIDATE_NOT_OTA_NOT_PHONE_PASSED":
        fail(f"未知 release_policy: {prov.get('release_policy')}")

    out_terrain = dest / RES_TERRAIN
    out_ground = dest / RES_GROUNDCOVER
    staged = 0
    total = 0

    for tex in prov["textures"]:
        if tex["license"] != "CC0":
            fail(f"{tex['slug']} 不是 CC0，拒绝入库")
        src_dir = TERRAIN / tex["slug"]
        out_dir = out_terrain / tex["slug"]
        out_dir.mkdir(parents=True, exist_ok=True)
        for m in tex["maps"]:
            src = src_dir / m["file"]
            if not src.is_file():
                fail(f"缺文件 {src}")
            got = sha256(src)
            if got != m["sha256"]:
                fail(f"{src} SHA256 {got} != manifest {m['sha256']}")
            shutil.copyfile(src, out_dir / m["file"])
            staged += 1
            total += int(m["bytes"])

    for model in prov["models"]:
        if model["license"] != "CC0":
            fail(f"{model['slug']} 不是 CC0，拒绝入库")
        src_dir = GROUNDCOVER / model["slug"]
        out_dir = out_ground / model["slug"]
        out_dir.mkdir(parents=True, exist_ok=True)
        for f in model["files"]:
            src = src_dir / f["file"]
            if not src.is_file():
                fail(f"缺文件 {src}")
            got = sha256(src)
            if got != f["sha256"]:
                fail(f"{src} SHA256 {got} != manifest {f['sha256']}")
            target = out_dir / f["file"]
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(src, target)
            staged += 1
            total += int(f["bytes"])

    out_terrain.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(PROVENANCE, out_terrain / "ecology-intake-provenance.json")

    for src_script, res_rel in ((SCRIPT, RES_SCRIPT), (VIVID, RES_VIVID)):
        if not src_script.is_file():
            fail(f"缺脚本 {src_script}")
        (dest / res_rel).parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src_script, dest / res_rel)

    print(
        "PASS_REV208_HQ_ECOLOGY_STAGED_INTO_PCK "
        f"textures={len(prov['textures'])} models={len(prov['models'])} "
        f"files={staged} bytes={total} dest={dest}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
