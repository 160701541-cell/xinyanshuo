#!/usr/bin/env python3
"""Regression tests for candidate QA; generates fixtures, no model or GPU needed."""
import json
import tempfile
import unittest
from pathlib import Path
from PIL import Image
from audit_candidates import audit


class CandidateAuditTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        image_dir = self.root / "candidates" / "CL_1"
        image_dir.mkdir(parents=True)
        self.scene = image_dir / "scene_candidate.png"
        self.icon = image_dir / "icon_candidate.png"
        self.data = {"count": 1, "approved_count": 0, "assets": [{
            "id": "CL_1", "review": "UNAPPROVED",
            "scene": "candidates/CL_1/scene_candidate.png",
            "icon": "candidates/CL_1/icon_candidate.png"}]}
        self.write_images()
        self.save_manifest()

    def write_images(self, opaque=False, touch=False):
        for path, n in ((self.scene, 256), (self.icon, 512)):
            image = Image.new("RGBA", (n, n), (0, 0, 0, 255) if opaque else (0, 0, 0, 0))
            if not opaque:
                from PIL import ImageDraw
                ImageDraw.Draw(image).rectangle((0 if touch else 20, 20, n-20, n-20), fill=(200, 120, 30, 255))
            image.save(path)

    def save_manifest(self):
        (self.root / "candidate_manifest.json").write_text(json.dumps(self.data), encoding="utf-8")

    def test_valid_candidate_is_never_approved(self):
        result = audit(self.root)
        self.assertEqual(result["status"], "TECH_ONLY_PASS")
        self.assertEqual(result["production_approved_count"], 0)
        self.assertEqual(result["assets"][0]["visual_review"], "REQUIRED")

    def test_opaque_composite_fails(self):
        self.write_images(opaque=True)
        self.assertEqual(audit(self.root)["status"], "FAIL")

    def test_edge_touch_fails(self):
        self.write_images(touch=True)
        self.assertIn("SCENE_ALPHA_TOUCHES_CANVAS_EDGE", audit(self.root)["failures"][0])

    def test_path_escape_fails(self):
        self.data["assets"][0]["scene"] = "../../outside.png"
        self.save_manifest()
        self.assertEqual(audit(self.root)["status"], "FAIL")

    def test_fake_approval_fails(self):
        self.data["assets"][0]["review"] = "APPROVED"
        self.save_manifest()
        self.assertEqual(audit(self.root)["status"], "FAIL")


if __name__ == "__main__":
    unittest.main()
