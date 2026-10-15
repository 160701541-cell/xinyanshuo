#!/usr/bin/env python3
"""CAC-0011: bridge independent asset jobs to an existing ComfyUI API workflow."""
import argparse, copy, json, time, urllib.parse, urllib.request
from pathlib import Path
from PIL import Image

def request_json(url, payload=None):
    data=None if payload is None else json.dumps(payload).encode()
    req=urllib.request.Request(url,data=data,headers={"Content-Type":"application/json"})
    with urllib.request.urlopen(req,timeout=45) as response:return json.load(response)

def execute(job, workflow, url, prompt_node, negative_node, timeout):
    graph=copy.deepcopy(workflow)
    graph[str(prompt_node)]["inputs"]["text"]=job["prompt"]
    if negative_node:graph[str(negative_node)]["inputs"]["text"]=job["negative_prompt"]
    pid=request_json(url.rstrip("/")+"/prompt",{"prompt":graph,"client_id":"canglan_cac0011"})["prompt_id"]
    end=time.monotonic()+timeout
    while time.monotonic()<end:
        record=request_json(url.rstrip("/")+"/history/"+pid).get(pid,{})
        if record.get("status",{}).get("status_str")=="error":raise RuntimeError("MODEL_EXECUTION_FAILED")
        imgs=[i for node in record.get("outputs",{}).values() for i in node.get("images",[]) if i.get("type")=="output"]
        if imgs:
            if len(imgs)!=1:raise RuntimeError("EXPECTED_SINGLE_OUTPUT")
            params=urllib.parse.urlencode({k:imgs[0].get(k,"") for k in ("filename","subfolder","type")})
            with urllib.request.urlopen(url.rstrip("/")+"/view?"+params,timeout=90) as response:return response.read()
        time.sleep(3)
    raise TimeoutError("COMFYUI_TIMEOUT")

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--jobs",required=True);p.add_argument("--workflow",required=True)
    p.add_argument("--prompt-node",required=True);p.add_argument("--negative-node")
    p.add_argument("--url",default="http://127.0.0.1:8188");p.add_argument("--out",required=True)
    p.add_argument("--limit",type=int,default=20);p.add_argument("--timeout",type=int,default=600)
    p.add_argument("--dry-run",action="store_true")
    a=p.parse_args()
    jobs=json.loads(Path(a.jobs).read_text())["jobs"][:a.limit]
    workflow=json.loads(Path(a.workflow).read_text())
    output=Path(a.out);output.mkdir(parents=True,exist_ok=True)
    reports=[]
    for job in jobs:
        status="PENDING_GENERATION"; error=None
        if not a.dry_run:
            for attempt in range(1,job.get("max_attempts",3)+1):
                try:
                    data=execute(job,workflow,a.url,a.prompt_node,a.negative_node,a.timeout)
                    import io
                    with Image.open(io.BytesIO(data)) as im:
                        im.load()
                        native_ok=min(im.size)>=min(job["minimum_native_size"])
                        alpha_ok=im.mode=="RGBA" and im.getchannel("A").getextrema()[0]<255
                        if not native_ok or not alpha_ok:raise ValueError("NATIVE_SIZE_OR_ALPHA_REJECTED")
                    (output/(job["job_id"]+".png")).write_bytes(data)
                    status="PENDING_VISUAL_QA";break
                except Exception as exc:error=str(exc);status="FAILED_RETRY_EXHAUSTED"
        reports.append({"job_id":job["job_id"],"status":status,"approved":False,"error":error})
    (output/"run_report.json").write_text(json.dumps(reports,indent=2))
    print(json.dumps({"jobs":len(reports),"pending_visual_qa":sum(x["status"]=="PENDING_VISUAL_QA" for x in reports),"report":str(output/"run_report.json")}))
if __name__=="__main__":main()
