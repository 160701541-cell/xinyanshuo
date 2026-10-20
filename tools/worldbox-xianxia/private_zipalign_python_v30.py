"""Private alignment of copied user APK before signing. Never signs or publishes game assets."""
import copy,struct,zipfile
from pathlib import Path

def align_apk(src,dst):
    aligned=0
    with zipfile.ZipFile(src) as origin,zipfile.ZipFile(dst,"w",allowZip64=True) as out:
        out.comment=origin.comment
        for member in origin.infolist():
            info=copy.copy(member)
            extra=b""; raw=info.extra; i=0
            while i+4<=len(raw):
                ident,size=struct.unpack_from("<HH",raw,i)
                if i+size+4>len(raw):break
                if ident not in (0xd935,0xffff,0x0001):
                    extra+=raw[i:i+size+4]
                i+=size+4
            if member.compress_type==zipfile.ZIP_STORED:
                align=16384 if member.filename.startswith("lib/") and member.filename.endswith(".so") else 4
                name=member.filename.encode("utf-8")
                base=out.fp.tell()+30+len(name)+len(extra)
                if base%align:
                    padding=(align-(base+4)%align)%align
                    extra+=struct.pack("<HH",0xd935,padding)+bytes(padding)
                aligned+=1
            info.extra=extra
            out.writestr(info,origin.read(member),compress_type=member.compress_type)
    with zipfile.ZipFile(dst) as z:
        if z.testzip() is not None:raise ValueError("bad output ZIP CRC")
        for member in z.infolist():
            if member.compress_type==zipfile.ZIP_STORED:
                offset=member.header_offset+30+len(member.filename.encode("utf-8"))+len(member.extra)
                boundary=16384 if member.filename.startswith("lib/") and member.filename.endswith(".so") else 4
                if offset%boundary:raise ValueError("unaligned entry: "+member.filename)
    return aligned
if __name__=="__main__":
    import argparse
    ap=argparse.ArgumentParser()
    ap.add_argument("src",type=Path);ap.add_argument("dst",type=Path)
    args=ap.parse_args()
    print("ALIGNED_STORED",align_apk(args.src,args.dst))
