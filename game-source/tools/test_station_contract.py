"""No workstation exists merely because a recipe names it."""
import copy
import json
from pathlib import Path
import unittest
from craft_graph import CraftGraph, CatalogError
from station_contract import inspect

ROOT=Path(__file__).resolve().parent.parent/'data/craft'
class StationProvenanceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.graph=CraftGraph.load(ROOT/'material_graph.v1.json')
        cls.raw=json.loads((ROOT/'station_provenance.v1.json').read_text())

    def corrupt(self, edit):
        data=copy.deepcopy(self.raw)
        edit(data)
        return inspect(self.graph,data)

    def test_missing_seven_unbuilt_workstations_blocked(self):
        report=inspect(self.graph,self.raw)
        self.assertEqual(report['catalog_recipes'],14)
        self.assertEqual(report['declared_candidates'],4)
        self.assertGreaterEqual(report['facility_types'],8)
        self.assertEqual(report['unrealized_facility_types'],report['facility_types'])
        self.assertFalse(report['release_approved'])
        self.assertEqual(report['worldstate_station_grants'],0)
        self.assertIn('hand_mix_clay', report['facility_review']['mixing_tub']['recipes'])

    def test_station_cannot_claim_art_approval_itself(self):
        with self.assertRaisesRegex(CatalogError,'station_review_falsely_approved'):
            self.corrupt(lambda d:d['facilities'][0].update(real_physical_fit_review='PASS'))

    def test_no_fabricated_ownership(self):
        with self.assertRaisesRegex(CatalogError,'station_not_physically_owned'):
            self.corrupt(lambda d:d['facilities'][0].update(requires_owned_crafted_entity=False))

    def test_one_cannot_claim_other_stations_recipes(self):
        with self.assertRaisesRegex(CatalogError,'station_permission_mismatch'):
            self.corrupt(lambda d:d['facilities'][0]['recipe_permissions'].append('fire_roof_tile'))

    def test_unlisted_machine_is_never_free(self):
        with self.assertRaisesRegex(CatalogError,'unlisted_station_can_be_free'):
            self.corrupt(lambda d:d.update(unlisted_station_policy='ALLOW'))

    def test_no_alias_for_fake_kiln(self):
        with self.assertRaisesRegex(CatalogError,'unsupported_physical_station_alias'):
            self.corrupt(lambda d:d['facilities'][3].update(prototype_entity='ceramic_pot'))

    def test_no_station_will_spawn_if_missing_registry(self):
        result=self.corrupt(lambda d:d['facilities'].pop())
        self.assertEqual(result['worldstate_station_grants'],0)
        self.assertIn('kiln',result['facility_review'])
        self.assertEqual(result['facility_review']['kiln']['state'],'BLOCKED_NO_PHYSICAL_DEVICE_DESIGN')

    def test_duplicate_stations_rejected(self):
        with self.assertRaisesRegex(CatalogError,'station_duplicate'):
            self.corrupt(lambda d:d['facilities'].append(copy.deepcopy(d['facilities'][0])))

if __name__=='__main__':
    unittest.main()
