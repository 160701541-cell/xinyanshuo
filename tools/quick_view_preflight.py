#!/usr/bin/env python3
"""Fail-fast, read-only original-installed-game quick-view readiness gate.

No APK building, signer substitution, website mutation or credential output.
Use before expensive Godot imports / asset builds.
"""
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
CHANNEL = ROOT / "android-preview" / "latest.json"
BASE = ROOT / "android-preview" / "base-latest.json"
REPORT = ROOT / "qa-results" / "quick-view-preflight.json"
REQUIRED_3D = (
    "game-source/godot3d/project.godot",
    "game-source/godot3d/scenes/main.tscn",
    "game-source/godot3d/scripts/world_main.gd",
    "game-source/godot3d/scripts/world_resource_seeder.gd",
    "game-source/godot3d/scripts/world_resource_visuals.gd",
)
# The original entrypoint must be tested by the original APK fixture.
ORIGINAL_TEST = "logic-qa/apk176-export-fixture/verify_original_main_live_house.gd"


def main() -> int:
    checks = {}
    problems = []
    try:
        live = json.loads(CHANNEL.read_text(encoding="utf-8"))
        base = json.loads(BASE.read_text(encoding="utf-8"))
        checks["channel"] = live.get("channel")
        checks["revision"] = live.get("revision")
        checks["original_apk_code"] = base.get("version_code")
        checks["base_package"] = base.get("package_name")
        checks["channel_url_is_https"] = str(live.get("pack_url", "")).startswith(
            "https://160701541-cell.github.io/xinyanshuo/android-preview/"
        )
        checks["has_signed_manifest"] = bool(live.get("signature"))
        if checks["channel"] != "android-preview":
            problems.append("WRONG_CHANNEL")
        if checks["base_package"] != "org.canglan.ancient25d.preview":
            problems.append("WRONG_ORIGINAL_APP")
        if checks["original_apk_code"] != 1176:
            problems.append("WRONG_ORIGINAL_VERSION")
        if not isinstance(checks["revision"], int):
            problems.append("INVALID_LIVE_REVISION")
        if not checks["channel_url_is_https"]:
            problems.append("UNTRUSTED_UPDATE_HOST")
        if not checks["has_signed_manifest"]:
            problems.append("UNSIGNED_PUBLISHED_CHANNEL")
    except (OSError, ValueError, TypeError) as exc:
        problems.append("CANNOT_READ_ORIGINAL_MANIFEST:" + type(exc).__name__)
    checks["missing_3d_files"] = [f for f in REQUIRED_3D if not (ROOT / f).is_file()]
    checks["original_scene_fixture_present"] = (ROOT / ORIGINAL_TEST).is_file()
    if checks["missing_3d_files"]:
        problems.append("MISSING_3D_SOURCE")
    if not checks["original_scene_fixture_present"]:
        problems.append("MISSING_APK176_RUNTIME_FIXTURE")

    # A full replacement 3D project is NOT an additive original-APK PCK.
    # This gate records that the original entrypoint + signature must be
    # independently validated for a new revision before any release.
    checks["new_3d_compatible_with_installed_apk"] = "NOT_YET_VERIFIED"
    checks["original_RSA_signer"] = "CHECK_SEPARATELY_WITH_EXISTING_SECRET_PROBE"
    checks["release_allowed"] = False
    checks["release_blockers"] = problems + [
        "APK176_3D_ENTRYPOINT_COMPATIBILITY_NOT_VERIFIED",
        "NEW_REVISION_RSA_SIGNATURE_NOT_VERIFIED",
        "ANDROID_IN_APP_UPDATE_NOT_YET_ACCEPTED"
    ]
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text(json.dumps(checks, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("ORIGINAL_QUICK_VIEW_PREFLIGHT " + json.dumps({
        "revision": checks.get("revision"), "app_code": checks.get("original_apk_code"),
        "source_missing": len(checks["missing_3d_files"]),
        "release_allowed": False,
        "blockers": checks["release_blockers"]}, ensure_ascii=False), flush=True)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
