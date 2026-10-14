#!/usr/bin/env python3
"""Strict declarative crafting DAG. No WorldState writes, no free item grants.

Experimental recipes are merely proposals for future bounded R&D:
a player cannot invent arbitrary mass or bypass evidence/unlock requirements.
Only the existing Godot WorldState may commit jobs, stocks and provenance.
"""
from __future__ import annotations

import argparse
from collections import defaultdict
import json
import math
from pathlib import Path
import re

ID = re.compile(r'^[a-z][a-z0-9_]{1,63}$')
STAGES = {'raw', 'intermediate', 'product', 'byproduct', 'construction'}


class CatalogError(ValueError):
    pass


def require(ok, code):
    if not ok:
        raise CatalogError(code)


def integer(x, low, high, label):
    require(type(x) is int and low <= x <= high, label)
    return x


def uniq_ids(rows, label):
    require(type(rows) is list, f'{label}_not_a_list')
    result = {}
    for row in rows:
        require(isinstance(row, dict), f'{label}_record_type')
        key = row.get('id')
        require(type(key) is str and ID.fullmatch(key) is not None,
                f'{label}_invalid_id:{key}')
        require(key not in result, f'{label}_duplicate:{key}')
        result[key] = row
    return result


def order_graph(edges, label):
    states = {}
    result = []
    def walk(n):
        state = states.get(n, 0)
        require(state != 1, f'{label}_cycle_at:{n}')
        if state == 2:
            return
        states[n] = 1
        for dep in sorted(edges.get(n, set())):
            walk(dep)
        states[n] = 2
        result.append(n)
    for node in sorted(edges):
        walk(node)
    return result


