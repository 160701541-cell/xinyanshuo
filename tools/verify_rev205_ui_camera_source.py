#!/usr/bin/env python3
"""Source/static-asset guard only, not a substitute for real Godot/Android QA."""
import hashlib
import importlib.util
from pathlib import Path

ROOT=Path("game-source/apk176-ota177-candidate")
UI=ROOT/"ui/kenney"
SCRIPT=ROOT/"scripts/apk176_player_controller_rev187.gd"
VENDOR=Path("tools/vendor_kenney_ui_rev205.py")

def validate() -> None:
    spec=importlib.util.spec_from_file_location("canglan_ui_vendor",VENDOR)
    module=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    for name,(origin,want_sha) in module.ART.items():
        raw=(UI/name).read_bytes()
        actual=hashlib.sha1(("blob %d\0"%len(raw)).encode()+raw).hexdigest()
        assert actual==want_sha,("Kenney sprite altered/not authentic",name)
        assert raw[:8]==bytes.fromhex("89504e470d0a1a0a"),name
    p=SCRIPT.read_text(encoding="utf-8")
    for needle in (
        "Image.new()",
        "image.load_png_from_buffer(encoded)",
        "StyleBoxTexture.new()",
        "AuthenticKenneyMobileControlsCC0_",
        "func toggle_target_lock() -> bool",
        "func _step_target_lock(delta: float) -> void:",
        'var quick_keys: Array=["Iso45Button"',
        '"TargetLockButton"',
        'clampf(_pitch+speed_y,-1.31,1.52)',
        'clampf(_pitch-speed_y,-1.49,1.49)',
        "func _toggle_touch_camera_direction() -> void:",
        "已取消降落，飞剑重新起飞",
        "func _install_kenney_ui_theme() -> void:",
    ):
        assert needle in p,("Missing integrated player HUD/camera behavior",needle)
    pack=Path("logic-qa/tools/build_apk176_quality_rev187.gd").read_text(encoding="utf-8")
    assert 'BLOCKED_REV205_REAL_KENNEY_CC0_UI_MISSING' in pack
    print("PASS_REV205_PINNED_KENNEY_UI_REAL_BINARY_BLOBS_SKIN_AND_CAMERA_SOURCE_GUARD")

if __name__=="__main__":
    validate()
