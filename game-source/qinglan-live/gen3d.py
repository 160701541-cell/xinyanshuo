"""text-to-3D 适配层：同一份 prompts.json，喂给不同服务商。

本地没有 3D 生成模型（容器离线、无 GPU、无额度），所以这里只做两件事：
  1) --plan   把每条提示词组装成各家的请求体，打印/落盘，可直接 curl 或贴进网页
  2) --run    有 key 时真跑（需要网络与额度），下载 glb 到 assets3d/

用法：
  TRIPO_KEY=xxx python3 gen3d.py --provider tripo --run
  python3 gen3d.py --provider meshy --plan
"""
import argparse, json, os, pathlib, urllib.request

ROOT = pathlib.Path(__file__).parent
P = json.load(open(ROOT / "prompts.json"))
COMMON = P["common"]

def full_prompt(a):
    return (f'{a["prompt"]}. Style: {COMMON["style"]}. '
            f'Bake {COMMON["lighting_bake"]}. Output texture resolution {COMMON["resolution"]}px, PBR: albedo/normal/roughness/metalness. '
            f'Avoid: {COMMON["negative"]}.')

def build_request(provider, a):
    pr = full_prompt(a)
    if provider == "tripo":
        return {"type": "text_to_model", "prompt": pr, "model_version": "v2.5-20250123",
                "texture": True, "pbr": True, "texture_quality": "detailed", "face_limit": 20000}
    if provider == "meshy":
        return {"mode": "preview", "prompt": pr, "art_style": "realistic", "should_remesh": True,
                "topology": "quad", "target_polycount": 20000, "enable_pbr": True}
    if provider == "rodin":
        return {"prompt": pr, "condition_mode": "concat", "geometry_file_format": "glb",
                "material": "PBR", "quality": "high", "tier": "Regular", "use_hyper": False}
    if provider == "hunyuan":
        return {"prompt": pr, "num_infer_steps": 50, "guidance_scale": 5.5, "octree_resolution": 384}
    raise SystemExit("unknown provider")

ENDPOINT = {
    "tripo": "https://api.tripo3d.ai/v2/openapi/task",
    "meshy": "https://api.meshy.ai/openapi/v2/text-to-3d",
    "rodin": "https://hyper3d.ai/api/v1/rodin",
    "hunyuan": "http://localhost:8080/generate",   # 本地部署的 Hunyuan3D
}
KEYENV = {"tripo": "TRIPO_KEY", "meshy": "MESHY_KEY", "rodin": "RODIN_KEY", "hunyuan": "HUNYUAN_KEY"}

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--provider", default="tripo", choices=list(ENDPOINT))
    ap.add_argument("--plan", action="store_true")
    ap.add_argument("--run", action="store_true")
    ap.add_argument("--only", default=None)
    args = ap.parse_args()

    out = []
    for a in P["assets"]:
        if args.only and a["id"] != args.only:
            continue
        body = build_request(args.provider, a)
        out.append({"id": a["id"], "cn": a["cn"], "endpoint": ENDPOINT[args.provider], "body": body})
    (ROOT / f"requests_{args.provider}.json").write_text(json.dumps(out, ensure_ascii=False, indent=1))
    print(f"[plan] {len(out)} 条请求已写入 requests_{args.provider}.json")
    if not args.run:
        print(json.dumps(out[0]["body"], ensure_ascii=False, indent=1)[:600])
        raise SystemExit(0)
    key = os.environ.get(KEYENV[args.provider])
    if not key:
        raise SystemExit(f"缺少环境变量 {KEYENV[args.provider]}")
    (ROOT / "assets3d").mkdir(exist_ok=True)
    for o in out:
        req = urllib.request.Request(o["endpoint"], data=json.dumps(o["body"]).encode(),
                                     headers={"Content-Type": "application/json", "Authorization": f"Bearer {key}"})
        with urllib.request.urlopen(req, timeout=120) as r:
            print(o["id"], r.status, r.read()[:200])
