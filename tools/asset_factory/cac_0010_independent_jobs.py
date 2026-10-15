#!/usr/bin/env python3
"""CAC-0010: deterministic one-object-per-job production manifest (no atlas generation)."""
import argparse, json, re
from pathlib import Path

DEFAULT_STATES = {
    "tree_peach": ["sapling", "young", "adult_spring", "adult_summer", "adult_autumn", "adult_winter", "felled", "stump"],
    "building_house": ["intact_day", "intact_night", "damaged", "burned", "collapsed"],
    "prop_lantern": ["unlit", "lit", "broken"],
    "prop_well": ["intact", "damaged", "ruined"],
}
STYLE = {
    "view": "3/4 elevated HD2D game sprite, fixed camera, no perspective drift",
    "light": "soft upper-left studio key light, consistent cast shadow",
    "composition": "exactly ONE complete object, centered, fully visible, >=12% safety margin",
    "background": "transparent alpha preferred; no black backdrop, labels, watermark or grid",
    "quality": "native minimum 1024x1024 RGBA master; crisp silhouette; coherent scale",
}
def make_jobs(catalog, batch_id):
    seen=set()
    jobs=[]
    for obj in catalog:
        ident=obj["id"]
        if not re.fullmatch(r"[a-z][a-z0-9_]{2,63}",ident) or ident in seen:
            raise ValueError("invalid or duplicate id: "+ident)
        seen.add(ident)
        states=obj.get("states",DEFAULT_STATES.get(ident,["default"]))
        if not states or len(states)!=len(set(states)): raise ValueError("invalid states")
        for state in states:
            if not re.fullmatch(r"[a-z][a-z0-9_]{1,63}",state):raise ValueError("invalid state")
            key=f"{ident}__{state}"
            jobs.append({"job_id":f"{batch_id}__{key}","entity_id":ident,"state":state,
                         "prompt":f"{obj['description']}, state: {state}. "+
                            ". ".join(STYLE.values()),
                         "negative_prompt":"contact sheet, multiple objects, cropped, text, black background, low resolution",
                         "master_target":f"art-source/hd2d/masters/{ident}/{state}.png",
                         "minimum_native_size":[1024,1024],"safe_margin_fraction":0.12,
                         "status":"PENDING_GENERATION","approved":False,
                         "attempt":0,"max_attempts":3})
    return jobs

def main():
    p=argparse.ArgumentParser();p.add_argument("--catalog",required=True)
    p.add_argument("--batch-id",default="CAC0010");p.add_argument("--out",required=True)
    args=p.parse_args()
    catalog=json.loads(Path(args.catalog).read_text(encoding="utf-8"))
    jobs=make_jobs(catalog,args.batch_id)
    target=Path(args.out);target.parent.mkdir(parents=True,exist_ok=True)
    target.write_text(json.dumps({"schema":"CAC-0010","style":STYLE,"jobs":jobs},indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    print(f"created {len(jobs)} independent pending jobs; generated images: 0")

if __name__=="__main__":main()
