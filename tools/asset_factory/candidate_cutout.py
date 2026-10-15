#!/usr/bin/env python3
"""Conservative candidate-only matting for uniform studio backgrounds.

Outputs are NEVER visually approved. Refuses textured/ambiguous backgrounds, and
preserves the input. A human must inspect edge contamination and anatomy.
"""
import argparse
import hashlib
import json
from collections import deque
from pathlib import Path
import re
from PIL import Image

ID = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.-]{0,99}$")


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def _median(values):
    values = sorted(values)
    return values[len(values) // 2]


def _distance(rgb, bg):
    return max(abs(rgb[i] - bg[i]) for i in range(3))


def infer_background(im, threshold):
    w, h = im.size
    rgb = im.convert("RGB")
    px = rgb.load()
    k = max(1, min(w, h) // 50)
    corners = []
    for x0, y0 in ((0, 0), (w - k, 0), (0, h - k), (w - k, h - k)):
        pts = [px[x, y] for x in range(x0, x0 + k) for y in range(y0, y0 + k)]
        corners.append(tuple(_median([p[c] for p in pts]) for c in range(3)))
    bg = tuple(_median([v[c] for v in corners]) for c in range(3))
    if any(_distance(v, bg) > threshold for v in corners):
        raise ValueError("INCONSISTENT_CORNER_BACKGROUND")
    border = [px[x, 0] for x in range(w)] + [px[x, h - 1] for x in range(w)]
    border += [px[0, y] for y in range(1, h - 1)] + [px[w - 1, y] for y in range(1, h - 1)]
    confidence = sum(_distance(p, bg) <= threshold for p in border) / len(border)
    if confidence < 0.90:
        raise ValueError("BORDER_NOT_UNIFORM_OR_SUBJECT_CROPPED")
    return bg, round(confidence, 5)


def remove_uniform_background(source, threshold=28):
    """Remove ONLY edge-connected pixels similar to a confirmed plain border.

    A binary matte intentionally leaves possible halos as pending visual review;
    this tool must not silently extrapolate or invent fine hair/foliage detail.
    """
    rgba = source.convert("RGBA")
    w, h = rgba.size
    if w < 32 or h < 32:
        raise ValueError("INPUT_TOO_SMALL")
    alpha = rgba.getchannel("A")
    n_transparent = alpha.histogram()[0]
    if n_transparent:
        return rgba, {"operation": "PRESERVED_EXISTING_ALPHA", "background_rgb": None,
                      "transparency_pixels": n_transparent, "confidence": None}
    if alpha.getextrema()[0] < 255:
        raise ValueError("PARTIAL_ALPHA_WITHOUT_TRANSPARENT_BORDER_NEEDS_REVIEW")
    bg, confidence = infer_background(rgba, threshold)
    rgb = rgba.convert("RGB")
    pix = rgb.load()
    flagged = bytearray(w * h)
    queue = deque()
    for x in range(w):
        queue.append((x, 0))
        queue.append((x, h - 1))
    for y in range(1, h - 1):
        queue.append((0, y))
        queue.append((w - 1, y))
    count = 0
    while queue:
        x, y = queue.popleft()
        i = y * w + x
        if flagged[i]:
            continue
        flagged[i] = 1
        if _distance(pix[x, y], bg) > threshold:
            continue
        count += 1
        if x > 0 and not flagged[i - 1]:
            queue.append((x - 1, y))
        if x + 1 < w and not flagged[i + 1]:
            queue.append((x + 1, y))
        if y > 0 and not flagged[i - w]:
            queue.append((x, y - 1))
        if y + 1 < h and not flagged[i + w]:
            queue.append((x, y + 1))
    coverage = count / (w * h)
    if coverage < 0.03 or coverage > 0.94:
        raise ValueError("AMBIGUOUS_BACKGROUND_COVERAGE")
    a = alpha.load()
    for y in range(h):
        for x in range(w):
            i = y * w + x
            if flagged[i] and _distance(pix[x, y], bg) <= threshold:
                a[x, y] = 0
    rgba.putalpha(alpha)
    return rgba, {"operation": "UNIFORM_EDGE_CONNECTED_CUTOUT_CANDIDATE",
                  "background_rgb": list(bg), "border_confidence": confidence,
                  "removed_fraction": round(coverage, 5), "threshold": threshold,
                  "matte_warning": "Potential halo and lost near-background detail; manual visual QA required"}


def make_icon(image, size=512):
    bounds = image.getchannel("A").getbbox()
    if not bounds:
        raise ValueError("EMPTY_SPRITE")
    cropped = image.crop(bounds)
    cropped.thumbnail((int(size * .86), int(size * .86)), Image.Resampling.LANCZOS)
    out = Image.new("RGBA", (size, size))
    out.alpha_composite(cropped, ((size - cropped.width) // 2, (size - cropped.height) // 2))
    return out


def make_preview(image):
    w, h = image.size
    out = Image.new("RGB", (w * 2, h), (255, 255, 255))
    for i, bg in enumerate(((245, 245, 245, 255), (38, 44, 49, 255))):
        base = Image.new("RGBA", (w, h), bg)
        base.alpha_composite(image)
        out.paste(base.convert("RGB"), (i * w, 0))
    return out


def _checked_file(root, relative):
    if not isinstance(relative, str) or not relative:
        raise ValueError("INVALID_INPUT_PATH")
    target = (root / relative).resolve()
    if not target.is_relative_to(root) or not target.is_file():
        raise ValueError("MISSING_OR_ESCAPE_INPUT_PATH")
    return target


def process(input_dir, output_dir, threshold=28):
    root = Path(input_dir).resolve()
    out = Path(output_dir).resolve()
    if root == out or root in out.parents:
        raise ValueError("OUTPUT_MUST_NOT_OVERWRITE_OR_NEST_INSIDE_INPUT")
    data = json.loads((root / "candidate_manifest.json").read_text(encoding="utf-8"))
    if (data.get("approved_count") != 0 or not data.get("assets") or
            data.get("count") != len(data.get("assets", [])) or
            any(entry.get("review") != "UNAPPROVED" for entry in data["assets"])):
        raise ValueError("INVALID_OR_APPROVED_SOURCE_MANIFEST")
    out.mkdir(parents=True, exist_ok=True)
    records = []
    ids = set()
    for entry in data["assets"]:
        asset_id = entry.get("id")
        if not isinstance(asset_id, str) or not ID.fullmatch(asset_id) or asset_id in ids:
            raise ValueError("INVALID_OR_DUPLICATE_ASSET_ID")
        ids.add(asset_id)
        record = dict(entry)
        record["review"] = "UNAPPROVED"
        record["cleanup_status"] = "BLOCKED"
        try:
            src = _checked_file(root, entry.get("scene"))
            with Image.open(src) as image:
                image.load()
                cleaned, metrics = remove_uniform_background(image, threshold)
            folder = out / "candidates" / asset_id
            folder.mkdir(parents=True, exist_ok=True)
            spr = folder / "scene_candidate.png"
            ico = folder / "icon_candidate.png"
            cleaned.save(spr)
            make_icon(cleaned).save(ico)
            make_preview(cleaned).save(folder / "visual_review_preview.png")
            record.update({"scene": str(spr.relative_to(out)), "icon": str(ico.relative_to(out)),
                           "cleanup_status": "CLEANED_CANDIDATE", "source_scene_sha256": sha256(src),
                           "scene_sha256": sha256(spr), "icon_sha256": sha256(ico),
                           "cleanup_metrics": metrics})
        except (OSError, ValueError) as exc:
            record["cleanup_error"] = str(exc)
            record["scene"] = ""
            record["icon"] = ""
        records.append(record)
    manifest = {"source_manifest_sha256": sha256(root / "candidate_manifest.json"),
                "count": len(records), "approved_count": 0,
                "cleaned_candidate_count": sum(r["cleanup_status"] == "CLEANED_CANDIDATE" for r in records),
                "status": "CANDIDATE_ONLY_NOT_APPROVED", "assets": records}
    (out / "candidate_manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return manifest


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--input", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--threshold", type=int, default=28)
    args = p.parse_args()
    if not 1 <= args.threshold <= 60:
        p.error("threshold must be between 1 and 60")
    report = process(args.input, args.out, args.threshold)
    print(f"CANDIDATES ONLY: {report['cleaned_candidate_count']}/{report['count']} cleaned; 0 approved")
    raise SystemExit(1 if report["cleaned_candidate_count"] != report["count"] else 0)


if __name__ == "__main__":
    main()
