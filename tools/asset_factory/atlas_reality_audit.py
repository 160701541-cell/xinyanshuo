#!/usr/bin/env python3
"""Reproducible real-poster audit: physical crops, cautious matte candidates, no approval.

This is NOT a generator; the source image must exist. Presentation sheets are
not equivalent to independent production sprites.
"""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image
from candidate_cutout import remove_uniform_background, make_icon, make_preview


def source_sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def normalized_crop(image, box):
    if len(box) != 4 or not all(isinstance(v, (float, int)) for v in box):
        raise ValueError('BAD_CROP_BOX')
    x1, y1, x2, y2 = box
    if not (0 <= x1 < x2 <= 1 and 0 <= y1 < y2 <= 1):
        raise ValueError('CROP_BOX_OUTSIDE_IMAGE')
    w, h = image.size
    result = image.crop((round(x1*w), round(y1*h), round(x2*w), round(y2*h)))
    if min(result.size) < 32:
        raise ValueError('CROP_TOO_SMALL')
    return result


def audit_atlas(source_path, layout_path, outdir, *, flatten_ambiguous_alpha=False, threshold=28):
    src = Path(source_path).resolve()
    lay = Path(layout_path).resolve()
    out = Path(outdir).resolve()
    if src == out or lay == out or src.parent == out or lay.parent == out:
        raise ValueError('OUTPUT_OVERLAPS_INPUT')
    layout = json.loads(lay.read_text(encoding='utf-8'))
    slots = layout.get('slots', [])
    if not slots:
        raise ValueError('NO_SLOTS')
    ids = [s.get('id') for s in slots]
    if len(ids) != len(set(ids)) or any(not isinstance(sid, str) or not sid.replace('_','').isalnum() for sid in ids):
        raise ValueError('INVALID_ASSET_IDS')
    im = Image.open(src).convert('RGBA')
    out.mkdir(parents=True, exist_ok=True)
    records = []
    for slot in slots:
        cell = normalized_crop(im, slot['box'])
        crop = normalized_crop(cell, slot.get('sprite_region', [.04, .14, .96, .78]))
        dirname = out/'candidates'/slot['id']
        dirname.mkdir(parents=True, exist_ok=True)
        crop.save(dirname/'original_composite_crop.png')
        alpha = crop.getchannel('A')
        histogram = alpha.histogram()
        pathological_alpha = histogram[0] == 0 and histogram[255] == 0
        info = {'id': slot['id'], 'name': slot.get('name'), 'status': 'BLOCKED',
                'original_size': list(crop.size),
                'original_alpha_minmax': list(alpha.getextrema()),
                'art_approved': False, 'manual_review': 'REQUIRED',
                'source_slot_box': slot['box'], 'source_sprite_region': slot.get('sprite_region', [.04,.14,.96,.78]),
                'composite_crop_sha256': source_sha(dirname/'original_composite_crop.png')}
        if pathological_alpha and not flatten_ambiguous_alpha:
            info['failure'] = 'SHEET_ALPHA_NEITHER_OPAQUE_NOR_TRANSPARENT_USE_EXPLICIT_FLATTEN_FLAG'
            records.append(info)
            continue
        if pathological_alpha:
            candidate = crop.convert('RGB')
            info['analysis_alpha_normalization'] = 'EXPLICIT_RGB_CHANNEL_PRESERVATION_NOT_ALPHA_RECONSTRUCTION'
        else:
            candidate = crop
        try:
            matte, qa = remove_uniform_background(candidate, threshold)
            spr = dirname/'scene_candidate.png'
            icon = dirname/'icon_candidate.png'
            preview = dirname/'two_backgrounds.png'
            matte.save(spr)
            make_icon(matte).save(icon)
            make_preview(matte).save(preview)
            info.update({'status':'CUTOUT_CANDIDATE_UNAPPROVED',
                         'scene':str(spr.relative_to(out)),
                         'icon':str(icon.relative_to(out)),
                         'scene_sha256':source_sha(spr),
                         'icon_sha256':source_sha(icon),
                         'qa_metrics':qa})
        except ValueError as exc:
            info['failure'] = str(exc)
        records.append(info)
    result = {'source_file':src.name, 'source_sha256':source_sha(src),
              'source_pixels':list(im.size), 'source_alpha_minmax':list(im.getchannel('A').getextrema()),
              'layout_sha256':source_sha(lay), 'count':len(records), 'approved_count':0,
              'cutout_candidate_count':sum(x['status']=='CUTOUT_CANDIDATE_UNAPPROVED' for x in records),
              'status':'AUDIT_ONLY_NOT_A_GAME_ASSET_RELEASE', 'assets':records}
    (out/'real_atlas_audit.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    return result


def main():
    p=argparse.ArgumentParser()
    p.add_argument('--image', required=True)
    p.add_argument('--layout',required=True)
    p.add_argument('--out',required=True)
    p.add_argument('--flatten-ambiguous-alpha',action='store_true')
    p.add_argument('--threshold',type=int,default=28)
    args=p.parse_args()
    if not (1<=args.threshold<=60):
        p.error('threshold out of bounds 1..60')
    result=audit_atlas(args.image,args.layout,args.out,
       flatten_ambiguous_alpha=args.flatten_ambiguous_alpha, threshold=args.threshold)
    print(f"SOURCE POSTER AUDIT: {result['cutout_candidate_count']}/{result['count']} cutout candidates; 0 approved")
    raise SystemExit(1 if result['cutout_candidate_count'] != result['count'] else 0)


if __name__=='__main__':
    main()
