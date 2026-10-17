#!/usr/bin/env python3
"""Lossless material-preserving GLB mesh aggregation for rev208 Android Draft.

Keep ORIGINAL vendor CC0 source GLBs immutable. This script only creates a
separate unapproved RENDER CANDIDATE, with strict triangle/geometry/material/
embedded PBR image verification. Godot 4.4.1 will independently measure the
actual model size and engine mesh-surface draw counts.
"""
from __future__ import annotations
import base64
import collections
import copy
import hashlib
import json
import struct
import subprocess
import sys
from pathlib import Path
from urllib.parse import unquote_to_bytes

def read_glb(path):
    b=Path(path).read_bytes()
    if len(b)<28 or b[:4]!=b"glTF":
        raise ValueError("NOT_GLTF2_BINARY: "+str(path))
    magic,version,n=struct.unpack_from("<4sII",b)
    if version!=2 or n!=len(b):raise ValueError("GLB2_LENGTH_MISMATCH: "+str(path))
    offset=12
    json_doc=None
    binary=b""
    while offset+8<=len(b):
        size,tag=struct.unpack_from("<I4s",b,offset)
        offset+=8
        data=b[offset:offset+size]
        if len(data)!=size:raise ValueError("TRUNCATED_GLTF_CHUNK")
        if tag==b"JSON":json_doc=json.loads(data.decode("utf-8").strip(" \\0"))
        elif tag==b"BIN\\x00":binary=data
        offset+=size
    if json_doc is None:raise ValueError("GLTF_HAS_NO_JSON")
    return json_doc,binary

def image_digest_map(doc,binbytes):
    views=doc.get("bufferViews",[])
    result={}
    for i,img in enumerate(doc.get("images",[])):
        if "bufferView" in img:
            view=views[img["bufferView"]]
            if view.get("buffer",0)!=0:raise ValueError("EXTERNAL_BUFFER_REFUSED")
            data=binbytes[view.get("byteOffset",0):view.get("byteOffset",0)+view["byteLength"]]
        elif img.get("uri","").startswith("data:"):
            uri=img["uri"];meta,body=uri.split(",",1)
            data=base64.b64decode(body) if ";base64" in meta else unquote_to_bytes(body)
        else:
            raise ValueError("EXTERNAL_IMAGE_URI_CANNOT_BE_SHA_VALIDATED")
        if not data:raise ValueError("EMPTY_PBR_IMAGE")
        result[i]=hashlib.sha256(data).hexdigest()
    return result

def used_material_signatures(doc,images):
    textures=doc.get("textures",[])
    materials=doc.get("materials",[])
    used=set()
    for mesh in doc.get("meshes",[]):
        for prim in mesh.get("primitives",[]):
            if "material" in prim:used.add(prim["material"])
    if not used:raise ValueError("NO_REAL_VENDOR_PBR_MATERIALS")
    def tex_sig(idx):
        tex=textures[idx]
        source=tex.get("source",None)
        if source is None:
            ext=tex.get("extensions",{})
            source=ext.get("KHR_texture_basisu",{}).get("source",None)
        if source is None or source not in images:
            raise ValueError("UNSUPPORTED_NON_SHA_PINNED_PBR_TEXTURE")
        return {"image_sha":images[source],
                "sampler":doc.get("samplers",[])[tex["sampler"]]
                  if "sampler" in tex else None}
    def canon(obj):
        if isinstance(obj,dict):
            result={}
            for k,v in obj.items():
                if k=="name":continue
                if k in ("baseColorTexture","metallicRoughnessTexture",
                         "normalTexture","occlusionTexture","emissiveTexture") and (
                         isinstance(v,dict) and "index" in v):
                    rest={k2:canon(v2) for k2,v2 in v.items() if k2!="index"}
                    result[k]={"source":tex_sig(v["index"]),"params":rest}
                else:result[k]=canon(v)
            return result
        if isinstance(obj,list):return [canon(v) for v in obj]
        return obj
    return {json.dumps(canon(materials[i]),sort_keys=True,ensure_ascii=False)
            for i in used}

def geometry(doc):
    acc=doc.get("accessors",[])
    triangles=0
    surfaces=0
    for mesh in doc.get("meshes",[]):
        for prim in mesh.get("primitives",[]):
            if prim.get("mode",4)!=4:
                raise ValueError("NON_TRIANGULAR_VENDOR_PBR_MESH_REFUSED")
            idx=prim.get("indices")
            pos=prim.get("attributes",{}).get("POSITION")
            use=idx if idx is not None else pos
            if not isinstance(use,int) or use>=len(acc):
                raise ValueError("MISSING_TRIANGLE_VERTEX_ACCESSOR")
            triangles+=int(acc[use]["count"])//3
            surfaces+=1
    return triangles,surfaces

