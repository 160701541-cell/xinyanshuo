#!/usr/bin/env python3
"""Strictly separate WorldBox external MOD lab from Canglan original game."""
import argparse,json,subprocess
from pathlib import Path
BASE_SHA="36c25c7fb56dbc1fb1e6e1bd512b7d73880024fe"
SOURCE="tools/worldbox-xianxia/"
WORKFLOW=".github/workflows/worldbox-external-mod-lab-v07.yml"
FORBIDDEN=(".apk",".pck",".dll",".pdb",".exe",".rar",".7z",".aab")

def validate_paths(paths):
    errors=[]
    for raw in paths:
        p=raw.replace(chr(92),"/")
        if p.startswith("./"):p=p[2:]
        if not p or p.startswith("../") or "/.." in p:
            errors.append("BAD_PATH: "+raw)
        elif not (p.startswith(SOURCE) or p==WORKFLOW):
            errors.append("CROSS_PROJECT_EDIT_BLOCKED: "+p)
        if p.lower().endswith(FORBIDDEN):
            errors.append("THIRD_PARTY_BINARY_BLOCKED: "+p)
    return errors

def evaluate_policy(scope):
    errors=[]
    if scope.get("project_id")!="WORLDBOX_THIRD_PARTY_MOD_DERIVATIVE_TEST":
        errors.append("Wrong project identity")
    if scope.get("merge_main_allowed") is not False:
        errors.append("No merging external test into main")
    if scope.get("third_party_binary_publication_allowed") is not False:
        errors.append("Do not publish private third-party binaries")
    if scope.get("device_test")!="PENDING":
        errors.append("Unverified Android device claim")
    return errors

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--changed-file-list",type=Path)
    ap.add_argument("--scope",type=Path,default=Path(__file__).with_name("project_scope.json"))
    args=ap.parse_args()
    scope=json.loads(args.scope.read_text(encoding="utf8"))
    if args.changed_file_list:
        paths=args.changed_file_list.read_text(encoding="utf8").splitlines()
    else:
        paths=subprocess.check_output(["git","diff","--name-only","--diff-filter=ACMRT",BASE_SHA+"..HEAD"],text=True).splitlines()
    errors=evaluate_policy(scope)+validate_paths(paths)
    if not paths: errors.append("No changed files in v0.7 test scope")
    for x in paths:print("SCOPED "+x)
    for x in errors:print("BLOCKED "+x)
    if errors:raise SystemExit(1)
    print("PASS_EXTERNAL_MOD_ONLY_SCOPE_GATE: "+str(len(paths))+" changes")
if __name__=="__main__": main()
