#!/usr/bin/env python3
"""Read-only Android loader log evidence filter. No log != pass."""
import argparse,json,re
from pathlib import Path

NML=re.compile(r'(?:NeoModLoader|\bNML\b).{0,180}(?:loaded|ready|initialize|start|启动|加载)',re.I)
MOD=re.compile(r'\[XIANXIA-V0[78]\].{0,120}(?:SOURCE_ONLY_LOAD|MOD_LOADED)',re.I)
MAP=re.compile(r'\[XIANXIA-V0[78]\].{0,120}REAL_MAP_SAMPLE',re.I)
ERROR=re.compile(r'(?:XIANXIA-V0[78].*(?:Exception|ERROR)|FATAL.*(?:NeoModLoader|XIANXIA))',re.I)

def check(raw):
    lines=raw.splitlines()
    ev={
       "loader_ready":next((i+1 for i,s in enumerate(lines) if NML.search(s)),None),
       "mod_loaded":next((i+1 for i,s in enumerate(lines) if MOD.search(s)),None),
       "world_sampled":next((i+1 for i,s in enumerate(lines) if MAP.search(s)),None)}
    errors=[{"line":i+1,"message":s[:300]} for i,s in enumerate(lines) if ERROR.search(s)][:30]
    good=all(ev.values()) and ev["loader_ready"]<=ev["mod_loaded"]<=ev["world_sampled"] and not errors
    return {
      "status":"CANDIDATE_LOG_EVIDENCE_PRESENT" if good else "DEVICE_PENDING",
      "milestones":ev,"errors":errors,"lines_examined":len(lines),
      "warning":"Full Android MOD certification still requires real loader identity/version, UI, FPS and save integrity QA."}

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--log",type=Path,required=True)
    p.add_argument("--out",type=Path,required=True)
    a=p.parse_args()
    result=check(a.log.read_text(encoding="utf8",errors="replace"))
    a.out.parent.mkdir(parents=True,exist_ok=True)
    a.out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf8")
    print(result["status"])
    if result["status"]!="CANDIDATE_LOG_EVIDENCE_PRESENT":raise SystemExit(2)
if __name__=="__main__":main()
