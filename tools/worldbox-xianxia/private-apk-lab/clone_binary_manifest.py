#!/usr/bin/env python3
"""Original AXML-only clone patch: preserve resource IDs, Java class names and permissions.

Changes application ID, provider authorities and package-scoped custom permissions;
adds an independent diagnostic launcher while retaining the original Unity activity.
Does not modify resources.arsc, billing code, native libraries or saved worlds.
"""
import argparse
import struct
from pathlib import Path

OLD = 'com.mkarpenko.worldbox'
NEW = 'com.xinyanshuo.worldbox.lab13'
ACTIVITY = NEW + '.DiagnosticsActivity'
TITLE = 'WorldBox·万界仙侠 整合v16'
ANDROID = 'http://schemas.android.com/apk/res/android'


def u16(data, pos): return struct.unpack_from('<H', data, pos)[0]
def u32(data, pos): return struct.unpack_from('<I', data, pos)[0]
def set32(data, pos, value): struct.pack_into('<I', data, pos, value)


def chunks(data, start=8):
    pos = start
    while pos < len(data):
        size = u32(data, pos+4)
        if size < 8 or pos+size > len(data): raise ValueError('Malformed AXML chunk')
        yield pos, u16(data, pos), data[pos:pos+size]
        pos += size


def patch(data):
    parts = list(chunks(data))
    if parts[0][1] != 1: raise ValueError('Expected first string pool')
    pool = parts[0][2]
    _, header, _, count, styles, flags, start, style_start = struct.unpack_from('<HHIIIIII', pool)
    if styles or style_start or flags & 0x100: raise ValueError('Expected unstyled UTF16 manifest pool')
    strings = []
    for i in range(count):
        pos = start + u32(pool, header+4*i)
        length = u16(pool, pos); pos += 2
        if length & 0x8000:
            length = ((length & 0x7fff) << 16) | u16(pool, pos); pos += 2
        strings.append(pool[pos:pos+length*2].decode('utf-16le'))
    index = {s:i for i,s in enumerate(strings)}
    android = index[ANDROID]
    replacement_indices = set()
    for _, kind, raw in parts:
        if kind != 0x102: continue
        tag = strings[u32(raw,20)]
        at = 16+u16(raw,24)
        step, total = u16(raw,26), u16(raw,28)
        for a in range(total):
            offset = at+a*step
            name = strings[u32(raw,offset+4)]
            if raw[offset+15] != 3: continue
            value_index = u32(raw,offset+16)
            value = strings[value_index]
            if (tag == 'manifest' and name == 'package') or name == 'authorities' or (tag in ('permission','uses-permission') and name=='name'):
                if value == OLD or value.startswith(OLD+'.'): replacement_indices.add(value_index)
    if index[OLD] not in replacement_indices: raise ValueError('Original package not identified')
    for i in replacement_indices: strings[i] = strings[i].replace(OLD,NEW)
    activity_index=len(strings); strings.append(ACTIVITY)
    title_index=len(strings); strings.append(TITLE)
    encoded=bytearray(); offsets=[]
    for text in strings:
        offsets.append(len(encoded)); binary=text.encode('utf-16le'); length=len(binary)//2
        if length < 0x8000: encoded += struct.pack('<H',length)
        else: encoded += struct.pack('<HH',0x8000 | (length>>16),length & 0xffff)
        encoded += binary+b'\0\0'
    while len(encoded)%4: encoded += b'\0'
    pool_start=28+4*len(strings)
    rebuilt=struct.pack('<HHIIIIII',1,28,pool_start+len(encoded),len(strings),0,flags & ~1,pool_start,0)
    rebuilt += struct.pack('<'+'I'*len(offsets),*offsets)+encoded

    stack=[]; output=[]; launcher=None; captured=[]; capturing=False; unity=False; added=False
    for _, kind, chunk in parts[1:]:
        raw=bytearray(chunk)
        if kind==0x102:
            tag=strings[u32(raw,20)]
            at=16+u16(raw,24); step=u16(raw,26); total=u16(raw,28)
            if tag=='manifest':
                for a in range(total):
                    o=at+a*step
                    if strings[u32(raw,o+4)]=='versionCode':
                        set32(raw,o+16,727)
            if tag=='activity':
                unity=False
                for a in range(total):
                    o=at+a*step
                    if strings[u32(raw,o+4)]=='name' and raw[o+15]==3:
                        unity=strings[u32(raw,o+16)]=='com.unity3d.player.UnityPlayerActivity'
            if tag=='intent-filter' and unity and stack and stack[-1]=='activity':
                if launcher is not None:raise ValueError('Multiple Unity intent filters need manual review')
                capturing=True; captured=[]
            if tag in ('application','activity'):
                for a in range(total):
                    o=at+a*step
                    if strings[u32(raw,o+4)]=='label':
                        set32(raw,o+8,title_index);raw[o+15]=3;set32(raw,o+16,title_index)
            stack.append(tag)
        elif kind==0x103:
            tag=strings[u32(raw,20)]
            if not stack or stack[-1]!=tag: raise ValueError('Unbalanced XML')
            stack.pop()
            if tag=='application':
                if launcher is None:raise ValueError('Missing Unity launcher intent filter')
                attrs=[]
                for name,typ,value in [('label',3,title_index),('name',3,activity_index),('exported',18,0xffffffff)]:
                    attrs.append(struct.pack('<IIIHBBI',android,index[name],value if typ==3 else 0xffffffff,8,0,typ,value))
                activity=struct.pack('<HHIIIIIHHHHHH',0x102,16,36+20*len(attrs),0,0xffffffff,0xffffffff,index['activity'],20,20,len(attrs),0,0,0)+b''.join(attrs)
                end=struct.pack('<HHIIIII',0x103,16,24,0,0xffffffff,0xffffffff,index['activity'])
                output.extend([activity,launcher,end]);added=True
        if capturing:
            captured.append(bytes(raw))
            if kind==0x103 and tag=='intent-filter':
                launcher=b''.join(captured);capturing=False
        else:
            output.append(bytes(raw))
        if kind==0x103 and tag=='activity': unity=False
    if not added: raise ValueError('No application end')
    result=bytearray(data[:8]+rebuilt+b''.join(output));set32(result,4,len(result))
    return bytes(result)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source',type=Path);parser.add_argument('out',type=Path)
    args=parser.parse_args()
    if args.source.resolve()==args.out.resolve(): raise ValueError('Never overwrite input')
    args.out.write_bytes(patch(args.source.read_bytes()))
    print('INDEPENDENT_MANIFEST_READY '+NEW)
