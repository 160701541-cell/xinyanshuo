#!/usr/bin/env python3
"""Patch a checked-out WorldX generator to accept Canglan's style-specific map prompt.

Usage: python tools/asset_factory/patch_worldx_canglan_prompt.py /path/to/WorldX
No network calls, no image generation, no API keys required. Idempotent.
"""
from pathlib import Path
import sys

OLD = '2. **必须是接近90度的俯视视角**'
NEW = '2. **必须是35至45度斜俯视视角**'
REPLACEMENT = ('2. **必须是35至45度斜俯视视角**，同时看见青灰瓦屋顶、木构建筑正面和院内地面。'
               '严禁90度垂直俯视、像素风、Q版；采用精细国风手绘、统一左上方自然光照。'
               '这是独立高清建筑试样，不是可直接用作整张地图的平面背景。')
TARGET = Path('generators/map/prompts/step1-map-generation.md')


def patch(root: Path) -> str:
    target = root / TARGET
    if not target.is_file():
        raise FileNotFoundError(f'WorldX map prompt not found: {target}')
    source = target.read_text(encoding='utf-8')
    lines = source.splitlines(keepends=True)
    hits = [i for i, line in enumerate(lines) if line.startswith(OLD) or line.startswith(NEW)]
    if len(hits) != 1:
        raise RuntimeError(f'Expected exactly one viewpoint rule; found {len(hits)}. Refusing unsafe patch.')
    index = hits[0]
    if lines[index].startswith(NEW):
        return 'ALREADY_PATCHED'
    ending = '\r\n' if lines[index].endswith('\r\n') else '\n'
    lines[index] = REPLACEMENT + ending
    target.write_text(''.join(lines), encoding='utf-8', newline='')
    return 'PATCHED'


if __name__ == '__main__':
    if len(sys.argv) != 2:
        raise SystemExit('Usage: patch_worldx_canglan_prompt.py /path/to/WorldX')
    print(patch(Path(sys.argv[1]).expanduser().resolve()))
