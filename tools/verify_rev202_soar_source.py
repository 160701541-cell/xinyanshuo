#!/usr/bin/env python3
"""Static rev202 guard for ORIGINAL APK176 controller source (not a Godot runtime QA)."""
from pathlib import Path

SOURCE = Path("game-source/apk176-ota177-candidate/scripts/apk176_player_controller_rev187.gd")

def verify(text: str) -> None:
    assert 'visible=camera_mode in ["fly","soar"] and not _soar_landing' in text, (
        "Avatar's ascend and descend controls must both be visible when soaring")
    assert 'if camera_mode=="soar" and mode!="soar" and _soar_altitude>0.045:' in text, (
        "Switching camera modes must not erase midair altitude")
    assert '    _soar_landing=true\n    _soar_target_altitude=0.0\n    say("请先平稳降落，再切换视角")\n    return' in text, (
        "Mode switch must start descent and refuse premature mode change")
    assert '    _soar_altitude=0.0\n    _soar_target_altitude=3.0' in text, (
        "Takeoff must begin at terrain level, not teleport 0.9m")
    assert 'func _step_soar_altitude(delta: float)' in text
    assert 'if _soar_landing and _soar_altitude<=0.045:' in text

if __name__ == "__main__":
    verify(SOURCE.read_text(encoding="utf-8"))
    print("PASS_REV202_SOURCE_GUARDS_ONLY_GODOT_ANDROID_UNVERIFIED")
