#!/usr/bin/env python3
"""Strictly separate WorldBox external MOD lab from Canglan original game."""
import argparse,json,subprocess
from pathlib import Path
BASE_SHA="52e52b4460db04d3c91e71aff5ac618ed5c291e1"
SOURCE="tools/worldbox-xianxia/"
WORKFLOW=".github/workflows/worldbox-external-mod-lab-v13.yml"
OLD_WORKFLOW=".github/workflows/worldbox-external-mod-lab-v12.yml"
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

def validate_change_entries(entries):
    """Include deletions. Only old *invalid* WorldBox workflow can be deleted."""
    errs=[]
    for row in entries:
        if "\t" not in row:
            errs.append("BAD_GIT_NAME_STATUS: "+row)
            continue
        kind,path=row.split("\t",1)
        if kind=="D" and path==OLD_WORKFLOW:
            continue
        errs.extend(validate_paths([path]))
    return errs

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--changed-file-list",type=Path)
    ap.add_argument("--scope",type=Path,default=Path(__file__).with_name("project_scope.json"))
    args=ap.parse_args()
    scope=json.loads(args.scope.read_text(encoding="utf8"))
    if args.changed_file_list:
        # Legacy offline test mode accepts plain paths as added/modified.
        paths=["M\t"+p for p in args.changed_file_list.read_text(encoding="utf8").splitlines()]
    else:
        paths=subprocess.check_output(
            ["git","diff","--no-renames","--name-status","--diff-filter=ACMRTD",BASE_SHA+"..HEAD"],text=True).splitlines()
    errors=evaluate_policy(scope)+validate_change_entries(paths)
    if not paths: errors.append("No changed files in v0.13 test scope")
    for x in paths:print("SCOPED "+x)
    for x in errors:print("BLOCKED "+x)
    if errors:raise SystemExit(1)
    print("PASS_EXTERNAL_MOD_ONLY_SCOPE_GATE: "+str(len(paths))+" changes")
if __name__=="__main__": main()
