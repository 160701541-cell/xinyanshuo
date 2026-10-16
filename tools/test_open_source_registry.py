#!/usr/bin/env python3
"""Mutation tests: unauthorized binaries/assets must never silently enter mobile builds."""
import copy
import json
import unittest
from pathlib import Path

from verify_open_source_registry import OpenSourceGateError, REGISTRY, verify

ROOT = Path(__file__).resolve().parents[1]


class LicenseContractTests(unittest.TestCase):
    def setUp(self) -> None:
        self.payload = json.loads((ROOT / REGISTRY).read_text(encoding="utf-8"))

    def check_invalid(self, payload: dict) -> None:
        with self.assertRaises(OpenSourceGateError):
            verify(ROOT, payload)

    def test_actual_registered_runtime_is_present(self) -> None:
        result = verify(ROOT, self.payload)
        self.assertEqual(result["gate"], "PASS")
        self.assertEqual(result["embedded_third_party_asset_count"], 0)
        self.assertGreaterEqual(result["active"], 3)
        self.assertGreaterEqual(result["candidate_only"], 3)

    def test_unsupported_commercial_license_blocked(self) -> None:
        bad = copy.deepcopy(self.payload)
        bad["entries"][0]["license"] = "Commercial-Only"
        self.check_invalid(bad)

    def test_duplicate_dependency_blocked(self) -> None:
        bad = copy.deepcopy(self.payload)
        bad["entries"].append(copy.deepcopy(bad["entries"][0]))
        self.check_invalid(bad)

    def test_missing_license_evidence_blocked(self) -> None:
        bad = copy.deepcopy(self.payload)
        bad["entries"][1]["license_proof"] = ""
        self.check_invalid(bad)

    def test_candidate_cannot_claim_active_import(self) -> None:
        bad = copy.deepcopy(self.payload)
        idx = next(i for i,e in enumerate(bad["entries"]) if e["id"] == "kenney-cc0-packs")
        bad["entries"][idx]["used_by"] = ["game-source/hd2d-world/scripts/village.gd"]
        self.check_invalid(bad)

    def test_candidate_cannot_claim_fake_pin(self) -> None:
        bad = copy.deepcopy(self.payload)
        bad["entries"][-1]["sha256"] = "a"*64
        self.check_invalid(bad)

    def test_unpinned_cc0_asset_blocked(self) -> None:
        bad = copy.deepcopy(self.payload)
        idx = next(i for i,e in enumerate(bad["entries"]) if e["id"] == "poly-haven-assets")
        bad["entries"][idx]["status"] = "ACTIVE"
        bad["entries"][idx]["used_by"] = ["game-source/hd2d-world/scripts/village.gd"]
        self.check_invalid(bad)

    def test_absolute_and_parent_traversals_blocked(self) -> None:
        for unsafe in ["../../dev/null", "/tmp/file.png", "C:/private/texture.png"]:
            with self.subTest(unsafe=unsafe):
                bad = copy.deepcopy(self.payload)
                bad["entries"][0]["used_by"] = [unsafe]
                self.check_invalid(bad)

    def test_missing_runtime_file_blocked(self) -> None:
        bad = copy.deepcopy(self.payload)
        bad["entries"][2]["used_by"] = ["game-source/hd2d-world/scripts/no-such-class.gd"]
        self.check_invalid(bad)

    def test_gpl_tool_not_allowed_inside_runtime(self) -> None:
        bad = copy.deepcopy(self.payload)
        bad["entries"][0]["license"] = "GPL-3.0-or-later"
        self.check_invalid(bad)


if __name__ == "__main__":
    unittest.main()
