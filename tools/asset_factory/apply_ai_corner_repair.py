"""Apply saved AI-inpainted patches; preserve original files and outside pixels."""
import argparse, hashlib, json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageChops

def apply(root):
    box=(868,950,1009,1006)
    reports=[]
    for name in ['courtyard_gate_closed','village_stone_well']:
        source=root/(name+'.png'); patch_file=root/(name+'_repair_patch.png')
        original=Image.open(source).convert('RGB'); final=original.copy()
        patch=Image.open(patch_file).convert('RGB')
        if original.size!=(1024,1024) or patch.size!=(141,56):
            raise ValueError('Unexpected source/patch dimensions')
        mask=Image.new('L',patch.size,0)
        ImageDraw.Draw(mask).rectangle((4,4,patch.width-5,patch.height-5),fill=255)
        mask=mask.filter(ImageFilter.GaussianBlur(2))
        final.paste(patch,box,mask)
        # Prove every pixel outside the repair box remains unchanged.
        difference=ImageChops.difference(original,final)
        difference.paste((0,0,0),box)
        if difference.getbbox() is not None: raise AssertionError('Outside pixels changed')
        target=root/(name+'_repaired.png');final.save(target)
        reports.append({'id':name,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
            'output':target.name,'output_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),
            'patch_sha256':hashlib.sha256(patch_file.read_bytes()).hexdigest(),
            'bbox_xyxy':box,'outside_pixels_unchanged':True,'repair':'script mask + built-in AI inpainting + local feathered compositing',
            'original_provenance_retained':True,'approval':'TEXT_REPAIR_ONLY_NOT_INDEPENDENT_SPRITE_APPROVAL'})
    (root/'corner_repair_report.json').write_text(json.dumps(reports,ensure_ascii=False,indent=2)+'\n')
    print('PASS_TWO_AI_REPAIRS_OUTSIDE_PIXELS_UNCHANGED')
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--root',type=Path,required=True)
    apply(parser.parse_args().root)
