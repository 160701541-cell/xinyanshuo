#!/usr/bin/env python3
"""Generate and audit per-object manufacturing contracts for ANY catalog item.

A new item is not an asset just because its ID was added. The gate demands
independent receipts across construction, Godot, world authority and phone.
This system *never* marks a draft as production-ready.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re

from craft_graph import CraftGraph

RECEIPT = re.compile(r'^[0-9a-f]{64}$')
STAGES = ('specification','source_art','physical_authority','godot_import',
          'visual_review','controls','android_performance','save_compatibility',
          'signed_release')
RULES = {
    'specification':'traceable_metre_scale_and_use_case',
    'source_art':'original_or_licensed_mesh_uv_pbr_lod',
    'physical_authority':'worldstate_transaction_and_provenance',
    'godot_import':'real_godot_4_4_1_scene_and_frame',
    'visual_review':'reference_actual_same_camera_independent_approval',
    'controls':'real_touch_camera_and_use_collision',
    'android_performance':'physical_android_15min_p95_metrics',
    'save_compatibility':'old_save_backup_and_no_duplication',
    'signed_release':'same_RSA_or_original_ANDROID_certificate',
}


class ContractFailure(ValueError):
    pass


def check(test, why):
    if not test:
        raise ContractFailure(why)


def make_contract(graph):
    cards={}
    for item_id,item in sorted(graph.items.items()):
        cards[item_id]={
            'item_id':item_id,
            'canonical_mass_g':item['mass_g'],
            'source_or_recipe':item['origin'],
            'producer_recipe_ids':sorted(graph.producers.get(item_id,[])),
            'consumer_recipe_ids':sorted(graph.consumers.get(item_id,[])),
            'display_model_asset_id':None,
            'source_blend_or_licensed_asset':None,
            'lod_mesh_ids':[],
            'pbr_atlas_ids':[],
            'canonical_worldstate_entity_or_lot_type':None,
            'player_use_case':None,
            'risks_and_failure_modes':[],
            'gate_status':{stage:'BLOCKED' for stage in STAGES},
            'evidence_receipts':{},
        }
    return {'schema':1,'authority':'canonical_WorldState_only',
            'status':'draft_never_publish',
            'items':cards}


def verify_contract(graph,doc):
    check(type(doc) is dict and doc.get('schema')==1
          and doc.get('authority')=='canonical_WorldState_only',
          'contract_identity_or_authority')
    check(set(doc.get('items',{}))==set(graph.items),
          'contract_missing_or_extra_catalog_items')
    violations=[]
    eligible=[]
    for item_id,card in sorted(doc['items'].items()):
        check(type(card) is dict and card.get('item_id')==item_id,
              item_id+':identity_mismatch')
        check(card.get('canonical_mass_g')==graph.items[item_id]['mass_g'],
              item_id+':physical_mass_changed')
        check(card.get('source_or_recipe')==graph.items[item_id]['origin'],
              item_id+':provenance_changed')
        check(card.get('producer_recipe_ids')==sorted(graph.producers.get(item_id,[])),
              item_id+':producer_paths_tampered')
        check(card.get('consumer_recipe_ids')==sorted(graph.consumers.get(item_id,[])),
              item_id+':consumer_paths_tampered')
        gate=card.get('gate_status')
        check(type(gate) is dict and set(gate)==set(STAGES),
              item_id+':missing_engineering_gate')
        proofs=card.get('evidence_receipts',{})
        check(type(proofs) is dict and set(proofs).issubset(STAGES),
              item_id+':unknown_evidence')
        for stage in STAGES:
            status=gate[stage]
            check(status in ('BLOCKED','FAIL','PASS'),
                  item_id+':bad_gate_state')
            if status=='PASS':
                proof=proofs.get(stage)
                check(type(proof) is dict and set(proof)==
                      {'sha256','artifact_path','engine_or_device','reviewer'},
                      item_id+':fake_stage_pass:'+stage)
                check(type(proof['sha256']) is str
                      and RECEIPT.fullmatch(proof['sha256'])
                      and all(type(proof[k]) is str and proof[k].strip()
                              for k in ('artifact_path','engine_or_device','reviewer')),
                      item_id+':incomplete_stage_proof:'+stage)
            else:
                check(stage not in proofs,
                      item_id+':conflicting_stage_proof:'+stage)
        if all(gate[stage]=='PASS' for stage in STAGES):
            # Even nine submitted metadata hashes cannot independently validate
            # signatures or authenticate a phone. This is a candidate for
            # manual + release-CI review, never a publish button.
            eligible.append(item_id)
        else:
            violations.append({'item':item_id,'missing_or_failed':
                               [stage for stage in STAGES if gate[stage]!='PASS']})
    return {'schema':1,'status':'SPEC_AUDITED',
            'catalog_item_count':len(doc['items']),
            'complete_receipt_sets_for_separate_review':eligible,
            'release_approved':False,
            'unproven_items':violations,
            'contract_rules':RULES}


if __name__=='__main__':
    cli=argparse.ArgumentParser()
    cli.add_argument('--catalog',required=True,type=Path)
    cli.add_argument('--cards',type=Path)
    cli.add_argument('--write-new-cards',type=Path)
    cli.add_argument('--report',type=Path)
    args=cli.parse_args()
    try:
        graph=CraftGraph.load(args.catalog)
        if args.write_new_cards:
            check(not args.write_new_cards.exists(),
                  'refuse_to_overwrite_existing_worked_contracts')
            doc=make_contract(graph)
            args.write_new_cards.parent.mkdir(parents=True,exist_ok=True)
            args.write_new_cards.write_text(
                json.dumps(doc,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
        elif args.cards:
            doc=json.loads(args.cards.read_text(encoding='utf-8'))
        else:
            doc=make_contract(graph)
        report=verify_contract(graph,doc)
    except (OSError,ValueError,TypeError) as error:
        raise SystemExit('MANUFACTURING_CONTRACT_FAIL_CLOSED: '+str(error)) from error
    output=json.dumps(report,ensure_ascii=False,indent=2)+'\n'
    if args.report:
        args.report.write_text(output,encoding='utf-8')
    print(output)
