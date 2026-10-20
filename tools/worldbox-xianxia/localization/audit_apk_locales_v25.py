#!/usr/bin/env python3
"""Read-only WorldBox APK localization *asset-name* scanner.

Scans length-prefixed Unity asset index strings in globalgamemanagers. This
does NOT decrypt, translate or copy copyrighted game text, nor verify the
contents of individual locale assets. Only summarizes built-in language
groups by language code. Compatible as a conservative diagnostic for a
user-owned Android package, never for public APK publication.
"""
import argparse
import json
import re
import struct
import zipfile
from collections import defaultdict
from pathlib import Path

INDEX_PATH="assets/bin/Data/globalgamemanagers"
NAME=re.compile(r"^locales/([a-z]{2})/([a-z0-9_]+)$")
PREFIX=re.compile(rb"locales/[a-z]{2}/")
MAX_INDEX_SIZE=40_000_000
MAX_GROUPS=8000

def inspect(apk: Path):
    if not zipfile.is_zipfile(apk):
        raise ValueError("不是有效APK ZIP归档")
    groups=defaultdict(set)
    with zipfile.ZipFile(apk) as z:
        try:
            meta=z.getinfo(INDEX_PATH)
        except KeyError:
            raise ValueError("APK不包含预期的Unity资源索引；不能推断该版本语言目录")
        if meta.file_size>MAX_INDEX_SIZE or meta.file_size<128:
            raise ValueError("Unity资源索引大小超出安全范围")
        buf=z.read(meta)
    inspected=0
    for hit in PREFIX.finditer(buf):
        offset=hit.start()
        if offset<4:continue
        length=struct.unpack_from("<I",buf,offset-4)[0]
        if not 11<=length<=100:continue
        try:
            path=buf[offset:offset+length].decode("ascii")
        except UnicodeDecodeError:
            continue
        m=NAME.fullmatch(path)
        if not m:continue
        inspected+=1
        if inspected>MAX_GROUPS:
            raise ValueError("Unity资源索引中语言条目数量异常")
        groups[m.group(1)].add(m.group(2))
    english=groups.get("en",set())
    chinese=groups.get("cz",set())
    return {
        "文件":apk.name,
        "模式":"仅检查Unity语言资源索引中的名称，不导出受版权保护的语言文本",
        "语言数量":len(groups),
        "语言清单":{k:len(v) for k,v in sorted(groups.items())},
        "原版英文资源组数":len(english),
        "原版简体中文资源组数":len(chinese),
        "简中与英文共同存在资源组数":len(english&chinese),
        "英文有但简中无的资源组名":sorted(english-chinese),
        "简中有但英文无的资源组名":sorted(chinese-english),
        "简中已索引的资源组名":sorted(chinese),
        "关键限制":"资源组名称存在≠每条游戏文本已翻译，更不等于第三方MOD已有汉化。"
    }

def main():
    p=argparse.ArgumentParser()
    p.add_argument("apk",type=Path)
    p.add_argument("--out",type=Path)
    a=p.parse_args()
    result=inspect(a.apk)
    output=json.dumps(result,ensure_ascii=False,indent=2)+"\n"
    if a.out:
        a.out.parent.mkdir(parents=True,exist_ok=True)
        a.out.write_text(output,encoding="utf-8")
    print(output)

if __name__=="__main__":main()
