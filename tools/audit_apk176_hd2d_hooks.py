#!/usr/bin/env python3
"""Read-only inventory of *installed* APK176 entrypoints and HD2D patch hooks.
Never confuses new files in an OTA pack with files that the old client loads.
"""
import argparse, hashlib, json, pathlib, zipfile
ROOT=pathlib.Path(__file__).resolve().parents[1]
BASE=ROOT/"android-preview/base-latest.json"
LIVE=ROOT/"android-preview/latest.json"

def audit(apk_path:pathlib.Path)->dict:
    base=json.loads(BASE.read_text())
    live=json.loads(LIVE.read_text())
    if apk_path.stat().st_size!=base["size_bytes"]:
        raise ValueError("APK176 base bytes differ from installed-package manifest")
    if hashlib.sha256(apk_path.read_bytes()).hexdigest()!=base["sha256"]:
        raise ValueError("APK176 SHA256 mismatch")
    with zipfile.ZipFile(apk_path) as z:
        names=z.namelist()
        scenes=[p for p in names if p.startswith("assets/scenes/") and p.endswith((".scn",".tscn",".remap"))]
        scripts=[p for p in names if p.startswith("assets/scripts/") and p.endswith((".gd",".gdc",".remap"))]
        art=[p for p in names if p.startswith("assets/") and any(term in p.lower() for term in ("hd2d","sprite","tile","art","roof","house","village","courtyard"))]
        generated_paths=["assets/scenes/main.tscn","assets/scenes/main.tscn.remap","assets/scenes/main.scn",
                         "assets/scripts/main.gdc","assets/scripts/main.gd",
                         "assets/scenes/update_bootstrap.tscn.remap",
                         "assets/scripts/update_bootstrap.gdc"]
        entry={k:{"exists":k in names,
                  "bytes":z.getinfo(k).file_size if k in names else 0} for k in generated_paths}
        # Godot remaps may refer to compiled bytecode. Preserve a clipped,
        # non-sensitive mapping for reviewers, but never dump binaries.
        remaps={}
        for p in sorted(scripts+scenes):
            if p.endswith(".remap") and any(k in p for k in ("main","hd2d","update_bootstrap","world_visual")):
                if z.getinfo(p).file_size<=4096:
                    remaps[p]=z.read(p).decode("utf8","replace").strip()[:512]
        script_names=[p.split("/")[-1] for p in scripts]
        hd2d_symbols=sorted(set(p for p in art+scripts+scenes if "hd2d" in p.lower()))
        # A newly added scene without a hook in an existing entrypoint is NOT visible.
        return {"apk_verified":True,"version_code":base["version_code"],
                "revision":live["revision"],
                "next_usable_revision":max(live["revision"],base["version_code"]-1000)+1,
                "scene_count":len(scenes),"script_count":len(scripts),
                "scenes":scenes[:100], "main_entrypoint":entry,
                "relevant_script_names":[x for x in script_names if any(k in x for k in ("main","update","visual","hd2d"))][:120],
                "existing_hd2d_entries":hd2d_symbols[:120],
                "other_relevant_art_entries":art[:120],
                "compiled_remaps":remaps,
                "can_activate_new_hd2d_scene_by_additive_pck_alone":False,
                "reason":"Godot requires the existing game script/scene to instantiate new content; adding a new scene path cannot redirect the installed main scene.",
                "requires_existing_entrypoint_override_validation":True,
                "requires_real_apk_RSA_signer":True}

def main():
    a=argparse.ArgumentParser()
    a.add_argument("--apk",type=pathlib.Path,default=ROOT/"android-preview/base/Canglan-AncientWorld-v0.2.0-dev.176-Stable-Signed-ARM64.apk")
    a.add_argument("--out",type=pathlib.Path,default=pathlib.Path("qa-results/apk176-hd2d-entrypoints.json"))
    args=a.parse_args()
    result=audit(args.apk)
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n")
    print("PASS_APK176_ENTRYPOINT_AUDIT",result["scene_count"],result["script_count"],"revision_floor",result["next_usable_revision"])
    print("GAME_ENTRYPOINT",json.dumps(result["main_entrypoint"],ensure_ascii=False))
    print("HD2D_REFERENCES",json.dumps(result["existing_hd2d_entries"][:25],ensure_ascii=False))
    print("BLOCKED_UNTIL_ENTRYPOINT_OVERRIDE_AND_REAL_SIGNING_KEY")

if __name__=="__main__":
    main()