def main(source_dir,out_dir):
    source=Path(source_dir)
    dest=Path(out_dir)
    dest.mkdir(parents=True,exist_ok=True)
    manifest=json.loads((source/"manifest.json").read_text(encoding="utf8"))
    if manifest.get("art_approval")!="PENDING_REAL_GODOT_AND_USER" or (
        manifest.get("release_policy")!="QUARANTINED_NO_SIGNING_NO_OTA"):
        raise ValueError("SOURCE_LICENSE_AND_RELEASE_QUARANTINE_NOT_CONFIRMED")
    report={"schema":208,"release_policy":"QA_ONLY_NOT_SIGNED_NOT_SHIPPED",
            "art_approval":"PENDING_SOURCE_LOD_MOBILE_VISUAL",
            "algorithm":"glTF-Transform 4.5.0 dedup+flatten+join, no simplify, no material/textures re-encoding",
            "items":{}}
    for kind,entry in manifest["items"].items():
        original=source/entry["file"]
        blob=original.read_bytes()
        if hashlib.sha256(blob).hexdigest()!=entry["original_sha256"]:
            raise ValueError("VENDOR_SOURCE_ORIGINAL_SHA256_MISMATCH_"+kind)
        input_doc,input_binary=read_glb(original)
        if input_doc.get("animations") or input_doc.get("skins"):
            raise ValueError("SKELETAL_OR_ANIMATED_SOURCE_NOT_SAFE_FOR_FLATTEN_"+kind)
        source_tri,source_surfaces=geometry(input_doc)
        if source_tri!=entry["triangle_lod0"]:
            raise ValueError("SOURCE_TESSSELLATION_MANIFEST_CONFLICT_"+kind)
        output=dest/("hq_"+kind+"_cc0_drawmerged.glb")
        cmd=["gltf-transform","join",str(original),str(output),
             "--keepMeshes","false","--keepNamed","false"]
        result=subprocess.run(cmd,capture_output=True,text=True,timeout=200)
        if result.returncode!=0:
            raise ValueError("JOIN_TRANSFORM_FAILED_"+kind+" "+result.stderr[-2600:])
        derived=output.read_bytes()
        final_doc,final_bin=read_glb(output)
        final_tri,final_surfaces=geometry(final_doc)
        if source_tri!=final_tri:
            raise ValueError("RENDER_CANDIDATE_GEOMETRY_TRIANGLE_LOSS_"+kind+
                             " source="+str(source_tri)+" actual="+str(final_tri))
        source_images=image_digest_map(input_doc,input_binary)
        final_images=image_digest_map(final_doc,final_bin)
        if sorted(source_images.values())!=sorted(final_images.values()):
            raise ValueError("ORIGINAL_VENDOR_IMAGE_PBR_TEXTURE_CHANGED_"+kind)
        source_mats=used_material_signatures(input_doc,source_images)
        final_mats=used_material_signatures(final_doc,final_images)
        if source_mats!=final_mats:
            raise ValueError("ORIGINAL_VENDOR_MATERIAL_ROUGHNESS_ALPHA_NORMALS_CHANGED_"+kind+
                             " before="+str(len(source_mats))+" after="+str(len(final_mats)))
        if final_surfaces>source_surfaces:
            raise ValueError("MESH_JOIN_INCREASED_DRAW_PARTS_"+kind)
        # Fail closed for sources with excess 20+ original draw parts, but
        # keep the authentic light 4-surface fern intact.
        if source_surfaces>=20 and final_surfaces>max(8,source_surfaces//2):
            raise ValueError("SOURCE_STILL_TOO_FRAGMENTED_FOR_PHONE_"+kind+
                " before="+str(source_surfaces)+" after="+str(final_surfaces))
        report["items"][kind]={
            "vendor_file":entry["file"],
            "vendor_original_sha256":entry["original_sha256"],
            "vendor_source_page":entry["source_page"],
            "license":entry["license"],"file":output.name,
            "sha256":hashlib.sha256(derived).hexdigest(),
            "original_triangles":source_tri,"triangle_lod0":final_tri,
            "source_draw_surfaces":source_surfaces,"merged_draw_surfaces":final_surfaces,
            "vendor_PBR_material_signatures_preserved":True,
            "original_embedded_PBR_images_sha_preserved":True,
            "original_image_count":len(source_images),
            "godot_441_bounds_checked":False,
            "game_asset_approved":False,
            "lod1":"NOT_PRODUCED","lod2":"NOT_PRODUCED"
        }
        print("REV208_CC0_LOSSLESS_MESH_DRAW_JOIN",kind,
              source_surfaces,"=>",final_surfaces,
              "triangles",final_tri,"images",len(source_images),flush=True)
    (dest/"manifest.json").write_text(
        json.dumps(report,indent=2,ensure_ascii=False)+"\n",encoding="utf8")
    print("PASS_REV208_REAL_11_CC0_BOTANICAL_VENDOR_PBR_IMAGES_MATERIALS_TRIANGLES_UNCHANGED_DRAW_PARTS_DECREASED_NOT_ART_APPROVED")

if __name__=="__main__":
    if len(sys.argv)!=3:
        raise SystemExit("usage: rev208_join_cc0_botanical_meshes.py SOURCE_DIR OUT_DIR")
    main(sys.argv[1],sys.argv[2])
