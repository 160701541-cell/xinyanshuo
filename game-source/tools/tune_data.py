#!/usr/bin/env python3
"""Fail-closed multidisciplinary data calibration for the Canglan game.

Produces measured PASS/FAIL/BLOCKED and a bounded candidate override; NEVER
edits game scripts, relaxes gate limits, signs updates or approves aesthetics.
An immutable evidence receipt (commit / run / screenshot hashes) is mandatory.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import math
from pathlib import Path
import re

SHA = re.compile(r'^[0-9a-f]{40}$')
SHA256 = re.compile(r'^[0-9a-f]{64}

class TuneError(ValueError):
    pass


def require(ok, message):
    if not ok:
        raise TuneError(message)


def numeric(x, field):
    require(type(x) in (int, float) and math.isfinite(x), f'{field}:invalid_numeric')
    return float(x)


def load_json(path):
    return json.loads(Path(path).read_text(encoding='utf-8'))


def validate_contract(contract):
    require(type(contract) is dict and contract.get('schema') == 1,
            'contract_schema_mismatch')
    policy = contract.get('policy', {})
    require(policy.get('unknown_evidence') == 'BLOCK'
            and policy.get('art_approval') == 'HUMAN_REQUIRED'
            and policy.get('save_and_provenance') == 'INVARIANT',
            'weak_or_untrusted_qa_policy')
    require(set(contract.get('gates', {})) == {
        'visual','controls','logic','performance'},'incomplete_quality_gates')
    factor = numeric(policy.get('max_single_adjustment_fraction'),
                     'max_single_adjustment_fraction')
    require(0 < factor <= 0.1, 'unsafe_tuning_rate')
    require(policy.get('device_min_duration_seconds',0) >= 900,
            'short_phone_benchmark_prohibited')
    for domain,gate in contract['gates'].items():
        require(gate.get('require_source') in ('godot_real','android_real'),
                f'{domain}:invalid_evidence_source')
        require(type(gate.get('metrics')) is dict and gate['metrics'],
                f'{domain}:no_quality_metrics')
        require(set(gate['metrics']) == set(QUALITY_FLOORS[domain]),
                f'{domain}:hard_quality_floor_missing_or_extra')
        for key,bound in gate['metrics'].items():
            require(type(bound) is dict and len(bound)==1
                    and (set(bound)=={'min'} or set(bound)=={'max'}),
                    f'{domain}:{key}:invalid_threshold')
            observed=numeric(next(iter(bound.values())),f'{domain}:{key}:threshold')
            floor_op, floor_value=QUALITY_FLOORS[domain][key]
            require(floor_op in bound
                    and (observed<=floor_value if floor_op=='max'
                         else observed>=floor_value),
                    f'{domain}:{key}:quality_floor_relaxed')
    for name,p in contract.get('tuning_parameters',{}).items():
        require(type(p) is dict,'tuning_record_invalid')
        current=numeric(p.get('value'),name)
        low=numeric(p.get('min'),name)
        high=numeric(p.get('max'),name)
        step=numeric(p.get('step'),name)
        require(low<=current<=high and high>low and step>0,
                f'{name}:bad_tuning_limits')
        require(p.get('direction') in (
            'human_review','decrease_if_over_budget','increase_if_conflict'),
            f'{name}:unknown_tuning_strategy')
        require(set(p.get('requires',[])).issubset(contract['gates']),
                f'{name}:unknown_dependency')


def eval_gate(name, gate, records):
    applicable=[]
    invalid=[]
    for record in records:
        if record.get('domain')!=name:
            continue
        origin=record.get('origin')
        if origin!=gate['require_source']:
            invalid.append('not_real_'+gate['require_source'])
            continue
        commit=record.get('commit')
        if type(commit) is not str or not SHA.fullmatch(commit):
            invalid.append('missing_verified_git_commit')
            continue
        proofs=record.get('proof_sha256')
        if type(proofs) is not list or len(proofs)==0 or any(
            type(x) is not str or not SHA256.fullmatch(x) for x in proofs
        ):
            invalid.append('missing_proof_hash')
            continue
        if type(record.get('device')) is not str or not record['device'].strip():
            invalid.append('missing_device_or_renderer')
            continue
        if name=='performance' and numeric(record.get('sample_seconds',0),
                                           'performance:duration') < gate.get('sample_seconds',0):
            invalid.append('insufficient_sustained_benchmark')
            continue
        applicable.append(record)
    if not applicable:
        return {'state':'BLOCKED','reason':sorted(set(invalid)) or ['no_real_evidence'],
                'metrics':{}}
    # Every real sample must pass to avoid cherry-picking.
    results={}
    failures=[]
    for metric,bound in gate['metrics'].items():
        readings=[]
        for row in applicable:
            value=row.get('metrics',{}).get(metric)
            if type(value) not in (int,float) or not math.isfinite(value):
                failures.append('missing_metric:'+metric)
                break
            readings.append(float(value))
        if len(readings)!=len(applicable):
            continue
        op,limit=next(iter(bound.items()))
        worst=max(readings) if op=='max' else min(readings)
        ok=(worst<=limit if op=='max' else worst>=limit)
        results[metric]={'worst':worst,'threshold':limit,'operator':op,
                         'passed':ok}
        if not ok:
            failures.append('threshold_violation:'+metric)
    if any(reason.startswith('missing_metric') for reason in failures):
        return {'state':'BLOCKED','reason':sorted(set(failures)),
                'metrics':results,'sample_count':len(applicable)}
    if invalid:
        return {'state':'BLOCKED','reason':['some_invalid_evidence']+sorted(set(invalid)),
                'metrics':results,'sample_count':len(applicable)}
    return {'state':'FAIL' if failures else 'PASS','reason':sorted(set(failures)),
            'metrics':results,'sample_count':len(applicable)}


def propose_tuning(contract, decisions):
    """Small, review-only adjustments; never relax quality thresholds."""
    factor=float(contract['policy']['max_single_adjustment_fraction'])
    proposed={}
    perf=decisions['performance']
    control=decisions['controls']
    perf_r=perf.get('reason',[])
    control_r=control.get('reason',[])
    perf_regression=any(str(reason).startswith('threshold_violation:') for reason in perf_r)
    input_conflict='threshold_violation:input_conflicts' in control_r
    for key,param in sorted(contract['tuning_parameters'].items()):
        if perf_regression and param['direction']=='decrease_if_over_budget':
            direction=-1
        elif input_conflict and param['direction']=='increase_if_conflict':
            direction=+1
        else:
            continue
        before=float(param['value'])
        step=float(param['step'])
        if before == 0:
            cap=step
        else:
            cap=max(step,abs(before)*factor)
        increment=min(step,cap)
        after=min(float(param['max']),max(float(param['min']),before+direction*increment))
        if after!=before:
            proposed[key]={'old':before,'candidate':round(after,5),
                           'reason':'performance_budget_exceeded' if direction<0
                           else 'input_conflicts_observed',
                           'requires_new_actual_measurement':True,
                           'automatically_applied_to_game':False}
    return proposed


def calibrate(contract,evidence):
    validate_contract(contract)
    require(type(evidence) is dict and evidence.get('schema')==1,
            'invalid_evidence_schema')
    require(type(evidence.get('records')) is list,
            'evidence_records_required')
    decisions={name:eval_gate(name,gate,evidence['records'])
               for name,gate in contract['gates'].items()}
    # Approval requires independent human reviewer and actual image provenance.
    art=evidence.get('art_review',{})
    approved=(type(art) is dict and art.get('approved') is True
              and type(art.get('reviewer')) is str and bool(art['reviewer'].strip())
              and type(art.get('reference_sha256')) is str
              and bool(SHA256.fullmatch(art['reference_sha256']))
              and type(art.get('actual_frame_sha256')) is str
              and bool(SHA256.fullmatch(art['actual_frame_sha256'])))
    decisions['art']={'state':'PASS' if approved else 'BLOCKED',
                      'reason':[] if approved else ['real_independent_art_review_missing']}
    suggestions=propose_tuning(contract,decisions)
    passed=all(item['state']=='PASS' for item in decisions.values())
    return {'schema':1,'status':'PASS' if passed else 'BLOCKED_OR_FAIL',
            'release_allowed':False, # This is a tuning tool, not an APK release signer.
            'quality_gates':decisions,
            'proposed_overrides':suggestions,
            'warnings':['This report cannot approve Android distribution.',
                        'Human art review and signed APK/PCK QA are separate.',
                        'Visual and control settings require physical Godot/Android validation.']}


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--contract',type=Path,required=True)
    parser.add_argument('--evidence',type=Path,required=True)
    parser.add_argument('--report',type=Path)
    args=parser.parse_args()
    try:
        report=calibrate(load_json(args.contract),load_json(args.evidence))
    except (OSError,ValueError,TypeError,KeyError) as error:
        raise SystemExit('TUNING_FAIL_CLOSED: '+str(error)) from error
    output=json.dumps(report,indent=2,ensure_ascii=False)+'\n'
    if args.report:
        args.report.write_text(output,encoding='utf-8')
    print(output)
)

# Non-negotiable project engineering floors. Parameter suggestions cannot
# weaken these even if an edited JSON contract asks for an easier pass.
QUALITY_FLOORS = {
    'visual': {'missing_meshes': ('max',0),
               'floating_foundations': ('max',0),
               'roof_coverage_fraction': ('min',0.25),
               'roof_tile_legibility_faults': ('max',0),
               'material_stretch_faults': ('max',0)},
    'controls': {'input_conflicts': ('max',0),
                 'touch_to_feedback_p95_ms': ('max',100),
                 'camera_obstruction_frames': ('max',0),
                 'movement_foot_sliding_faults': ('max',0)},
    'logic': {'entity_id_collisions': ('max',0),
              'inventory_balance_faults': ('max',0),
              'save_recovery_faults': ('max',0),
              'recipe_mass_faults': ('max',0),
              'unearned_unlocks': ('max',0)},
    'performance': {'fps_p05': ('min',30),
                    'frame_p95_ms': ('max',33.34),
                    'draw_calls_p95': ('max',200),
                    'triangle_count_p95': ('max',150000),
                    'crashes': ('max',0)},
}


class TuneError(ValueError):
    pass


def require(ok, message):
    if not ok:
        raise TuneError(message)


def numeric(x, field):
    require(type(x) in (int, float) and math.isfinite(x), f'{field}:invalid_numeric')
    return float(x)


def load_json(path):
    return json.loads(Path(path).read_text(encoding='utf-8'))


def validate_contract(contract):
    require(type(contract) is dict and contract.get('schema') == 1,
            'contract_schema_mismatch')
    policy = contract.get('policy', {})
    require(policy.get('unknown_evidence') == 'BLOCK'
            and policy.get('art_approval') == 'HUMAN_REQUIRED'
            and policy.get('save_and_provenance') == 'INVARIANT',
            'weak_or_untrusted_qa_policy')
    require(set(contract.get('gates', {})) == {
        'visual','controls','logic','performance'},'incomplete_quality_gates')
    factor = numeric(policy.get('max_single_adjustment_fraction'),
                     'max_single_adjustment_fraction')
    require(0 < factor <= 0.1, 'unsafe_tuning_rate')
    require(policy.get('device_min_duration_seconds',0) >= 900,
            'short_phone_benchmark_prohibited')
    for domain,gate in contract['gates'].items():
        require(gate.get('require_source') in ('godot_real','android_real'),
                f'{domain}:invalid_evidence_source')
        require(type(gate.get('metrics')) is dict and gate['metrics'],
                f'{domain}:no_quality_metrics')
        for key,bound in gate['metrics'].items():
            require(type(bound) is dict and len(bound)==1
                    and (set(bound)=={'min'} or set(bound)=={'max'}),
                    f'{domain}:{key}:invalid_threshold')
            numeric(next(iter(bound.values())),f'{domain}:{key}:threshold')
    for name,p in contract.get('tuning_parameters',{}).items():
        require(type(p) is dict,'tuning_record_invalid')
        current=numeric(p.get('value'),name)
        low=numeric(p.get('min'),name)
        high=numeric(p.get('max'),name)
        step=numeric(p.get('step'),name)
        require(low<=current<=high and high>low and step>0,
                f'{name}:bad_tuning_limits')
        require(p.get('direction') in (
            'human_review','decrease_if_over_budget','increase_if_conflict'),
            f'{name}:unknown_tuning_strategy')
        require(set(p.get('requires',[])).issubset(contract['gates']),
                f'{name}:unknown_dependency')


def eval_gate(name, gate, records):
    applicable=[]
    invalid=[]
    for record in records:
        if record.get('domain')!=name:
            continue
        origin=record.get('origin')
        if origin!=gate['require_source']:
            invalid.append('not_real_'+gate['require_source'])
            continue
        commit=record.get('commit')
        if type(commit) is not str or not SHA.fullmatch(commit):
            invalid.append('missing_verified_git_commit')
            continue
        proofs=record.get('proof_sha256')
        if type(proofs) is not list or len(proofs)==0 or any(
            type(x) is not str or not SHA256.fullmatch(x) for x in proofs
        ):
            invalid.append('missing_proof_hash')
            continue
        if type(record.get('device')) is not str or not record['device'].strip():
            invalid.append('missing_device_or_renderer')
            continue
        if name=='performance' and numeric(record.get('sample_seconds',0),
                                           'performance:duration') < gate.get('sample_seconds',0):
            invalid.append('insufficient_sustained_benchmark')
            continue
        applicable.append(record)
    if not applicable:
        return {'state':'BLOCKED','reason':sorted(set(invalid)) or ['no_real_evidence'],
                'metrics':{}}
    # Every real sample must pass to avoid cherry-picking.
    results={}
    failures=[]
    for metric,bound in gate['metrics'].items():
        readings=[]
        for row in applicable:
            value=row.get('metrics',{}).get(metric)
            if type(value) not in (int,float) or not math.isfinite(value):
                failures.append('missing_metric:'+metric)
                break
            readings.append(float(value))
        if len(readings)!=len(applicable):
            continue
        op,limit=next(iter(bound.items()))
        worst=max(readings) if op=='max' else min(readings)
        ok=(worst<=limit if op=='max' else worst>=limit)
        results[metric]={'worst':worst,'threshold':limit,'operator':op,
                         'passed':ok}
        if not ok:
            failures.append('threshold_violation:'+metric)
    if any(reason.startswith('missing_metric') for reason in failures):
        return {'state':'BLOCKED','reason':sorted(set(failures)),
                'metrics':results,'sample_count':len(applicable)}
    if invalid:
        return {'state':'BLOCKED','reason':['some_invalid_evidence']+sorted(set(invalid)),
                'metrics':results,'sample_count':len(applicable)}
    return {'state':'FAIL' if failures else 'PASS','reason':sorted(set(failures)),
            'metrics':results,'sample_count':len(applicable)}


def propose_tuning(contract, decisions):
    """Small, review-only adjustments; never relax quality thresholds."""
    factor=float(contract['policy']['max_single_adjustment_fraction'])
    proposed={}
    perf=decisions['performance']
    control=decisions['controls']
    perf_r=perf.get('reason',[])
    control_r=control.get('reason',[])
    perf_regression=any(str(reason).startswith('threshold_violation:') for reason in perf_r)
    input_conflict='threshold_violation:input_conflicts' in control_r
    for key,param in sorted(contract['tuning_parameters'].items()):
        if perf_regression and param['direction']=='decrease_if_over_budget':
            direction=-1
        elif input_conflict and param['direction']=='increase_if_conflict':
            direction=+1
        else:
            continue
        before=float(param['value'])
        step=float(param['step'])
        if before == 0:
            cap=step
        else:
            cap=max(step,abs(before)*factor)
        increment=min(step,cap)
        after=min(float(param['max']),max(float(param['min']),before+direction*increment))
        if after!=before:
            proposed[key]={'old':before,'candidate':round(after,5),
                           'reason':'performance_budget_exceeded' if direction<0
                           else 'input_conflicts_observed',
                           'requires_new_actual_measurement':True,
                           'automatically_applied_to_game':False}
    return proposed


def calibrate(contract,evidence):
    validate_contract(contract)
    require(type(evidence) is dict and evidence.get('schema')==1,
            'invalid_evidence_schema')
    require(type(evidence.get('records')) is list,
            'evidence_records_required')
    decisions={name:eval_gate(name,gate,evidence['records'])
               for name,gate in contract['gates'].items()}
    # Approval requires independent human reviewer and actual image provenance.
    art=evidence.get('art_review',{})
    approved=(type(art) is dict and art.get('approved') is True
              and type(art.get('reviewer')) is str and bool(art['reviewer'].strip())
              and type(art.get('reference_sha256')) is str
              and bool(SHA256.fullmatch(art['reference_sha256']))
              and type(art.get('actual_frame_sha256')) is str
              and bool(SHA256.fullmatch(art['actual_frame_sha256'])))
    decisions['art']={'state':'PASS' if approved else 'BLOCKED',
                      'reason':[] if approved else ['real_independent_art_review_missing']}
    suggestions=propose_tuning(contract,decisions)
    passed=all(item['state']=='PASS' for item in decisions.values())
    return {'schema':1,'status':'PASS' if passed else 'BLOCKED_OR_FAIL',
            'release_allowed':False, # This is a tuning tool, not an APK release signer.
            'quality_gates':decisions,
            'proposed_overrides':suggestions,
            'warnings':['This report cannot approve Android distribution.',
                        'Human art review and signed APK/PCK QA are separate.',
                        'Visual and control settings require physical Godot/Android validation.']}


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--contract',type=Path,required=True)
    parser.add_argument('--evidence',type=Path,required=True)
    parser.add_argument('--report',type=Path)
    args=parser.parse_args()
    try:
        report=calibrate(load_json(args.contract),load_json(args.evidence))
    except (OSError,ValueError,TypeError,KeyError) as error:
        raise SystemExit('TUNING_FAIL_CLOSED: '+str(error)) from error
    output=json.dumps(report,indent=2,ensure_ascii=False)+'\n'
    if args.report:
        args.report.write_text(output,encoding='utf-8')
    print(output)
