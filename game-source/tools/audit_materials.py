#!/usr/bin/env python3
"""Independent fail-closed material pixel audit. NOT a visual/art approval."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import statistics
import struct
import zlib

PNG_HEADER = b'\x89PNG\r\n\x1a\n'
MATERIALS = {'ivory_plaster', 'qing_tile'}
CHANNELS = {'albedo', 'normal', 'roughness'}
MAX_PNG_BYTES = 1024 * 1024
MAX_TOTAL_BYTES = 2 * 1024 * 1024


class QualityFailure(ValueError):
    pass


def require(condition, message):
    if not condition:
        raise QualityFailure(message)


def read_rgb_png(path, dim):
    blob = path.read_bytes()
    require(40 < len(blob) <= MAX_PNG_BYTES, f'{path}: PNG byte budget')
    require(blob.startswith(PNG_HEADER), f'{path}: invalid PNG signature')
    offset, compressed, got_ihdr, got_iend = 8, bytearray(), False, False
    while offset < len(blob):
        require(offset + 12 <= len(blob), f'{path}: incomplete PNG chunk')
        length = struct.unpack_from('>I', blob, offset)[0]
        tag = blob[offset+4:offset+8]
        end = offset+12+length
        require(end <= len(blob), f'{path}: truncated PNG chunk')
        payload = blob[offset+8:offset+8+length]
        expected_crc = struct.unpack_from('>I', blob, offset+8+length)[0]
        require(zlib.crc32(tag+payload) & 0xffffffff == expected_crc,
                f'{path}: CRC mismatch in {tag!r}')
        if tag == b'IHDR':
            require(not got_ihdr and length == 13 and offset == 8,
                    f'{path}: illegal PNG IHDR')
            require(struct.unpack('>IIBBBBB', payload) == (dim, dim, 8, 2, 0, 0, 0),
                    f'{path}: wrong size/depth/RGB format')
            got_ihdr = True
        elif tag == b'IDAT':
            require(got_ihdr, f'{path}: IDAT before IHDR')
            compressed.extend(payload)
            require(len(compressed) <= MAX_PNG_BYTES,
                    f'{path}: compressed data exceeds budget')
        elif tag == b'IEND':
            require(got_ihdr and length == 0 and end == len(blob),
                    f'{path}: IEND not terminal')
            got_iend = True
        else:
            require(tag in (b'gAMA', b'sRGB', b'pHYs'),
                    f'{path}: unexpected PNG metadata {tag!r}')
        offset = end
    require(got_ihdr and got_iend and len(compressed) > 0,
            f'{path}: missing required PNG chunks')
    decompressor = zlib.decompressobj()
    raw = decompressor.decompress(bytes(compressed), dim*(dim*3+1)+1)
    require(len(raw) == dim*(dim*3+1) and decompressor.eof
            and not decompressor.unused_data and not decompressor.unconsumed_tail,
            f'{path}: invalid RGB scanlines or compressed trailing data')
    row_len = dim*3+1
    require(all(raw[y*row_len] == 0 for y in range(dim)),
            f'{path}: unsupported scanline filter')
    return [raw[y*row_len+1:(y+1)*row_len] for y in range(dim)]


def channel_stats(rows, component):
    values = [row[x*3+component] for row in rows for x in range(len(row)//3)]
    return round(statistics.fmean(values), 3), round(statistics.pstdev(values), 3), len(set(values))


def seam_stats(rows, component):
    n=len(rows)
    left_right = statistics.fmean(abs(row[component]-row[(n-1)*3+component]) for row in rows)
    top_bottom = statistics.fmean(abs(rows[0][x*3+component]-rows[-1][x*3+component]) for x in range(n))
    interior_x = statistics.fmean(abs(row[x*3+component]-row[(x+1)*3+component])
                                   for row in rows for x in range(n-1))
    interior_y = statistics.fmean(abs(rows[y][x*3+component]-rows[y+1][x*3+component])
                                   for y in range(n-1) for x in range(n))
    return {key: round(val,3) for key,val in {
        'left_right':left_right,'top_bottom':top_bottom,
        'interior_x':interior_x,'interior_y':interior_y}.items()}


def audit(root):
    path = root/'manifest.json'
    require(path.is_file(), 'missing material manifest')
    manifest = json.loads(path.read_text(encoding='utf-8'))
    require(manifest.get('schema') == 2, 'required material schema 2')
    require(manifest.get('status') == 'prototype_unapproved',
            'generator must not self-certify its own artwork')
    require(manifest.get('license') == 'original_project_generated_no_external_assets',
            'resource origin must be explicitly established')
    require(manifest.get('normal_convention') == 'tangent_space_opengl_y_positive',
            'normal orientation contract changed')
    require(manifest.get('color_space') == {
        'albedo':'sRGB', 'normal':'linear', 'roughness':'linear'},
        'color-space contract changed')
    size = manifest.get('resolution')
    require(size == [256, 256], 'mobile texture size must be exactly 256x256 in this prototype')
    require(set(manifest.get('materials', {})) == MATERIALS, 'wrong material inventory')
    expected_files = {'manifest.json'}
    report = {'schema': 1, 'technical_gate': 'PASS',
              'godot_integration_gate': 'BLOCKED_NO_REAL_ENGINE_EVIDENCE',
              'android_release_gate': 'BLOCKED_NO_SIGNED_ANDROID_EVIDENCE',
              'art_direction_gate': 'BLOCKED_NO_HUMAN_APPROVED_AB_CAPTURE',
              'material_metrics': {}}
    total=0
    for material, channels in manifest['materials'].items():
        require(set(channels) == CHANNELS, f'{material}: missing texture channel')
        metrics={}
        loaded={}
        for channel in sorted(channels):
            item=channels[channel]
            require(set(item)=={'path','sha256','bytes'},f'{material}/{channel}: metadata schema')
            name=f'{material}_{channel}.png'
            require(item['path']==name,f'{material}/{channel}: path substitution prohibited')
            expected_files.add(name)
            file=root/name
            require(file.is_file(), f'{name}: missing file')
            require(file.stat().st_size==item['bytes'], f'{name}: size mismatch')
            require(hashlib.sha256(file.read_bytes()).hexdigest()==item['sha256'],
                    f'{name}: SHA256 mismatch')
            total+=file.stat().st_size
            rows=read_rgb_png(file,256)
            loaded[channel]=rows
            avg,std,unique=channel_stats(rows,0)
            seams=seam_stats(rows,0)
            require(seams['left_right']<=max(.8, seams['interior_x']*3+.5),
                    f'{name}: horizontal tiling seam')
            require(seams['top_bottom']<=max(.8, seams['interior_y']*3+.5),
                    f'{name}: vertical tiling seam')
            metrics[channel]={'mean_r':avg,'std_r':std,
                              'unique_r':unique,'edge_metrics':seams,
                              'bytes':file.stat().st_size}
        albedo=metrics['albedo']
        require(albedo['std_r']>2.2 and albedo['unique_r']>=12,
                f'{material}: overly uniform albedo, texture quality regression')
        if material=='qing_tile':
            require(68<=albedo['mean_r']<=110, 'tile color drifts out of agreed slate palette')
        else:
            require(195<=albedo['mean_r']<=235, 'plaster not legibly ivory')
        rough=loaded['roughness']
        require(metrics['roughness']['std_r']>2.0, f'{material}: flat roughness')
        require(all(row[i]==row[i+1]==row[i+2]
                    for row in rough for i in range(0,len(row),3)),
                f'{material}: roughness must be grayscale')
        require(all(150<=row[i]<=240 for row in rough for i in range(0,len(row),3)),
                f'{material}: uncontrolled roughness budget')
        normal=loaded['normal']
        lengths=[]
        for row in normal:
            for i in range(0,len(row),3):
                x,y,z=((v/255*2-1) for v in row[i:i+3])
                lengths.append(abs(math.sqrt(x*x+y*y+z*z)-1))
                require(z>0.5, f'{material}: inverted or implausible normal vector')
        require(statistics.fmean(lengths)<.012 and max(lengths)<.018,
                f'{material}: nonunit tangent normals')
        require(metrics['normal']['std_r']>(4 if material=='qing_tile' else .35),
                f'{material}: fake flat normal map')
        report['material_metrics'][material]=metrics
    require(total<MAX_TOTAL_BYTES, 'mobile texture package exceeds budget')
    require({p.name for p in root.iterdir() if p.is_file()}==expected_files,
            'unexpected resource or asset injection into package')
    report['texture_file_count']=len(expected_files)-1
    report['total_png_bytes']=total
    return report


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--root',type=Path,required=True)
    parser.add_argument('--report',type=Path)
    args=parser.parse_args()
    try:
        result=audit(args.root)
    except (QualityFailure, OSError, ValueError, KeyError) as exc:
        raise SystemExit(f'QA FAIL CLOSED: {exc}') from exc
    if args.report:
        args.report.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(result,ensure_ascii=False,indent=2))
