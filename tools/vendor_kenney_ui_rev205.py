#!/usr/bin/env python3
"""Exact CC0 Kenney UI assets, pinned upstream with Git blob content SHA1.
This is build-time vendoring only; no live Internet dependency in the app.
"""
from __future__ import annotations
import hashlib, json, pathlib, urllib.parse, urllib.request

UPSTREAM_COMMIT = "3694c6879e487c108f55677be7dd2ca75b07cc3b"
UPSTREAM = "https://raw.githubusercontent.com/shorepine/kenney/" + UPSTREAM_COMMIT + "/"
ROOT = pathlib.Path("game-source/apk176-ota177-candidate/ui/kenney")
ART = {
    "panel_brown_dark.png": ("ui/UI Pack - Adventure/panel_brown_dark.png", "6c240398b6a4379850b41215762d5d43399502d4"),
    "panel_border_brown_detail.png": ("ui/UI Pack - Adventure/panel_border_brown_detail.png", "e05b35156cb0df89520dd39c168576e460a0da35"),
    "button_brown.png": ("ui/UI Pack - Adventure/button_brown.png", "73c062e9213a5a10c506e93b71b272c8ea2aec4b"),
    "button_brown_close.png": ("ui/UI Pack - Adventure/button_brown_close.png", "e8b83b5bf12a24d9872649723f2dca958d48c676"),
    "button_grey.png": ("ui/UI Pack - Adventure/button_grey.png", "2f70b21c778567c8854f4f77826ba6dab12a1a92"),
    "progress_red.png": ("ui/UI Pack - Adventure/progress_red.png", "570310fff678b3720e8fe4b23f570894d242a492"),
    "progress_blue.png": ("ui/UI Pack - Adventure/progress_blue.png", "db01e70fc3ee8fd20b22ac742bd73d45a2b80047"),
    "progress_green.png": ("ui/UI Pack - Adventure/progress_green.png", "9d7c584007202d94ddcd4a9fc415ad8ca768e17f"),
    "joystick_circle_pad_a.png": ("ui/Mobile Controls/Sprites/Style A/joystick_circle_pad_a.png", "74e2c93ca80d1a4b6a83d5ab2f0d6ae8e5929695"),
    "joystick_circle_nub_a.png": ("ui/Mobile Controls/Sprites/Style A/joystick_circle_nub_a.png", "e2cfc1b87492515a3d58ce909f15943a08d6667e"),
}

def main():
    ROOT.mkdir(parents=True, exist_ok=True)
    manifest = []
    for output, (source, expected_git_sha) in ART.items():
        if len(expected_git_sha)!=40:
            raise ValueError(output+" expected 40-char Git object sha")
        url = UPSTREAM + urllib.parse.quote(source, safe="/")
        with urllib.request.urlopen(
            urllib.request.Request(url,headers={"User-Agent":"CanglanCC0Vendor/1"}),
            timeout=25) as answer:
            data = answer.read(250_000)
        git_sha = hashlib.sha1(
            ("blob %d\0" % len(data)).encode() + data).hexdigest()
        if git_sha != expected_git_sha:
            raise RuntimeError(output+": immutable upstream SHA mismatch: "+git_sha)
        if data[:8] != bytes.fromhex("89504e470d0a1a0a"):
            raise RuntimeError(output+": source is not real PNG")
        (ROOT/output).write_bytes(data)
        manifest.append({"file":output,"original":source,"upstream_git_blob_sha1":git_sha,
            "sha256":hashlib.sha256(data).hexdigest(),"bytes":len(data),
            "license":"CC0-1.0"})
    (ROOT/"MANIFEST.json").write_text(json.dumps({
        "source_repository":"https://github.com/shorepine/kenney",
        "source_commit":UPSTREAM_COMMIT,
        "license":"CC0-1.0",
        "upstream_pack_urls":["https://kenney.nl/assets/ui-pack-adventure",
            "https://kenney.nl/assets/mobile-controls"],
        "files":manifest},ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print("PASS_REV205_PINNED_KENNEY_ADVENTURE_UI_CC0_AND_MOBILE_CONTROLS",len(manifest))

if __name__=="__main__":
    main()
