#!/usr/bin/env python3
"""Original deterministic P1 Chinese architectural material studies; not final art."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import struct
import zlib

SIZE = 256

def png_rgb(path, pixels, size=SIZE):
    assert len(pixels) == size * size * 3
    def chunk(tag, data):
        return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff)
    raw = b''.join(b'\x00' + pixels[y*size*3:(y+1)*size*3] for y in range(size))
    path.write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b''))

def noise(x, y, seed):
    n = (x * 374761393 + y * 668265263 + seed * 1442695041) & 0xffffffff
    n = ((n ^ (n >> 13)) * 1274126177) & 0xffffffff
    return ((n ^ (n >> 16)) & 65535) / 65535.0

def shade(material, x, y):
    theta = 2 * math.pi * x / SIZE
    phi = 2 * math.pi * y / SIZE
    if material == 'qing_tile':
        wave = math.cos(theta * 8)
        mortar = min(1.0, max(0., (wave + .74) * 12.))
        height = .44 + .36 * wave * mortar + .08 * math.sin(phi * 4)
        grain = (noise(x//4, y//4, 29) - .5) * 10
        color = (72 + 22 * height + grain, 91 + 18 * height + grain, 95 + 19 * height + grain)
        rough = 181 + 24 * (1 - height)
    else:
        height = (.08 * math.sin(theta * 12) * math.sin(phi * 15)
                  + .04 * math.cos(theta * 27 + phi * 9))
        grain = (noise(x//3, y//3, 41) - .5) * 9
        color = (215 + 13 * height + grain, 211 + 12 * height + grain, 197 + 13 * height + grain)
        rough = 216 + 18 * height
    return tuple(max(0, min(255, round(v))) for v in color), height, max(0, min(255, round(rough)))

def build(output):
    output.mkdir(parents=True, exist_ok=True)
    manifest = {'schema': 1, 'status': 'prototype_unapproved', 'resolution': [SIZE, SIZE], 'materials': {}}
    for key in ('ivory_plaster', 'qing_tile'):
        height = [[shade(key, x, y)[1] for x in range(SIZE)] for y in range(SIZE)]
        pixels = {'albedo': bytearray(), 'normal': bytearray(), 'roughness': bytearray()}
        for y in range(SIZE):
            for x in range(SIZE):
                color, _, rough = shade(key, x, y)
                dx = (height[y][(x+1)%SIZE] - height[y][(x-1)%SIZE]) * .9
                dy = (height[(y+1)%SIZE][x] - height[(y-1)%SIZE][x]) * .9
                inv = 1. / math.sqrt(dx*dx + dy*dy + 1)
                normal = tuple(round((v * inv * .5 + .5) * 255) for v in (-dx, -dy, 1.))
                pixels['albedo'].extend(color)
                pixels['normal'].extend(normal)
                pixels['roughness'].extend((rough,)*3)
        files = {}
        for channel, buf in pixels.items():
            path = output / f'{key}_{channel}.png'
            png_rgb(path, bytes(buf))
            files[channel] = {'path': path.name, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
        manifest['materials'][key] = files
    (output / 'manifest.json').write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    return manifest

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, default=Path('game-source/godot3d/assets/materials/p1'))
    args = parser.parse_args()
    info = build(args.output)
    print(f"P1 prototypes: {len(info['materials'])} material sets, {len(info['materials'])*3} PNGs, {SIZE}x{SIZE}; NOT art-approved")
