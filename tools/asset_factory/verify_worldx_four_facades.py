#!/usr/bin/env python3
"""Strict structural QA for real WorldX 4-side facade candidates.

Pass means real, intact, unique assets exist and are described; it does NOT
mean four directions depict the SAME house or pass human art/texture QA.
No OCR/AI watermark guessing and no image synthesis here.
"""
from __future__ import annotations
import argparse,hashlib,json
from pathlib import Path
from PIL import Image,ImageStat

SIDES=("front","back","left","right")
BUILDING="courtyard_main_hall"

def validate(root:Path)->dict:
    manifest=json.loads((root/"facades.json").read_text(encoding="utf-8"))
    assert manifest["building_id"]==BUILDING
    assert manifest["source"]=="WorldX"
    assert manifest["art_status"]=="GENERATED_UNAPPROVED"
    assert manifest["identical_building_across_views"]=="PENDING_VISUAL_APPROVAL"
    assert set(manifest["materials"])==set(SIDES)
    fingerprints=[]
    sizes={}
    for side in SIDES:
        info=manifest["materials"][side]
        detail=json.loads((root/(side+".json")).read_text(encoding="utf-8"))
        assert detail["source"]=="WorldX" and detail["building_id"]==BUILDING
        assert detail["reference_conditioned"] is True
        assert detail["source_art_approved"] is False
        assert detail["status"]=="GENERATED_UNAPPROVED"
        assert detail["side"]==side and detail["file"]==info["file"]
        assert detail["sha256"]==info["sha256"]
        name=Path(info["file"])
        assert name.name==str(name) and name.stem==side
        binary=(root/name).read_bytes()
        assert 25_000<len(binary)<18_000_000
        digest=hashlib.sha256(binary).hexdigest()
        assert digest==detail["sha256"]
        with Image.open(root/name) as im:
            im.load()
            w,h=im.size
            assert 768<=w<=4096 and 768<=h<=4096,(side,w,h)
            assert im.format in ("PNG","JPEG"),(side,im.format)
            pixels=im.convert("RGB")
            sigma=ImageStat.Stat(pixels.resize((96,96))).stddev
            assert min(sigma)>5,"Nearly blank/invalid facade: "+side
            sizes[side]=[w,h]
        fingerprints.append(digest)
    assert len(set(fingerprints))==4,"Duplicated facade images; 3D side texture would repeat"
    result={"qa":"PASS_STRUCTURAL_FOUR_FACADE_CANDIDATES_UNAPPROVED",
            "source":"WorldX","building_id":BUILDING,"count":4,
            "sides":list(SIDES),"dimensions":sizes,
            "valid_png_jpg_and_hash":True,
            "unique_images":True,"style_and_correct_view":"PENDING_VISUAL_QA",
            "released_to_original_apk":False}
    return result

def main():
    p=argparse.ArgumentParser()
    p.add_argument("root",type=Path)
    args=p.parse_args()
    summary=validate(args.root)
    (args.root/"structural_qa.json").write_text(
        json.dumps(summary,ensure_ascii=False,indent=2)+"\n",encoding="utf8")
    print("PASS_4_REAL_WORLDX_FACADES_STRUCTURAL_ONLY_NOT_VISUALLY_APPROVED")
if __name__=="__main__":
    main()
