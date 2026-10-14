#!/usr/bin/env python3
"""Deterministic original P1 surface prototypes. Not production-approved art.

All outputs are periodic, 8-bit RGB maps. Real roof construction must use
geometry; these maps are a supporting micro-surface, not fake model detail.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import struct
import zlib

SIZE = 256
CHANNELS = ('albedo', 'normal', 'roughness')


def png_rgb(path, pixels, size=SIZE):
    if len(pixels) != size * size * 3:
        raise ValueError('RGB pixel count does not match requested PNG dimensions')
    def chunk(tag, data):
        return (struct.pack('>I', len(data)) + tag + data
                + struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff))
    raw = b''.join(b'\0' + pixels[y * size * 3:(y + 1) * size * 3]
                   for y in range(size))
    path.write_bytes(b'\x89PNG\r\n\x1a\n'
                     + chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 2, 0, 0, 0))
                     + chunk(b'IDAT', zlib.compress(raw, 9))
                     + chunk(b'IEND', b''))


def lattice_hash(x, y, seed):
    n = (x * 374761393 + y * 668265263 + seed * 2246822519) & 0xffffffff
    n = ((n ^ (n >> 13)) * 1274126177) & 0xffffffff
    return ((n ^ (n >> 16)) & 65535) / 65535.0


def periodic_noise(x, y, cells, seed):
    """Continuous periodic value noise; no random pixel-block seams."""
    a, b = x * cells / SIZE, y * cells / SIZE
    i, j = math.floor(a), math.floor(b)
    u, v = a - i, b - j
    u, v = u*u*(3-2*u), v*v*(3-2*v)
    def h(dx, dy):
        return lattice_hash((i + dx) % cells, (j + dy) % cells, seed)
    return ((h(0, 0)*(1-u) + h(1, 0)*u)*(1-v)
            + (h(0, 1)*(1-u) + h(1, 1)*u)*v)


def clamp8(value):
    return min(255, max(0, round(value)))


def surface(material, x, y):
    broad = periodic_noise(x, y, 4, 31)
    grain = periodic_noise(x, y, 16, 71)
    pores = periodic_noise(x, y, 32, 107)
    variation = (broad-.5)*2
    micro = (grain-.5)*2
    if material == 'qing_tile':
        ridge = (0.5 + 0.5*math.cos(math.tau*8*x/SIZE)) ** 1.4
        height = .20 + .44*ridge + .105*variation + .048*micro
        pigment = 14*variation + 6*micro + 4*(pores-.5)
        color = (78 + 12*ridge + pigment, 96 + 11*ridge + pigment,
                 100 + 12*ridge + pigment)
        rough = 190 + 13*(1-ridge) + 9*variation + 6*micro
    elif material == 'ivory_plaster':
        height = .22 + .16*variation + .055*micro + .025*(pores-.5)
        pigment = 7*variation + 4*micro + 3*(pores-.5)
        color = (216 + pigment, 210 + pigment, 196 + pigment)
        rough = 215 + 10*variation + 4*micro
    else:
        raise ValueError('Unexpected material name')
    return tuple(clamp8(v) for v in color), height, clamp8(rough)


def build(output):
    output.mkdir(parents=True, exist_ok=True)
    manifest = {
        'schema': 2,
        'status': 'prototype_unapproved',
        'license': 'original_project_generated_no_external_assets',
        'resolution': [SIZE, SIZE],
        'color_space': {'albedo': 'sRGB', 'normal': 'linear', 'roughness': 'linear'},
        'normal_convention': 'tangent_space_opengl_y_positive',
        'materials': {},
    }
    for name in ('ivory_plaster', 'qing_tile'):
        data = [[surface(name, x, y) for x in range(SIZE)] for y in range(SIZE)]
        maps = {key: bytearray() for key in CHANNELS}
        for y in range(SIZE):
            for x in range(SIZE):
                color, _, rough = data[y][x]
                dx = (data[y][(x+1) % SIZE][1] - data[y][(x-1) % SIZE][1]) * 1.45
                dy = (data[(y+1) % SIZE][x][1] - data[(y-1) % SIZE][x][1]) * 1.45
                inv = 1.0 / math.sqrt(1.0 + dx*dx + dy*dy)
                normal = (clamp8((-dx*inv*.5+.5)*255),
                          clamp8((-dy*inv*.5+.5)*255),
                          clamp8((inv*.5+.5)*255))
                maps['albedo'].extend(color)
                maps['normal'].extend(normal)
                maps['roughness'].extend((rough, rough, rough))
        entries = {}
        for channel, buf in maps.items():
            p = output / f'{name}_{channel}.png'
            png_rgb(p, buf)
            entries[channel] = {'path': p.name,
                                'sha256': hashlib.sha256(p.read_bytes()).hexdigest(),
                                'bytes': p.stat().st_size}
        manifest['materials'][name] = entries
    (output / 'manifest.json').write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    return manifest


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path,
                        default=Path('game-source/godot3d/assets/materials/p1'))
    args = parser.parse_args()
    result = build(args.output)
    print(f"GENERATED {len(result['materials']) * 3} original maps; "
          'not art-approved, not signed for Android release')
