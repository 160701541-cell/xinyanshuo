#!/usr/bin/env python3
"""CAC-0008: fail-closed quarantine inventory and production intake gate.
Does not claim that an upscale or palette conversion creates native HD art.
"""
import argparse, hashlib, json, zipfile
from io import BytesIO
from pathlib import Path
from PIL import Image

def inspect_zip(path, min_size=512):
    findings=[]
    with zipfile.ZipFile(path) as z:
        names=z.namelist()
        if len(names)!=len(set(names)):
            raise ValueError("DUPLICATE_ARCHIVE_PATH")
        for info in z.infolist():
            n=info.filename
            if n.startswith("/") or ".." in Path(n).parts or "\\" in n:
                raise ValueError("UNSAFE_ARCHIVE_PATH")
            if info.is_dir() or not n.lower().endswith(".png"):
                continue
            raw=z.read(info)
            with Image.open(BytesIO(raw)) as im:
                im.load()
                w,h=im.size
                rgba=im.convert("RGBA")
                alpha=rgba.getchannel("A")
                bbox=alpha.getbbox()
                issues=[]
                if min(w,h)<min_size: issues.append("NATIVE_RESOLUTION_BELOW_TARGET")
                if im.mode!="RGBA": issues.append("NOT_NATIVE_RGBA")
                if not bbox: issues.append("EMPTY_ALPHA")
                elif bbox[0]==0 or bbox[1]==0 or bbox[2]==w or bbox[3]==h:
                    issues.append("VISIBLE_PIXELS_TOUCH_EDGE")
                if alpha.histogram()[0]==0: issues.append("NO_FULLY_TRANSPARENT_PIXEL")
                findings.append({"path":n,"size":[w,h],"mode":im.mode,
                                 "sha256":hashlib.sha256(raw).hexdigest(),
                                 "issues":issues,"approved":False})
    return findings

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--input",nargs="+",required=True)
    p.add_argument("--out",required=True)
    p.add_argument("--min-size",type=int,default=512)
    args=p.parse_args()
    assets=[]
    for f in args.input:
        for x in inspect_zip(f,args.min_size):
            x["archive"]=Path(f).name
            assets.append(x)
    result={"schema":"CAC-0008","status":"BLOCKED_FOR_PRODUCTION",
            "candidate_count":len(assets),"production_approved":0,
            "pass_machine_checks":sum(not a["issues"] for a in assets),
            "assets":assets}
    out=Path(args.out)
    out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(f"audited {len(assets)} quarantined PNGs; 0 approved")
    raise SystemExit(1 if any(x["issues"] for x in assets) else 0)

if __name__=="__main__":main()
