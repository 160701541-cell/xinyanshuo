#!/usr/bin/env python3
import unittest
from collections import Counter
from starter_village_catalog import build, validate, FAMILIES

class VillageCatalogTest(unittest.TestCase):
    def setUp(self):
        self.data = build()

    def test_unique_and_consistent(self):
        self.assertTrue(validate(self.data))

    def test_each_family_covered(self):
        covered = {a["family"] for a in self.data["assets"]}
        self.assertEqual(covered, set(FAMILIES))

    def test_door_and_lantern_states(self):
        by_kind = {}
        for asset in self.data["assets"]:
            by_kind.setdefault(asset["kind"], set()).update(asset["variant"].values())
        self.assertEqual(by_kind["door"], {"open", "closed"})
        self.assertEqual(by_kind["lantern"], {"lit", "unlit"})
        self.assertEqual(by_kind["house"], {"intact", "damaged", "burned", "collapsed"})

    def test_actor_actions_directions(self):
        farmer = [a for a in self.data["assets"] if a["prototype_id"] == "CL.ACTORS.FARMER.001"]
        self.assertEqual(len(farmer), 32)

    def test_no_false_art_release(self):
        self.assertTrue(all(a["status"] == "SPEC_ONLY" and a["source_sha256"] is None
                            and a["qa"]["visual"] == "NOT_REVIEWED" for a in self.data["assets"]))

if __name__ == "__main__":
    unittest.main()
