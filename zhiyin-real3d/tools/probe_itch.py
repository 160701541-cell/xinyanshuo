#!/usr/bin/env python3
"""Quaternius publisher-only download metadata investigation (no payments)."""
import urllib.request,re
urls=[
"https://quaternius.itch.io/universal-base-characters",
"https://quaternius.itch.io/universal-base-characters/purchase",
"https://quaternius.itch.io/universal-base-characters/download",
"https://quaternius.com/packs/universalbasecharacters.html",
]
for url in urls:
 print("\nSOURCE",url,flush=True)
 try:
  request=urllib.request.Request(url,headers={"User-Agent":"Mozilla/5.0"})
  with urllib.request.urlopen(request,timeout=22) as resp:
   raw=resp.read(220000).decode("utf-8","replace")
   print("HTTP",resp.status,"length",len(raw),"final_path",resp.geturl().split("?")[0],flush=True)
  for term in ("Standard","upload_id","download","file/","iframe","data-upload","purchase","base characters"):
   positions=[m.start() for m in re.finditer(re.escape(term),raw,re.IGNORECASE)]
   print(term,"occurrences",len(positions))
   if positions:print("context",re.sub(r"<[^>]*>"," ",raw[max(0,positions[0]-90):positions[0]+200])[:280])
 except Exception as e:
  print(type(e).__name__,str(e)[:230])

  if "purchase" in url:
   for needle in ("Universal Base Characters[Standard].zip","No thanks","download_button","button","payments","form"):
    idx=raw.find(needle)
    if idx>=0:
     print("RAW",needle,repr(raw[max(0,idx-500):idx+700])[:1100])
