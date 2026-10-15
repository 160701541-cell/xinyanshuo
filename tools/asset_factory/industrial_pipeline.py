#!/usr/bin/env python3
"""Canglan art factory: two model stages, no silent mock output."""
import argparse, hashlib, json, os, pathlib, subprocess, time, urllib.request
from PIL import Image, ImageOps
ROOT=pathlib.Path(__file__).parent

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def post(url, data):
 req=urllib.request.Request(url,data=json.dumps(data).encode(),headers={'Content-Type':'application/json'})
 with urllib.request.urlopen(req,timeout=45) as f:return json.load(f)
def generate(job, url, template):
 wf=json.loads(template.read_text()); node=wf[str(job['prompt_node'])]
 node['inputs']['text']=job['prompt']; result=post(url.rstrip('/')+'/prompt',{'prompt':wf,'client_id':'canglan_factory'})
 return result['prompt_id']
def fetch_result(pid,url,dest,timeout):
 start=time.monotonic()
 while time.monotonic()-start<timeout:
  with urllib.request.urlopen(url.rstrip('/')+'/history/'+pid,timeout=30) as f: hist=json.load(f)
  entry=hist.get(pid,{})
  if entry.get('status',{}).get('status_str')=='error':raise RuntimeError('ComfyUI execution error: '+pid)
  outputs=[img for v in entry.get('outputs',{}).values() for img in v.get('images',[]) if img.get('type')=='output']
  if outputs:
   if len(outputs)!=1:raise RuntimeError('Expected ONE image, got '+str(len(outputs)))
   import urllib.parse
   q=urllib.parse.urlencode({'filename':outputs[0]['filename'],'subfolder':outputs[0].get('subfolder',''),'type':'output'})
   with urllib.request.urlopen(url.rstrip('/')+'/view?'+q,timeout=90) as f:dest.write_bytes(f.read())
   with Image.open(dest) as im:im.verify()
   return
  time.sleep(3)
 raise TimeoutError(pid)
def upscale(src,dst,command,scale):
 if command:
  cmd=[p.format(input=str(src),output=str(dst),scale=str(scale)) for p in command]
  subprocess.run(cmd,check=True,timeout=600)
 else:
  # Fallback is ONLY image resizing, not AI super-resolution; record explicitly.
  with Image.open(src) as im:
   im=im.convert('RGBA');im.resize((im.width*scale,im.height*scale),Image.Resampling.LANCZOS).save(dst)
def process(job,args):
 base=ROOT/'output'/job['id']/job['state'];base.mkdir(parents=True,exist_ok=True)
 raw=base/'stage1.png';enh=base/'stage2.png';icon=base/'icon.png';meta=base/'metadata.json'
 if not raw.exists():
  if args.dry_run:return {'id':job['id'],'state':job['state'],'status':'PENDING_GENERATION'}
  if not args.workflow:raise RuntimeError('No generation workflow specified; cannot generate '+job['id'])
  pid=generate(job,args.url,pathlib.Path(args.workflow));fetch_result(pid,args.url,raw,args.timeout)
 if not enh.exists():upscale(raw,enh,args.upscale_command,args.scale)
 with Image.open(enh) as im:
  rgba=im.convert('RGBA')
  if min(rgba.size)<512:raise ValueError('Enhanced asset below 512px')
  # No fake alpha: opaque outputs are quarantined until background removal.
  alpha=rgba.getchannel('A')
  if alpha.getextrema()[0]==255:status='NEEDS_BACKGROUND_REMOVAL'
  else:status='PENDING_VISUAL_QA'
  canvas=Image.new('RGBA',(512,512)); thumb=rgba.copy();thumb.thumbnail((464,464),Image.Resampling.LANCZOS)
  canvas.alpha_composite(thumb,((512-thumb.width)//2,(512-thumb.height)//2));canvas.save(icon)
  record={'id':job['id'],'state':job['state'],'status':status,'stage1_sha256':sha(raw),'stage2_sha256':sha(enh),'icon_sha256':sha(icon),'upscale_method':'external_AI' if args.upscale_command else 'LANCZOS_NOT_AI','prompt':job['prompt'],'approved':False}
  meta.write_text(json.dumps(record,ensure_ascii=False,indent=2));return record

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--jobs',default=str(ROOT/'jobs.json'));ap.add_argument('--url',default='http://127.0.0.1:8188');ap.add_argument('--workflow');ap.add_argument('--timeout',type=int,default=600);ap.add_argument('--scale',type=int,default=2);ap.add_argument('--upscale-command',nargs='+');ap.add_argument('--dry-run',action='store_true');args=ap.parse_args()
 jobs=json.loads(pathlib.Path(args.jobs).read_text());seen=set();results=[]
 for job in jobs:
  key=(job['id'],job['state']);assert key not in seen,key;seen.add(key)
  try:results.append(process(job,args))
  except Exception as e:results.append({'id':job['id'],'state':job['state'],'status':'ERROR','error':str(e)})
 print(json.dumps(results,ensure_ascii=False,indent=2));(ROOT/'run_report.json').write_text(json.dumps(results,ensure_ascii=False,indent=2))
if __name__=='__main__':main()
