"""Per-object production contracts must fail-closed before assets can ship."""
import copy
import json
from pathlib import Path
import unittest

from craft_graph import CraftGraph
from production_contracts import ContractFailure, make_contract, verify_contract, STAGES

CATALOG=Path(__file__).resolve().parent.parent/'data/craft/material_graph.v1.json'

class ProductionContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.graph=CraftGraph.load(CATALOG)

    def fresh(self):
        return make_contract(self.graph)

    def test_every_item_has_independent_full_gate_set(self):
        doc=self.fresh()
        self.assertEqual(len(doc['items']),24)
        for row in doc['items'].values():
            self.assertEqual(set(row['gate_status']),set(STAGES))
        result=verify_contract(self.graph,doc)
        self.assertEqual(len(result['unproven_items']),24)
        self.assertFalse(result['release_approved'])

    def test_lacking_provenance_not_accepted(self):
        doc=self.fresh()
        doc['items']['clay_soil']['source_or_recipe']='magic'
        with self.assertRaisesRegex(ContractFailure,'provenance_changed'):
            verify_contract(self.graph,doc)

    def test_cannot_omit_complex_interaction_test(self):
        doc=self.fresh()
        del doc['items']['roof_module']['gate_status']['controls']
        with self.assertRaisesRegex(ContractFailure,'missing_engineering_gate'):
            verify_contract(self.graph,doc)

    def test_no_one_can_self_label_pass_without_proof(self):
        doc=self.fresh()
        doc['items']['roof_module']['gate_status']['source_art']='PASS'
        with self.assertRaisesRegex(ContractFailure,'fake_stage_pass'):
            verify_contract(self.graph,doc)

    def test_same_sha_placeholder_is_not_a_release(self):
        doc=self.fresh()
        for stage in STAGES:
            doc['items']['roof_module']['gate_status'][stage]='PASS'
            doc['items']['roof_module']['evidence_receipts'][stage]={
                'sha256':'a'*64,'artifact_path':'candidate',
                'engine_or_device':'claimed_only','reviewer':'claimed_only'}
        result=verify_contract(self.graph,doc)
        self.assertIn('roof_module',result['complete_receipt_sets_for_separate_review'])
        self.assertFalse(result['release_approved'])

    def test_mass_mismatch_with_real_catalog_is_blocked(self):
        doc=self.fresh()
        doc['items']['log']['canonical_mass_g']=8000
        with self.assertRaisesRegex(ContractFailure,'physical_mass_changed'):
            verify_contract(self.graph,doc)

    def test_no_extra_magic_item(self):
        doc=self.fresh()
        doc['items']['magic_gold']=copy.deepcopy(doc['items']['log'])
        with self.assertRaisesRegex(ContractFailure,'missing_or_extra'):
            verify_contract(self.graph,doc)

    def test_status_cannot_be_the_word_done(self):
        doc=self.fresh()
        doc['items']['qing_roof_tile']['gate_status']['visual_review']='DONE'
        with self.assertRaisesRegex(ContractFailure,'bad_gate_state'):
            verify_contract(self.graph,doc)

if __name__=='__main__':
    unittest.main()
