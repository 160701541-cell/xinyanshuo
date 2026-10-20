"""Synthetic regression: deploy never means custom observer loaded."""
from triage_android_summary_v38 import analyze
def test():
 s='''=== android_current.log ===
2026-10-21 03:34:20 MOD_DEPLOY_OK build=v34-modzip-abc managed=294 payloadFiles=735
2026-10-21 03:05:18 USER_MOD_IMPORT_FAILED java.io.IOException: 仅支持ModType 0/1，实际：-1
2026-10-21 03:34:13 USER_MOD_IMPORT_FAILED java.util.zip.ZipException: zip END header not found
=== unity_current.log ===
Log System.Exception: Steam is not available
Log System.DllNotFoundException: libsteam_api
[XIANXIA-INTEGRATION] NML_STAGE initialized_successfully=True
[XIANXIA-INTEGRATION] LOADED_ENTRY Frontiers.FrontiersMod
[XIANXIA-INTEGRATION] MOD_STATE XINYANSHUO_WORLD_BOX_OBSERVER_V07=FAILED reason=
=== unity_previous.log ===
NML_STAGE initialized_successfully=False
'''
 r=analyze(s);e=r['evidence']
 assert e['last_deploy_build']=='v34-modzip-abc'
 assert e['nml_initialized_reported'] is True
 assert e['observer_latest_state']=='FAILED' and not e['observer_reason_present']
 assert e['archive_zip_end_missing'] and e['historic_missing_mod_type']
 assert e['loaded_other_mod_entries']==['Frontiers.FrontiersMod']
 assert r['verdict']=='P0_OBSERVER_FAILED_FULL_STACK_REQUIRED'
 q=analyze('=== android_current.log ===\nMOD_DEPLOY_OK build=v38\n=== unity_current.log ===\n')
 assert q['verdict']=='P0_OBSERVER_STATUS_UNCONFIRMED'
 assert q['evidence']['nml_initialized_reported'] is None
 print('PASS_V38_NO_FALSE_MOD_LOADED_SUCCESS')
if __name__=='__main__':test()