class CraftGraph:
    def __init__(self, document):
        require(isinstance(document, dict) and document.get('schema') == 1,
                'catalog_schema_unsupported')
        require(document.get('status') == 'design_candidate_not_integrated',
                'catalog_cannot_self_assert_game_release')
        self.document = document
        self.items = uniq_ids(document.get('items'), 'item')
        self.recipes = uniq_ids(document.get('recipes'), 'recipe')
        self.research = uniq_ids(document.get('research'), 'research')
        self.blueprints = uniq_ids(document.get('blueprints'), 'blueprint')
        self.producers = defaultdict(list)
        self.consumers = defaultdict(list)
        self.validate()

    @staticmethod
    def load(path):
        return CraftGraph(json.loads(Path(path).read_text(encoding='utf-8')))

    def validate(self):
        require(self.document.get('units') == 'integer_item_units_with_declared_gram_mass',
                'units_not_canonical')
        require(self.document.get('world_authority') == 'existing_WorldState_only',
                'second_world_inventory_forbidden')
        for key, item in self.items.items():
            require(type(item.get('name')) is str and item['name'].strip(),
                    f'{key}:name')
            require(item.get('stage') in STAGES, f'{key}:stage')
            integer(item.get('mass_g'), 1, 1000000000, f'{key}:mass')
            require(type(item.get('origin')) is str and item['origin'].strip(),
                    f'{key}:origin')
        for key, research in self.research.items():
            integer(research.get('work_minutes'), 1, 1000000,
                    f'{key}:research_time')
            requires = research.get('requires')
            require(type(requires) is list, f'{key}:research_requires')
            require(len(requires)==len(set(requires)), f'{key}:duplicate_research_dependency')
            require(all(i in self.research and i!=key for i in requires),
                    f'{key}:unknown_research_dependency')
            evidence = research.get('observations')
            require(type(evidence) is list and len(evidence)>0
                    and len(set(evidence))==len(evidence)
                    and all(isinstance(e,str) and ID.fullmatch(e) for e in evidence),
                    f'{key}:research_evidence')
            costs=research.get('cost')
            # paper is an established canonical resource in original WorldState.
            require(type(costs) is dict and len(costs)>0 and set(costs)=={'paper'},
                    f'{key}:unproven_research_cost')
            integer(costs['paper'],1,10000,f'{key}:paper_cost')
        order_graph({k:set(v['requires']) for k,v in self.research.items()},
                    'research')
        for bid, bp in self.blueprints.items():
            require(type(bp.get('name')) is str and bp['name'].strip(),
                    f'{bid}:blueprint_name')
            refs=bp.get('reveals')
            require(type(refs) is list and refs and len(set(refs))==len(refs)
                    and all(r in self.recipes for r in refs),
                    f'{bid}:blueprint_references')
        requires_research = {}
        for key, recipe in self.recipes.items():
            for channel in ('inputs','outputs'):
                d=recipe.get(channel)
                require(type(d) is dict and len(d)>0,
                        f'{key}:{channel}_empty')
                for item_id,amount in d.items():
                    require(item_id in self.items, f'{key}:unknown_item:{item_id}')
                    integer(amount,1,100000,f'{key}:{channel}:{item_id}')
            require(not (set(recipe['inputs']) & set(recipe['outputs'])),
                    f'{key}:self_regenerating_recipe')
            integer(recipe.get('loss_g'),0,1000000000,f'{key}:loss_g')
            integer(recipe.get('work_minutes'),1,10000000,f'{key}:minutes')
            integer(recipe.get('energy_kj'),0,1000000000,f'{key}:energy')
            require(type(recipe.get('station')) is str and ID.fullmatch(recipe['station']),
                    f'{key}:station')
            inflow=sum(self.items[i]['mass_g']*n for i,n in recipe['inputs'].items())
            outflow=sum(self.items[i]['mass_g']*n for i,n in recipe['outputs'].items())
            require(inflow == outflow + recipe['loss_g'],
                    f'{key}:mass_not_balanced:in={inflow}:out={outflow}+loss={recipe["loss_g"]}')
            unlock=recipe.get('unlock')
            require(type(unlock) is dict and unlock.get('mode') in
                    ('known','research','blueprint'),f'{key}:unlock_mode')
            if unlock['mode']=='known':
                require(set(unlock)=={'mode'},f'{key}:illegal_known_unlock_fields')
            else:
                require(unlock.get('id') in (self.research if unlock['mode']=='research' else self.blueprints),
                        f'{key}:unknown_unlock')
                if unlock['mode']=='blueprint':
                    require(key in self.blueprints[unlock['id']]['reveals'],
                            f'{key}:not_revealed_by_blueprint')
                    if 'research' in unlock:
                        require(unlock['research'] in self.research,
                                f'{key}:unknown_prerequisite_research')
            for item_id in recipe['inputs']:
                self.consumers[item_id].append(key)
            for item_id in recipe['outputs']:
                self.producers[item_id].append(key)
        graph={item_id:set() for item_id in self.items}
        for recipe in self.recipes.values():
            for out in recipe['outputs']:
                graph[out].update(recipe['inputs'])
        self.item_order=order_graph(graph,'materials')
        self.research_order=order_graph(
            {k:set(v['requires']) for k,v in self.research.items()},'research')
        # All intermediate/finished items must have a maker; raw items must
        # originate in the real ecology, not inside a recipe.
        for item_id,item in self.items.items():
            makers=self.producers.get(item_id,[])
            if item['stage']=='raw':
                require(not makers,f'{item_id}:raw_resource_generated_by_recipe')
            else:
                require(makers,f'{item_id}:orphan_nonraw_item')
        for key,recipe in self.recipes.items():
            if recipe['station']=='kiln':
                require(recipe['energy_kj']>0 and 'firewood' in recipe['inputs'],
                        f'{key}:free_furnace_heat')

    def unlock_gaps(self, recipe_id, known_research=(), found_blueprints=()):
        require(recipe_id in self.recipes,'unknown_recipe')
        row=self.recipes[recipe_id]['unlock']
        gaps=[]
        if row['mode']=='research' and row['id'] not in known_research:
            gaps.append('research:'+row['id'])
        if row['mode']=='blueprint':
            if row['id'] not in found_blueprints:
                gaps.append('blueprint:'+row['id'])
            if 'research' in row and row['research'] not in known_research:
                gaps.append('research:'+row['research'])
        return gaps

    def can_research(self, technology_id, known_research, observations, inventory):
        require(technology_id in self.research,'unknown_research')
        r=self.research[technology_id]
        missing = ['research:'+key for key in r['requires'] if key not in known_research]
        missing += ['observation:'+key for key in r['observations'] if key not in observations]
        missing += ['stock:'+key for key,value in r['cost'].items() if inventory.get(key,0)<value]
        return {'allowed':not missing, 'missing':missing,
                'research_minutes':r['work_minutes'],
                'debits':r['cost'].copy() if not missing else {},
                'effect':'proposal_only_no_worldstate_mutation'}

    def can_start(self, recipe_id, inventory, known_research=(),
                  found_blueprints=(), stations=()):
        require(recipe_id in self.recipes,'unknown_recipe')
        recipe=self.recipes[recipe_id]
        missing=self.unlock_gaps(recipe_id,known_research,found_blueprints)
        if recipe['station'] not in stations:
            missing.append('station:'+recipe['station'])
        missing += ['stock:'+key for key,quantity in recipe['inputs'].items()
                    if inventory.get(key,0)<quantity]
        return {'allowed':not missing, 'missing':missing,
                'debits':recipe['inputs'].copy() if not missing else {},
                'credits':recipe['outputs'].copy() if not missing else {},
                'time_minutes':recipe['work_minutes'],
                'loss_g':recipe['loss_g'],
                'effect':'preview_only_existing_WorldState_must_commit'}

    def reachable_from(self, item_id):
        require(item_id in self.items,'unknown_item')
        found={item_id}
        remaining=[item_id]
        while remaining:
            for rid in self.consumers.get(remaining.pop(),()):
                for product in self.recipes[rid]['outputs']:
                    if product not in found:
                        found.add(product)
                        remaining.append(product)
        return sorted(found-{item_id})

    def input_frontier(self, target, quantity=1):
        """Conservative gross raw-material dependency estimate, not a bill.
        Co-products, ownership, site, time, research and stored inventory are
        NOT optimized. Never auto-debit from this planning estimate.
        """
        require(target in self.items,'unknown_target')
        integer(quantity,1,100000,'target_quantity')
        raw=defaultdict(int)
        jobs=defaultdict(int)
        def trace(item,required):
            producers=self.producers.get(item,())
            if not producers:
                raw[item]+=required
                return
            # Deterministically select cheapest single-stage producer.
            rid=min(producers,key=lambda r:(self.recipes[r]['work_minutes'],r))
            recipe=self.recipes[rid]
            batch=math.ceil(required/recipe['outputs'][item])
            jobs[rid]+=batch
            for source,count in recipe['inputs'].items():
                trace(source,batch*count)
        trace(target,quantity)
        return {'target':target,'quantity':quantity,
                'raw_gross':dict(sorted(raw.items())),
                'operations_gross':dict(sorted(jobs.items())),
                'mode':'gross_estimate_not_inventory_or_byproduct_optimized'}

    def evaluate_experiment(self, proposal):
        """Research sandbox: may REJECT or propose, can never grant inventory."""
        require(type(proposal) is dict,'proposal_must_be_dict')
        inputs=proposal.get('inputs')
        outputs=proposal.get('outputs')
        require(type(inputs) is dict and inputs,'experiment_missing_inputs')
        require(type(outputs) is dict and outputs,'experiment_missing_outputs')
        require(type(proposal.get('station')) is str
                and ID.fullmatch(proposal['station']), 'experiment_station_required')
        require(type(proposal.get('evidence')) is list
                and len(set(proposal['evidence']))>=2
                and all(type(e) is str and ID.fullmatch(e) for e in proposal['evidence']),
                'experiment_needs_independent_observations')
        for group in (inputs,outputs):
            for id,qty in group.items():
                require(id in self.items,'experiment_unknown_item')
                integer(qty,1,10000,'experiment_count')
        require(not set(inputs)&set(outputs),'experiment_self_regeneration')
        in_mass=sum(self.items[i]['mass_g']*q for i,q in inputs.items())
        out_mass=sum(self.items[i]['mass_g']*q for i,q in outputs.items())
        require(out_mass<=in_mass,'experiment_fabricates_mass')
        integer(proposal.get('work_minutes'),1,100000,'experiment_time')
        return {'accepted_as_recipe':False,
                'status':'candidate_requires_review_and_actual_experiment',
                'mass_remaining_g':in_mass-out_mass,
                'world_granted_items':{},
                'warning':'No inventory was mutated; a verified on-world work order is required.'}

    def summary(self):
        return {'schema':1,'items':len(self.items),
                'recipes':len(self.recipes),'research':len(self.research),
                'blueprints':len(self.blueprints),
                'max_depth':self.depth(),
                'sample_chain':self.input_frontier('roof_module'),
                'release_state':'design_candidate_not_integrated'}

    def depth(self):
        depth={}
        for key in self.item_order:
            makers=self.producers.get(key,())
            depth[key]=max((1+max(depth[i] for i in self.recipes[r]['inputs'])
                            for r in makers),default=0)
        return max(depth.values())

if __name__=='__main__':
    cli=argparse.ArgumentParser()
    cli.add_argument('--catalog',type=Path,required=True)
    cli.add_argument('--report',type=Path)
    cli.add_argument('--from-item',default=None)
    cli.add_argument('--target-item',default=None)
    args=cli.parse_args()
    try:
        graph=CraftGraph.load(args.catalog)
        result=graph.summary()
        if args.from_item:
            result['reachable']=graph.reachable_from(args.from_item)
        if args.target_item:
            result['plan']=graph.input_frontier(args.target_item)
    except (OSError,ValueError,KeyError,TypeError) as error:
        raise SystemExit(f'CRAFT_GRAPH_FAIL_CLOSED: {error}') from error
    output=json.dumps(result,ensure_ascii=False,indent=2)+'\n'
    if args.report:
        args.report.write_text(output,encoding='utf-8')
    print(output)
