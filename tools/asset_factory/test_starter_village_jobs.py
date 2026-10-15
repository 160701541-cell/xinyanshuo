#!/usr/bin/env python3
import unittest
from starter_village_catalog import build
from starter_village_jobs import make_jobs

class VillageQueueTest(unittest.TestCase):
    def setUp(self):
        self.catalog = build()

    def test_full_queue_matches_catalog(self):
        jobs = make_jobs(self.catalog)
        self.assertEqual(len(jobs), self.catalog["asset_count"])
        self.assertEqual(len({(x["id"], x["state"]) for x in jobs}), len(jobs))

    def test_small_vertical_slice(self):
        jobs = make_jobs(self.catalog, batch=2, family="terrain")
        self.assertEqual(len(jobs), 2)
        self.assertTrue(all(x["family"] == "terrain" for x in jobs))

    def test_no_automatic_approval(self):
        for j in make_jobs(self.catalog, batch=10):
            self.assertEqual(j["quality_gate"], "UNAPPROVED")
            self.assertEqual(j["status"], "PENDING_GENERATION")
            self.assertIn("no text", j["prompt"])
            self.assertTrue(j["world_png_target"].endswith(".png"))

    def test_action_orientation(self):
        actors = make_jobs(self.catalog, family="actors")
        self.assertTrue(any("direction" in j["prompt"] for j in actors))
        self.assertTrue(any(j["state"] == "walk-NE" for j in actors))

if __name__ == "__main__":
    unittest.main()
