#!/usr/bin/env python3
"""CAC-3D-AI-003: fail closed on real Android local GGUF runtime installation.

This gate checks byte content and binary linkage; it does not pretend to prove
real-world phone FPS, complete NPC autonomy, or old APK signing compatibility.
"""
from __future__ import annotations
import argparse, hashlib, json, pathlib, struct, subprocess, sys

MODEL_REL="models/Qwen3-0.6B.Q4_K_M.gguf"
EXPECTED_SHA="7af3fdf842f87b24672f8a7f1dd50404043f0bfb71093ff91c31d2b49df4631d"
ANDROID_SO="addons/canglan_ai/bin/libcanglan_ai.android.arm64.so"
LINUX_SO="addons/canglan_ai/bin/libcanglan_ai.linux.x86_64.so"
DESCRIPTOR="addons/canglan_ai/canglan_ai.gdextension"

def check(project: pathlib.Path, android_required: bool=False) -> dict:
    project=project.resolve()
    manifest=json.loads((project/"local_ai/model_manifest.json").read_text("utf-8"))
    assert manifest["model"]=="Qwen3-0.6B" and manifest["sha256"]==EXPECTED_SHA
    assert manifest["license"]=="Apache-2.0"
    assert manifest["destination"]==MODEL_REL
    assert manifest["required_for_offline"] is True
    assert 1024<=manifest["max_context_tokens"]<=4096
    assert 1<=manifest["threads"]<=4
    source=(project/"scripts/local_ai_service.gd").read_text("utf-8")
    bridge=(project/"scripts/world_main.gd").read_text("utf-8")
    native=(project/"local_ai/native/canglan_local_llm.cpp").read_text("utf-8")
    for term in ("HashingContext","_install_or_verify","CanglanLocalLLM","ask_npc",
                 "inference_failed","model_ready"):
        assert term in source, f"Missing verified GGUF load contract {term}"
    for term in ("OfflineLocalAI","_talk_to_nearby","_nearest_citizen",
                 'connect("npc_reply"', "local_ai_state"):
        assert term in bridge, f"3D scene has no real NPC AI link: {term}"
    for term in ("llama_model_load_from_file","llama_decode(","llama_sampler_sample(",
                 "llama_tokenize(","n_gpu_layers = 0","load_gguf"):
        assert term in native, f"Native llama inference absent: {term}"
    for suspicious in ("HTTPRequest","http://localhost","https://api.",
                       "eval(","OS.execute("):
        assert suspicious not in source, f"Local AI must not use remote inference: {suspicious}"
    details={"gate":"SOURCE_ONLY","model":"Qwen3-0.6B Q4_K_M","license":"Apache-2.0",
             "expected_sha256":EXPECTED_SHA,"gguf_present":False,
             "native_android":False,"android_playtest":"NOT_VERIFIED",
             "original_signed_apk_updated":False}
    filename=project/MODEL_REL
    if filename.exists():
        h=hashlib.sha256()
        with filename.open("rb") as f:
            header=f.read(4)
            assert header==b"GGUF", "Selected file is not actual GGUF"
            h.update(header)
            while block:=f.read(4*1024*1024):
                h.update(block)
        assert h.hexdigest()==EXPECTED_SHA,"GGUF SHA256 mismatch"
        details["gguf_present"]=True
        details["model_bytes"]=filename.stat().st_size
    elif android_required:
        raise AssertionError("Offline AI release blocked: real verified GGUF missing")
    so_file=project/ANDROID_SO
    ext_file=project/DESCRIPTOR
    if so_file.is_file():
        contents=so_file.read_bytes()[:64]
        assert contents[:4]==b"\x7fELF", "Native ARM64 library must be ELF"
        assert struct.unpack("<H",contents[18:20])[0]==183, "ARM64 AArch64 ELF machine required"
        assert so_file.stat().st_size>1024*1024, "ARM64 AI lib suspiciously small"
        details["native_android"]=True
    elif android_required:
        raise AssertionError("Offline AI release blocked: actual Android GDExtension missing")
    if ext_file.exists():
        descriptor=ext_file.read_text("utf-8")
        assert "canglan_ai_init" in descriptor
        assert "libcanglan_ai.android.arm64.so" in descriptor
        assert "libcanglan_ai.linux.x86_64.so" in descriptor
    elif android_required:
        raise AssertionError("Offline AI release blocked: registered GDExtension missing")
    if android_required:
        details["gate"]="LOCAL_AI_BYTES_VERIFIED_NOT_PHONE_TESTED"
    return details

if __name__=="__main__":
    p=argparse.ArgumentParser()
    p.add_argument("--project",type=pathlib.Path,default=pathlib.Path("game-source/godot3d"))
    p.add_argument("--android-release-gate",action="store_true")
    args=p.parse_args()
    try:
        result=check(args.project,args.android_release_gate)
        print(json.dumps(result,ensure_ascii=False,sort_keys=True))
    except (AssertionError,ValueError,OSError,KeyError) as exc:
        print(json.dumps({"gate":"BLOCKED","reason":str(exc)},ensure_ascii=False))
        sys.exit(2)
