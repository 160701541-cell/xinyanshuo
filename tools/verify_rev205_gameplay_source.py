#!/usr/bin/env python3
"""Static rev205 guard for ORIGINAL APK176 controller source (not a Godot runtime QA)."""
from pathlib import Path

SOURCE = Path("game-source/apk176-ota177-candidate/scripts/apk176_player_controller_rev187.gd")
CULT = Path("game-source/apk176-ota177-candidate/scripts/apk176_cultivation_world_rev201.gd")

def verify(text: str) -> None:
    assert 'visible=camera_mode in ["fly","soar"] and not _soar_landing' in text, (
        "Avatar's ascend and descend controls must both be visible when soaring")
    assert 'if camera_mode=="soar" and mode!="soar" and _soar_altitude>0.045:' in text, (
        "Switching camera modes must not erase midair altitude")
    assert '    _soar_landing=true\n    _soar_hold_axis=0.0\n    _soar_hold_seconds=0.0\n    _soar_target_altitude=0.0\n    say("请先平稳降落，再切换视角")\n    _layout_hud()' in text, (
        "Mode switch must start descent and refuse premature mode change")
    assert '    _soar_altitude=0.0\n    _soar_target_altitude=3.0' in text, (
        "Takeoff must begin at terrain level, not teleport 0.9m")
    # Rev203: a real thumb press emits once then continuously adjusts
    # target altitude while held; release resets without touching world clock.
    assert 'BaseButton.ACTION_MODE_BUTTON_PRESS' in text
    assert 'lift_button.button_down.connect' in text
    assert 'lift_button.button_up.connect' in text
    assert 'lower_button.button_down.connect' in text
    assert 'lower_button.button_up.connect' in text
    assert 'func _step_soar_hold(delta: float)' in text
    assert '_soar_target_altitude+_soar_hold_axis*6.0*delta' in text
    assert 'actor.rotation.z=_soar_bank_angle' in text
    assert '_flight_sword.rotation=Vector3(PI/2.0,actor.rotation.y,_soar_bank_angle)' in text
    assert 'var chase_distance: float=_distance+_soar_camera_extra' in text
    assert 'func _step_soar_altitude(delta: float)' in text
    assert 'if _soar_landing and _soar_altitude<=0.045:' in text

def verify_combat(player: str, spirit: str) -> None:
    # No unearned free-mana, invisible opponent UI or fake spell projectile.
    for needle in (
        "RealMortalSparOpponentRealmHealthManaAboveHead",
        "ActualCombatTargetRealmHPMP",
        "LiveEnemyHealthNotCosmetic",
        "RealSpiritManaFromCultivationLedgerNotFaked",
        "func sword_attack()",
        "func cast_spirit_bolt()",
        "func cast_spirit_ward()",
        "func _step_spell_projectiles(delta:",
        "spend_player_mana_for_art",
        "_spar_damage_opponent(int(shot[",
        "ActualSwordOrSpiritProjectileWorldImpact",
        "ActualPlayerMortalSwordArcNotFakeSpell",
        "RealTravelingRootColoredQiBoltManaPaidAndObstacleChecked",
    ):
        assert needle in player, "Missing real combat integration: " + needle
    for needle in (
        "npc_vitals_bars",
        "ActualCultivatorVitals_",
        "max_health",
        "max_mana",
        "known_arts",
        "func available_player_arts()",
        "func spend_player_mana_for_art(",
        "if int(player_data.get(\"mana\",0))<cost",
        "if not save_state():",
        "ART_SPIRIT_BOLT",
        "ART_SPIRIT_WARD",
    ):
        assert needle in spirit, "Missing authority-gated spiritual arts: " + needle

if __name__ == "__main__":
    controller = SOURCE.read_text(encoding="utf-8")
    verify(controller)
    verify_combat(controller, CULT.read_text(encoding="utf-8"))
    bag = Path("game-source/apk176-ota177-candidate/scripts/apk176_backpack_rev205.gd").read_text(encoding="utf-8")
    for needle in (
        "func absorb_carried(", "carried.erase(actor_id)",
        "func deposit_at_warehouse(", "func craft(",
        "func equip(", "MAX_SLOTS: int=24", "func _save() -> bool:"):
        assert needle in bag, "Rev205 backpack must be actual ledger: "+needle
    for needle in (
        "func toggle_target_lock()", "func _step_target_lock(delta:",
        "func toggle_quickbar()", "func _open_icon(name:",
        'func _toggle_touch_invert()', "STOP_UNUSED_MARKER",
        "停止降落，重新御剑起飞", 'MAX_INPUT_MARKER'):
        if needle.endswith("_MARKER"):
            continue
        assert needle in controller, "Rev205 camera/HUD must be real: "+needle
    for name in ("backpack", "swords", "crosshair", "pickaxe", "shield",
                 "book-open", "house", "compass", "eye", "move-3d", "leaf", "menu", "zap"):
        src = Path("game-source/apk176-ota177-candidate/ui/lucide") / (name+".svg")
        assert src.read_text().lstrip().startswith("<svg"), "Missing licensed real icon: "+name
    assert "ISC License" in Path("game-source/apk176-ota177-candidate/ui/lucide/LICENSE").read_text()
    print("PASS_REV205_REAL_LUCIDE_CAMERA_LOCK_BAG_HUD_SOURCE_GUARDS_ONLY")
