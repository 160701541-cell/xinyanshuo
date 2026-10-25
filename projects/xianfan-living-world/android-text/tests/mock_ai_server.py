#!/usr/bin/env python3
# Local testing server only. Never shipped to the Android APK.
from http.server import BaseHTTPRequestHandler, HTTPServer
import json

class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path!="/v1/chat/completions":
            self.send_error(404)
            return
        length=int(self.headers.get("Content-Length","0"))
        body=json.loads(self.rfile.read(length))
        assert body.get("model")=="demo-local"
        text=" ".join(m.get("content","") for m in body.get("messages",[]))
        if "你扮演中国古风生活文字游戏中" in text:
            payload="我今天在扫院子。你要一起帮忙吗？"
        else:
            payload='{"kind":"action","command":"打扫院子"}'
        encoded=json.dumps({"choices":[{"message":{"role":"assistant","content":payload}}]},ensure_ascii=False).encode()
        self.send_response(200)
        self.send_header("Content-Type","application/json")
        self.send_header("Content-Length",str(len(encoded)))
        self.end_headers()
        self.wfile.write(encoded)
    def log_message(self, *args): pass

HTTPServer(("127.0.0.1",19180),Handler).serve_forever()
