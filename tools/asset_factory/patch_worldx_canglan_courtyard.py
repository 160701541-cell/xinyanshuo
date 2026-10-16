#!/usr/bin/env python3
"""Patch a local WorldX checkout for Canglan courtyard asset generation.
No image is fabricated: WorldX still calls its configured image model.
"""
from pathlib import Path
import argparse

def patch(root: Path, prompt: Path):
    loader = root / "generators/map/src/utils/prompt-loader.mjs"
    if not loader.is_file():
        raise SystemExit(f"WorldX prompt loader missing: {loader}")
    template = root / "generators/map/prompts/step1-map-generation.md"
    if not template.is_file():
        raise SystemExit(f"WorldX map prompt missing: {template}")
    original = template.read_text(encoding="utf-8")
    if "90度" not in original and "90°" not in original:
        raise SystemExit("Unexpected upstream template: top-down constraint not found")
    text = prompt.read_text(encoding="utf-8")
    begin = text.index("制作一套用于商业品质")
    end = text.index("\n\n**严格负面约束**", begin)
    negative = text.split("**严格负面约束**：", 1)[1].split("\n", 1)[0]
    canglan = (
        "请生成一张《苍岚·人生世界》独立建筑美术原图，供后续分层裁剪。\n\n"
        + text[begin:end].strip() + "\n\n严格禁止：" + negative + "\n"
        + "\n必须保留清晰建筑轮廓、屋顶边界、院墙边界和可进入的院门。"
        + "本阶段只生成一张候选图，不得声称已得到透明分层PNG或碰撞数据。\n"
        + "\n附加用户要求：{{userPrompt}}\n{{additionalConstraints}}\n"
    )
    output = root / "generators/map/prompts/step1-map-generation.md"
    backup = output.with_suffix(".worldx-original.md")
    if not backup.exists():
        backup.write_text(original, encoding="utf-8")
    output.write_text(canglan, encoding="utf-8")
    print(f"PATCHED_WORLDX_NATIVE_PROMPT {output}")
    print("NOTE: next run uses WorldX's own image generator; model API credentials required")

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--worldx-root", required=True, type=Path)
    ap.add_argument("--prompt-file", type=Path, default=Path(__file__).with_name("worldx_canglan_courtyard_batch01.md"))
    args = ap.parse_args()
    patch(args.worldx_root.resolve(), args.prompt_file.resolve())
