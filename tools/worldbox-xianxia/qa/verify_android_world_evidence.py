#!/usr/bin/env python3
"""Read-only verifier for WorldBox v0.51.4 third-party MOD device logs.

NEVER asserts a 2048 map worked without real runtime lines; no Canglan files.
"""
import argparse, json, re
from pathlib import Path

SIZE = re.compile(r"WORLD_SIZE_(MATCH|DIFFERENT|FAIL)(?:\s+actual=(\d+)x(\d+))?")
API = re.compile(r"MAP_API_(READY|FAIL)")
LOADER = re.compile(r"\[XIANXIA-(?:V\d+|MONO-V\d+)\].*(LOAD_BRIDGE_OK|LOAD_FAILED|VIEW_OPEN|MAP_API_|WORLD_SIZE_)")
BAD = re.compile(r"(FATAL EXCEPTION|SIGSEGV|OutOfMemoryError|OutOfMemoryException|ANR in|java\.lang\.Error)")
def verify(text):
    problems = sorted(set(BAD.findall(text)))
    api = API.findall(text)
    sizes = SIZE.findall(text)
    # Later lines supersede earlier ones after world-generation transitions.
    latest = sizes[-1] if sizes else None
    actual = [int(latest[1]),int(latest[2])] if latest and latest[1] else None
    world_match = bool(latest and latest[0]=="MATCH" and actual==[2048,2048])
    # Even a dimension match cannot attest save/reload or a performance benchmark.
    return {
      "schema":"worldbox.external.mod.device.evidence.v1",
      "scope":"WorldBox third-party MOD only; unrelated to Canglan original game",
      "mod_log_seen":bool(LOADER.search(text)),
      "map_api_diagnostic_seen":bool(api),
      "latest_map_api":api[-1] if api else "NO_EVIDENCE",
      "world_dimension_readback_seen":bool(sizes),
      "world_dimension_status":latest[0] if latest else "NO_EVIDENCE",
      "actual_dimensions":actual,
      "observed_exact_2048_square":world_match,
      "crash_signatures":problems,
      "device_launch_verified":False, # cannot infer from arbitrary pasted log text
      "save_reload_verified":False,
      "stable_fps_verified":False,
      "apk_one_tap_verified":False,
      "verdict":"DIMENSIONS_ONLY_NEEDS_DEVICE_QA" if world_match and not problems else
         "FAIL_CRASH_SIGNATURE" if problems else
         "NO_2048_WORLD_PROOF",
      "required_next_checks":[
        "Show actual Android app launch and loaded MOD UI",
        "Create a NEW 2048x2048 world; collect real WORLD_SIZE_MATCH readback",
        "Save, close game, reopen, reload and check same map dimensions",
        "Measure sustained FPS, memory and thermals with 5000+ population",
        "Verify signed APK install/update behavior and backups"
      ]
    }

def main():
    p=argparse.ArgumentParser(description="Evaluate actual Android logcat from Work privately; not proof without provenance")
    p.add_argument("--log",type=Path,required=True)
    p.add_argument("--out",type=Path,required=True)
    a=p.parse_args()
    report=verify(a.log.read_text(encoding="utf8",errors="replace"))
    a.out.parent.mkdir(parents=True,exist_ok=True)
    a.out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf8")
    print(report["verdict"])
if __name__=="__main__":main()
