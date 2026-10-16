#!/usr/bin/env python3
"""Pixel-layout gate for the original APK176 real Godot indoor screenshot.

Catches the confirmed left-half blank brown panel. It is NOT a substitute
for human art-direction review or mobile device acceptance.
"""
import argparse
from pathlib import Path
from PIL import Image, ImageStat


def check_room(path: Path):
    image = Image.open(path).convert("RGB")
    w, h = image.size
    if w < 800 or h < 480:
        raise ValueError(f"Rendered indoor screenshot too small: {w}x{h}")
    deviations = []
    for start, end in ((0.10, 0.38), (0.40, 0.68), (0.68, 0.95)):
        crop = image.crop((round(w * start), round(h * .46), round(w * end), round(h * .88)))
        std = ImageStat.Stat(crop).stddev
        score = sum(std) / 3.0
        deviations.append(round(score, 2))
        if score < 8.0:
            raise ValueError(f"Blank room pane at width [{start:.2f},{end:.2f}]: RGB std {std}")
    return deviations


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--indoor", type=Path, required=True)
    args = p.parse_args()
    deviations = check_room(args.indoor)
    print("PASS_CANG LAN_INTERIOR_NO_EMPTY_HALF_SCREEN".replace(" ", ""), deviations)
    print("ARTISTIC_STYLE_AND_ROOF_VS_ROOM_VISUAL_REVIEW_STILL_REQUIRED")


if __name__ == "__main__":
    main()
