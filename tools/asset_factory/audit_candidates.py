#!/usr/bin/env python3
"""Fail-closed technical audit of independent atlas candidates (not visual approval)."""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image


def audit(root):
    root = Path(root).resolve()
    manifest = json.loads((root / "candidate_manifest.json").read_text(encoding="utf-8"))
    failures = []
    report = []
    seen = set()
    assets = manifest.get("assets", [])
    if manifest.get("count") != len(assets) or not assets:
        failures.append("MANIFEST_COUNT_MISMATCH")
    if manifest.get("approved_count") != 0:
        failures.append("CANDIDATE_MANIFEST_CLAIMS_APPROVAL")
    for asset in assets:
        aid = str(asset.get("id", ""))
        issues = []
        if not aid or aid in seen:
            issues.append("MISSING_OR_DUPLICATE_ID")
        seen.add(aid)
        if asset.get("review") != "UNAPPROVED":
            issues.append("UNREVIEWED_CANDIDATE_MARKED_APPROVED")
        file_info = {}
        for key in ("scene", "icon"):
            relative = asset.get(key, "")
            target = (root / relative).resolve()
            if not relative or not target.is_relative_to(root):
                issues.append(key.upper() + "_PATH_ESCAPE")
                continue
            if not target.is_file():
                issues.append(key.upper() + "_MISSING")
                continue
            payload = target.read_bytes()
            file_info[key + "_sha256"] = hashlib.sha256(payload).hexdigest()
            try:
                with Image.open(target) as image:
                    image.load()
                    if image.format != "PNG" or image.mode != "RGBA":
                        issues.append(key.upper() + "_NOT_RGBA_PNG")
                    rgba = image.convert("RGBA")
                    w, h = rgba.size
                    if min(w, h) < (128 if key == "scene" else 256):
                        issues.append(key.upper() + "_RESOLUTION_TOO_LOW")
                    alpha = rgba.getchannel("A")
                    hist = alpha.histogram()
                    if hist[0] == 0:
                        issues.append(key.upper() + "_NO_TRANSPARENT_PIXELS")
                    if hist[255] == w * h:
                        issues.append(key.upper() + "_OPAQUE_RECTANGULAR_BACKGROUND")
                    bbox = alpha.getbbox()
                    if not bbox:
                        issues.append(key.upper() + "_EMPTY")
                    elif bbox[0] == 0 or bbox[1] == 0 or bbox[2] == w or bbox[3] == h:
                        issues.append(key.upper() + "_ALPHA_TOUCHES_CANVAS_EDGE")
                    file_info[key + "_dimensions"] = [w, h]
            except (OSError, ValueError):
                issues.append(key.upper() + "_INVALID_IMAGE")
        report.append({"id": aid, "status": "BLOCKED" if issues else "TECH_CANDIDATE_PASS",
                       "issues": issues, **file_info,
                       "visual_review": "REQUIRED", "production_approved": False})
        failures.extend(aid + ":" + issue for issue in issues)
    return {"schema": 1, "candidate_count": len(report), "technical_pass_count": sum(
        x["status"] == "TECH_CANDIDATE_PASS" for x in report),
        "production_approved_count": 0, "status": "FAIL" if failures else "TECH_ONLY_PASS",
        "failures": failures, "assets": report}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, help="directory containing candidate_manifest.json")
    parser.add_argument("--report", help="output JSON; default input/technical_qa.json")
    args = parser.parse_args()
    result = audit(args.input)
    dest = Path(args.report) if args.report else Path(args.input) / "technical_qa.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"{result['status']}: {result['technical_pass_count']}/{result['candidate_count']} technical candidates; 0 visually approved")
    raise SystemExit(1 if result["status"] == "FAIL" else 0)


if __name__ == "__main__":
    main()
