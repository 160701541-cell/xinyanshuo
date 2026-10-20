#!/usr/bin/env python3
"""WorldBox 0.51.x large-map planning, separate from original Canglan game.

Independent planning model; does not claim WorldBox mobile has registered sizes.
8x8 chunks=512x512, as documented 64 tiles/chunk. No invented RAM benchmarks.
"""
from dataclasses import dataclass,asdict
import argparse,json,math

CHUNK=64
TIERS=(8,10,12,16,20,24,30)
@dataclass(frozen=True)
class Size:
    chunks:int
    tiles:int
    tile_count:int
    relative_to_vanilla_titanic:float
    level:str
    recommendation:str
    registration_status:str="NOT_REGISTERED_IN_ANDROID_GAME"
def calc(chunks):
    if chunks not in TIERS:
        raise ValueError("size must be supported candidate tier")
    tiles=CHUNK*chunks
    ratio=(chunks/8.)**2
    level=("base" if chunks==8 else
           "safe_candidate" if chunks<=12 else
           "high_end_candidate" if chunks<=16 else
           "experimental" if chunks<=20 else "extreme_no_default")
    recommendation={
        "base":"Base vanilla Titanic; game itself knows this size.",
        "safe_candidate":"Test first on a COPY of world, then watch simulation FPS and memory.",
        "high_end_candidate":"Snapdragon 8 Elite-class device candidate, NOT confirmed safe; test with large NPC population.",
        "experimental":"20x20 is 6.25x 8x8 world area; device RAM and NPC simulation may bottleneck.",
        "extreme_no_default":"No automatic unlock; do not generate without device load and backup."
    }[level]
    return Size(chunks,tiles,tiles*tiles,round(ratio,3),level,recommendation)

def recommend(soc_name,available_ram_gb=None,observed_fps=None,population=5000):
    if population<0:raise ValueError("population must be nonnegative")
    high_end=any(v in soc_name.lower() for v in ("8 elite","8至尊","8至尊版","骁龙8 elite"))
    # conservative when no actual phone telemetry
    if observed_fps is None or available_ram_gb is None:
        return {"tier": 12 if high_end else 8, "phase":"START_WITHOUT_DEVICE_TELEMETRY",
                "note":"GPU/SoC name alone cannot prove 16x16/20x20 works."}
    if available_ram_gb<1.2 or observed_fps<25:return {"tier":8,"phase":"THROTTLE_OR_ROLLBACK"}
    if observed_fps<36 or available_ram_gb<2.5:return {"tier":10,"phase":"LIMIT_COMPLEXITY"}
    if population>10000 and observed_fps<50:return {"tier":12,"phase":"DENSE_WORLD_LIMIT"}
    if high_end and observed_fps>=50 and available_ram_gb>=5 and population<=10000:
        return {"tier":20,"phase":"EXPERIMENTAL_ADVANCE_ONLY_WITH_BACKUP"}
    if high_end and observed_fps>=42 and available_ram_gb>=3.5:
        return {"tier":16,"phase":"ADVANCE_WITH_RUNTIME_TEST"}
    return {"tier":12,"phase":"GRADUAL_RAMP"}

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--device",default="Snapdragon 8 Elite")
    p.add_argument("--free-ram-gb",type=float)
    p.add_argument("--fps",type=float)
    p.add_argument("--population",type=int,default=5000)
    p.add_argument("--out",required=True)
    a=p.parse_args()
    result={
        "schema":"worldbox.external.mod.map-sizes.plan.v1",
        "project":"WorldBox 0.51.4 third-party nonofficial MOD testing; unrelated to Canglan game development",
        "device":a.device,"basis":"64 tiles/chunk; base 8x8 Titanic 512x512",
        "recommendation":recommend(a.device,a.free_ram_gb,a.fps,a.population),
        "candidate_sizes":[asdict(calc(x)) for x in TIERS],
        "worldbox_runtime_compatible":False,
        "modded_map_generation_implemented":False,
        "save_backups_required":True}
    from pathlib import Path
    output=Path(a.out);output.parent.mkdir(parents=True,exist_ok=True)
    output.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf8")
    print("planned map sizes only:",",".join(f"{z}x{z}" for z in TIERS))
if __name__=="__main__":main()
