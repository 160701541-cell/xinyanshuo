"""Hard gates: test real catalog, tampering, unlocks, self-research/no-free-items."""
import copy
import json
from pathlib import Path
import unittest
from craft_graph import CatalogError, CraftGraph

CATALOG = (Path(__file__).resolve().parent.parent
           / 'data/craft/material_graph.v1.json')

class GraphTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.raw=json.loads(CATALOG.read_text(encoding='utf-8'))
        cls.graph=CraftGraph(cls.raw)

    def change(self, fn):
        document=copy.deepcopy(self.raw)
        fn(document)
        return CraftGraph(document)

    def test_canonical_counts_and_multistep_soil_chain(self):
        g=self.graph
        self.assertGreaterEqual(len(g.items),20)
        self.assertGreaterEqual(len(g.recipes),12)
        self.assertGreaterEqual(g.depth(),4)
        self.assertIn('roof_module',g.reachable_from('clay_soil'))
        self.assertIn('wall_module',g.reachable_from('clay_soil'))
        self.assertIn('qing_roof_tile',g.reachable_from('clay_soil'))

    def test_gross_plan_includes_real_resources(self):
        p=self.graph.input_frontier('roof_module')
        self.assertEqual(p['quantity'],1)
        self.assertGreater(p['raw_gross']['clay_soil'],0)
        self.assertGreater(p['raw_gross']['log'],0)
        self.assertEqual(p['operations_gross']['assemble_roof_module'],1)

    def test_no_unlock_no_stock_no_station(self):
        result=self.graph.can_start('fire_roof_tile',{},(),(),())
        self.assertFalse(result['allowed'])
        self.assertIn('research:ceramics_1',result['missing'])
        self.assertIn('blueprint:bp_kiln_arch',result['missing'])
        self.assertEqual(result['credits'],{})

    def test_unlocks_still_require_stock_station(self):
        result=self.graph.can_start('fire_roof_tile',
            {'tile_blank':1,'firewood':1},['ceramics_1'],['bp_kiln_arch'],['kiln'])
        self.assertTrue(result['allowed'])
        self.assertEqual(result['debits'],{'tile_blank':1,'firewood':1})
        self.assertEqual(result['credits'],{'qing_roof_tile':1,'ash':1})
        self.assertEqual(result['effect'],
                         'preview_only_existing_WorldState_must_commit')

    def test_research_requires_evidence_and_real_cost(self):
        research=self.graph.can_research('ceramics_1',[],[],{'paper':5})
        self.assertFalse(research['allowed'])
        self.assertIn('research:clay_filtering',research['missing'])
        research=self.graph.can_research('ceramics_1',['clay_filtering'],
           ['kiln_temperature_logged','fired_sample_inspected'],{'paper':2})
        self.assertTrue(research['allowed'])
        self.assertEqual(research['debits'],{'paper':2})

    def test_experiment_only_candidate_never_free_recipe(self):
        proposal={'inputs':{'settled_clay':1,'water':1},
                  'outputs':{'tile_blank':1},'station':'tile_mould',
                  'evidence':['clay_test_001','test_firing_002'],
                  'work_minutes':50}
        before=json.dumps(self.raw,sort_keys=True)
        result=self.graph.evaluate_experiment(proposal)
        self.assertFalse(result['accepted_as_recipe'])
        self.assertEqual(result['world_granted_items'],{})
        self.assertEqual(json.dumps(self.raw,sort_keys=True),before)

    def test_experiment_fabricating_mass_rejected(self):
        with self.assertRaisesRegex(CatalogError,'fabricates_mass'):
            self.graph.evaluate_experiment({
                'inputs':{'water':1},'outputs':{'roof_module':2},
                'station':'table','evidence':['test_a','test_b'],
                'work_minutes':5})

    def test_mass_cheat_rejected(self):
        with self.assertRaisesRegex(CatalogError,'mass_not_balanced'):
            self.change(lambda d:d['recipes'][0]['outputs'].update(clay_slurry=100))

    def test_existing_world_mass_scale_is_preserved(self):
        self.assertEqual(self.graph.items['log']['mass_g'],40000)
        self.assertEqual(self.graph.items['timber_beam_standard']['mass_g'],20000)
        self.assertEqual(self.graph.items['roof_module']['mass_g'],43800)

    def test_legacy_mass_scale_tamper_is_rejected(self):
        with self.assertRaisesRegex(CatalogError,'material_mass_incompatible'):
            self.change(lambda d: d['items'][5].update(mass_g=8000))

    def test_unknown_items_rejected(self):
        with self.assertRaisesRegex(CatalogError,'unknown_item'):
            self.change(lambda d:d['recipes'][0]['inputs'].update(ghost_gold=1))

    def test_duplicate_ids_rejected(self):
        with self.assertRaisesRegex(CatalogError,'item_duplicate'):
            self.change(lambda d:d['items'].append(copy.deepcopy(d['items'][0])))

    def test_unlock_bypass_rejected(self):
        with self.assertRaisesRegex(CatalogError,'not_revealed_by_blueprint'):
            self.change(lambda d:d['recipes'][1]['unlock'].update(id='bp_wall_module'))

    def test_research_cycle_rejected(self):
        with self.assertRaisesRegex(CatalogError,'research_cycle_at'):
            self.change(lambda d:d['research'][0]['requires'].append('ceramics_1'))

    def test_material_cycle_rejected(self):
        with self.assertRaisesRegex(CatalogError,'materials_cycle_at'):
            def mutate(d):
                # Make raw clay soil no longer raw, and introduce a cycle
                d['items'][0]['stage']='intermediate'
                d['recipes'].append({
                  'id':'cycle_clay','name':'循环泥',
                  'inputs':{'settled_clay':1},'outputs':{'clay_soil':1},
                  'loss_g':500,'work_minutes':20,'energy_kj':0,
                  'station':'mixing_tub','unlock':{'mode':'known'}})
            self.change(mutate)

    def test_unsafe_research_self_approval_rejected(self):
        with self.assertRaisesRegex(CatalogError,'experiment_needs_independent_observations'):
            self.graph.evaluate_experiment({
                'inputs':{'water':1},'outputs':{'washed_sand':1},
                'station':'sieve','work_minutes':10,'evidence':['i_say_so']})

    def test_no_fake_raw_generation(self):
        with self.assertRaisesRegex(CatalogError,'raw_resource_generated_by_recipe'):
            def mutate(d):
                d['recipes'].append({
                  'id':'mint_firewood','name':'火生柴',
                  'inputs':{'roof_module':1},'outputs':{'firewood':1},
                  'loss_g':42800,'work_minutes':1,'energy_kj':0,
                  'station':'table','unlock':{'mode':'known'}})
            self.change(mutate)

if __name__=='__main__':
    unittest.main()
