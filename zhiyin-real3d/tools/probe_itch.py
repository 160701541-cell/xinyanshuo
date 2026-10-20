#!/usr/bin/env python3
"""Probe the anonymous official itch.io downloads listing for Quaternius CC0 character.
No mirrors, logins, payments or third-party redistribution used.
This script prints only non-sensitive upload metadata and HTTP codes.
"""
import urllib.request, urllib.parse, re, html, json
URL="https://quaternius.itch.io/universal-base-characters"
headers={"User-Agent":"Mozilla/5.0 (compatible; ZhiYinAssetCI/1.0)"}
with urllib.request.urlopen(urllib.request.Request(URL,headers=headers),timeout=50) as result:
    page=result.read().decode("utf-8","replace")
print("OFFICIAL_PAGE_BYTES",len(page))
patterns=[
    r'Universal Base Characters\\[Standard\\].{0,360}',
    r"upload_id.{0,28}[0-9]{7,}",
    r'data-upload_id="([0-9]+)"',
    r'/file/([0-9]+)',
    r'<a[^>]*class="[^"]*download[^"]*"[^>]+',
]
for pat in patterns:
    matches=re.findall(pat,page,flags=re.IGNORECASE|re.DOTALL)
    print("PATTERN",pat,"COUNT",len(matches))
    for m in matches[:5]:print("RESULT",str(m)[:320])
