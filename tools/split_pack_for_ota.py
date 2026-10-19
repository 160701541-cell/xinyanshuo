#!/usr/bin/env python3
"""把 OTA PCK 切成多分片并生成 manifest，供客户端按片下载后按序拼接。

为什么要分片
------------
GitHub Pages 对单个文件有 100 MB 硬上限，站点总量也有 ~1 GB 软上限；
Release 资产单文件 2 GB。所以"几个 G 的版本"必须同时满足两点：
  1) 单个产物文件足够小（分片）；
  2) 宿主能返回 Range 且不限制单文件体积（Pages 不行，Release 资产/R2/OSS 可以）。

manifest 结构（向后兼容）
-------------------------
旧客户端只读 pack_url/pack_sha256/signature，会忽略新增的 assets/chunks 字段；
新客户端优先读 chunks，按 offset 顺序写入同一个 .pck 文件，再校验整包 sha256。

用法
----
  python3 tools/split_pack_for_ota.py --pack canglan-content-rev-208.pck \
      --outdir /tmp/ota209 --revision 209 --chunk-mb 90
"""
import argparse, hashlib, json, os, pathlib


def sha256_file(path, limit=None):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        remaining = limit
        while True:
            n = 1 << 20 if remaining is None else min(1 << 20, remaining)
            if n <= 0:
                break
            b = f.read(n)
            if not b:
                break
            h.update(b)
            if remaining is not None:
                remaining -= len(b)
    return h.hexdigest()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--pack', required=True)
    ap.add_argument('--outdir', required=True)
    ap.add_argument('--revision', type=int, required=True)
    ap.add_argument('--chunk-mb', type=int, default=90)
    ap.add_argument('--pack-url-prefix', default='')
    a = ap.parse_args()

    pack = pathlib.Path(a.pack)
    out = pathlib.Path(a.outdir)
    out.mkdir(parents=True, exist_ok=True)
    total = pack.stat().st_size
    step = a.chunk_mb * 1024 * 1024
    chunks = []
    with open(pack, 'rb') as f:
        offset = 0
        idx = 0
        while offset < total:
            take = min(step, total - offset)
            name = f'part-{idx:03d}.pck'
            dst = out / name
            h = hashlib.sha256()
            with open(dst, 'wb') as g:
                left = take
                while left:
                    b = f.read(min(1 << 20, left))
                    if not b:
                        raise SystemExit(f'EOF at {offset} while writing {name}')
                    g.write(b)
                    h.update(b)
                    left -= len(b)
            chunks.append({'name': name, 'offset': offset, 'size': take, 'sha256': h.hexdigest()})
            print(f'{name}  offset={offset}  size={take}  sha256={h.hexdigest()[:16]}…')
            offset += take
            idx += 1

    manifest = {
        'schema': 2,
        'revision': a.revision,
        'pack_size': total,
        'pack_sha256': sha256_file(pack),
        'chunk_size': step,
        'chunk_count': len(chunks),
        'assets_base': a.pack_url_prefix,
        'chunks': chunks,
        # 旧客户端字段：指向"直链整包"（新宿主上仍可存在），没有就留空
        'pack_url': '',
    }
    mp = out / 'manifest.json'
    mp.write_text(json.dumps(manifest, ensure_ascii=False, indent=2))
    print(f'\nmanifest.json: {len(chunks)} 片, 总 {total} 字节, 整包sha256={manifest["pack_sha256"][:16]}…')
    print('分片自检：拼接后 sha256 是否等于整包 →', verify(out, manifest))


def verify(out, manifest):
    h = hashlib.sha256()
    for c in manifest['chunks']:
        with open(out / c['name'], 'rb') as f:
            while True:
                b = f.read(1 << 20)
                if not b:
                    break
                h.update(b)
    return h.hexdigest() == manifest['pack_sha256']


if __name__ == '__main__':
    main()
