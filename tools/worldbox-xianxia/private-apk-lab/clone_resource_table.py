#!/usr/bin/env python3
"""Match the compiled resource package name to the independent manifest identity.

The ResTable_package name occupies a fixed UTF16[128] field. Change only that
field; retain every resource ID, string value, offset and configuration byte.
"""
import struct


def patch_resource_table(data, old='com.mkarpenko.worldbox', new='com.xinyanshuo.worldbox.lab13'):
    if len(data)<12 or struct.unpack_from('<H',data)[0]!=0x0002:
        raise ValueError('Expected Android compiled resource table')
    if struct.unpack_from('<I',data,4)[0]!=len(data):
        raise ValueError('Resource table length mismatch')
    replacement=new.encode('utf-16le')
    if not new or len(replacement)>254:
        raise ValueError('Package name exceeds UTF16[128] field')
    output=bytearray(data);pos=struct.unpack_from('<H',data,2)[0];changed=0
    while pos<len(data):
        if pos+8>len(data):raise ValueError('Truncated resource chunk')
        kind,header,size=struct.unpack_from('<HHI',data,pos)
        if size<header or size<8 or pos+size>len(data):raise ValueError('Invalid resource chunk')
        if kind==0x0200:
            if header<284:raise ValueError('Invalid package header')
            name=data[pos+12:pos+268].decode('utf-16le').split('\0',1)[0]
            if name==old:
                output[pos+12:pos+268]=replacement+b'\0'*(256-len(replacement))
                changed+=1
        pos+=size
    if changed!=1:raise ValueError('Expected exactly one original resource package, got '+str(changed))
    return bytes(output)
