#!/usr/bin/env python3
"""Fail-closed independent PCK v2 index audit for ONLY the 3-file OTA177.

No signing keys. This is a game-data *allowlist*, not proof of real APK
compatibility or authorized production publication.
"""
import hashlib
import struct
import sys
from pathlib import Path

ALLOWED = {
    "scripts/touch_look_router.gd",
    "scripts/touch_look_router_ota177.gd",
    "scripts/touch_look_router.gd.remap",
}


def read_index(raw: bytes) -> list[dict]:
    if len(raw) < 512 or raw[:4] != b"GDPC":
        raise ValueError("not a real Godot PCK")
    fmt, major, minor, patch, flags = struct.unpack_from("<IIIII", raw, 4)
    if (fmt, major, minor) != (2, 4, 4):
        raise ValueError(f"unsupported Godot PCK format/engine {fmt}, {major}.{minor}.{patch}")
    if flags != 0:
        raise ValueError("encrypted/delta/flagged packages not allowed")
    # PCK v2: file data base is at 0x18, reserved[16] occupies 0x20..0x5f,
    # 32-bit file count begins at 0x60.
    file_base = struct.unpack_from("<Q", raw, 0x18)[0]
    if file_base < 0x68 or file_base > len(raw):
        raise ValueError("invalid PCK file base")
    n = struct.unpack_from("<I", raw, 0x60)[0]
    if n != len(ALLOWED):
        raise ValueError(f"unexpected PCK file count {n}, expected {len(ALLOWED)}")
    position = 0x64
    found = []
    for _ in range(n):
        if position + 4 > file_base:
            raise ValueError("PCK index truncated at filename")
        length = struct.unpack_from("<I", raw, position)[0]
        position += 4
        if not 1 <= length <= 1024 or position + length + 36 > file_base:
            raise ValueError("PCK file entry length invalid")
        name_raw = raw[position:position+length].split(b"\x00", 1)[0]
        position += length
        name = name_raw.decode("utf-8", "strict")
        ofs, size = struct.unpack_from("<QQ", raw, position)
        position += 16
        md5 = raw[position:position+16]
        position += 16
        file_flags = struct.unpack_from("<I", raw, position)[0]
        position += 4
        if name.startswith("res://") or name != name.replace("\\", "/") or ".." in Path(name).parts:
            raise ValueError("noncanonical PCK resource path")
        if file_flags != 0:
            raise ValueError("encrypted/removal PCK resource not allowed")
        if not 1 <= size <= 8_000_000 or ofs + size > len(raw) - file_base:
            raise ValueError("PCK file outside data boundaries")
        payload = raw[file_base+ofs:file_base+ofs+size]
        if hashlib.md5(payload).digest() != md5:
            raise ValueError("PCK entry MD5 mismatch: " + name)
        found.append({"name": name, "size": size, "sha256": hashlib.sha256(payload).hexdigest()})
    actual = {x["name"] for x in found}
    if actual != ALLOWED:
        raise ValueError(f"wrong PCK resource set; missing={ALLOWED-actual}, extra={actual-ALLOWED}")
    if position > file_base:
        raise ValueError("PCK index overlaps file data")
    return found


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: audit_tiny_ota_pck.py path-to-PCK")
    entries = read_index(Path(sys.argv[1]).read_bytes())
    for entry in entries:
        print("VERIFIED_OTA_ENTRY", entry["name"], entry["size"], entry["sha256"])
    print("PASS OTA177 EXACT THREE RESOURCE PCK; SIGNATURE AND PHONE QA NOT PROVEN")


if __name__ == "__main__":
    main()
