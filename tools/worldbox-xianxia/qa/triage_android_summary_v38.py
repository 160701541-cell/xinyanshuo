#!/usr/bin/env python3
"""Evidence-only WorldBox MOD Android/Unity summary triage.

Does not manipulate APKs, mods, permissions or saves. Never marks
native deployment as successful third-party MOD runtime loading.
"""
from __future__ import annotations
import argparse, json, re
from pathlib import Path
SECTIONS=re.compile(r'^===\s+(android_current\.log|android_previous\.log|unity_current\.log|unity_previous\.log)\s+===$',re.M)
DEPLOY=re.compile(r'MOD_DEPLOY_(?:OK|CACHED)\s+build=([^\s;]+)')
OBSERVER=re.compile(r'MOD_STATE\s+XINYANSHUO_WORLD_BOX_OBSERVER_V07=(\w+)\s+reason=([^\r\n]*)')
READY=re.compile(r'NML_STAGE\s+initialized_successfully=(\w+)')
LOADED=re.compile(r'LOADED_ENTRY\s+([^\s\r\n]+)')
def analyze(raw:str)->dict:
 names=['android_current.log','android_previous.log','unity_current.log','unity_previous.log']
 chunks={name:'' for name in names}
 spans=list(SECTIONS.finditer(raw))
 for i,m in enumerate(spans):
  chunks[m.group(1)]=raw[m.end():spans[i+1].start() if i+1<len(spans) else len(raw)]
 android,unity=chunks['android_current.log'],chunks['unity_current.log']
 builds=DEPLOY.findall(android);observed=OBSERVER.findall(unity)
 ready=READY.findall(unity);loaded=LOADED.findall(unity)
 bad_zip=bool(re.search(r'ZipException:\s*zip END header not found',android))
 old_type='ModType 0/1' in android and '实际：-1' in android
 steam=bool(re.search(r'libsteam_api|Steam is not available',unity))
 fail=any(x[0]!='LOADED' for x in observed)
 blank=any(not x[1].strip() for x in observed if x[0]!='LOADED')
 return {
  'source':'Copied Android summary, not full log ZIP',
  'evidence':{
   'last_deploy_build':builds[-1] if builds else None,
   'nml_initialized_reported':ready[-1].lower()=='true' if ready else None,
   'loaded_other_mod_entries':sorted(set(loaded)),
   'observer_latest_state':observed[-1][0] if observed else 'UNKNOWN',
   'observer_reason_present':bool(observed and observed[-1][1].strip()),
   'archive_zip_end_missing':bad_zip,
   'historic_missing_mod_type':old_type,
   'historic_unsafe_zip_entry':'ZIP路径格式不安全' in android,
   'steam_missing_in_unity_log':steam,
   'full_exception_stack_available':False
  },
  'conclusions':[
   'MOD_DEPLOY_OK proves file deployment only, not MOD runtime loading.' if builds else 'No deployment evidence.',
   'Other NML MOD entries load but our observer FAILED.' if fail and loaded else 'Observer requires full log.',
   'Blank reason cannot identify observer compile/dependency/load/root exception.' if blank else 'Review actual observer stack.',
   'ZIP end-of-central-directory header missing means invalid/truncated/non-ZIP input, separate from ModType.' if bad_zip else 'No truncated ZIP observed.',
   'Android libsteam_api warnings alone do not prove observer root cause.' if steam else 'No Steam warning shown.'
  ],
  'required_next_evidence':'WorldBox_logs_*.zip from in-app Export Full Logs (read only; no saves)',
  'verdict':'P0_OBSERVER_FAILED_FULL_STACK_REQUIRED' if fail else 'P0_OBSERVER_STATUS_UNCONFIRMED',
  'not_proven':['latest APK installed','observer usable','every MOD compatible','ZIPs valid']
 }
def main():
 p=argparse.ArgumentParser();p.add_argument('--input',type=Path,required=True)
 p.add_argument('--output',type=Path,required=True);args=p.parse_args()
 result=analyze(args.input.read_text(encoding='utf8',errors='replace'))
 args.output.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
 print(result['verdict'])
if __name__=='__main__':main()
