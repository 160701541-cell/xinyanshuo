"""Extract visible main-house pixels without generative style drift or upscaling."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageChops
import argparse,hashlib,json
POINTS=[(292,43),(302,83),(322,103),(365,105),(378,93),(378,76),(389,72),(398,93),(615,91),(617,66),(628,77),(631,109),(649,109),(669,104),(688,96),(705,84),(719,66),(730,45),(742,27),(737,56),(731,83),(722,112),(716,151),(712,195),(714,235),(716,264),(718,295),(727,306),(740,303),(751,291),(747,308),(739,317),(723,325),(715,332),(721,351),(716,384),(745,399),(765,379),(763,414),(747,431),(716,441),(705,446),(697,500),(688,510),(675,516),(574,520),(575,541),(580,568),(445,575),(446,539),(446,527),(339,523),(331,518),(321,513),(313,449),(286,445),(261,428),(247,403),(271,404),(306,381),(312,351),(289,341),(272,331),(266,311),(290,311),(316,299),(349,275),(369,247),(366,212),(357,163),(334,131),(313,112),(302,89)]
def run(source,out):
    data=source.read_bytes();digest=hashlib.sha256(data).hexdigest()
    if digest!='44d116addb17c5aa5a1f6c7edc85d44132fefdc0eb52ae422b63cc0b71060e3f':raise ValueError('Reference SHA mismatch')
    rgb=Image.open(source).convert('RGB');mask=Image.new('L',(4096,4096),0)
    ImageDraw.Draw(mask).polygon([(x*4,y*4) for x,y in POINTS],fill=255)
    mask=mask.resize(rgb.size,Image.Resampling.LANCZOS)
    rgba=rgb.convert('RGBA');rgba.putalpha(mask)
    bbox=mask.getbbox();rgba=rgba.crop(bbox)
    # All retained colors are the actual reference image; only alpha changes.
    if ImageChops.difference(rgba.convert('RGB'),rgb.crop(bbox)).getbbox():raise AssertionError('Source colors changed')
    out.mkdir(parents=True,exist_ok=True);rgba.save(out/'main_house_edge04_candidate.png')
    for color,name in [((225,225,225),'light'),((40,44,49),'dark')]:
        bg=Image.new('RGBA',rgba.size,color+(255,));bg.alpha_composite(rgba);bg.convert('RGB').save(out/('review_'+name+'.jpg'),quality=95)
    report={'source_sha256':digest,'source_size':list(rgb.size),'bbox_xyxy':bbox,'polygon':POINTS,'native_size':list(rgba.size),'rgb_preserved_exactly':True,'upscaled':False,'generated':False,'status':'VISIBLE_PART_CANDIDATE_NOT_PRODUCTION_APPROVED','limitations':['Second manual outline pass; fine detail and full silhouette still require visual acceptance','Occluded or rear geometry not reconstructed','Native crop resolution smaller than whole 1024 image','Engine/mobile validation separate from image QA']}
    (out/'source_extraction_report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print('PASS_ORIGINAL_RGB_PRESERVED_NO_UPSCALE',rgba.size)
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--source',type=Path,required=True);p.add_argument('--out',type=Path,required=True);a=p.parse_args();run(a.source,a.out)
